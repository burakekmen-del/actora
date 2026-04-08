# Deferred Link Setup (Firebase Hosting)

Bu repo, invite/deferred link fallback icin Firebase Hosting + Cloud Functions akisini kullanir.

## Domain stratejisi (actora.app yoksa)

`hatirlatbana.com` kullanabilirsin, ama farkli bir uygulamada zaten App/Universal Link aktifse cakisma riski olur.
En temiz yol: invite akisi icin ayri bir subdomain ayirmak.

Onerilen:
- `invite.hatirlatbana.com` -> bu uygulama (Actora)
- `hatirlatbana.com` -> diger uygulama/landing

Bu secimde su dosyalardaki host degerleri ayni domain olacak sekilde guncellenmeli:
- `ios/Runner/Runner.entitlements`
- `android/app/src/main/AndroidManifest.xml`
- `web/.well-known/apple-app-site-association`
- `web/.well-known/assetlinks.json`
- `lib/services/viral/invite_backend_service.dart`

## 0) Local E2E test (301 hatasini bypass)

Logdaki `Invite backend request failed. (301)` hatasi, domain yanlış yapılandırılmış olabilir veya redirect etmesinden gelir.

Invite akisini lokal test etmek icin:

```bash
firebase emulators:start --only firestore,hosting,functions
```

Ilk acilista emulator su degerleri sorabilir:
- `APPLE_BUNDLE_ID`
- `GOOGLE_PACKAGE_NAME`

Gelistirme icin ikisine de su degeri girebilirsin:

```text
com.example.actora
```

Bu sorularin her acilista cikmamasi icin `functions/.env.local` olustur:

```bash
cat > functions/.env.local <<'EOF'
APPLE_BUNDLE_ID=com.example.actora
GOOGLE_PACKAGE_NAME=com.example.actora
WEB_FALLBACK_BASE_URL=http://127.0.0.1:5002
APP_DEEP_LINK_URL=actora://today
EOF
```

Ardindan uygulamayi emulator API base URL'i ile calistir:

```bash
flutter run \
  --dart-define=ACTORA_VIRAL_API_BASE_URL=http://127.0.0.1:5002

# Profesyonel detayli terminal logu icin
flutter run \
  --dart-define=ACTORA_VIRAL_API_BASE_URL=http://127.0.0.1:5002 \
  --dart-define=ACTORA_LOG_LEVEL=trace
```

Fiziksel cihazda (gercek iPhone/Android) `127.0.0.1` cihazin kendisini isaret eder;
bu durumda Mac'in LAN IP'sini kullan:

```bash
ipconfig getifaddr en0
flutter run \
  --dart-define=ACTORA_VIRAL_API_BASE_URL=http://<MAC_LAN_IP>:5002
```

Onemli: LAN IP degisebilir (wifi degisimi, hotspot, yeniden baglanti).
Her oturumda `ipconfig getifaddr en0` ile guncel IP'yi tekrar al.

Alternatif olarak Functions emulatoruna dogrudan gidebilirsin:

```bash
flutter run \
  --dart-define=ACTORA_VIRAL_API_BASE_URL=http://<MAC_LAN_IP>:5001/actora-70647/us-central1/viralApi
```

Not: `:5002` (Hosting emulator) kullanirken base URL sonuna `.../us-central1/viralApi` ekleme.
Bu path Hosting rewrite eslesmesine girmez ve API yerine `index.html` donebilir.

Beklenen:
- Share ekraninda `share.invite.backend_failed` logu gorunmez.
- Invite olusturma ve kabul etme endpointleri 2xx doner.

Not:
- Bu local testte Universal Link yerine custom scheme (`actora://...`) ile acis beklenir.
- Gercek domain testi icin once `hosting,functions:viralApi` deploy edilmelidir.
- Eger Hosting emulatoru 5000 yerine baska port acarsa (`5002` gibi), dart-define icindeki portu da ayni sekilde guncelle.

## 1) Hosting + Functions deploy

```bash
firebase deploy --only hosting,functions:viralApi
```

## 2) iOS Universal Links

Bu repoda iOS icin `Runner.entitlements` ve `apple-app-site-association` ayarlari eklendi.

- Entitlements: `ios/Runner/Runner.entitlements`
- AASA endpoint: `https://invite.hatirlatbana.com/.well-known/apple-app-site-association`

Kontrol:

```bash
curl -i https://invite.hatirlatbana.com/.well-known/apple-app-site-association
```

Beklenen:
- `HTTP 200`
- `Content-Type: application/json`

## 3) Android App Links

Asset links dosyasi:
- `web/.well-known/assetlinks.json`

Su an debug sertifika SHA256 yazili. Release'e cikmadan once release fingerprint eklenmeli.

Release fingerprint alma:

```bash
keytool -list -v \
  -keystore <RELEASE_KEYSTORE_PATH> \
  -alias <RELEASE_ALIAS>
```

Sonra `assetlinks.json` icindeki `sha256_cert_fingerprints` listesine release fingerprint ekle.

Kontrol:

```bash
curl -i https://invite.hatirlatbana.com/.well-known/assetlinks.json
```

## 4) Invite URL testleri

- Landing page: `https://invite.hatirlatbana.com/invite/<invite_id>`
- Redirect short path: `https://invite.hatirlatbana.com/r/<invite_id>`
- API metrics: `https://invite.hatirlatbana.com/api/metrics`

## 5) App tarafi beklenen davranis

- Uygulama HTTPS invite linkini yakalar.
- `invite_id` ile backend'den invite kaydini ceker.
- Fullscreen accept ekrani acilir.
- Accept olunca ledger backend'de `accepted` olur.
