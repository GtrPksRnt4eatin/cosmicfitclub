# Plaid Production Setup (Chase Transactions)

## 1) Add production env vars

Set these in Heroku/app env:

- `PLAID_ENV=production`
- `PLAID_CLIENT_ID=...`
- `PLAID_SECRET=...`
- `PLAID_PRODUCTS=transactions`
- `PLAID_COUNTRY_CODES=US`
- `PLAID_CLIENT_NAME=CosmicFit`
- `PLAID_REDIRECT_URI=https://YOUR_DOMAIN/...` (only if your Link flow uses OAuth redirect)

## 2) Install dependencies

```bash
bundle install
```

## 3) Create a Link token

`POST /integrations/plaid/link_token`

Example:

```bash
curl -X POST https://YOUR_DOMAIN/integrations/plaid/link_token \
  -H 'Content-Type: application/json' \
  -d '{"user_id":"staff-1"}'
```

This returns `link_token`, which your frontend uses with Plaid Link.

## 4) Connect Chase in Plaid Link

In your frontend, initialize Plaid Link with that `link_token`. After the user logs into Chase and finishes Link, you receive a `public_token`.

## 5) Exchange `public_token` for `access_token`

`POST /integrations/plaid/exchange_public_token`

```bash
curl -X POST https://YOUR_DOMAIN/integrations/plaid/exchange_public_token \
  -H 'Content-Type: application/json' \
  -d '{"public_token":"PUBLIC_TOKEN_FROM_LINK"}'
```

Save the returned `access_token` securely (server-side only).

## 6) Pull transactions

`POST /integrations/plaid/transactions`

```bash
curl -X POST https://YOUR_DOMAIN/integrations/plaid/transactions \
  -H 'Content-Type: application/json' \
  -d '{
    "access_token":"ACCESS_TOKEN",
    "start_date":"2026-10-01",
    "end_date":"2026-10-31"
  }'
```

If you set `PLAID_ACCESS_TOKEN`, you can omit `access_token` in the request body.

## Notes for Chase

- Chase commonly uses OAuth in production; make sure your Plaid dashboard redirect URI matches `PLAID_REDIRECT_URI`.
- Use production keys only in production.
- Never store `public_token`; exchange it immediately and store only `access_token` securely.
