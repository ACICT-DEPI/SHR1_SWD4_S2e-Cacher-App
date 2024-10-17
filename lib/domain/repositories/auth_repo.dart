import 'package:image_picker/image_picker.dart';

import '../../data/model/manager_model.dart';

abstract class AuthRepo {
  Future<void> register(
    ManagerModel managerModel,
    XFile? selectedLogo,
  );
  Future<void> login(String email, String password);
  Future<ManagerModel?> fetchManagerData();
  Future<void> logout();
  Future<void> updateLogo(XFile newLogo);
  Future<void> updateName(String newName);
}
