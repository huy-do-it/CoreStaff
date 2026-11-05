# Flutter Mobile — Handoff Checklist (Web done, phần còn lại cho team)

> **Ngày tạo:** 2026-11-05
> **Phạm vi đã làm:** bản **dev web (`flutter run -d web-server`)** chạy đúng nghiệp vụ. Native (Android/iOS) **chưa verify**.
> **Trạng thái kỹ thuật hiện tại:** `flutter analyze` → 0 issue; `flutter test` → 354/354 pass (51 suites).
> **Cách dùng:** tick từng ô. Mỗi ô ghi rõ file/đường dẫn để khỏi phải dò lại.

---

## 0. Đã hoàn thành (không cần làm lại)

- [x] **SDK pin chặn toàn bộ tooling** — `pubspec.yaml`: `sdk: ^3.13.1` → `^3.12.0`. `pubspec.lock` sinh lại, 13 package transitive bị hạ version.
- [x] **Selfie upload trên web** — `MultipartFile.fromFile` ném `UnsupportedError` vì ảnh web là blob URL. Đổi `String? selfiePath` → `Uint8List? selfieBytes` ở: `lib/features/attendance/data/models/punch_request_payload.dart`, `data/services/camera_service.dart`, `data/attendance_repository.dart`, `domain/services/punch_coordinator.dart`.
- [x] **Silent refresh trên web** — `lib/core/network/auth_interceptor.dart`: bỏ guard `cookieManager.hasRefreshToken` khi `kIsWeb` (browser giữ `rt` HttpOnly, app không đọc được); gọi refresh bằng `withCredentials` thay vì header `Cookie` (browser cấm header này).
- [x] **Socket.io auth trên web** — `lib/core/services/socket_service.dart`: `enableWithCredentials()` khi `kIsWeb`.
- [x] **Viewport mobile** — `web/index.html` (meta viewport, title, theme-color `#2563EB`).

**Bằng chứng đã verify trên web (headless Brave + CDP, `http://localhost:8099`):**
- Login 201 → `/api/auth/me` 200 → `/api/attendance/today` 200; cả 5 tab render dữ liệu seed thật.
- Refresh: xoá `sid` giữ `rt` → reload → `/auth/me` 401 → `POST /auth/refresh` → `/auth/me` 200 → `sid` cấp lại. Chỉ **một** lần refresh cho 2 request 401 song song (`QueuedInterceptor` tự serialize).
- Socket: `ws://localhost:3000/socket.io/?EIO=4&transport=websocket` → `101` → `40/events,{"sid":...}` (server chấp nhận; thiếu cookie thì server trả `41/events`).

---

## 1. Chặn release — phải sửa trước khi build native

- [ ] **iOS: thiếu Access WiFi Information entitlement** → Tier 1 (Wi-Fi BSSID) **chắc chắn fail trên iOS**.
  - Chưa có `ios/Runner/Runner.entitlements`, `project.pbxproj` không có `CODE_SIGN_ENTITLEMENTS`.
  - Cần: tạo `Runner.entitlements` với `com.apple.developer.networking.wifi-info` = true, gắn vào target Runner (cả Debug/Release/Profile), bật capability "Access WiFi Information" trên Apple Developer portal.
  - `NSLocalNetworkUsageDescription` trong `Info.plist` **không** đủ để đọc SSID/BSSID trên iOS 13+.
