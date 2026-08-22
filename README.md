# Arogyam Flutter Application

Arogyam is a digital healthcare application designed to streamline clinic workflows, patient consultations, queue management, prescription verification, pharmacy auditing, and disease monitoring.

---

## 📁 Project Directory Structure

```text
Arogyam/
├── android/                             # Android native configurations & platform code
├── ios/                                 # iOS native configurations & platform code
├── test/                                # Unit and widget test suite
├── pubspec.yaml                         # Flutter dependencies & project metadata
├── analysis_options.yaml                # Dart analyzer rules & linting configs
└── lib/
    ├── main.dart                        # Application entry point
    │
    ├── app/                             # Core App configuration & setup
    │   ├── app.dart                     # Main app widget configuration
    │   ├── bootstrap.dart               # App initialization logic
    │   ├── config/                      # Environment & feature flag configurations
    │   │   ├── app_config.dart
    │   │   ├── environment.dart
    │   │   └── feature_flags.dart
    │   ├── router/                      # App routing, guards & role redirects
    │   │   ├── app_router.dart
    │   │   ├── role_redirect.dart
    │   │   ├── route_guards.dart
    │   │   └── route_names.dart
    │   └── theme/                       # App themes, typography, colors & spacing
    │       ├── app_colors.dart
    │       ├── app_spacing.dart
    │       ├── app_theme.dart
    │       └── app_typography.dart
    │
    ├── core/                            # Core shared infrastructure & utilities
    │   ├── constants/                   # Global, API, and Security constants
    │   │   ├── api_constants.dart
    │   │   ├── app_constants.dart
    │   │   └── security_constants.dart
    │   ├── device/                      # Device info & network connectivity
    │   │   ├── connectivity_service.dart
    │   │   └── device_info_service.dart
    │   ├── errors/                      # Error handling, failures, and custom exceptions
    │   │   ├── error_handler.dart
    │   │   ├── exceptions.dart
    │   │   └── failures.dart
    │   ├── location/                    # Geofence & location services
    │   │   ├── distance_calculator.dart
    │   │   ├── geofence_service.dart
    │   │   └── location_service.dart
    │   ├── network/                     # HTTP client, interceptors & network status
    │   │   ├── api_client.dart
    │   │   ├── api_response.dart
    │   │   ├── network_info.dart
    │   │   └── interceptors/
    │   │       ├── auth_interceptor.dart
    │   │       ├── logging_interceptor.dart
    │   │       └── refresh_token_interceptor.dart
    │   ├── nfc/                         # NFC session, permissions & communication
    │   │   ├── nfc_permission.dart
    │   │   ├── nfc_service.dart
    │   │   └── nfc_session.dart
    │   ├── notifications/               # Push notification handling & services
    │   │   ├── notification_handler.dart
    │   │   └── notification_service.dart
    │   ├── security/                    # Biometrics, encryption, tokens & permissions
    │   │   ├── biometric_service.dart
    │   │   ├── encryption_service.dart
    │   │   ├── permission_service.dart
    │   │   └── token_manager.dart
    │   ├── storage/                     # Local storage, caching & secure storage
    │   │   ├── cache_manager.dart
    │   │   ├── local_storage.dart
    │   │   └── secure_storage.dart
    │   ├── utils/                       # Utility formatters, debouncers & validators
    │   │   ├── date_utils.dart
    │   │   ├── debouncer.dart
    │   │   ├── formatters.dart
    │   │   └── validators.dart
    │   └── widgets/                     # Common reusable UI components
    │       ├── app_bottom_navigation.dart
    │       ├── app_button.dart
    │       ├── app_card.dart
    │       ├── app_empty_view.dart
    │       ├── app_error_view.dart
    │       ├── app_loader.dart
    │       └── app_text_field.dart
    │
    ├── features/                        # Feature-first domain modules
    │   │
    │   ├── auth/                        # Authentication & Authorization
    │   │   ├── data/                    # Datasources, models, repositories
    │   │   ├── domain/                  # Entities, repository interfaces, usecases
    │   │   └── presentation/            # Login page & Auth state providers
    │   │
    │   ├── patient/                     # Patient-facing portal & features
    │   │   ├── data/                    # Datasources (ABHA, appointments, clinics, history, prescriptions, queue)
    │   │   ├── domain/                  # Patient domain entities, usecases (ABHA link, book appointment, NFC share)
    │   │   └── presentation/
    │   │       ├── pages/               # ABHA linking, appointments, history, nearby clinics, NFC share, queue status
    │   │       ├── providers/           # State providers for patient interactions
    │   │       └── widgets/             # Specialized UI cards and components
    │   │
    │   ├── clinic/                      # Clinic operations (Doctor, Reception, Shared)
    │   │   ├── doctor/
    │   │   │   └── presentation/        # Consultation, doctor dashboard, records, prescription writer
    │   │   ├── reception/
    │   │   │   └── presentation/        # Patient check-in, queue management, reception stats
    │   │   └── shared/                  # Shared clinic data models
    │   │
    │   ├── pharmacy/                    # Pharmacy portal & medicine management
    │   │   ├── data/                    # Inventory, pharmacy & prescription datasources/models
    │   │   ├── domain/                  # Dispense medicine, controlled drugs log, verify prescriptions
    │   │   └── presentation/            # Pharmacy dashboard, inventory management, verify prescription
    │   │
    │   ├── admin/                       # Administrative & public health monitoring
    │   │   ├── data/                    # Analytics, disease trends, audit datasources & models
    │   │   ├── domain/                  # Doctor risk score, national stats & trend usecases
    │   │   └── presentation/            # Admin dashboard, disease trends, audits & outbreak monitoring
    │   │
    │   ├── ai_callback/                 # AI-assisted patient callback management
    │   │   ├── data/                    # Remote datasources & session models
    │   │   ├── domain/                  # Session entities & callback usecases
    │   │   └── presentation/
    │   │
    │   └── queue/                       # Dedicated queue management domain logic
    │       └── domain/usecases/         # Auto check-in, join queue, leave queue, queue status
    │
    └── shared/                          # Cross-feature shared domain entities & widgets
        ├── entities/                    # Clinic, Doctor, Medicine, Patient, Prescription, User
        ├── enums/                       # AppointmentStatus, PrescriptionStatus, QueueStatus, UserRole
        ├── models/                      # Shared models
        └── widgets/                     # Shared composite widgets
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.12.2`)
- Android Studio / VS Code with Flutter and Dart extensions
- Android / iOS emulator or physical device

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Arogyam
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```
