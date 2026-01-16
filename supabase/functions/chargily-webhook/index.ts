import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

// Supabase client
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.42.0';


// Chargily Pay secret key for webhook verification
const CHARGILY_WEBHOOK_SECRET = Deno.env.get('CHARGILY_WEBHOOK_SECRET');
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID');
const FIREBASE_SERVICE_ACCOUNT_KEY = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY');

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  const signature = req.headers.get('chargily-signature');
  if (!signature) {
    return new Response('No signature header', { status: 400 });
  }

  const payloadBuffer = new TextEncoder().encode(await req.text());

  // Verify webhook signature
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
    payloadBuffer
  );

  const digest = Array.from(new Uint8Array(hmacBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');


  if (digest !== signature) {
    console.error('Webhook signature verification failed.');
    return new Response('Invalid signature', { status: 403 });
  }

  const payloadText = new TextDecoder().decode(payloadBuffer);
  const event = JSON.parse(payloadText);

  if (event.type === 'checkout.paid') {
    const checkoutData = event.data;
    const clinicId = checkoutData.metadata?.clinic_id;
    const doctorCount = checkoutData.metadata?.doctor_count;

    if (!clinicId || doctorCount === undefined) {
      console.error('Missing clinic_id or doctor_count in checkout metadata.');
      return new Response('Missing metadata', { status: 400 });
    }

    try {
      const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT_KEY);

      // Authenticate with Firebase using service account to get an access token
      const tokenResponse = await fetch(
        `https://accounts.google.com/o/oauth2/token`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion: await signJwt(serviceAccount),
          }).toString(),
        },
      );

      if (!tokenResponse.ok) {
        throw new Error(`Failed to get Firebase access token: ${await tokenResponse.text()}`);
      }
      const tokenData = await tokenResponse.json();
      const accessToken = tokenData.access_token;

      const firestoreApiUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/clinics/${clinicId}`;

      const now = new Date();
      const subscriptionEndDate = new Date(now);
      subscriptionEndDate.setDate(now.getDate() + 30); // 30 days from now

      const updatePayload = {
        fields: {
          firstMonthFreeTrial: { booleanValue: false },
          freeTrialEnded: { booleanValue: true },
          subscriptionStartDate: { timestampValue: now.toISOString() },
          subscriptionEndDate: { timestampValue: subscriptionEndDate.toISOString() },
          staff: { integerValue: doctorCount.toString() },
        },
      };

      const firestoreResponse = await fetch(`${firestoreApiUrl}?updateMask.fieldPaths=firstMonthFreeTrial,freeTrialEnded,subscriptionStartDate,subscriptionEndDate,staff`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify(updatePayload),
      });

      if (!firestoreResponse.ok) {
        throw new Error(`Failed to update Firestore document: ${await firestoreResponse.text()}`);
      }

      console.log(`Clinic ${clinicId} subscription updated successfully.`);
      return new Response('Webhook received and processed', { status: 200 });
    } catch (error) {
      console.error(`Error updating clinic ${clinicId}: ${error.message}`);
      return new Response(`Error processing webhook: ${error.message}`, { status: 500 });
    }
  }

  return new Response('Unhandled event type', { status: 200 });
});

async function signJwt(serviceAccount: any): Promise<string> {
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };

  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/cloud-platform',
    aud: 'https://accounts.google.com/o/oauth2/token',
    exp: now + 3600, // 1 hour from now
    iat: now,
  };

  const textEncoder = new TextEncoder();
  const encodedHeader = base64url(textEncoder.encode(JSON.stringify(header)));
  const encodedClaims = base64url(textEncoder.encode(JSON.stringify(claims)));

  const signatureInput = `${encodedHeader}.${encodedClaims}`;
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    textEncoder.encode(serviceAccount.private_key),
    {
      name: 'RSASSA-PKCS1-V1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-V1_5', saltLength: 32 },
    privateKey,
    textEncoder.encode(signatureInput),
  );

  const encodedSignature = base64url(new Uint8Array(signature));

  return `${signatureInput}.${encodedSignature}`;
}

function base64url(array: Uint8Array): string {
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

