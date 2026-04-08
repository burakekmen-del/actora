# Release Readiness (Flutter + Firebase)

Bu dokuman canliya cikmadan once tek bir yerden kontrol etmen icin hazirlandi.

## 1) Domain ve kimlikler

Canliya cikmadan once asagidakiler ornek degerde kalmamali:
- `com.example.actora`
- `actora.app` (eger farkli domain/subdomain kullaniyorsan)

Oneri:
- Bu uygulama icin `invite.hatirlatbana.com` gibi ayri bir subdomain kullan.
- Universal/App Link cakismasi olmasin diye iki farkli uygulama ayni exact host/path'i paylasmasin.

## 2) Otomatik preflight

```bash
./scripts/release_preflight.sh
```

Script sunlari yapar:
- Placeholder kimlik/domain taramasi
- `flutter pub get`
- `flutter analyze`
- `flutter test`

## 3) Profesyonel terminal logu

Detayli runtime logu icin:

```bash
flutter run \
  --dart-define=ACTORA_LOG_LEVEL=trace
```

Seviye secenekleri:
- `error`
- `warn`
- `info`
- `debug`
- `trace`

Not:
- Release modda varsayilan seviye `error` olur (gereksiz log gurultusunu engeller).

## 4) Firebase deploy

```bash
firebase deploy --only hosting,functions:viralApi
```

## 5) Link dogrulamalari

```bash
curl -i https://<YOUR_DOMAIN>/.well-known/apple-app-site-association
curl -i https://<YOUR_DOMAIN>/.well-known/assetlinks.json
curl -i https://<YOUR_DOMAIN>/api/metrics
```

Beklenen:
- `HTTP 200`
- AASA/assetlinks `application/json`
