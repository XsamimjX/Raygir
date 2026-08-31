# Raygir

Raygir is the Laravel 13/Inertia React application and owns the application protocol.

This repository contains:

- Laravel/Inertia Raygir at the repository root.
- Solidity contracts under `contracts/`.
- ZK circuits under `circuits/`.
- The eligibility-authority demo under `issuer-demo/`.
- Shared protocol schemas under `packages/protocol/`.

It does not contain Sepehr Chain or Sepehrbin. During local development those independent repositories may be cloned beside this application at `sepehr-chain/` and `sepehrbin/`; both paths are ignored here.

Local verification:

```bash
composer install
npm ci
php artisan migrate
php artisan test --compact
npm run types:check
npm run lint:check
npm run build
```

Raygir requires PostgreSQL. Copy `.env.example` to `.env`, configure PostgreSQL, the Sepehr RPC endpoints, contracts, relayer, bundler, and public URLs, then generate the Laravel application key. Never commit `.env`, signing keys, wallet material, or production credentials.
