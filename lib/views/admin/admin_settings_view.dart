import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/activity_actions.dart';
import '../../core/admin_audit_helper.dart';
import '../../core/l10n_extensions.dart';
import '../../data/add_car_option_keys.dart';
import '../../l10n/app_localizations.dart';
import '../../models/activity_log.dart';
import '../../models/admin_system_config.dart';
import '../../providers/admin_settings_provider.dart';
import '../../providers/storage_providers.dart';
import '../../services/admin_database_service.dart';
import '../add_car/add_car_theme.dart';

enum _SettingsCategory { general, packages, cities, security }

/// Super-admin platform settings — packages, cities, admins, credentials.
class AdminSettingsView extends ConsumerStatefulWidget {
  const AdminSettingsView({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends ConsumerState<AdminSettingsView> {
  _SettingsCategory _category = _SettingsCategory.general;

  AdminSystemConfig? _config;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _boostPriceCtrl;
  late TextEditingController _superBoostPriceCtrl;
  late TextEditingController _r2EndpointCtrl;
  late TextEditingController _r2AccessKeyCtrl;
  late TextEditingController _r2SecretKeyCtrl;
  late TextEditingController _r2BucketCtrl;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    _boostPriceCtrl = TextEditingController();
    _superBoostPriceCtrl = TextEditingController();
    _r2EndpointCtrl = TextEditingController();
    _r2AccessKeyCtrl = TextEditingController();
    _r2SecretKeyCtrl = TextEditingController();
    _r2BucketCtrl = TextEditingController();
    _loadConfig();
  }

  @override
  void dispose() {
    _boostPriceCtrl.dispose();
    _superBoostPriceCtrl.dispose();
    _r2EndpointCtrl.dispose();
    _r2AccessKeyCtrl.dispose();
    _r2SecretKeyCtrl.dispose();
    _r2BucketCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final config =
          await ref.read(adminDatabaseServiceProvider).fetchSystemConfig();
      if (!mounted) return;
      _applyConfigToControllers(config);
      setState(() {
        _config = config;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _applyConfigToControllers(AdminSystemConfig config) {
    _boostPriceCtrl.text =
        '${config.priceForPackage(AddCarOptionKeys.packageBoost)}';
    _superBoostPriceCtrl.text =
        '${config.priceForPackage(AddCarOptionKeys.packageSuperBoost)}';
    _r2EndpointCtrl.text = config.r2Endpoint;
    _r2AccessKeyCtrl.text = config.r2AccessKey;
    _r2SecretKeyCtrl.text = config.r2SecretKey;
    _r2BucketCtrl.text = config.r2Bucket;
  }

  AdminSystemConfig _configFromControllers() {
    final base = _config ?? AdminSystemConfig.defaults();
    return base.copyWith(
      packagePrices: {
        AddCarOptionKeys.packageBoost:
            int.tryParse(_boostPriceCtrl.text.replaceAll(',', '')) ??
                base.priceForPackage(AddCarOptionKeys.packageBoost),
        AddCarOptionKeys.packageSuperBoost:
            int.tryParse(_superBoostPriceCtrl.text.replaceAll(',', '')) ??
                base.priceForPackage(AddCarOptionKeys.packageSuperBoost),
      },
      r2Endpoint: _r2EndpointCtrl.text.trim(),
      r2AccessKey: _r2AccessKeyCtrl.text.trim(),
      r2SecretKey: _r2SecretKeyCtrl.text.trim(),
      r2Bucket: _r2BucketCtrl.text.trim(),
    );
  }

  Future<void> _saveConfig({
    AdminSystemConfig? override,
    ActivityAuditContext? audit,
  }) async {
    final toSave = override ?? _configFromControllers();
    setState(() => _isSaving = true);
    try {
      await ref.read(adminDatabaseServiceProvider).saveSystemConfig(
            toSave,
            audit: audit,
          );
      ref.invalidate(systemConfigProvider);
      if (!mounted) return;
      setState(() {
        _config = toSave;
        _isSaving = false;
      });
      _applyConfigToControllers(toSave);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.adminSettingsSavedSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AddCarTheme.successGreen,
        ),
      );
    } on AdminDatabaseException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(e.message);
    }
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

  Future<void> _addCity() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final added = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.adminSettingsAddCityTitle),
        content: TextField(
          controller: controller,
          decoration: AddCarTheme.textFieldDecoration(
            hintText: l10n.adminSettingsNewCityHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.adminSettingsAddCity),
          ),
        ],
      ),
    );
    if (added == null || added.isEmpty || !mounted) return;

    final base = _config ?? AdminSystemConfig.defaults();
    if (base.activeCities.contains(added)) return;

    final updated = base.copyWith(
      activeCities: [...base.activeCities, added],
    );
    setState(() => _config = updated);
    await _saveConfig(
      override: updated,
      audit: buildAdminAudit(
        ref,
        action: ActivityActions.addedCity,
        details: 'City: $added',
      ),
    );
  }

  Future<void> _removeCity(String city) async {
    final base = _config ?? AdminSystemConfig.defaults();
    if (base.activeCities.length <= 1) return;
    final updated = base.copyWith(
      activeCities: base.activeCities.where((c) => c != city).toList(),
    );
    setState(() => _config = updated);
    await _saveConfig(
      override: updated,
      audit: buildAdminAudit(
        ref,
        action: ActivityActions.removedCity,
        details: 'City: $city',
      ),
    );
  }

  Future<void> _addAdmin() async {
    final l10n = context.l10n;
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.adminSettingsAddAdminTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: AddCarTheme.textFieldDecoration(
                  hintText: l10n.adminSettingsAdminName,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: AddCarTheme.textFieldDecoration(
                  hintText: l10n.adminSettingsAdminEmail,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: AddCarTheme.textFieldDecoration(
                  hintText: l10n.adminSettingsAdminPhone,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.adminSettingsAddAdmin),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final entry = AdminAccountEntry(
      email: emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      name: nameCtrl.text.trim(),
    );
    if (entry.email.isEmpty && entry.phone.isEmpty) return;

    final base = _config ?? AdminSystemConfig.defaults();
    final updated = base.copyWith(admins: [...base.admins, entry]);
    setState(() => _config = updated);
    await _saveConfig(
      override: updated,
      audit: buildAdminAudit(
        ref,
        action: ActivityActions.addedAdmin,
        details:
            'Admin: ${entry.name.isNotEmpty ? entry.name : entry.email}',
      ),
    );
  }

  Future<void> _removeAdmin(int index) async {
    final base = _config ?? AdminSystemConfig.defaults();
    if (base.admins.length <= 1) return;
    final admins = List<AdminAccountEntry>.from(base.admins)..removeAt(index);
    final updated = base.copyWith(admins: admins);
    setState(() => _config = updated);
    await _saveConfig(override: updated);
  }

  Future<void> _savePackagePrices() async {
    final audit = buildAdminAudit(
      ref,
      action: ActivityActions.updatedPackagePrice,
      details: '',
    );
    if (audit == null) return;

    final base = _config ?? AdminSystemConfig.defaults();
    final boost = int.tryParse(_boostPriceCtrl.text.replaceAll(',', ''));
    final superBoost =
        int.tryParse(_superBoostPriceCtrl.text.replaceAll(',', ''));

    setState(() => _isSaving = true);
    try {
      final adminDb = ref.read(adminDatabaseServiceProvider);
      var changed = false;

      if (boost != null &&
          boost != base.priceForPackage(AddCarOptionKeys.packageBoost)) {
        await adminDb.updatePackagePrice(
          packageKey: AddCarOptionKeys.packageBoost,
          priceIqd: boost,
          adminId: audit.adminId,
          adminDisplayName: audit.adminDisplayName,
          details: 'Boost: $boost IQD',
        );
        changed = true;
      }

      if (superBoost != null &&
          superBoost !=
              base.priceForPackage(AddCarOptionKeys.packageSuperBoost)) {
        await adminDb.updatePackagePrice(
          packageKey: AddCarOptionKeys.packageSuperBoost,
          priceIqd: superBoost,
          adminId: audit.adminId,
          adminDisplayName: audit.adminDisplayName,
          details: 'Super Boost: $superBoost IQD',
        );
        changed = true;
      }

      if (!changed) {
        await adminDb.saveSystemConfig(_configFromControllers());
      }

      ref.invalidate(systemConfigProvider);
      await _loadConfig();
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.adminSettingsSavedSuccess),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AddCarTheme.successGreen,
        ),
      );
    } on AdminDatabaseException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(e.message);
    }
  }

  Future<void> _saveCredentials() async {
    await _saveConfig(
      audit: buildAdminAudit(
        ref,
        action: ActivityActions.updatedCredentials,
        details: 'Cloudflare R2 credentials updated',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.navSettings,
          style: TextStyle(
            fontSize: widget.isMobile ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: AddCarTheme.textPrimary,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.adminSettingsSubtitle,
          style: AddCarTheme.stepSubtitle.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 24),
        _CategoryTabs(
          selected: _category,
          isMobile: widget.isMobile,
          labels: {
            _SettingsCategory.general: l10n.adminSettingsGeneral,
            _SettingsCategory.packages: l10n.adminSettingsPackages,
            _SettingsCategory.cities: l10n.adminSettingsCities,
            _SettingsCategory.security: l10n.adminSettingsSecurity,
          },
          onSelected: (cat) => setState(() => _category = cat),
        ),
        const SizedBox(height: 20),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          _SettingsCard(
            child: switch (_category) {
              _SettingsCategory.general => _GeneralSection(l10n: l10n),
              _SettingsCategory.packages => _PackagesSection(
                  l10n: l10n,
                  boostController: _boostPriceCtrl,
                  superBoostController: _superBoostPriceCtrl,
                  isSaving: _isSaving,
                  onSave: _savePackagePrices,
                ),
              _SettingsCategory.cities => _CitiesSection(
                  l10n: l10n,
                  cities: _config?.activeCities ?? const [],
                  onAdd: _addCity,
                  onRemove: _removeCity,
                ),
              _SettingsCategory.security => _SecuritySection(
                  l10n: l10n,
                  admins: _config?.admins ?? const [],
                  endpointController: _r2EndpointCtrl,
                  accessKeyController: _r2AccessKeyCtrl,
                  secretKeyController: _r2SecretKeyCtrl,
                  bucketController: _r2BucketCtrl,
                  obscureSecret: _obscureSecret,
                  onToggleSecret: () =>
                      setState(() => _obscureSecret = !_obscureSecret),
                  isSaving: _isSaving,
                  onSave: _saveCredentials,
                  onAddAdmin: _addAdmin,
                  onRemoveAdmin: _removeAdmin,
                ),
            },
          ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.selected,
    required this.isMobile,
    required this.labels,
    required this.onSelected,
  });

  final _SettingsCategory selected;
  final bool isMobile;
  final Map<_SettingsCategory, String> labels;
  final ValueChanged<_SettingsCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = _SettingsCategory.values.map((cat) {
      final isActive = cat == selected;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8, bottom: 8),
        child: GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AddCarTheme.textPrimary : AddCarTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AddCarTheme.textPrimary : AddCarTheme.border,
              ),
              boxShadow: isActive ? null : AddCarTheme.cardShadow,
            ),
            child: Text(
              labels[cat] ?? '',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AddCarTheme.textSecondary,
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Wrap(children: chips);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AddCarTheme.cardDecoration(),
      child: child,
    );
  }
}

