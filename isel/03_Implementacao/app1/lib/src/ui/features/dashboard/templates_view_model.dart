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
      templates = List.of(v)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (selectedId == null || !templates.any((t) => t.id == selectedId)) {
        selectedId = templates.firstOrNull?.id;
      }
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
  List<CartTemplate> templates = const [];
  List<Cart> carts = const [];
  String? selectedId;

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

  Future<ActionResult<void>> delete(CartTemplate template) =>
      run(() => services.templates.deleteTemplate(session.institution.id, template.id));

  Future<ActionResult<Cart>> createCart(CartTemplate template, {required String name, String? service, String? location}) =>
      run(() => _useCases.createCartFromTemplate(template: template, name: name, service: service, location: location));
}
