import '../../data/model/operation_model.dart';

abstract class OperationRepo {
  Future<void> logOperation(String type, String description,
      String oldInvoiceId, String newInvoiceId);
  Future<List<Operation>> getOperations();
  Future<List<Operation>> getOperationsSinceInstallation();
}
