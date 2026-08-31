# Raygir and Sepehrbin Design Specification

## 1. Purpose and principles

This document is the implementation source of truth for the bilingual Raygir, issuer-demo, and Sepehrbin interfaces. It covers public, anonymous, authenticated-operator, trading, voting, explorer, and failure-state experiences.

The visual direction is a civic-market hybrid:

- Civic flows are calm, spacious, readable, and institutionally trustworthy.
- Trading flows are denser and faster without becoming visually noisy.
- Explorer flows are technical, data-first, and optimized for scanning hashes, state, and status.
- Security and privacy claims are literal. Never use “completely anonymous,” “untraceable,” “risk-free,” or “stable” for test assets.
- Cryptography claims are literal. Use `classical`, `hybrid PQ`, `PQ-ready`, or `not yet PQ` from the protocol inventory; never label the Phase 2 chain simply `post-quantum secure`.
- All value-bearing actions show the immutable rule summary immediately before confirmation.
- No page fabricates fallback markets, balances, transactions, votes, evidence, or analytics.

## 2. Brand architecture and voice

| Product | Persian name | English name | Purpose | Voice |
|---|---|---|---|---|
| Raygir | رأی‌گیر | Raygir | Voting and prediction application | Clear, neutral, cautious |
| Sepehr | سپهر | Sepehr | Experimental EVM network | Technical, factual |
| Sepehrbin | سپهربین | Sepehrbin | Chain explorer and developer interface | Precise, compact |
| Issuer demo | مرجع آزمایشی احراز صلاحیت | Demo Eligibility Authority | Fictional two-site credential demonstration | Formal, instructional |

Primary Persian tagline: `انتخاب آگاهانه، اثبات‌پذیر و خصوصی`

Primary English tagline: `Informed choices, privately proven`

Permanent testnet disclosure:

- Persian: `این سامانه آزمایشی است. دارایی‌های شبکه ارزش پولی، پشتوانه یا حق بازخرید ندارند.`
- English: `This is an experimental system. Network assets have no monetary value, backing, or redemption right.`

Privacy limitation disclosure:

- Persian: `اثبات دانایی صفر هویت را از رأی جدا می‌کند، اما بدافزار دستگاه، نشانی IP، زمان‌بندی و تبانی زیرساخت‌ها را پنهان نمی‌کند.`
- English: `Zero-knowledge proofs separate identity from a vote, but do not hide device malware, IP metadata, timing, or colluding infrastructure.`

Cryptography disclosure:

- Persian: `نسخه آزمایشی شبکه برای سازگاری EVM هنوز از برخی الگوریتم‌های کلاسیک استفاده می‌کند. امضای ترکیبی پساکوانتومی در بخش‌های مشخص فعال است، اما کل زنجیره هنوز پساکوانتومی نیست.`
- English: `The experimental EVM-compatible network still uses some classical algorithms. Hybrid post-quantum signing is enabled on identified surfaces, but the whole chain is not yet post-quantum.`
- Every signature/certificate detail view shows algorithm, parameter set, classical/PQ/hybrid status, key version, domain tag, creation time, expiry, revocation state, and verification result.
- Sepehrbin shows paired Keccak-256 and SHA3-384 artifact digests when both exist, while addresses, transaction hashes, and block hashes remain labeled as EVM Keccak-256 values.
- Wallet confirmations identify whether authorization is classical-only or hybrid. High-value/admin actions warn and fail closed when a required ML-DSA component is absent or invalid.

## 3. Token architecture

Use three layers. Components must consume component or semantic tokens, never primitive values directly.

```text
Primitive values → semantic roles → component tokens
```

### 3.1 Primitive colors

| Token | Light value | Purpose |
|---|---:|---|
| `navy-950` | `#071A2B` | Darkest foundation |
| `navy-900` | `#0B2238` | Dark surfaces |
| `navy-800` | `#12324D` | Elevated dark surfaces |
| `teal-700` | `#087A79` | Primary dark |
| `teal-600` | `#0B918E` | Primary |
| `teal-500` | `#16AAA5` | Primary hover on dark |
| `saffron-500` | `#E8A317` | Accent and selected market signal |
| `saffron-400` | `#F2B93B` | Accent hover on dark |
| `green-600` | `#16835C` | Success/YES only with text/icon |
| `red-600` | `#C23B4A` | Error/NO only with text/icon |
| `amber-600` | `#B96C0A` | Warning/pending |
| `blue-600` | `#2B67C8` | Informational/link |
| `slate-950` | `#101820` | Light-theme foreground |
| `slate-700` | `#344653` | Secondary foreground |
| `slate-500` | `#687985` | Muted foreground |
| `slate-300` | `#C7D1D8` | Strong border |
| `slate-200` | `#DDE4E8` | Border |
| `slate-100` | `#EDF2F4` | Muted surface |
| `white` | `#FFFFFF` | Light surface |

