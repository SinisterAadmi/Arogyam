import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/router/route_names.dart';
import '../../../../../core/location/location_service.dart';
import '../../../../../core/widgets/app_map_view.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../shared/widgets/page_header.dart';
import '../../providers/nearby_clinics_provider.dart';
import '../../widgets/clinic_bottom_sheet.dart';
import '../../widgets/clinic_about_bottom_sheet.dart';
import '../../widgets/clinic_card.dart';
import '../../../../../core/widgets/app_refresh_progress_bar.dart';
import '../../../../../core/mixins/polling_mixin.dart';
import '../../../../../shared/entities/clinic.dart';
import '../../providers/queue_provider.dart';

class NearbyClinicsPage extends StatefulWidget {
  const NearbyClinicsPage({super.key});

  @override
  State<NearbyClinicsPage> createState() => _NearbyClinicsPageState();
}

class _NearbyClinicsPageState extends State<NearbyClinicsPage>
    with WidgetsBindingObserver, PollingMixin<NearbyClinicsPage> {
  bool _isMapView = true;
  bool _isLocating = false;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialLocation();
    });
  }

  Future<void> _fetchInitialLocation() async {
    final pos = await LocationService().getCurrentLocation(fallbackToDefault: false);
    if (pos != null && mounted) {
      context.read<NearbyClinicsProvider>().setUserLocation(pos);
      _mapController.move(pos, 14.0);
    }
  }

  Future<void> _handleCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final pos = await LocationService().getCurrentLocation(
        fallbackToDefault: false,
        timeout: const Duration(seconds: 10),
      );

      if (!mounted) return;

      if (pos != null) {
        context.read<NearbyClinicsProvider>().fetchNearbyClinics(
          lat: pos.latitude,
          lng: pos.longitude,
        );
        _mapController.move(pos, 15.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Located: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.teal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location permission not granted or GPS unavailable. Using default clinic area.',
            ),
            backgroundColor: const Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleCurrentLocation,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error acquiring location: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _handleJoinQueue(BuildContext context, Clinic clinic) async {
    final queueProvider = context.read<QueueProvider>();
    final success = await queueProvider.joinQueue(clinic.id);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${clinic.name} queue (#${queueProvider.status?.tokenNumber})'),
          backgroundColor: const Color(0xFF0D9488),
        ),
      );
      Navigator.of(context, rootNavigator: true).pushNamed(RouteNames.queueStatus);
    } else {
      final msg = queueProvider.errorMessage ?? 'Failed to join queue. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleAbout(BuildContext context, Clinic clinic) {
    ClinicAboutBottomSheet.show(
      context,
      clinic: clinic,
      onJoinQueue: () => _handleJoinQueue(context, clinic),
      onBookVisit: () {
        Navigator.of(context, rootNavigator: true).pushNamed(
          RouteNames.appointmentBooking,
          arguments: clinic,
        );
      },
    );
  }

  void _onClinicSelected(Clinic clinic) {
    final provider = context.read<NearbyClinicsProvider>();
    provider.selectClinic(clinic.id);
    _mapController.move(LatLng(clinic.latitude, clinic.longitude), 15.0);
  }

  @override
  Duration get pollingInterval => const Duration(seconds: 30);

  @override
  int? get tabIndex => 1;

  @override
  Future<void> onPoll() async {
    if (mounted) {
      await context.read<NearbyClinicsProvider>().refresh();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NearbyClinicsProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            AppRefreshProgressBar(isRefreshing: provider.isRefreshing),
            _buildHeader(),
            _buildSearchAndToggle(),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading && provider.clinics.isEmpty) {
                    return const Center(child: AppLoader());
                  }

                  if (provider.errorMessage != null && provider.clinics.isEmpty) {
                    return AppErrorView(
                      message: provider.errorMessage!,
                      onRetry: () => provider.fetchNearbyClinics(),
                    );
                  }

                  return Stack(
                    children: [
                      if (_isMapView)
                        AppMapView(
                          controller: _mapController,
                          clinics: provider.clinics,
                          userLocation: provider.userLocation,
                          selectedClinicId: provider.selectedClinicId,
                          onMarkerTap: _onClinicSelected,
                          onLocationTap: _handleCurrentLocation,
                          isLocating: _isLocating,
                        )
                      else
                        ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: provider.clinics.length,
                          itemBuilder: (context, index) {
                            final clinic = provider.clinics[index];
                            final isSelected = provider.selectedClinicId == clinic.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClinicCard(
                                clinic: clinic,
                                isSelected: isSelected,
                                onTap: () => _onClinicSelected(clinic),
                                onAbout: () => _handleAbout(context, clinic),
                                onJoinQueue: () => _handleJoinQueue(context, clinic),
                                onBookVisit: () {
                                  Navigator.of(context, rootNavigator: true).pushNamed(
                                    RouteNames.appointmentBooking,
                                    arguments: clinic,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      if (_isMapView)
                        ClinicBottomSheet(
                          clinics: provider.clinics,
                          onClinicSelected: _onClinicSelected,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return PageHeader(
      child: Row(
        children: [
          const SizedBox(width: 48),
          Text(
            'Nearby Clinics',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndToggle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => context.read<NearbyClinicsProvider>().searchClinics(value),
                      decoration: const InputDecoration(
                        hintText: 'Search clinics or speciality',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _isMapView = !_isMapView),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isMapView ? LucideIcons.list : LucideIcons.map,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
