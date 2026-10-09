import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_dimensions.dart';
import '../i18n/app_localizations.dart';
import '../models/city_model.dart';
import '../presentation/widgets/components/cosmic_cta_button.dart';
import '../presentation/widgets/components/cosmic_input_field.dart';
import '../providers/active_profile_provider.dart';
import '../providers/language_provider.dart';
import '../services/chart_persistence_service.dart';
import 'package:lottie/lottie.dart';

/// K33: doğum tarihi + yeri + saati tek ekran, tam yeniden hesap.
class EditBirthDataPage extends StatefulWidget {
  final String profileId;
  const EditBirthDataPage({super.key, required this.profileId});

  @override
  State<EditBirthDataPage> createState() => _EditBirthDataPageState();
}

class _EditBirthDataPageState extends State<EditBirthDataPage> {
  final TextEditingController _ctl = TextEditingController();
  List<CityModel> _all = [];
  List<CityModel> _results = [];
  CityModel? _city;
  DateTime _date = DateTime(2000, 1, 1);
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 0);
  bool _timeKnown = true;
  bool _loading = true;
  bool _saving = false;
  bool _error = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final row = await Supabase.instance.client
          .from('user_profiles')
          .select(
              'birth_date, birth_time, birth_time_known, birth_city, latitude, longitude, timezone')
          .eq('id', widget.profileId)
          .single();
      final cities = await CityModel.loadAll();
      final d = DateTime.tryParse(row['birth_date']?.toString() ?? '');
      final parts = (row['birth_time']?.toString() ?? '').split(':');
      final h = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
      final m = parts.length > 1 ? int.tryParse(parts[1]) : null;
      final name = row['birth_city']?.toString() ?? '';
      final lat = (row['latitude'] as num?)?.toDouble() ?? 0.0;
      final lon = (row['longitude'] as num?)?.toDouble() ?? 0.0;
      CityModel? city;
      for (final c in cities) {
        if (c.city == name &&
            (c.latitude - lat).abs() < 0.01 &&
            (c.longitude - lon).abs() < 0.01) {
          city = c;
          break;
        }
      }
      city ??= name.isEmpty
          ? null
          : CityModel(
              city: name,
              country: '',
              display: name,
              latitude: lat,
              longitude: lon,
              timezone: row['timezone']?.toString() ?? '',
            );
      if (!mounted) return;
      setState(() {
        _all = cities;
        if (d != null) _date = d;
        _timeKnown = row['birth_time_known'] == true;
        if (_timeKnown && h != null) {
          _time = TimeOfDay(hour: h, minute: m ?? 0);
        }
        _city = city;
        _ctl.text = city?.display ?? '';
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('EditBirthData load error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _onSearch(String v) {
    setState(() {
      _city = null;
      _results = v.trim().isEmpty
          ? []
          : _all
              .where((c) => c.display.toLowerCase().contains(v.toLowerCase()))
              .take(6)
              .toList();
    });
  }

  void _pickCity(CityModel c) {
    FocusScope.of(context).unfocus();
    setState(() {
      _city = c;
      _ctl.text = c.display;
      _results = [];
    });
  }

  Future<void> _save() async {
    final city = _city;
    if (city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(context, 'onboarding.city.required'))),
      );
      return;
    }
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = false;
    });
    try {
      final locale = context.read<LanguageProvider>().locale.languageCode;
      await ChartPersistenceService.updateBirthData(
        profileId: widget.profileId,
        birthDate: _date,
        time: _time,
        timeKnown: _timeKnown,
        city: city,
        locale: locale,
      );
      if (!mounted) return;
      context.read<ActiveProfileProvider>().bump();
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('EditBirthData save error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = true;
      });
    }
  }

  Widget _label(String key) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 4),
        child: Text(t(context, key),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(t(context, 'birth_data.title'),
            style: Theme.of(context).textTheme.titleMedium),
      ),
      body: Stack(children: [
      SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
                ? Center(child: Text(t(context, 'birth_time.error')))
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenH),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label('birth_data.date'),
                              SizedBox(
                                height: 160,
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  initialDateTime: _date,
                                  maximumDate: DateTime.now(),
                                  minimumDate: DateTime(1900),
                                  onDateTimeChanged: (d) => _date = d,
                                ),
                              ),
                              _label('birth_data.city'),
                              CosmicInputField(
                                label: t(context, 'create_profile.city_hint'),
                                icon: Icons.location_on_outlined,
                                controller: _ctl,
                                hint: t(context, 'onboarding.city.hint'),
                                onChanged: _onSearch,
                              ),
                              if (_results.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  constraints:
                                      const BoxConstraints(maxHeight: 220),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Theme.of(context).dividerColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _results.length,
                                    itemBuilder: (c, i) => ListTile(
                                      title: Text(_results[i].display),
                                      onTap: () => _pickCity(_results[i]),
                                    ),
                                  ),
                                ),
                              _label('birth_data.time'),
                              Opacity(
                                opacity: _timeKnown ? 1 : 0.35,
                                child: IgnorePointer(
                                  ignoring: !_timeKnown,
                                  child: SizedBox(
                                    height: 160,
                                    child: CupertinoDatePicker(
                                      mode: CupertinoDatePickerMode.time,
                                      use24hFormat: true,
                                      initialDateTime: DateTime(
                                          2000, 1, 1, _time.hour, _time.minute),
                                      onDateTimeChanged: (d) => _time =
                                          TimeOfDay(
                                              hour: d.hour, minute: d.minute),
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _timeKnown = !_timeKnown),
                                child: Text(_timeKnown
                                    ? t(context, 'onboarding.birthtime.unknown')
                                    : t(context, 'birth_data.time_known')),
                              ),
                              if (_error)
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: AppSpacing.sm),
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: AppDecorations.errorBanner(),
                                  child: Text(t(context, 'birth_time.error'),
                                      style: const TextStyle(
                                          color: AppColors.errorRed)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.screenH),
                        child: CosmicCtaButton(
                          label: t(context, 'birth_time.save'),
                          onTap: _saving ? () {} : _save,
                        ),
                      ),
                    ],
                      ),
      ),
      if (_saving)
        Positioned.fill(
          child: AbsorbPointer(
            child: Container(
              color: AppColors.bgDeep,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: Lottie.asset(
                        'assets/animations/Astrology.json',
                        animate: !MediaQuery.of(context).disableAnimations,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t(context, 'onboarding.calculating.title'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}