### 3.2 Semantic colors

Light theme:

```css
--background: var(--white);
--foreground: var(--slate-950);
--surface: var(--white);
--surface-muted: var(--slate-100);
--surface-elevated: var(--white);
--border: var(--slate-200);
--border-strong: var(--slate-300);
--primary: var(--teal-700);
--primary-hover: var(--teal-600);
--primary-foreground: var(--white);
--accent: var(--saffron-500);
--accent-foreground: var(--navy-950);
--link: var(--blue-600);
--success: var(--green-600);
--warning: var(--amber-600);
--danger: var(--red-600);
--focus-ring: var(--teal-600);
```

Dark theme:

```css
--background: var(--navy-950);
--foreground: #F3F7F8;
--surface: var(--navy-900);
--surface-muted: var(--navy-800);
--surface-elevated: #173A55;
--border: #294B62;
--border-strong: #3B6178;
--primary: var(--teal-500);
--primary-hover: #35BDB8;
--primary-foreground: var(--navy-950);
--accent: var(--saffron-400);
--accent-foreground: var(--navy-950);
--link: #7FB0FF;
--success: #52C391;
--warning: #F1B95B;
--danger: #F27984;
--focus-ring: #5AD4CF;
```

### 3.3 Outcome colors

- YES/positive uses success color, check icon, and localized label.
- NO/negative uses danger color, cross icon, and localized label.
- Multi-option polls use a color-blind-safe categorical palette plus letters/numbers and labels.
- Color alone never communicates outcome, status, trend, or validation.

### 3.4 Typography

Self-host WOFF2 files; do not fetch fonts at runtime.

| Context | Family | Weights |
|---|---|---|
| Persian UI | Vazirmatn | 400, 500, 600, 700 |
| English UI | Inter | 400, 500, 600, 700 |
| Hashes, addresses, code, numerals in explorer | JetBrains Mono | 400, 500, 600 |

Scale:

| Token | Mobile | Desktop | Line height | Use |
|---|---:|---:|---:|---|
| `display` | 36 | 52 | 1.15 | Landing hero only |
| `h1` | 30 | 40 | 1.2 | Page title |
| `h2` | 24 | 30 | 1.3 | Major section |
| `h3` | 20 | 22 | 1.35 | Card/section title |
| `body-lg` | 18 | 18 | 1.7 Persian / 1.6 English | Lead copy |
| `body` | 16 | 16 | 1.7 Persian / 1.55 English | Default |
| `small` | 14 | 14 | 1.6 | Supporting text |
| `caption` | 12 | 12 | 1.5 | Metadata; never essential legal copy |
| `mono` | 13 | 14 | 1.55 | Hashes and code |

### 3.5 Spacing, radii, and elevation

- Base spacing unit: 4px.
- Allowed spacing: 4, 8, 12, 16, 24, 32, 48, 64, 96.
- Page gutters: 16px at 375, 24px at 768, 32px at 1024, 48px at 1440.
- Content max widths: 720px forms/readable text, 1200px civic/discovery, 1440px trading/explorer.
- Radii: 6px control, 10px card, 14px modal, pill only for statuses/tags.
- Light elevation: border plus subtle shadow. Dark elevation: border and surface shift, not heavy glow.

## 4. Direction, localization, and data formatting

- Route locale is authoritative: `/fa/...` sets `lang="fa" dir="rtl"`; `/en/...` sets `lang="en" dir="ltr"`.
- Mirror navigation, breadcrumb arrows, drawers, form alignment, table edge actions, pagination, and directional icons.
- Do not mirror media controls, charts’ time direction, mathematical notation, hashes, addresses, code, or candlesticks.
- Isolate hashes/addresses with `dir="ltr"` and `unicode-bidi: isolate` inside Persian layouts.
- Persian interface dates use Jalali calendar plus explicit Tehran time when relevant.
- Binding opening/closing/resolution rules always show UTC beneath the localized date.
- English dates use Gregorian calendar.
- Financial digits and chain identifiers use Latin digits in both locales. Persian prose may use Persian digits for non-technical counts.
- Translate product copy, statuses, errors, emails, metadata, dialogs, validation, and empty states. Do not leave mixed-language placeholder text.
- User-generated bilingual fields display the active locale first and provide a labeled fallback when missing; publication validation requires both languages.

