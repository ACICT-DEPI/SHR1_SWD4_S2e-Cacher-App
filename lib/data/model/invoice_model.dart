import 'cleints_model.dart';
import 'product_model.dart';

class Invoice {
  final String invoiceId;
  ClientModel? clientModel;
  final String paidUp;
  final String paymentMethod;
  final String discount;
  final String firstDiscount;
  final int numOfBuyings;
  late final double totalCoast;
  final String managerId;
  final String logoUrl;
  final List<Product> products;
  final DateTime date;
  DateTime? trashDate;
  String?
      oldProductId; // Link to the original product if this invoice contains a replacement
  String?
      replacedinvoiceId; // Link to the replacement product if this invoice contains an original product
  String? movedToInvoice;

  Invoice(
      {required this.invoiceId,
      required this.clientModel,
      required this.paidUp,
      required this.paymentMethod,
      required this.firstDiscount,
      required this.discount,
      required this.numOfBuyings,
      required this.totalCoast,
      required this.managerId,
      required this.logoUrl,
      required this.products,
      required this.date,
      this.trashDate,
      this.oldProductId, // Add this
      this.replacedinvoiceId, // Add this
      this.movedToInvoice});

  Map<String, dynamic> toJson() => {
        'invoiceId': invoiceId,
        'clientInfo': clientModel?.toJson(),
        'paidUp': paidUp,
        'paymentMethod': paymentMethod,
        'firstDiscount': firstDiscount,
        'discount': discount,
        'numOfBuyings': numOfBuyings,
        'totalCoast': totalCoast,
        'managerId': managerId,
        'logoUrl': logoUrl,
        'products': products.map((product) => product.toJson()).toList(),
        'date': date.toIso8601String(),
        'trashDate': trashDate?.toIso8601String(),
        'oldProductId': oldProductId, // Add this
        'replacedinvoiceId': replacedinvoiceId, //
        'movedToInvoice': movedToInvoice
      };

  static Invoice fromJson(Map<String, dynamic> json) => Invoice(
        invoiceId: json['invoiceId'],
        clientModel: json['clientInfo'] != null
            ? ClientModel.fromJson(json['clientInfo'])
            : null,
        paidUp: json['paidUp'],
        paymentMethod: json['paymentMethod'],
        firstDiscount: json['firstDiscount'],
        discount: json['discount'],
        numOfBuyings: json['numOfBuyings'],
        totalCoast: json['totalCoast'],
        managerId: json['managerId'],
        logoUrl: json['logoUrl'],
        products: List<Product>.from(
            json['products'].map((item) => Product.fromJson(item))),
        date: DateTime.parse(json['date']),
        trashDate: json['trashDate'] != null
            ? DateTime.parse(json['trashDate'])
            : null,
        oldProductId: json['oldProductId'],
        replacedinvoiceId: json['replacedinvoiceId'],
        movedToInvoice: json['movedToInvoice']
      );
}
