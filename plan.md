# Sepehr, Raygir, and Sepehrbin Implementation Plan

## Document control

- Current state: `LOCAL_IMPLEMENTATION_COMPLETE_THROUGH_PHASE_9`
- Approved plan recorded: 2026-08-11
- Active phase: none; Phase 10 remains `PRODUCTION_TEST`
- Blocked dependency: none
- Status vocabulary: `PENDING`, `IN_PROGRESS`, `PRODUCTION_TEST`, `BLOCKED`, `COMPLETED`
- Only one phase may be `IN_PROGRESS` at a time.
- `PRODUCTION_TEST` means implementation may continue locally, but the remaining gate requires real infrastructure, a public deployment, independent operators, an external audit, legal approval, or certification. It is not an assumed pass and does not authorize a production-readiness claim.
- A phase may be marked `COMPLETED` only after every listed gate passes.
- Each completion entry must record the date, commit when Git exists, commands run, test results, artifact hashes, and remaining non-blocking limitations.
- A failed mandatory gate must be marked `BLOCKED` with its evidence. It must never be relabeled as complete.
- Any requirement change must update this file, affected tests, privacy disclosures, and `design.md` before implementation continues.

> Continuation received on 2026-08-21. Work proceeds phase-by-phase until completion or a mandatory blocked gate.

> On 2026-08-22, after reviewing the Phase 2 blocked result, the user explicitly instructed work to proceed to later phases. This override permits isolated application, contract, and circuit research only. Phase 2 remains `BLOCKED`; no Sepehr deployment, public testnet, production-readiness claim, or chain-dependent phase gate may pass until the consensus blocker is resolved.

> On 2026-08-22, the user explicitly instructed work to move to Phase 4 before Phase 3 passed its gate. Phase 3 progress is preserved but paused as `PENDING`. Phase 4 may proceed only as isolated browser/application research against mocked protocol boundaries; it cannot pass its phase gate until the required Phase 3 contracts, real ML-DSA verifier, and circuits are complete.

> On 2026-08-22, the user instructed that all remaining gates be fixed so Phases 2–4 can be completed. Work returned to the mandatory Phase 2 dependency first. Phase 4 progress is preserved and paused as `PENDING` while Phase 2 is `IN_PROGRESS`; a failed repeated feasibility gate returns Phase 2 to `BLOCKED` with evidence.

> On 2026-08-23, Phase 2 passed its three clean transition/recovery repetitions, explicit replay and post-TTD rejection checks, and a 2/2 partition safe-halt/healing matrix. Phase 2 is `COMPLETED`; Phase 3 resumes as the only `IN_PROGRESS` phase.

> On 2026-08-30, the user instructed local implementation to continue while deployment-only gates are deferred. Phases 10–12 use `PRODUCTION_TEST`; this records that their real VPS, public-deployment, independent-audit, legal, and certification evidence is pending rather than assumed successful. Phases 0–9 retain normal implementation gates.

> On 2026-08-31, the user replaced the monorepo Git boundary with three independent repositories: Raygir at the workspace root, Sepehr Chain under `/sepehr-chain`, and Sepehrbin under `/sepehrbin`. Raygir continues to own `/contracts`, `/circuits`, `/issuer-demo`, and `/packages/protocol` because they implement the Raygir application protocol rather than the execution/consensus client. The repositories share one development workspace but have independent history, remotes, releases, secrets, and deployment credentials.

> On 2026-08-31, the user required Sepehr execution and consensus nodes to discover and connect over ordinary public P2P networking rather than a WireGuard dependency. Phase 10 therefore uses signed bootnode records plus discovery/static fallback peers, public P2P ports, and loopback-only Engine/validator administration. A canonical persistent Sepehr Testnet configuration must behave like the future main network while all assets remain explicitly valueless; an offline-generated faucet account is pre-funded by public address at genesis, and its private key must never enter Git. A constrained 2-vCPU/4-GB/30-GB profile may be tested but is not accepted for archive/RPC service or production readiness without measured soak evidence.

> On 2026-08-31, community deployment was required to use one guarded entry script with separate `create`, `join`, `doctor`, `start`, `stop`, and `status` operations. Network creation must produce a checksummed public bundle without validator or faucet secrets. Joining must consume an existing immutable bundle, never regenerate genesis, and install only the selected full-node or validator role. The three repository READMEs must provide bilingual step-by-step community instructions. A comprehensive Persian RTL university report is generated under a Git-ignored local output directory and is not part of any source repository.

> On 2026-08-31, the persistent testnet faucet allocation changed from one 1,000,000,000-SEP account to four independent node-operated faucet accounts. The canonical genesis pre-funds each public faucet address with 1,000,000 valueless test SEP, and the default grant is 200 SEP per accepted wallet request. Faucet operators do not mint independently; all supply is defined once in the shared genesis, and private keys remain host-specific secrets outside Git and the public bundle.

## Phase status

| Phase | Name | Status | Depends on |
|---|---|---|---|
| 0 | Design specification and baseline | `COMPLETED` | User continuation instruction received 2026-08-21 |
| 1 | Laravel/PostgreSQL and bilingual foundation | `COMPLETED` | Phase 0 completed 2026-08-21 |
| 2 | Local Sepehr PoW→PoS feasibility gate | `COMPLETED` | Phase 1 completed; gate passed 2026-08-23 |
| 3 | Immutable contracts, assets, and circuit foundation | `COMPLETED` | Phase 2 completed 2026-08-23 |
| 4 | Passkey wallet, shielded funding, and eligibility demo | `COMPLETED` | Completed 2026-08-31 |
| 5 | CivicPoll and governmental research profile | `COMPLETED` | Completed 2026-08-30 |
| 6 | PredictionPool, moderation, and oracle | `COMPLETED` | Phase 5 completed 2026-08-30 |
| 7 | Continuous CLOB | `COMPLETED` | Phase 6 completed 2026-08-31 |
| 8 | Complete Raygir UI | `COMPLETED` | Completed 2026-08-31 |
| 9 | Sepehrbin from-scratch explorer | `COMPLETED` | Completed 2026-08-31 |
| 10 | Four-VPS experimental testnet | `PRODUCTION_TEST` | Phases 2–9; execute on the four real VPS hosts |
| 11 | First public research beta and open-source release | `PRODUCTION_TEST` | Phase 10; execute against the public research deployment |
| 12 | Mainnet and governmental readiness gates | `PRODUCTION_TEST` | Phase 11 plus independent operators, approvals, audits, and certification |

## 1. Goal and workspace structure

Build a workspace containing:

```text
/                         Existing Laravel 13 + Inertia React app: Raygir
/contracts                Foundry/Solidity contracts
/circuits                 Circom/Groth16 circuits and proving clients
/sepehr-chain             Nethermind patch set, Prysm config, genesis tooling
/sepehrbin                 Separate Laravel/Inertia explorer and indexer
/issuer-demo               Separate Laravel/Inertia eligibility-authority demo
/infra/testnet             Four-VPS deployment and recovery configuration
/packages/protocol         ABIs, generated types, OpenAPI schemas
```

The existing Laravel application stays at the workspace root.

Git boundaries:

- Raygir repository: `/`, excluding `/sepehr-chain` and `/sepehrbin`.
- Sepehr Chain repository: `/sepehr-chain`.
- Sepehrbin repository: `/sepehrbin`.

The root `.gitmodules` remains owned by Raygir because the Foundry dependencies live under `/contracts/lib`. Sepehr Chain upstream client checkouts, generated node data, artifacts, validator wallets, JWT secrets, and evidence are not vendored into Raygir or Sepehrbin.

Locked product decisions:

- Raygir supports:
  - `CivicPoll`: eligibility-based voting without purchased voting power.
  - `PredictionPool`: pari-mutuel RAY stakes and weighted payouts.
  - `ExchangeMarket`: fully collateralized outcome positions and a continuous CLOB.
- The first public beta is incomplete until both prediction modes and the broad custom Sepehrbin explorer exist.
- PostgreSQL is the only durable off-chain application datastore.
- Blockchain clients retain their required native databases.
- Persian is the default locale under `/fa`; English uses `/en`.
- Persian pages are RTL; English pages are LTR.
- Raygir, Sepehrbin, and related application services use AGPL-3.0 subject to dependency compatibility.
- The Nethermind fork retains its LGPL obligations.
- Testnet assets have no monetary value, fiat redemption, or legal claim.
- Sepehr is cryptographically agile. New application and operational signatures use hybrid classical plus post-quantum verification where deployable; no surface may claim the Phase 2 Ethereum-compatible consensus is fully post-quantum.

### Post-quantum boundary

- “Post-quantum encryption” is not used as a catch-all term. ML-DSA and SLH-DSA are signature algorithms; ML-KEM is for key establishment; hashes are sized and domain-separated for quantum security margins.
- The Phase 2 PoW→PoS continuity experiment remains EIP-3675 compatible and therefore retains secp256k1 transaction signatures, BLS validator signatures, Keccak-256 consensus hashing, and Groth16 where specified. These are not collectively post-quantum secure.
- Phase 3 adds a versioned algorithm registry and domain separation. New off-chain manifests, releases, backups, issuer roots, resolver statements, and administrative approvals use hybrid classical + ML-DSA-65 signatures. Offline recovery/root artifacts additionally support SLH-DSA as an algorithm-independent fallback.
- ERC-4337 Raygir smart accounts support hybrid passkey/secp256k1 plus ML-DSA authorization. EOAs remain classical and must be labeled accordingly. On-chain ML-DSA verification starts as a benchmarked verifier contract; a consensus precompile or PQ transaction type requires a separately versioned, audited fork.
- New non-consensus artifact digests use SHA3-384 with explicit domain tags. EVM-visible identifiers retain Keccak-256 for compatibility and carry a paired SHA3-384 digest where long-lived integrity matters. Existing Ethereum block, transaction, address, and trie hashing is not renamed or represented as post-quantum.
- Public X.509/TLS remains compatible with deployed clients. Internal services may trial composite ML-DSA certificates behind crypto-agility flags, but the current IETF composite ML-DSA certificate specification is still an Internet-Draft and cannot be a mandatory public dependency.
- A future “PQ-ready” claim requires inventory and migration tests. A “post-quantum secure blockchain” claim additionally requires replacement of validator BLS, transaction authentication, vulnerable ZK proof systems, and all operational signing paths, followed by independent cryptographic and consensus audits.

Primary post-quantum references:

- https://csrc.nist.gov/pubs/fips/204/final
- https://csrc.nist.gov/pubs/fips/205/final
- https://datatracker.ietf.org/doc/draft-ietf-lamps-pq-composite-sigs/

## 2. Consensus boundary

Current maintained Geth cannot seal a new Ethash chain. The research baseline is therefore:

- Nethermind `1.39.2` execution client with a narrow Ethash-production patch.
- Prysm `7.1.8` consensus and validator client.
- An EIP-3675 terminal-total-difficulty transition preserving one chain, state, balances, receipts, and history.
- Four hosts, each mining before the transition and validating afterward.
- 256 validator keys divided into four non-overlapping groups of 64.

Mandatory rules:

- The implementation must not substitute obsolete Geth or another unsupported Internet-facing client.
- The local transition must pass before any VPS deployment.
- Any failed transition, state-continuity, partition, replay, compatibility, or audit gate marks Phase 2 `BLOCKED`.
- Because PoW is mandatory and no PoS-genesis fallback was accepted, a blocked Phase 2 blocks later chain phases.
- Four co-hosting VPSs are an experimental testnet topology, not decentralization.
- A future mainnet repeats PoW→PoS, but Raygir assets remain test-value-only during PoW.
- No bridge, fiat redemption, or real-value market activates until audited PoS finality.

Primary references:

- https://geth.ethereum.org/docs/fundamentals/private-network
- https://eips.ethereum.org/EIPS/eip-3675
- https://github.com/NethermindEth/nethermind/releases/tag/1.39.2
- https://github.com/OffchainLabs/prysm/releases/tag/v7.1.8

## 3. Asset model

| Asset | Rules |
|---|---|
| `SEP` | 18-decimal native gas, mining, staking, and governance asset. Protocol gas remains non-zero. |
| `RAY` | 18-decimal Raygir utility credit. Fixed testnet supply of 100,000,000. User-to-user transfers revert; approved swaps and protocol contracts remain allowed. |
| `Sepehr Toman (SPTM)` | 6-decimal transferable test token. One whole SPTM displays as 1,000 Toman. It is non-redeemable and uses a signed mock SEP/Toman oracle. |
| Civic credits | Poll-scoped, non-transferable, non-purchasable credits created from eligibility proofs. |
| Outcome positions | Fully RAY-collateralized YES/NO positions tradable only through ExchangeMarket. |

RAY allocation:

- 80% to an immutable protocol-owned SEP/RAY constant-product pool.
- 10% to a rate-limited test faucet.
- 10% to the test treasury.
- No transferable LP token.
- No later RAY minting in immutable v1.

SPTM quote:

```text
SPTM price in SEP = 1,000 Toman / mock SEP price in Toman
```

When SEP’s mock Toman quote increases, fewer SEP purchase one SPTM. SPTM balances never rebase. A real stable asset is out of scope until reserves, par redemption, legal rights, audits, and regulatory approvals exist.

## 4. Privacy and account boundaries

| Mode | Privacy guarantee |
|---|---|
| CivicPoll | Identity and funding wallet are not revealed. The anonymous selected choice becomes public after close. |
| Government research profile | One replacement ballot is allowed. Anonymous individual ballots become public after close. This is not receipt-free or coercion-resistant. |
| PredictionPool | Funding and payouts use shielded notes. Anonymous choices become visible after close. |
| ExchangeMarket | Balances and positions are hidden from public chain observers, but the Raygir matcher can decrypt orders. The matcher must not receive real identity or funding-wallet information. |
| Sepehrbin direct interaction | Normal wallet-connected calls are public. Private Raygir actions remain in Raygir’s proof-and-relay flow. |

User flow:

1. Generate a local non-custodial Raygir smart account protected by a passkey.
2. Let the user export an encrypted recovery package; never store the private key in Raygir.
3. Permit a browser-extension wallet only for public funding deposits.
4. Deposit SEP or SPTM into a shared shielded pool.
5. After batching and an anonymity delay, spend the private note through a relayer.
6. Use an ERC-4337 paymaster to sponsor approved Raygir calls with quotas, expiry, gas caps, and abuse controls.
7. Keep voter routes free from Laravel identity sessions, email, stored IP address, stored user agent, and analytics identifiers.
8. Keep existing Fortify/passkey authentication exclusively for administrators and operators.

Privacy copy must state that ZK does not hide compromised devices, browser fingerprints, ISP metadata, timing, or colluding infrastructure. Never promise “no trace anywhere.”

## 5. Eligibility API and two-site demo

The demo contains Raygir and a separately deployed fictional civil-registry site with independent PostgreSQL databases, origins, DIDs, and signing keys.

Credential flow:

1. The authority authenticates a fictional demo person.
2. The holder creates a secret and blinded eligibility commitment locally.
3. The authority signs the commitment and policy.
4. Raygir verifies the authority signature and co-signs only the blinded commitment.
5. The holder proves possession of the authority signature, Raygir signature, and local secret.
6. Neither party receives a voting callback or records whether the credential was used.
7. The chain enforces use through poll-scoped nullifiers.

```text
scope = H(chainId, verifierContract, pollId, policyVersion)
nullifier = H(holderSecret, scope, creditCounter)
```

Versioned interfaces:

```text
GET  /.well-known/raygir-issuer
POST /api/v1/eligibility/challenges
POST /api/v1/credentials/blind-issue
POST /api/v1/credentials/co-sign
GET  /api/v1/eligibility-policies/{policy}
GET  /api/v1/issuer-roots/{policy}/{epoch}
GET  /api/v1/revocation-roots/{policy}/{epoch}
```

Use Semaphore v4-style membership/nullifiers plus SNARK-friendly dual signatures initially. BBS blind credentials may be prototyped but must not silently become a production dependency while the W3C specification remains a Candidate Recommendation.

## 6. Poll and market contracts

Public protocol enums:

```text
PollKind:
  CivicPoll
  PredictionPool
  ExchangeMarket
  GovernmentElection

PollState:
  Draft
  PendingReview
  Open
  Paused
  Closed
  Proposed
  Disputed
  Resolved
  Invalid
  Refunding
  Final

PrivacyProfile:
  AnonymousReveal
  GovernmentAnonymousReveal
  ShieldedPosition
  MatcherVisibleOrder
```

Every poll permanently binds:

- Bilingual question and mutually exclusive options.
- Opening, closing, reveal, challenge, and resolution times in UTC.
- Eligibility policy and credit limit.
- Allowed primary evidence sources and evidence cutoff.
- Invalid, tie, timeout, and no-winner rules.
- Market type, asset, stake bounds, creation fee, and early-boost configuration.
- Contract version, verifier version, and privacy disclosure.

Official governmental ballots require a threshold-signed election-authority manifest. LLM review may lint the manifest but cannot publish or alter it.

## 7. PredictionPool settlement

For total stake `T`:

```text
creatorReward = floor(T × 10%)
winnerPool = T - creatorReward
```

The creator receives 10% of the whole pot. Winners are therefore not guaranteed their principal. This consequence must be displayed before staking.

Early weighting:

```text
multiplier(t) =
  1 + boost × (closeTime - t) / (closeTime - openTime)
```

- Default boost: 1%.
- Per-poll range: 0%–5%.
- Weight applies per staked unit so splitting positions gives no benefit.
- Commitment time, not reveal time, sets the weight.

Winners are ordered by commitment hash. Integer payouts conserve the complete winner pool:

```text
payout_i =
  floor(winnerPool × cumulativeWeight_i / totalWeight)
  - floor(winnerPool × previousCumulativeWeight_i / totalWeight)
```

Required invariant:

```text
sum(winner payouts) + creator reward = total pot
```

Invalid, unresolved, timed-out, and no-winner markets refund all stakes and pay no creator reward. The poll-creation fee is separate from the pot.

## 8. ExchangeMarket settlement

- One RAY of collateral creates one YES and one NO position.
- A complete YES/NO pair merges back into one RAY.
- The winning outcome redeems for one RAY; the losing outcome redeems for zero.
- The off-chain matcher performs continuous price-time matching and sees plaintext order price and size.
- Signed orders settle in on-chain batches against shielded commitments.
- The public order book exposes aggregate levels, volume, spread, and trades, not identity or funding wallets.
- CLOB creators receive no share of settlements or fees.
- Testnet trading fees default to zero.
- The 10% creator reward applies only to PredictionPool.

## 9. LLM moderation, reports, and resolution

Pre-publication:

- Hold the creation fee in escrow.
- Review only public poll text and public source material through a provider-neutral LLM adapter.
- Require versioned structured JSON containing decision, reason codes, confidence, citations, model ID, and prompt hash.
- Deterministically reject malformed dates, overlapping options, missing sources, unsafe HTML, and inconsistent rules.
- Approved poll: send the complete creation fee to the treasury.
- Content rejection: refund 90% and retain a 10% review fee.
- Provider outage or internal failure: refund 100%.
- Ordinary community and prediction polls require no human pre-approval.

Post-publication:

- Permit one anonymous report per eligible credential and poll.
- Automatically pause at `max(5, ceil(1% of distinct participants))` reports.
- Stop new stakes and orders while paused.
- Never silently edit economic terms after value enters a market.
- Resume the unchanged poll or invalidate it and refund stakes.
- First non-malicious upheld violation: warning.
- Deliberate deception: 30-day creator-credential ban.
- Repeated violation within 180 days: one-year ban.
- Preserve every decision and evidence hash; never delete chain history.

Resolution:

1. AI gathers allowed evidence and proposes an outcome with bilingual rationale.
2. A fixed 3-of-5 resolver committee validates the proposal.
3. Open a 48-hour bonded challenge period.
4. Finalize an uncontested proposal.
5. Require committee review and published reasoning after a challenge.
6. If quorum is unavailable for seven days, invalidate and refund.
7. Never allow AI alone to settle funds.

## 10. Governance

Before PoS:

- Contract implementations are non-upgradeable.
- Role addresses and signer sets are fixed at deployment.
- Upgrades require new contracts and voluntary migration.
- Fixed roles cover the resolver committee, LLM signer, mock price oracle, paymaster policy, issuer roots, and emergency pause.
- Lost or compromised keys require a new protocol version.

After PoS:

- Deploy a new canonical registry and governance-controlled versions.
- Chamber one: delegated SEP holders, at least 20% turnout, simple-majority approval.
- Chamber two: active validators weighted by stake, simple-majority approval.
- Both chambers must pass.
- Wait through a 48-hour timelock.
- Governance authorizes chain upgrades but cannot install software; validators still install signed releases.

## 11. PostgreSQL boundaries

Use isolated PostgreSQL databases and credentials for:

- Raygir application data, queues, cache, admin sessions, moderation, oracle evidence, CLOB orders, and derived chain state.
- Sepehrbin indexing, APIs, search, contract verification, labels, analytics, and alerts.
- Eligibility-demo identities and issuer audit state.
- Test and proving-job coordination.

Hard rules:

- Do not use Redis, Kafka, SQLite, MongoDB, or another durable application datastore.
- Do not store a mapping between real identity and wallet, nullifier, vote, wager, or order in Raygir.
- Encrypt CLOB orders at rest even though the matcher can decrypt them while matching.
- Treat the chain as source of truth for balances, commitments, nullifiers, and settlement.
- Make PostgreSQL projections rebuildable from chain history.

## 12. `design.md` requirements

Phase 0 must create a decision-complete bilingual design specification containing:

- Civic-market hybrid visual direction.
- Deep navy/teal trust palette, saffron highlight, semantic outcome colors, light and dark themes.
- Self-hosted Vazirmatn for Persian, Inter for English, and a monospace font for hashes.
- RTL/LTR mirroring, Persian/Gregorian dates, UTC resolution display, and Latin digits for addresses.
- Responsive behavior at 375, 768, 1024, and 1440 pixels.
- WCAG AA contrast, keyboard support, focus states, reduced motion, semantic charts, and non-color status cues.
- Loading, empty, stale, network-error, proof-generation, transaction-pending, failed-proof, and refund states.
- Truthful privacy badges per product mode.
- Specifications for navigation, market cards, poll options, charts, order book, wallet panels, proof progress, disputes, tables, code viewers, and transaction status.
- Persian and English copy plus page templates for:
  - Landing and discovery.
  - Civic poll detail and results.
  - PredictionPool detail and claims.
  - CLOB trading workspace.
  - Poll creation and LLM review.
  - Eligibility and passkey onboarding.
  - Funding, shielded notes, portfolio, and recovery.
  - Reports, evidence, challenges, and refunds.
  - Admin operations.
  - Eligibility-demo flows.
  - Sepehrbin dashboard, blocks, transactions, addresses, tokens, contracts, validators, analytics, APIs, alerts, and settings.