## 5. Responsive layout

### 375px

- Single column.
- Bottom navigation: Discover, Portfolio, Create, Activity, Menu.
- Primary action may use a sticky bottom bar with safe-area padding.
- Tables become labeled key/value cards unless horizontal scrolling is essential for order books.
- Trading workspace order: outcome header, chart, order ticket, positions, compact order book, trades/rules.

### 768px

- Two-column cards where meaningful.
- Header navigation replaces bottom navigation on landscape/tablet.
- Poll detail uses 7/5 content/sidebar split when space permits.

### 1024px

- Persistent desktop header.
- Trading/explorer side navigation becomes available.
- Dense tables and multi-panel analytics render without card conversion.

### 1440px

- Maximum data workspace width is 1440px.
- CLOB uses chart/order book/order ticket in a 6/4/3-style grid.
- Explorer detail pages use main content plus sticky summary rail.

No fixed element may cover content. All pointer targets are at least 44×44px.

## 6. Motion and interaction

- Default transition: 180ms ease-out for color, opacity, border, and shadow.
- Dialog/drawer: 220ms; no decorative motion over 300ms.
- Avoid layout-shifting hover transforms.
- `prefers-reduced-motion` removes nonessential animation and replaces progress animation with static status text.
- Proof creation shows deterministic stages rather than an indeterminate spinner alone.
- Every async action disables duplicate submission and keeps a visible cancel action where cancellation is safe.
- Destructive and irreversible actions require a summary dialog; token amounts and poll rules are repeated in that dialog.

## 7. Core component specifications

### Navigation

- Product mark, network badge, primary sections, locale switch, theme control, and wallet/account state.
- Network badge always shows `Experimental testnet` / `شبکه آزمایشی`.
- Active route uses text weight, indicator, and `aria-current`; never color alone.
- Mobile drawer traps focus and returns focus to its trigger.

### Buttons

Variants: primary, secondary, outline, ghost, destructive, link.

States: default, hover, pressed, focus-visible, loading, disabled. Loading preserves width and includes localized status text. Disabled buttons expose the reason near the control.

### Market card

Displays kind, privacy badge, bilingual question, status, close time, participation/volume, outcome signal, resolution source class, and risk/testnet badge. Never imply probability for civic polls.

### Poll options

- Civic: radio/checkbox/allocation controls with remaining-credit counter.
- Pool: option, stake, estimated weight, creator-share warning, and no guaranteed principal warning.
- CLOB: YES/NO price, spread, depth, limit/market controls, available shielded balance.

### Charts

- Text summary precedes every chart.
- Accessible table view is always available.
- Time axes remain chronological left-to-right in both locales.
- Tooltips are keyboard accessible and never the only source of exact values.

### Order book

- Bids and asks have text headers, price, size, total, and depth visualization.
- Aggregate public depth is labeled; do not imply orders are hidden from the matcher.
- Private CLOB orders use a circuit-native Poseidon2 authorization digest; the UI must not describe this secp256k1 authorization as post-quantum. Public direct-contract orders use the separate EIP-712 path.
- Private settlement currently proves batches of one or two non-repeating matches; this implementation limit is operational and must not be presented as market capacity or throughput.
- Price tick, minimum size, matching priority, and stale-data time are visible.

### Wallet and shielded note panels

- Separate public extension address from private local account.
- Show asset, available/locked/pending balance, note age/anonymity-delay state, and recovery status.
- Never render a private key, holder secret, complete note secret, or credential secret.

### Privacy badges

Four explicit variants:

- `Anonymous reveal`: identity hidden; choice public after close.
- `Shielded position`: public observers cannot see position; protocol limitations apply.
- `Matcher-visible order`: matcher sees price and size.
- `Public wallet action`: wallet and transaction are public.

Each badge opens the complete leakage description.

### Proof progress

Stages: preparing witness, generating proof, verifying locally, waiting for relay, submitted, confirmed. Failures preserve safe retry data without logging secrets.

### Tables and code viewers

- Sticky header only when it does not obscure anchor targets.
- Sort state is announced.
- Hashes are monospace, LTR, middle-truncated visually, full value available through labeled copy.
- Code viewer has line numbers, language, copy, wrap toggle, and accessible plain-text mode.

### Status and transaction feedback

Every state uses icon, label, and color. Pending transactions show hash when available, current confirmations/finality, replacement status, and safe navigation. Never display success before final required confirmation.

## 8. Shared application states

