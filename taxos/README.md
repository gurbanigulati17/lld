# Kardo

*Taxes, kar do.* ITR and GST filing for India, from a salaried ITR-1 to capital gains, presumptive business and GSTR-3B, built in Flutter with the Evergreen theme: warm off-white ground, forest-green serif headings, white rounded cards and plain-English sentences in place of dashboards. The design goal is to replace the chartered accountant for the ~90% of filers who do not need an audit sign-off, and to explain every rupee rather than just compute it.

## Layout

```text
taxos/
  packages/tax_engine   pure-Dart rules engine (no Flutter): ITR, interest, forms, GST
  packages/taxos_ui     design system: Evergreen tokens, Source Serif 4 / Source Sans 3, cards, row fields, pill buttons
  apps/taxos_app        Flutter app (Android, iOS, web)
  services/api          Dart shelf service exposing the same engine over HTTP
  tool/ci.sh            everything CI runs, in one script
```

The engine is the product. The app runs it on-device for instant what-if and offline drafting; the API runs the identical package for the authoritative pre-filing computation, so the two can never disagree.

## Run it

```bash
cd taxos
flutter pub get
make test                # engine, API, design system and app tests
make run-api             # http://localhost:8080
make run-web             # flutter run -d chrome
make build-web           # release build in apps/taxos_app/build/web
```

`tool/ci.sh engine` runs only the pure-Dart engine and API checks (fast). The Flutter tool is still needed to resolve the workspace.

## Sign-in

The app runs in one of two modes, chosen at build time:

| Build | Sign-in |
|---|---|
| default (no `KARDO_API_URL`) | Demo: the 6-digit code is generated on the phone and shown on screen. Nothing leaves the device. |
| `--dart-define=KARDO_API_URL=https://api.example.in` | Real: the API sends an OTP, verifies it and issues a signed 30-day token. |

The API needs `TAXOS_AUTH_SECRET` (base64, at least 32 bytes). `TAXOS_DEV_OTP=1` returns the code in the response for local testing; never set it in production. OTPs are stored hashed, expire after 5 minutes, allow 5 attempts, and can be resent after 30 seconds.

## Engine in 30 seconds

```dart
final input = ItrInput(
  assessmentYear: AssessmentYear.ay2026_27,
  profile: TaxpayerProfile(dateOfBirth: DateTime(1990, 5, 1)),
  salary: const SalaryIncome(basic: 600000, otherTaxableComponents: 675000),
);
final cmp = const ItrComputer().compare(input);
print(cmp.recommended);                       // TaxRegime.newRegime
print(cmp.best.totalTaxLiability);            // 0  (₹12.75L salary is tax-free in FY 2025-26)
print(selectForm(input, totalIncome: cmp.best.totalIncome).form); // ItrForm.itr1
for (final line in cmp.best.lineItems) print(line); // SAL.GROSS, SAL.STD_DED, TI, TAX.REBATE …
```

Every number carries a `LineItem` with its statutory section, so the UI and the assistant can show provenance instead of a bare total.

## What is implemented

| Area | Coverage |
|---|---|
| Assessment years | AY 2025-26 and AY 2026-27 as separate immutable rule packs |
| Regimes | Old and new (s.115BAC), side-by-side comparison, recommendation |
| Salary | HRA exemption, s.10(14) allowances, standard deduction, professional tax, employer NPS |
| House property | Self-occupied cap, let-out NAV / 30% / interest, loss set-off rules per regime |
| Capital gains | s.111A, s.112A with ₹1.25L exemption, s.112, intra-head loss set-off, basic-exemption absorption |
| Business | Books of account, s.44AD (8% / 6% digital), s.44ADA |
| Other sources | Interest, dividends, family pension deduction, agricultural income integration |
| Deductions | 80C, 80CCD(1B), 80CCD(2), 80D, 80E, 80G, 80EEA, 80U, 80TTA/80TTB with caps |
| Tax | Slabs by age, s.87A with marginal relief, surcharge with 15% cap and marginal relief, cess, s.288A/B rounding |
| Interest | ss.234A, 234B, 234C including presumptive single instalment and 12%/36% tolerance |
| Forms | ITR-1 / 2 / 3 / 4 eligibility with reasons |
| GST | GSTR-3B with Rule 88A set-off, late fee caps, s.50 interest; GSTR-2B reconciliation; registration and composition advice |
| Sign-in | Phone OTP, 30-day signed session in secure storage, sign out (revokes the token and clears drafts) |
| Late filing | s.234F fee (₹1,000 / ₹5,000), belated-return last date, warnings |
| App | Dashboard, 8-section ITR with live liability, "How we got your tax" ledger, filing checklist, GST, assistant |
| API | `/health`, `/v1/auth/{otp/request,otp/verify,me,logout}`, `/v1/itr/{compute,compare,form}`, `/v1/gst/{gstr3b,reconcile,registration}` |

## What is not yet implemented

- ERI submission to the Income Tax Department and GSP connectivity to GSTN (the API has the seams; credentials and partner onboarding are external).
- Document ingestion: Form 16 / AIS / broker P&L parsing. The capital-gains screen shows where it plugs in.
- ITR-5/6/7, Schedule FA detail, dividend surcharge carve-out, s.234C relief for late-arising gains.
- Encrypted on-device storage for drafts (the session token is in secure storage; drafts still sit in shared preferences).
- An SMS gateway for OTPs. The API ships a logging sender; plug in a provider behind `OtpSender`.
- A language-model layer over the assistant. The assistant is template-based on purpose: it never produces a number the engine did not.

## Tests

Golden cases in `packages/tax_engine/test` were hand-worked from the Finance Act 2025 and compared with the department's published examples. A change to any expectation needs a statutory citation in the commit message.
