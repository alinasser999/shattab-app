// Arabic-first Shattab assistant boundary.
//
// The function is intentionally narrow: it authenticates the caller, removes
// sensitive data, asks the current OpenRouter free router for a bounded JSON
// envelope, and returns a deterministic fallback on every upstream failure.

import { createClient } from 'jsr:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

const MODEL = 'openrouter/free';
const DAILY_LIMIT = 50;

const CANONICAL_SPECIALTIES = new Set([
  'paint',
  'flooring',
  'kitchen',
  'bathroom',
  'electrical',
  'plumbing',
  'carpentry',
  'design',
  'full_reno',
  'plastering',
  'gypsum_board',
  'marble_granite',
  'aluminum_upvc',
  'hvac',
]);

const CANONICAL_CITIES = new Set([
  'القاهرة',
  'الجيزة',
  'القاهرة الجديدة',
  '٦ أكتوبر',
  'الإسكندرية',
]);

const ALLOWLISTED_HELP_ACTIONS = new Set([
  'browse_contractors',
  'post_brief',
  'my_requests',
  'view_portfolio',
  'pricing_info',
  'contact_support',
]);

const SPECIALTY_SYNONYMS: Record<string, string> = {
  'دهان': 'paint',
  'دهانات': 'paint',
  'نقاش': 'paint',
  'نقاشة': 'paint',
  'بياض': 'paint',
  'أرضيات': 'flooring',
  'ارضيات': 'flooring',
  'سيراميك': 'flooring',
  'بورسلين': 'flooring',
  'باركية': 'flooring',
  'باركيه': 'flooring',
  'مطبخ': 'kitchen',
  'مطابخ': 'kitchen',
  'حمام': 'bathroom',
  'حمامات': 'bathroom',
  'صحي': 'bathroom',
  'كهرباء': 'electrical',
  'كهربائي': 'electrical',
  'سباكة': 'plumbing',
  'سباك': 'plumbing',
  'نجارة': 'carpentry',
  'نجار': 'carpentry',
  'أبواب': 'carpentry',
  'شبابيك': 'carpentry',
  'تصميم': 'design',
  'تصميم داخلي': 'design',
  'ديكور': 'design',
  'مهندس ديكور': 'design',
  'تشطيب': 'full_reno',
  'تشطيب كامل': 'full_reno',
  'عمارة': 'full_reno',
  'محارة': 'plastering',
  'لياسة': 'plastering',
  'جبس': 'gypsum_board',
  'جبس بورد': 'gypsum_board',
  'رخام': 'marble_granite',
  'جرانيت': 'marble_granite',
  'رخام وجرانيت': 'marble_granite',
  'ألوميتال': 'aluminum_upvc',
  'الوميتال': 'aluminum_upvc',
  'upvc': 'aluminum_upvc',
  'تكييف': 'hvac',
  'تكييفات': 'hvac',
  'تكييف مركزي': 'hvac',
};

const CITY_SYNONYMS: Record<string, string> = {
  'قاهرة': 'القاهرة',
  'القاهره': 'القاهرة',
  'cairo': 'القاهرة',
  'جيزة': 'الجيزة',
  'الجيزه': 'الجيزة',
  'giza': 'الجيزة',
  'التجمع': 'القاهرة الجديدة',
  'التجمع الخامس': 'القاهرة الجديدة',
  'القاهرة الجديده': 'القاهرة الجديدة',
  'new cairo': 'القاهرة الجديدة',
  '6 اكتوبر': '٦ أكتوبر',
  '٦ اكتوبر': '٦ أكتوبر',
  'اكتوبر': '٦ أكتوبر',
  'الشيخ زايد': '٦ أكتوبر',
  'زايد': '٦ أكتوبر',
  'october': '٦ أكتوبر',
  'اسكندرية': 'الإسكندرية',
  'الإسكندريه': 'الإسكندرية',
  'اسكندريه': 'الإسكندرية',
  'alexandria': 'الإسكندرية',
};

const DETERMINISTIC_SAFE_FALLBACK = {
  intent: 'fallback',
  reply:
    'أهلاً بك في شطّب. أقدر أساعدك في فهم خطوات التشطيب والعثور على محترفين مناسبين من داخل التطبيق.',
  next_question: 'ما هي الخدمة أو المحافظة التي تبحث عنها؟',
  specialty_key: null,
  city_key: null,
  help_action_id: 'browse_contractors',
  quick_replies: ['تصفح المحترفين', 'نشر طلب جديد', 'سباكة', 'دهانات'],
};

