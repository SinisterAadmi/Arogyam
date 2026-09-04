import { PrismaClient, Role } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
  await prisma.queueToken.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.doctor.deleteMany();
  await prisma.patient.deleteMany();
  await prisma.clinic.deleteMany();
  await prisma.user.deleteMany();
  const clinics = await Promise.all([
    prisma.clinic.create({
      data: {
        name: 'City Care Hospital',
        address: '123 Main St, Mumbai',
        phone: '+91 22 2500 1100',
        specialty: 'Multi-Specialty & Critical Care',
        operatingHours: 'Mon-Sun 24/7',
        description: 'Comprehensive 24/7 acute healthcare with advanced trauma center and cardiac ICU.',
        latitude: 19.076,
        longitude: 72.8777,
        isLiveQueueActive: true,
        rating: 4.5,
        reviewCount: 120,
      },
    }),
    prisma.clinic.create({
      data: {
        name: 'Wellness Clinic',
        address: '456 Park Rd, Mumbai',
        phone: '+91 22 2600 2200',
        specialty: 'Family Medicine & Pediatrics',
        operatingHours: 'Mon-Sat 8:00 AM - 8:00 PM',
        description: 'Neighborhood primary care clinic specializing in preventive health and child wellness.',
        latitude: 19.082,
        longitude: 72.8888,
        isLiveQueueActive: false,
        rating: 4.2,
        reviewCount: 85,
      },
    }),
    prisma.clinic.create({
      data: {
        name: 'Sunrise Medical Center',
        address: '789 East Blvd, Mumbai',
        phone: '+91 22 2700 3300',
        specialty: 'Orthopedics & Dermatology',
        operatingHours: 'Mon-Sat 9:00 AM - 9:00 PM',
        description: 'Premier outpatient clinic with modern digital queuing, diagnostics, and tele-consultation.',
        latitude: 19.095,
        longitude: 72.8999,
        isLiveQueueActive: true,
        rating: 4.8,
        reviewCount: 200,
      },
    }),
  ]);
  const doctorData = [
    { email: 'dr.sharma@example.com', name: 'Dr. Rajesh Sharma', specialty: 'Cardiologist', clinicId: clinics[0].id },
    { email: 'dr.patel@example.com', name: 'Dr. Anita Patel', specialty: 'Pediatrician', clinicId: clinics[0].id },
    { email: 'dr.verma@example.com', name: 'Dr. Sunil Verma', specialty: 'General Physician', clinicId: clinics[1].id },
    { email: 'dr.iyer@example.com', name: 'Dr. Meena Iyer', specialty: 'Dermatologist', clinicId: clinics[2].id },
    { email: 'dr.reddy@example.com', name: 'Dr. Vikram Reddy', specialty: 'Orthopedic', clinicId: clinics[2].id },
  ];
  for (const doc of doctorData) {
    const user = await prisma.user.create({
      data: {
        email: doc.email,
        role: Role.doctor,
        firebaseUid: `seed-doctor-${doc.email}`
      }
    });
    await prisma.doctor.create({ data: { userId: user.id, name: doc.name, specialty: doc.specialty, clinicId: doc.clinicId } });
  }
  const patientData = [
    { email: 'rohan.patient@example.com', name: 'Rohan Mehta', abhaId: '11-2222-3333-4444' },
    { email: 'priya.patient@example.com', name: 'Priya Singh', abhaId: '55-6666-7777-8888' },
  ];
  for (const pat of patientData) {
    const user = await prisma.user.create({
      data: {
        email: pat.email,
        role: Role.patient,
        firebaseUid: `seed-patient-${pat.email}`
      }
    });
    await prisma.patient.create({ data: { userId: user.id, name: pat.name, abhaId: pat.abhaId, isAbhaLinked: true } });
  }
  console.log('Seeding completed successfully');
}
main().catch((e) => { console.error(e); process.exit(1); }).finally(async () => { await prisma.$disconnect(); });