## 13. Phase runbook

### Phase 0 — Design specification and baseline

Tasks:

- [x] Change Phase 0 to `IN_PROGRESS` only after the user says to continue.
- [x] Initialize Git without creating a remote or pushing externally.
- [x] Create `design.md` with every requirement in Section 12.
- [x] Re-run and record the Laravel/Pest, TypeScript, and ESLint baseline.
- [x] Record environment/package versions and the absence or presence of required tools.

Gate:

- [x] `plan.md` and `design.md` contain no unresolved implementation choices.
- [x] Baseline results and any environmental blockers are recorded honestly.

Completion evidence (2026-08-21):

- Git: local repository initialized on `master`; no remote configured; no commit exists yet.
- Commands: `php artisan test --compact`, `npm run types:check`, `npm run lint:check`, `npm run format:check`, version/tool probes.
- Tests: Pest 39 passed / 136 assertions; TypeScript passed; ESLint passed; Prettier passed.
- Runtime: PHP 8.5.9, Laravel 13.24.0, Inertia Laravel 3.3.1, Fortify 1.37.3, Wayfinder 0.1.21, Pest 5.1.0, Node 26.3.0, npm 11.6.2.
- Available prerequisites: Docker 28.5.1 and PostgreSQL client 18.1.
- Deferred prerequisites: Foundry, Circom, Go, and .NET SDK are not installed; they are required by later phases and are not Phase 0 blockers.
- Artifact hash: `design.md` SHA-256 `FFABFFA0E5BBDAE6594BC391E61121856CC6D92A362AFB2BF0F74D88EC121C59` before this status update.
- Limitation: Git emitted a read warning for the user-level global ignore file; repository-local operations succeeded.

### Phase 1 — Laravel/PostgreSQL and bilingual foundation

Tasks:

- [x] Rebrand the root app to Raygir.
- [x] Replace SQLite with PostgreSQL for development, testing, CI, sessions, queues, and cache.
- [x] Separate administrator authentication from anonymous voter flows.
- [x] Add `/fa` and `/en` routes, translation catalogs, RTL/LTR layouts, local fonts, and locale-aware dates/numbers.
- [x] Expand workspace configuration without moving the root Laravel app.
- [x] Use Wayfinder for frontend/backend links and forms.
- [x] Keep Fortify/passkeys for administrators and operators only.

Gate:

- [x] PostgreSQL-only tests and CI pass locally with an equivalent PostgreSQL 18 service configuration committed for CI.
- [x] Locale routing, RTL/LTR, and admin/voter separation tests pass.
- [x] Existing baseline behavior remains intact unless explicitly replaced.

Completion evidence (2026-08-21):

- Commit: `08a9beb` (`feat: establish Raygir foundation`).
- Commands: PostgreSQL 18 database creation and migrations, `php artisan wayfinder:generate --with-form --no-interaction`, `vendor/bin/pint --dirty --format agent`, `npm run lint:check`, `npm run format:check`, `npm run types:check`, `npm run build`, and `php artisan test --compact`.
- Tests: Pest 46 passed / 167 assertions against PostgreSQL; TypeScript passed; ESLint passed; Prettier passed; production Vite build passed.
- PostgreSQL: isolated UTF-8 `raygir` and `raygir_test` databases owned by the non-superuser `raygir_app` role; database-backed sessions, queues, and cache; PostgreSQL 18 CI service.
- Security: public registration disabled; authenticated non-operators receive HTTP 403 on operator surfaces; public localized routes do not require a Laravel identity.
- Artifacts: self-hosted Vazirmatn and Inter build manifest SHA-256 `877EBA60E4D502C9D70F7663914356CBF618FA7A05D4D88B36F993E5AB2F024B`.
- Limitation: locale-aware calendar conversion beyond direction/locale propagation is deferred until a page displays protocol dates; no fabricated dates are shown in Phase 1.

### Phase 2 — Local Sepehr PoW→PoS feasibility gate

Tasks:

- [x] Pin signed Nethermind and Prysm commits and create a provenance manifest.
- [x] Patch only Ethash producer wiring, continuous single-flight mining, cancellation, and TTD termination.
- [x] Use genuine Ethash nonce search with calibrated fixed difficulty.
- [x] Generate matching execution/consensus genesis artifacts and 256 validator keys.
- [x] Run four local nodes and prove each mines at least one canonical block.
- [x] Deploy a canary contract and record code, storage, balances, nonces, receipts, logs, block hashes, and state roots.
- [x] Trigger the EIP-3675 transition without state export/import.
- [x] Prove continuity, post-TTD PoW rejection, replay of both eras, and PoS finality.
- [x] Repeat from empty directories three times.

Gate:

- [x] All unit, single-node, four-node, partition, replay, compatibility, and state-continuity checks pass.
- [x] Failure changes Phase 2 to `BLOCKED`; do not continue chain deployment.

Blocked evidence (2026-08-21):

- Official refs resolved to Nethermind `1.39.2` commit `6568910591e4618dc49d54285b6213c3753d7243` and Prysm `v7.1.8` commit `51b5a75ebbadf05af22bd2601b5baf7a9e99b66d`; both commit objects contain GitHub GPG signature blocks, but signer trust verification is not yet complete.
- A project-local .NET SDK `10.0.400`, permitted by Nethermind's `global.json` roll-forward policy, compiled the patched `Nethermind.Consensus.Ethash` project with zero warnings and zero errors.
- The narrow experimental patch reinstates the existing `MinedBlockProducer` and `EthashSealer`, uses continuous block-production triggers, and leaves TTD switching to the existing Merge runner. Patch SHA-256: `610A9A1D83AFF60D6C5467B7923EB0D3E530FDE59FC2853FE8D65FC836965A93`.
- Prysm's pinned `go.mod` requires Go `1.26.5`. The official release manifest identifies `go1.26.5.windows-amd64.zip` with SHA-256 `97e6b2a833b6d89f9ff17d25419ac0a7e3b482a044e9ab18cdef834bd834fd38`, but both `https://go.dev/dl/go1.26.5.windows-amd64.zip` and its official `https://dl.google.com/go/go1.26.5.windows-amd64.zip` endpoint returned HTTP 404. The official MSI endpoint also returned HTTP 404.
- The full Nethermind solution build was stopped after generated test outputs consumed 22.8 GB; only the verified generated `src/Nethermind/artifacts` directory was removed. The focused Ethash build then passed and retained bounded output.
- Mandatory transition, continuity, four-miner, replay, finality, partition, and three-clean-run gates therefore did not run and must not be represented as passing.
- Per the locked no-fallback rule, no alternate Go version, obsolete client, PoS-genesis substitution, Phase 3 work, or public chain deployment is permitted while this blocker remains.

Resume entry (2026-08-21):

- The operator installed `go1.27.0 windows/amd64` at `C:\Go\bin\go.exe` and explicitly requested continuation.
- This is a disclosed toolchain deviation from Prysm's `go 1.26.5` directive, not a silent replacement. Phase 2 returned to `IN_PROGRESS` solely to test compatibility.
- The phase returns to `BLOCKED` if the pinned Prysm build, its relevant tests, or any transition gate fails under Go 1.27.0.

Compatibility result (2026-08-21):

- Go `1.27.0 windows/amd64` compiled both pinned Prysm command binaries from an LF-preserving checkout. This proved the earlier embedded-hex decoding errors were caused by the machine's global Git CRLF conversion and were not a source defect.
- `go test ./cmd/beacon-chain ./cmd/validator` then failed in both packages with `panic: ERR Init curve=5` from `crypto/bls/herumi.Init()`. The generated binaries fail at the same initializer before normal CLI startup.
- WSL 2 with Ubuntu is available, but it has no Go toolchain. The official `https://go.dev/dl/go1.27.0.linux-amd64.tar.gz` endpoint returned HTTP 404, so the operator's Windows-only Go installation cannot be reproduced honestly as a Linux build toolchain.
- Patching out a BLS initializer or substituting a different consensus client would cross the locked compatibility and security boundary and was not attempted.
- Phase 2 is therefore `BLOCKED`. Phases 3–12 remain pending under the mandatory no-fallback dependency rule. Resume requires the pinned Go `1.26.5` toolchain or a verifiable Go `1.27.0` Linux toolchain inside WSL/Linux, followed by successful Prysm tests and all remaining Phase 2 gates.

Compatibility resolution (2026-08-22):

- The operator installed the exact required `go1.26.5 linux/amd64` toolchain in WSL 2 Ubuntu.
- Pinned Prysm `v7.1.8` compiled under Linux; `go test ./cmd/beacon-chain ./cmd/validator` passed, and both generated binaries completed `--version` without the Windows Herumi panic.
- Artifact SHA-256: beacon `00bfb08fdb7a41618a4bb53664f5cc46d0855c34a3004faeb172956d6d358272`; validator `08c85a6271fd2bbdc4dd456bea3b4908ac13a2a009345c1810876deea7944cdf`.
- The linker emitted an upstream `static_code.o` executable-stack deprecation warning. It is recorded for hardening review and does not override the remaining security/audit gates.
- The patched Nethermind runner then built successfully with 0 warnings and 0 errors using the bounded single-worker build. Phase 2 returned to `IN_PROGRESS`; no transition gate is yet represented as passing.
- The first runtime attempt exposed an Autofac construction failure because upstream `EthashSealer` had no public constructor. The narrow patch now expresses the sealer as a DI-compatible primary constructor; its focused project rebuild passes with 0 warnings/errors and the complete patch reverse-applies cleanly. Updated patch SHA-256: `8694B997347832D4EAF97899CD0AE358FD138E369FEF1812699554D04560F70D`.
- A mainnet-preset Phase 0 SSZ genesis with 256 deterministic validators was generated successfully; SHA-256 `b718b4ef0dee9b9944ebb5ea86a07636a932e6f1bfd36267335a8d9432aeffda`. Four non-overlapping validator ranges are committed as `0–63`, `64–127`, `128–191`, and `192–255`.
- The optional Prysm JSON genesis exporter panicked on its Phase 0 multi-value slice and was removed from the generation path; the canonical SSZ output succeeded. This upstream tooling limitation remains recorded.
- Starting the corrected single execution node with localhost RPC/P2P binding requires elevated local-network permission. The launch was not rerun after the environment rejected elevation because the Codex execution allowance was exhausted; this is an environment pause, not a passed or failed chain gate.

Single-node Ethash result (2026-08-22):

