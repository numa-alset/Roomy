# frontend Realtime Voice Chat + AI Assistant (Flutter)

Flutter client for a **real-time voice chat + AI assistant**. It showcases:
- Mock **login**
- **Text chat** over Socket.IO with **SQLite** persistence
- **Voice calls** with **WebRTC (audio-only)** using free STUN
- **AI voice**: record → upload to backend → **STT → LLM → TTS** → playback
- Clean Architecture + Riverpod + Dio
---

## Quick start

1. **Install Flutter 3.x**
   ```bash
   flutter --version
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run (Android emulator)**
   ```bash
   # Android emulator reaches your host via 10.0.2.2
   flutter run -d emulator-5554 \
     --dart-define=BACKEND_URL=http://10.0.2.2:3001
   ```

4. **Run (physical Android device)**
   ```bash
   # Replace with your host LAN IP
   flutter run -d <device-id> \
     --dart-define=BACKEND_URL=http://192.168.x.y:3001
   ```

5. **Run (iOS)**
   ```bash
   # Use your Mac’s LAN IP; ensure Info.plist ATS dev exception or use HTTPS
   flutter run -d <ios-simulator-or-device-id> \
     --dart-define=BACKEND_URL=http://<your-mac-ip>:3001
   ```

---

## Features

- **Auth:** mock login calls backend and stores JWT in memory (Riverpod).
- **Chat:** Socket.IO client; send `{to, text}`; receive persisted messages; local store in SQLite.
- **AI:** Record mic (AAC), upload via Dio multipart with progress; plays returned TTS MP3.

---

## Tech stack

- **State & DI:** flutter_riverpod  
- **HTTP:** dio (+ retry, logger, JWT interceptor)  
- **Realtime:** socket_io_client  
- **WebRTC:** flutter_webrtc  
- **Local DB:** sqflite (+ path_provider)  
- **Audio:** record (capture), just_audio (playback)  
- **Navigation:** go_router

---

## Project structure (Clean Architecture)

```
lib/
├─ app/                    # router, app shell, theme
├─ core/                   # reusable (no feature deps)
│  ├─ env/                 # BACKEND_URL, STUN_URL
│  ├─ error/               # Failure
│  ├─ functional/          # Result<Err,Ok>
│  ├─ log/                 # light logger
│  ├─ network/             # Dio client wrapper
│  ├─ providers/           # global Riverpod providers (token, userId, Dio)
│  └─ storage/             # SQLite init
├─ shared/                 # shared widgets, theme
└─ features/
   ├─ auth/ (domain|data|presentation)
   ├─ chat/ (domain|data|presentation)   # WebRTC + signaling Socket + chat Socket + SQLite
   └─ ai/   (domain|data|presentation)   # record → upload → play TTS
```

---

## Configuration

Runtime config via **`--dart-define`**:

- `STUN_URL` (optional): default `stun:stun.l.google.com:19302`

Example:
```bash
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:3001 \
            --dart-define=STUN_URL=stun:stun.l.google.com:19302
```

---

## Permissions

### Android — `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<!-- Dev only (HTTP) -->
<!-- <application android:usesCleartextTraffic="true"
     android:networkSecurityConfig="@xml/network_security_config"> -->
```

Create `android/app/src/main/res/xml/network_security_config.xml` (dev only) to allow cleartext HTTP.

### iOS — `ios/Runner/Info.plist`
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone is needed for voice chat and voice queries.</string>

<!-- Dev only if using HTTP -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key><true/>
</dict>
```

---

## How to use (demo flow)

1. **Login**: enter a username (e.g., `alice`). Backend upserts, returns JWT.
2. **Chat**: Enter any room and start chat and voice with ur peers.
4. **AI**: open AI page → **Start Recording** → speak → **Stop & Send**. See transcript and hear TTS.

> Emulators can be flaky for audio. If you don’t hear anything, try a physical device.

---

## Commands

Analyze & tests:
```bash
dart analyze
flutter test
```

Build Android debug APK:
```bash
flutter build apk --debug \
  --dart-define=BACKEND_URL=http://10.0.2.2:3001
```

(Release signing: set up `key.properties` & `build.gradle` per Flutter docs.)

---

## Troubleshooting

- **Cannot reach backend on Android emulator**  
  Use `http://10.0.2.2:3001` (not `localhost`).

- **HTTP blocked (Android)**  
  Enable `usesCleartextTraffic="true"` and `network_security_config.xml` (dev only). Prefer HTTPS for prod.

- **HTTP blocked (iOS)**  
  Add ATS exception (dev only) or use HTTPS.

- **No audio on emulator**  
  Test on a physical device or ensure emulator mic/speaker enabled.

- **WebRTC not connecting**  
  STUN-only can fail across strict NATs. Test on the same Wi-Fi; TURN is out of scope.

- **Multipart field mismatch**  
  Backend expects field `file` by default. If you changed it server-side, update the client DS.

- **JWT not attached**  
  Ensure you set token in Riverpod after login; Dio interceptor reads it dynamically.

---

## Notes on design

- **Dio-only** networking with a single `DioClient` (JWT interceptor, retries, progress).
- **SocketService** abstraction so Chat & voice share the same eventing style.
- **Clean Architecture**: domain (entities/usecases) is UI-agnostic; data (DS/DTO) is infra-aware; presentation is Riverpod + UI.
- **SQLite** keeps chat history offline; swap to SQLCipher easily if needed.

---

## License
MIT
