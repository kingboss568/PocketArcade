# Screenshot Plan

Required capture devices from AGENTS.md:

- iPhone 17 Max / Pro Max 6.9-inch portrait and landscape where relevant.
- iPad Pro 13-inch portrait and landscape where relevant.

## Six App Store Frames

1. Main arcade cabinet grid: show 10 game cards, neon visual identity, free/premium split.
2. Brick Blitz gameplay: paddle, ball, bricks, score HUD.
3. Snake EVO gameplay: grid snake, food, score HUD.
4. Premium unlock screen: `$2.99` unlock all, `$1.99` remove ads.
5. Scoreboard and export: SwiftData progress + CSV/PDF export preview.
6. Arcade Coach fallback: show 「AI 功能目前不可用」 plus evidence/RAG note.

## Command Template On Mac

```bash
xcodebuild -scheme PocketArcade -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build
xcrun simctl io booted screenshot Screenshots/iphone17max-main.png
xcodebuild -scheme PocketArcade -destination 'platform=iOS Simulator,name=iPad Pro 13-inch' build
xcrun simctl io booted screenshot Screenshots/ipad13pro-main.png
```

If simulator marketing names differ in the installed Xcode, use the available 6.9-inch iPhone 17-class device and iPad Pro 13-inch equivalent.
