import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../app/router/route_names.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../../core/security/token_manager.dart';
import '../../../../../../core/socket/socket_service.dart';
import '../queue_management/queue_page.dart';
import '../patient_check_in/check_in_page.dart';
import '../reception_stats/stats_page.dart';
import '../clinic_details/clinic_details_page.dart';

class ReceptionMainScreen extends StatefulWidget {
  const ReceptionMainScreen({super.key});

  @override
  State<ReceptionMainScreen> createState() => _ReceptionMainScreenState();
}

class _ReceptionMainScreenState extends State<ReceptionMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await TokenManager().getAccessToken();
      if (token != null) {
        debugPrint('[DIAGNOSTIC] [ReceptionMainScreen] Initializing SocketService for reception with token...');
        SocketService().connect(token: token);
      }
    });
  }

  final List<Widget> _pages = const [
    QueuePage(),
    CheckInPage(),
    StatsPage(),
    ClinicDetailsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final staffName = user?.reception?.name ?? 'Reception Staff';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.userCheck, size: 20, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    staffName,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Reception Staff',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.receptionClinicEdit);
            },
            icon: const Icon(LucideIcons.mapPin, size: 20, color: AppColors.teal),
            tooltip: 'Quick Map Pin Editor',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.teal,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.listOrdered),
              label: 'Live Queue',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.scanLine),
              label: 'Check-In',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.barChart3),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.building2),
              label: 'Clinic Details',
            ),
          ],
        ),
      ),
    );
  }
}