- After execution permission resumed, the custom node started with chain ID `7331`, TTD `2097152`, TTD-not-reached state, isolated public RPC `18545`, JWT-protected Engine RPC `18551`, and P2P bound to localhost.
- The first genuine Ethash block became canonical at height `1` after approximately 96 seconds. Hash: `0x3a70ece4a5d225d5ecb8ad239005247b84d4468dd1622e15d0b7bb7a25465a51`; miner: `0x7e5f4552091a69125d5dfcb7b8c2659029395bdf`; nonce: `0xae0c94f55ff58bff`; mix hash: `0x3f3cea3add1a578669e5a7c6f14d1879505820fd51a786f31dcc1e8d5eee99b4`; state root: `0xbd1d3398139ed37a1f316fcd7e3917f628545cabf8fedfdc612dccc76b8f4ff3`.
- Difficulty was `0x20000`; total difficulty advanced from genesis `0x20000` to `0x40000`. The non-zero seal and canonical total-difficulty progression prove this was not a fake or instant developer seal.
- The 96-second block time is too slow for the mandatory four-node and three-clean-run matrix on this host. Fixed difficulty must be recalibrated downward while retaining genuine Ethash validation before the remaining gates run.
- The reproducible harness difficulty is calibrated to `0x2000` with TTD `0x42000` (270336), preserving real Ethash while targeting roughly 32 pre-transition blocks so every miner can be observed.
- Pinned Prysm’s deterministic key generator produced four disjoint 64-key containers matching genesis indices `0–255`. The supported account importer created four permission-safe WSL wallets; all 256 validator keys imported successfully. Generated keys and wallets remain outside Git.
- The calibrated 256-validator SSZ genesis was regenerated successfully with SHA-256 `6bfaef230b8aad2d25ffd7eecbcecbcb1324a2968ccd6c3ead3a83d5d5f1b94f`.

Four-node transition result and blocking evidence (2026-08-22):

- The first corrected clean execution/consensus run passed the core transition path. All four execution nodes mined at least one canonical Ethash block. Terminal block `32` had hash `0xbfd36b4eee80b5552d44fe0f84bcc859b0887d21fbb2a9564fcc4f13db6b4071`, difficulty `0x2000`, and total difficulty `0x42000`. Its first canonical PoS child was block `33`, hash `0x3fbbb33a4b6789c82e259e7b3aae1f8b31e16884779721ba907ad7eacb9d74fb`, with zero difficulty and the terminal block as parent. All four beacons later converged and finalized epoch `22`.
- The deterministic canary retained runtime code `0x60005460005260206000f3` and storage value `42` across that transition. Execution restart preserved the chain, contract state, and finality progression.
- Prysm initially could not discover the terminal block because Nethermind omitted `totalDifficulty` from pre-Merge RPC blocks whenever Merge was configured. The narrow patch now returns the loaded block total difficulty and includes a focused regression test. `Nethermind.Facade.Test` passed for `BlockForRpcTests`; patched Linux binary SHA-256 is `c6769a8421640c1dbbb3cbaf311dfeafdea1153d209d9d5bdbab2a645b30ddba`; combined patch SHA-256 is `36bc7f85f498cb74a4a474d3972138fc45f3577fb45bbf6651b5aadb117e5e07`.
- The second clean execution run again reached exact TTD with all four miners represented. Terminal block `32` had hash `0x85f59a58641f16f5af6cb0913bf475cd8d52ff01a663e7d75016810d93d3bae8`, parent total difficulty `0x40000`, total difficulty `0x42000`, difficulty `0x2000`, and a non-zero Ethash seal.
- Recovery remediation demonstrated that all four patched miners can contribute canonical blocks, but a subsequent clean run had only two winners by block `6`. The clean-run harness therefore uses TTD `0x22000` (139,264), permitting sixteen post-genesis PoW blocks at genuine difficulty `0x2000`, and explicitly rejects a run unless all four distinct miners are canonical before transition.
- During the required outage/replay exercise, all four Prysm nodes were paused long enough to become equally stale. Normal initial sync remained at `suitable=0` despite three connected peers. `--min-sync-peers=0 --sync-from=head` replayed the stored Bellatrix state but did not restore validator readiness. Those databases were preserved under `outage-stale-*` names rather than discarded.
- A fresh consensus genesis was then deliberately attempted against the unchanged terminal execution state to test recovery without exporting/importing execution state. Prysm validated the terminal block and proposed Bellatrix payload hashes `0x71af3043af69e6711ec5acdc8088748b3c8a865ca629df504bcac48dbeada455` and `0x31e4b2171d17a0c5dc3194e4d49c5ea47daa4fd477ef315b8b6d807b208f9710`, but Nethermind returned `SYNCING`, reported those fork-choice heads as unknown, and kept canonical execution height at terminal block `32`.
- Therefore the mandatory outage/replay and three-clean-run gates did not pass. Under the locked no-fallback rule, Phase 2 is `BLOCKED`. The user subsequently authorized isolated research work beginning with Phase 3, but no chain-dependent deployment or readiness gate may pass while Phase 2 remains blocked. No obsolete client, PoS-genesis substitution, state export/import, weakened TTD, or fabricated success evidence is permitted.

Completion entry (2026-08-23):

- Status: `COMPLETED`. Repository base commit at verification time: `00a8588b1446`; the completion changes were not committed automatically.
- Three independent empty-directory runs (`clean-1`, `clean-2`, and `clean-3`) passed genuine four-miner Ethash production, exact TTD transition, canonical PoS continuity, canary code/storage/receipt preservation, non-genesis finality, a 120-second full-client outage, post-TTD mining suppression, equal-head replay, and renewed finality.
- `python sepehr-chain/scripts/phase2/verify-replay-evidence.py <run>` passed for all three clean runs and the partition matrix, comparing 49–61 persisted PoW/PoS blocks plus unchanged canary state and receipts after full restart.
- The explicit 2/2 matrix split validators and peers into `[1,2]` and `[3,4]`, 128 validators per half. From observation slots `92/91` through `161/161`, both halves retained finalized checkpoint `8:0x6d15e849434a962abba611f51b2b0c6353f32ba2a227b27ce2b03dccf4ed484a` while their unfinalized heads diverged. After healing, all four nodes converged and finalized epoch `24` at root `0xb1e3d0160403e813e14b58e34e72ca3c3f4bd57d9b0065b9f0193c71bde2673b`.
- Focused Nethermind verification passed with .NET SDK `10.0.400`: 2 payload cache/import recovery cases and 1 explicit post-TTD PoW-header rejection case; focused build completed with 0 warnings and 0 errors.
- Focused Prysm verification passed with pinned Go `1.26.5`: `go test ./beacon-chain/p2p/peers ./validator/client/beacon-api -count=1`. The upstream `static_code.o` executable-stack deprecation warning remains disclosed.
- Both patch files pass forward application against clean pinned commits and reverse application against the patched sources. Nethermind patch SHA-256: `700e0251860a9f3eed500731ddabb3bcd6d0a557ad26d430e574348fd75f72f7`. Prysm patch SHA-256: `a0d3e1e261921c8f8932d5b1447c561d26f5e8124748aa5e946fd41cdf21fdf9`.
- Client artifact SHA-256 values: Nethermind `c6769a8421640c1dbbb3cbaf311dfeafdea1153d209d9d5bdbab2a645b30ddba`; recovery beacon `d292db5644d7340c8996f6b367953c07ec55a40249baa1bbbbe594bc9b4934a`; recovery validator `595aa0034e8da9326390aa0a88e62ba0a3bc7e170a7b4896b7f19ea6c95a2001`; partition genesis SSZ `cde48a3552c852e3ad850912968f8a233cc2b876835dd17633bb32202f77a458`.
- Evidence SHA-256 values: clean-1 pre/post `f7444505b4ea019082190c6cad991a0bb4d44db6d9d157e0da7750873486f11d` / `fe8b62e19575f34a82acf43f9e367b2fd8d22665db8b0452d3fae103a12f082d`; clean-2 `436501f8840036b8dfcc1c701a338f7f6cfa0cc56fefb8b0f75738cb1124d45` / `8aa88e17cc931fd431fe69983a1d5f9c7ba2768156662a61fb9a9389fd851521`; clean-3 `f2f100015e9a3eca5a4dcd859c2f7369934cb488a81e11774e31a216328fd7bb` / `a840f82bafd8cb88a331a7dff29b1b4dbfb25483141202aa4d426f0d1be71b72`; partition safety `0455c0662b99fefee0cd9efd81947b2cf9d911c9577ae6f6a898d13969b29463`; healed state `b3924b2c1ce1a879e07fea560b4f9615e419627aa55e8d1c2d93b2ec796295d0`.
- Both pinned commits have good cryptographic signatures under GitHub's published web-flow key fingerprint `968479A1AFF927E37D1A566BB5690EEEBB952194`; local owner trust remains `UNKNOWN` and is not represented as a personal trust certification.
- Remaining non-blocking limitations: this is a single-machine experimental testnet with modified clients, not decentralization or production readiness; the Prysm linker warning requires hardening review; validator BLS, secp256k1 transactions, Keccak consensus hashing, and Groth16 are not post-quantum secure; public deployment remains gated by later phases and audits.

### Phase 3 — Immutable contracts, assets, and circuits

Tasks:

- [x] Add Foundry and pinned compatible OpenZeppelin dependencies.
- [x] Implement account/paymaster contracts, RAY, SPTM, mock oracle/reserve, AMM, treasury, fee escrow, fixed roles, and version registry.
- [x] Add the cryptographic algorithm registry, domain-separated SHA3-384 artifact digests, hybrid ML-DSA-65 verifier benchmarks, and downgrade-resistant signature envelopes.
- [x] Implement poll factories, CivicPoll, PredictionPool, outcome positions, CLOB settlement, oracle, reports, and refunds.
- [x] Add Circom/Groth16 circuits for commitments, notes, nullifiers, value conservation, eligibility, staking, claims, and settlement roots.
- [x] Generate reproducible test proving/verifying-key manifests without ceremony secrets.

Progress evidence (2026-08-22):

- Pinned Foundry `v1.7.1` (`cf7e688ed0c4c48adffca788b496076e31060b67ac5afe1e43dbb5499c20c88b`), OpenZeppelin Contracts `v5.6.1` (`5fd1781b1454fd1ef8e722282f86f9293cacf256`), Forge Standard Library `v1.16.2` (`bf647bd6046f2f7da30d0c2bf435e5c76a780c1b`), and Solidity `0.8.30`.
- Implemented the initial research contracts for fixed-supply RAY transfer restrictions, signed mock SPTM pricing and one-way sale, zero-fee protocol-owned AMM, fixed treasury and creation-fee escrow, immutable role/version registries, hybrid classical/post-quantum signature envelopes, and pari-mutuel payout arithmetic.
- Verification command: `forge fmt --check && forge test -vv && forge lint` from `/contracts`.
- Current result: 46 Foundry tests passed, including 2,000 fuzz cases; 0 failed; lint completed without findings.
- Phase 2 completion unblocked Phase 3 on 2026-08-23. The pinned Foundry v1.7.1 Windows archive and Solidity 0.8.30 binary were restored from their official release artifacts and verified against SHA-256 `6d41121b4bbb809845821c903619cfee75ed364f2bdc58a6787c9b0454114537` and `ccbd3ed44d5fbd26fe039702d403421f1212d2e8752e3cbe3bfd074986911586` respectively.
- Added a minimal immutable ERC-4337 Raygir smart account and signed-policy paymaster. Focused tests cover EntryPoint-only execution, owner signature validation, sponsorship time bounds, call-data tamper rejection, per-operation gas caps, and EntryPoint-only gas accounting.
- Verification command: `forge fmt --check && forge test --use <verified-solc-0.8.30> -vv && forge lint --use <verified-solc-0.8.30>` from `/contracts`. Current result: 52 Foundry tests passed, including 2,000 fuzz cases; 0 failed.
- Pinned Circom `2.2.3` from its official Windows release artifact (SHA-256 `e43f132ee6f0aa79b705beceb59c2a7e6a54d7bdeab917ca34e9fc1951d185e1`), plus `circomlib 2.0.5`, `circom_tester 0.0.24`, and `snarkjs 0.7.6`; package lock SHA-256 `79e3a5e7ce9442feb32c7d567c8c61abf30c2e4f51477fd09884cce6d00f4333`.
- Added the first circuit foundation for private note commitments, poll-scoped nullifiers, and 128-bit value conservation. `npm test` in `/circuits` passes 4 witness/constraint tests, including scoped-nullifier divergence and inflation rejection. Eligibility, staking, claims, settlement roots, proof fixtures, and reproducible proving-key manifests remain incomplete, so the circuit task and Phase 3 gate remain open.
- The post-quantum test verifier is deliberately a deterministic mock. A real ML-DSA-65 verifier, gas/size benchmarks, external SHA3-384 artifact generation, account/paymaster contracts, market state machines, and circuits remain pending; Phase 3 is not complete.

