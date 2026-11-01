# ShaxAI

ShaxAI is an Uzbek-first AI workspace using a static frontend, Supabase Auth/Postgres, and a Cloudflare Worker proxy for Groq.

## Included
- Responsive chat workspace and Google sign-in.
- Private per-user conversations and message history.
- Community knowledge submissions with admin review.
- API key dashboard for external websites and apps.
- OpenAI-compatible `POST /v1/chat/completions` endpoint.
- API keys are stored as SHA-256 hashes; full keys are shown only once.
- Each API key starts with a limit of 100 requests per day and can be revoked.

## Supabase
Project URL: https://czckdcoylhydauernhjr.supabase.co

The schema and API key table are already applied to this project. Enable Google under Supabase Dashboard → Authentication → Providers. Add the deployed website URL to Authentication → URL Configuration → Redirect URLs.

The browser uses the Supabase publishable key in `config.js`. The Worker already has the public anon key as a fallback, so you do not need to add a Supabase secret. The anon key is not a service-role key.

To grant the first admin, sign in once with the owner's Google account, then run this in Supabase SQL Editor (replace the email):

```sql
insert into public.admin_roles (user_id, role)
select id, 'admin' from auth.users where email = 'YOUR_GOOGLE_EMAIL'
on conflict (user_id) do update set role = 'admin';
```

## Cloudflare Worker
Deploy `worker.js` with `wrangler.toml` or Cloudflare dashboard. Add only this required Worker secret:
- `GROQ_API_KEY` — your Groq API key.

The Worker uses `SUPABASE_URL` from `wrangler.toml` and the public anon key fallback in its source. Keep the Groq key secret. `ALLOWED_ORIGIN = "*"` allows API calls from other sites; API keys must still be kept on server-side code. Set `CHAT_API_URL` in `config.js` to the Worker URL plus `/api/chat` if the frontend and Worker use different origins.

The Worker provides:
- `POST /api/chat` for the ShaxAI website.
- `POST /v1/chat/completions` for external integrations, using `Authorization: Bearer sk-shax-...`.

## External API example

```bash
curl https://YOUR-WORKER.workers.dev/v1/chat/completions \
  -H "Authorization: Bearer sk-shax-YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "shaxai",
    "messages": [{"role":"user","content":"Salom, ShaxAI!"}]
  }'
```

The API key is created in the ShaxAI → API kalitlar page after Google sign-in. Copy it immediately; the full value is not stored or shown again. Revoke keys from the same page.

## Frontend
Serve `index.html`, `styles.css`, `config.js`, and `app.js` from GitHub Pages, Cloudflare Pages, or another static host. No frontend build step is required.

## Security
- Never put Groq keys or Supabase service-role keys in browser files.
- Never embed a ShaxAI API key in public HTML/JavaScript; call the API from your own server.
- API key hashes are not readable by normal authenticated users.
- Each key has a 100-request daily limit enforced in the database.
- Configure additional Cloudflare abuse protection before a large public launch.
