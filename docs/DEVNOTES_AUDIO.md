# Audio Diagnostics & Session Timer Chime

## Log Format

All audio/timer events are emitted via `dart:developer` `log()` with the name `APP`. Each line is structured as:

```
[APP][<CATEGORY>][<timerId>] name=<EVENT> level=<LEVEL> ts=<ISO8601> {k=v,...}
```

Example timeline for the session timer:

```
[APP][TIMER][6f2f6b2d-...] name=TIMER_START level=INFO ts=2025-10-05T10:00:00.000Z {tStart=2025-10-05T10:00:00.000Z, tEnd=2025-10-05T10:03:00.000Z, tChime=2025-10-05T10:02:57.000Z, durationSec=180, remainingSec=180}
[APP][AUDIO][6f2f6b2d-...] name=AUDIO_INIT_START level=INFO ts=... {assetPathRaw=audio/session_timer_end.wav, assetKey=audio/session_timer_end.wav, pubspecPath=assets/audio/session_timer_end.wav}
[APP][AUDIO][6f2f6b2d-...] name=AUDIO_DURATION level=INFO ts=... {seconds=3.002}
[APP][TIMER][6f2f6b2d-...] name=CHIME_SCHEDULED level=INFO ts=... {now=2025-10-05T10:02:57.001Z, deltaToEndMs=2999, assetKey=audio/session_timer_end.wav}
[APP][AUDIO][6f2f6b2d-...] name=AUDIO_COMPLETE level=INFO ts=... {assetKey=audio/session_timer_end.wav}
[APP][TIMER][6f2f6b2d-...] name=TIMER_END_REACHED level=INFO ts=... {tEnd=2025-10-05T10:03:00.001Z}
[APP][TIMER][6f2f6b2d-...] name=NAVIGATE_AFTER_AUDIO level=INFO ts=... {reason=completed}
```

## Verbose Logging Flag

Verbose audio logging is controlled by the compile-time flag `AUDIO_VERBOSE_LOGS` (defaults to `true`). To disable the detailed logs in release builds, pass `--dart-define=AUDIO_VERBOSE_LOGS=false` to `flutter run`/`flutter build`.

## Smoke Test Screen

* Location: Admin Dashboard → **Audio Smoke Test** tile.
* Action: Tap **Play Chime** to execute the same pipeline as the session timer.
* Expectation: The terminal prints the `AUDIO_*` timeline and the UI updates the last timerId, status, state, duration, and position.

## Manual Verification Steps

1. `flutter clean && flutter pub get`
2. Run on iOS Simulator (e.g. iPhone 15, iOS 17).
3. Navigate to Admin Dashboard → Audio Smoke Test → press **Play Chime**.
   * Observe the log order: `AUDIO_CTX_SET`, `AUDIO_INIT_OK`, `ASSET_VALIDATED`, `AUDIO_DURATION`, `AUDIO_PLAY_ATTEMPT`, optional `AUDIO_FALLBACK`, `AUDIO_STATE`, progressive `AUDIO_POSITION`, `AUDIO_COMPLETE`.
4. Repeat on a physical iOS device.
5. Full timer flow: start a workout session, confirm `TIMER_START`, `CHIME_SCHEDULED` (T−3 s), audio events, `TIMER_END_REACHED`, then `NAVIGATE_AFTER_AUDIO` only after `AUDIO_COMPLETE` (or timeout).
