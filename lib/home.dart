import 'package:auth/service/dio_singleton.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool logged = false;
  String accessToken = "";
  String refreshToken = "";
  bool pointAccount = false;
  late Amount amount;
  late CVU cvu;
  late PointAvailable pointAvailable;
  Map<String, dynamic> token = {};
  late Credential credential;

  @override
  void initState() {
    super.initState();
  }

  authenticate() async {
    try{
      var uri = Uri.parse(dotenv.env['SSO_URL']!);
      var issuer = await Issuer.discover(uri);
      var client = Client(
        issuer,
        dotenv.env['SSO_CLIENT_ID']!,
        clientSecret: dotenv.env['SSO_SECRET']!,
      );


      urlLauncher(String url) async {
        if (await canLaunch(url)) {
          await launch(url, forceWebView: true);
        } else {
          logged = false;
          throw 'Could not launch $url';
        }
      }

      var authenticator = Authenticator(
        client,
        scopes: dotenv.env['SSO_SCOPES']!.split(','),
        port: 4200,
        urlLancher: urlLauncher,
      );

      var c = await authenticator.authorize();
      c.generateLogoutUrl();
      var t = await c.getTokenResponse();
      setState(() {
        credential = c;
        accessToken = t.accessToken.toString();
        refreshToken =  t.refreshToken.toString();
        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        token = decodedToken;
        logged = true;
      });
      Amount am = await getAmount();
      setState(() { amount = am; });
      CVU cv = await getCVU();
      setState(() { cvu = cv; });

      PointAvailable pae = const PointAvailable(point: 0, amount: 0);
      setState(() { pointAvailable = pae; });
      closeWebView();
    }
    catch(ex){
      closeWebView();
    }
  }

  logout() async {
    try {
      String urlEncode = Uri.encodeComponent(dotenv.env['SSO_RETURN_URL']!);
      String keycloakUri = dotenv.env['SSO_URL']!;
      final uri = Uri.parse('$keycloakUri/protocol/openid-connect/logout?redirect_uri=$urlEncode');
      await http.post(uri, headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/x-www-form-urlencoded"
      }, body: {
        "client_id": dotenv.env['SSO_CLIENT_ID']!,
        "client_secret": dotenv.env['SSO_SECRET']!,
        "refresh_token": refreshToken
      }).then((value) {
        token = {};
      });
      setState(() {
        token = {};
        logged = false;
      });
    }
    catch(ex){
      setState(() {
        token = {};
        logged = false;
      });
    }
  }

  callAllServices() async {
    Amount am = await getAmount();
    setState(() { amount = am; });
    CVU cv = await getCVU();
    setState(() { cvu = cv; });
    try {
      PointAvailable pa = await getPointAvailable();
      pointAccount = true;
      setState(() { pointAvailable = pa; });
    } on Exception catch (_) {
      pointAccount = true;
      PointAvailable pae = const PointAvailable(point: 0, amount: 0);
      setState(() { pointAvailable = pae; });
    }
  }

  Future<Amount> getAmount() async {
    final dio = await DioSingleton.getInstance();
    String bricksUri = dotenv.env['BRICKS_URL']!;
    final uri = '${bricksUri}bank/account/amount?currency=ARS';
    var options = Options(headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},);
    Response response = await dio.get(uri, options: options);
    return Amount.fromJson(response.data);
  }

  Future<CVU> getCVU() async {
    final dio = await DioSingleton.getInstance();
    String bricksUri = dotenv.env['BRICKS_URL']!;
    final uri = '${bricksUri}bank/account/cvu?currency=ARS';
    var options = Options(headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},);
    Response response = await dio.get(uri, options: options);
    return CVU.fromJson(response.data);
  }

  Future<PointAvailable> getPointAvailable() async {
    final dio = await DioSingleton.getInstance();
    String brickEdlpCode = dotenv.env['BRICKS_CLIENT_EDLP_CODE']!;
    String bricksUri = dotenv.env['BRICKS_URL']!;
    final uri = '${bricksUri}point/user/available/$brickEdlpCode';
    var options = Options(headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},);
    Response response = await dio.get(uri, options: options);
    return PointAvailable.fromJson(response.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title),
      ),
      body: logged ? Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text("CUENTA BANCARIA", style: TextStyle(fontSize: 20),),
          Card(
            color: Colors.white70,
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(

                child: Column(

                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      logged ? token['dni'] : '',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Text(
                      logged ? token['email'] : '',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      logged ? "Monto: ${amount.amount}" : '',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      logged ? "CVU: ${cvu.cvu}" : '',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      logged ? "Alias: ${cvu.alias}" : '',
                      style: const TextStyle(fontSize: 20),
                    ),

                  ],
                ),
              ),
            ),
          ),


          const Text("PUNTOS", style: TextStyle(fontSize: 20),),
          pointAccount ? Card(
            color: Colors.white70,
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Center(child: Text(
                   "Puntos: ${pointAvailable.point}",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),),
                  Center(child: Text(
                    "Monto: ${pointAvailable.amount}",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),),
                ],
              ),
            ),
          ) : const Card (
            color: Colors.white70,
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("El usuario no tiene puntos"),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(),
              Container(
                height: 50,
                width: 70,
                margin: const EdgeInsets.only(left: 10, right: 10),
                child: ElevatedButton(
                  onPressed: callAllServices,
                  child: const Icon(Icons.refresh,),
                ),
              ),
            ],
          )
        ],
      ) : Container(),
      floatingActionButtonLocation:  FloatingActionButtonLocation.centerFloat,
        floatingActionButton: logged ? Container(
          height: 50,
          margin: const EdgeInsets.only(left: 10, right: 10),
          child: ElevatedButton(
            onPressed: logout,
            child: const Center(
              child: Text('Logout'),
            ),
          ),
        ) : Container(
          height: 50,
          margin: const EdgeInsets.only(left: 10, right: 10),
          child: ElevatedButton(
            onPressed: authenticate,
            child: const Center(
              child: Text('Opera con BRICKS'),
            ),
          ),
        ),

    );
  }
}