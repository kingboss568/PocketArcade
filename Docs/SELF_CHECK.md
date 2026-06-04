# Self Check Log

## Pass 1 - Build, Types, Imports, Previews

- Windows environment has no `swift` or `xcodebuild`; Mac compile is required.
- Static checks validate file presence, plist XML, JSON seeds, asset metadata, and project references.

## Pass 2 - Data, Deterministic Logic, AI Fallback, Errors

- Seed data includes 10 games and source trace fields.
- 2048 and Gomoku have deterministic services and unit tests.
- StoreKit entitlements are deterministic through `EntitlementResolver`.
- AI fallback returns 「AI 功能目前不可用」.

## Pass 3 - UI, Store Docs, Disclaimer, Seed, Tests, README

- Neon arcade visual direction, onboarding, empty state, paywall, scoreboard, settings, and screenshot plan included.
- README, TODO_PHASE_2, App Store copy, privacy policy, nutrition label draft, and review notes included.
