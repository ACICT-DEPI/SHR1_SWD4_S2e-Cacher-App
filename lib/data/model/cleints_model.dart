class ClientModel {
  String clientId;
  String clientName;
  String cleintAddress;
  String clientPhone;
  ClientModel({
    required this.clientId,
    required this.clientName,
    required this.cleintAddress,
    required this.clientPhone
  });  

  Map<String,dynamic> toJson(){
    return {
      "client_id": clientId,
      "client_name": clientName,
      "client_address": cleintAddress,
      "client_phone": clientPhone
    };
  }

  factory ClientModel.fromJson(Map<String,dynamic> json){
    return ClientModel(
      clientId: json["client_id"],
      clientName: json["client_name"],
      cleintAddress: json["client_address"],
      clientPhone: json["client_phone"]
    );
  }
}