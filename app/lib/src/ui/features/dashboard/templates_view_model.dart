import '../../../common/app_services.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_template.dart';
import '../../../domain/use_cases/cart_templates.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

/// B6 · Modelos de carrinho.
class TemplatesViewModel extends ViewModel {
  TemplatesViewModel(this.services, this.session) {
    final id = session.institution.id;
    listen(services.templates.watchTemplates(id), (v) {
      _all = List.of(v)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _keepSelection();
      state = LoadState.ready;
      notify();
    }, onError: (_) {
      state = LoadState.error;
      notify();
    });
    listen(services.carts.watchAccessibleCarts(id), (v) {
      carts = v.where((c) => !c.archived).toList()..sort((a, b) => a.name.compareTo(b.name));
      notify();
    }, onError: (_) {});
  }

  final AppServices services;
  final SessionController session;

  LoadState state = LoadState.loading;
  List<CartTemplate> _all = const [];
  List<Cart> carts = const [];
  String? selectedId;

  /// P3: "Ativos" or "Arquivados".
  bool showArchived = false;

  /// The templates in the current tab.
  List<CartTemplate> get templates => _all.where((t) => t.archived == showArchived).toList();

  /// Templates offered when creating a cart (archived ones never are).
  List<CartTemplate> get activeTemplates => _all.where((t) => !t.archived).toList();

  int get archivedCount => _all.where((t) => t.archived).length;

  void _keepSelection() {
    final visible = templates;
    if (selectedId == null || !visible.any((t) => t.id == selectedId)) {
      selectedId = visible.firstOrNull?.id;
    }
  }

  void setShowArchived(bool value) {
    showArchived = value;
    selectedId = null;
    _keepSelection();
    notify();
  }

  CartTemplateUseCases get _useCases =>
      CartTemplateUseCases(carts: services.carts, drawers: services.drawers, inventory: services.inventory);

  CartTemplate? get selected => templates.where((t) => t.id == selectedId).firstOrNull;

  int usageOf(String templateId) => carts.where((c) => c.templateId == templateId).length;

  void select(String id) {
    selectedId = id;
    notify();
  }

  /// "Novo modelo": captures the structure and target quantities of a cart.
  Future<ActionResult<CartTemplate>> createFromCart({required String cartId, required String name}) => run(() async {
        final draft = await _useCases.templateFromCart(
          institutionId: session.institution.id,
          cartId: cartId,
          name: name,
          updatedByName: session.myName,
        );
        final saved = await services.templates.saveTemplate(draft);
        selectedId = saved.id;
        return saved;
      });

  /// "Duplicar".
  Future<ActionResult<CartTemplate>> duplicate(CartTemplate template, {required String name}) => run(() async {
        final saved = await services.templates
            .saveTemplate(template.copyWith(id: '', name: name, updatedAt: DateTime.now(), updatedByName: session.myName));
        selectedId = saved.id;
        return saved;
      });

  /// "Editar modelo": rename and, optionally, re-capture from a cart.
  Future<ActionResult<void>> update(CartTemplate template, {required String name, String? refreshFromCartId}) => run(() async {
        var next = template.copyWith(name: name, updatedAt: DateTime.now(), updatedByName: session.myName);
        if (refreshFromCartId != null) {
          final captured = await _useCases.templateFromCart(
            institutionId: session.institution.id,
            cartId: refreshFromCartId,
            name: name,
            updatedByName: session.myName,
          );
          next = next.copyWith(drawers: captured.drawers);
        }
        await services.templates.saveTemplate(next);
      });

  /// "Arquivar modelo" (P3: never deleted). Carts already made from it keep
  /// their structure.
  Future<ActionResult<void>> archive(CartTemplate template) =>
      run(() => services.templates.setArchived(session.institution.id, template.id, archived: true));

  /// "Restaurar modelo".
  Future<ActionResult<void>> restore(CartTemplate template) =>
      run(() => services.templates.setArchived(session.institution.id, template.id, archived: false));

  /// Error code `templateArchived`: an archived template can't make new carts.
  Future<ActionResult<Cart>> createCart(CartTemplate template, {required String name, String? service, String? location}) =>
      run(() async {
        if (template.archived) throw const ActionError('templateArchived');
        return _useCases.createCartFromTemplate(template: template, name: name, service: service, location: location);
      });
}
