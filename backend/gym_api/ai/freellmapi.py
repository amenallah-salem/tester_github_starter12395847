"""
Server-side client for freellmapi (github.com/tashfeenahmed/freellmapi), a
local OpenAI-compatible proxy exposing /v1/chat/completions, /v1/responses,
/v1/messages and /v1/embeddings.

Mirrors gym_api/ai/openrouter.py's OpenRouterService — same
stream_chat_completion()/chat_completion() interface — so
AISendMessageStreamView (see views.py:get_ai_service()) can swap between
providers without changing any call site. The API key/base URL/model come
from Django settings (populated from FREELLMAPI_* env vars) — never from the
client, never logged, never returned in any response body.
"""
import json

import requests
from django.conf import settings

from .openrouter import StreamChunk


class FreellmapiError(Exception):
    """Generic upstream failure (non-2xx, network error, etc.)."""


class FreellmapiAuthError(FreellmapiError):
    """Invalid/missing API key. Not worth retrying."""


class FreellmapiRateLimited(FreellmapiError):
    """Upstream rate limit. Not worth retrying immediately."""


class FreellmapiTimeout(FreellmapiError):
    """Request to freellmapi timed out."""


class FreellmapiService:
    """Thin wrapper around freellmapi's OpenAI-compatible chat completions
    API. Configured entirely from settings — callers never pass a model or
    API key, so the client can never override either."""

    REQUEST_TIMEOUT_SECONDS = 30

    def __init__(self):
        self.api_key = settings.FREELLMAPI_API_KEY
        self.base_url = settings.FREELLMAPI_BASE_URL.rstrip('/')
        self.model = settings.FREELLMAPI_MODEL

    def is_configured(self):
        return bool(self.api_key)

    def _headers(self):
        return {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json',
        }

    def stream_chat_completion(self, messages):
        """Yield StreamChunk objects as they arrive from freellmapi.

        `messages` is a list of {'role': ..., 'content': ...} dicts, already
        built by gym_api/ai/context.py (system prompt + trimmed history).
        """
        if not self.is_configured():
            raise FreellmapiAuthError('FREELLMAPI_API_KEY is not configured.')

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
            raise FreellmapiTimeout('freellmapi request timed out.') from exc
        except requests.RequestException as exc:
            raise FreellmapiError('Could not reach freellmapi.') from exc

        if response.status_code in (401, 403):
            raise FreellmapiAuthError('freellmapi rejected the API key.')
        if response.status_code == 429:
            raise FreellmapiRateLimited('freellmapi rate limit exceeded.')
        if response.status_code >= 400:
            raise FreellmapiError(f'freellmapi returned HTTP {response.status_code}.')

        try:
            # See OpenRouterService.stream_chat_completion for why we decode
            # bytes as UTF-8 ourselves instead of decode_unicode=True.
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
            raise FreellmapiError('freellmapi stream was interrupted.') from exc

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
