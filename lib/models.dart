class Amount {
  final double amount;

  const Amount({
    required this.amount,
  });

  factory Amount.fromJson(Map<String, dynamic> json) {
    return Amount(
      amount: json['amount'],
    );
  }
}

class CVU {
  final String cvu;
  final String alias;

  const CVU({
    required this.cvu,
    required this.alias,
  });

  factory CVU.fromJson(Map<String, dynamic> json) {
    return CVU(
      cvu: json['cvu'],
      alias: json['alias'],
    );
  }
}

class PointAvailable {
  final int point;
  final double amount;

  const PointAvailable({
    required this.point,
    required this.amount,
  });

  factory PointAvailable.fromJson(Map<String, dynamic> json) {
    return PointAvailable(
      point: json['point'],
      amount: json['amount'],
    );
  }
}