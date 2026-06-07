import 'package:cloud_firestore/cloud_firestore.dart';

class CarDatabaseException implements Exception {
  CarDatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Persists car listing documents to Firestore.
class CarDatabaseService {
  CarDatabaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Saves a car ad to the `cars` collection with [imageUrls] and [createdAt].
  Future<String> publishCarAd(
    Map<String, dynamic> carData,
    List<String> imageUrls,
  ) async {
    try {
      final doc = _firestore.collection('cars').doc();
      await doc.set({
        ...carData,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } on FirebaseException catch (e) {
      throw CarDatabaseException(
        e.message ?? 'Failed to publish car listing.',
      );
    } catch (e) {
      throw CarDatabaseException('Failed to publish car listing: $e');
    }
  }
}
