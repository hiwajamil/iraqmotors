import 'package:iq_motors/core/localization/iraq_location_l10n.dart';
import 'package:iq_motors/l10n/app_localizations.dart';
import 'package:iq_motors/features/listings/domain/models/add_car_draft.dart';
import 'package:iq_motors/shared/data/add_car_form_options.dart';
import 'package:iq_motors/shared/data/car_models_by_brand.dart';
import 'package:iq_motors/shared/data/dummy_brands.dart';

/// A labeled row in the add-car review summary.
class AddCarReviewRow {
  const AddCarReviewRow({required this.label, required this.value});

  final String label;
  final String value;
}

/// A review section tied to an editable wizard step index.
class AddCarReviewSection {
  const AddCarReviewSection({
    required this.title,
    required this.stepIndex,
    required this.rows,
  });

  final String title;
  final int stepIndex;
  final List<AddCarReviewRow> rows;
}

/// Builds human-readable review sections from [AddCarDraft].
abstract final class AddCarReviewSummary {
  static List<AddCarReviewSection> build(AppLocalizations l10n, AddCarDraft draft) {
    final locale = l10n.localeName.split('_').first;
    final languageCode = l10n.localeName.split('_').first;

    String brandModel = '—';
    if (draft.brandId != null) {
      for (final brand in dummyBrands) {
        if (brand.id == draft.brandId) {
          final modelLabel = draft.modelKey != null
              ? CarModelsByBrand.labelForModel(
                  brand,
                  draft.modelKey!,
                  languageCode,
                )
              : null;
          brandModel = modelLabel != null
              ? '${brand.displayName(languageCode)} · $modelLabel'
              : brand.displayName(languageCode);
          break;
        }
      }
    }

    final priceText = draft.priceValue != null && draft.priceValue!.isNotEmpty
        ? '${AddCarFormOptions.currencySymbol(draft.currencyKey)} ${draft.priceValue}'
        : '—';

    final featuresText = draft.selectedFeatures.isEmpty
        ? switch (locale) {
            'en' => 'None selected',
            'ar' => 'لم يتم التحديد',
            _ => 'هیچ هەڵنەبژێردراوە',
          }
        : switch (locale) {
            'en' => '${draft.selectedFeatures.length} features',
            'ar' => '${draft.selectedFeatures.length} ميزات',
            _ => '${draft.selectedFeatures.length} تایبەتمەندی',
          };

    final mileageUnit = AddCarFormOptions.mileageUnitLabel(l10n, draft.mileageUnit);

    return [
      AddCarReviewSection(
        title: switch (locale) {
          'en' => 'Location',
          'ar' => 'الموقع',
          _ => 'شوێن',
        },
        stepIndex: 0,
        rows: [
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Province / City',
              'ar' => 'المحافظة / المدينة',
              _ => 'پارێزگا / شار',
            },
            value: draft.province == null || draft.city == null
                ? '—'
                : '${IraqLocationL10n.provinceLabel(l10n, draft.province!)} · '
                    '${IraqLocationL10n.cityLabel(l10n, draft.city!)}',
          ),
        ],
      ),
      AddCarReviewSection(
        title: switch (locale) {
          'en' => 'Photos',
          'ar' => 'الصور',
          _ => 'وێنەکان',
        },
        stepIndex: 1,
        rows: [
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Uploaded',
              'ar' => 'مرفوعة',
              _ => 'بارکراو',
            },
            value: '${draft.filledPhotoCount} / ${AddCarDraft.photoSlotCount}',
          ),
        ],
      ),
      AddCarReviewSection(
        title: switch (locale) {
          'en' => 'Basic info',
          'ar' => 'المعلومات الأساسية',
          _ => 'زانیاری سەرەتایی',
        },
        stepIndex: 2,
        rows: [
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Brand / Model',
              'ar' => 'العلامة / الموديل',
              _ => 'براند / مۆدێل',
            },
            value: brandModel,
          ),
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Year',
              'ar' => 'السنة',
              _ => 'ساڵ',
            },
            value: draft.year ?? '—',
          ),
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Color',
              'ar' => 'اللون',
              _ => 'ڕەنگ',
            },
            value: draft.colorKey != null
                ? AddCarFormOptions.colorLabel(draft.colorKey!, languageCode)
                : '—',
          ),
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Trim',
              'ar' => 'الفئة',
              _ => 'خاسڵەت',
            },
            value: draft.trim ?? '—',
          ),
        ],
      ),
      AddCarReviewSection(
        title: switch (locale) {
          'en' => 'Plate',
          'ar' => 'اللوحة',
          _ => 'تابلۆ',
        },
        stepIndex: 3,
        rows: [
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Type / City',
              'ar' => 'النوع / المدينة',
              _ => 'جۆر / شار',
            },
            value:
                '${draft.plateTypeKey != null ? AddCarFormOptions.plateTypeLabel(l10n, draft.plateTypeKey!) : '—'} · ${draft.plateCityKey != null ? AddCarFormOptions.plateCityLabel(l10n, draft.plateCityKey!) : '—'}',
          ),
        ],
      ),
      AddCarReviewSection(
        title: switch (locale) {
          'en' => 'Mileage & fuel',
          'ar' => 'المسافة والوقود',
          _ => 'ماوەی ڕۆیشتن و سووتەمەنی',
        },
        stepIndex: 4,
        rows: [
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Mileage',
              'ar' => 'المسافة',
              _ => 'ماوەی ڕۆیشتن',
            },
            value: draft.mileageValue != null
                ? '${draft.mileageValue} $mileageUnit'
                : '—',
          ),
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Fuel',
              'ar' => 'الوقود',
              _ => 'سووتەمەنی',
            },
            value: draft.fuelKey != null
                ? AddCarFormOptions.fuelLabel(l10n, draft.fuelKey!)
                : '—',
          ),
        ],
      ),
      AddCarReviewSection(
        title: switch (locale) {
          'en' => 'Technical',
          'ar' => 'تقني',
          _ => 'تەکنیکی',
        },
        stepIndex: 5,
        rows: [
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Import / Transmission',
              'ar' => 'الاستيراد / ناقل الحركة',
              _ => 'هاوردە / گێڕ',
            },
            value:
                '${draft.importCountryKey != null ? AddCarFormOptions.importCountryLabel(l10n, draft.importCountryKey!) : '—'} · ${draft.transmissionKey != null ? AddCarFormOptions.transmissionLabel(l10n, draft.transmissionKey!) : '—'}',
          ),
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Cylinders / Engine',
              'ar' => 'الأسطوانات / المحرك',
              _ => 'پستۆن / بزوێنەر',
            },
            value:
                '${draft.cylindersKey != null ? AddCarFormOptions.cylindersLabel(l10n, draft.cylindersKey!) : '—'} · ${draft.engineSizeKey != null ? AddCarFormOptions.engineSizeLabel(l10n, draft.engineSizeKey!) : '—'}',
          ),
        ],
      ),
      AddCarReviewSection(
        title: switch (locale) {
          'en' => 'Interior',
          'ar' => 'الداخلية',
          _ => 'ناوەوە',
        },
        stepIndex: 6,
        rows: [
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Seats / Material',
              'ar' => 'المقاعد / المادة',
              _ => 'کورسی / ماددە',
            },
            value:
                '${draft.seatCountKey != null ? AddCarFormOptions.seatCountLabel(l10n, draft.seatCountKey!) : '—'} · ${draft.seatMaterialKey != null ? AddCarFormOptions.seatMaterialLabel(l10n, draft.seatMaterialKey!) : '—'}',
          ),
        ],
      ),
      AddCarReviewSection(
        title: switch (locale) {
          'en' => 'Condition & features',
          'ar' => 'الحالة والميزات',
          _ => 'دۆخ و تایبەتمەندی',
        },
        stepIndex: 7,
        rows: [
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Paint / Damage',
              'ar' => 'الطلاء / الأضرار',
              _ => 'بویاغ / زیان',
            },
            value: draft.conditionKey != null
                ? AddCarFormOptions.conditionLabel(l10n, draft.conditionKey!)
                : '—',
          ),
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Features',
              'ar' => 'الميزات',
              _ => 'تایبەتمەندی',
            },
            value: featuresText,
          ),
        ],
      ),
      AddCarReviewSection(
        title: switch (locale) {
          'en' => 'Price',
          'ar' => 'السعر',
          _ => 'نرخ',
        },
        stepIndex: 8,
        rows: [
          AddCarReviewRow(
            label: switch (locale) {
              'en' => 'Selling price',
              'ar' => 'سعر البيع',
              _ => 'نرخی فرۆشتن',
            },
            value: priceText,
          ),
          if (draft.description != null && draft.description!.trim().isNotEmpty)
            AddCarReviewRow(
              label: switch (locale) {
                'en' => 'Note',
                'ar' => 'ملاحظة',
                _ => 'تێبینی',
              },
              value: draft.description!.trim(),
            ),
        ],
      ),
    ];
  }
}