const JSON_HEADERS = { ...corsHeaders, 'Content-Type': 'application/json' };

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: JSON_HEADERS,
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function normalize(value: string): string {
  return value.trim().toLowerCase().replace(/\s+/g, ' ');
}

function redactPii(text: string): string {
  return text
    .replace(/(?:\+?20|0)?1[0125]\d{8}/g, '[رقم محذوف]')
    .replace(/[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+/g, '[بريد محذوف]')
    .replace(
      /\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b/g,
      '[معرف محذوف]',
    )
    .replace(/\b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b/g, '[بطاقة محذوفة]')
    .replace(/\b\d{14}\b/g, '[رقم قومي محذوف]')
    .replace(/https?:\/\/[^\s]+/g, '[رابط محذوف]');
}

function prepareMessages(rawMessages: unknown): Array<{ role: string; content: string }> {
  if (!Array.isArray(rawMessages)) return [];
  const result: Array<{ role: string; content: string }> = [];

  for (const item of rawMessages.slice(-6)) {
    if (!isRecord(item)) continue;
    const content = typeof item.content === 'string'
      ? item.content.slice(0, 500).trim()
      : '';
    if (!content) continue;
    result.push({
      role: item.role === 'assistant' ? 'assistant' : 'user',
      content: redactPii(content),
    });
  }
  return result;
}

function boundedText(value: string, maxLength: number): string {
  const text = value.trim();
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength - 1).trim()}…`;
}

function sanitizeAssistantText(value: string, maxLength: number): string {
  const clean = redactPii(value)
    .replace(/[\d٠-٩][\d٠-٩,.\s]*\s*(?:جنيه|ج\.م|EGP)/gi, 'التكلفة تحدد حسب المعاينة')
    .replace(/(?:تقييم|نجوم)\s*[\d٠-٩](?:[.,][\d٠-٩])?/gi, '');
  return boundedText(clean, maxLength);
}

function resolveSpecialty(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const value = normalize(raw);
  return CANONICAL_SPECIALTIES.has(value) ? value : SPECIALTY_SYNONYMS[value] ?? null;
}

function resolveCity(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const value = normalize(raw);
  return CANONICAL_CITIES.has(value) ? value : CITY_SYNONYMS[value] ?? null;
}

function resolveHelpAction(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const value = raw.trim();
  return ALLOWLISTED_HELP_ACTIONS.has(value) ? value : null;
}

function validateEnvelope(raw: Record<string, unknown>) {
  const allowedIntents = new Set([
    'discovery',
    'consultation',
    'clarification',
    'help_action',
    'general',
    'fallback',
  ]);
  const rawIntent = typeof raw.intent === 'string' ? raw.intent.trim() : '';
  const intent = allowedIntents.has(rawIntent) ? rawIntent : 'general';

  const reply = typeof raw.reply === 'string'
    ? sanitizeAssistantText(raw.reply, 1200)
    : '';
  const rawQuestion = typeof raw.next_question === 'string'
    ? sanitizeAssistantText(raw.next_question, 280)
    : '';
  const quickReplies = Array.isArray(raw.quick_replies)
    ? raw.quick_replies
        .filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
        .slice(0, 4)
        .map((item) => sanitizeAssistantText(item, 40))
        .filter((item) => item.length > 0)
    : [];

  return {
    intent,
    reply: reply || DETERMINISTIC_SAFE_FALLBACK.reply,
    next_question: rawQuestion || null,
    specialty_key: resolveSpecialty(raw.specialty_key),
    city_key: resolveCity(raw.city_key),
    help_action_id: resolveHelpAction(raw.help_action_id),
    quick_replies: quickReplies.length > 0
      ? quickReplies
      : DETERMINISTIC_SAFE_FALLBACK.quick_replies,
  };
}

const SYSTEM_PROMPT = `أنت مساعد تطبيق شطّب في مصر. ساعد المستخدم بإجابة عربية قصيرة وعملية عن التشطيب أو استخدام التطبيق.
أعد كائن JSON صالحاً فقط، من دون Markdown أو نص خارجه.
المفاتيح المسموحة فقط:
{
  "intent": "discovery" | "consultation" | "clarification" | "help_action" | "general",
  "reply": "نص الرد",
  "next_question": "سؤال واحد للخطوة التالية أو null",
  "specialty_key": "مفتاح تخصص قياسي أو null",
  "city_key": "مدينة قياسية أو null",
  "help_action_id": "إجراء مسموح أو null",
  "quick_replies": ["اقتراحات قصيرة"]
}
التخصصات القياسية فقط: ["paint", "flooring", "kitchen", "bathroom", "electrical", "plumbing", "carpentry", "design", "full_reno", "plastering", "gypsum_board", "marble_granite", "aluminum_upvc", "hvac"]
المدن القياسية فقط: ["القاهرة", "الجيزة", "القاهرة الجديدة", "٦ أكتوبر", "الإسكندرية"]
الإجراءات المسموحة فقط: ["browse_contractors", "post_brief", "my_requests", "view_portfolio", "pricing_info", "contact_support"]
لا تذكر أسماء محترفين أو أرقام هواتف أو روابط أو معرفات أو تقييمات أو أسعار محددة أو ادعاءات توثيق. بيانات المحترفين الحقيقية تأتي من التطبيق بعد تحديد التخصص والمكان.
إذا كان الجمهور contractor، ساعده في استخدام التطبيق ومجاله ولا تقترح عليه محترفين آخرين.`;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }
  const token = authHeader.slice('Bearer '.length).trim();
  if (!token) return jsonResponse({ error: 'Unauthorized' }, 401);

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  if (!supabaseUrl || !supabaseAnonKey) return jsonResponse({ error: 'Service unavailable' }, 503);

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  if (authError || !user) return jsonResponse({ error: 'Unauthorized' }, 401);

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse(DETERMINISTIC_SAFE_FALLBACK);
  }

  const record = isRecord(body) ? body : {};
  const messages = prepareMessages(record.messages);
  if (messages.length === 0) return jsonResponse(DETERMINISTIC_SAFE_FALLBACK);
  const audience = record.audience === 'contractor' ? 'contractor' : 'homeowner';

  // The RPC derives the user from auth.uid() and owns the daily limit. Errors
  // are fail-open so a quota outage does not take down the assistant surface.
  try {
    const { data: quotaAllowed, error: quotaError } = await supabase.rpc(
      'check_and_increment_assistant_quota',
    );
    if (!quotaError && quotaAllowed === false) {
      return jsonResponse({
        ...DETERMINISTIC_SAFE_FALLBACK,
        reply: `وصلت للحد اليومي للاستفسارات المتاحة (${DAILY_LIMIT}). يمكنك تصفح المحترفين أو نشر طلبك مباشرة.`,
      }, 429);
    }
  } catch {
    // No prompt, completion, or error payload is logged.
  }

  const apiKey = Deno.env.get('OPENROUTER_API_KEY');
  if (!apiKey) return jsonResponse(DETERMINISTIC_SAFE_FALLBACK);

  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://shattab.app',
        'X-Title': 'Shattab Assistant',
      },
      body: JSON.stringify({
        // Hard invariant: never accept a model from the client and never use
        // a paid fallback when the free router is unavailable.
        model: MODEL,
        messages: [
          { role: 'system', content: `${SYSTEM_PROMPT}\nالجمهور: ${audience}` },
          ...messages,
        ],
        temperature: 0.2,
        max_tokens: 600,
      }),
    });
    if (!response.ok) return jsonResponse(DETERMINISTIC_SAFE_FALLBACK);

    const data: unknown = await response.json();
    const content = isRecord(data) && Array.isArray(data.choices)
      ? data.choices[0]
      : null;
    const rawContent = isRecord(content) && isRecord(content.message)
      ? content.message.content
      : null;
    if (typeof rawContent !== 'string' || !rawContent.trim()) {
      return jsonResponse(DETERMINISTIC_SAFE_FALLBACK);
    }

    let jsonText = rawContent.trim()
      .replace(/^```json\s*/i, '')
      .replace(/^```\s*/i, '')
      .replace(/\s*```$/, '')
      .trim();
    const start = jsonText.indexOf('{');
    const end = jsonText.lastIndexOf('}');
    if (start >= 0 && end > start) jsonText = jsonText.slice(start, end + 1);

    const parsed: unknown = JSON.parse(jsonText);
    return jsonResponse(validateEnvelope(isRecord(parsed) ? parsed : {}));
  } catch {
    // Never log prompts, completions, provider errors, or secrets.
    return jsonResponse(DETERMINISTIC_SAFE_FALLBACK);
  }
});
