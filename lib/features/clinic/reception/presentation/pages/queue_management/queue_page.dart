import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../core/mixins/polling_mixin.dart';
import '../../providers/reception_queue_provider.dart';
import '../../widgets/queue_patient_card.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> with WidgetsBindingObserver, PollingMixin<QueuePage> {
  @override
  Duration get pollingInterval => const Duration(seconds: 15);

  @override
  int? get tabIndex => 0;

  @override
  Future<void> onPoll() async {
    if (mounted) {
      await context.read<ReceptionQueueProvider>().fetchQueue(silent: true);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceptionQueueProvider>().fetchQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceptionQueueProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(provider),
            _buildStatsRow(provider),
            _buildFilterChips(provider),
            Expanded(
              child: provider.isLoading && provider.allTokens.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : RefreshIndicator(
                      color: AppColors.teal,
                      onRefresh: () => provider.fetchQueue(),
                      child: provider.filteredTokens.isEmpty
                          ? _buildEmptyState(provider)
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              itemCount: provider.filteredTokens.length,
                              itemBuilder: (context, index) {
                                final token = provider.filteredTokens[index];
                                return QueuePatientCard(
                                  token: token,
                                  onUpdateStatus: (newStatus) async {
                                    final success = await provider.updateStatus(token.id, newStatus);
                                    if (success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Token #${token.tokenNumber} marked as $newStatus'),
                                          backgroundColor: AppColors.teal,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ReceptionQueueProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Clinic Queue',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16A34A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  provider.clinicName,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => provider.fetchQueue(),
            icon: const Icon(LucideIcons.refreshCw, size: 20, color: AppColors.teal),
            tooltip: 'Refresh Queue',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ReceptionQueueProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatBox(
              label: 'Waiting',
              value: '${provider.waitingCount}',
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatBox(
              label: 'Now Serving',
              value: provider.currentlyServing != null ? '#${provider.currentlyServing}' : 'None',
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatBox(
              label: 'Total Today',
              value: '${provider.totalToday}',
              color: AppColors.textPrimary,
              bgColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ReceptionQueueProvider provider) {
    final filters = [
      {'id': 'all', 'label': 'All (${provider.allTokens.length})'},
      {'id': 'waiting', 'label': 'Waiting (${provider.waitingCount})'},
      {'id': 'serving', 'label': 'Serving'},
      {'id': 'done', 'label': 'Done'},
      {'id': 'absent', 'label': 'Absent'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = provider.selectedFilter == filter['id'];
          return ChoiceChip(
            label: Text(
              filter['label']!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.teal,
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? AppColors.teal : AppColors.border),
            onSelected: (_) => provider.setFilter(filter['id']!),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ReceptionQueueProvider provider) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.users, size: 48, color: AppColors.teal),
              ),
              const SizedBox(height: 20),
              Text(
                provider.selectedFilter == 'all' ? 'No Patients in Queue' : 'No ${provider.selectedFilter.toUpperCase()} Patients',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.selectedFilter == 'all'
                    ? 'Patients joining the queue online or at the clinic desk will appear here in real-time.'
                    : 'Switch back to "All" to view the full queue list.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => provider.fetchQueue(),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Refresh Queue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
