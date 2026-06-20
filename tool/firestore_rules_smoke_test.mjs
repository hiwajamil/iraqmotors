/**
 * Smoke tests for Firestore security rules (cars collection).
 * Run: firebase emulators:exec --only firestore "node tool/firestore_rules_smoke_test.mjs"
 */
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  arrayUnion,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, '..');
const projectId = 'iqmotors-d588d';

const sellerId = 'seller-user-001';
const buyerId = 'buyer-user-002';
const strangerId = 'stranger-user-003';
const carId = 'smoke-test-car-001';

let testEnv;
let passed = 0;
let failed = 0;

async function runTest(name, fn) {
  try {
    await fn();
    passed += 1;
    console.log(`  ✓ ${name}`);
  } catch (error) {
    failed += 1;
    console.error(`  ✗ ${name}`);
    console.error(`    ${error.message ?? error}`);
  }
}

async function seedCar() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `cars/${carId}`), {
      sellerId,
      status: 'active',
      highestBid: 10000,
      likedByUsers: [],
      title: 'Smoke Test Car',
      createdAt: serverTimestamp(),
    });
  });
}

async function main() {
  console.log('\nFirestore rules smoke test\n');

  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(resolve(projectRoot, 'firestore.rules'), 'utf8'),
    },
  });

  try {
    await testEnv.clearFirestore();

    // --- Create (add car) ---
    await runTest('authenticated seller can create a car ad', async () => {
      const seller = testEnv.authenticatedContext(sellerId);
      await assertSucceeds(
        setDoc(doc(seller.firestore(), 'cars/new-car'), {
          sellerId,
          status: 'pending',
          highestBid: 0,
          title: 'New Listing',
          createdAt: serverTimestamp(),
        }),
      );
    });

    await runTest('unauthenticated user cannot create a car ad', async () => {
      const anon = testEnv.unauthenticatedContext();
      await assertFails(
        setDoc(doc(anon.firestore(), 'cars/blocked-car'), {
          sellerId,
          status: 'pending',
        }),
      );
    });

    await runTest('user cannot create a car ad for another seller', async () => {
      const impostor = testEnv.authenticatedContext(strangerId);
      await assertFails(
        setDoc(doc(impostor.firestore(), 'cars/spoofed-car'), {
          sellerId,
          status: 'pending',
        }),
      );
    });

    // --- Favorites ---
    await seedCar();

    await runTest('another user can favorite a car (likedByUsers only)', async () => {
      const buyer = testEnv.authenticatedContext(buyerId);
      await assertSucceeds(
        updateDoc(doc(buyer.firestore(), `cars/${carId}`), {
          likedByUsers: arrayUnion(buyerId),
        }),
      );
      const snapshot = await getDoc(doc(buyer.firestore(), `cars/${carId}`));
      if (!snapshot.data()?.likedByUsers?.includes(buyerId)) {
        throw new Error('likedByUsers was not updated');
      }
    });

    await runTest('non-owner cannot edit listing fields while favoriting', async () => {
      const buyer = testEnv.authenticatedContext(buyerId);
      await assertFails(
        updateDoc(doc(buyer.firestore(), `cars/${carId}`), {
          title: 'Hijacked Title',
          likedByUsers: arrayUnion(buyerId),
        }),
      );
    });

    // --- Bids ---
    await runTest('authenticated user can place a bid (bid fields only)', async () => {
      const bidder = testEnv.authenticatedContext(buyerId);
      await assertSucceeds(
        updateDoc(doc(bidder.firestore(), `cars/${carId}`), {
          highestBid: 15000,
          lastBidAt: serverTimestamp(),
          lastBidBy: buyerId,
        }),
      );
    });

    await runTest('non-owner cannot change price/title while bidding', async () => {
      const bidder = testEnv.authenticatedContext(buyerId);
      await assertFails(
        updateDoc(doc(bidder.firestore(), `cars/${carId}`), {
          highestBid: 20000,
          title: 'Cheap car',
        }),
      );
    });

    // --- Owner update/delete ---
    await runTest('seller can update their own listing', async () => {
      const seller = testEnv.authenticatedContext(sellerId);
      await assertSucceeds(
        updateDoc(doc(seller.firestore(), `cars/${carId}`), {
          title: 'Updated by seller',
          price: 18000,
        }),
      );
    });

    await runTest('seller cannot transfer ownership (change sellerId)', async () => {
      const seller = testEnv.authenticatedContext(sellerId);
      await assertFails(
        updateDoc(doc(seller.firestore(), `cars/${carId}`), {
          sellerId: strangerId,
        }),
      );
    });

    await runTest('stranger cannot delete seller listing', async () => {
      const stranger = testEnv.authenticatedContext(strangerId);
      await assertFails(deleteDoc(doc(stranger.firestore(), `cars/${carId}`)));
    });

    await runTest('seller can delete their own listing', async () => {
      const seller = testEnv.authenticatedContext(sellerId);
      await assertSucceeds(deleteDoc(doc(seller.firestore(), `cars/${carId}`)));
    });

    // --- Super admin ---
    await seedCar();

    await runTest('super admin can update ad status', async () => {
      const admin = testEnv.authenticatedContext('admin-uid', {
        email: 'hiwa.constructions@gmail.com',
      });
      await assertSucceeds(
        updateDoc(doc(admin.firestore(), `cars/${carId}`), {
          status: 'rejected',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    await runTest('super admin can delete any listing', async () => {
      const admin = testEnv.authenticatedContext('admin-uid', {
        email: 'hiwa.constructions@gmail.com',
      });
      await assertSucceeds(deleteDoc(doc(admin.firestore(), `cars/${carId}`)));
    });

    // --- Read ---
    await seedCar();

    await runTest('anyone can read car listings', async () => {
      const anon = testEnv.unauthenticatedContext();
      await assertSucceeds(getDoc(doc(anon.firestore(), `cars/${carId}`)));
    });
  } finally {
    await testEnv.cleanup();
  }

  console.log(`\n${passed} passed, ${failed} failed\n`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
