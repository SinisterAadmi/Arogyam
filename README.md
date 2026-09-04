# 🌿 Arogyam - Smart Healthcare & Live Queue Management Ecosystem

A comprehensive, full-stack healthcare management ecosystem combining a **Flutter cross-platform mobile application** with a high-performance **Node.js/TypeScript backend** powered by Express, Prisma ORM, PostgreSQL, Redis, Socket.io, Firebase Auth, and Vapi AI.

---

## 🏗️ Repository Architecture

The project is structured as a clean monorepo with strict separation of concerns:

```
Arogyam/
├── 📱 Arogyam/               # Frontend Mobile Application (Flutter / Dart)
│   ├── android/              # Android native wrapper & configurations
│   ├── ios/                  # iOS native wrapper & configurations
│   ├── lib/                  # Core Flutter application source (Clean Architecture)
│   │   ├── app/              # Router, theme, configs, role-based redirects
│   │   ├── core/             # Network, security, biometrics, socket client, errors
│   │   ├── features/         # Feature modules (auth, patient, clinic, reception, ai_callback)
│   │   └── shared/           # Shared models, entities, and universal widgets
│   ├── test/                 # Flutter unit and widget test suites
│   └── pubspec.yaml          # Flutter dependencies and assets
│
├── ⚙️ Arogyam-Backend/       # Backend Services & APIs (Node.js / Express / Prisma)
│   ├── prisma/               # Database schema, migrations, and seed scripts
│   ├── src/                  # Backend application source code
│   │   ├── controllers/      # Route controllers (Auth, Patient, Reception, Vapi)
│   │   ├── lib/              # Integrations (Firebase Admin, Prisma, Redis)
│   │   ├── middleware/       # Role-based authorization & authentication guards
│   │   ├── routes/           # REST API routes
│   │   ├── scripts/          # Diagnostic, security verification, and test suites
│   │   ├── services/         # Core business logic & database services
│   │   ├── utils/            # Timezone and date helpers
│   │   ├── index.ts          # Express server initialization
│   │   └── socket.ts         # Real-time WebSocket connection handler
│   ├── package.json          # Node dependencies and scripts
│   ├── tsconfig.json         # TypeScript compiler configuration
│   └── .env.example          # Safe configuration template (dummy values)
│
└── 🛡️ .gitignore             # Strict secret and build artifact exclusion rules
```

---

## 🚀 Accomplishments & Features Built Till Now

### 📱 1. Frontend Mobile Application (`Arogyam/`)

Built with **Flutter (Dart)** following **Clean Architecture** principles (Presentation, Domain, Data layers) and reactive state management (`provider`):

* **Interactive Map & Nearby Clinics**:
  * Full-screen interactive map using `flutter_map` and MapTiler tiles.
  * Medical-themed pill markers for clinics with live wait times and ratings.
  * Draggable "Uber/Rapido-style" sheet (`DraggableScrollableSheet`) with snap points (15%, 55%, 90%).
  * Multi-criteria clinic sorting: by **Distance** (nearest), **Wait Time** (shortest), **Rating** (highest), or **Live Queue Availability**.
* **Live Queue System**:
  * Real-time patient queue token tracking.
  * Live status display: current serving token, people ahead, estimated wait time, and completion banners.
  * Live socket updates connecting patient devices to reception events.
* **Appointment Booking & Management**:
  * Clinic visit scheduling with doctor selection, date picker, and time slot selection.
  * Appointment cancellation, status tracking, and details bottom sheet.
* **Clinic & Receptionist Portal**:
  * Reception dashboard showing live queue stats (patients served today, currently waiting, currently serving).
  * Hourly patient flow charts and wait time analytics.
  * Queue status controls: mark tokens as `serving`, `done`, or `absent`.
  * Patient check-in via short code and QR code scanning.
* **Authentication & Biometrics**:
  * Firebase phone/OTP authentication with role-based routing (`RoleRedirect`).
  * Biometric authentication (`local_auth`) for fast, secure patient unlocking.
  * Digital health records, active prescription lists, and ABHA-compatible NFC record sharing.
* **Vapi AI Callback Integration**:
  * In-app trigger for outbound AI voice confirmations.
  * Live call status cards and outcome badges.

---

### ⚙️ 2. Backend Services & APIs (`Arogyam-Backend/`)

Built with **Node.js, TypeScript, Express, Prisma ORM, PostgreSQL (Neon), Redis, and Socket.io**:

* **Concurrency-Safe Queue Token Allocation**:
  * Uses PostgreSQL transaction-level advisory locks (`pg_advisory_xact_lock`) to eliminate token number collision race conditions under heavy load.
  * Automated date-scoping and timezone awareness (`Asia/Kolkata`) for accurate daily queue resets.
* **Role-Based Access Control (RBAC)**:
  * Strict authentication middleware (`authMiddleware.ts`) verifying Firebase ID tokens and custom user claims.
  * Scoped clinic data access: Receptionists and staff can only view and update tokens belonging strictly to their clinic.
