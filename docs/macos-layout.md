# Ölçüm raporu — UltiMaker Cura 5.13.0 macOS (ARM64) uygulaması (27.10.2026)

## Paket
- Kaynak: `UltiMaker-Cura-5.13.0-macos-ARM64.dmg` ile kurulan `/Applications/UltiMaker Cura.app`, 480 MB
- `CFBundleIdentifier` nl.ultimaker.cura_UltiMaker_Cura, `CFBundleShortVersionString` 5.13.0
- İmza: Developer ID Application: Ultimaker B.V. (V4B3JXRRQS), hardened runtime, zaman damgası 28.05.2026;
  `codesign --verify --deep --strict` geçerli
- Ana program `Contents/MacOS/UltiMaker-Cura`: Mach-O arm64 (tek mimari), minos 11.0
- Haklar (ana program ve motor): allow-dyld-environment-variables, disable-executable-page-protection,
  disable-library-validation (yalnızca hardened runtime gevşetmeleri; sandbox yok)

## İç yapı (Contents/)
- Motor: `Frameworks/CuraEngine`; `Resources/CuraEngine` → `../Frameworks/CuraEngine` sembolik bağlantısı
  (Cura motoru `Resources/CuraEngine` yolundan başlatır)
- Resources: `Resources/share/cura/resources/`, Uranium eklentileri `Resources/share/uranium/plugins/`
- Python çekirdeği (`UM`, `cura`) ana programa gömülü (PyInstaller); `Resources/UM/*.py` dosyaları yüklenmez
  (ölçüm: değiştirilmiş `Resources/UM/Resources.py` etkisiz, günlükteki satır numaraları özgün).
  Eklentiler `.py` dosyalarından yüklenir (ölçüm: değiştirilmiş LocalContainerProvider etkili).

## Değişen dosyalar — orijinal SHA-256
| Dosya (Contents/ altında) | SHA-256 | Windows/Linux kaynağıyla |
|---|---|---|
| Frameworks/CuraEngine | b7e19c3d…5d28f7 | (platforma özgü) |
| Resources/share/cura/resources/definitions/fdmprinter.def.json | 8fbbf8b7…7e11ee | AYNI |
| Resources/share/cura/resources/i18n/tr_TR/fdmprinter.def.json.po | ace33455…f51a85 | AYNI |
| Resources/share/cura/resources/i18n/tr_TR/LC_MESSAGES/fdmprinter.def.json.mo | 16dda401…99d3ad | Linux ile AYNI |
| Resources/share/cura/resources/setting_visibility/expert.cfg | 9b646941…720a4ba | AYNI |
| Resources/share/uranium/plugins/LocalContainerProvider/LocalContainerProvider.py | d778d897…432ffad | Uranium 5.13.0 etiketiyle AYNI |
| Info.plist | 82d1a180…52d4f7 | (yalnızca macOS) |

## Resmi motor
- Mach-O arm64, minos 12.0, SDK 13.1; tek LC_RPATH `@loader_path`
- @rpath kütüphaneleri (Frameworks içinde): libArcus.dylib, libpolyclipping.22.dylib, libtbb.12.dylib,
  libtbbmalloc.2.dylib, libtbbmalloc_proxy.2.dylib; geri kalanı sistem kütüphaneleri/çerçeveleri
- protobuf/gRPC/abseil/OpenSSL statik gömülü; GitHub runner yolları (`/Users/runner/.conan2/...`) dizgi olarak içinde
- `CuraEngine help` → "Cura_SteamEngine version 5.13.0"

## Profil yolları (kaynak: UM/Resources.py, Cura 5.13 içinden; ölçümle doğrulandı)
- Config = Data: `~/Library/Application Support/cura/5.13/` (cura.cfg burada)
- Cache: `~/Library/Application Support/cura/5.13/cache/` (`_getCacheStorageRootPath` macOS'ta None; XDG değişkenleri yok sayılır)
- Tanım önbelleği: `cache/definitions/5.13.0/<id>`; geçerlilik: tanım dosyasının mtime'ı önbellekten yeni değilse önbellek kullanılır
- Yamalı kopya: `cache/definitions-efnl/5.13.0/<id>` (ölçüm: kopya çalıştıktan sonra burada, yeni ayarları içeren `fdmprinter`)

## Kopya ve imza (ölçüm)
- `ditto --clone --noqtn` sonrası kök klasörde `com.apple.quarantine` kalabiliyor → kurulum `xattr -dr` ile kaldırır
- Dosyalar değiştirildikten sonra `codesign --verify`: "invalid Info.plist (plist or signature have been modified)"
- `codesign --force --sign - --preserve-metadata=entitlements` (yalnızca dış paket) → `--verify --deep --strict` geçerli;
  Frameworks içindeki değişmeyen kütüphaneler Ultimaker imzasını korur
- `open` ile başlatma (LaunchServices/Gatekeeper yolu): uygulama açılıyor, yamalı motor `Resources/CuraEngine`'den başlatılıyor
