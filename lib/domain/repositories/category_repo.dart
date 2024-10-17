abstract class CategoryRepo {
  Future<List<String>> getCategories();
  Future<void> addCategory(String categoryName);
  Future<void> deleteCategory(String categoryName);
}
