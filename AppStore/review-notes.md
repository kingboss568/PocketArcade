# App Review Notes

- The first three games are free: Brick Blitz, Snake EVO, Stack Attack.
- Premium games are gated by `net.boss888.pocketarcade.unlockall`.
- Remove ads product ID: `net.boss888.pocketarcade.removeads`.
- This handoff build does not include the GoogleMobileAds SDK; ad UI is protocol-gated and can stay hidden until a real provider is added.
- AI Coach currently demonstrates the required unavailable fallback and does not call an external AI service.
- Game Center requires leaderboards named with `pocketarcade_<gameID>`.
