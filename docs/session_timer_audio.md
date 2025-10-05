# Session Timer Audio Setup

The session timer uses the `TimerChimePlayer` service to play a short chime when the countdown completes. The application code expects a WAV file at `assets/audio/session_timer_end.wav`, but the binary is not tracked in version control. Follow the checklist below to enable the sound in your build.

## 1. Prepare the audio asset

1. Create or source a concise (≈ 3 second) notification-style chime in WAV format. The clip should be optimised for low latency and avoid long fades so that the cue begins crisply and can finish as the countdown reaches zero.
2. Verify that your chosen audio is licensed for your intended distribution. Keep the license text alongside the asset if attribution is required.
3. Normalise the audio to avoid clipping while ensuring it remains audible on quiet devices. A peak level of −3 dBFS is typically sufficient.

## 2. Place the asset in the project

1. Create the directory `assets/audio/` if it does not already exist.
2. Save the WAV file as `session_timer_end.wav` inside that directory. The final path should be:

   ```
   assets/audio/session_timer_end.wav
   ```

## 3. Declare the asset in `pubspec.yaml`

Add the file to the Flutter asset list so it is bundled at build time. The relevant section should contain an entry similar to:

```yaml
flutter:
  assets:
    # …existing assets…
    - assets/audio/session_timer_end.wav
```

## 4. Update packages and rebuild

1. Run `flutter pub get` to ensure the `audioplayers` dependency is installed.
2. Rebuild the application. Three seconds before the session timer completes, you should now hear the audio cue alongside the existing haptic feedback and system click that trigger at completion.

If the sound does not play, check the debug console for log statements from `TimerChimePlayer`—they will indicate whether the asset is missing or if playback failed on the target platform.
