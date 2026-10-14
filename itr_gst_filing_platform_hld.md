# Kardo (TaxOS platform) — ITR & GST Filing Platform HLD/LLD

Companion to the code in `taxos/`. Written in the same cram style as the other design docs here.

## FR
1. User can compute income tax for an assessment year under both regimes and see the cheaper one.
2. User can enter income under all five heads: salary, house property, capital gains, business/profession, other sources.
3. System applies head-specific deductions, loss set-off, Chapter VI-A caps, rebate, surcharge, cess, and rounding exactly as the Act does.
4. System computes interest under ss.234A/B/C from advance-tax challans and the filing date.
5. System recommends the ITR form (1/2/3/4) with reasons.
6. Every amount carries provenance (section, note) so the UI can explain it.
7. User can compute GSTR-3B: output tax, ITC set-off per Rule 88A, cash payable, late fee, interest.
8. User can reconcile purchase books against GSTR-2B.
9. User can check whether GST registration, composition or e-invoicing applies.
10. User can verify the on-device computation against the server before filing.
11. User can submit through an e-Return Intermediary and e-verify (server side, credentialed).
12. Assistant answers "why" questions from engine output.

## NFR
1. Deterministic: same input, same output, on device and on server.
2. Rule packs versioned per assessment year; adding a year never changes an old one.
3. Instant what-if: full computation under 1 ms on a phone, no network.
4. Offline drafting; sync when online.
5. Seasonal scale: 20–50× traffic in the last 3 days before deadlines.
6. PAN/Aadhaar/bank fields encrypted at rest; data resident in India; DPDP Act 2023 consent trail.
7. Auditable: immutable log of every computation and submission.
8. Honest scope: audit cases (s.44AB) route to a CA marketplace; the app does not sign audits.

## Core Entities
- TaxpayerProfile (PAN, DOB → AgeCategory, ResidentialStatus)
- ItrInput (AssessmentYear, SalaryIncome, HouseProperty[], CapitalGain[], BusinessIncome, OtherSourcesIncome, Deductions, TaxesPaid)
- ItrRulePack (slabs, rebate, surcharge, caps, due date) — one per AssessmentYear
- ItrComputation (heads, GTI, TI, tax, rebate, surcharge, cess, credits, interest, LineItem[])
- RegimeComparison (old, new, recommended, savings)
- FormRecommendation (ItrForm, reasons)
- Gstr3bInput / Gstr3bResult (GstHeads × output, ITC, utilised, cash)
- GstInvoice / ReconLine / ReconResult
- LineItem (code, label, amount, section, note, group)

## Relationships
```text
AssessmentYear 1 → 1 ItrRulePack
ItrInput       1 → 1 TaxpayerProfile
ItrInput       1 → 0..1 SalaryIncome
ItrInput       1 → N HouseProperty
ItrInput       1 → N CapitalGain
ItrInput       1 → 0..1 BusinessIncome
ItrInput       1 → 1 TaxesPaid → N AdvanceTaxPayment
ItrComputer(ItrInput, TaxRegime) → ItrComputation → N LineItem
ItrComputer.compare(ItrInput) → RegimeComparison → 2 ItrComputation
Gstr3bInput    1 → N OutwardSupply
```

## Computation Pipeline (statutory order)
```text
1. Heads:   salary − exemptions − std ded − prof tax
            HP: NAV − 30% − interest  (SOP interest cap ₹2L old; nil new)
            CG: intra-head set-off (ST loss → any; LT loss → LT only)
            Business: books | 44AD 8%/6% | 44ADA 50%
            OS: interest + dividends + family pension − s.57(iia)
2. Set-off: HP loss ≤ ₹2L (old) / none (new); business loss never against salary
3. GTI → Chapter VI-A (old; 80CCD(2) both) capped to normal-rate income
4. TI = round10(GTI − deductions)                               s.288A
5. Tax: slabs on normal income (+ agri integration)
        111A 20% · 112A 12.5% above ₹1.25L · 112 12.5%
        residents absorb unexhausted basic exemption against special income
6. Rebate 87A: ≤ threshold → min(tax, cap); above → marginal relief (new)
7. Surcharge by TI band, 15% cap on special income, marginal relief at band edge
8. Cess 4% → total = round10(…)                                  s.288B
9. Credits: TDS + TCS + advance + SAT
10. Interest: 234A (late filing) · 234B (<90% advance) · 234C (instalments)
11. Net payable / refund
```