| State | Required behavior |
|---|---|
| Loading | Skeleton matches final geometry; no fake values. |
| Empty | Explain why empty and provide one valid next action. |
| Stale | Keep last confirmed data, show timestamp and refresh action. |
| Network error | Preserve safe user input and distinguish RPC, API, and offline failures. |
| Proof generation | Show stages, device-performance warning, cancel/retry rules. |
| Transaction pending | Show transaction lifecycle and do not duplicate submission. |
| Failed proof | Give non-secret error code, likely cause, retry, and support export with secrets stripped. |
| Refund | Show reason, refundable amount, destination type, eligibility time, and claim state. |
| Paused | Explain whether reading, canceling, withdrawing, or refunding remains possible. |
| Reorg | Mark data provisional, roll projections back, and explain the replaced block/transaction. |

## 9. Raygir page templates

### Landing and discovery

- Header with product/network status.
- Hero: tagline, truthful testnet disclosure, Explore polls, How privacy works.
- Live network/market status using real data or an unavailable state.
- Filter tabs: All, Civic, Prediction pools, Exchange markets, Government research.
- Search and filters for status, close time, category, eligibility, and privacy profile.
- Educational comparison of the three product modes.
- Security/legal limitation section and open-source links.

### Civic poll detail/results

- Question, authority/creator, eligibility, rule snapshot, timeline, and privacy badge.
- Eligibility proof CTA before ballot controls.
- Credit allocation, remaining credits, commit confirmation, reveal reminder, and receipt.
- Results show aggregate counts and anonymous revealed ballots only after close.
- Government variant displays official manifest signature state and one-replacement limit.

### PredictionPool detail/claims

- Pot composition, option stakes, close/resolution timeline, evidence rules, and creator identity class.
- Mandatory warning: creator receives 10% of entire pot and winners may receive less than principal.
- Stake ticket shows RAY balance, commitment-time multiplier, estimated weight—not promised payout.
- Resolution proposal, challenge window, committee signatures, final result, and claim/refund state.

### CLOB trading workspace

- Event header, outcome prices, resolution rules, and matcher-visible privacy disclosure.
- Price/volume chart, aggregate order book, recent trades, order ticket, open orders, private positions, and collateral controls.
- Split/merge/redeem actions explain full collateralization.
- Cancellation/replacement behavior and matching priority are visible.

### Poll creation and LLM review

Steps: type → bilingual wording/options → eligibility → timing → evidence/resolution → economics/privacy → review/fee → submitted decision.

- Autosave drafts locally and in the creator’s pseudonymous account only.
- Preview exact immutable manifest.
- Show LLM reason codes, citations, confidence, prompt/model identifiers, and refund calculation.
- Government ballots cannot be created here; link to authority-manifest documentation.

### Eligibility/passkey onboarding

Phase 4 implementation constraint: the anonymous voter wallet is browser-local and must never reuse the Fortify operator identity, passkeys, session, or user table. Initial research uses WebAuthn PRF output only when the authenticator actually returns it; unsupported authenticators stop with a truthful compatibility state and never fall back to a server-held or silently weaker key. Until the real smart-account, ML-DSA, and shielded-note contracts pass Phase 3, screens must label generated material as a local research vault and must not display a deployable wallet address or claim on-chain privacy.

- Explain two-site boundaries before beginning.
- Create passkey-protected local identity.
- Generate blinded commitment locally.
- Redirect/open issuer origin with unmistakable domain context.
- Return credential without identity callback.
- Verify locally and offer encrypted recovery export.

### Funding, portfolio, and recovery

- Clearly separate public deposit wallet from private balances.
- Deposit flow explains public linkage boundary, batching, delay, paymaster, and relayer.
- Portfolio groups civic receipts, pool positions, exchange positions/orders, claimable/refundable assets.
- Recovery export requires passkey confirmation and warns that Raygir cannot restore a lost secret.

### Reports, evidence, challenges, refunds

- Report reasons, anonymous report-nullifier disclosure, threshold progress without reporter identities.
- Evidence items contain source, retrieval time, content hash, relevance, and correction history.
- Challenge shows bond, deadline, committee state, and refund consequences.
- Refund page supports batch claim and per-market audit trail.

### Admin operations

- Fortify/passkey/2FA-protected only.
- Separate dashboards for LLM decisions, paused polls, creator sanctions, resolver proposals, issuer roots, paymaster quotas, relayer health, PostgreSQL projection lag, and RPC health.
- Every privileged action shows immutable/fixed-role limitations and writes an audit event.

## 10. Eligibility-demo templates

### Authority site

- Fictional-service banner prevents confusion with a real government service.
- Demo identity login, eligibility policy, blinded request fingerprint, explicit fields the authority cannot see, issue/reject action, and audit history.
- Never show Raygir wallet, poll, nullifier, ballot, or later participation.

