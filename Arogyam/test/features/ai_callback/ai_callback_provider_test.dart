import 'package:flutter_test/flutter_test.dart';
import 'package:arogyam_flutter/features/ai_callback/domain/repositories/ai_callback_repository.dart';
import 'package:arogyam_flutter/features/ai_callback/domain/usecases/request_callback.dart';
import 'package:arogyam_flutter/features/ai_callback/domain/usecases/cancel_callback.dart';
import 'package:arogyam_flutter/features/ai_callback/domain/usecases/get_callback_status.dart';
import 'package:arogyam_flutter/features/ai_callback/domain/usecases/trigger_vapi_callback.dart';
import 'package:arogyam_flutter/features/ai_callback/presentation/providers/ai_callback_provider.dart';

class MockAiCallbackRepo extends AiCallbackRepository {
  bool requestCalled = false;
  bool triggerVapiCalled = false;
  bool cancelCalled = false;

  Map<String, dynamic> vapiResult = {
    'appointmentId': 'appt-123',
    'vapiCallId': 'vapi-call-456',
    'status': 'pending',
    'doctorName': 'Dr. Test Sharma',
    'specialty': 'Cardiology',
    'clinicName': 'Test Heart Clinic',
    'clinicPhone': '+919876543210',
    'scheduledAt': '2026-09-03T10:00:00.000Z',
  };

  @override
  Future<Map<String, dynamic>> requestCallback(String clinicId, String phone, String scheduledAt) async {
    requestCalled = true;
    return {'requestId': 'req-1', 'status': 'pending'};
  }

  @override
  Future<Map<String, dynamic>> triggerVapiCallback({
    required String clinicId,
    String? doctorId,
    String? scheduledAt,
    String? phone,
  }) async {
    triggerVapiCalled = true;
    return vapiResult;
  }

  @override
  Future<Map<String, dynamic>> getCallbackStatus() async {
    return {'status': 'pending'};
  }

  @override
  Future<void> cancelCallback() async {
    cancelCalled = true;
  }
}

void main() {
  late MockAiCallbackRepo mockRepo;
  late AiCallbackProvider provider;

  setUp(() {
    mockRepo = MockAiCallbackRepo();
    provider = AiCallbackProvider(
      requestCallbackUseCase: RequestCallback(mockRepo),
      cancelCallbackUseCase: CancelCallback(mockRepo),
      getCallbackStatusUseCase: GetCallbackStatus(mockRepo),
      triggerVapiCallbackUseCase: TriggerVapiCallback(mockRepo),
    );
  });

  test('initial state has no active call or outcome', () {
    expect(provider.isLoading, isFalse);
    expect(provider.isCalling, isFalse);
    expect(provider.isRequested, isFalse);
    expect(provider.outcome, isNull);
    expect(provider.activeAppointmentId, isNull);
  });

  test('triggerVapiCall updates active appointment and in-progress calling state', () async {
    await provider.triggerVapiCall(
      clinicId: 'clinic-1',
      doctorId: 'doc-1',
      scheduledAt: '2026-09-03T10:00:00.000Z',
      phone: '+919876543210',
    );

    expect(mockRepo.triggerVapiCalled, isTrue);
    expect(provider.isRequested, isTrue);
    expect(provider.activeAppointmentId, 'appt-123');
    expect(provider.vapiCallId, 'vapi-call-456');
    expect(provider.doctorName, 'Dr. Test Sharma');
    expect(provider.clinicName, 'Test Heart Clinic');
    expect(provider.clinicPhone, '+919876543210');
    expect(provider.status, 'pending');
  });

  test('cancelCallback clears active state and calls repo', () async {
    await provider.triggerVapiCall(clinicId: 'clinic-1');
    expect(provider.activeAppointmentId, isNotNull);

    await provider.cancelCallback();
    expect(mockRepo.cancelCalled, isTrue);
    expect(provider.isRequested, isFalse);
    expect(provider.activeAppointmentId, isNull);
    expect(provider.status, 'cancelled');
  });

  test('reset restores initial state', () async {
    await provider.triggerVapiCall(clinicId: 'clinic-1');
    provider.reset();

    expect(provider.activeAppointmentId, isNull);
    expect(provider.outcome, isNull);
    expect(provider.isCalling, isFalse);
    expect(provider.isRequested, isFalse);
  });
}
