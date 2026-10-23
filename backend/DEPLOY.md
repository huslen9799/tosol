# Backend deployment

Database: existing Neon database. Media: Cloudinary. API: Render Web Service.
Do not use the Render filesystem for uploaded images: it is ephemeral.

## Before deploying

1. Create a Cloudinary account and copy its CLOUDINARY_URL into backend/.env.
2. Install dependencies locally:
   `.\backend\venv\Scripts\python.exe -m pip install -r backend/requirements.txt`
3. Stop local API writes. Back up Neon before modifying image paths. Keep the
   existing DB dumps and backend/media as recovery copies.
4. Upload images to Cloudinary, using the Neon URL already in backend/.env:
   `powershell -ExecutionPolicy Bypass -File scripts/backend-online.ps1 upload_media`
5. Verify image URLs and push these source changes through GitHub Desktop.
   Never commit .env, .local-secrets.json, media, or database backups.

## Render Web Service

Repository: https://github.com/huslen23/tosol
Branch: main
Root Directory: backend
Runtime: Python
Build Command: bash build.sh
Start Command: bash start.sh
Health Check Path: /health/

Choose a service plan only after reviewing its price. Free services block
outbound SMTP ports including Gmail's 587, so Gmail OTP requires a compatible
paid plan or a separately configured HTTPS email provider. Do not launch an
OTP-dependent registration flow with email delivery unverified.

Environment variables:

- PYTHON_VERSION: a Render-supported Python 3.14 patch version
- DATABASE_URL: the existing Neon connection URL, including SSL options
- CLOUDINARY_URL: Cloudinary credentials
- DJANGO_DEBUG: false
- DJANGO_SECRET_KEY: generate a new random secret for production
- EMAIL_HOST_USER / EMAIL_HOST_PASSWORD: SMTP user and a newly issued App Password
- DEFAULT_FROM_EMAIL: the sender address
- CORS_ALLOWED_ORIGINS: actual Flutter web origins, comma-separated
- CSRF_TRUSTED_ORIGINS: actual Flutter web origins, comma-separated

Render's own hostname is added to ALLOWED_HOSTS automatically. For custom API
domains set DJANGO_ALLOWED_HOSTS (hostnames only, comma-separated).

## Email on Render Free: Resend HTTPS API

The application selects `core.email_backends.ResendEmailBackend` automatically
when `RESEND_API_KEY` is nonempty. Registration, resend OTP, and password reset
keep their existing Django `send_mail()` calls and use HTTPS on port 443.
No additional package is required. SMTP variables and `EMAIL_BACKEND` overrides
are ignored while the Resend key is present. With no Resend key, the original
SMTP/development configuration is retained.

Deploy the source change before testing. In Render Environment set:

- `RESEND_API_KEY`: the `re_...` key generated in Resend.
- `DEFAULT_FROM_EMAIL`: a sender address on a domain verified in Resend.

For a domain-free test use `Urgoo <onboarding@resend.dev>` as the sender, and
register with the email address that owns the Resend account. This sender
cannot send OTPs to arbitrary users. A Gmail App Password is not a Resend key,
and a Gmail address is not a verified Resend sending domain.

After pushing to GitHub, wait for Render's deployment of that commit to become
Live. Test registration, resend, and password reset with an address you control.
Check Resend's Emails log for accepted/delivered/bounced events and the recipient's
Spam folder. An API acceptance ID confirms submission, not inbox delivery.
Do not post API keys, OTPs, or database credentials in chat or commit them.

Sanitized Render log errors identify common configuration problems:

- HTTP 401: missing/invalid key.
- HTTP 403: key permissions, unverified sender domain, or disallowed test recipient.
- HTTP 422: sender or recipient format.
- HTTP 429: sending quota or rate limit.
- HTTPS connection failure: network timeout; retry later.

Provider contract tests, using mocked HTTPS responses (no real mail or DB):

`python manage.py test core.test_resend --noinput`

References: https://resend.com/docs/api-reference/emails/send-email and
https://resend.com/docs/api-reference/errors

## Verify after deployment

Check /health/ and /api/properties/, image loading, login, OTP delivery, password
reset, and an authenticated image upload. /health/ checks the process only;
the API request also verifies database connectivity.

Run Flutter with the real deployed API URL:

`flutter run --dart-define=API_BASE_URL=https://YOUR-SERVICE.onrender.com`

For releases, pass the same dart-define to flutter build. Browser frontend
hosting is separate from hosting this API. Keep local backups until deployment
and uploads are verified. Removing old secrets from current files does not
revoke them or remove them from Git history.
