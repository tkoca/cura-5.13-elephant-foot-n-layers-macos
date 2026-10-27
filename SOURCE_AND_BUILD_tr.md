# Kaynak ve derleme (macOS)

[English](SOURCE_AND_BUILD.md) · [Türkçe](SOURCE_AND_BUILD_tr.md)

`Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run` dosyasını yeniden üretmek için gereken her şey bu depodadır.

## İçerik

| Yol | İçerik |
| --- | --- |
| `patches/CuraEngine-5.13.0.patch` | CuraEngine 5.13.0 `src/slicer.cpp` değişikliği (Windows ve Linux projeleriyle aynı) |
| `patches/Cura-5.13.0.patch` | Üç Cura kaynak dosyasındaki değişiklikler (`fdmprinter.def.json`, Türkçe `.po`, `expert.cfg`); Türkçe `.mo`, yamalı `.po`'dan `scripts/po2mo.py` ile derlenir (Windows ve Linux projeleriyle aynı) |
| `patches/Uranium-5.13.0-macos.patch` | Yalnızca macOS: kopyanın LocalContainerProvider eklentisi kendi tanım önbelleği klasörünü (`definitions-efnl`) kullanır, aşağıya bakın |
| `scripts/setup-tools.sh` | Sabitlenmiş derleme araçlarını `/Users/Shared/efnl` içine kurar: Python 3.12 (uv ile), Conan 2.32.0, CMake 3.31.6, Ninja 1.13.2 |
| `scripts/build-curaengine.sh` | CuraEngine'i Xcode komut satırı araçlarıyla doğrudan derler (`--unpatched`: kontrol derlemesi) |
| `scripts/check-engine.sh` | İkili denetimleri: yalnızca arm64, hedef sürüm ≤ macOS 12.0, yalnızca sistem kütüphaneleri ve `Cura.app/Contents/Frameworks` içindeki beş kütüphane, tek `LC_RPATH` `@loader_path`, geçerli imza, kullanıcı/makine adı yok |
| `scripts/apply_patch.py`, `scripts/make_payload.py`, `scripts/make_bundle.py` | Yamaları uygular; yükü ve paketi oluşturur (deterministik tar) |
| `scripts/build-installer.sh` | Kendini açan `.run` dosyasını `dist/` içine üretir |
| `installer/` | Kurulum programı (`efnl.sh`, bash 3.2), `.run` başlığı, İngilizce/Türkçe mesajlar |
| `tests/installer-tests.sh` | Kurulum testleri (74 denetim) |
| `tests/engine/` | Resmi Cura 5.13.0 motoruna karşı dilimleme testleri (26 denetim) |
| `docs/macos-layout.md` | Resmi 5.13.0 macOS uygulamasının ölçülmüş yapısı |

## Derleme tercihlerinin nedenleri

Resmi uygulama (`UltiMaker-Cura-5.13.0-macos-ARM64.dmg`), `Contents/Frameworks` içinde yalnızca arm64 bir `CuraEngine` içerir (hedef sürüm macOS 12.0). Bu motor `libArcus`, `libpolyclipping`, `libtbb`, `libtbbmalloc` ve `libtbbmalloc_proxy` kütüphanelerini aynı klasörden tek bir `LC_RPATH @loader_path` ile yükler; geri kalan her şey (protobuf, gRPC, abseil, OpenSSL, …) statik bağlanmıştır. Yamalı motor da aynı şekilde derlenir: UltiMaker Conan yapılandırmasıyla (`Ultimaker/conan-config`, Linux'takiyle aynı sabit commit), `os.version=12.0`; rpath tam olarak `@loader_path` yapılır. Motor küçültülür (strip) ve ad hoc imzalanır (arm64 kodu imzalı olmak zorundadır).

Apple clang 19 ve sonrası, gRPC 1.54.3'teki (CuraEngine 5.13.0'ın sabitlediği sürüm) bir yapıyı varsayılan olarak reddeder; derleme bunun için `-Wno-missing-template-arg-list-after-template-kw` verir. Conan ana klasörü tarafsız `/Users/Shared/efnl` yoludur ve `-ffile-prefix-map` bunu `.` olarak eşler; böylece ikiliye kullanıcı adı girmez. Resmi motor Sentry hata raporlamasıyla derlendiği için daha büyüktür; bu derleme Windows ve Linux sürümleri gibi varsayılan seçenekleri kullanır (Sentry kapalı).

