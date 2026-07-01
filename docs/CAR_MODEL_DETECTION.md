# Car Model Detection

IQ Motors uses a **two-stage pipeline** for real-time car scanning:

1. **On-device (ML Kit)** — `google_mlkit_object_detection` finds vehicles in the live camera feed and draws bounding boxes.
2. **Cloud (Gemini)** — When confidence exceeds **85%**, a still frame is sent to Gemini to identify **brand**, **model**, and **year**, then Firestore is queried for matching listings in the `cars` collection.

Entry point: **Home → scan icon** → `CarDetectionScreen` (`lib/features/detection/`).

---

## Architecture

```
CameraView (live feed)
    → CarDetectionService.detectVehicles()   [ML Kit, stream mode]
    → confidence ≥ 0.85
    → capture still photo
    → CarVisionService.analyzeCarImage()     [Gemini]
    → map brand/model to catalog keys
    → CarDatabaseService.findListingsByDetection()  [Firestore]
```

| Layer | File |
|-------|------|
| Camera + overlay | `lib/features/detection/presentation/widgets/camera_view.dart` |
| Detection pipeline | `lib/features/detection/data/services/car_detection_service.dart` |
| Gemini + catalog mapping | `lib/features/listings/data/services/car_vision_service.dart` |
| Firestore lookup | `lib/features/marketplace/data/services/car_database_service.dart` |

Firestore fields used for matching:

- `brandId` — catalog brand id (e.g. `toyota`)
- `modelKey` — catalog model key (e.g. `camry`)
- `year` — model year (used as generation proxy; listings do not store a separate generation field)

Only listings with `status` in `active` or `sold` are returned.

---

## Option A: Custom TensorFlow Lite model (on-device make/model)

The bundled ML Kit default model detects **generic objects** (including vehicles) but does **not** classify Toyota vs BMW. For make/model on-device, ship a custom `.tflite` model trained on car datasets.

### 1. Train or obtain a model

Common datasets:

- [Stanford Cars](https://ai.stanford.edu/~jkrause/cars/car_dataset.html)
- [CompCars](http://mmlab.ie.cuhk.edu.hk/datasets/comp_cars/)
- Export to TensorFlow Lite with object-detection metadata (labels file).

### 2. Add the model to the app

```text
assets/ml/car_make_model.tflite
assets/ml/car_make_model_labels.txt
```

Register in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/ml/car_make_model.tflite
    - assets/ml/car_make_model_labels.txt
```

### 3. Wire the custom model

`CarDetectionService` accepts an optional asset path via `LocalObjectDetectorOptions`:

```dart
CarDetectionService(
  customModelAssetPath: 'assets/ml/car_make_model.tflite',
)
```

Copy the asset to a local path on first launch (ML Kit requires a filesystem path on some platforms), or use Flutter’s asset-to-temp copy pattern before passing `modelPath`.

### 4. Map model labels to your catalog

Custom model labels (e.g. `"Toyota Camry 2018-2022"`) must be parsed and mapped with `CarVisionService.mapAnalysisToFormKeys()` or your own mapping table to `brandId` / `modelKey` / `year`.

**Pros:** Works offline after download, low latency, no API cost.  
**Cons:** Large model size, retraining when catalog changes, lower accuracy than cloud VLMs on rare trims.

---

## Option B: Google Cloud Vision API

Use [Cloud Vision](https://cloud.google.com/vision/docs) when you want managed infrastructure instead of Gemini.

### 1. Enable the API

- Create a GCP project, enable **Cloud Vision API**.
- Create an API key or service account with `roles/vision.user`.

### 2. Call from a trusted backend (recommended)

Do **not** embed Vision API keys in the mobile app. Add a Cloud Function / Worker:

```http
POST /v1/identify-car
Body: { "imageBase64": "..." }
Response: { "brand": "Toyota", "model": "Camry", "year": "2020" }
```

The function calls:

```http
POST https://vision.googleapis.com/v1/images:annotate
```

With features such as `LABEL_DETECTION`, `OBJECT_LOCALIZATION`, or **AutoML Vision** if you trained a custom product.

### 3. Integrate in Flutter

Add a method parallel to `CarVisionService.analyzeCarImage()` that POSTs the still frame to your backend, then reuse `mapAnalysisToFormKeys()` and `findListingsByDetection()`.

**Pros:** Google-managed scaling, can combine with AutoML for fine-grained classes.  
**Cons:** Network required, per-request billing, needs a backend for key security.

---

## Option C: Gemini (current default)

The app already uses **Gemini 2.0 Flash** via `google_generative_ai` when `GEMINI_API_KEY` is set in `.env`:

```env
GEMINI_API_KEY=your_key_here
```

`CarDetectionService` triggers `CarVisionService.analyzeCarImage()` on high-confidence detections. No extra setup beyond the existing add-car AI flow.

**Pros:** Strong zero-shot make/model recognition, minimal integration.  
**Cons:** Requires network, API quota/cost, not real-time on every frame (throttled to ~1 lookup per 3 seconds).

---

## Tuning

| Constant | Location | Default |
|----------|----------|---------|
| Confidence threshold | `CarDetectionService.confidenceThreshold` | `0.85` |
| Lookup cooldown | `CarDetectionService.identificationCooldown` | `3s` |
| Frame skip | `CameraView._frameSkipInterval` | every 2nd frame |

---

## Platform notes

- **Android / iOS only** — ML Kit object detection does not run on web/desktop; `CarDetectionScreen` shows an explanatory message.
- **Permissions** — `CAMERA` is declared in `AndroidManifest.xml`; `NSCameraUsageDescription` is set in `Info.plist`.
- **Dependencies** — `google_mlkit_object_detection`, `camera`, `google_generative_ai` (see `pubspec.yaml`).

---

## Firestore index

If you filter by `brandId` + `modelKey` + `year` together, Firestore may require a composite index. Create it from the link in the Firebase console error log, or add to `firestore.indexes.json`:

```json
{
  "collectionGroup": "cars",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "arrayConfig": "CONTAINS" },
    { "fieldPath": "brandId", "order": "ASCENDING" },
    { "fieldPath": "modelKey", "order": "ASCENDING" },
    { "fieldPath": "year", "order": "ASCENDING" }
  ]
}
```

(Adjust `status` filter to match your query shape — the app uses `whereIn` on `status`.)
