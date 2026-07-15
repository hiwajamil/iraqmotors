import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iq_motors/core/localization/l10n_extensions.dart';
import 'package:iq_motors/features/listings/presentation/add_car_theme.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/shared/data/car_metadata_brand_lookup.dart';
import 'package:iq_motors/shared/data/services/car_metadata_service.dart';
import 'package:iq_motors/shared/domain/models/car_metadata.dart';
import 'package:iq_motors/shared/presentation/providers/car_metadata_providers.dart';
import 'package:iq_motors/shared/widgets/car_network_image.dart';

/// Super-admin Brand → Model → Trim manager for `car_metadata`.
class AdminCarManagementView extends ConsumerStatefulWidget {
  const AdminCarManagementView({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<AdminCarManagementView> createState() =>
      _AdminCarManagementViewState();
}

class _AdminCarManagementViewState
    extends ConsumerState<AdminCarManagementView> {
  static const Color _textPrimary = Color(0xFF1D1D1F);
  static const Color _textSecondary = Color(0xFF86868B);

  String? _selectedBrandId;
  String? _selectedModelName;
  final _searchController = TextEditingController();
  String _query = '';
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CarMetadataService get _service => ref.read(carMetadataServiceProvider);

  String? _canonicalBrandId(CarMetadataCatalog catalog) =>
      catalog.resolveBrandId(_selectedBrandId);

  void _syncSelectedBrandId(CarMetadataCatalog catalog) {
    final canonical = _canonicalBrandId(catalog);
    if (canonical == null || canonical == _selectedBrandId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedBrandId = canonical);
    });
  }

  String? _canonicalModelName(CarMetadataCatalog catalog, String? modelName) {
    final brandId = _canonicalBrandId(catalog);
    if (brandId == null || modelName == null) return null;
    return catalog.resolveModelName(brandId, modelName);
  }

