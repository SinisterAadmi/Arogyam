import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();
import { ReceptionService } from '../services/receptionService';
import { PatientService } from '../services/patientService';

async function verifyClinicEditSync() {
  console.log('===========================================================');
  console.log('  TEST: RECEPTION CLINIC LOCATION EDIT & PATIENT SYNC');
  console.log('===========================================================\n');

  // 1. Identify Sunrise Reception User & Clinic
  const receptionUser = await prisma.user.findFirst({
    where: { email: 'reception.sunrise@arogyam.test' },
  });
  if (!receptionUser) throw new Error('Reception user not found');

  const beforeClinic = await ReceptionService.getClinic(receptionUser.id);
  console.log('1. BEFORE Clinic State in Database:');
  console.log(`   Name: "${beforeClinic.name}"`);
  console.log(`   Address: "${beforeClinic.address}"`);
  console.log(`   Location: Lat=${beforeClinic.latitude}, Lng=${beforeClinic.longitude}\n`);

  // 2. Reception updates clinic name, address, and moves the map pin
  const newLat = 28.5985;
  const newLng = 77.0512;
  const newName = 'Sunrise Medical Center (Main Wing)';
  const newAddress = 'Plot 12, Sector 12, Dwarka, New Delhi';

  console.log('2. Reception calls PATCH /reception/clinic:');
  console.log(`   Updating to: Lat=${newLat}, Lng=${newLng}, Name="${newName}"`);

  const updatedClinic = await ReceptionService.updateClinic(receptionUser.id, {
    name: newName,
    address: newAddress,
    latitude: newLat,
    longitude: newLng,
  });

  console.log('   Response from updateClinic:');
  console.log(JSON.stringify(updatedClinic, null, 2));

  // 3. Query the patient-side Nearby Clinics endpoint
  console.log('\n3. Checking Patient-side Nearby Clinics (/patients/clinics/nearby):');
  const patient = await prisma.patient.findFirst({
    where: { user: { phoneNumber: '+917276633833' } },
  });
  if (!patient) throw new Error('Patient not found');

  const nearbyClinics = await PatientService.getNearbyClinics(28.5921, 77.0460);
  const patientViewClinic = nearbyClinics.find((c) => c.id === beforeClinic.id);

  console.log('   Patient-side Clinic Data for Sunrise:');
  console.log(`   ID: ${patientViewClinic?.id}`);
  console.log(`   Name: "${patientViewClinic?.name}"`);
  console.log(`   Address: "${patientViewClinic?.address}"`);
  console.log(`   Location: Lat=${patientViewClinic?.latitude}, Lng=${patientViewClinic?.longitude}`);
  console.log(`   Computed Distance: ${patientViewClinic?.distanceKm} km\n`);

  // 4. Assertions
  if (
    patientViewClinic &&
    patientViewClinic.latitude === newLat &&
    patientViewClinic.longitude === newLng &&
    patientViewClinic.name === newName
  ) {
    console.log('>>> SUCCESS: Patient map reflects the updated coordinates & name immediately!');
  } else {
    console.error('>>> FAILURE: Patient map coordinates or name do not match update!');
  }

  // 5. Restore clinic location & name to standard test values
  await ReceptionService.updateClinic(receptionUser.id, {
    name: 'Sunrise Medical Center',
    address: 'Sector 12, Dwarka, New Delhi',
    latitude: 28.5921,
    longitude: 77.0460,
  });
  console.log('\n[Cleaned up & restored original clinic coordinates: 28.5921, 77.0460]');
}

verifyClinicEditSync()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