class _GeneralSection extends StatelessWidget {
  const _GeneralSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.adminSettingsGeneralInfo, style: AddCarTheme.sectionTitle),
        const SizedBox(height: 20),
        _InfoRow(
          icon: Icons.directions_car_outlined,
          title: l10n.adminSettingsAppName,
          subtitle: l10n.adminSettingsAppVersion,
        ),
        const Divider(height: 32, color: AddCarTheme.border),
        _InfoRow(
          icon: Icons.language_outlined,
          title: l10n.navSettings,
          subtitle: l10n.adminSettingsSubtitle,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AddCarTheme.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AddCarTheme.focusBlue, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AddCarTheme.sectionLabel),
              const SizedBox(height: 2),
              Text(subtitle, style: AddCarTheme.stepSubtitle.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PackagesSection extends StatelessWidget {
  const _PackagesSection({
    required this.l10n,
    required this.boostController,
    required this.superBoostController,
    required this.isSaving,
    required this.onSave,
  });

  final AppLocalizations l10n;
  final TextEditingController boostController;
  final TextEditingController superBoostController;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsField(
          label: l10n.adminSettingsBoostPrice,
          controller: boostController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _SettingsField(
          label: l10n.adminSettingsSuperBoostPrice,
          controller: superBoostController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        _SaveButton(
          label: l10n.adminSettingsSaveChanges,
          isLoading: isSaving,
          onPressed: onSave,
        ),
      ],
    );
  }
}