- [ ] **iOS: kiểm tra ATS cho API local** — `ios/Runner/Info.plist` không có `NSAppTransportSecurity`. Dart dùng `dart:io` socket nên thường không bị ATS chặn, nhưng nếu chuyển sang client dựa trên `NSURLSession` (hoặc gọi qua WebView) thì `http://localhost:3000` sẽ fail. Thêm `NSAllowsLocalNetworking = true` cho build dev nếu gặp lỗi kết nối.
- [ ] **Release signing còn dùng debug key** — `android/app/build.gradle.kts:32-38` (`signingConfig = signingConfigs.getByName("debug")`, có TODO). Cần keystore riêng + `key.properties` (git-ignore).
- [ ] **Application ID còn placeholder** — `android/app/build.gradle.kts:18-19`: `com.corestaff.corestaff_mobile` kèm TODO. Chốt ID thật trước khi publish (đổi sau khi lên store là không được).
- [ ] **Tên app chưa branding** — `android/app/src/main/AndroidManifest.xml:10`: `android:label="corestaff_mobile"`; `ios/Runner/Info.plist`: `CFBundleDisplayName = Corestaff Mobile`. Đổi thành `CoreStaff`.
- [ ] **API base hardcode, không override được** — `lib/core/config/app_constants.dart:26`: `defaultRemoteUrl = 'https://18-141-68-40.sslip.io'`, không có `String.fromEnvironment`/`--dart-define`. Cần thêm `--dart-define=API_BASE_URL=...` để build staging/prod không phải sửa code.
- [ ] **Release mode không có fallback** — `lib/core/config/api_config.dart:106-113`: `!kDebugMode` thì probe remote, fail là ném lỗi → app kẹt ở ConnectionErrorScreen nếu remote chết. Quyết định: giữ nguyên (fail-fast) hay cho phép retry/đổi URL.
- [ ] **CI chưa chạy Flutter** — `CoreStaff/.github/workflows/ci.yml` chỉ có Node (api/web): `npm ci → lint → build → test`. Không có job `flutter analyze` / `flutter test`. Thêm job Flutter để chặn regression 354 test.
- [ ] **Android licenses chưa accept** (`flutter doctor`): `flutter doctor --android-licenses`.
- [ ] **Chrome chưa cấu hình** (`flutter doctor`): cần `CHROME_EXECUTABLE` nếu muốn `flutter run -d chrome`. Không ảnh hưởng `-d web-server`.
- [ ] **App icon vẫn là icon Flutter mặc định** — `android/app/src/main/res/mipmap-*/ic_launcher.png`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- [ ] **Bundle/version chưa chốt** — `pubspec.yaml`: `version: 1.0.0+1`.

---

## 2. Verify trên máy thật (web không test được)

Chi tiết kịch bản đã có sẵn trong `Docs/FLUTTER_MIGRATION_FINAL_REPORT.md` §8. Dưới đây là phần **chưa ai chạy**:

- [ ] **Tier 1 — Wi-Fi BSSID**: `wifi_service.dart` **không xin quyền** ở đâu cả; `location_service.hasPermission()` chỉ được gọi ở Tier 2 (`punch_coordinator.dart:171`), tức **sau** Tier 1 (dòng 131-164). Trên Android 10+ đọc BSSID cần `ACCESS_FINE_LOCATION` đã cấp runtime → lần chấm công đầu tiên trên máy mới cài sẽ trả Wi-Fi rỗng, punch rơi xuống Tier 2 rồi mới xin quyền. Cần xin quyền trước Tier 1 (hoặc chấp nhận degrade và ghi rõ).
- [ ] **Tier 2 — GPS geofence** (`location_service.dart`): xin quyền, sai số, ngoài geofence.
- [ ] **Tier 3 — Selfie camera thật** (`camera_service.dart`): camera trước, từ chối quyền → phải ra `CAMERA_PERMISSION_DENIED` với câu "Cần quyền camera..."; huỷ chụp → `PunchCoordinatorCancelled`.
- [ ] **Branch A — OUT_OFFICE**: vào thẳng selfie, không chạy Wi-Fi/GPS.
- [ ] **Idempotency**: double-tap "Vào ca" → chỉ 1 bản ghi. UI đã chặn tap khi state là `PunchSubmitting`/`PunchDetectingEnvironment`/`PunchPromptSelfie` (`attendance_screen.dart:326`), nhưng **Idempotency-Key vẫn sinh mới mỗi lần gọi** (`attendance_repository.dart:94` `_uuid.v4()`; `PunchCoordinator` gọi repository 3 lần khi waterfall fail, mỗi lần một key khác). Bản Expo cũng sinh key mới mỗi lần (`Apps/mobile/src/employee-api.ts:193`) → hiện tại key chỉ chống double-submit **cùng một HTTP request**, không chống double-punch khi waterfall retry. Xác nhận server có chặn punch trùng theo thời gian/action, nếu không thì truyền cùng key cho 3 lần fallback.
- [ ] **Lifecycle**: background <15s khi đang chụp selfie → không reload; >15s → silent refresh; throttle 5s.
- [ ] **Socket trên native**: cookie phải đi qua `setExtraHeaders({'cookie': ...})` (nhánh non-web của `socket_service.dart:101-103`) → xác nhận namespace `/events` connect được.
- [ ] **Logout/relogin native**: `SecureStorageService` xoá `sid`/`rt`; kill app rồi mở lại phải về Login.
- [ ] **Forced password change**: tài khoản `mustChangePassword` → không cancel được.
- [ ] **Role trapping**: login bằng `HR` / `SYSTEM_ADMIN` → ra `UnauthorizedRoleScreen` (SCR-007).