Revalidation and cryptographic progress (2026-08-27):

- Phase 0 documents remain present and Phase 1 revalidation passes: Pest 50 tests / 207 assertions against PostgreSQL, TypeScript, repository-owned ESLint, Prettier, and the production Vite build. Root ESLint now excludes checked-out toolchains, chain clients, circuits, and Solidity dependencies rather than linting third-party generated JavaScript.
- Phase 2 replay verification passes again for `clean-1`, `clean-2`, `clean-3`, and the 2/2 partition dataset: 50, 61, 49, and 61 persisted blocks respectively, each spanning PoW and PoS with unchanged canary state and receipt.
- Current Phase 3 verification passes 58 Foundry tests plus 4 circuit witness tests. The contract suite includes 2,000 fuzz cases; Foundry formatting and lint pass.
- Node.js/OpenSSL generated and verified a real ML-DSA-65 signature. The measured test vector uses a 3,309-byte signature and 1,974-byte SPKI public key; the standard-library SHA3-384 helper emits the required 48-byte artifact digest. The timing command is an environment benchmark, not a protocol constant.
- Added a fail-closed Solidity adapter for a future chain-native ML-DSA-65 verifier. False, malformed, reverting, and absent verifier responses cannot authorize an envelope.
- Added the immutable CivicPoll factory foundation. Reviewed bilingual manifest hashes, timing, option count, credit limit, proof relay, nullifier uniqueness, and committed-credit conservation are enforced on-chain; four focused tests pass. PredictionPool, outcome positions, CLOB settlement, resolution, reporting, and refund contracts remain open.
- The cryptographic task remains open: the Sepehr execution client does not yet expose a native ML-DSA-65 verifier/precompile, so real on-chain verification, gas benchmarking, key rotation, and the complete downgrade/algorithm-confusion matrix have not passed.

Native post-quantum verifier progress (2026-08-30):

- Added an experimental Sepehr-only ML-DSA-65 execution-client precompile at address `0x0101`. It accepts the fixed raw envelope `message(32) || publicKey(1952) || signature(3309)`, returns a 32-byte true value only for a valid signature, and otherwise fails closed.
- Added the `mldsa65TransitionTimestamp` chain-spec parameter and enabled it from genesis in the committed Sepehr Nethermind chain specification. The modern Bouncy Castle dependency is assembly-aliased so it cannot be confused with Nethermind's transitive legacy Bouncy Castle assembly.
- Verification: the focused native test generated a real ML-DSA-65 key pair/signature, accepted the valid vector, and rejected a one-byte mutation (1/1 passed, measured test body 90 ms). The complete Nethermind Specs suite passed 277/277 tests, and the affected execution-client projects built in Release mode with zero warnings and zero errors.
- Updated the Solidity adapter to send the precompile's raw fixed-length input. Foundry formatting, unit/fuzz tests, and lint pass: 58/58 tests, including 2,000 fuzz cases. Circuit foundation revalidation passes 4/4 witness/constraint tests with pinned Circom 2.2.3.
- Phase 3 remains `IN_PROGRESS`: a defensible gas benchmark, regenerated/revalidated client patch provenance, remaining market contracts, remaining circuits and Groth16 artifacts, and the full signature-security matrix are still required by the gate.

Full Phase 3 gate audit (2026-08-30):

- Passing evidence: Pest 50/50 tests with 207 assertions against PostgreSQL; PHPStan with a 1 GB worker limit; Foundry formatting, lint, and 58/58 tests including 2,000 fuzz runs; Circom 4/4 witness tests; Nethermind ML-DSA focused test 1/1; Nethermind Specs 277/277; and replay verification for `clean-1`, `clean-2`, `clean-3`, and `partition` with 50, 61, 49, and 61 PoW/PoS blocks respectively.
- Root `composer ci:check` is not green: Pint reports `single_blank_line_at_eof` failures in ten existing PHP test files. PHPStan also requires an explicit memory limit above the configured 128 MB on this workstation, although analysis passes with `--memory-limit=1G`.
- The committed execution-client patch SHA-256 still matches its provenance entry (`700e0251860a9f3eed500731ddabb3bcd6d0a557ad26d430e574348fd75f72f7`), but that patch predates and does not contain the ML-DSA precompile or activation changes. It must be regenerated and forward/reverse validated before the client work is reproducible.
- Missing implementations confirmed by source inventory: PredictionPool state machine, fully collateralized outcome positions, CLOB settlement, market-resolution/report/refund contracts, note-ownership/eligibility/staking/claim/settlement-root circuits, Groth16 proof fixtures, and proving/verifying-key manifests.
- Missing mandatory negative/security evidence: malformed Groth16 proofs, proof replay and double-spend, complete algorithm-confusion and downgrade matrix, key-version migration/rotation, native verifier gas calibration, and classical-only compatibility. Consequently none of the three Phase 3 gate checkboxes can yet be marked complete.
- Local CI remediation (2026-08-30): normalized the ten reported PHP test-file endings and made the existing Composer PHPStan command use a 1 GB analysis limit so the repository gate does not depend on the workstation's insufficient 128 MB default.
- Added fully collateralized YES/NO outcome positions with one-for-one split, complete-pair merge, resolver-gated post-close resolution, winning redemption, and protocol-only secondary transfers. Five focused tests cover collateral conservation, transfer boundaries, resolution timing, winning redemption, and invalid-market pair recovery; the full Foundry result is now 63/63 tests with 2,000 fuzz runs.

Foundry and Noir revalidation (2026-08-30):

- Installed the official Linux Foundry `v1.7.1` archive and verified Forge commit `4072e48705af9d93e3c0f6e29e93b5e9a40caed8` inside WSL. `forge fmt --check`, `forge test -vv`, and `forge lint` pass: 63/63 tests, 0 failures, including 2,000 fuzz runs.
- Added a dependency-free Noir `1.0.0-beta.26` foundation benchmark using Poseidon2 domain separation for note commitments and poll-scoped nullifiers plus 128-bit value conservation. `nargo fmt --check`, `nargo check`, `nargo test`, `nargo info`, and `nargo execute` pass; 4/4 Noir tests pass and the compiled circuit contains 23 ACIR opcodes and 0 Brillig opcodes.
- Barretenberg `5.0.0` generated and natively verified an EVM-target UltraHonk proof. A one-byte-mutated proof was rejected, and the generated 103,919-byte Solidity verifier compiled successfully with Solidity 0.8.30. Evidence hashes are recorded in `circuits/noir/foundation/proof-manifest.json`.
- Compatibility limitation: the official Barretenberg version map currently ends at Noir `1.0.0-beta.22` and does not formally map beta.26. The successful `beta.26` + Barretenberg `5.0.0` run is local compatibility evidence, not an upstream support claim. Noir remains an evaluated supplement; replacing the locked Circom/Groth16 architecture requires an explicit plan change and equivalent verifier, ceremony, audit, and integration gates.
- Phase 3 remains `IN_PROGRESS`: this closes only the installed-toolchain and foundation proof smoke checks. The remaining market contracts, complete circuit inventory, replay/double-spend proof integration, reproducible setup artifacts, cryptographic security matrix, gas calibration, and client patch provenance are still mandatory.

Market, circuit, and Phase 4 boundary progress (2026-08-30):

- Added an immutable PredictionPool with opaque commitments, exact early-weighted payout slices, 10%-of-whole-pot creator reward, invalid-market refunds, duplicate-commitment rejection, and claim replay protection. Added replay-safe EIP-712 CLOB settlement with partial fills, cancellation, price bounds, collateral transfer, and overfill rejection.
- Added a fixed 3-of-5 resolution manager with a 48-hour challenge window, seven-day invalidation timeout, poll-scoped report nullifiers, and the configured adaptive pause threshold. The full Foundry suite now passes 71/71 tests with 2,000 fuzz runs; formatting and lint pass without findings.
- Expanded the Circom foundation with note-ownership, credential-knowledge/nullifier, 128-bit stake conservation, and deterministic settlement-root circuits. The suite passes 8/8 valid/invalid witness tests. These are foundations, not a claim that the complete Semaphore/signature, claim, batch-settlement, and production ceremony circuits are finished.
- Added a separate Laravel 13 issuer service under `/issuer-demo`, configured for PostgreSQL only. Its versioned challenge, blind-issue, policy, issuer-root, revocation-root, and well-known endpoints store a keyed person-reference hash and blinded commitment but no wallet, poll, nullifier, choice, or voting callback. Its focused Pest suite passes 3 tests / 24 assertions against PostgreSQL.
- Added Raygir credential co-signing and anonymous relayer APIs. Issuer signatures are verified before co-signing; relayer persistence keeps only the nullifier, SHA3-384 proof hash, public call data, expiry, status, and optional transaction hash. Seven focused root tests pass across credential co-signing, relayer privacy/replay, and the local wallet boundary.
- Added encrypted local-vault recovery export/import. TypeScript, ESLint, and Prettier pass. The generated empty SQLite file from the issuer scaffold was removed after switching development and tests to PostgreSQL; it contained no application data and is not recoverable or needed.
- Compatibility limitation: the issuer demo currently uses fail-closed Ed25519 detached signatures at the HTTP boundary. It demonstrates the two-site privacy separation but is not the final SNARK-friendly dual-signature credential required by the Phase 4 gate. Phase 3 and Phase 4 therefore remain incomplete.

Groth16 and native post-quantum evidence (2026-08-30):