* **Vapi AI Voice Calling & Webhook Pipeline**:
  * Automated outbound phone calls in conversational Hindi/English for appointment reminders and confirmations.
  * Secure webhook receiver (`/api/webhooks/vapi`) verifying cryptographic signatures.
  * Automated state machine updating database records based on patient responses (`confirmed`, `rescheduled`, `cancelled`).
* **Real-Time WebSockets (`Socket.io`)**:
  * Token-authenticated socket rooms isolated per user and clinic.
  * Broadcasts live token transitions (`waiting` ➔ `serving` ➔ `done`) to all connected devices instantly.
* **Consent Session & QR Check-In**:
  * Short code and QR token generator for contact-free clinic registration.
  * Time-limited consent sessions to authorize receptionists to access patient health profiles.

---

## 📡 Backend API Endpoints Reference

### 🏥 Patient Endpoints (`/api/patients`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/patients/me` | Fetch authenticated patient profile |
| `PATCH` | `/api/patients/me` | Update personal details (name, DOB, gender) |
| `GET` | `/api/patients/clinics/nearby` | Discover clinics with wait times and queue counters |
| `GET` | `/api/patients/appointments/upcoming`| List scheduled upcoming appointments |
| `POST` | `/api/patients/appointments` | Book a new clinic appointment |
| `DELETE`| `/api/patients/appointments/:id` | Cancel a scheduled appointment |
| `GET` | `/api/patients/queue/status` | Get patient's live active queue token and position |
| `POST` | `/api/patients/queue/join` | Join a clinic's walk-in live queue |
| `GET` | `/api/patients/prescriptions/active`| Retrieve valid digital prescriptions |
| `GET` | `/api/patients/medical-history` | View encrypted patient health records |

### 🏨 Reception Endpoints (`/api/reception`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/reception/queue/live` | Get current clinic live queue and stats |
| `PATCH` | `/api/reception/queue/token/:tokenId` | Advance token status (`serving`, `done`, `absent`) |
| `GET` | `/api/reception/clinic` | Fetch reception's clinic settings |
| `PATCH` | `/api/reception/clinic` | Update clinic operating hours and status |
| `POST` | `/api/reception/consent/verify` | Verify patient QR code or short code check-in |

### 🤖 AI Webhooks (`/api/webhooks`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/webhooks/vapi` | Ingest and process Vapi AI call status and transcripts |

---

## 🔐 Security & Secret Protection

To ensure patient privacy and system security:
* **Committed Files**: Only source code, tests, schemas, and [`.env.example`](file:///d:/Arogyam/Arogyam-Backend/.env.example) (template with dummy placeholders) are tracked in version control.
* **Excluded Files**:
  * Real `.env` files (database passwords, private keys, API secrets).
  * Sensitive data dumps (`vapi-call-details.json`, `latest_vapi_webhook.json`) containing call audio URLs and patient phone numbers.
  * Build outputs (`dist/`, `build/`, `.dart_tool/`, `node_modules/`).
* Both root and subfolder `.gitignore` files enforce wildcard protections (`**/.env`, `**/*.log`, etc.).

---

## 🛠️ Getting Started Locally

### Prerequisites
* **Node.js** (v18+) & **npm**
* **Flutter SDK** (v3.19+) & **Dart**
* **PostgreSQL Database** (Local or cloud e.g. Neon, Supabase)
* **Redis Server** (Local or cloud)
* **Firebase Project** with Authentication enabled

---

### Backend Setup (`Arogyam-Backend/`)

1. **Navigate to the backend directory**:
   ```bash
   cd Arogyam-Backend
   ```
2. **Install dependencies**:
   ```bash
   npm install
   ```
3. **Configure environment variables**:
   ```bash
   cp .env.example .env
   ```
   Fill in your actual `DATABASE_URL`, `REDIS_URL`, `FIREBASE_*`, and `VAPI_*` credentials.
4. **Run database migrations**:
   ```bash
   npx prisma migrate dev
   ```
5. **Seed demo data**:
   ```bash
   npm run prisma:seed
   ```
6. **Start development server**:
   ```bash
   npm run dev
   ```

---

### Frontend Setup (`Arogyam/`)

1. **Navigate to the frontend directory**:
   ```bash
   cd Arogyam
   ```
2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```
3. **Run on an emulator or physical device**:
   ```bash
   flutter run
   ```

---

## 🧪 Verification & Diagnostic Scripts

The backend includes test and diagnostic scripts inside `Arogyam-Backend/src/scripts/`:

| Script | Purpose |
|---|---|
| `verifyReceptionSuite.ts` | Validates QR and consent code generation and verification |
| `verifyQueueFixes.ts` | Validates concurrency locks and zero-duplication queue tokens |
| `verifyAiCallbackIsolation.ts` | Verifies cross-clinic authorization isolation |
| `testVapiOutboundFlow.ts` | Simulates and tests the complete outbound voice calling lifecycle |
| `testMaliciousClinicPatch.ts` | Asserts that unauthorized clinic modification attempts return 403 |

Run any verification script with:
```bash
npx ts-node src/scripts/<script_name>.ts
```
