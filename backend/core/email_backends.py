"""Django email delivery through Resend's HTTPS API (no SMTP connection)."""
import json
import logging
from email.utils import parseaddr
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from django.core.exceptions import ImproperlyConfigured
from django.core.mail.backends.base import BaseEmailBackend

logger = logging.getLogger(__name__)


class ResendDeliveryError(RuntimeError):
    """A sanitized delivery error, safe to return through the existing API."""


class ResendEmailBackend(BaseEmailBackend):
    def __init__(self, *, api_key="", timeout=10, fail_silently=False, **kwargs):
        super().__init__(**kwargs)
        self.fail_silently = fail_silently
        self.api_key = api_key.strip()
        self.timeout = timeout
        if not self.api_key:
            raise ImproperlyConfigured("Set RESEND_API_KEY to enable Resend email delivery.")

    def send_messages(self, email_messages):
        sent = 0
        for message in email_messages or ():
            if not message.recipients():
                continue
            try:
                self._send(message)
            except ResendDeliveryError:
                if not self.fail_silently:
                    raise
            else:
                sent += 1
        return sent

    def _send(self, message):
        if message.attachments:
            raise ResendDeliveryError("Attachments are not supported by this email backend.")
        payload = {
            "from": message.from_email,
            "to": message.to,
            "subject": message.subject,
        }
        payload["html" if message.content_subtype == "html" else "text"] = message.body
        for alternative in getattr(message, "alternatives", ()):
            if alternative.mimetype == "text/html":
                payload["html"] = alternative.content
        for field in ("cc", "bcc", "reply_to"):
            if getattr(message, field):
                payload[field] = getattr(message, field)
        request = Request(
            "https://api.resend.com/emails",
            data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json",
                "User-Agent": "Urgoo-Django/1.0",
            },
            method="POST",
        )
        try:
            with urlopen(request, timeout=self.timeout) as response:
                result = json.loads(response.read())
        except HTTPError as error:
            # Never expose provider response bodies, API keys, recipients, or OTPs.
            error.close()
            hints = {
                401: "Check RESEND_API_KEY in Render Environment.",
                403: "Check API permissions, verified sender domain, and the allowed test recipient.",
                422: "Check DEFAULT_FROM_EMAIL and recipient addresses.",
                429: "Resend rate or sending quota reached; try again later.",
            }
            hint = hints.get(error.code, "Check the email event in the Resend dashboard.")
            logger.warning("Resend rejected an email (HTTP %s). %s", error.code, hint)
            raise ResendDeliveryError(f"Resend HTTP {error.code}. {hint}") from None
        except (URLError, OSError):
            logger.warning("Resend HTTPS connection failed or timed out.")
            raise ResendDeliveryError("Resend HTTPS connection failed; try again later.") from None
        except (ValueError, UnicodeError):
            raise ResendDeliveryError("Resend returned an invalid response.") from None
        if not isinstance(result, dict) or not isinstance(result.get("id"), str) or not result["id"]:
            raise ResendDeliveryError("Resend did not confirm that the email was accepted.")


class BrevoDeliveryError(RuntimeError):
    """A sanitized delivery error, safe to return through the existing API."""


class BrevoEmailBackend(BaseEmailBackend):
    """Django email delivery through Brevo's HTTPS API (no SMTP connection).

    Brevo needs only a verified sender email (no domain), which makes it a
    practical choice when no domain is available. Set BREVO_API_KEY.
    """

    def __init__(self, *, api_key="", timeout=10, fail_silently=False, **kwargs):
        super().__init__(**kwargs)
        self.fail_silently = fail_silently
        self.api_key = api_key.strip()
        self.timeout = timeout
        if not self.api_key:
            raise ImproperlyConfigured("Set BREVO_API_KEY to enable Brevo email delivery.")

    def send_messages(self, email_messages):
        sent = 0
        for message in email_messages or ():
            if not message.recipients():
                continue
            try:
                self._send(message)
            except BrevoDeliveryError:
                if not self.fail_silently:
                    raise
            else:
                sent += 1
        return sent

    @staticmethod
    def _address(value):
        name, email = parseaddr(value)
        entry = {"email": email}
        if name:
            entry["name"] = name
        return entry

    def _send(self, message):
        if message.attachments:
            raise BrevoDeliveryError("Attachments are not supported by this email backend.")
        payload = {
            "sender": self._address(message.from_email),
            "to": [self._address(address) for address in message.to],
            "subject": message.subject,
        }
        payload["htmlContent" if message.content_subtype == "html" else "textContent"] = message.body
        for alternative in getattr(message, "alternatives", ()):
            if alternative.mimetype == "text/html":
                payload["htmlContent"] = alternative.content
        if getattr(message, "cc", None):
            payload["cc"] = [self._address(address) for address in message.cc]
        if getattr(message, "bcc", None):
            payload["bcc"] = [self._address(address) for address in message.bcc]
        if getattr(message, "reply_to", None):
            payload["replyTo"] = self._address(message.reply_to[0])
        request = Request(
            "https://api.brevo.com/v3/smtp/email",
            data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
            headers={
                "api-key": self.api_key,
                "Content-Type": "application/json",
                "accept": "application/json",
                "User-Agent": "Urgoo-Django/1.0",
            },
            method="POST",
        )
        try:
            with urlopen(request, timeout=self.timeout) as response:
                result = json.loads(response.read())
        except HTTPError as error:
            # Never expose provider response bodies, API keys, recipients, or OTPs.
            error.close()
            hints = {
                401: "Check BREVO_API_KEY in the environment.",
                403: "Verify the sender email in Brevo and check the API key permissions.",
                422: "Check DEFAULT_FROM_EMAIL, recipient addresses, and message content.",
                429: "Brevo sending quota reached; try again later.",
            }
            hint = hints.get(error.code, "Check the email event in the Brevo dashboard.")
            logger.warning("Brevo rejected an email (HTTP %s). %s", error.code, hint)
            raise BrevoDeliveryError(f"Brevo HTTP {error.code}. {hint}") from None
        except (URLError, OSError):
            logger.warning("Brevo HTTPS connection failed or timed out.")
            raise BrevoDeliveryError("Brevo HTTPS connection failed; try again later.") from None
        except (ValueError, UnicodeError):
            raise BrevoDeliveryError("Brevo returned an invalid response.") from None
        if not isinstance(result, dict) or not result.get("messageId"):
            raise BrevoDeliveryError("Brevo did not confirm that the email was accepted.")