Bir uygulama paketinin içindeki dosyaları değiştirmek kod imzasını geçersiz kılar; bu yüzden kurulum programı bir kopya üzerinde çalışır, kopyayı yeniden imzalar (ad hoc) ve Ultimaker imzalı `Cura.app`'e hiç dokunmaz. Cura macOS'ta tanım önbelleğini profilin içinde tutar (`~/Library/Application Support/cura/5.13/cache`), `XDG_CACHE_HOME`'u dikkate almaz ve önbelleği dosya değişiklik zamanına göre seçer. Ayrı bir önbellek klasörü olmasaydı, kopya çalıştıktan sonra değiştirilmemiş Cura yamalı `fdmprinter` tanımının önbelleğini yükler (ve iki ayarı etkisiz olarak gösterirdi). Çekirdek modül `UM/Resources.py` uygulama dosyasının içine gömülüdür ve değiştirilemez; eklentiler ise `.py` dosyalarından yüklenir. Bu nedenle `patches/Uranium-5.13.0-macos.patch`, kopyanın LocalContainerProvider eklentisindeki önbellek klasörünün adını değiştirir.

## Derleme

Gereksinimler: Apple çipli bir Mac, Xcode komut satırı araçları (`xcode-select --install`), yaklaşık 10 GB boş disk alanı. İlk derleme tüm bağımlılıkları kaynaktan derler ve bir Apple M5'te (10 çekirdek) yaklaşık 8 dakika sürdü; sonraki derlemeler yaklaşık 30 saniye sürer.

```sh
# upstream kaynakları (etiket arşivleri)
curl -L -o CuraEngine-5.13.0.tar.gz https://github.com/Ultimaker/CuraEngine/archive/refs/tags/5.13.0.tar.gz
curl -L -o Cura-5.13.0.tar.gz       https://github.com/Ultimaker/Cura/archive/refs/tags/5.13.0.tar.gz
curl -L -o Uranium-5.13.0.tar.gz    https://github.com/Ultimaker/Uranium/archive/refs/tags/5.13.0.tar.gz

scripts/setup-tools.sh                                            # bir kez
scripts/build-curaengine.sh CuraEngine-5.13.0.tar.gz out          # -> out/CuraEngine, CHECK PASS
scripts/build-installer.sh  Cura-5.13.0.tar.gz Uranium-5.13.0.tar.gz out/CuraEngine dist
```

Derleme tekrarlanabilirdir: iki kez derlemek aynı `CuraEngine`'i ve aynı `.run` dosyasını verir (sürüm notlarındaki SHA-256 değerleri).

## Testler

```sh
scripts/build-curaengine.sh --unpatched CuraEngine-5.13.0.tar.gz out   # isteğe bağlı kontrol derlemesi
python3 scripts/make_payload.py Cura-5.13.0.tar.gz Uranium-5.13.0.tar.gz out/CuraEngine build

tests/engine/slice-tests.sh "/Applications/UltiMaker Cura.app" out/CuraEngine \
    build/payload/Resources/share/cura/resources/definitions/fdmprinter.def.json out/CuraEngine.unpatched
tests/installer-tests.sh "/Applications/UltiMaker Cura.app" build/payload \
    dist/Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run
```

Dilimleme testleri resmi motoru `Cura.app` içinden, derlenen motorları ise Cura'nın yaptığı gibi onun kütüphanelerine bağlantıların yanında çalıştırır. Katman sayısı 1'in resmi motorla birebir aynı G-code verdiğini, N katman için kademeli telafi açık ve kapalıyken katman başına duvar içe kaymasını ve yamasız kontrol derlemesinin resmi motorla birebir aynı G-code verdiğini (yani farkların yalnızca yamadan geldiğini) denetler. Kurulum testleri geçici bir ev klasöründe (`/Users/Shared/efnl/installer-tests.noindex`, Spotlight dışında) gerçek uygulamanın APFS klonlarıyla çalışır; gerçek profile, `/Applications`'a veya özgün `Cura.app`'e hiç dokunmaz.
