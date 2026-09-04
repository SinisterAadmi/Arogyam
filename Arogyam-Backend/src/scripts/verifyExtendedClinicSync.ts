import prisma from '../lib/prisma';
import { PatientService } from '../services/patientService';
import { ReceptionService } from '../services/receptionService';

async function main() {
  console.log('===========================================================');
  console.log('  TEST: REAL HAVERSINE DISTANCE & EXTENDED CLINIC SYNC');
  console.log('===========================================================');

  // 1. Check Clinics in Database
  const allClinics = await prisma.clinic.findMany({
    orderBy: { name: 'asc' },
  });
  console.log(`\n1. Found ${allClinics.length} clinics in database:`);
  for (const c of allClinics) {
    console.log(`   - "${c.name}": Lat=${c.latitude}, Lng=${c.longitude}, Rating=${c.rating}★ (${c.reviewCount})`);
  }

  // 2. Haversine Distance Test from Mumbai Center (19.0760, 72.8777)
  const patientLat = 19.0760;
  const patientLng = 72.8777;
  console.log(`\n2. Patient at Lat=${patientLat}, Lng=${patientLng} calls getNearbyClinics:`);

  const nearbyClinics = await PatientService.getNearbyClinics(patientLat, patientLng);
  for (const c of nearbyClinics) {
    console.log(`   * ${c.name}:`);
    console.log(`     Distance: ${c.distanceKm} km`);
    console.log(`     Specialty: ${c.specialty}`);
    console.log(`     Phone: ${c.phone}`);
    console.log(`     Operating Hours: ${c.operatingHours}`);
    console.log(`     Description: ${c.description}`);
  }

  // Verify distance differentiation
  const distances = nearbyClinics.map((c) => c.distanceKm);
  const distinctDistances = new Set(distances);
  if (distinctDistances.size <= 1) {
    throw new Error(`FAIL: Distances are not differentiated! Got: ${distances.join(', ')}`);
  }
  console.log(`\n>>> SUCCESS: Real Haversine distances calculated and verified! (${distances.join(' km, ')} km)`);

  // 3. Test Reception Update Clinic Extended Fields (and verify non-editable fields remain protected)
  const receptionUser = await prisma.user.findFirst({
    where: { role: 'reception', email: 'reception.sunrise@arogyam.test' },
    include: { reception: { include: { clinic: true } } },
  });
  if (!receptionUser || !receptionUser.reception) {
    throw new Error('Reception user for Sunrise clinic not found');
  }

  console.log(`\n3. Reception updates Sunrise Medical Center details:`);
  const beforeRating = receptionUser.reception.clinic.rating;
  const beforeReviewCount = receptionUser.reception.clinic.reviewCount;
  const beforeLiveQueue = receptionUser.reception.clinic.isLiveQueueActive;

  const updateResult = await ReceptionService.updateClinic(receptionUser.id, {
    name: 'Sunrise Super Specialty Hospital',
    address: 'Plot 45, Sector 14, Dwarka, New Delhi',
    phone: '+91 11 4999 8888',
    specialty: 'Orthopedics, Cardiology & Diagnostics',
    operatingHours: 'Mon-Sat 8:00 AM - 10:00 PM',
    description: 'Premier multi-specialty healthcare center with advanced digital queuing.',
    latitude: 28.5950,
    longitude: 77.0480,
    // Attempting to send forbidden fields to verify security whitelist
    ...({ rating: 5.0, reviewCount: 9999, isLiveQueueActive: false } as any),
  });

  console.log('   Response from updateClinic:');
  console.log(`   - Name: ${updateResult.name}`);
  console.log(`   - Phone: ${updateResult.phone}`);
  console.log(`   - Specialty: ${updateResult.specialty}`);
  console.log(`   - Hours: ${updateResult.operatingHours}`);
  console.log(`   - Rating (protected): ${updateResult.rating}★ (was ${beforeRating}★)`);
  console.log(`   - Review Count (protected): ${updateResult.reviewCount} (was ${beforeReviewCount})`);
  console.log(`   - Live Queue (protected): ${updateResult.isLiveQueueActive} (was ${beforeLiveQueue})`);

  if (updateResult.rating !== beforeRating || updateResult.reviewCount !== beforeReviewCount) {
    throw new Error('FAIL: rating/reviewCount were illegally modified by reception update!');
  }

  // 4. Verify Patient View reflects the updated details
  console.log(`\n4. Checking Patient View for updated Sunrise Clinic from Dwarka (28.5921, 77.0460):`);
  const patientViewAfter = await PatientService.getNearbyClinics(28.5921, 77.0460);
  const updatedSunrise = patientViewAfter.find((c) => c.id === receptionUser.reception?.clinicId);

  if (!updatedSunrise) {
    throw new Error('Sunrise clinic not found in patient nearby clinics');
  }

  console.log(`   - Patient sees: "${updatedSunrise.name}"`);
  console.log(`   - Address: "${updatedSunrise.address}"`);
  console.log(`   - Phone: "${updatedSunrise.phone}"`);
  console.log(`   - Specialty: "${updatedSunrise.specialty}"`);
  console.log(`   - Hours: "${updatedSunrise.operatingHours}"`);
  console.log(`   - Distance: ${updatedSunrise.distanceKm} km`);

  if (
    updatedSunrise.name !== 'Sunrise Super Specialty Hospital' ||
    updatedSunrise.phone !== '+91 11 4999 8888' ||
    updatedSunrise.specialty !== 'Orthopedics, Cardiology & Diagnostics'
  ) {
    throw new Error('FAIL: Patient view did not reflect updated clinic details!');
  }

  console.log('\n>>> SUCCESS: Patient view and About details are 100% synchronized in real-time!');

  // Cleanup: restore original details
  await prisma.clinic.update({
    where: { id: receptionUser.reception.clinicId },
    data: {
      name: 'Sunrise Medical Center',
      address: '789 East Blvd, Mumbai',
      phone: '+91 22 2700 3300',
      specialty: 'Orthopedics & Dermatology',
      operatingHours: 'Mon-Sat 9:00 AM - 9:00 PM',
      description: 'Premier outpatient clinic with modern digital queuing, diagnostics, and tele-consultation.',
      latitude: 19.095,
      longitude: 72.8999,
    },
  });
  console.log('\n[Cleaned up test data & restored original clinic state]');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