### Raygir co-sign site

- Authority DID/signature status, blinded commitment, policy, expiry, co-sign result, and fields Raygir cannot see.
- Never request civil identity.

### Boundary demonstration

A side-by-side educational page uses two visibly different origins and identifiers. It shows:

```text
Authority knows: demo identity + blinded request
Raygir knows: valid authority signature + blinded request
Chain knows: valid proof + poll-scoped nullifier
No party receives: identity ↔ wallet ↔ choice mapping
```

## 11. Sepehrbin templates

### Dashboard

Network status, era (PoW/PoS), finalized/head blocks, transactions, gas, peers, validator participation, index lag, Merge timeline, and latest blocks/transactions.

### Blocks

List and detail views for number/hash, timestamp, miner or proposer, difficulty/total difficulty, gas, size, transaction count, rewards, roots, withdrawals, finality, uncles where applicable, and reorg status.

### Transactions

Status, block/finality, from/to, value, fee, gas, nonce, input, logs, traces/internal calls, token movements, state changes when supported, and replacement/reorg state.

### Addresses and portfolio

Native/token balances, transactions, transfers, NFTs, contract status, labels/public notes, holdings, and export. Never infer identity from Raygir privacy artifacts.

### Tokens and NFTs

Metadata, supply, holders, transfers, contracts, verification, inventory, and warnings for restricted-transfer RAY and non-redeemable SPTM.

### Contracts

Verification form, compiler/settings, source tree, bytecode match, constructor arguments, proxy/implementation, ABI, read, write, simulation, and event logs. Wallet actions display public-linkage warnings.

### Validators and Merge

PoW miner contributions before TTD; terminal block proof; first PoS child; finality/participation; validator details; deposits/exits/slashing; client/version health without exposing private management endpoints.

### Analytics

Transactions, active addresses, contracts, gas, tokens, blocks, finality, validator participation, reorgs, index lag, and privacy-protocol aggregate counts. Every chart includes range, source, last update, and table alternative.

### APIs and developer tools

Native `/api/v1` documentation, Etherscan-compatible subset, API keys, rate limits, examples, schema errors, WebSocket status, verified ABI download, and chain configuration.

### Alerts/settings

Address/contract/validator/network alerts, locale/theme, notification channels, API keys, saved labels, and privacy warning that watching an address creates an off-chain association.

## 12. Accessibility and content acceptance

- WCAG 2.2 AA minimum; target AAA for core civic text where feasible.
- Skip link, landmarks, logical headings, visible focus, keyboard dialogs/menus/tables, status announcements, and error summaries.
- Body text is at least 16px. Legal/privacy copy cannot use low-contrast caption styling.
- Form labels remain visible; placeholders never replace labels.
- Validation identifies the field, problem, and correction.
- Charts, proofs, cryptographic statuses, and transaction states have text equivalents.
- Screen-reader order matches visual order in both RTL and LTR.
- Verify at 200% zoom and with reduced motion.

## 13. Security and privacy UI rules

- Never place secrets in query strings, analytics, server-rendered props, error telemetry, clipboard by default, or downloadable support bundles.
- Mask sensitive values and require intentional reveal with passkey reconfirmation where appropriate.
- Use separate origins and visual chrome for issuer and Raygir.
- Always show the current chain ID and contract address before signing.
- Detect wrong network, stale manifest, expired proof, replayed nullifier, and mismatched contract version before wallet submission.
- External links show destination domain and use safe new-window attributes.
- Sanitized user content only; evidence pages render fetched material as inert text.

## 14. Implementation acceptance checklist

- [ ] All public routes exist in `/fa` and `/en`.
- [ ] Every page sets correct `lang` and `dir`.
- [ ] No mixed-language starter copy remains.
- [ ] Local fonts load without an external request.
- [ ] Light and dark semantic tokens pass contrast checks.
- [ ] All controls work by keyboard and have visible focus.
- [ ] All states in Section 8 are implemented where applicable.
- [ ] Privacy claims match the table in Section 4.
- [ ] RAY and SPTM limitations appear before acquisition/use.
- [ ] Pool creator-share warning appears before commitment.
- [ ] CLOB matcher visibility appears before order submission.
- [ ] Government mode is visibly experimental and non-coercion-resistant.
- [ ] No fabricated fallback data appears.
- [ ] Layout is verified at 375, 768, 1024, and 1440px.
- [ ] Reduced-motion and 200% zoom remain usable.
- [ ] Persian screenshots are reviewed for complete RTL mirroring.