---

## 3. Chưa làm — quyết định scope

- [ ] **Deep link cho reset password** — grep không thấy `app_links`/`uni_links`, `AndroidManifest.xml` không có deep-link `intent-filter`, `Info.plist` không có `CFBundleURLTypes`. Hiện user **phải copy token dán tay** vào `reset_password_screen.dart:19`. Doc MIG-06 ghi "Deep link handling in Sprint 6" nhưng chưa có.
- [ ] **PDF export phiếu lương** — MIG-10 ghi "deferred", không có package/impl.
- [ ] **Avatar upload** — MIG-09 ghi "not in mobile scope".
- [ ] **2FA** — MIG-05 ghi "disabled in current mobile scope".
- [ ] **Periodic connectivity polling** — MIG-04 ghi "periodic connectivity polling" là next action; hiện chỉ check lúc bootstrap.
- [ ] **Typography scaling đầy đủ** — MIG-02 next action.

---

## 4. Dọn code (không gấp, nhưng nên làm trước khi mở rộng)

- [ ] **Xoá 1.042 dòng code chết** (đã grep: chỉ self-reference, không file nào ngoài nhóm này import):
  - `lib/screens/main_shell_screen.dart` (126) — bản cũ; bản thật là `lib/features/shell/presentation/screens/main_shell_screen.dart`
  - `lib/screens/overview/overview_tab.dart` (330)
  - `lib/screens/account/account_tab.dart` (280)
  - `lib/screens/attendance/attendance_tab.dart` (19)
  - `lib/screens/requests/requests_tab.dart` (19)
  - `lib/widgets/bottom_tab_bar.dart` (124)
  - `lib/widgets/feature_screen.dart` (144)
  - ⚠️ **Không xoá** `lib/screens/auth/*`, `lib/screens/splash/*`, `lib/widgets/{app_logo,auth_layout,banners,buttons,fields}.dart` — `lib/app.dart` vẫn dùng (login/forgot/reset/change-password/splash chưa migrate sang `features/`).
- [ ] **Bỏ 2 dependency không dùng** — `pubspec.yaml`: `http: ^1.2.0` (0 import), `shared_preferences: ^2.5.6` (0 import).
- [ ] **Doc bị nhân đôi** — 13 file `FLUTTER_*.md` tồn tại ở cả `Docs/` và `CoreStaff/Docs/` (nội dung gần giống, `CoreStaff/Docs` thiếu `FLUTTER_MIGRATION_GUIDE.html`). Chọn 1 nơi làm chuẩn rồi xoá bản còn lại. `PROJECT_CONTEXT.md:135` coi `Docs/` là chuẩn; `Apps/mobile_flutter/README.md` lại link `../../Docs/` = `CoreStaff/Docs/`.
- [ ] **Số liệu doc lệch** — `FLUTTER_MIGRATION_PROGRESS.md` §6.2 ghi **349 tests**, final report ghi **354**; cả hai còn path máy cũ `D:\dev\flutter\bin\flutter.bat` và `d:\FPTU\...`. Cập nhật lại 354 + path tương đối.

---

## 5. Môi trường chạy dev web (để team tái lập)

```bash
cd CoreStaff/Apps/mobile_flutter
flutter pub get
flutter run -d web-server --web-port 8099      # KHÔNG dùng -d chrome nếu chưa set CHROME_EXECUTABLE
```

- Backend: `localhost:3000` (dev mode `ApiConfig.resolveApiBase()` fallback về local khi remote fail).
- **Mở bằng `http://localhost:8099/`**, không dùng `http://127.0.0.1:8099/` — cookie `sid`/`rt` set cho host `localhost`, host `127.0.0.1` là origin khác → login 201 nhưng mọi API sau đó 401.
- Tài khoản seed: `nv.kinh-doanh.1@anphat.local` / `Demo123456!`.
