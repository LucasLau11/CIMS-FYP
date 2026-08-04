import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Result returned when the user confirms a location.
class PickedAddress {
  final String addressText;
  final double lat;
  final double lng;

  PickedAddress({required this.addressText, required this.lat, required this.lng});
}

class _SearchResult {
  final String displayName;
  final double lat;
  final double lng;

  _SearchResult({required this.displayName, required this.lat, required this.lng});
}

class AddressPickerScreen extends StatefulWidget {
  /// Optional starting point (e.g. the user's previously saved address).
  /// Defaults to Kuala Lumpur if not provided.
  final double? initialLat;
  final double? initialLng;

  const AddressPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  late latlng.LatLng _pickedPoint;
  String? _resolvedAddress;
  bool _isResolvingAddress = false;
  final MapController _mapController = MapController();

  final _searchController = TextEditingController();
  Timer? _debounce;
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _pickedPoint = latlng.LatLng(
      widget.initialLat ?? 3.1390, // Kuala Lumpur default
      widget.initialLng ?? 101.6869,
    );
    _resolveAddress(_pickedPoint);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Address search — uses Nominatim, OpenStreetMap's free search API.
  // No API key needed. Their usage policy asks for a descriptive
  // User-Agent header and a light request rate, which the debounce below
  // (500ms after typing stops) respects.
  // ---------------------------------------------------------------------
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '6',
        'addressdetails': '1',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'CIMS-FYP-App/1.0 (student project)'},
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _searchResults = data
              .map((item) => _SearchResult(
            displayName: item['display_name'] as String,
            lat: double.parse(item['lat'] as String),
            lng: double.parse(item['lon'] as String),
          ))
              .toList();
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorAddressSearchFailed(e.toString())), backgroundColor: AppColors.error),
      );
    }
  }

  void _selectSearchResult(_SearchResult result) {
    final point = latlng.LatLng(result.lat, result.lng);
    setState(() {
      _pickedPoint = point;
      _resolvedAddress = result.displayName;
      _searchResults = [];
      _searchController.clear();
    });
    FocusScope.of(context).unfocus();
    _mapController.move(point, 16);
  }

  // ---------------------------------------------------------------------
  // Reverse geocoding — used when the user fine-tunes the pin manually
  // after picking a search result (or taps the map directly).
  // ---------------------------------------------------------------------
  Future<void> _resolveAddress(latlng.LatLng point) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isResolvingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.postalCode,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.trim().isNotEmpty).toList();
        setState(() {
          _resolvedAddress = parts.join(', ');
          _isResolvingAddress = false;
        });
      } else {
        setState(() {
          _resolvedAddress = l10n.unknownLocationCoords(point.latitude.toStringAsFixed(5), point.longitude.toStringAsFixed(5));
          _isResolvingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolvedAddress = l10n.errorCouldNotResolveAddress;
        _isResolvingAddress = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, latlng.LatLng point) {
    setState(() => _pickedPoint = point);
    _resolveAddress(point);
  }

  void _confirm() {
    if (_resolvedAddress == null || _isResolvingAddress) return;
    Navigator.pop(
      context,
      PickedAddress(
        addressText: _resolvedAddress!,
        lat: _pickedPoint.latitude,
        lng: _pickedPoint.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectYourAddress,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedPoint,
              initialZoom: 15,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.cims.fyp_cims',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedPoint,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_on, color: AppColors.error, size: 40),
                  ),
                ],
              ),
              // Required attribution for OpenStreetMap usage.
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // Search bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: l10n.searchForYourAddressHint,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: _isSearching
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : (_searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, size: 20, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                          : null),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                          title: Text(
                            result.displayName,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.mapSearchOrTapHint,
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isResolvingAddress
                            ? Text(l10n.resolvingAddress,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 13))
                            : Text(
                          _resolvedAddress ?? '',
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isResolvingAddress ? null : _confirm,
                      child: Text(l10n.confirmThisAddress),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}