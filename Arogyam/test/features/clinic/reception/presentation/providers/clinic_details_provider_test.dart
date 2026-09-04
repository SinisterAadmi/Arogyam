import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/clinic/reception/data/datasources/reception_remote_datasource.dart';
import 'package:arogyam_flutter/features/clinic/reception/data/models/reception_queue_models.dart';
import 'package:arogyam_flutter/features/clinic/reception/presentation/providers/clinic_details_provider.dart';

class MockClinicDetailsRemoteDataSource extends ReceptionRemoteDataSource {
  ReceptionClinicModel _mockClinic = ReceptionClinicModel(
    id: 'clinic-123',
    name: 'Sunrise Medical Center',
    address: 'Sector 12, Dwarka, New Delhi',
    phone: '+91 22 2700 3300',
    specialty: 'Orthopedics & Multi-Specialty',
    operatingHours: 'Mon-Sat 9:00 AM - 9:00 PM',
    description: 'Premier outpatient clinic with digital queuing.',
    latitude: 28.5921,
    longitude: 77.0460,
    isLiveQueueActive: true,
    rating: 4.8,
    reviewCount: 42,
  );

  @override
  Future<ReceptionClinicModel> getClinic() async {
    return _mockClinic;
  }

  @override
  Future<ReceptionClinicModel> updateClinic({
    String? name,
    String? address,
    String? phone,
    String? specialty,
    String? operatingHours,
    String? description,
    double? latitude,
    double? longitude,
    bool? isOpen,
  }) async {
    _mockClinic = ReceptionClinicModel(
      id: _mockClinic.id,
      name: name ?? _mockClinic.name,
      address: address ?? _mockClinic.address,
      phone: phone ?? _mockClinic.phone,
      specialty: specialty ?? _mockClinic.specialty,
      operatingHours: operatingHours ?? _mockClinic.operatingHours,
      description: description ?? _mockClinic.description,
      latitude: latitude ?? _mockClinic.latitude,
      longitude: longitude ?? _mockClinic.longitude,
      isLiveQueueActive: _mockClinic.isLiveQueueActive,
      rating: _mockClinic.rating,
      reviewCount: _mockClinic.reviewCount,
      isOpen: isOpen ?? _mockClinic.isOpen,
    );
    return _mockClinic;
  }
}

void main() {
  group('ClinicDetailsProvider Tests', () {
    late ClinicDetailsProvider provider;
    late MockClinicDetailsRemoteDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockClinicDetailsRemoteDataSource();
      provider = ClinicDetailsProvider(dataSource: mockDataSource);
    });

    test('initial state is correct', () {
      expect(provider.isLoading, isFalse);
      expect(provider.isSaving, isFalse);
      expect(provider.clinic, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.successMessage, isNull);
    });

    test('fetchClinicDetails retrieves clinic model', () async {
      await provider.fetchClinicDetails();
      expect(provider.clinic, isNotNull);
      expect(provider.clinic?.name, 'Sunrise Medical Center');
      expect(provider.clinic?.latitude, 28.5921);
      expect(provider.clinic?.longitude, 77.0460);
    });

    test('saveClinicDetails updates location and details successfully', () async {
      await provider.fetchClinicDetails();
      final success = await provider.saveClinicDetails(
        name: 'Sunrise Super Specialty Hospital',
        address: 'Sector 14, Dwarka, New Delhi',
        phone: '+91 11 4500 9900',
        specialty: 'Cardiology & Critical Care',
        operatingHours: 'Mon-Sun 24/7',
        description: 'Updated state of the art cardiology care center.',
        latitude: 28.6010,
        longitude: 77.0520,
      );

      expect(success, isTrue);
      expect(provider.clinic?.name, 'Sunrise Super Specialty Hospital');
      expect(provider.clinic?.address, 'Sector 14, Dwarka, New Delhi');
      expect(provider.clinic?.phone, '+91 11 4500 9900');
      expect(provider.clinic?.specialty, 'Cardiology & Critical Care');
      expect(provider.clinic?.operatingHours, 'Mon-Sun 24/7');
      expect(provider.clinic?.description, 'Updated state of the art cardiology care center.');
      expect(provider.clinic?.latitude, 28.6010);
      expect(provider.clinic?.longitude, 77.0520);
      expect(provider.successMessage, contains('updated successfully'));
    });

    test('toggleClinicOpen updates open/closed status correctly', () async {
      await provider.fetchClinicDetails();
      expect(provider.clinic?.isOpen, isTrue);

      final result1 = await provider.toggleClinicOpen(false);
      expect(result1, isTrue);
      expect(provider.clinic?.isOpen, isFalse);

      final result2 = await provider.toggleClinicOpen(true);
      expect(result2, isTrue);
      expect(provider.clinic?.isOpen, isTrue);
    });
  });
}
