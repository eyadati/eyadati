import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import admin from "firebase-admin"

// Initialize Firebase Admin using your service account JSON secret
const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") || "{}")
const app = admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
})

serve(async (req) => {
  // CORS headers for Flutter web support
  const headers = new Headers({
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST',
  })

  // Handle preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers })
  }

  try {
    // Parse body - client sends everything directly
    const { token, title, body, data = {} } = await req.json()
    
    // Validate required fields
    if (!token || !title || !body) {
      return new Response(JSON.stringify({ error: 'Missing required fields: token, title, body' }), {
        status: 400,
        headers
      })
    }

    // Send notification directly using the provided token
    const message = {
      token: token,
      notification: { title, body },
      data: {
        ...Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            contentAvailable: true,
            priority: '10'
          }
        }
      }
    }

    const response = await admin.messaging(app).send(message)
    
    return new Response(JSON.stringify({ success: true, messageId: response }), {
      status: 200,
      headers
    })

  } catch (error) {
    console.error('Error sending notification:', error)
    
    // Handle invalid token
    if (error.code === 'messaging/invalid-registration-token') {
      return new Response(JSON.stringify({ error: 'Invalid FCM token' }), {
        status: 410,
        headers
      })
    }

    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers
    })
  }
})