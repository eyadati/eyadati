import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { GoogleAuth } from 'npm:google-auth-library@9.0.0';

// ======================================================
// CONFIGURATION
// ======================================================
const CHARGILY_WEBHOOK_SECRET = "test_sk_cCDBJ3lBdjpzoWKiOwdbW7O6KsVHJf0MRFPXb1Ld";
const FIREBASE_PROJECT_ID = "eydati-fcd79"; 

// Get the full JSON from Supabase Secrets
const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

let auth: any = null;

if (serviceAccountJson) {
  try {
    const credentials = JSON.parse(serviceAccountJson);
    auth = new GoogleAuth({
      credentials,
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
    console.log("Auth initialized successfully from Secret.");
  } catch (e) {
    console.error("Failed to parse FIREBASE_SERVICE_ACCOUNT secret:", e.message);
  }
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const signature = req.headers.get('signature');
  const rawBody = await req.text();

  if (!signature) {
    console.error('Missing signature header');
    return new Response('No signature header', { status: 400 });
  }

  // 1. Verify webhook signature
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

  console.log("--- Signature Verification ---");
  console.log("Status: ", digest === signature ? "PASSED" : "FAILED");

  if (digest !== signature) {
    console.error('Webhook signature verification failed');
    return new Response('Invalid signature', { status: 403 }); 
  }

  // 2. Parse event
  let event;
  try {
    event = JSON.parse(rawBody);
  } catch (e) {
    return new Response('Invalid JSON', { status: 400 });
  }

  // 3. Process checkout.paid
  if (event.type === 'checkout.paid') {
    const checkoutData = event.data;
    const clinicId = checkoutData.metadata?.clinic_id;

    if (!clinicId) {
      console.error('Missing clinic_id');
      return new Response('Missing clinic_id', { status: 400 });
    }

    if (!auth) {
      console.error('Firebase Auth not initialized. Check Supabase Secret FIREBASE_SERVICE_ACCOUNT');
      return new Response('Internal Server Error', { status: 500 });
    }

    try {
      console.log("Requesting Access Token...");
      const client = await auth.getClient();
      const tokenResponse = await client.getAccessToken();
      const token = (typeof tokenResponse === 'object' && tokenResponse !== null && 'token' in tokenResponse) 
        ? tokenResponse.token 
        : tokenResponse;

      if (!token) throw new Error("Failed to get access token");

      // 4. Fetch clinic data via REST API
      const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/clinics/${clinicId}`;
      
      const getResponse = await fetch(firestoreUrl, {
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (!getResponse.ok) {
        throw new Error(`Failed to fetch clinic: ${await getResponse.text()}`);
      }

      const clinicDoc = await getResponse.json();
      const fields = clinicDoc.fields || {};
      
      const currentEndVal = fields.subscriptionEndDate?.timestampValue;
      const currentEndDate = currentEndVal ? new Date(currentEndVal) : new Date();
      const now = new Date();

      let newEndDate: Date;
      if (currentEndDate > now) {
        newEndDate = new Date(currentEndDate);
        newEndDate.setDate(newEndDate.getDate() + 30);
      } else {
        newEndDate = new Date(now);
        newEndDate.setDate(now.getDate() + 30);
      }

      console.log(`Clinic ${clinicId}: Extending subscription to ${newEndDate.toISOString()}`);

      // 5. Update clinic via REST PATCH
      const updateUrl = `${firestoreUrl}?updateMask.fieldPaths=paused&updateMask.fieldPaths=paid_this_month&updateMask.fieldPaths=appointments_this_month&updateMask.fieldPaths=subscriptionEndDate&updateMask.fieldPaths=subscriptionStartDate`;
      
      const patchData = {
        fields: {
          paused: { booleanValue: false },
          paid_this_month: { booleanValue: true },
          appointments_this_month: { integerValue: 0 },
          subscriptionEndDate: { timestampValue: newEndDate.toISOString() },
          subscriptionStartDate: { timestampValue: now.toISOString() },
        }
      };

      const patchResponse = await fetch(updateUrl, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(patchData)
      });

      if (!patchResponse.ok) {
        throw new Error(`Failed to update clinic: ${await patchResponse.text()}`);
      }

      console.log("✅ Firestore updated successfully.");
      return new Response('Webhook processed successfully', { status: 200 });

    } catch (error: any) {
      console.error(`Error: ${error.message}`);
      return new Response('Internal Server Error', { status: 500 });
    }
  }

  return new Response('Unhandled event type', { status: 200 });
});
