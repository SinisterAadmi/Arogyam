import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../core/constants/api_constants.dart';
import '../../providers/clinic_details_provider.dart';

class EditClinicPage extends StatefulWidget {
  const EditClinicPage({super.key});

  @override
  State<EditClinicPage> createState() => _EditClinicPageState();
}

class _EditClinicPageState extends State<EditClinicPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng? _selectedLocation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ClinicDetailsProvider>();
      await provider.fetchClinicDetails();
      if (mounted && provider.clinic != null) {
        final c = provider.clinic!;
        _nameController.text = c.name;
        _addressController.text = c.address;
        setState(() {
          _selectedLocation = LatLng(c.latitude, c.longitude);
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a map location for your clinic'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final provider = context.read<ClinicDetailsProvider>();
    final success = await provider.saveClinicDetails(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Clinic location updated live on patient map!',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicDetailsProvider>();
    final initialCenter = _selectedLocation ?? const LatLng(28.5921, 77.0460);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Clinic Details & Location',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: provider.isLoading && !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),

                    if (provider.errorMessage != null) ...[
                      _buildErrorBanner(provider.errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'Clinic Information',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Clinic Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Clinic Name',
                        hintText: 'e.g. Sunrise Medical Center',
                        prefixIcon: const Icon(LucideIcons.building2, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Clinic name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Clinic Address Field
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Street Address',
                        hintText: 'e.g. Sector 12, Dwarka, New Delhi',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(LucideIcons.mapPin, size: 18),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Map Location Picker Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Map Pin Location',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap anywhere on the map to set exact coordinates',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_selectedLocation != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCCFBF1)),
                            ),
                            child: Text(
                              '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Map Container
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: initialCenter,
                              initialZoom: 15.0,
                              minZoom: 3.0,
                              maxZoom: 18.0,
                              onTap: _handleMapTap,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${ApiConstants.mapTilerApiKey}',
                                userAgentPackageName: 'com.example.arogyam',
                                tileProvider: NetworkTileProvider(),
                              ),
                              if (_selectedLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _selectedLocation!,
                                      width: 140,
                                      height: 50,
                                      child: _buildSelectedMarker(),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      onTap: () {
                                        final currentZoom = _mapController.camera.zoom;
                                        _mapController.move(_mapController.camera.center, (currentZoom + 1.0).clamp(2.0, 18.0));
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(LucideIcons.plus, size: 16, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ),
                                  Container(width: 24, height: 1, color: AppColors.border),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                      onTap: () {
                                        final currentZoom = _mapController.camera.zoom;
                                        _mapController.move(_mapController.camera.center, (currentZoom - 1.0).clamp(2.0, 18.0));
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Icon(LucideIcons.minus, size: 16, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: FloatingActionButton.small(
                              heroTag: 'recenter_clinic_btn',
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.teal,
                              onPressed: () {
                                if (_selectedLocation != null) {
                                  _mapController.move(_selectedLocation!, 15.0);
                                }
                              },
                              child: const Icon(LucideIcons.locateFixed, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: provider.isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: provider.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.save, size: 18),
                        label: Text(
                          provider.isSaving ? 'Saving Changes...' : 'Save Clinic Location & Info',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSelectedMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.building2, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Clinic Pin',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          LucideIcons.mapPin,
          size: 24,
          color: AppColors.teal,
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Changes saved here immediately update the live location and name visible on the patient-side Nearby Clinics map.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E40AF), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 18, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }
}
