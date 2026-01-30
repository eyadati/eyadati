import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import admin from "npm:firebase-admin@12.0.0";

// Chargily Pay secret key for webhook verification
const CHARGILY_WEBHOOK_SECRET = Deno.env.get('CHARGILY_WEBHOOK_SECRET');
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID');
const FIREBASE_SERVICE_ACCOUNT_KEY = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY');

// Initialize Firebase Admin once
if (!admin.apps.length && FIREBASE_SERVICE_ACCOUNT_KEY) {
  try {
    const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT_KEY);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: FIREBASE_PROJECT_ID,
    });
    console.log("Firebase Admin initialized successfully.");
  } catch (e) {
    console.error("Error initializing Firebase Admin:", e.message);
  }
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const signature = req.headers.get('chargily-signature');
  if (!signature) {
    console.error('Missing chargily-signature header');
    return new Response('No signature header', { status: 400 });
  }

  const rawBody = await req.text();
  if (!rawBody) {
    console.error('Empty request body');
    return new Response('Empty body', { status: 400 });
  }

  // 1. Verify webhook signature (Essential for security)
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(CHARGILY_WEBHOOK_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const hmacBuffer = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(rawBody)
  );

  const digest = Array.from(new Uint8Array(hmacBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  if (digest !== signature) {
    console.error('Webhook signature verification failed. Computed:', digest, 'Received:', signature);
    return new Response('Invalid signature', { status: 403 });
  }

  // 2. Parse event
  let event;
  try {
    event = JSON.parse(rawBody);
  } catch (e) {
    console.error('Failed to parse JSON body:', e.message);
    return new Response('Invalid JSON', { status: 400 });
  }

  // 3. Process checkout.paid
  if (event.type === 'checkout.paid') {
    const checkoutData = event.data;
    const clinicId = checkoutData.metadata?.clinic_id;
    const doctorCountStr = checkoutData.metadata?.doctor_count;

    if (!clinicId || doctorCountStr === undefined) {
      console.error('Missing metadata in checkout.paid event. Metadata:', JSON.stringify(checkoutData.metadata));
      return new Response('Missing metadata', { status: 400 });
    }

    try {
      const db = admin.firestore();
      const doctorCount = parseInt(doctorCountStr);
      
      const now = new Date();
      const subscriptionEndDate = new Date(now);
      subscriptionEndDate.setDate(now.getDate() + 30); // 30 days from now

      console.log(`Updating clinic ${clinicId} with doctor count ${doctorCount}...`);

      await db.collection('clinics').doc(clinicId).update({
        firstMonthFreeTrial: false,
        freeTrialEnded: true,
        subscriptionStartDate: admin.firestore.FieldValue.serverTimestamp(),
        subscriptionEndDate: admin.firestore.Timestamp.fromDate(subscriptionEndDate),
        staff: doctorCount,
      });

      console.log(`Clinic ${clinicId} subscription updated successfully via Admin SDK.`);
      return new Response('Webhook received and processed', { status: 200 });
    } catch (error) {
      console.error(`Error updating clinic ${clinicId}: ${error.message}`);
      return new Response(`Error processing webhook: ${error.message}`, { status: 500 });
    }
  }

  return new Response('Unhandled event type', { status: 200 });
});