- Replaced the initial eligibility prototype with a dual-approved credential proof: the authority and Raygir each provide an EdDSA-Poseidon signature over the same blinded credential commitment, while the holder secret, blinding, and signatures remain private. The circuit binds public issuer keys, chain, verifier, poll, policy, and credit counter to its public credential commitment and nullifier.
- Compiled the corrected eligibility circuit to R1CS/WASM with Circom 2.2.3: 18,129 constraints, nine public inputs, eight private inputs, and two outputs. A local Groth16 proof verified successfully; a tampered poll input was rejected; and the generated Solidity verifier compiled with Solidity 0.8.30.
- Added `circuits/groth16-test-manifest.json` with SHA-256 hashes for the R1CS, zkey, verification key, proof, public signals, and Solidity verifier, plus the Powers-of-Tau Blake2b-512 hash. The manifest explicitly marks the deterministic single-contributor local ceremony as test-only and `productionSafe: false`; no ceremony secret is committed.
- Official prepared Powers-of-Tau downloads were unavailable from this environment, so this evidence closes the local proof-generation and malformed-public-input smoke check only. A multi-contributor or otherwise independently trusted production setup remains mandatory before public use.
- Added a separate reproducible ML-DSA-65 Nethermind patch at `sepehr-chain/patches/nethermind-1.39.2-mldsa65-precompile.patch` (SHA-256 `a146710843603eb0d2a015d8ed22d361923d061ae578ae8c9d9206e5d76717ce`). Forward and reverse application checks pass against pinned commit `6568910591e4618dc49d54285b6213c3753d7243`.
- The native verifier focused suite passes 3/3 tests after a clean Release rebuild with zero warnings and zero errors: valid ML-DSA-65 verification, signature tampering rejection, exact 5,293-byte input enforcement, malformed length rejection, and fixed-gas assertion. The measured workstation result is 1.499 ms average over 25 verifications at a provisional fixed cost of 250,000 gas.
- The hybrid-signature security matrix now covers missing classical/PQ signatures, swapped algorithm signatures, changed artifact/domain/epoch/verifier instance, explicit immutable key-epoch rotation, a reverting PQ verifier, and classical-only downgrade rejection. The complete Foundry suite passes 77/77 tests, including 2,000 fuzz runs; formatting and lint pass.
- Added claim and batch-settlement circuits. Claim proofs bind the private owner secret and blinding to a public poll, payout, position commitment, and emitted claim nullifier. Batch settlement enforces 128-bit input/output/fee conservation and binds the next root to the previous root, sequence, batch digest, output value, and fee. The Circom suite passes 11/11 valid/invalid witness tests, including forged authority/Raygir approval rejection.
- The provisional gas value remains experimental until independent multi-platform denial-of-service calibration. That external calibration and an independently trusted setup are `PRODUCTION_TEST` requirements for public deployment; Phase 3 still requires a documented one-command artifact regeneration workflow and the remaining factory wiring.
- Added the generated test-only Groth16 verifier as a Solidity test fixture and verified the real proof on-chain. Mutating either the poll public signal or proof point fails verification. Together with poll/pool nullifier and claim-replay tests, the circuit malformed-proof, replay, and double-spend gate now passes. The full Foundry suite passes 78/78 tests, including 2,000 fuzz runs; formatting and lint pass.
- Added a stateful RAY invariant suite. Across 256 runs and 16,384 randomized protocol-route transfers with zero reverts, total supply remained fixed and every unit remained accounted for. The full Foundry suite now passes 79/79 tests; formatting, lint, fuzz, conservation, and invariant checks pass.

Gate:

- [x] Foundry unit, fuzz, invariant, static-analysis, and conservation tests pass.
- [x] Circuit valid/invalid witness, malformed-proof, replay, and double-spend tests pass.
- [x] Cryptographic vectors, hybrid fail-closed behavior, algorithm-confusion, downgrade, key-rotation, size/gas, and classical-only compatibility tests pass locally. Independent multi-platform gas calibration remains a public-deployment `PRODUCTION_TEST`.

Completion entry (2026-08-30):

- Status: `COMPLETED`. Repository base commit at verification time: `00a8588b1446`; the completion changes were not committed automatically.
- Added deterministic CivicPoll and PredictionPool factories. The prediction factory binds the RAY asset, proof relay, resolver, creator, timing, and early-boost rules and rejects duplicate market identifiers.
- `forge fmt --check && forge test -vv && forge lint` passed from `/contracts`: 80 tests across 18 suites, 0 failures, including 2,000 fuzz runs and a stateful invariant with 256 runs / 16,384 calls / 0 reverts.
- `npm test` passed from `/circuits` with pinned Circom on `PATH`: 11 valid/invalid circuit tests, including dual credential signatures, claim ownership/nullifiers, batch conservation, malformed witnesses, and scoped replay resistance.
- The real test-only Groth16 verifier accepts the generated dual-credential proof and rejects mutated proof points and public poll inputs. `circuits/groth16-test-manifest.json` records the power-15, R1CS, proving key, verification key, proof, public signals, and Solidity-verifier hashes; `productionSafe` remains `false`.
- The separate ML-DSA-65 Nethermind patch still hashes to `a146710843603eb0d2a015d8ed22d361923d061ae578ae8c9d9206e5d76717ce` and previously passed forward/reverse checks against pinned Nethermind commit `6568910591e4618dc49d54285b6213c3753d7243`. Its Release build and 3 focused verifier tests passed with zero warnings/errors; measured verification was 1.499 ms over 25 iterations with a provisional 250,000 gas cost and exact 5,293-byte input.
- Remaining non-blocking limitations: the Groth16 setup is deterministic test material, not a trusted production ceremony; ML-DSA gas calibration requires independent multi-platform testing; Groth16, secp256k1, validator BLS, and consensus hashing are not post-quantum secure. These limitations remain explicit public-deployment `PRODUCTION_TEST` requirements and do not represent production readiness.

### Phase 4 — Passkey wallet, shielded funding, and issuer demo

Tasks:

- [x] Build the local passkey smart account and encrypted recovery export.
- [x] Add hybrid passkey/secp256k1 + ML-DSA smart-account authorization and clearly label classical-only extension-wallet actions.
- [x] Connect extension wallets only for public deposits.
- [x] Implement notes, batched deposits, relayers, withdrawals, and paymaster quotas.
- [x] Build the separate fictional authority app and PostgreSQL database.
- [x] Implement dual approval and the versioned OpenAPI contract.
- [x] Add issuer-root snapshots, revocations, credit counters, and replay protection.

Progress evidence (2026-08-22):

- Added a bilingual `/fa|en/wallet/onboarding` research surface with no Laravel session middleware and no operator identity prop, linked through generated Wayfinder routes.
- Added a browser-local vault prototype: a 32-byte random secret is encrypted with AES-256-GCM under an HKDF key derived from an authenticator-provided WebAuthn PRF result and stored in IndexedDB. PRF output and decrypted secret buffers are cleared after use.
- Unsupported WebAuthn PRF, cancelled ceremonies, malformed local records, and failed decryption have explicit states. There is no weaker password, server-held-key, or Fortify fallback.
- Verification: `php artisan test --compact` passed 50 tests with 207 assertions; TypeScript, ESLint, Prettier, production Vite build, and Pint passed.
- At this 2026-08-22 checkpoint this was not yet a smart account or recovery package and produced no wallet address. Later evidence below supersedes the completed portions of that limitation.

Progress evidence (2026-08-30):

- Added `RaygirHybridSmartAccount`, an ERC-4337 account that requires both a user-verifying WebAuthn P-256 assertion and an ML-DSA verifier result. Missing, malformed, or tampered signature envelopes fail closed. The pre-existing ECDSA account is now explicitly labeled classical-only for public extension-wallet funding actions.
- Added an immutable-verifier shielded note pool with batched deposits, proof-authorized withdrawals, exact amount/commitment binding, duplicate-commitment rejection, and nullifier replay protection. Its deterministic verifier remains a test fixture until the production proving setup is completed.
- Added append-only issuer and revocation root snapshots in the issuer demo PostgreSQL database. Issuance is restricted to configured policies and exposes the configured credit limit without storing wallet, poll, nullifier, or choice data.
- Added `issuer-demo/openapi.yaml`, a versioned OpenAPI 3.1 contract covering discovery, challenge, blind issuance, Raygir co-signing, policies, and issuer/revocation roots. Its focused contract-presence test passed with 11 assertions.
- Verification: the complete Foundry gate passed 84 tests across 20 suites with zero failures, including 2,000 fuzz cases and 256 invariant runs / 16,384 calls / 0 reverts. The focused issuer snapshot/policy suite passed 5 tests with 40 assertions.
- The browser vault now extracts the WebAuthn P-256 public coordinates, creates an ML-DSA-65 seed locally, encrypts the wallet and PQ seed under the passkey PRF-derived AES-GCM key, regenerates and verifies the ML-DSA public key after unlock, and includes only encrypted private material in the recovery package. `@noble/post-quantum` is pinned at `0.7.0`.
- Added a bilingual public RAY deposit flow using the extension wallet only for ERC-20 approval and `ShieldedNotePool.deposit`. Note secrets remain passkey-encrypted in IndexedDB. Contract addresses are deployment configuration, not user input.
- Browser commitments now use the same Poseidon-4 inputs as `commitment.circom`: owner secret, asset address, amount, and blinding. The circuit test asserts exact browser-library/Circom output equality; all 11 circuit tests pass.
- Remaining deployment limitations are classified `PRODUCTION_TEST`: real authenticator/browser coverage, deployed EntryPoint/account factory and bundler interoperability, real verifier/proving artifacts, two-origin traffic/log inspection, and testnet deposit/withdrawal round trips. These do not claim production readiness.

Gate:

- [x] Raygir never receives demo identity.
- [x] The issuer never receives wallet, poll, nullifier, or choice.
- [x] Duplicate and replayed proofs fail.

Completion entry (2026-08-31):

- Status: `COMPLETED`. Repository base commit at verification time: `00a8588b1446`.
- Root verification: 54 Pest tests / 226 assertions; TypeScript, ESLint, Prettier, and production Vite build passed.
- Issuer verification: 8 Pest tests / 53 assertions and production Vite build passed.
- Protocol verification: 84 Foundry tests across 20 suites, zero failures; 2,000 fuzz cases; 256 invariant runs / 16,384 calls / 0 reverts; formatter and linter passed. Circom passed 11/11 tests with pinned `.tools/circom.exe` on `PATH`.
- Artifact hashes: root `package-lock.json` SHA-256 `361baf92482b9bd82da6ea2ea44e8f4cf598e688c3768f4f095dcdbb05d434d3`; eligibility OpenAPI SHA-256 `53dca71c3fdbbabb3558f0e377c07a48e666c5338d6e2a86349453196b3a1893`.
- Non-blocking research limitations: ML-DSA browser code and Poseidon compatibility are locally verified but unaudited in this project; public deposits intentionally expose the funding transaction; private spending still depends on the production proving and relayer deployment gates.

### Phase 5 — CivicPoll and government research profile

Tasks:

- [x] Implement one-credit and configurable multi-credit civic polls.
- [x] Keep credits non-purchasable and non-transferable.
- [x] Add anonymous commit/reveal, tally proofs, tie/runoff rules, and non-reveal rules.
- [x] Add authority-signed official ballot manifests.
- [x] Permit government revision `0` plus one replacement revision `1`; only the latest counts.
- [x] Publish anonymous ballots after close.
- [x] Label government mode experimental and not coercion-resistant or certified.

Progress evidence (2026-08-31):