## Rule 88A Set-off (GST)
```text
IGST credit → IGST, then CGST, then SGST
CGST credit → CGST, then IGST   (never SGST)
SGST credit → SGST, then IGST   (never CGST)
Cess credit → Cess only
Reverse charge → always cash
Interest 18% p.a. on the cash component only (proviso to s.50(1))
```

## Patterns
| Pattern | Usage |
|---|---|
| Strategy | Regime (old/new) and rule pack per assessment year |
| Pipeline | Statutory computation order, each stage appends LineItems |
| Value object | GstHeads, Slab, SurchargeBand (immutable, arithmetic operators) |
| Repository | DraftStore for on-device drafts |
| Facade | ItrComputer.compare, Gstr3bComputer.compute |
| Template method | ExplanationBuilder / AssistantBrain: numbers from engine, prose from templates |
| Shared kernel | tax_engine package compiled into app and server |

## Architecture
```text
┌──────────────────────── Flutter app (iOS / Android / web) ───────────────────────┐
│ taxos_ui (Evergreen) · Riverpod · go_router + auth guard · drafts · secure store │
│                      ┌──────────── tax_engine (pure Dart) ────────────┐           │
└──────────────────────┼─────────────────────────────────────────────────┼───────────┘
                       │  identical package                              │
┌──────────────────────┼───────────── API service (Dart shelf) ──────────┼───────────┐
│ /v1/auth/* /v1/itr/* │  authoritative compute, explain, form           │           │
│ outbox → filing jobs │  ERI (ITD)  ·  GSP (GSTN)  ·  payments  ·  OCR  │           │
│ Postgres · Redis · object storage · KMS field encryption · audit log               │
└────────────────────────────────────────────────────────────────────────────────────┘
```

Modular monolith by design: module seams (identity, documents, itr, gst, tds, payments, expert-review) are the future service boundaries. Only the filing pipeline is asynchronous from day one, because ITD/GSTN calls are slow, rate-limited and flaky, so each submission is a durable, idempotent job.

## Scale Plan
| Stage | Users | What changes |
|---|---|---|
| 0 | 0–10k | One region (Mumbai), managed Postgres, Redis, single autoscaling service, job queue |
| 1 | 10k–1M | Read replicas, calendar-based pre-scaling before deadlines, per-tenant rate limiter in front of ERI/GSP quotas, CDN, compute service scaled separately |
| 2 | 1M–10M | Shard Postgres by user id, Kafka outbox, split GST and ITR along module seams, multi-AZ with standby region, warehouse for analytics |

Market context: ~9 crore ITR filers, ~1.5 crore GST registrations; the largest incumbent has ~7M users. Year-one design target is 1M registered, ~200k filings in the peak week, ~50k concurrent at the peak hour.

## Concurrency
- Engine is pure and stateless; safe to run in isolates and across server workers.
- Draft edits are last-write-wins on device, versioned on sync.
- Filing jobs use idempotency keys (PAN + AY + attempt) so retries never double-submit.
- ERI/GSP quotas are shared resources: a token-bucket limiter per credential, queue depth exposed as a health metric.

## Interview Navigation
**Why a shared Dart engine instead of a server-only one?** Instant what-if on device, offline drafting, and a single source of truth. The server re-runs the same package before filing so there is nothing to reconcile.

**Why not an LLM for the tax maths?** Tax is deterministic and auditable; a model may rephrase but must never originate a number. The assistant is templated on engine output; a model layer wraps it for tone.

**Why a modular monolith first?** Small team, fast iteration, and the seams are already drawn for later extraction. Seasonal spikes are handled by horizontal scaling of a stateless service, not by microservices.

**What can't be replaced?** Tax audit sign-off under s.44AB and representation before an assessing officer. The product routes those to a CA marketplace rather than pretending.

## Complexity
| Operation | Time | Space |
|---|---|---|
| ItrComputer.compute | O(slabs + properties + gains + deductions) ≈ O(1) | O(line items) |
| Gstr3bComputer.compute | O(supplies) | O(1) |
| Gstr2bReconciler.reconcile | O(books + statement) with hash map | O(statement) |

## Final Summary
Engine-first product: a versioned, deterministic, provenance-carrying tax engine shared by a Flutter app and a thin Dart API. Start as a modular monolith in Mumbai sized for 1M users and the deadline spike, with sharding and module extraction as the path to 10M.
