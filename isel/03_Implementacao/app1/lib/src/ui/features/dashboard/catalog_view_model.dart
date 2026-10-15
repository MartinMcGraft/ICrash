import '../../../common/app_services.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/entities/product.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

/// `null` = "Todos".
typedef CatalogFilter = ProductCategory?;

/// One line of a CSV import, already validated.
class CatalogImportLine {
  const CatalogImportLine({required this.name, this.unitDescription, this.gtin, this.category, this.expiryWarningDays});
  final String name;
  final String? unitDescription;
  final String? gtin;
  final ProductCategory? category;
  final int? expiryWarningDays;
}

class CatalogImportResult {
  const CatalogImportResult({required this.created, required this.skipped});
  final int created;
  final int skipped;
}

/// B5 · Catálogo de consumíveis.
class CatalogViewModel extends ViewModel {
  CatalogViewModel(this.services, this.session) {
    final id = session.institution.id;
    listen(services.products.watchProducts(id), (v) {
      _products = List.of(v)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = LoadState.ready;
      notify();
    }, onError: (_) {
      state = LoadState.error;
      notify();
    });
    listen(services.inventory.watchAllAssignments(id), (v) {
      _assignments = v;
      notify();
    }, onError: (_) {});
  }

  final AppServices services;
  final SessionController session;

  LoadState state = LoadState.loading;
  CatalogFilter filter;
  String query = '';

  List<Product> _products = const [];
  List<CartProductAssignment> _assignments = const [];

  int get total => _products.length;
  int get cartsUsingCatalog => _assignments.map((a) => a.cartId).toSet().length;
  int countOf(ProductCategory category) => _products.where((p) => p.category == category).length;

  /// Number of carts where the product is placed.
  int usedIn(String productId) => _assignments.where((a) => a.productId == productId).map((a) => a.cartId).toSet().length;

  List<Product> get visible {
    final q = query.trim().toLowerCase();
    return _products.where((p) {
      if (filter != null && p.category != filter) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || (p.gtin ?? '').contains(q);
    }).toList();
  }

  void setFilter(CatalogFilter value) {
    filter = value;
    notify();
  }

  void setQuery(String value) {
    query = value;
    notify();
  }

  /// GTINs must be unique in the catalogue (they identify a scanned box).
  bool gtinTaken(String gtin, {String? exceptId}) => _products.any((p) => p.gtin == gtin && p.id != exceptId);

  Future<ActionResult<void>> save(Product product) => run(() async {
        final gtin = product.gtin;
        if (gtin != null && gtinTaken(gtin, exceptId: product.id.isEmpty ? null : product.id)) {
          throw const ActionError('gtinTaken');
        }
        final id = session.institution.id;
        if (product.id.isEmpty) {
          await services.sync.track(services.products.createProduct(id, product));
        } else {
          await services.sync.track(services.products.updateProduct(id, product));
        }
      });

  /// Parses `nome;apresentação;GTIN;categoria;aviso` (comma or semicolon,
  /// optional header). Unknown categories are left empty.
  static List<CatalogImportLine> parseCsv(String text) {
    final lines = <CatalogImportLine>[];
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final sep = line.contains(';') ? ';' : ',';
      final cells = line.split(sep).map((c) => c.trim().replaceAll(RegExp(r'^"|"$'), '')).toList();
      String? cell(int i) => i < cells.length && cells[i].isNotEmpty ? cells[i] : null;
      final name = cell(0);
      if (name == null) continue;
      final lower = name.toLowerCase();
      if (lower == 'nome' || lower == 'name' || lower == 'produto' || lower == 'product') continue;
      lines.add(CatalogImportLine(
        name: name,
        unitDescription: cell(1),
        gtin: cell(2)?.replaceAll(RegExp(r'\s'), ''),
        category: _category(cell(3)),
        expiryWarningDays: int.tryParse(cell(4) ?? ''),
      ));
    }
    return lines;
  }

  static ProductCategory? _category(String? value) {
    final v = value?.toLowerCase();
    if (v == null) return null;
    if (v.startsWith('fárm') || v.startsWith('farm') || v.startsWith('drug')) return ProductCategory.drug;
    if (v.startsWith('mat')) return ProductCategory.material;
    if (v.startsWith('flu')) return ProductCategory.fluid;
    return ProductCategoryCodec.tryFromId(v);
  }

  /// Creates the parsed products, skipping names or GTINs already present.
  Future<ActionResult<CatalogImportResult>> importCsv(String text) => run(() async {
        final institutionId = session.institution.id;
        final names = {for (final p in _products) p.name.toLowerCase()};
        final gtins = {for (final p in _products) if (p.gtin != null) p.gtin!};
        var created = 0;
        var skipped = 0;
        for (final line in parseCsv(text)) {
          if (names.contains(line.name.toLowerCase()) || (line.gtin != null && gtins.contains(line.gtin))) {
            skipped++;
            continue;
          }
          await services.products.createProduct(
            institutionId,
            Product(
              id: '',
              institutionId: institutionId,
              name: line.name,
              unitDescription: line.unitDescription,
              gtin: line.gtin,
              category: line.category,
              expiryWarningDays: line.expiryWarningDays,
            ),
          );
          names.add(line.name.toLowerCase());
          if (line.gtin != null) gtins.add(line.gtin!);
          created++;
        }
        return CatalogImportResult(created: created, skipped: skipped);
      });
}
