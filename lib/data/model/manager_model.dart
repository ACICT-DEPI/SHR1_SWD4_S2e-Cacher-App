class ManagerModel {
  String? email;
  String? name;
  String? password;
  String? logoPath;

  ManagerModel(
      {required this.email, required this.name,required this.password, required this.logoPath});

  factory ManagerModel.fromJson(Map<String, dynamic> json) {
    return ManagerModel(
      email: json['manager_email'],
      name: json['manager_name'],
      password: json['manager_password'],
      logoPath: json['manager_logo'],
    );
  }

  Map<String, dynamic> toJson(managerAuthId) {
    return {
      'managerId': managerAuthId,
      'manager_email': email,
      'manager_name': name,
      'manager_password': password,
      'manager_logo': logoPath
    };
  }
}