- Extended `CivicPoll` with an immutable reveal deadline, poll-scoped commitment storage, relay-only anonymous reveals, multi-option credit allocation, per-option tallies, non-reveal exclusion, deterministic winner/tie state, and one-time finalization.
- Civic credits remain accounting values created only by an eligible proof relay; there is no token, purchase, approval, or transfer surface.
- Focused Foundry verification passed 6/6 CivicPoll tests covering credit limits, unauthorized callers, duplicate nullifiers, forged and duplicate reveals, late reveals, exact tally conservation, winner selection, and duplicate poll IDs.
- At the first 2026-08-31 checkpoint, runoff rules, threshold signatures, replacement semantics, publication, and malicious-client coverage were pending; the completion evidence below supersedes that checkpoint.

Completion evidence (2026-08-30):

- Added a fixed 3-of-5 `GovernmentElectionFactory`. The signed digest binds the chain, factory, proof relay, poll ID, manifest hash, all deadlines, option count, and credit limit. Duplicate, unknown, insufficient, or term-mismatched signatures fail closed.
- Added the `GovernmentElection` research profile. It is permanently marked `GOVERNMENT_CERTIFIED = false` and `COERCION_RESISTANT = false`, permits revision `0` plus exactly one revision `1`, removes superseded credits from the committed total, and rejects reveals from superseded revisions.
- Anonymous `BallotRevealed` events publish the nullifier and allocations only after close. Non-reveals do not enter tallies; zero reveals produce `noWinner`; tied non-zero results set the runoff-required state.
- Added `civic-tally.circom`, a bounded four-ballot/eight-option proof building block that range-checks credits, rejects allocations to disabled options, proves per-ballot conservation, derives per-option totals, and binds them into a Poseidon tally root. Larger elections require recursive or multi-batch aggregation during the production proving gate.

Gate:

- [x] Eligibility, replacement, tally-conservation, reveal, and malicious-client tests pass.

Completion entry (2026-08-30):

- Status: `COMPLETED`. Repository base commit at verification time: `00a8588b1446`.
- `forge fmt && forge test && forge lint` passed: 91 tests across 21 suites, zero failures, including 2,000 fuzz cases and 256 invariant runs / 16,384 calls / 0 reverts.
- `npm test` from `/circuits` with pinned `.tools/circom.exe` on `PATH` passed 12/12 tests, including forged allocations, disabled-option allocation, aggregate conservation, eligibility replay, and malformed credential proofs.
- Artifact hashes: `GovernmentElectionFactory.sol` SHA-256 `bfd29e0ce59ef88cdecc36865a429af534bdb81f8f1cea8c086598bb3fff5cce`; `civic-tally.circom` SHA-256 `7d2e7c44e98563d0237d9e6e70609f17a065f1db2de1fbe4690dd47dd28e8cec`.
- Remaining non-blocking limitations: the tally circuit is a bounded aggregation primitive, authority signing remains classical ECDSA during this research phase, and real election guardians, ceremonies, recursive aggregation, independent audits, and coercion resistance remain `PRODUCTION_TEST`/Phase 12 requirements.

### Phase 6 — PredictionPool, moderation, and oracle

Tasks:

- [x] Implement RAY staking, 10% whole-pot creator reward, 1% early weighting, exact rounding, shielded claims, and refunds.
- [x] Implement LLM review, escrow outcomes, adaptive reports, pauses, warnings, and bans.
- [x] Add hybrid self-hosted/external LLM adapters using public content only.
- [x] Add evidence crawling, allowlists, hashes, proposals, committee decisions, challenge bonds, and timeouts.

Gate:

- [x] Property tests prove exact token conservation.
- [x] AI/provider failures cannot settle funds.
- [x] Every invalid path refunds according to the specification.

Progress evidence (2026-08-31):

- Added an operator-only, provider-neutral public-content moderation API with deterministic validation for bilingual terms, option overlap, HTML, timing, and source requirements.
- Review results persist schema version, reason codes, confidence, cited allowlisted sources, model ID, SHA3-384 public-payload hash, and prompt hash in PostgreSQL. Evidence bodies are not retained; only their URLs and SHA3-384 hashes are stored.
- Provider outage or invalid output produces `provider_failure`, the 100% creation-fee refund action, and `settlement_authorized: false`. AI review does not possess or invoke an outcome-settlement interface.
- `php artisan test --compact`: 58 tests, 252 assertions, all passed.
- `npm run types:check` and `npm run lint`: passed.
- Foundry: 91 tests across 21 suites passed, including 1,000-run payout fuzzing and 256 invariant runs / 16,384 calls / 0 reverts.
- Circuit rerun is currently environmental, not a protocol failure: the Windows test process cannot resolve a `circom` executable. The prior checked-in 12-test circuit suite remains unchanged, but this run is not counted as passing evidence.
- The Windows circuit runner limitation above is non-blocking for Phase 6 because this phase did not modify circuit sources; it remains an environment issue to resolve before the next circuit gate.

Completion evidence (2026-08-31):

- Creator enforcement records only a credential hash and audit reason hash: non-malicious upheld violations warn without a ban, first deliberate deception bans for 30 days, and a repeat within 180 days bans for one year.
- The configurable HTTP review adapter supports either a self-hosted or external compatible endpoint and receives public market material only.
- The evidence crawler requires HTTPS, exact configured host allowlisting, a future cutoff, explicit timeouts/retries, and a 1 MB response cap; tests prevent stray HTTP requests.
- `MarketResolutionManager` now requires an exact native-SEP challenge bond and distinct 3-of-5 committee review. Upheld and timed-out challenges credit the challenger; rejected challenges credit the treasury through pull withdrawals.
- Invalid and no-winner PredictionPools refund all stake and pay no creator reward. A 1,000-run fuzz test conserved every staked unit across two claimants.
- `php artisan test --compact`: 66 tests, 274 assertions, all passed.
- Foundry: 96 tests across 21 suites, all passed; payout/refund fuzz tests each ran 1,000 cases and the RAY invariant ran 256 sequences / 16,384 calls / 0 reverts.
- `vendor/bin/pint --dirty --format agent`, `forge fmt --check`, `npm run types:check`, `npm run lint`, and `git diff --check`: passed.
- Base commit: `00a8588b1446` (Phase 6 changes remain in the working tree).
- Artifact SHA-256: `MarketResolutionManager.sol` `58dfd329f3c84e82f36f11bc00bc56a87a142840a9e9178b25d8fc157b69237e`; `RecordCreatorViolation.php` `1c6592c3d8526ea72ab10a9bb59cabf4dc2ec08c21368990bad663ef82b51f10`; `AllowedEvidenceCrawler.php` `1b89302ee5baf900a539dcb35f53d80190547eb49b72bc5854752efee0aad009`.
- Remaining non-blocking limitation: crawler allowlists are operator-configured and do not make a source truthful; committee members must assess the preserved evidence hashes and publish reasoning.

### Phase 7 — Continuous CLOB

Tasks:

- [x] Implement PostgreSQL price-time matching, partial fills, cancellation, deterministic sequencing, and restart recovery.
- [x] Encrypt order envelopes at rest and decrypt only inside the matcher.
- [x] Publish aggregate depth and market data.
- [x] Batch signed matches into on-chain shielded settlements.
- [x] Implement split, trade, merge, and redeem.

Gate:

- [x] No overspend, double fill, under-collateralization, replay, or settlement divergence.
- [x] Restart reproduces the same order book from PostgreSQL.

Progress evidence (2026-08-31):

- Added PostgreSQL `clob_orders` and `clob_trades` ledgers. Order arrival IDs are the deterministic time-priority sequence; encrypted envelopes hold maker, size, price, nonce, signature, and filled amount and are hidden from model serialization.
- The matcher performs best-price/first-arrival matching, partial fills, maker-authorized cancellation, self-match avoidance, expiry filtering, aggregate depth, and deadlock-retried row locking.
- Raw PostgreSQL encryption and fresh-process book reconstruction are covered. A restarted matcher returns the identical aggregate price levels and remaining amounts.
- Pending trades receive a deterministic BN254-field-safe PostgreSQL coordination ID. Submitted batches survive restart, cannot be prepared twice, retry to the same ID after release, and become immutable after confirmation.
- Added `ShieldedClobBatchSettlement`, which enforces matcher-only, sequential, replay-safe state-root transitions through an `IClobBatchVerifier` proof boundary.
- Added a Noir/UltraHonk private-order authorization circuit for one or two non-repeating matches. It recomputes Poseidon2 digests from market, token, side, amount, limit price, nonce, and expiry; verifies distinct secp256k1 buyer/seller signatures; derives exchanged quote/outcome values from fill and execution price; enforces fill/price/expiry bounds; and binds ordered matches to the sequential settlement root. Testnet CLOB fees are constrained to zero.
- The PostgreSQL matcher now selects at most two trades without repeating a buy or sell order and emits the exact padded Noir ABI, including field/range-checked values, public keys, compact signatures, executions, prior root, sequence, fee, and settlement time.
- The generated Solidity verifier accepts the pinned two-match Barretenberg proof, rejects changed sequence/timestamp/count public inputs, and advances `ShieldedClobBatchSettlement` only when its on-chain `block.timestamp` and one-or-two match count match the proof. A malformed buyer signature fails during witness generation.
- `php artisan test --compact`: 73 tests, 315 assertions, all passed. Foundry: 101 tests across 24 suites, all passed. Noir: 2 CLOB authorization tests and 4 foundation tests passed. TypeScript and ESLint passed. The Barretenberg EVM proof also passed direct `bb verify`.
- Reproducibility is recorded in `circuits/noir/clob_authorization/proof-manifest.json`; the committed proof fixture is independent of ignored `target/` output.
- The CLOB circuit now proves owner-bound balance leaves, depth-16 Merkle membership, sufficient buyer quote and seller outcome balances, and four sequential leaf replacements for every active match. Its 65,536-leaf research tree advances from the public prior root to the exact public next root; stale paths and overspending fail witness generation.
- Added a PostgreSQL settlement-batch ledger and queued proving/submission lifecycle. Witnesses use Laravel encrypted casts at rest and are erased immediately after proof creation. The worker rejects prover output that does not bind the queued root, sequence, zero fee, timestamp, count, and next root.
- Submission uses the deterministic batch ID as the external gateway idempotency key. A scheduled reconciliation command records canonical block number/hash, confirms trades atomically, and resubmits the same proven batch after a failed or reorged transaction without recreating private witnesses.
- Status: `COMPLETED`. `php artisan test --compact`: 76 tests, 341 assertions; Foundry: 101 tests across 24 suites; Noir: 4 CLOB and 4 foundation tests; TypeScript and ESLint passed. The regenerated UltraHonk proof passed native verification and all 7 focused on-chain CLOB tests.
- Completion date: 2026-08-31. Base commit: `00a8588b1446` (completion changes remain in the working tree). Artifact SHA-256: circuit source `2cb973120506e724ecda4d31d13bbd4ff2bde44853ec9f6b21945aee36f27e5a`; verification key `1318c69a03f5b0f51bd9ad11d236c7582d33913fd2de7a1c7d316ec6241c1385`; proof fixture `aa363971cb5bee8ae179fd9a9c52ccd6a88ea2b960dbd1203f24028b9907644e`; proving job `7c6ada6067708ea5d62e7cc0d7635c3bf5e7df7f7babe164d6082a44cbc3cc96`; coordinator `c0830067627ea446c37b3e87ecc3383fad8540d583280e6a9cd590e72c045a46`.
- `PRODUCTION_TEST`: the configured prover executable and authenticated settlement-gateway endpoint still require a live PoS testnet end-to-end run, canonical receipt observation, and forced-reorg drill. Those external-environment checks do not replace or weaken the passing deterministic circuit, PostgreSQL recovery, and contract gates.

