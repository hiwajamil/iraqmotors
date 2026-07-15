import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:iq_motors/shared/domain/models/car_metadata.dart';

class CarMetadataException implements Exception {
  CarMetadataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches and mutates brand → model → trim metadata in Firestore.
///
/// Documents live in [collectionName]. Each document id is a brand id; the
/// `models` field is a map of model name → list of trim strings:
/// ```json
/// { "models": { "Land Cruiser": ["GXR", "VXR"], "Camry": ["LE"] } }
/// ```
class CarMetadataService {
  CarMetadataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'car_metadata';
  static const String modelsField = 'models';

  CarMetadataCatalog? _sessionCache;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Returns cached metadata when available; otherwise loads once per session.
  Future<CarMetadataCatalog> loadCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _sessionCache != null) {
      return _sessionCache!;
    }

    try {
      final snapshot = await _collection.get();
      final brands = <String, CarMetadataBrand>{};

      for (final doc in snapshot.docs) {
        final models = _parseModels(doc.data()[modelsField]);
        brands[doc.id] = CarMetadataBrand(id: doc.id, models: models);
      }

      _sessionCache = CarMetadataCatalog(brands: brands);
      return _sessionCache!;
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.loadCatalog FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to load car metadata (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.loadCatalog error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  void clearCache() => _sessionCache = null;

  Future<CarMetadataCatalog> refreshCatalog() =>
      loadCatalog(forceRefresh: true);

  /// Resolves a brand id to the canonical Firestore document id.
  Future<String> _resolveBrandDocId(String brandId) async {
    final normalized = _normalizeId(brandId, label: 'Brand');
    final catalog = await loadCatalog();
    final resolved = catalog.resolveBrandId(normalized);
    if (resolved != null) return resolved;

    // Fallback: scan the live collection in case the session cache is stale.
    final snapshot = await _collection.get();
    final lower = normalized.toLowerCase();
    for (final doc in snapshot.docs) {
      if (doc.id.toLowerCase() == lower) return doc.id;
    }
    return normalized;
  }

  Future<DocumentReference<Map<String, dynamic>>> _brandRef(String brandId) async {
    final docId = await _resolveBrandDocId(brandId);
    return _collection.doc(docId);
  }

  // ── Brands ──────────────────────────────────────────────────────────────

  /// Creates a brand document. [brandId] becomes the Firestore document id.
  Future<void> createBrand(String brandId) async {
    final id = _normalizeId(brandId, label: 'Brand');
    try {
      final ref = _collection.doc(id);
      final existing = await ref.get();
      if (existing.exists) {
        throw CarMetadataException('Brand "$id" already exists.');
      }
      await ref.set(<String, dynamic>{modelsField: <String, dynamic>{}});
      clearCache();
    } on CarMetadataException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.createBrand FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to create brand (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.createBrand error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  /// Renames a brand by copying its models map to a new document id.
  Future<void> renameBrand({
    required String oldBrandId,
    required String newBrandId,
  }) async {
    final from = _normalizeId(oldBrandId, label: 'Brand');
    final to = _normalizeId(newBrandId, label: 'Brand');
    if (from == to) return;

    try {
      final fromRef = _collection.doc(from);
      final toRef = _collection.doc(to);
      final fromSnap = await fromRef.get();
      if (!fromSnap.exists) {
        throw CarMetadataException('Brand "$from" was not found.');
      }
      final toSnap = await toRef.get();
      if (toSnap.exists) {
        throw CarMetadataException('Brand "$to" already exists.');
      }

      final models = _parseModels(fromSnap.data()?[modelsField]);
      final batch = _firestore.batch();
      batch.set(toRef, <String, dynamic>{
        modelsField: _modelsToFirestoreMap(models),
      });
      batch.delete(fromRef);
      await batch.commit();
      clearCache();
    } on CarMetadataException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.renameBrand FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to rename brand (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.renameBrand error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  Future<void> deleteBrand(String brandId) async {
    final id = _normalizeId(brandId, label: 'Brand');
    try {
      await _collection.doc(id).delete();
      clearCache();
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.deleteBrand FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to delete brand (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.deleteBrand error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  // ── Models ──────────────────────────────────────────────────────────────

  Future<void> createModel({
    required String brandId,
    required String modelName,
    List<String> trims = const [],
  }) async {
    final model = _normalizeLabel(modelName, label: 'Model');
    final normalizedTrims = _normalizeTrimList(trims);

    try {
      final ref = await _brandRef(brandId);
      final brand = ref.id;
      final snap = await ref.get();
      if (!snap.exists) {
        throw CarMetadataException('Brand "$brand" was not found.');
      }

      final models = _parseModels(snap.data()?[modelsField]);
      if (models.containsKey(model)) {
        throw CarMetadataException('Model "$model" already exists.');
      }

      // Nested field path so model names with spaces (e.g. "Land Cruiser")
      // update correctly without rewriting the whole map.
      await ref.set(
        <String, dynamic>{
          modelsField: <String, dynamic>{
            model: normalizedTrims,
          },
        },
        SetOptions(merge: true),
      );
      clearCache();
    } on CarMetadataException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.createModel FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to create model (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.createModel error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  Future<void> renameModel({
    required String brandId,
    required String oldModelName,
    required String newModelName,
  }) async {
    final to = _normalizeLabel(newModelName, label: 'Model');

    try {
      final ref = await _brandRef(brandId);
      final brand = ref.id;
      final snap = await ref.get();
      if (!snap.exists) {
        throw CarMetadataException('Brand "$brand" was not found.');
      }

      final models = _parseModels(snap.data()?[modelsField]);
      final from = _resolveModelKey(models, oldModelName, label: 'Model');
      if (from == to) return;
      if (!models.containsKey(from)) {
        throw CarMetadataException('Model "$from" was not found.');
      }
      if (models.containsKey(to)) {
        throw CarMetadataException('Model "$to" already exists.');
      }

      final trims = List<String>.from(models[from]!);
      await ref.update(<Object, Object?>{
        FieldPath([modelsField, to]): trims,
        FieldPath([modelsField, from]): FieldValue.delete(),
      });
      clearCache();
    } on CarMetadataException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.renameModel FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to rename model (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.renameModel error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  Future<void> deleteModel({
    required String brandId,
    required String modelName,
  }) async {
    try {
      final ref = await _brandRef(brandId);
      final brand = ref.id;
      final snap = await ref.get();
      if (!snap.exists) {
        throw CarMetadataException('Brand "$brand" was not found.');
      }

      final models = _parseModels(snap.data()?[modelsField]);
      final model = _resolveModelKey(models, modelName, label: 'Model');
      if (!models.containsKey(model)) {
        throw CarMetadataException('Model "$model" was not found.');
      }

      await ref.update(<Object, Object?>{
        FieldPath([modelsField, model]): FieldValue.delete(),
      });
      clearCache();
    } on CarMetadataException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.deleteModel FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to delete model (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.deleteModel error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  // ── Trims ───────────────────────────────────────────────────────────────

  Future<void> createTrim({
    required String brandId,
    required String modelName,
    required String trimName,
  }) async {
    final trim = _normalizeLabel(trimName, label: 'Trim');

    try {
      final ref = await _brandRef(brandId);
      final brand = ref.id;
      final snap = await ref.get();
      if (!snap.exists) {
        throw CarMetadataException('Brand "$brand" was not found.');
      }

      final models = _parseModels(snap.data()?[modelsField]);
      final model = _resolveModelKey(models, modelName, label: 'Model');
      if (!models.containsKey(model)) {
        throw CarMetadataException('Model "$model" was not found.');
      }

      final existing = models[model] ?? const <String>[];
      if (existing.any((t) => t.toLowerCase() == trim.toLowerCase())) {
        throw CarMetadataException('Trim "$trim" already exists.');
      }

      // arrayUnion on the nested trim list — safe for concurrent adds and
      // handles model names with spaces via FieldPath.
      await ref.update(<Object, Object?>{
        FieldPath([modelsField, model]): FieldValue.arrayUnion([trim]),
      });
      clearCache();
    } on CarMetadataException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.createTrim FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to create trim (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.createTrim error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  Future<void> renameTrim({
    required String brandId,
    required String modelName,
    required String oldTrimName,
    required String newTrimName,
  }) async {
    final to = _normalizeLabel(newTrimName, label: 'Trim');

    try {
      final ref = await _brandRef(brandId);
      final brand = ref.id;
      final snap = await ref.get();
      if (!snap.exists) {
        throw CarMetadataException('Brand "$brand" was not found.');
      }

      final models = _parseModels(snap.data()?[modelsField]);
      final model = _resolveModelKey(models, modelName, label: 'Model');
      if (!models.containsKey(model)) {
        throw CarMetadataException('Model "$model" was not found.');
      }

      final from = _normalizeLabel(oldTrimName, label: 'Trim');
      if (from == to) return;

      final trims = List<String>.from(models[model]!);
      final index =
          trims.indexWhere((t) => t.toLowerCase() == from.toLowerCase());
      if (index < 0) {
        throw CarMetadataException('Trim "$from" was not found.');
      }
      if (trims.any((t) => t.toLowerCase() == to.toLowerCase())) {
        throw CarMetadataException('Trim "$to" already exists.');
      }

      trims[index] = to;
      await ref.update(<Object, Object?>{
        FieldPath([modelsField, model]): trims,
      });
      clearCache();
    } on CarMetadataException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.renameTrim FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to rename trim (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.renameTrim error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  Future<void> deleteTrim({
    required String brandId,
    required String modelName,
    required String trimName,
  }) async {
    final trim = _normalizeLabel(trimName, label: 'Trim');

    try {
      final ref = await _brandRef(brandId);
      final brand = ref.id;
      final snap = await ref.get();
      if (!snap.exists) {
        throw CarMetadataException('Brand "$brand" was not found.');
      }

      final models = _parseModels(snap.data()?[modelsField]);
      final model = _resolveModelKey(models, modelName, label: 'Model');
      if (!models.containsKey(model)) {
        throw CarMetadataException('Model "$model" was not found.');
      }

      final trims = models[model] ?? const <String>[];
      final match = trims.cast<String?>().firstWhere(
            (t) => t!.toLowerCase() == trim.toLowerCase(),
            orElse: () => null,
          );
      if (match == null) {
        throw CarMetadataException('Trim "$trim" was not found.');
      }

      await ref.update(<Object, Object?>{
        FieldPath([modelsField, model]): FieldValue.arrayRemove([match]),
      });
      clearCache();
    } on CarMetadataException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('CarMetadataService.deleteTrim FirebaseException: '
          '${e.code} — ${e.message}');
      throw CarMetadataException(
        e.message ?? 'Failed to delete trim (${e.code}).',
      );
    } catch (e, st) {
      debugPrint('CarMetadataService.deleteTrim error: $e\n$st');
      throw CarMetadataException(_unwrapError(e));
    }
  }

  // ── Internals ───────────────────────────────────────────────────────────

  Map<String, List<String>> _parseModels(Object? raw) {
    if (raw is! Map) return {};

    final models = <String, List<String>>{};
    for (final entry in raw.entries) {
      final modelName = entry.key.toString().trim();
      if (modelName.isEmpty) continue;

      final value = entry.value;
      if (value is List) {
        models[modelName] = _normalizeTrimList(value);
      } else if (value is Map) {
        // Some seeds store trims as { "trims": [...] } objects.
        final nested = value['trims'] ?? value['trim'] ?? value['values'];
        models[modelName] = nested is List
            ? _normalizeTrimList(nested)
            : const <String>[];
      } else {
        models[modelName] = const <String>[];
      }
    }
    return models;
  }

  Map<String, dynamic> _modelsToFirestoreMap(Map<String, List<String>> models) {
    return {
      for (final entry in models.entries) entry.key: List<String>.from(entry.value),
    };
  }

  List<String> _normalizeTrimList(List<dynamic> raw) {
    final trims = <String>[];
    for (final item in raw) {
      final trim = item?.toString().trim();
      if (trim != null && trim.isNotEmpty) {
        trims.add(trim);
      }
    }
    return trims;
  }

  /// Trims and collapses whitespace, but preserves original casing so the
  /// value matches Firestore document ids exactly (e.g. `Toyota` ≠ `toyota`).
  String _normalizeId(String value, {required String label}) {
    final id = value.trim().replaceAll(RegExp(r'\s+'), '_');
    if (id.isEmpty) {
      throw CarMetadataException('$label name cannot be empty.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(id)) {
      throw CarMetadataException(
        '$label id may only contain letters, numbers, underscores, and hyphens.',
      );
    }
    return id;
  }

  String _normalizeLabel(String value, {required String label}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw CarMetadataException('$label name cannot be empty.');
    }
    return trimmed;
  }

  String _resolveModelKey(
    Map<String, List<String>> models,
    String modelName, {
    required String label,
  }) {
    final normalized = _normalizeLabel(modelName, label: label);
    if (models.containsKey(normalized)) return normalized;

    final lower = normalized.toLowerCase();
    for (final key in models.keys) {
      if (key.toLowerCase() == lower) return key;
    }
    return normalized;
  }

  /// Unwraps Flutter-web boxed Futures ("Dart exception thrown from converted Future").
  static String _unwrapError(Object error) {
    if (error is CarMetadataException) return error.message;
    if (error is FirebaseException) {
      return error.message ?? error.code;
    }

    try {
      final dynamic boxed = error;
      final inner = boxed.error;
      if (inner != null && !identical(inner, error)) {
        return _unwrapError(inner as Object);
      }
      final message = boxed.message;
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    } catch (_) {
      // Not a boxed JS / Future error.
    }

    final text = error.toString();
    if (text.contains('Dart exception thrown from converted Future')) {
      return 'Firestore write failed. Check console for details.';
    }
    return text;
  }
}