  Future<void> _refresh() async {
    _service.clearCache();
    ref.invalidate(carMetadataProvider);
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await action();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.adminCarMetaSaved),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AddCarTheme.successGreen,
        ),
      );
    } on CarMetadataException catch (e) {
      debugPrint('AdminCarManagement CarMetadataException: ${e.message}');
      if (!mounted) return;
      _showError(e.message);
    } on FirebaseException catch (e) {
      debugPrint(
        'AdminCarManagement FirebaseException: ${e.code} — ${e.message}',
      );
      if (!mounted) return;
      _showError(e.message ?? e.code);
    } catch (e, st) {
      debugPrint('AdminCarManagement mutation error: $e\n$st');
      if (!mounted) return;
      _showError(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  String _friendlyError(Object error) {
    if (error is CarMetadataException) return error.message;
    if (error is FirebaseException) return error.message ?? error.code;

    try {
      final dynamic boxed = error;
      final inner = boxed.error;
      if (inner != null && !identical(inner, error)) {
        return _friendlyError(inner as Object);
      }
      final message = boxed.message;
      if (message is String &&
          message.trim().isNotEmpty &&
          !message.contains('Dart exception thrown from converted Future')) {
        return message;
      }
    } catch (_) {
      // Not a boxed web Future error.
    }

    final text = error.toString();
    if (text.contains('Dart exception thrown from converted Future')) {
      return 'Firestore write failed. See browser console for details.';
    }
    return text;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF3B30),
      ),
    );
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    String initial = '',
    String? confirmLabel,
  }) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: AddCarTheme.textFieldDecoration(hintText: hint),
          onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(confirmLabel ?? l10n.adminCarMetaSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<bool> _confirmDelete(String message) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteAction),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _addBrand() async {
    final l10n = context.l10n;
    final name = await _promptText(
      title: l10n.adminCarMetaAddBrand,
      hint: l10n.adminCarMetaBrandIdHint,
      confirmLabel: l10n.adminCarMetaAdd,
    );
    if (name == null) return;
    await _runMutation(() => _service.createBrand(name));
  }

  Future<void> _editBrand(String brandId) async {
    final l10n = context.l10n;
    final name = await _promptText(
      title: l10n.adminCarMetaEditBrand,
      hint: l10n.adminCarMetaBrandIdHint,
      initial: brandId,
      confirmLabel: l10n.adminCarMetaSave,
    );
    if (name == null || name == brandId) return;
    await _runMutation(() async {
      await _service.renameBrand(oldBrandId: brandId, newBrandId: name);
      if (_selectedBrandId == brandId) {
        setState(() {
          // Keep the same casing used as the Firestore document id.
          _selectedBrandId = name.trim().replaceAll(RegExp(r'\s+'), '_');
        });
      }
    });
  }

  Future<void> _deleteBrand(String brandId) async {
    final l10n = context.l10n;
    final label = metadataBrandLabel(
      brandId,
      Localizations.localeOf(context).languageCode,
    );
    final ok = await _confirmDelete(
      l10n.adminCarMetaDeleteBrandConfirm(label),
    );
    if (!ok) return;
    await _runMutation(() async {
      await _service.deleteBrand(brandId);
      if (_selectedBrandId == brandId) {
        setState(() {
          _selectedBrandId = null;
          _selectedModelName = null;
        });
      }
    });
  }

  Future<void> _addModel() async {
    final catalog = ref.read(carMetadataProvider).value;
    if (catalog == null) return;
    final brandId = _canonicalBrandId(catalog);
    if (brandId == null) return;
    final l10n = context.l10n;
    final name = await _promptText(
      title: l10n.adminCarMetaAddModel,
      hint: l10n.adminCarMetaModelNameHint,
      confirmLabel: l10n.adminCarMetaAdd,
    );
    if (name == null) return;
    await _runMutation(
      () => _service.createModel(brandId: brandId, modelName: name),
    );
  }

  Future<void> _editModel(String modelName) async {
    final catalog = ref.read(carMetadataProvider).value;
    if (catalog == null) return;
    final brandId = _canonicalBrandId(catalog);
    if (brandId == null) return;
    final resolvedModel = _canonicalModelName(catalog, modelName) ?? modelName;
    final l10n = context.l10n;
    final name = await _promptText(
      title: l10n.adminCarMetaEditModel,
      hint: l10n.adminCarMetaModelNameHint,
      initial: resolvedModel,
    );
    if (name == null || name == resolvedModel) return;
    await _runMutation(() async {
      await _service.renameModel(
        brandId: brandId,
        oldModelName: resolvedModel,
        newModelName: name,
      );
      if (_selectedModelName == modelName || _selectedModelName == resolvedModel) {
        setState(() => _selectedModelName = name.trim());
      }
    });
  }

  Future<void> _deleteModel(String modelName) async {
    final catalog = ref.read(carMetadataProvider).value;
    if (catalog == null) return;
    final brandId = _canonicalBrandId(catalog);
    if (brandId == null) return;
    final resolvedModel = _canonicalModelName(catalog, modelName) ?? modelName;
    final l10n = context.l10n;
    final ok = await _confirmDelete(
      l10n.adminCarMetaDeleteModelConfirm(resolvedModel),
    );
    if (!ok) return;
    await _runMutation(() async {
      await _service.deleteModel(brandId: brandId, modelName: resolvedModel);
      if (_selectedModelName == modelName || _selectedModelName == resolvedModel) {
        setState(() => _selectedModelName = null);
      }
    });
  }

  Future<void> _addTrim() async {
    final catalog = ref.read(carMetadataProvider).value;
    if (catalog == null) return;
    final brandId = _canonicalBrandId(catalog);
    final modelName = _canonicalModelName(catalog, _selectedModelName);
    if (brandId == null || modelName == null) return;
    final l10n = context.l10n;
    final name = await _promptText(
      title: l10n.adminCarMetaAddTrim,
      hint: l10n.adminCarMetaTrimNameHint,
      confirmLabel: l10n.adminCarMetaAdd,
    );
    if (name == null) return;
    await _runMutation(
      () => _service.createTrim(
        brandId: brandId,
        modelName: modelName,
        trimName: name,
      ),
    );
  }

  Future<void> _editTrim(String trimName) async {
    final catalog = ref.read(carMetadataProvider).value;
    if (catalog == null) return;
    final brandId = _canonicalBrandId(catalog);
    final modelName = _canonicalModelName(catalog, _selectedModelName);
    if (brandId == null || modelName == null) return;
    final l10n = context.l10n;
    final name = await _promptText(
      title: l10n.adminCarMetaEditTrim,
      hint: l10n.adminCarMetaTrimNameHint,
      initial: trimName,
    );
    if (name == null || name == trimName) return;
    await _runMutation(
      () => _service.renameTrim(
        brandId: brandId,
        modelName: modelName,
        oldTrimName: trimName,
        newTrimName: name,
      ),
    );
  }

  Future<void> _deleteTrim(String trimName) async {
    final catalog = ref.read(carMetadataProvider).value;
    if (catalog == null) return;
    final brandId = _canonicalBrandId(catalog);
    final modelName = _canonicalModelName(catalog, _selectedModelName);
    if (brandId == null || modelName == null) return;
    final l10n = context.l10n;
    final ok = await _confirmDelete(
      l10n.adminCarMetaDeleteTrimConfirm(trimName),
    );
    if (!ok) return;
    await _runMutation(
      () => _service.deleteTrim(
        brandId: brandId,
        modelName: modelName,
        trimName: trimName,
      ),
    );
  }

  List<CarMetadataBrand> _filteredBrands(
    CarMetadataCatalog catalog,
    String languageCode,
  ) {
    final brands = catalog.sortedBrands;
    if (_query.isEmpty) return brands;
    return brands.where((brand) {
      final label = metadataBrandLabel(brand.id, languageCode).toLowerCase();
      return brand.id.toLowerCase().contains(_query) || label.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final catalogAsync = ref.watch(carMetadataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.navCarManagement,
          style: TextStyle(
            fontSize: widget.isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminCarMetaSubtitle,
          style: const TextStyle(fontSize: 14, color: _textSecondary),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: catalogAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (error, _) => _ErrorState(
              message: error.toString(),
              retryLabel: l10n.adminRetry,
              onRetry: _refresh,
            ),
            data: (catalog) {
              _syncSelectedBrandId(catalog);
              final resolvedBrandId = _canonicalBrandId(catalog);
              final selectedBrand = resolvedBrandId == null
                  ? null
                  : catalog.brands[resolvedBrandId];
              final models = selectedBrand?.sortedModelNames ?? const [];
              final resolvedModelName =
                  _canonicalModelName(catalog, _selectedModelName);
              final selectedModelExists = resolvedModelName != null &&
                  (selectedBrand?.models.containsKey(resolvedModelName) ??
                      false);
              final trims = selectedModelExists
                  ? selectedBrand!.trimsFor(resolvedModelName)
                  : const <String>[];

              final brands = _filteredBrands(catalog, languageCode);

              if (widget.isMobile) {
                return _MobileDrillDown(
                  l10n: l10n,
                  languageCode: languageCode,
                  brands: brands,
                  models: models,
                  trims: trims,
                  selectedBrandId: resolvedBrandId,
                  selectedModelName:
                      selectedModelExists ? resolvedModelName : null,
                  searchController: _searchController,
                  isMutating: _isMutating,
                  onSelectBrand: (id) => setState(() {
                    _selectedBrandId = id;
                    _selectedModelName = null;
                  }),
                  onSelectModel: (name) =>
                      setState(() => _selectedModelName = name),
                  onClearBrand: () => setState(() {
                    _selectedBrandId = null;
                    _selectedModelName = null;
                  }),
                  onClearModel: () => setState(() => _selectedModelName = null),
                  onAddBrand: _addBrand,
                  onEditBrand: _editBrand,
                  onDeleteBrand: _deleteBrand,
                  onAddModel: _addModel,
                  onEditModel: _editModel,
                  onDeleteModel: _deleteModel,
                  onAddTrim: _addTrim,
                  onEditTrim: _editTrim,
                  onDeleteTrim: _deleteTrim,
                  onRefresh: _refresh,
                );
              }

              return _DesktopTriplePane(
                l10n: l10n,
                languageCode: languageCode,
                brands: brands,
                models: models,
                trims: trims,
                selectedBrandId: resolvedBrandId,
                selectedModelName:
                    selectedModelExists ? resolvedModelName : null,
                searchController: _searchController,
                isMutating: _isMutating,
                onSelectBrand: (id) => setState(() {
                  _selectedBrandId = id;
                  _selectedModelName = null;
                }),
                onSelectModel: (name) =>
                    setState(() => _selectedModelName = name),
                onAddBrand: _addBrand,
                onEditBrand: _editBrand,
                onDeleteBrand: _deleteBrand,
                onAddModel: _addModel,
                onEditModel: _editModel,
                onDeleteModel: _deleteModel,
                onAddTrim: _addTrim,
                onEditTrim: _editTrim,
                onDeleteTrim: _deleteTrim,
                onRefresh: _refresh,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DesktopTriplePane extends StatelessWidget {
  const _DesktopTriplePane({
    required this.l10n,
    required this.languageCode,
    required this.brands,
    required this.models,
    required this.trims,
    required this.selectedBrandId,
    required this.selectedModelName,
    required this.searchController,
    required this.isMutating,
    required this.onSelectBrand,
    required this.onSelectModel,
    required this.onAddBrand,
    required this.onEditBrand,
    required this.onDeleteBrand,
    required this.onAddModel,
    required this.onEditModel,
    required this.onDeleteModel,
    required this.onAddTrim,
    required this.onEditTrim,
    required this.onDeleteTrim,
    required this.onRefresh,
  });

  final AppLocalizations l10n;
  final String languageCode;
  final List<CarMetadataBrand> brands;
  final List<String> models;
  final List<String> trims;
  final String? selectedBrandId;
  final String? selectedModelName;
  final TextEditingController searchController;
  final bool isMutating;
  final ValueChanged<String> onSelectBrand;
  final ValueChanged<String> onSelectModel;
  final VoidCallback onAddBrand;
  final ValueChanged<String> onEditBrand;
  final ValueChanged<String> onDeleteBrand;
  final VoidCallback onAddModel;
  final ValueChanged<String> onEditModel;
  final ValueChanged<String> onDeleteModel;
  final VoidCallback onAddTrim;
  final ValueChanged<String> onEditTrim;
  final ValueChanged<String> onDeleteTrim;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _PaneCard(
            title: l10n.addCarBrandLabel,
            count: brands.length,
            onAdd: isMutating ? null : onAddBrand,
            addLabel: l10n.adminCarMetaAddBrand,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: AddCarTheme.textFieldDecoration(
                    hintText: l10n.adminCarMetaSearchBrands,
                  ).copyWith(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF86868B),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: onRefresh,
                    child: brands.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: 160,
                                child: _EmptyHint(
                                  message: l10n.adminCarMetaNoBrands,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: brands.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final brand = brands[index];
                              return _BrandRow(
                                brandId: brand.id,
                                label: metadataBrandLabel(
                                  brand.id,
                                  languageCode,
                                ),
                                selected: brand.id == selectedBrandId,
                                modelsLabel: l10n.adminCarMetaModelsCount(
                                  brand.models.length,
                                ),
                                onTap: () => onSelectBrand(brand.id),
                                onEdit: () => onEditBrand(brand.id),
                                onDelete: () => onDeleteBrand(brand.id),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PaneCard(
            title: l10n.addCarModelLabel,
            count: selectedBrandId == null ? null : models.length,
            onAdd:
                selectedBrandId == null || isMutating ? null : onAddModel,
            addLabel: l10n.adminCarMetaAddModel,
            child: selectedBrandId == null
                ? _EmptyHint(message: l10n.adminCarMetaSelectBrand)
                : models.isEmpty
                    ? _EmptyHint(message: l10n.adminCarMetaNoModels)
                    : ListView.separated(
                        itemCount: models.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final model = models[index];
                          return _SimpleRow(
                            title: model,
                            selected: model == selectedModelName,
                            onTap: () => onSelectModel(model),
                            onEdit: () => onEditModel(model),
                            onDelete: () => onDeleteModel(model),
                          );
                        },
                      ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PaneCard(
            title: l10n.addCarTrimLabel,
            count: selectedModelName == null ? null : trims.length,
            onAdd:
                selectedModelName == null || isMutating ? null : onAddTrim,
            addLabel: l10n.adminCarMetaAddTrim,
            child: selectedModelName == null
                ? _EmptyHint(message: l10n.adminCarMetaSelectModel)
                : trims.isEmpty
                    ? _EmptyHint(message: l10n.adminCarMetaNoTrims)
                    : ListView.separated(
                        itemCount: trims.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final trim = trims[index];
                          return _SimpleRow(
                            title: trim,
                            selected: false,
                            onTap: null,
                            onEdit: () => onEditTrim(trim),
                            onDelete: () => onDeleteTrim(trim),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

class _MobileDrillDown extends StatelessWidget {
  const _MobileDrillDown({
    required this.l10n,
    required this.languageCode,
    required this.brands,
    required this.models,
    required this.trims,
    required this.selectedBrandId,
    required this.selectedModelName,
    required this.searchController,
    required this.isMutating,
    required this.onSelectBrand,
    required this.onSelectModel,
    required this.onClearBrand,
    required this.onClearModel,
    required this.onAddBrand,
    required this.onEditBrand,
    required this.onDeleteBrand,
    required this.onAddModel,
    required this.onEditModel,
    required this.onDeleteModel,
    required this.onAddTrim,
    required this.onEditTrim,
    required this.onDeleteTrim,
    required this.onRefresh,
  });

  final AppLocalizations l10n;
  final String languageCode;
  final List<CarMetadataBrand> brands;
  final List<String> models;
  final List<String> trims;
  final String? selectedBrandId;
  final String? selectedModelName;
  final TextEditingController searchController;
  final bool isMutating;
  final ValueChanged<String> onSelectBrand;
  final ValueChanged<String> onSelectModel;
  final VoidCallback onClearBrand;
  final VoidCallback onClearModel;
  final VoidCallback onAddBrand;
  final ValueChanged<String> onEditBrand;
  final ValueChanged<String> onDeleteBrand;
  final VoidCallback onAddModel;
  final ValueChanged<String> onEditModel;
  final ValueChanged<String> onDeleteModel;
  final VoidCallback onAddTrim;
  final ValueChanged<String> onEditTrim;
  final ValueChanged<String> onDeleteTrim;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (selectedBrandId == null) {
      return _PaneCard(
        title: l10n.addCarBrandLabel,
        count: brands.length,
        onAdd: isMutating ? null : onAddBrand,
        addLabel: l10n.adminCarMetaAddBrand,
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: AddCarTheme.textFieldDecoration(
                hintText: l10n.adminCarMetaSearchBrands,
              ).copyWith(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF86868B),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: brands.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: 160,
                            child: _EmptyHint(
                              message: l10n.adminCarMetaNoBrands,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        itemCount: brands.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final brand = brands[index];
                          return _BrandRow(
                            brandId: brand.id,
                            label: metadataBrandLabel(brand.id, languageCode),
                            selected: false,
                            modelsLabel: l10n.adminCarMetaModelsCount(
                              brand.models.length,
                            ),
                            onTap: () => onSelectBrand(brand.id),
                            onEdit: () => onEditBrand(brand.id),
                            onDelete: () => onDeleteBrand(brand.id),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      );
    }

    if (selectedModelName == null) {
      return _PaneCard(
        title: metadataBrandLabel(selectedBrandId!, languageCode),
        count: models.length,
        onAdd: isMutating ? null : onAddModel,
        addLabel: l10n.adminCarMetaAddModel,
        leading: IconButton(
          onPressed: onClearBrand,
          icon: const Icon(Icons.arrow_back),
        ),
        child: models.isEmpty
            ? _EmptyHint(message: l10n.adminCarMetaNoModels)
            : ListView.separated(
                itemCount: models.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final model = models[index];
                  return _SimpleRow(
                    title: model,
                    selected: false,
                    trailingChevron: true,
                    onTap: () => onSelectModel(model),
                    onEdit: () => onEditModel(model),
                    onDelete: () => onDeleteModel(model),
                  );
                },
              ),
      );
    }

    return _PaneCard(
      title: selectedModelName!,
      count: trims.length,
      onAdd: isMutating ? null : onAddTrim,
      addLabel: l10n.adminCarMetaAddTrim,
      leading: IconButton(
        onPressed: onClearModel,
        icon: const Icon(Icons.arrow_back),
      ),
      child: trims.isEmpty
          ? _EmptyHint(message: l10n.adminCarMetaNoTrims)
          : ListView.separated(
              itemCount: trims.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final trim = trims[index];
                return _SimpleRow(
                  title: trim,
                  selected: false,
                  onTap: null,
                  onEdit: () => onEditTrim(trim),
                  onDelete: () => onDeleteTrim(trim),
                );
              },
            ),
    );
  }
}

class _PaneCard extends StatelessWidget {
  const _PaneCard({
    required this.title,
    required this.child,
    this.count,
    this.onAdd,
    this.addLabel,
    this.leading,
  });

  final String title;
  final Widget child;
  final int? count;
  final VoidCallback? onAdd;
  final String? addLabel;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AddCarTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leading != null) leading!,
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    style: AddCarTheme.sectionTitle.copyWith(fontSize: 18),
                    children: [
                      if (count != null)
                        TextSpan(
                          text: ' ($count)',
                          style: AddCarTheme.stepSubtitle.copyWith(
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (onAdd != null)
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(addLabel ?? ''),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({
    required this.brandId,
    required this.label,
    required this.selected,
    required this.modelsLabel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final String brandId;
  final String label;
  final bool selected;
  final String modelsLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final brand = carBrandFromMetadataId(brandId);
    return Material(
      color: selected ? const Color(0xFFF2F2F7) : AddCarTheme.inputFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AddCarTheme.textPrimary : AddCarTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _BrandLogo(logoUrl: brand.logoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AddCarTheme.sectionLabel),
                    const SizedBox(height: 2),
                    Text(
                      modelsLabel,
                      style: AddCarTheme.stepSubtitle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              _RowActions(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  const _SimpleRow({
    required this.title,
    required this.selected,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.trailingChevron = false,
  });

  final String title;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool trailingChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF2F2F7) : AddCarTheme.inputFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AddCarTheme.textPrimary : AddCarTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: AddCarTheme.sectionLabel),
              ),
              _RowActions(onEdit: onEdit, onDelete: onDelete),
              if (trailingChevron)
                const Icon(Icons.chevron_right, color: Color(0xFF86868B)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.l10n.editAction,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AddCarTheme.textSecondary,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: context.l10n.deleteAction,
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 18),
          color: const Color(0xFFFF3B30),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.logoUrl});

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AddCarTheme.border),
      ),
      padding: const EdgeInsets.all(6),
      child: logoUrl.isEmpty
          ? const Icon(Icons.directions_car_outlined, size: 20)
          : CarNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
            ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AddCarTheme.stepSubtitle.copyWith(fontSize: 14),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
