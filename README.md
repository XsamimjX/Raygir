# Raygir | رای‌گیر

[English](#english) · [فارسی](#فارسی)

Repository: <https://github.com/XsamimjX/Raygir>

## English

Raygir is a bilingual Persian/English research application for privacy-preserving civic polls and prediction markets on Sepehr Chain. It uses Laravel 13, Inertia 3, React 19, PostgreSQL, Solidity contracts, and zero-knowledge circuits.

This repository owns the Raygir application at its root, Solidity contracts in `contracts/`, Circom and Noir circuits in `circuits/`, the fictional eligibility-authority demonstration in `issuer-demo/`, and shared schemas in `packages/protocol/`. Sepehr Chain and Sepehrbin are independent repositories. Their local `sepehr-chain/` and `sepehrbin/` directories are ignored here.

### Requirements

- Git 2.40 or newer.
- PHP 8.3 or newer with PostgreSQL/PDO and normal Laravel extensions.
- Composer 2, PostgreSQL, Node.js 22 or newer, and npm.
- Foundry for Solidity and Noir `nargo` for Noir circuits.
- A Chromium-based browser for browser tests.

### Application installation

```bash
git clone <raygir-repository-url> raygir
cd raygir
git submodule update --init --recursive
composer install --no-interaction
npm ci
cp .env.example .env
php artisan key:generate
```

On PowerShell, use `Copy-Item .env.example .env`. Create an isolated PostgreSQL database and user, then set `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, and `DB_PASSWORD` in `.env`. Do not use SQLite for durable application state.

```sql
CREATE USER raygir_app WITH PASSWORD 'replace-with-a-strong-password';
CREATE DATABASE raygir OWNER raygir_app;
```

```bash
php artisan migrate --force
npm run build
composer run dev
```

The local URL is normally `http://127.0.0.1:8000`. Persian pages use `/fa`; English pages use `/en`.

Chain-dependent functionality additionally requires Sepehr RPC and contract addresses, relayer/bundler configuration, eligibility issuer keys, and CLOB prover/gateway settings in `.env`. Empty values keep those integrations unavailable; the application must not fabricate chain data. Never commit `.env`, wallet keys, issuer secrets, recovery packages, or production credentials.

### Contracts and circuits

```bash
cd contracts
forge build
forge test
forge fmt --check
```

```bash
cd circuits
npm ci
npm test
```

Run `nargo check` and `nargo test` separately in `circuits/noir/foundation/` and `circuits/noir/clob_authorization/`.

### Eligibility-authority demo

The fictional issuer is a separate Laravel application with its own PostgreSQL database and origin:

```bash
cd issuer-demo
composer install --no-interaction
npm ci
cp .env.example .env
php artisan key:generate
php artisan migrate --force
npm run build
php artisan serve --port=8010
```

Use a database such as `raygir_issuer` owned by a separate role. Never point the issuer and Raygir at the same database.

### Verification

```bash
php artisan test --compact
npm run types:check
npm run lint:check
npm run format:check
npm run build
npm run test:browser
```

### Production outline

Use TLS, Nginx, PHP-FPM, PostgreSQL, supervised queue workers, the Laravel scheduler, and a separately managed relayer/prover. Serve `public/` as the web root. Use `APP_ENV=production`, `APP_DEBUG=false`, encrypted backups, rotated secrets, and monitored queues. Raygir remains research/testnet software and must not accept real-value assets until the later gates in `plan.md` pass.

---

## فارسی

رای‌گیر یک برنامه پژوهشی دوزبانه برای رأی‌گیری مدنی حریم‌خصوصی‌محور و بازارهای پیش‌بینی روی زنجیره سپهر است. فناوری‌های اصلی آن Laravel 13،‏ Inertia 3،‏ React 19،‏ PostgreSQL، قراردادهای Solidity و مدارهای اثبات دانش صفر هستند.

مخزن رسمی: <https://github.com/XsamimjX/Raygir>

این مخزن شامل برنامه اصلی رای‌گیر، قراردادهای `contracts/`، مدارهای `circuits/`، مرجع احراز صلاحیت نمایشی `issuer-demo/` و طرح‌واره‌های `packages/protocol/` است. زنجیره سپهر و سپهربین دو مخزن مستقل هستند.

### پیش‌نیازها

- Git نسخه 2.40 یا جدیدتر.
- PHP نسخه 8.3 یا جدیدتر با PostgreSQL/PDO و افزونه‌های معمول Laravel.
- Composer 2،‏ PostgreSQL،‏ Node.js نسخه 22 یا جدیدتر و npm.
- Foundry برای Solidity و ابزار `nargo` برای Noir.
- مرورگر Chromium برای آزمون مرورگر.

### نصب

```bash
git clone <raygir-repository-url> raygir
cd raygir
git submodule update --init --recursive
composer install --no-interaction
npm ci
cp .env.example .env
php artisan key:generate
```

در PowerShell از `Copy-Item .env.example .env` استفاده کنید. یک کاربر و پایگاه‌داده مستقل PostgreSQL بسازید، مقادیر `DB_*` را در `.env` وارد کنید و سپس اجرا کنید:

```bash
php artisan migrate --force
npm run build
composer run dev
```

مسیر فارسی `/fa` و مسیر انگلیسی `/en` است. برای قابلیت‌های زنجیره‌ای باید RPC سپهر، آدرس قراردادها، تنظیمات relayer/bundler، کلید صادرکننده صلاحیت و prover/CLOB را تنظیم کنید. مقدار خالی یعنی قابلیت مربوطه غیرفعال است و داده ساختگی نباید نمایش داده شود.

### قراردادها، مدارها و صادرکننده نمایشی

در `contracts/` دستورهای `forge build` و `forge test` را اجرا کنید. در `circuits/` از `npm ci` و `npm test` استفاده کنید. در هر دو پوشه Noir نیز `nargo check` و `nargo test` را اجرا کنید.

برنامه `issuer-demo/` باید با `.env`، کلید برنامه، دامنه و PostgreSQL مستقل نصب شود. پایگاه‌داده آن را با رای‌گیر مشترک نکنید.

### آزمون و استقرار

```bash
php artisan test --compact
npm run types:check
npm run lint:check
npm run format:check
npm run build
```

در تولید از TLS،‏ Nginx،‏ PHP-FPM،‏ PostgreSQL، صف‌های تحت نظارت، زمان‌بند Laravel، پشتیبان‌گیری رمزگذاری‌شده و مدیریت امن اسرار استفاده کنید. ریشه وب باید `public/` باشد. رای‌گیر تا عبور از دروازه‌های `plan.md` فقط نرم‌افزار پژوهشی/تست‌نت است و نباید دارایی واقعی دریافت کند.