### Phase 8 — Complete Raygir UI

Tasks:

- [x] Implement every Raygir page and state in `design.md`.
- [x] Display privacy disclosures before eligibility, deposits, voting, staking, orders, and explorer links.
- [x] Add mobile voting and trading without hiding critical rules.
- [x] Add admin review, report, evidence, dispute, issuer, paymaster, and health dashboards.

Gate:

- [x] Bilingual browser, accessibility, responsive, keyboard, light/dark, and empty/error-state tests pass.
- [x] No fabricated fallback data appears.

Progress evidence (2026-08-31):

- Added sessionless `/fa` and `/en` research surfaces for CivicPoll, PredictionPool, ExchangeMarket, creation, portfolio/funding, reports, oracle evidence, challenges, and refunds. Each surface renders mode-specific privacy and economic disclosures before unavailable controls and uses explicit real-data empty states.
- Replaced the operator dashboard starter placeholders with the required review, report/pause, resolver, issuer-root, paymaster, relayer, PostgreSQL projection, and RPC health panels. Panels remain unavailable rather than displaying fabricated telemetry.
- Anonymous surface routing strips the Laravel operator identity and session middleware. Generated Wayfinder route functions connect discovery cards to the three market-mode surfaces.
- Verification: `php artisan test --compact` passed 108 tests / 680 assertions; `npm run types:check`, `npm run lint:check`, `npm run format:check`, and `npm run build` passed.
- Completion entry (2026-08-31): status `COMPLETED`. `npm run test:browser` drove system Chrome through 66 Persian/English page profiles at 375, 768, and 1440 pixels in light/dark and reduced-motion modes. It verified 200 responses, locale direction, landmark uniqueness, keyboard focus, horizontal overflow, and browser error absence. The run exposed and fixed an unintended nested AppLayout on public market pages. The full Pest suite passed 108 tests / 680 assertions; TypeScript, ESLint, Prettier, Wayfinder generation, and the production build passed. Live chain-dependent controls correctly remain unavailable until their real projections and endpoints exist; no fabricated fallback records are used.

### Phase 9 — Sepehrbin from-scratch explorer

Use a separate Laravel 13/Inertia React application, PostgreSQL, and horizontally scalable Artisan indexer workers.

Tasks:

- [x] Index blocks, PoW miners, PoS proposers/validators, transactions, receipts, logs, withdrawals, pending transactions, and reorgs.
- [x] Index traces, token transfers, balances, ERC-20/721/1155 assets, NFTs, and portfolios.
- [x] Implement Solidity standard-JSON verification, metadata, constructor arguments, proxies, ABI, source, and bytecode matching.
- [x] Implement ABI read/write, simulation, gas estimation, chain warnings, and wallet connection.
- [x] Implement search, labels, notes, exports, charts, gas tracker, Merge timeline, analytics, alerts, API keys, and rate limits.
- [x] Expose native `/api/v1` APIs and a documented Etherscan-compatible subset.
- [x] Display privacy commitments and proofs without attempted deanonymization.

Gate:

- [x] Genesis reindex, multi-block reorg recovery, trace/token reconciliation, verification, API, export, and wallet tests pass.

- Completion entry (2026-08-31): status `COMPLETED`. Repository base commit at verification time: `2fe5a15`; completion changes were not committed automatically. A separate Laravel 13/Inertia React/PostgreSQL Sepehrbin application now provides rebuildable chain projections, PoW/PoS and validator views, pending and canonical transactions, multi-block reorg handling, traces, token transfers and portfolios, independently indexed contract bytecode verification, proxy metadata, ABI/source APIs, RPC simulation and gas estimation, CSV exports, search, privacy-aware displays, network charts, Merge metrics, alerts, labels, API keys, and a documented Etherscan-compatible subset. `php artisan test --compact` passed 9 tests / 425 assertions against PostgreSQL; `npm run test:browser` passed 48 real-Chrome Persian/English mobile/desktop profiles including wallet interaction; TypeScript, ESLint, Prettier, Pint, Wayfinder generation, production build, and a clean PostgreSQL migration passed. The root Raygir suite also passed 108 tests / 680 assertions and its 66-profile browser matrix. Artifact SHA-256: `sepehrbin/composer.lock` `452BFC2E7CB52AF8812BC1F08F0E677F93E44EFE32AB2457E912E48797DCCE02`; `sepehrbin/package-lock.json` `7A26C1935BC4D4AA97DFAAA2B43E4347A033928AC89DBD56C8C4EAC0C3213864`; `sepehrbin/public/build/manifest.json` `A7716107775CAC305A7FFB2107F3E66ADDD9ED0E9FCA38F01CBB7F5D79D7970A`. Remaining non-blocking limitation: live Sepehr RPC ingestion and wallet broadcasting require the deployed Phase 10 network; deterministic fixture/RPC-boundary tests are used locally and no fabricated explorer records are shipped.

### Phase 10 — Four-VPS experimental testnet

Every host runs patched Nethermind, a Prysm beacon node, a Prysm validator, and 64 validators. Every host mines before TTD.

| Host | Additional services |
|---|---|
| VPS 1 | Gateway, relayer, paymaster bundler, issuer demo |
| VPS 2 | Raygir web/workers and Raygir PostgreSQL primary |
| VPS 3 | Sepehrbin web/indexer and explorer PostgreSQL primary |
| VPS 4 | Archive/public RPC process, PostgreSQL replicas, monitoring and backups |

Tasks:

- [ ] Place hosts in different providers/regions where practical.
- [ ] Publish at least two signed execution bootnode records and consensus bootstrap ENRs, enable public discovery, and retain static peers only as a recovery fallback; node P2P must not depend on WireGuard.
- [ ] Generate one canonical immutable Sepehr Testnet EL/CL genesis bundle with a unique network identity, checksums, explicit valueless-asset disclosure, and no committed secret keys.
- [ ] Pre-fund an offline-generated faucet public address in genesis and provide a rate-limited funding path for test SEP; faucet funds have no redemption or monetary claim.
- [ ] Measure the constrained 2-vCPU/4-GB/30-GB profile separately; reject it for archive/public RPC and upgrade it if memory, disk, finality, or pruning gates fail.
- [x] Provide and test a guarded one-script community workflow for network bundle creation, dependency diagnosis, joining, service installation, lifecycle commands, and checksum verification. The 2026-08-31 local acceptance run covered dependency diagnosis, four-faucet genesis rendering, public bundle creation, outer and per-file SHA-256 verification, full-node preparation, local JWT generation, unsafe input rejection, duplicate faucet rejection, and tampered bundle rejection. Real systemd launch and live peer discovery remain Phase 10 production tests.
- [ ] Keep Engine and validator APIs loopback-only.
- [ ] Keep the PoW phase isolated from public RPC.
- [ ] Open public access only after the Merge, continuity tests, and private soak.
- [ ] Configure encrypted keys, slashing databases, configuration hashes, backups, alerts, clock monitoring, and restore procedures.
- [ ] Use hybrid classical + ML-DSA signatures for releases, configuration manifests, backups, issuer/resolver operations, and internal service identity where supported.
- [ ] Keep all secrets out of Git.

Gate:

- [ ] One-host outage preserves finality.
- [ ] Two-host outage halts safely.
- [ ] Backup/restore, 2/2 partition, TTD mismatch, reorg, and seven-day soak tests pass.

### Phase 11 — Public research beta and open source

Gate requirements:

- [ ] CivicPoll, PredictionPool, continuous CLOB, and broad Sepehrbin are complete.
- [ ] Persian and English experiences are complete.
- [ ] PostgreSQL restore and full chain reindex succeed.
- [ ] Chain, client, container, and proving artifacts are reproducible and have SBOMs.
- [ ] AGPL/LGPL review, contributor guide, security policy, and disclosure process exist.
- [ ] Threat model, privacy leakage table, economic invariants, and known limitations are public.
- [ ] Publish a cryptographic inventory and migration matrix that identifies every classical, hybrid, PQ, and not-yet-PQ primitive.
- [ ] Assets are visibly marked non-redeemable and valueless.
- [ ] No decentralization, real-Toman, government-certification, or absolute-anonymity claim is made.

### Phase 12 — Mainnet and government readiness

Mainnet remains unavailable until:

- [ ] The PoW→PoS fork is rebased, audited, and transition-tested again.
- [ ] Independent validators, RPC, archive/indexing, PostgreSQL, relayer, resolver, and election-guardian operators exist beyond the original four VPSs.
- [ ] Mainnet repeats PoW→PoS with test-value-only Raygir assets during PoW.
- [ ] Dual-chamber PoS governance is live and tested.
- [ ] Contract, circuit, wallet, relayer, oracle, matcher, node-client, and economic audits pass.
- [ ] A separately versioned consensus proposal replaces or hybridizes BLS validator signatures and classical transaction authorization, benchmarks larger keys/signatures and denial-of-service limits, and passes independent cryptographic and consensus audits before any fully-PQ claim.
- [ ] Any real SPTM-like asset has licensed reserves, legal claims, par redemption, attestations, and jurisdiction approval.
- [ ] Real prediction markets have written Iran-specific and every-target-jurisdiction legal approval.
- [ ] Government elections have legal authorization, independent certification, election-authority operation, recovery plans, observation procedures, and public audits.

## 14. Mandatory verification families

- Pest feature, unit, and browser tests for Laravel, PostgreSQL, authorization, localization, moderation, APIs, queues, and explorer behavior.
- TypeScript, ESLint, accessibility, responsive, RTL/LTR, and empty/error-state checks.
- Foundry unit, fuzz, invariant, gas, reentrancy, authorization, pause, conservation, and migration checks.
- Circuit valid/invalid witness, forged proof, replay, nullifier, overflow, rounding, double-spend, and setup-manifest checks.
- Chain TTD, state continuity, replay, finality, partition, outage, sync, clock-skew, and post-TTD PoW rejection checks.
- CLOB price-time ordering, partial fill, cancellation race, restart, collateral, settlement, and matcher-leakage checks.
- Explorer genesis reindex, trace consistency, token balance, verification, reorg, API, export, and wallet-command checks.
- Privacy checks proving PII, funding-wallet links, credential secrets, ballot secrets, and private notes never enter Raygir PostgreSQL or logs.

## 15. Explicit limitations

- The first beta is research/testnet only and cannot accept real money.
- Four VPSs owned by one operator provide redundancy, not decentralization.
- Failed mandatory PoW gates stop the project; they do not justify insecure deployment.
- RAY is swappable but not directly transferable between users.
- SPTM is a simulated 1,000-Toman reference, not a stablecoin or fiat claim.
- User-facing gas sponsorship is rate-limited and treasury-funded.
- The 10% whole-pot PredictionPool creator share means winners may receive less than their stake.
- Community and governmental anonymous ballots become public after close.
- The CLOB matcher can see orders and correlate activity within a pseudonymous account.
- Governmental remote voting is not claimed to be coercion-resistant.
- Mainnet tokenomics, real SPTM reserves, and legal-value activation require a separately approved mainnet specification after research gates pass.
