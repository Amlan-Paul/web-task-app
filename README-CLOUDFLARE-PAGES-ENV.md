# WebTask Manager — Cloudflare Pages Environment Configuration

## Architecture
- Static frontend: `index.html`
- Server-side config endpoint: `functions/api/config.js` (`GET /api/config`)
- Configuration storage: Cloudflare Pages → Settings → Variables and Secrets
- No separate Worker, KV namespace, admin token, or browser-side credential storage.

## 1. Add Cloudflare variables
Open your Cloudflare Dashboard → Workers & Pages → select your Pages project → Settings → Variables and Secrets.
Add these variables for **Production** (and Preview too, if you use preview deployments):

| Name | Value |
|---|---|
| `SUPABASE_URL` | `https://YOUR-PROJECT-REF.supabase.co` |
| `SUPABASE_ANON_KEY` | Your Supabase `anon` / publishable public key |

Do not add a `service_role` key or Supabase secret key. The anon/publishable key is designed to be visible to browser clients; secure database access with Supabase Row Level Security (RLS) policies.

## 2. Deploy Pages Functions
Cloudflare Pages Functions are not deployed by uploading only `index.html` with the dashboard drag-and-drop uploader. Deploy the project with Git integration or Wrangler so the `functions/` directory is included.

Recommended Wrangler route:

```bash
npm install -g wrangler
wrangler login
wrangler pages deploy . --project-name YOUR_PAGES_PROJECT_NAME
```

Run this command from the directory containing `index.html` and the `functions/` directory. If your project already uses a build output directory, deploy that directory and ensure `functions/api/config.js` is included in the Pages project root according to your build setup.

## 3. Verify
Open `https://YOUR-PAGES-DOMAIN.pages.dev/api/config`.
A successful response contains `url` and `anonKey`. This is the public browser configuration, not a private server secret.
Then open the WebTask Manager and check the Supabase connection diagnostic.

## Security notes
- The endpoint is read-only. It has no write/delete route.
- Cloudflare stores the variables server-side; the frontend cannot edit them.
- The endpoint intentionally returns the anon/publishable key because Supabase browser clients require it.
- Supabase RLS is mandatory for protecting table data. Do not rely on the app's client-side role checks as database security.
- Remove old `webtask_supabase_url` and `webtask_supabase_key` values from browser localStorage if you previously used the old build. This updated code no longer reads or writes them.
