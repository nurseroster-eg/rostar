import { createClient } from "npm:@supabase/supabase-js@2";

const origin = "https://nurseroster-eg.github.io";
const headers = {
  "Access-Control-Allow-Origin": origin,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reply = (status: number, body: object) => Response.json(body, { status, headers });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers });
  if (req.method !== "POST") return reply(405, { error: "الطريقة غير مدعومة" });
  const token = req.headers.get("Authorization")?.match(/^Bearer (\S+)$/i)?.[1];
  if (!token) return reply(401, { error: "سجّل الدخول أولاً" });

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: authError } = await db.auth.getUser(token);
  if (authError || !user) return reply(401, { error: "جلسة الدخول غير صالحة" });
  const { data: caller, error: roleError } = await db.from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (roleError) return reply(500, { error: "تعذر التحقق من الصلاحية" });
  if (caller?.role !== "admin") return reply(403, { error: "إنشاء الحسابات متاح للمدير فقط" });

  let body;
  try { body = await req.json(); } catch { return reply(400, { error: "بيانات الحساب غير صالحة" }); }
  const name = typeof body?.full_name === "string" ? body.full_name.trim() : "";
  const login = typeof body?.login === "string" ? body.login.trim().toLowerCase() : "";
  const email = login.includes("@") ? login : /^[a-z0-9_-]{3,40}$/.test(login) ? login + "@roster.invalid" : "";
  const role = body?.role;
  const department = body?.department_id ?? null;
  if (!name || name.length > 120 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254 ||
      !["admin", "nurse"].includes(role) || typeof body?.password !== "string" ||
      body.password.length < 12 || body.password.length > 72 ||
      (department !== null && (typeof department !== "string" || !/^[1-9]\d{0,17}$/.test(department)))) {
    return reply(400, { error: "راجع الاسم والبريد وكلمة المرور والصلاحية والقسم" });
  }

  if (department !== null) {
    const { data, error } = await db.from("departments").select("id").eq("id", department).maybeSingle();
    if (error || !data) return reply(400, { error: "القسم غير متاح" });
  }
  const { data, error } = await db.auth.admin.createUser({
    email, password: body.password, email_confirm: true,
    user_metadata: { full_name: name },
  });
  if (error || !data.user) {
    return reply(error?.code === "email_exists" ? 409 : 400, {
      error: error?.code === "email_exists" ? "الحساب موجود بالفعل" : "تعذر إنشاء الحساب. راجع بيانات الدخول",
    });
  }
  const { error: profileError } = await db.from("profiles").upsert({
    id: data.user.id, full_name: name, role, department_id: department,
  });
  if (profileError) return reply(500, { error: "اتعمل الحساب، لكن تعذر ضبط الصلاحية والقسم. عدّلهم من قائمة المستخدمين." });
  return reply(201, { id: data.user.id });
});
