# AI Buzz Feed

A cross-platform (Android + iOS) app that collects the latest feature rollouts and
updates for the major AI models in one feed:

| Model   | Company   | Sources                                   |
|---------|-----------|-------------------------------------------|
| Claude  | Anthropic | Google News (launch/release/rollout news) |
| ChatGPT | OpenAI    | OpenAI News RSS + Google News             |
| Gemini  | Google    | Google AI Blog RSS + Google News          |
| Grok    | xAI       | Google News                               |

Features: filter by model, search, pull to refresh, de-duplicated headlines, light/dark
mode. Tap a story to open it in the browser.

Built with [Expo](https://expo.dev) (React Native, TypeScript), so one codebase ships to
both stores.

## Run locally

```bash
npm install
npm start          # scan the QR code with Expo Go on Android or iPhone
npm run typecheck
```

## Build & release (EAS)

```bash
npm install -g eas-cli
eas login
eas init                 # links the project to your Expo account

npm run build:preview    # installable test builds (Android APK + iOS internal)
npm run build:android    # Play Store bundle (.aab)
npm run build:ios        # App Store build (needs an Apple Developer account)

eas submit --platform android
eas submit --platform ios
```

Bundle ID / package: `com.stackcone.aibuzzfeed` (change in `app.json` before the first
store submission if you want a different one).

## Adding sources

Edit `src/sources.ts`. Any RSS 2.0 or Atom feed works — add an entry with the model it
belongs to.

## Project layout

```
App.tsx          UI: header, model filter chips, search, feed list
src/sources.ts   Providers (name, colour) and feed URLs
src/feed.ts      Fetching, RSS/Atom parsing, de-duplication, sorting
eas.json         Build profiles for Android and iOS
```
