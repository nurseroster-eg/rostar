import { createClient } from "npm:@supabase/supabase-js@2";

const origin = "https://nurseroster-eg.github.io";
const cors = {
  "Access-Control-Allow-Origin": origin,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reply = (status: number, body: object) => Response.json(body, { status, headers: cors });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "POST" || req.headers.get("origin") !== origin) return reply(403, {});
  let body;
  try { body = await req.json(); } catch { return reply(400, { error: "طلب غير صالح" }); }
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const enrollment = () => db.from("employee_enrollment");

  if (body?.action === "register") {
    const number = typeof body.employee_no === "string" ? body.employee_no.trim() : "";
    const login = typeof body.login === "string" ? body.login.trim().toLowerCase() : "";
    const password = body.password;
    if (!number || number.length > 40 || !/^[a-z0-9_-]{3,40}$/.test(login) ||
        typeof password !== "string" || password.length < 12 || new TextEncoder().encode(password).length > 72) {
      return reply(400, { error: "راجع الرقم الوظيفي واسم المستخدم وكلمة المرور" });
    }
    const accepted = () => reply(202, { message: "لو الرقم متاح للتسجيل، طلبك هيوصل لمدير النظام للمراجعة." });
    const requested = new Date().toISOString();
    const { data: entry, error: reserveError } = await enrollment()
      .update({ requested_login: login, requested_at: requested }).eq("employee_no", number)
      .is("requested_at", null).is("approved_at", null).select("full_name").maybeSingle();
    if (reserveError) return reply(503, { error: "تعذر استقبال الطلب حالياً" });
    if (!entry) return accepted();
    const { data, error } = await db.auth.admin.createUser({
      email: login + "@roster.invalid", password, email_confirm: false,
      user_metadata: { full_name: entry.full_name },
    });
    if (error || !data.user) {
      await enrollment().update({ requested_login: null, requested_at: null })
        .eq("employee_no", number).eq("requested_at", requested).is("auth_user_id", null);
      return reply(409, { error: "تعذر تسجيل اسم المستخدم. اختار اسم مختلف." });
    }
    const { error: attachError } = await enrollment().update({ auth_user_id: data.user.id })
      .eq("employee_no", number).eq("requested_at", requested);
    if (attachError) return reply(503, { error: "تعذر إكمال الطلب. تواصل مع مدير النظام." });
    return accepted();
  }

  const managerId = Deno.env.get("ROSTER_SYSTEM_MANAGER_ID");
  const token = req.headers.get("authorization")?.match(/^Bearer (\S+)$/i)?.[1];
  if (!token || !managerId) return reply(403, {});
  const { data: { user } } = await db.auth.getUser(token);
  if (user?.id !== managerId) return reply(403, {});
  const { data: profile } = await db.from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (profile?.role !== "admin") return reply(403, {});

  if (body?.action === "list") {
    const { data, error } = await enrollment().select("employee_no,full_name,requested_login,requested_at")
      .not("auth_user_id", "is", null).is("approved_at", null).order("requested_at").limit(200);
    return error ? reply(500, { error: "تعذر تحميل الطلبات" }) : reply(200, { requests: data });
  }
  if (body?.action !== "approve" || typeof body.employee_no !== "string") return reply(400, {});
  const { data: entry } = await enrollment().select("auth_user_id,full_name")
    .eq("employee_no", body.employee_no).is("approved_at", null).maybeSingle();
  if (!entry?.auth_user_id) return reply(404, { error: "الطلب غير موجود" });
  const { error: profileError } = await db.from("profiles").update({ employee_no: body.employee_no, full_name: entry.full_name })
    .eq("id", entry.auth_user_id).eq("role", "nurse").select("id").single();
  if (profileError) return reply(409, { error: "راجع تعارض الرقم الوظيفي أو بيانات الحساب" });
  const { error: approvalError } = await db.auth.admin.updateUserById(entry.auth_user_id, { email_confirm: true });
  if (approvalError) return reply(500, { error: "تعذر تفعيل الحساب" });
  const { error: recordError } = await enrollment().update({ approved_at: new Date().toISOString() })
    .eq("employee_no", body.employee_no).eq("auth_user_id", entry.auth_user_id);
  return recordError ? reply(500, { error: "تم تفعيل الدخول وتعذر تحديث حالة الطلب" }) : reply(200, { approved: true });
});
