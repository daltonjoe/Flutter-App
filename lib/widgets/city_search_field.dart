import 'package:flutter/material.dart';
import '../models/city_model.dart';
import '../i18n/app_localizations.dart';

class CitySearchField extends StatefulWidget {
  final List<CityModel> cities;
  final ValueChanged<CityModel> onSelected;
  final InputDecoration? decoration;

  const CitySearchField({
    super.key,
    required this.cities,
    required this.onSelected,
    this.decoration,
  });

  @override
  State<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<CitySearchField> {
  // ── App renkleri (create_profile_page ile aynı) ───────────────────
  static const Color _bg = Color(0xFF0D0B1A);
  static const Color _surface = Color(0xFF1A1730);
  static const Color _surfaceHover = Color(0xFF221F3A);
  static const Color _accent = Color(0xFFB07BFF);
  static const Color _textPrimary = Color(0xFFF0EAFF);
  static const Color _textSecondary = Color(0xFF9985C0);
  static const Color _border = Color(0xFF2E2850);

  final TextEditingController _controller = TextEditingController();
  List<CityModel> _filtered = [];
  bool _showList = false;

  // Türkçe karakter + büyük/küçük harf duyarsız normalize
  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  void _onChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filtered = [];
        _showList = false;
      });
      return;
    }
    final q = _normalize(query);
    setState(() {
      _filtered =
          widget.cities.where((c) => _normalize(c.city).startsWith(q)).toList()
            ..addAll(
              widget.cities.where(
                (c) =>
                    _normalize(c.city).contains(q) &&
                    !_normalize(c.city).startsWith(q),
              ),
            );
      _showList = _filtered.isNotEmpty;
    });
  }

  void _onSelect(CityModel city) {
    _controller.text = city.display;
    setState(() {
      _filtered = [];
      _showList = false;
    });
    widget.onSelected(city);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Arama input ───────────────────────────────────────────
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          style: const TextStyle(color: _textPrimary, fontSize: 15),
          decoration:
              widget.decoration?.copyWith(
                // Dışarıdan gelen decoration'ı koru, sadece text stilini override et
              ) ??
              InputDecoration(
                hintText: t(context, 'create_profile.city_hint'),
                hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border, width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
        ),

        // ── Dropdown listesi ──────────────────────────────────────
        if (_showList)
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _border, width: 1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _filtered.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: _border.withOpacity(0.5),
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final city = _filtered[index];
                  return _CityListItem(
                    city: city,
                    onTap: () => _onSelect(city),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ── Şehir listesi satırı ──────────────────────────────────────────
class _CityListItem extends StatefulWidget {
  final CityModel city;
  final VoidCallback onTap;

  const _CityListItem({required this.city, required this.onTap});

  @override
  State<_CityListItem> createState() => _CityListItemState();
}

class _CityListItemState extends State<_CityListItem> {
  static const Color _surfaceHover = Color(0xFF221F3A);
  static const Color _accent = Color(0xFFB07BFF);
  static const Color _textPrimary = Color(0xFFF0EAFF);
  static const Color _textSecondary = Color(0xFF9985C0);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered ? _surfaceHover : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Şehir ikonu
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: _accent.withOpacity(0.7),
              ),
              const SizedBox(width: 10),
              // Şehir adı + ülke
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.city.city,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.city.country.isNotEmpty)
                      Text(
                        widget.city.country,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
