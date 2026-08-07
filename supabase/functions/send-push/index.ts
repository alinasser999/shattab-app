// Fans a `notifications` INSERT out to the recipient's devices via FCM v1.
//
// Invoked by a Supabase Database Webhook on public.notifications (INSERT).
// The triggers in 20260803202740 decide *that* a notification exists; this
// decides how it reaches a phone that is not currently holding a socket open.
// With the app foregrounded, realtime (20260807231500) has already delivered
// it — which is why nothing here tries to also render an in-app banner.
//
// Required secrets (supabase secrets set ...):
//   PUSH_WEBHOOK_SECRET   shared with the webhook's custom header
//   FCM_PROJECT_ID        Firebase project id
//   FCM_CLIENT_EMAIL      service-account email
//   FCM_PRIVATE_KEY       service-account private key (PEM, \n escaped)
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected by the platform.

import { createClient } from 'jsr:@supabase/supabase-js@2';

// ── copy ───────────────────────────────────────────────────────────────────
// Deliberately duplicated from lib/l10n/app_{ar,en}.arb. A push is rendered
// where the app is not running, so it cannot reach the Flutter catalogue, and
// resolving keys client-side would mean sending a silent push and waking the
// app just to draw a string — the thing push exists to avoid.
//
// `test/notifications/push_copy_test.dart` fails if a key here drifts out of
// the ARB, which is the guard that makes the duplication survivable.
const COPY: Record<string, { ar: string; en: string }> = {
  notificationsTitle: { ar: 'الإشعارات', en: 'Notifications' },
  notificationNewQuoteTitle: { ar: 'عرض سعر جديد', en: 'New quote' },
  notificationNewQuoteBody: {
    ar: 'وصلك عرض جديد على طلبك.',
    en: 'You received a new quote on your request.',
  },
  notificationQuoteDecisionTitle: {
    ar: 'تحديث على عرضك',
    en: 'Update on your quote',
  },
  notificationQuoteAcceptedBody: {
    ar: 'صاحب الطلب وافق على عرضك.',
    en: 'The homeowner accepted your quote.',
  },
  notificationQuoteDeclinedBody: {
    ar: 'صاحب الطلب اختار عرضًا آخر للطلب.',
    en: 'The homeowner chose another quote for this request.',
  },
  notificationCompletionTitle: { ar: 'تحديث على الشغل', en: 'Work update' },
  notificationCompletionRequestedBody: {
    ar: 'المحترف بيقول إن الشغل خلص. راجع تفاصيل الطلب.',
    en: 'The professional marked the work as finished. Review the request details.',
  },
  notificationJobCompletedBody: {
    ar: 'تم تأكيد اكتمال المشروع.',
    en: 'The project was confirmed complete.',
  },
  notificationNewReviewTitle: { ar: 'تقييم جديد', en: 'New review' },
  notificationNewReviewBody: {
    ar: 'العميل أضاف تقييمًا جديدًا على شغلك.',
    en: 'A homeowner added a new review to your profile.',
  },
  notificationVerificationTitle: {
    ar: 'تحديث التوثيق',
    en: 'Verification update',
  },
  notificationVerificationApprovedBody: {
    ar: 'حسابك اتوثق بنجاح.',
    en: 'Your account was verified successfully.',
  },
  notificationVerificationRejectedBody: {
    ar: 'راجع ملاحظات التوثيق وقدّم الطلب مرة تانية.',
    en: 'Review the verification notes and submit again.',
  },
  notificationPaymentTitle: { ar: 'تحديث الاشتراك', en: 'Subscription update' },
  notificationPaymentApprovedBody: {
    ar: 'تم تفعيل اشتراكك.',
    en: 'Your subscription is now active.',
  },
  notificationPaymentRejectedBody: {
    ar: 'طلب الدفع محتاج مراجعة.',
    en: 'Your payment request needs review.',
  },
  notificationCommunityTitle: { ar: 'تفاعل جديد', en: 'New activity' },
  notificationPostLikedBody: {
    ar: 'حد عمل إعجاب على منشورك.',
    en: 'Someone liked your post.',
  },
  notificationPostCommentedBody: {
    ar: 'حد كتب تعليق على منشورك.',
    en: 'Someone commented on your post.',
  },
  notificationCommentRepliedBody: {
    ar: 'حد رد على تعليقك.',
    en: 'Someone replied to your comment.',
  },
  notificationCommentLikedBody: {
    ar: 'حد عمل إعجاب على تعليقك.',
    en: 'Someone liked your comment.',
  },
};

