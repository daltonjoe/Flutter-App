// lib/screens/create_profile_page.dart
// SoulBound Cosmic Sanctum — SCREEN-001: Create Profile Page
// Completely redesigned with Cosmic Sanctum presentation system.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/city_model.dart';
import '../services/astro_service.dart';
import '../widgets/city_search_field.dart';
import '../widgets/language_selector.dart';
import '../widgets/animations/zodiac_orbital_animation.dart';
import '../../i18n/app_localizations.dart';
import '../core/theme/cosmic_theme.dart';
import '../presentation/widgets/components/components.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _tobController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  CityModel? _selectedCity;
  List<CityModel> _cities = [];
  bool _isLoading = false;
  bool _submitAttempted = false;

  String? _nameError;
  String? _dobError;
  String? _tobError;
  String? _cityError;
  String? _generalError;

  late AnimationController _bgCtrl;
  late AnimationController _entranceCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Key to force reload CitySearchField when a quick chip is pressed
  Key _citySearchKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadCities();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _bgAnim = Tween<double>(begin: 0, end: 1).animate(_bgCtrl);
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _tobController.dispose();
    _bgCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    final list = await CityModel.loadAll();
    if (mounted) {
      setState(() => _cities = list);
    }
  }

  bool _validate() {
    bool ok = true;
    if (_nameController.text.trim().isEmpty) {
      _nameError = t(context, 'create_profile.name_error');
      ok = false;
    } else {
      _nameError = null;
    }
    if (_selectedDate == null) {
      _dobError = _dobController.text.isEmpty
          ? t(context, 'create_profile.dob_error_required')
          : t(context, 'create_profile.dob_error_invalid');
      ok = false;
    } else {
      _dobError = null;
    }
    if (_selectedTime == null) {
      _tobError = t(context, 'create_profile.tob_error');
      ok = false;
    } else {
      _tobError = null;
    }
    if (_selectedCity == null) {
      _cityError = t(context, 'create_profile.city_error');
      ok = false;
    } else {
      _cityError = null;
    }
    return ok;
  }

  void _onDateInput(String value) {
    if (value.isEmpty) {
      setState(() => _selectedDate = null);
      return;
    }
    final digits = value.replaceAll('/', '');
    String fmt = '';
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) fmt += '/';
      fmt += digits[i];
    }
    if (fmt != value) {
      _dobController.value = TextEditingValue(
        text: fmt,
        selection: TextSelection.collapsed(offset: fmt.length),
      );
    }
    if (digits.length == 8) {
      try {
        final d = DateFormat('dd/MM/yyyy').parseStrict(fmt);
        if (!d.isAfter(DateTime.now())) {
          setState(() {
            _selectedDate = d;
            if (_submitAttempted) _dobError = null;
          });
        } else {
          setState(() {
            _selectedDate = null;
            if (_submitAttempted) {
              _dobError = t(context, 'create_profile.dob_error_future');
            }
          });
        }
      } catch (_) {
        setState(() {
          _selectedDate = null;
          if (_submitAttempted) {
            _dobError = t(context, 'create_profile.dob_error_invalid');
          }
        });
      }
    } else {
      setState(() => _selectedDate = null);
    }
  }

  Future<void> _pickDate() async {
    if (_isLoading) return;
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1995, 6, 15),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.violetPrimary,
            onPrimary: Colors.white,
            surface: AppColors.bgCard,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.bgDeep,
          ),
        ),
        child: child!,
      ),
    );
    if (p != null) {
      setState(() {
        _selectedDate = p;
        _dobController.text = DateFormat('dd/MM/yyyy').format(p);
        if (_submitAttempted) _dobError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    if (_isLoading) return;
    final p = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.violetPrimary,
            onPrimary: Colors.white,
            surface: AppColors.bgCard,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.bgDeep,
          ),
        ),
        child: child!,
      ),
    );
    if (p != null) {
      setState(() {
        _selectedTime = p;
        _tobController.text =
            '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}';
        if (_submitAttempted) _tobError = null;
      });
    }
  }

  void _setUnknownTime() {
    if (_isLoading) return;
    setState(() {
      _selectedTime = const TimeOfDay(hour: 12, minute: 0);
      _tobController.text = '12:00';
      if (_submitAttempted) _tobError = null;
    });
  }

  void _selectQuickCity(String cityName, String countryCode) {
    if (_isLoading) return;
    CityModel? matched;
    for (final c in _cities) {
      if (c.city.toLowerCase() == cityName.toLowerCase() &&
          c.country.toUpperCase() == countryCode.toUpperCase()) {
        matched = c;
        break;
      }
    }
    matched ??= _cities.firstWhere(
      (c) => c.city.toLowerCase().contains(cityName.toLowerCase()),
      orElse: () => CityModel(
        city: cityName,
        country: countryCode,
        display: '$cityName, $countryCode',
        latitude: cityName == 'London' ? 51.5074 : 41.0082,
        longitude: cityName == 'London' ? -0.1278 : 28.9784,
        timezone: cityName == 'London' ? 'Europe/London' : 'Europe/Istanbul',
      ),
    );

    setState(() {
      _selectedCity = matched;
      _citySearchKey = UniqueKey(); // refresh search box
      if (_submitAttempted) _cityError = null;
    });
  }

  Future<void> _onSubmit() async {
    setState(() {
      _submitAttempted = true;
      _generalError = null;
    });
    if (!_validate()) {
      setState(() {});
      return;
    }

    final date = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final time =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    setState(() => _isLoading = true);

    try {
      final result = await AstroService.generateNatalChart(
        birthDate: date,
        birthTime: time,
        city: _selectedCity!.display,
        latitude: _selectedCity!.latitude,
        longitude: _selectedCity!.longitude,
        timezone: _selectedCity!.timezone,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        Navigator.pushNamed(
          context,
          '/chart',
          arguments: {
            'chartData': result,
            'userName': _nameController.text.trim(),
          },
        );
      } else {
        setState(() {
          if (result.errorCode == 'CITY_NOT_FOUND') {
            _cityError = result.message;
          } else {
            _generalError =
                result.message ?? t(context, 'common.unknown_error');
          }
        });
      }
    } on AstroServiceException catch (e) {
      setState(() => _generalError = e.message);
    } catch (_) {
      setState(() => _generalError = t(context, 'common.unknown_error'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // ── Background Cosmic Ambience ──────────────────────────────
          _buildBackground(),

          // ── Main Scrollable Content ─────────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                slivers: [
                  // ── Top Bar Safe Area Spacer ────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(height: topPadding + 64),
                  ),

                  // ── Sacred Hero Illustration & Titles ───────────────
                  SliverToBoxAdapter(
                    child: _buildHeroSection(),
                  ),

                  // ── Form Inputs ─────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // 1. Name Field
                        CosmicInputField(
                          label: t(context, 'create_profile.name_label'),
                          icon: Icons.person_outline_rounded,
                          controller: _nameController,
                          hint: t(context, 'create_profile.name_hint'),
                          errorText: _nameError,
                          disabled: _isLoading,
                          onChanged: (_) {
                            if (_submitAttempted && _nameError != null) {
                              setState(() => _nameError = null);
                            }
                          },
                          actionWidget: _nameController.text.trim().isNotEmpty
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: AppColors.successGreen,
                                )
                              : null,
                        ),

                        // 2. Birth Date & Time Row (Two equal-width fields)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Picker Field
                            Expanded(
                              child: CosmicInputField(
                                label: t(context, 'create_profile.dob_label'),
                                icon: Icons.calendar_today_rounded,
                                controller: _dobController,
                                hint: t(context, 'create_profile.dob_hint'),
                                errorText: _dobError,
                                disabled: _isLoading,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d/]'),
                                  ),
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                onChanged: _onDateInput,
                                actionWidget: GestureDetector(
                                  onTap: _pickDate,
                                  child: const Icon(
                                    Icons.date_range_rounded,
                                    size: 18,
                                    color: AppColors.violetPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Time Picker Field
                            Expanded(
                              child: CosmicInputField(
                                label: t(context, 'create_profile.tob_label'),
                                icon: Icons.access_time_rounded,
                                controller: _tobController,
                                hint: t(context, 'create_profile.tob_hint'),
                                errorText: _tobError,
                                readOnly: true,
                                disabled: _isLoading,
                                onTap: _pickTime,
                                actionWidget: GestureDetector(
                                  onTap: _setUnknownTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.violetPrimary
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                      ),
                                    ),
                                    child: Text(
                                      '12:00',
                                      style: AppTextStyles.tinyLabel(
                                        color: AppColors.violetPrimary,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 3. Birth Location Search Field
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: AppColors.violetPrimary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    t(context, 'create_profile.city_label')
                                        .toUpperCase(),
                                    style: AppTextStyles.fieldLabel(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  if (_selectedCity != null) ...[
                                    const Spacer(),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: AppColors.successGreen,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: AppSpacing.inputLabelGap),
                              CitySearchField(
                                key: _citySearchKey,
                                cities: _cities,
                                onSelected: (c) => setState(() {
                                  _selectedCity = c;
                                  if (_submitAttempted) _cityError = null;
                                }),
                                decoration: InputDecoration(
                                  hintText: t(
                                    context,
                                    'create_profile.city_hint',
                                  ),
                                  hintStyle: AppTextStyles.bodyMd(
                                    color: AppColors.textMuted,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.bgSurface,
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.violetPrimary,
                                    size: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    borderSide: BorderSide(
                                      color: _cityError != null
                                          ? AppColors.borderError
                                          : AppColors.borderSubtle,
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    borderSide: BorderSide(
                                      color: _cityError != null
                                          ? AppColors.borderError
                                          : AppColors.borderSubtle,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.violetPrimary,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                              if (_cityError != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 6, left: 4),
                                  child: Text(
                                    _cityError!,
                                    style: AppTextStyles.bodyXs(
                                      color: AppColors.errorRed,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // 4. Quick City Chips
                        _buildQuickCityChips(),
                        const SizedBox(height: 20),

                        // 5. Cosmic Guidance Card
                        _buildGuidanceCard(),
                        const SizedBox(height: 24),

                        // Error Banner (if API or general validation fails)
                        if (_generalError != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 16),
                        ],

                        // 6. Submit Button
                        CosmicCtaButton(
                          label: t(context, 'create_profile.submit_button'),
                          onTap: _onSubmit,
                          loading: _isLoading,
                          icon: const Text('☽', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 20),

                        // 7. Security Footer
                        _buildSecurityFooter(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed Top Bar (Canli Efemeris + Language Selector) ──────
          Positioned(
            top: topPadding + 10,
            left: 20,
            right: 20,
            child: _buildTopBar(),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: CANLI EFEMERİS Indicator Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successGreen,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.successGreen,
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t(context, 'create_profile.ephemeris_live'),
                style: AppTextStyles.fieldLabel(
                  color: AppColors.textPrimary,
                ).copyWith(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        // Right: Language Selector Pill (Maintains LanguageProvider)
        const LanguageSelector(),
      ],
    );
  }

  // ── Hero Section ────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Concentric Orbital Illustration with Crescent Moon
          SizedBox(
            height: screenWidth * 0.58,
            width: screenWidth * 0.58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Layer 1 & 2 & 3: Zodiac Planetary Orbital Ring
                ZodiacOrbitalAnimation(size: screenWidth * 0.58),

                // Layer 4: Center Sacred Hero Moon Orb
                Container(
                  width: AppSizes.heroZodiacOrb,
                  height: AppSizes.heroZodiacOrb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3D2B7A), AppColors.violetPrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violetPrimary.withValues(alpha: 0.5),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🌙',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Main Playfair Title: "Kaderinizi Keşfedin"
          Text(
            t(context, 'create_profile.title'),
            textAlign: TextAlign.center,
            style: AppTextStyles.heroTitle(
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle: "Gökyüzü doğduğunuz anda sizin için nasıl hizalandı?"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              t(context, 'create_profile.subtitle'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick City Chips ────────────────────────────────────────────────
  Widget _buildQuickCityChips() {
    final quickList = [
      {'name': 'İstanbul', 'country': 'TR'},
      {'name': 'Ankara', 'country': 'TR'},
      {'name': 'İzmir', 'country': 'TR'},
      {'name': 'London', 'country': 'UK'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickList.map((item) {
        final cityName = item['name']!;
        final country = item['country']!;
        final isSelected = _selectedCity?.city.toLowerCase() ==
            cityName.toLowerCase();

        return GestureDetector(
          onTap: () => _selectQuickCity(cityName, country),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.violetPrimary.withValues(alpha: 0.25)
                  : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isSelected
                    ? AppColors.violetPrimary
                    : AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.near_me_outlined,
                  size: 11,
                  color: isSelected
                      ? AppColors.violetPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$cityName, $country',
                  style: AppTextStyles.bodyXs(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Guidance Card ───────────────────────────────────────────────────
  Widget _buildGuidanceCard() {
    return CosmicCard(
      compact: true,
      borderColor: AppColors.borderMedium,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldAccent.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(context, 'create_profile.guidance_title'),
                  style: AppTextStyles.h3(
                    color: AppColors.textPrimary,
                  ).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  t(context, 'create_profile.guidance_desc'),
                  style: AppTextStyles.bodyXs(
                    color: AppColors.textSecondary,
                  ).copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error Banner ────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.errorRed.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.errorRed,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _generalError!,
              style: AppTextStyles.bodySm(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  // ── Security Footer ─────────────────────────────────────────────────
  Widget _buildSecurityFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: AppColors.textMuted.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              t(context, 'create_profile.security_footer'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyXs(
                color: AppColors.textMuted,
              ).copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated Ambient Background ─────────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, _) {
        final t = _bgAnim.value;
        return Stack(
          children: [
            // Top Right Violet Mesh
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.violetPrimary.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Left Indigo Mesh
            Positioned(
              bottom: 120,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.indigoAccent.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Floating Star Dots
            ..._buildStars(t),
          ],
        );
      },
    );
  }

  List<Widget> _buildStars(double t) {
    final stars = [
      {'x': 0.12, 'y': 0.15, 'size': 2.5},
      {'x': 0.85, 'y': 0.10, 'size': 2.0},
      {'x': 0.65, 'y': 0.22, 'size': 1.5},
      {'x': 0.90, 'y': 0.40, 'size': 2.5},
      {'x': 0.08, 'y': 0.48, 'size': 2.0},
    ];
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return stars.map((s) {
      return Positioned(
        left: (s['x'] as double) * w,
        top: (s['y'] as double) * h,
        child: Container(
          width: s['size'] as double,
          height: s['size'] as double,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.goldAccent.withValues(alpha: 0.65),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldAccent.withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
