# WELLAURA Security Skill

Apply automatically to authentication, APIs, user data, payments/subscriptions, AI integrations, and infrastructure changes.

## Secrets
Never commit or expose `.env` values, API keys, tokens, passwords, or private keys. Use environment variables and existing configuration patterns.

## Authorization
Authentication is not authorization. For every user-owned resource verify ownership server-side. Check for IDOR risks in user, workout, favorite, goal, profile, and other object IDs. Never trust a client-supplied user ID when the authenticated identity is available.

## Input/API Security
Validate input. Preserve Django/DRF protections. Avoid unsafe dynamic SQL and unsafe deserialization.

## Logs
Never log credentials, tokens, session secrets, or unnecessary personal data.

## AI
Do not send secrets or unnecessary private user data to an AI provider. Treat AI-generated recommendations as untrusted output and validate structured data before persistence/use.