function copy(key: string, locale: string): string {
  const entry = COPY[key] ?? COPY.notificationsTitle;
  return locale === 'en' ? entry.en : entry.ar;
}

// ── FCM auth ───────────────────────────────────────────────────────────────
// FCM's legacy server key was withdrawn in 2024, so v1 with an OAuth2 bearer is
// the only route. Tokens last an hour; caching one across warm invocations
// saves a round trip per notification on a function that fires constantly.
let cachedToken: { value: string; expiresAt: number } | null = null;

function pemToBinary(pem: string): Uint8Array {
  const body = pem
    .replace(/\\n/g, '\n')
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

function base64url(input: Uint8Array | string): string {
  const bytes =
    typeof input === 'string' ? new TextEncoder().encode(input) : input;
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

async function accessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) return cachedToken.value;

  const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL')!;
  const privateKey = Deno.env.get('FCM_PRIVATE_KEY')!;

  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = base64url(
    JSON.stringify({
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  );

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBinary(privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(`${header}.${claim}`),
  );
  const jwt = `${header}.${claim}.${base64url(new Uint8Array(signature))}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}: ${await res.text()}`);

  const json = await res.json();
  cachedToken = { value: json.access_token, expiresAt: now + 3500 };
  return cachedToken.value;
}

// ── handler ────────────────────────────────────────────────────────────────
Deno.serve(async (req) => {
  // The webhook is the only legitimate caller. Without this check the endpoint
  // is an open push relay: anyone who learned the URL could address a
  // notification at any user id they could guess.
  const secret = Deno.env.get('PUSH_WEBHOOK_SECRET');
  if (!secret || req.headers.get('x-push-secret') !== secret) {
    return new Response('forbidden', { status: 403 });
  }

  const body = await req.json().catch(() => null);
  const record = body?.record;
  if (!record?.recipient_id) {
    return new Response('ignored', { status: 200 });
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: devices, error } = await admin
    .from('device_tokens')
    .select('token, platform, locale')
    .eq('user_id', record.recipient_id);

  if (error) {
    return new Response(`lookup failed: ${error.message}`, { status: 500 });
  }
  if (!devices?.length) return new Response('no devices', { status: 200 });

  const bearer = await accessToken();
  const projectId = Deno.env.get('FCM_PROJECT_ID')!;
  const endpoint =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const stale: string[] = [];

  await Promise.all(
    devices.map(async (device) => {
      const title = copy(record.title_key, device.locale);
      const bodyText = copy(record.body_key, device.locale);

      const res = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${bearer}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: device.token,
            notification: { title, body: bodyText },
            // Routing data only. Nothing here is a secret: entity ids are
            // already RLS-guarded, and the app re-fetches the row before it
            // renders anything from it.
            data: {
              notification_id: String(record.id ?? ''),
              kind: String(record.kind ?? ''),
              entity_type: String(record.entity_type ?? ''),
              entity_id: String(record.entity_id ?? ''),
            },
            android: { priority: 'HIGH', notification: { sound: 'default' } },
            apns: { payload: { aps: { sound: 'default', badge: 1 } } },
          },
        }),
      });

      if (res.ok) return;

      const text = await res.text();
      // 404 / UNREGISTERED means the install is gone. Keeping the row means
      // retrying a dead address on every future notification, so drop it here
      // rather than growing the table forever.
      if (res.status === 404 || text.includes('UNREGISTERED')) {
        stale.push(device.token);
      } else {
        console.error(`fcm ${res.status} for ${record.id}: ${text}`);
      }
    }),
  );

  if (stale.length) {
    await admin.from('device_tokens').delete().in('token', stale);
  }

  return new Response(
    JSON.stringify({
      sent: devices.length - stale.length,
      pruned: stale.length,
    }),
    { headers: { 'Content-Type': 'application/json' } },
  );
});
