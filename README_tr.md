# Cura 5.13.0 — İlk N Katmanda Fil Ayağı Telafisi (macOS)

[English](README.md) · [Türkçe](README_tr.md)

Bu, **Apple çipli Mac'lerde (M1 veya daha yeni) UltiMaker Cura 5.13.0** için resmi olmayan bir eklentidir. *İlk Katmanın Yatay Genişlemesi* değerini yalnızca ilk katmana değil, basılan ilk **N** katmana uygular. İsteğe bağlı olarak değeri bu katmanlar boyunca adım adım normal *Yatay Büyüme* değerine döndürür.

Bu depo, [cura-5.13-elephant-foot-n-layers](https://github.com/tkoca/cura-5.13-elephant-foot-n-layers) (Windows) ve [cura-5.13-elephant-foot-n-layers-linux](https://github.com/tkoca/cura-5.13-elephant-foot-n-layers-linux) (Linux) projelerinin macOS karşılığıdır. Üçü de aynı yamaları, aynı ayarları ve aynı kaynak dosyalarını kullanır.

> Bu bir topluluk projesidir. UltiMaker bu projeyi geliştirmemiştir, onaylamamıştır ve desteklememektedir.

## Ayarlar

*İlk Katmanın Yatay Genişlemesi* ayarının hemen altına (*Duvarlar* kategorisi) iki ayar eklenir. Ayarlar *Uzman* görünürlük ön ayarında yer alır; ayar aramasıyla da bulunabilir.

| Ayar | Varsayılan | Etkisi |
| --- | --- | --- |
| Fil Ayağı Telafi Katman Sayısı | `1` | *İlk Katmanın Yatay Genişlemesi* değerinin basılan ilk kaç katmanda kullanılacağı. `1`, standart Cura davranışıyla birebir aynıdır. 20'nin üzerinde Cura uyarı gösterir. |
| Fil Ayağı Kademeli Telafi | kapalı | Değeri bu katmanlar boyunca *İlk Katmanın Yatay Genişlemesi*'nden *Yatay Büyüme*'ye doğru adım adım değiştirir. Yalnızca katman sayısı 1'den büyükken görünür. |

Örnek: *İlk Katmanın Yatay Genişlemesi* `-0,20 mm`, *Yatay Büyüme* `0,00 mm`, katman sayısı `4`:

| Basılan katman | Kademeli kapalı | Kademeli açık |
| --- | --- | --- |
| 1 | -0,20 | -0,20 |
| 2 | -0,20 | -0,15 |
| 3 | -0,20 | -0,10 |
| 4 | -0,20 | -0,05 |
| 5 ve sonrası | 0,00 | 0,00 |

N katmanın hepsi telafi edilir; bunlardan sonraki katman normal değeri kullanır. *Yatay Büyüme* sıfır değilse adımlar 0'a değil, o değere doğru ilerler.

İngilizce arayüzde ayarların adı *Elephant Foot Compensation Layer Count* ve *Elephant Foot Gradual Compensation*'dır.

Windows veya Linux sürümüyle hazırlanmış profiller değiştirilmeden çalışır: ayar adları aynıdır.

## Gereksinimler

- Apple çipli (M1 veya daha yeni) bir Mac, macOS 12 Monterey veya daha yenisi.
- [UltiMaker Cura 5.13.0 sürümündeki](https://github.com/Ultimaker/Cura/releases/tag/5.13.0) **`UltiMaker-Cura-5.13.0-macos-ARM64.dmg`** ile kurulmuş resmi **UltiMaker Cura 5.13.0** uygulaması (normalde `/Applications/UltiMaker Cura.app`). Kurulum programı Ultimaker'ın kod imzasını ve değişen dosyaların SHA-256 değerlerini denetler.
- Başka bir şey gerekmez: kurulum programı yalnızca macOS ile gelen programları kullanır (`/bin/bash` 3.2, `ditto`, `codesign`, `shasum`, `plutil`). Homebrew, Python, Xcode ve yönetici yetkisi **gerekmez**.
- Desteklenmez: Intel Mac'ler ve Cura'nın Intel sürümü (`…-macos-X64.dmg`).

## Kurulum

1. [Releases](../../releases) sayfasından `Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run` dosyasını indirin ve SHA-256 değerinin sürüm notlarındakiyle aynı olduğunu kontrol edin:
   ```sh
   shasum -a 256 ~/Downloads/Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run
   ```
2. Cura'dan çıkın.
3. Terminal'de kurun (Cura `/Applications` veya `~/Applications` içinde bulunur; konumunu siz de verebilirsiniz):
   ```sh
   bash ~/Downloads/Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run install
   ```
4. **UltiMaker Cura 5.13 (Elephant Foot N Layers)** uygulamasını Launchpad'den veya Spotlight'tan başlatın. Uygulama `~/Applications` (Ev klasörünüzdeki Uygulamalar) içindedir.

Dosyayı gösterildiği gibi `bash` ile çalıştırın: çift tıklamak işe yaramaz, çünkü bu imzalı bir uygulama değil, bir betiktir.

Nasıl çalışır: Kurulum programı Cura.app'i denetler (Ultimaker kod imzası, 5.13.0 sürümü, Apple çipi sürümü, değişen altı dosyanın ve `Info.plist`'in SHA-256 değerleri), kopyalar (APFS klonu: değişmeyen dosyalar ek disk alanı kaplamaz), kopyadaki altı dosyayı değiştirir, kopyaya kendi adını ve paket kimliğini verir ve kopyayı yeniden imzalar (ad hoc), çünkü Ultimaker'ın imzası değişen içeriği kapsamaz. **Cura.app'iniz değişmez** — normal Cura olarak kullanmaya devam edebilirsiniz. Kopya Mac'inizde oluşturulduğu için indirme karantinası taşımaz ve Gatekeeper uyarısı olmadan açılır. Kurulum atomiktir: bir hata olursa geride hiçbir şey kalmaz (var olan kurulum da çalışmaya devam eder).

Windows ve Linux sürümlerinde olduğu gibi iki uygulama aynı Cura profilini (`~/Library/Application Support/cura/5.13`) kullanır. Yamalı kopyanın kendi tanım önbelleği vardır (`…/cura/5.13/cache/definitions-efnl`); böylece iki uygulama birbirinin önbelleğe alınmış ayar tanımını yüklemez. Değiştirilmemiş Cura iki ayarı yok sayar.

macOS'un dili (veya `LANG`) Türkçe ise mesajlar Türkçe, değilse İngilizcedir.

## Kaldırma

```sh
~/Applications/"UltiMaker Cura 5.13 (Elephant Foot N Layers).app"/Contents/Resources/efnl/uninstall   # .run dosyası olmadan da çalışır
# veya
bash Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run uninstall
```

- Yamalı kopya kaldırılır. Cura.app'iniz hiç değiştirilmemiştir.
- İki ayar Cura profilinizden (`~/Library/Application Support/cura/5.13`, kayıtlı özel profilleriniz dahil; `plugins/` klasörüne dokunulmaz) kaldırılır ve kopyanın tanım önbelleği silinir.
- Yamalı kopyadaki bir dosya kurulumdan sonra değiştiyse adını belirten bir uyarı alırsınız.
- Güvenlik için profil sembolik bağlantı içeriyorsa profile dokunulmaz.

Uygulamayı Çöp Sepeti'ne taşımak da çalışır, ancak iki ayar profilinizde kalır (normal Cura bunları yok sayar).

Başka bir Cura sürümüne geçmeden önce eklentiyi kaldırın.

## Bilgisayarınızda değişenler

| Konum | İçerik |
| --- | --- |
| `~/Applications/UltiMaker Cura 5.13 (Elephant Foot N Layers).app` | Aşağıdaki dosyaları değiştirilmiş, ad hoc imzalı Cura 5.13.0 kopyası |
| `…/Contents/Frameworks/CuraEngine` | Yamalı CuraEngine 5.13.0 (arm64) |
| `…/Contents/Resources/share/cura/resources/definitions/fdmprinter.def.json` | İki yeni ayar |
| `…/resources/i18n/tr_TR/fdmprinter.def.json.po` ve `LC_MESSAGES/fdmprinter.def.json.mo` | Türkçe adlar ve açıklamalar |
| `…/resources/setting_visibility/expert.cfg` | Uzman ön ayarındaki ayar listesi |
| `…/Contents/Resources/share/uranium/plugins/LocalContainerProvider/LocalContainerProvider.py` | Kendi tanım önbelleği klasörü (`definitions-efnl`), yukarıya bakın |
| `…/Contents/Info.plist` | Kendi adı ve paket kimliği (`nl.ultimaker.cura_UltiMaker_Cura.efnl`) |
| `…/Contents/Resources/efnl/` | Manifest (SHA-256), kaldırma programı |
| `~/Library/Application Support/cura/5.13/cache/definitions-efnl/` | Yamalı kopyanın tanım önbelleği (Cura oluşturur) |

`--system` ile kopya `/Applications` içine (tüm kullanıcılar için) kurulur; yönetici parolası yalnızca hesabınız `/Applications`'a yazamıyorsa sorulur.

### Komut satırı

```text
bash Cura-5.13-…-arm64.run install [CURA.APP] [--system] [--gui] [--yes|--silent]
bash Cura-5.13-…-arm64.run uninstall          [--system] [--gui] [--yes|--silent]
bash Cura-5.13-…-arm64.run status             [--system]
```

- `--system`: tüm kullanıcılar için `/Applications` içine kurar. Profil temizliği her zaman sizin kullanıcınızla çalışır. Kurulum programını `sudo` ile başlatmayın.
- `--gui`: sorular ve sonuçlar pencerelerde gösterilir.
- `--yes`: soru sorulmaz. `--silent`: `--yes` gibi, mesajlar yalnızca standart hataya yazılır (uyarılar `WARNING: …` olarak).
- Çıkış kodu `0` başarı (uyarılar olabilir), `1` hiçbir şeyin veya her şeyin yapılamadığı, `2` kullanım hatası anlamına gelir.

## Kaynak ve derleme

Kurulum dosyasını yeniden üretmek için gereken her şey bu depodadır: yamalar, kurulum programı, derleme betikleri ve testler. Bkz. [SOURCE_AND_BUILD_tr.md](SOURCE_AND_BUILD_tr.md).

## Lisans

GNU Affero General Public License v3.0 veya sonrası ([LICENSE](LICENSE)); CuraEngine'in lisansı. Cura ve Uranium kaynak dosyaları © UltiMaker, LGPL-3.0 veya sonrası. Kurulum dosyasındaki `CuraEngine`'in kaynak kodu, UltiMaker CuraEngine 5.13.0 ile [`patches/CuraEngine-5.13.0.patch`](patches/CuraEngine-5.13.0.patch) yamasıdır ve [`scripts/build-curaengine.sh`](scripts/build-curaengine.sh) ile derlenir. Kurulum dosyası UltiMaker Cura'nın kendisini içermez ve dağıtmaz; kendi kurulu Cura.app'inizin değiştirilmiş bir kopyasını oluşturur.

Kullanım sorumluluğu size aittir; önce küçük bir kalibrasyon baskısıyla deneyin.
