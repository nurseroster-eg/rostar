# NurseRoster GitHub Pages setup
1. Create a Supabase project at https://supabase.com/dashboard.
2. Run `schema.sql` then `audit.sql`, `user-management.sql`, then `departments.sql` in SQL Editor.
3. In Supabase Authentication > Users, create one user per nurse/supervisor.
4. For username login, use a unique alias email such as `nurse105@roster.invalid` and a strong password, created administratively; use the same username `nurse105` on the login screen. The email alias is NOT a deliverable mailbox. Do not enable public self-registration. Supabase's email-confirmation behavior may require admin-created confirmed users.
5. The schema backfills missing profiles for existing Auth users and preserves existing roles. To make an admin, verify the intended account in Authentication > Users and copy its UUID, then run `update public.profiles set role='admin' where id='THE_ADMIN_UUID';` in SQL Editor. Do this only for trusted supervisors.
6. In `config.js`, enter the project's URL and **publishable/anon** key (never service_role).
7. GitHub repository Settings > Pages > Build and deployment > Deploy from a branch > main > /docs > Save.
8. Visit `https://khaledmoon64.github.io/rostar/` after Pages publishes.
9. Test with dummy accounts before importing real employee data. Use Supabase backups/export, restrict admin access, and enable MFA for supervisors if available.

GitHub Pages hosts static UI only. Supabase stores the users and preferences. Free tier has limits and may pause inactive projects. This is an MVP, not a production-tested clinical staffing system.

## Create accounts from NurseRoster
Deploy the `create-roster-user` Supabase Edge Function before using the account form.
From the repository root, with an authenticated Supabase CLI:

```sh
supabase functions deploy create-roster-user --project-ref knvxfyalfqqklpiwcwor
```

The function uses the Supabase-provided server environment. The browser sends the
signed-in user's access token, and the function verifies the caller's current
admin role before creating a confirmed account. Use the Nurse role by default.
