# shellcheck shell=bash
# Türkçe mesajlar (MSG_<anahtar>, bash 3.2: ilişkisel dizi yok). %s yer tutucuları printf ile doldurulur.
# shellcheck disable=SC2034
MSG_title="Cura 5.13 - Fil Ayağı N Katman"
MSG_usage="Kullanım: %s {install [CURA.APP] | uninstall | status} [--system] [--gui] [--yes|--silent]

  install    Resmi UltiMaker Cura 5.13.0 uygulamasını doğrular ve yamalı bir kopyasını
             \"UltiMaker Cura 5.13 (Elephant Foot N Layers)\" adıyla kurar. Cura.app değiştirilmez.
  uninstall  Yamalı kopyayı kaldırır; eklenti ayarlarını Cura profilinizden ve tanım önbelleğinden temizler.
  status     Eklentinin kurulu olup olmadığını ve dosyalarının sağlam olup olmadığını gösterir.

  --system   Tüm kullanıcılar için /Applications altına kurar (yönetici parolasını yalnızca gerekirse ister).
  --gui      Soruları ve sonuçları pencereyle gösterir.
  --yes      Onay sormaz.  --silent: --yes gibi, mesajlar yalnızca stderr'e.
Çıkış kodu: 0 = yapıldı, 1 = yapılmadı veya eksik kaldı (nedeni yazılır)."
MSG_bad_args="Bilinmeyen parametre: %s"
MSG_missing_tool="Gerekli program bulunamadı: %s"
MSG_not_mac="Bu kurulum programı macOS içindir; bu sistem %s."
MSG_not_arm="Yalnızca Apple çipli (M1 veya daha yeni) Mac'ler desteklenir; bu Mac %s."
MSG_searching="UltiMaker Cura 5.13.0 aranıyor ..."
MSG_not_found="Resmi UltiMaker Cura 5.13.0 uygulaması bulunamadı. UltiMaker-Cura-5.13.0-macos-ARM64.dmg dosyasını https://github.com/Ultimaker/Cura/releases/tag/5.13.0 adresinden indirip kurun (Uygulamalar klasörüne sürükleyin) veya konumunu verin:
  %s install \"/Applications/UltiMaker Cura.app\""
MSG_other_cura="Not: %s bulundu, ancak bu UltiMaker Cura 5.13.0 değil."
MSG_several="Birden fazla UltiMaker Cura 5.13.0 uygulaması bulundu:"
MSG_choose="Kullanılacak uygulamanın numarası (Enter = 1): "
MSG_several_silent="Birden fazla UltiMaker Cura 5.13.0 uygulaması bulundu; konumu açıkça verin."
MSG_checking="%s doğrulanıyor ..."
MSG_bad_app="Bu, resmi ve değiştirilmemiş macOS için UltiMaker Cura 5.13.0 değil; kurulum yapılmadı:
%s
Yalnızca UltiMaker-Cura-5.13.0-macos-ARM64.dmg (UltiMaker GitHub sürümü) ile kurulan UltiMaker Cura 5.13.0 desteklenir. Uygulama değiştirildiyse dmg'den yeniden kurun."
MSG_intel_app="Bu, Cura'nın Intel (X64) sürümü; Apple çipli Mac'lerde yalnızca ARM64 sürümü desteklenir. UltiMaker-Cura-5.13.0-macos-ARM64.dmg dosyasını kurun; kurulum yapılmadı:
%s"
MSG_bad_signature="Bu uygulamanın kod imzası sağlam değil veya Ultimaker B.V.'ye ait değil; kurulum yapılmadı:
%s
UltiMaker Cura 5.13.0'ı resmi dmg'den yeniden kurun."
MSG_bad_payload="Kurulum dosyası bozuk (%s); kurulum yapılmadı. Dosyayı yeniden indirin."
MSG_confirm_install="UltiMaker Cura 5.13.0'ın yamalı bir kopyasına ilk N katmanda fil ayağı telafisi kurulsun mu?

Yeni uygulama: %s
Kopyalanan: %s (değişmez ve kullanılmaya devam edilebilir)."
MSG_confirm_update="Eklenti zaten kurulu. Yeniden kurulsun (güncellensin) mu?

Konum: %s"
MSG_confirm_uninstall="Eklenti (yamalı Cura uygulaması) ve Cura profilinizdeki eklenti ayarları kaldırılsın mı?"
MSG_cancelled="İptal edildi; hiçbir değişiklik yapılmadı."
MSG_running="Cura %s içinden çalışıyor (süreç %s). Programdan çıkıp yeniden deneyin."
MSG_foreign_dir="%s mevcut ama bu eklenti tarafından oluşturulmamış; kurulum yapılmadı. Taşıyın veya silin, sonra yeniden deneyin."
MSG_no_space="%s içinde yeterli boş alan yok (%s MB boş, %s MB gerekli); kurulum yapılmadı."
MSG_no_write="%s konumuna yazılamıyor; kurulum yapılmadı."
MSG_copying="Cura.app kopyalanıyor ..."
MSG_copy_failed="Cura.app kopyalanamadı; kurulum yapılmadı."
MSG_signing="Yamalı kopya imzalanıyor ..."
MSG_layout_bad="Kopyalanan uygulama beklenen Cura 5.13.0 dosyasını içermiyor: %s; kurulum yapılmadı."
MSG_verify_failed="Yazılan dosya doğrulanamadı: %s; kurulum yapılmadı."
MSG_failed_rollback="Kurulum tamamlanamadı (%s); tüm değişiklikler geri alındı."
MSG_installed="Eklenti kuruldu. \"UltiMaker Cura 5.13 (Elephant Foot N Layers)\" uygulamasını Launchpad'den, Spotlight'tan veya şuradan başlatın:
  %s
Ayarlar: Duvarlar > \"Fil Ayağı Telafi Katman Sayısı\" ve \"Fil Ayağı Kademeli Telafi\" (Uzman görünümü)."
MSG_not_installed="Eklenti kurulu değil; yapılacak bir şey yok."
MSG_changed_file="Yamalı kopyadaki bu dosya kurulumdan sonra değişmiş; kopyayla birlikte kaldırıldı: %s"
MSG_removed="Eklenti kaldırıldı. Profil ayarları ve tanım önbelleği temizlendi."
MSG_profile_link="Güvenlik nedeniyle durduruldu: Cura profili sembolik bağlantı içeriyor: %s
Yamalı kopya kaldırıldı; profil temizlenmedi."
MSG_unknown_form="Eklenti ayarı bu dosyada tanınmayan bir biçimde kaldı; Cura bunu yok sayar, isterseniz elle silebilirsiniz: %s"
MSG_need_root="Bu adım yönetici yetkisi gerektirir. Komutu normal kullanıcı olarak yeniden çalıştırın (sudo'yu kendisi ister)."
MSG_no_sudo="--system için yönetici yetkisi gerekiyor ama sudo bulunamadı."
MSG_elev_failed="Yönetici onayı verilmedi veya sistem adımı tamamlanamadı (kod %s)."
MSG_status_installed="Kurulu (%s): sürüm %s, %s"
MSG_status_intact="tüm dosyalar sağlam"
MSG_status_damaged="BOZUK: %s"
MSG_status_none="Kurulu değil (%s)."
MSG_yes="Evet"
MSG_no="Hayır"
MSG_app_name="UltiMaker Cura 5.13 (Elephant Foot N Layers)"
