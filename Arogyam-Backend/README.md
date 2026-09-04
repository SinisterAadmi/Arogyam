# Arogyam Backend

Node.js, TypeScript, Express, Prisma, PostgreSQL, Redis, Firebase Auth, and Socket.io foundation for the Arogyam Healthcare Ecosystem.

## Tech Stack
- **Runtime**: Node.js
- **Language**: TypeScript
- **Framework**: Express
- **ORM**: Prisma (PostgreSQL)
- **Cache**: Redis
- **Auth**: Firebase Admin SDK (Custom Claims for Roles)
- **Real-time**: Socket.io

## Prerequisites
- Node.js (v18+)
- PostgreSQL
- Redis
- Firebase Project with Service Account

## Setup Instructions

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Configure Environment**
   - Copy `.env.example` to `.env`.
   - Update `DATABASE_URL`, `REDIS_URL`, and Firebase credentials.

3. **Database Migration**
   ```bash
   npx prisma migrate dev --name init
   ```

4. **Seed Data**
   ```bash
   npm run prisma:seed
   ```

5. **Run Development Server**
   ```bash
   npm run dev
   ```

## Implemented Patient Routes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/patients/me` | Get current patient profile |
| PATCH | `/api/patients/me` | Update patient profile |
| GET | `/api/patients/clinics/nearby` | Find nearby clinics with wait times |
| GET | `/api/patients/appointments/upcoming` | List scheduled appointments |
| POST | `/api/patients/appointments` | Book a new appointment |
| GET | `/api/patients/queue/status` | Get current live queue position |
| POST | `/api/patients/queue/join` | Join a clinic's live queue |
| GET | `/api/patients/prescriptions/active` | Get valid prescriptions |
| GET | `/api/patients/medical-history` | Get patient medical records |

## WebSocket Events
- **`join`**: Send `{ token: "FIREBASE_ID_TOKEN" }` after connection to authenticate and join private room.
- **`authenticated`**: Received upon successful post-connect auth.

## Architecture Highlights
- **Advisory Locks**: Uses PostgreSQL advisory locks for race-condition-free token number generation in the queue.
- **Role-Based Access**: Middleware verifies Firebase custom claims against Prisma roles.
- **Flutter Compatibility**: JSON response fields match Flutter model naming conventions (camelCase).