class _CitiesSection extends StatelessWidget {
  const _CitiesSection({
    required this.l10n,
    required this.cities,
    required this.onAdd,
    required this.onRemove,
  });

  final AppLocalizations l10n;
  final List<String> cities;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.adminSettingsActiveCities, style: AddCarTheme.sectionTitle),
        const SizedBox(height: 16),
        for (var i = 0; i < cities.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ListItemRow(
            title: cities[i],
            trailing: cities.length > 1
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFFFF3B30),
                    onPressed: () => onRemove(cities[i]),
                    tooltip: l10n.adminSettingsRemove,
                  )
                : null,
          ),
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.adminSettingsAddCity),
          style: OutlinedButton.styleFrom(
            foregroundColor: AddCarTheme.focusBlue,
            side: const BorderSide(color: AddCarTheme.focusBlue),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({
    required this.l10n,
    required this.admins,
    required this.endpointController,
    required this.accessKeyController,
    required this.secretKeyController,
    required this.bucketController,
    required this.obscureSecret,
    required this.onToggleSecret,
    required this.isSaving,
    required this.onSave,
    required this.onAddAdmin,
    required this.onRemoveAdmin,
  });

  final AppLocalizations l10n;
  final List<AdminAccountEntry> admins;
  final TextEditingController endpointController;
  final TextEditingController accessKeyController;
  final TextEditingController secretKeyController;
  final TextEditingController bucketController;
  final bool obscureSecret;
  final VoidCallback onToggleSecret;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onAddAdmin;
  final ValueChanged<int> onRemoveAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.adminSettingsAdmins, style: AddCarTheme.sectionTitle),
        const SizedBox(height: 12),
        for (var i = 0; i < admins.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ListItemRow(
            title: admins[i].name.isNotEmpty
                ? admins[i].name
                : admins[i].email,
            subtitle: admins[i].phone.isNotEmpty
                ? '${admins[i].email}\n${admins[i].phone}'
                : admins[i].email,
            trailing: admins.length > 1
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFFFF3B30),
                    onPressed: () => onRemoveAdmin(i),
                  )
                : null,
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAddAdmin,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: Text(l10n.adminSettingsAddAdmin),
          style: OutlinedButton.styleFrom(
            foregroundColor: AddCarTheme.focusBlue,
            side: const BorderSide(color: AddCarTheme.focusBlue),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.adminSettingsSystemCredentials,
            style: AddCarTheme.sectionTitle),
        const SizedBox(height: 8),
        Text(
          l10n.adminSettingsCredentialsNote,
          style: AddCarTheme.stepSubtitle.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 16),
        _SettingsField(
          label: l10n.adminSettingsR2Endpoint,
          controller: endpointController,
        ),
        const SizedBox(height: 14),
        _SettingsField(
          label: l10n.adminSettingsR2AccessKey,
          controller: accessKeyController,
        ),
        const SizedBox(height: 14),
        _SettingsField(
          label: l10n.adminSettingsR2SecretKey,
          controller: secretKeyController,
          obscureText: obscureSecret,
          suffix: IconButton(
            icon: Icon(
              obscureSecret ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: AddCarTheme.textSecondary,
            ),
            onPressed: onToggleSecret,
          ),
        ),
        const SizedBox(height: 14),
        _SettingsField(
          label: l10n.adminSettingsR2Bucket,
          controller: bucketController,
        ),
        const SizedBox(height: 24),
        _SaveButton(
          label: l10n.adminSettingsSaveChanges,
          isLoading: isSaving,
          onPressed: onSave,
        ),
      ],
    );
  }
}

class _SettingsField extends StatefulWidget {
  const _SettingsField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  State<_SettingsField> createState() => _SettingsFieldState();
}

class _SettingsFieldState extends State<_SettingsField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AddCarTheme.sectionLabel),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: Container(
            decoration: AddCarTheme.inputDecorationBox(focused: _focused),
            child: TextField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              inputFormatters: widget.keyboardType == TextInputType.number
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AddCarTheme.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsetsDirectional.all(16),
                suffixIcon: widget.suffix,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListItemRow extends StatelessWidget {
  const _ListItemRow({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AddCarTheme.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AddCarTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AddCarTheme.sectionLabel),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AddCarTheme.stepSubtitle.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AddCarTheme.textPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
