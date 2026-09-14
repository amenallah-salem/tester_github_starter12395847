"""
Deterministic conversation-title generation from the first user message.
No extra LLM call — just a truncation at a word boundary.
"""
MAX_TITLE_LENGTH = 40


def title_from_message(text):
    text = ' '.join(text.strip().split())
    if not text:
        return 'New Chat'
    if len(text) <= MAX_TITLE_LENGTH:
        return text
    truncated = text[:MAX_TITLE_LENGTH]
    if ' ' in truncated:
        truncated = truncated.rsplit(' ', 1)[0]
    return truncated.rstrip('.,;:') + '…'
