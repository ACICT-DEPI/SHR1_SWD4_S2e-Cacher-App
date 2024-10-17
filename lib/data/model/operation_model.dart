class Operation {
  final String id;
  final String type;
  final String description;
  String? oldInvoice;
  String? newInvoice;
  final DateTime date;

  Operation({
    required this.id,
    required this.type,
    required this.description,
    this.oldInvoice,
    this.newInvoice,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'oldInvoice': oldInvoice,
      'newInvoice': newInvoice,
      'date': date.toIso8601String(),
    };
  }

  static Operation fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'],
      type: json['type'],
      description: json['description'],
      oldInvoice: json['oldInvoice'],
      newInvoice: json['newInvoice'],
      date: DateTime.parse(json['date']),
    );
  }
}
