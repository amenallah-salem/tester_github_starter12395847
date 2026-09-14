"""
Server-side OpenRouter client for the AI chat feature.

Kept separate from views.py (mirrors otp.py/sms.py) so the HTTP call to the
model provider is small, isolated, and easy to swap for a fake in tests
(see tests.py:FakeOpenRouterService). The API key/base URL/model come from
Django settings (populated from OPENROUTER_* env vars) — never from the
client, never logged, never returned in any response body.
"""
import json

import requests
from django.conf import settings


class OpenRouterError(Exception):
    """Generic upstream failure (non-2xx, network error, etc.)."""


class OpenRouterAuthError(OpenRouterError):
    """Invalid/missing API key. Not worth retrying."""


class OpenRouterRateLimited(OpenRouterError):
    """Upstream rate limit. Not worth retrying immediately."""


class OpenRouterTimeout(OpenRouterError):
    """Request to OpenRouter timed out."""


class StreamChunk:
    """One incremental piece of a streamed completion."""

    def __init__(self, delta_text='', finish_reason=None, usage=None):
        self.delta_text = delta_text
        self.finish_reason = finish_reason
        self.usage = usage


class OpenRouterService:
    """Thin wrapper around OpenRouter's OpenAI-compatible chat completions
    API. Configured entirely from settings — callers never pass a model or
    API key, so the client can never override either."""

    REQUEST_TIMEOUT_SECONDS = 30

    def __init__(self):
        self.api_key = settings.OPENROUTER_API_KEY
        self.base_url = settings.OPENROUTER_BASE_URL.rstrip('/')
        self.model = settings.OPENROUTER_MODEL

    def is_configured(self):
        return bool(self.api_key)

    def _headers(self):
        return {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json',
        }

    def stream_chat_completion(self, messages):
        """Yield StreamChunk objects as they arrive from OpenRouter.

        `messages` is a list of {'role': ..., 'content': ...} dicts, already
        built by gym_api/ai/context.py (system prompt + trimmed history).
        """
        if not self.is_configured():
            raise OpenRouterAuthError('OPENROUTER_API_KEY is not configured.')

        payload = {
            'model': self.model,
            'messages': messages,
            'stream': True,
        }

        try:
            response = requests.post(
                f'{self.base_url}/chat/completions',
                headers=self._headers(),
                json=payload,
                stream=True,
                timeout=self.REQUEST_TIMEOUT_SECONDS,
            )
        except requests.Timeout as exc:
            raise OpenRouterTimeout('OpenRouter request timed out.') from exc
        except requests.RequestException as exc:
            raise OpenRouterError('Could not reach OpenRouter.') from exc

        if response.status_code in (401, 403):
            raise OpenRouterAuthError('OpenRouter rejected the API key.')
        if response.status_code == 429:
            raise OpenRouterRateLimited('OpenRouter rate limit exceeded.')
        if response.status_code >= 400:
            raise OpenRouterError(f'OpenRouter returned HTTP {response.status_code}.')

        try:
            # decode_unicode=True would let `requests` guess the encoding
            # from headers, which falls back to Latin-1 for a response
            # without an explicit charset and mangles multi-byte UTF-8
            # characters (e.g. em dashes) the model emits. Decode bytes
            # as UTF-8 ourselves instead.
            for raw_bytes in response.iter_lines(decode_unicode=False):
                if not raw_bytes:
                    continue
                raw_line = raw_bytes.decode('utf-8', errors='replace')
                if not raw_line.startswith('data:'):
                    continue
                data = raw_line[len('data:'):].strip()
                if data == '[DONE]':
                    break
                try:
                    event = json.loads(data)
                except (json.JSONDecodeError, ValueError):
                    continue
                choice = (event.get('choices') or [{}])[0]
                delta = choice.get('delta') or {}
                text = delta.get('content') or ''
                finish_reason = choice.get('finish_reason')
                usage = event.get('usage')
                if text or finish_reason or usage:
                    yield StreamChunk(delta_text=text, finish_reason=finish_reason, usage=usage)
        except requests.RequestException as exc:
            raise OpenRouterError('OpenRouter stream was interrupted.') from exc

    def chat_completion(self, messages):
        """Non-streaming convenience wrapper (used by the real-request smoke
        test) — accumulates a stream into a single string."""
        text = ''
        finish_reason = None
        usage = None
        for chunk in self.stream_chat_completion(messages):
            text += chunk.delta_text
            if chunk.finish_reason:
                finish_reason = chunk.finish_reason
            if chunk.usage:
                usage = chunk.usage
        return text, finish_reason, usage
