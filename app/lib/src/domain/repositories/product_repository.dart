import '../entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchProducts(String institutionId);

  Future<Product?> findByGtin(String institutionId, String gtin);

  Future<Product> createProduct(String institutionId, Product product);

  Future<void> updateProduct(String institutionId, Product product);
}
