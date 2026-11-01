# ShaxAI

ShaxAI is an Uzbek-first AI workspace using a static frontend, Supabase Auth/Postgres, and a Cloudflare Worker proxy for Groq.

## Included
- Large responsive chat workspace and professional light UI.
- Google sign-in through Supabase Auth.
- Private per-user conversations and message history.
- Community knowledge submissions are pending until admin review.
- Public read access only to approved knowledge.
- Admin review authorization enforced by Postgres RLS.
- Groq API key stays server-side in Cloudflare Worker secrets.

## Supabase
Project URL: https://czckdcoylhydauernhjr.supabase.co

The initial schema has been applied to the ShaxAi project. Enable Google under Supabase Dashboard → Authentication → Providers. Add the deployed website URL to Authentication → URL Configuration → Redirect URLs.

To grant the first admin, sign in once with the owner's Google account, then run this in Supabase SQL Editor (replace the email):

```sql
insert into public.admin_roles (user_id, role)
select id, 'admin' from auth.users where email = 'YOUR_GOOGLE_EMAIL'
on conflict (user_id) do update set role = 'admin';
```

The browser uses only the Supabase publishable key in config.js. RLS protects user data.

## Cloudflare Worker
Deploy worker.js using wrangler.toml or Cloudflare dashboard. Add Worker secrets:
- GROQ_API_KEY — Groq API key.
- SUPABASE_ANON_KEY — ShaxAi project's legacy anon key.

Set ALLOWED_ORIGIN to the deployed website origin. The Worker validates the user's Supabase access token before forwarding chat requests to Groq. Set CHAT_API_URL in config.js to the deployed Worker URL plus /api/chat if frontend and Worker use different origins.

## Frontend
Serve index.html, styles.css, config.js, and app.js from GitHub Pages, Cloudflare Pages, or another static host. No frontend build step is required.

## Security notes
- User knowledge is inserted as pending; users cannot approve their own entries.
- Only admin_roles members can review submissions.
- Never place Groq or Supabase service-role secrets in browser files.
- Configure Cloudflare rate limiting before public launch.
- Admins should review community knowledge; automatic AI review is not a guarantee of truth.