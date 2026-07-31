# Notes Uygulaması — Proje Planı

*Bu belge, [PROJECT_PLAN.md](PROJECT_PLAN.md) dosyasının Türkçe çevirisidir. Kod tanımlayıcıları
(sınıf/fonksiyon adları, dosya yolları), veritabanı tablo/sütun adları, SQL kodu ve uygulamanın
gerçekte gösterdiği birebir arayüz metinleri (tırnak içindeki İngilizce mesajlar, buton etiketleri,
hata mesajları) bilinçli olarak çevrilmeden bırakılmıştır — bunlar kaynak koddaki gerçek değerlerdir
ve çevrilmeleri bu belgeyi uygulamanın gerçek davranışından saptırır, uygulama şu an yalnızca
İngilizce arayüzle çalışmaktadır. Bölüm numaraları (§) ve başlık numaraları, orijinal İngilizce
belgeyle birebir eşleşecek şekilde korunmuştur, böylece iki belge arasında çapraz referans vermek
kolay olsun.*

**Durum:** PR #57'den sonra (2026-07-30) en son yenilenmiş, geriye dönük olarak yazılmış bir proje
planı. Bu belgenin zaten yayınlanmış (shipped) bir şeyi tarif ettiği yerlerde bu açıkça belirtilir —
o bölümleri "sıfırdan tasarla" değil, "bunun hâlâ doğru olduğunu teyit et" olarak okuyun. Bu revizyon,
önceki taslaklarda bulunmayan ürün düzeyinde bölümler (vizyon, kullanıcı deneyimi/UX analizi, rekabet
ortamı) ve resmî, üç katmanlı bir kabul kriterleri çerçevesi (sayfa / modül / proje) eklemekte, bunun
yanında PR #30–#57 arasındaki arayüz yenileme ve özellik çalışmaları boyunca eskimiş olan
spesifikasyonun her bölümünü de güncellemektedir.

Bu belge **tamamen kendi kendine yeterli (self-contained)** olacak şekilde yazılmıştır: Bölüm I
üst düzey plandır (vizyon, kullanıcı deneyimi düşüncesi, rekabet bağlamı, hedefler, kapsam, yol
haritası); Bölüm II her ekranın, alanın, doğrulama kuralının, veri tablosunun ve iş kuralının
kapsamlı bir dökümüdür; Bölüm III her sayfayı bir ürün bileşeni olarak envanterler (amaç, içerik,
kullanıcı eylemleri, kabul kriterleri); Bölüm IV modül ve proje bütünü düzeyinde "tamamlanmış"
sayılmanın ne anlama geldiğini belirtir; Bölüm V uçtan uca örnek kullanıcı akışlarını adım adım
anlatır.

---

# BÖLÜM I — ÜST DÜZEY PLAN

## 1. Vizyon

Notes, `learning_flutter` uygulaması içindeki amiral gemisi mini-projedir (kullanıcıya gösterilen
uygulama adı: **Mini Projects**, bkz. §12): üzerine sosyal bir katman eklenmiş, kişisel bir not
tutma uygulaması. Notes en iyi haliyle, birbirini bozmayan iki dürüst şeyin bir araya getirilmiş
hâli gibi hissettirmelidir —

- **Hızlı, güvenilir, özel bir not defteri.** Yazmak, düzenlemek (sabitleme/favori) ve bir notu
  yeniden bulmak, düz metin bir dosyaya erişmekten hiçbir zaman daha yavaş ya da daha güvenilmez
  hissettirmemeli. Sosyal katmanın hiçbir parçası, özel-not deneyimini yavaşlatmamalı.
- **Küçük, bilinçli bir paylaşım eylemi.** Bir notu yayınlamak, bilinçli, görünür ve geri
  alınabilir bir seçimdir — ortama yayılan bir yayın değil. Arkadaş grafiği kapalıdır (herkese açık
  bir takip modeli yerine, karşılıklı ve istek tabanlı) ve yayınlanan her not, yalnızca yayınlandığı
  anda arkadaşınız olan kişilerin tam kümesine görünür.

Aynı zamanda, `learning_flutter` uygulamasının geri kalanının mühendislik kalıplarının üzerine
kurulduğu orijinal projedir — test edilebilir `*Logic` + `*DataSource` çifti, Supabase kimlik
doğrulama/RLS kuralları, koyu "eğlenceli ve yuvarlak hatlı" tema sistemi, iskelet-yükleme/çapraz
geçiş/dokunsal geri bildirim hareket dili — ve daha sonra (önce Notes'un kalıpları, sonra
SmartAcademy'nin varyasyonları) uygulamanın geri kalanında yeniden kullanılmıştır.

## 2. Sorun / Motivasyon

Bu bir öğrenme deposudur (repo) — motivasyon, Supabase üzerinde kimlik doğrulama, yetkilendirme,
bir sosyal grafik ve gerçek ürün-tasarım karar verme süreçleri (yalnızca arka uç altyapısı değil)
içeren gerçekçi bir tam-yığın (full-stack) CRUD uygulaması inşa etme pratiği yapmak ve proje
büyüdükçe bunu birçok küçük, sıralı PR ile sürdürülebilir tutmaktır. Dışarıdan bir kullanıcı kitlesi
yoktur; kapsam ve sıralama, bir sonraki adımda neyin inşa edilip öğrenilmesinin faydalı olacağına
göre, PR PR ilerleyerek ortaklaşa karar verilir ve gerçek bir kullanıcının ne beklediğine dair
periyodik özellik/UX denetimleriyle bilgilendirilir.

## 3. Kullanıcı deneyimi (UX) ilkeleri ve analizi

Bu bölüm, yayınlanmış ürünün standart kullanılabilirlik sezgisel yöntemlerine (Nielsen'in ilkeleri)
ve projenin kendi beyan ettiği tasarım değerlerine karşı geriye dönük, dürüst bir öz-değerlendirmedir
— bir pazarlama sunumu değildir. Bu projede dış kullanıcı olmadığı ve bir analitik/kullanıcı-testi
altyapısı bulunmadığı için nitel olarak değerlendirilmiştir.

| Sezgisel ilke | Güçlü olduğu yerler | Hâlâ zayıf olduğu yerler |
|---|---|---|
| **Sistem durumunun görünürlüğü** | Her listede, çıplak bir yükleniyor simgesi yerine gerçek içeriğinin şekline benzeyen parıldayan bir iskelet (skeleton) var (PR #47); düzenleyicide bir "Saved"/"Unsaved changes" (Kaydedildi/Kaydedilmemiş değişiklikler) rozeti (UI planının §7.4'ü); Feed sekmesinde görülmemiş gönderi rozeti. | Feed'in sabit 100 öğe sınırı kullanıcı için görünmez — daha eski gönderilerin var olduğunu ama gösterilmediğini kimse söylemiyor (§10, riskler). |
| **Sistem ile gerçek dünya arasındaki uyum** | "Liked by" (beğenenler), "mutual friends" (ortak arkadaşlar), "Friends"/"Requested"/"Add Friend" (Arkadaş/İstek Gönderildi/Arkadaş Ekle) etiketlerinin hepsi, veritabanı terimleri yerine sade, tanıdık sosyal-uygulama kelime dağarcığı kullanır (arayüz metninde asla "recipient," "shared_note" gibi terimler görünmez). | — |
| **Kullanıcı kontrolü ve özgürlüğü** | Yaygın durum için anında ve nihai bir silme yerine sil-sonra-geri-al bildirimi (snackbar); gönderilmiş bir arkadaşlık isteğini iptal etme; bir notu istediğiniz zaman yayından kaldırma. | Yorumlar bir kez gönderildikten sonra düzenlenemez ya da silinemez (§7.2, takip edilen bilinen bir eksik) — gerçek bir "geri dönüşü olmayan" nokta. |
| **Tutarlılık ve standartlar** | Bir değer ya da bölüm her göründüğünde/kaybolduğunda kullanılan tek bir paylaşılan `NotesErrorBanner`, tek bir paylaşılan `NotesEmptyState`, tek bir paylaşılan `PopOnChange` sekme (bounce) efekti, tek bir paylaşılan `AnimatedSwitcher`/`AnimatedSize` çapraz-geçiş deyimi — her ekran için ayrı ayrı animasyonlar değil, açık ve tekrarlanan bir mühendislik kuralı. | — |
| **Hata önleme** | Arkadaşlık-durumu butonu (Friends / Requested / Add Friend) zaten arkadaş olunan ya da zaten bekleyen bir istek olan biri için asla eyleme geçirilebilir bir "Add" (Ekle) kontrolü göstermez — gerçek bir hata (gereksiz/reddedilecek bir istek), sonradan zarifçe ele alınmak yerine doğrudan arayüz katmanında engellenir. | Yayınlama hâlâ mevcut tüm arkadaşlara ya-hep-ya-hiç şeklindedir; önceden belirli kişileri önizleme/hariç tutma imkânı yoktur (yalnızca kime ulaşacağını listeleyen sonradan bir onay vardır). |
| **Hatırlamak yerine tanıma** | "Liked by" listesi ortak-arkadaş sayılarını gösterir, böylece bir kullanıcı kendi arkadaş listesini hafızasından hatırlamak zorunda kalmadan potansiyel bir bağlantıyı tanıyabilir; benzer şekilde arkadaşlık-durumu butonu, kime zaten istek gönderdiğinizi hatırlama ihtiyacını ortadan kaldırır. | — |
| **Estetik ve minimalist tasarım** | Durum/vurgu gerektiren her yerde tutarlı şekilde kullanılan tek bir vurgu rengi (`#5865F2`) (favori altını, kasıtlı ve gerekçeli tek istisnadır — "yıldız = altın" kırılamayacak kadar güçlü bir kuraldır); ekranlar arasında rakip görsel sistemler yok. | — |
| **Kullanıcıların hataları tanıması, teşhis etmesi ve düzeltmesine yardım etme** | Tek, merkezi bir hata-insancıllaştırıcı (`userMessageForError`, §14.9), her ham Supabase/Postgrest hatasını belirli, eyleme geçirilebilir bir mesaja çevirir — bu, gerçek hatalar ortaya çıktıktan sonra birden fazla kez üzerinde çalışılmıştır (ör. aynı-şifre/yanlış-şifre mesaj çakışması). | — |

**Süs değil, bir UX aracı olarak hareket (motion).** PR #47–#56 aralığında kasıtlı, tekrarlanan bir
kalıp: eskiden *anlık* olan (bir rozetin belirmesi, bir rozet metninin değişmesi, bir listenin
yeniden sıralanması, bir değerin değişmesi) her durum geçişi tespit edilip kısa (200–300ms),
amaçlı bir animasyonla donatıldı — ya bir durumun gerçekten değiştiğini pekiştirerek
(beğenilme/favorilenme/sabitlenme durumuna geçerken `PopOnChange` sekme efekti) ya da aksi hâlde
sert bir kesme gibi görünecek bir düzen değişikliğini yumuşatarak (koşullu olarak beliren bir rozet
veya bölüm üzerinde `AnimatedSize`). Bu, kozmetik değil bir UX doğruluğu meselesi olarak ele
alındı — proje ortasında benimsenen çalışma kuralı: *bir ekran görünürken bir değer değişebiliyorsa,
onun belirmesi/kaybolması/yeniden sıralanması asla anlık bir kesme olmamalı.*

## 4. Rekabet ortamı

Dürüst bir konumlandırma, bir satış konuşması değil: Notes, mevcut hiçbir ürünle doğrudan
yarışmıyor — hiçbir ana akım ürünün doğrudan işgal etmediği bir kesişim noktasında duruyor; bu ya
gerçek (niş de olsa) bir açı, ya da bunun neden ölçekte inşa edilmediğinin kanıtı. Bir öğrenme
projesi için ikisini de aynı anda akılda tutmakta fayda var.

| Ürün | Özel notlar | Düzenleme (sabitleme/favori/arama) | Kapalı arkadaş grafiği | İçerik yayınlama/paylaşma | Beğeni/yorum etkileşimi | Ortak bağlantıları keşfetme |
|---|---|---|---|---|---|---|
| **Google Keep / Apple Notes** | ✅ | ✅ (etiketler, sabitlemeler) | ❌ (yalnızca bağlantıyla paylaşım, grafik yok) | ⚠️ bağlantı paylaşımı, akış (feed) değil | ❌ | ❌ |
| **Notion** | ✅ (çok daha zengin) | ✅ | ⚠️ (çalışma alanı üyeleri, kişisel bir arkadaş grafiği değil) | ⚠️ (sayfa paylaşımı/yayınlama) | ❌ | ❌ |
| **Instagram Close Friends / BeReal** | ❌ (not tutma değil) | ❌ | ✅ | ✅ (akış tarzı) | ✅ | ⚠️ (ortak arkadaşlar etrafında kurgulanmamış) |
| **Bu uygulama (Notes)** | ✅ | ✅ | ✅ (karşılıklı, istek tabanlı) | ✅ (tüm arkadaş grafiğinize) | ✅ (beğeniler + yorumlar) | ✅ (ortak-arkadaş sayısı + tek dokunuşla ekleme, PR #57) |

**Kapsam kararlarını bilgilendirmek için kullanılan çıkarımlar:**
- Salt not uygulamaları (Keep/Notes/Notion), ürünün *not tutma* yarısında tartışmasız daha olgun —
  daha zengin biçimlendirme, ekler, çok cihazlı senkronizasyon cilası. Notes kasıtlı olarak orada
  rekabet etmiyor (bkz. Hedef Olmayanlar, §5) — mevcut bir kısıtlama değil, tasarım gereği yalnızca
  düz metin.
- Sosyal-akış uygulamaları (BeReal/Close Friends), ölçekte *etkileşimde* (hikâyeler, beğeni/yorum
  ötesinde tepkiler, bildirimler) daha olgun. Notes'un push bildirimlerini açıkça hedef olarak
  belirlememesi (§5), bir üslup tercihi değil, o kategoriye kıyasla gerçek, güncel bir eksiktir.
- **Ortak-arkadaş-keşfi açısı (PR #57), tipik bir not uygulamasının yaptığından çok, Facebook gibi
  bir arkadaş-grafiği ürününün yaygınlaştırdığı şeye daha yakın** — kasıtlı olarak ödünç alındı,
  çünkü bir not uygulaması rakibinin özelliğini kendi adına taklit etmek yerine, doğrudan bu
  uygulamanın gerçek ayırt edici özelliğine (gerçek, kapalı bir arkadaş grafiği) hizmet ediyor.

## 5. Hedefler

- Bir kullanıcının kayıt olmasına, giriş yapmasına ve kendi özel notlarını yönetmesine (oluşturma/
  düzenleme/silme, sabitleme, favorileme, başlık veya içeriğe göre arama) izin vermek.
- Bir kullanıcının bir arkadaş grafiği kurmasına izin vermek: istek gönderme/kabul etme/reddetme/
  iptal etme, arkadaşlıktan çıkarma ve paylaşılan etkileşim yoluyla ortaya çıkan ortak arkadaşlar
  üzerinden yeni bağlantılar keşfetme (görebildiğiniz bir gönderiyi kimin beğendiği).
- Bir kullanıcının bir notu tüm arkadaşlarıyla paylaşmak üzere yayınlamasına ve kendi ile
  arkadaşlarının yayınladığı notların birleşik bir akışını görmesine izin vermek.
- Akış katılımcılarının yayınlanan notları beğenmesine ve yorumlamasına, bir gönderiyi kimin
  beğendiğini görmesine izin vermek.
- Tam hesap yaşam döngüsünü desteklemek: e-posta onayı ile kayıt, şifremi unuttum/sıfırlama,
  kullanıcı adı/avatar/şifre değişiklikleri.
- Yalnızca not listesinde değil, her ekranda tutarlı, canlandırılmış (animasyonlu), markaya uygun
  koyu bir arayüz sunmak.
- Hem web hem mobilde (Android) doğru çalışmak, e-posta derin bağlantı (deep-link) akışları dahil.

### Hedef olmayanlar (şimdilik)

- Notlar içinde zengin metin / ekler / görseller (yalnızca düz metin).
- Gerçek zamanlı (canlı) akış veya yorum güncellemeleri — veri abone olunarak değil, çekilerek
  alınır.
- Düz metin ötesinde zengin yorum özellikleri (dallanma/thread, beğeni-yorum ötesinde tepkiler).
  Kendi yorumunuzu temel düzeyde düzenleme/silme bir hedef-olmayan *değildir* — bu, takip edilen
  bir eksiktir, bkz. §7.2/§11.
- Uygulama içi rozetler dışında yeni beğeniler/yorumlar/arkadaşlık istekleri için push bildirimleri.
- Hesap silme (kullanıcının kendi başına yapabileceği).
- Yalnızca-arkadaşlar akışı ötesinde herkese açık/keşfedilebilir notlar (SmartAcademy'nin merkez
  (hub) modelinin aksine, küresel herkese açık bir akış yok).
- Yayınlanacak arkadaşların bir alt kümesini seçme — yayınlama her zaman *tüm* mevcut arkadaşları
  hedefler.
- Açık tema / tema değiştirici — uygulama tasarım gereği yalnızca koyu temadır (§12).
- Masaüstü/geniş-görünüm-alanı için optimize edilmiş bir düzen — iki kez açıkça ertelendi (UI planı
  §7.1/§8); mobil, onaylanmış birincil hedeftir, web yalnızca daha hızlı yerel geliştirme için
  vardır.

## 6. Hedef kullanıcılar

| Persona | Açıklama | İhtiyaçlar |
|---|---|---|
| **Not tutan kullanıcı** | Varsayılan kullanım senaryosu — Notes'u tamamen özel olarak kullanan biri. | Hızlı, güvenilir CRUD; büyüyen bir listeyi yönetmek için sabitleme/favori/arama; hiçbir notu kaybetmemek; unutulan bir manuel kaydetmeye hiçbir şeyin kurban gitmemesi için otomatik kaydetme. |
| **Sosyal paylaşımcı** | Bazı notlarını arkadaşlarıyla paylaşan bir not tutucu. | Tek adımda yayınlama, yalnızca arkadaşların gördüğüne dair güven (alıcıları listeleyen bir yayın-öncesi onayla pekiştirilmiş), kendi gönderileri üzerindeki etkileşime (beğeniler/yorumlar/kim-beğendi) görünürlük. |
| **Akış katılımcısı** | Not yayınlamış arkadaşları olan herkes. | Birleşik bir akış (arkadaş başına parçalanmış değil), beğenme/yorum yapma, başka kimin bir şeyi beğendiğini görme, arkadaş grafiğinin kendisini yönetme, arkadaş listelerini elle karşılaştırmadan yeni ortak bağlantılar keşfetme. |

## 7. Kapsam

### 7.1 Kapsamda, yayınlandı

- **Kimlik doğrulama (Auth)** — kullanıcı adıyla kayıt, e-posta onayı, giriş, kendi başına
  şifremi-unuttum/sıfırlama (web'de ve, gerçek donanımda doğrulanmamış olarak, Android derin
  bağlantılarında), çıkış yapma, onay e-postasını yeniden gönderme, her şifre alanında görünürlük
  aç/kapa düğmeleri.
- **Not CRUD'u** — oluşturma/düzenleme/silme (kaydırarak-geri-al-bildirimiyle silme *veya* bir
  taşma menüsü (overflow menu) öğesiyle silme, PR #38/#51), sabitleme, favorileme,
  **başlık veya içeriğe** göre arama/filtreleme (PR #36), yazarken otomatik kaydetme (1,5 saniyelik
  gecikme), canlı kelime/karakter sayacı, test edilebilir bir `NotesDataSource` ile desteklenmiş.
  Taşma menüsünden silme ve kaydırarak silme, aynı sil-ve-geri-al mantığından geçer.
- **Profil** — kullanıcı adı, avatar yükleme (değiştiğinde çapraz geçiş yapar, PR #55), şifre
  değiştirme.
- **Arkadaşlar** — kullanıcı adına göre arama, istek gönderme, kabul etme/reddetme, gönderilmiş bir
  isteği iptal etme, arkadaşlıktan çıkarma, tam yinelenen/kendine-istek/zaten-arkadaş koruma
  önlemleri, gelen istek sayısı rozeti ve her kişi satırında üç durumlu bir
  **arkadaşlık-durumu butonu** (Friends / Requested / Add Friend, PR #57) — böylece arama sonuçları,
  zaten bağlı olunan ya da zaten beklemede olan biri için yanıltıcı şekilde eyleme geçirilebilir bir
  "Add" hiçbir zaman göstermez.
- **Yayınlama ve akış** — alıcıları listeleyen bir yayın-öncesi onay penceresiyle (PR #37) bir notu
  tüm arkadaşlara birden yayınlama, kendi ve arkadaşların yayınlanan notlarını "You" (Sen)
  etiketlemesiyle birlikte gösteren birleşik bir akış, Feed gezinme hedefinde görülmemiş gönderi
  sayısı rozeti (PR #39).
- **Etkileşim** — yayınlanan/paylaşılan notlarda beğeniler ve yorumlar, ayrı bir gönderi-detay
  sayfasında gösterilir (modal bir sayfa değil, PR #35); bir gönderiyi kimlerin beğendiğini listeleyen
  bir **"liked by" (beğenenler) paneli** (PR #57) — siz de beğendiyseniz önce siz, sonra arkadaşlar,
  sonra ortak-arkadaş sayısı ve tek dokunuşluk bir "Add Friend" ile herkes.
- **Gezinme ve kabuk (shell)** — kalıcı alt gezinme (Notes/Feed/Friends), kalıcı Profil simgesi,
  `IndexedStack` üzerinden sekme başına durum koruması, sekme içeriğinin arka plan gradyanının
  görünmesine izin veren buzlu/yarı saydam bir gezinme çubuğu (PR #51).
- **Görsel/hareket tasarım sistemi** — *her* Notes ekranına uygulanmış tam bir koyu "eğlenceli ve
  yuvarlak hatlı" tema (yalnızca listeyle sınırlı olan önceki kısmi dağıtım durumunun üzerine),
  her platformda özel bir uygulama simgesi ve buna uyan koyu yerel açılış ekranları (PR #49/#53),
  uygulamanın Flutter şablon varsayılanından kullanıcıya görünen her yerde **Mini Projects**'e
  yeniden adlandırılması (PR #53/#54), her veri odaklı ekranda iskelet yükleme durumları ve
  özellikte koşullu olarak beliren her öğeyi kapsayan tutarlı bir çapraz-geçiş/sekme/kademeli-giriş
  hareket dili (PR #47–#56).
- **Test altyapısı** — `NotesDataSource` kalıbı (Notes → Profiller → Arkadaşlar → Akış → Kimlik
  Doğrulama), beş mantık alanının tamamında tamamlanmıştır, sahte (fake) nesneler kullanan
  toplamda 300'den fazla birim testi vardır.

### 7.2 Kapsamda, henüz başlanmadı / bilinen eksikler

- **Başka bir kullanıcının profilini görüntüleme** — bir arkadaşın avatarına (ya da "liked by"
  listesindeki bir beğenenin satırına) dokunmak, şu an arkadaşlık-durumu butonu dışında hiçbir şey
  yapmıyor. PR #9'dan önceki bir özellik denetiminden bu yana bir sonraki sosyal özellik olarak
  belirlenmiş, PR #57 itibarıyla hâlâ başlanmamış.
- **Kendi gönderdiğiniz yorumları düzenleme/silme** — bugün ne arayüzde ne de RLS katmanında bir yol
  yok, ham bir silme politikası dışında (`shared_note_comments_delete_self` veritabanı düzeyinde
  mevcut, ama hiçbir arayüz bunu çağırmıyor).
- **Akış sayfalama (pagination)** — akış, "daha fazla yükle" seçeneği olmadan en son 100 öğeyle
  sabit sınırlıdır — geçmiş denetimlerde defalarca işaretlenmiş, hiç ele alınmamış, mevcut kullanım
  ölçeğinde düşük öncelikli.
- **Kullanıcının kendi başına hesap silmesi.**
- **Kendi yayınladığınız notlardaki yeni beğeniler/yorumlar için bildirimler** (yalnızca arkadaşlık
  isteği rozeti ve görülmemiş-akış-gönderisi rozeti var — "birisi gönderinizi beğendi/yorumladı"
  diye hiçbir şey, o gönderinin "liked by" listesini ya da yorumlarını kendiniz açmadıkça
  görünmüyor).
- **Yayınlanacak arkadaşları seçme** — şu an ya hep ya hiç.
- **Toplu/optimize edilmiş ortak-arkadaş-sayısı getirme** — şu an "liked by" listesindeki her
  arkadaş-olmayan satır için bir RPC çağrısı yapılıyor; bu uygulamanın gerçek ölçeğinde (bir avuç
  beğenen) sorun değil, beğeni sayıları yüzlere ulaşırsa yeniden değerlendirilmesi gerekir.
- **PR #15'in Android derin bağlantı düzeltmesini ve PR #49'un Android/iOS yerel açılış
  ekranı/simgesini gerçek bir cihaz/emülatörde doğrulama** — hepsi uygulanmış ama gerçek
  Android/iOS donanımında hiç test edilmemiş; bu geliştirme ortamında SDK/emülatör ya da Mac yok.
- **`updateUsername`/`uploadProfileAvatar` için tam yol birim test kapsamı** — bugün yalnızca
  çıkış-yapılmış/geçersiz-girdi koruma cümleleri birim testine tabidir; gerçek Supabase'e dokunan
  yollar yalnızca entegrasyon testiyle test edilir (kasıtlı, kabul edilmiş bir eksik, bir gözden
  kaçma değil).

### 7.3 Açıkça kapsam dışı

Bkz. Hedef Olmayanlar (§5). Ayrıca planlanmayanlar: zengin içerik, gerçek zamanlı senkronizasyon,
herkese açık/küresel bir akış, yorum moderasyonu, masaüstüne özel bir düzen ya da açık bir tema.

## 8. Özellik dökümü

| Alan | Yetenek | Durum |
|---|---|---|
| Kimlik doğrulama | Kayıt / giriş / e-posta onayı | ✅ Yayınlandı |
| Kimlik doğrulama | Şifremi unuttum/sıfırlama (web) | ✅ Yayınlandı |
| Kimlik doğrulama | Şifremi unuttum/sıfırlama (Android derin bağlantı) | ⚠️ Uygulandı, gerçek donanımda doğrulanmadı |
| Kimlik doğrulama | Şifre görünürlüğü aç/kapa (tüm alanlar) | ✅ Yayınlandı |
| Profil | Avatar (değişince çapraz geçiş yapar), kullanıcı adı, şifre | ✅ Yayınlandı |
| Profil | Başka bir kullanıcının profilini görüntüleme | ⬜ Başlanmadı |
| Notlar | CRUD, sabitleme, favorileme | ✅ Yayınlandı |
| Notlar | Başlık veya içeriğe göre arama | ✅ Yayınlandı |
| Notlar | Kaydırarak-geri-al *ve* taşma menüsüyle silme | ✅ Yayınlandı |
| Notlar | Otomatik kaydetme + canlı kelime/karakter sayacı | ✅ Yayınlandı |
| Arkadaşlar | Arama / gönderme / kabul / reddetme / iptal / arkadaşlıktan çıkarma | ✅ Yayınlandı |
| Arkadaşlar | Bir kişi satırı göründüğü her yerde arkadaşlık-durumu butonu (Friends/Requested/Add) | ✅ Yayınlandı |
| Akış | Kendi + arkadaşların yayınlanan notlarının birleşimi | ✅ Yayınlandı |
| Akış | Görülmemiş gönderi sayısı rozeti | ✅ Yayınlandı |
| Akış | 100 öğe ötesinde sayfalama | ⬜ Başlanmadı |
| Etkileşim | Beğeniler, yorumlar (ayrı detay sayfası) | ✅ Yayınlandı |
| Etkileşim | "Liked by" listesi | ✅ Yayınlandı |
| Etkileşim | Beğenenlerden ortak-arkadaş keşfi | ✅ Yayınlandı |
| Etkileşim | Yorum düzenleme/silme | ⬜ Başlanmadı |
| Akış | Seçici (tüm-arkadaşlar-değil) yayınlama | ⬜ Başlanmadı |
| Büyüme | Push bildirimleri (beğeniler/yorumlar) | ⬜ Henüz planlanmadı |
| Büyüme | Hesap silme | ⬜ Henüz planlanmadı |
| Arayüz/Hareket | Koyu tema, her ekranda tam dağıtım | ✅ Yayınlandı |
| Arayüz/Hareket | İskelet yükleme, çapraz geçişler, sekmeler, kademeli listeler | ✅ Yayınlandı |
| Arayüz/Hareket | Buzlu/yarı saydam alt gezinme | ✅ Yayınlandı |
| Marka | Özel uygulama simgesi + adı ("Mini Projects") + koyu açılış ekranı | ✅ Yayınlandı |
| Arayüz/Hareket | Masaüstü/geniş-görünüm-alanı düzeni | ⬜ Ertelendi, planlanmadı |

## 9. Zaten alınmış önemli kararlar (ve nedenleri)

- **Yayınlanan not başına bir `shared_notes` satırı, alıcı başına değil** — orijinal alıcı-başına
  model, gönderi sahibinin kendi gönderisi üzerindeki etkileşimi görememesine yol açıyor ve
  yinelenen/parçalanmış akış kartları gösteriyordu. PR #13'te, orijinal şeklin etrafından
  dolanmak yerine bir not satırı (`shared_notes`) artı bir alıcılar birleşim tablosu
  (`shared_note_recipients`) olarak yeniden tasarlandı.
- **`friend_requests`/`friendships` durum geçişleri mevcut şema durumlarını yeniden kullanır** —
  ör. gönderilmiş-bir-isteği-iptal-etme, kontrol kısıtlamasının zaten izin verdiği ama hiçbir kod
  yolunun kullanmadığı bir `'cancelled'` durumunu kullanır, böylece gereksiz bir geçiş (migration)
  önlenir.
- **Kimlik doğrulamanın karar mantığı, tam bir sahte istemci yerine çıkarılmış saf fonksiyonlarla
  birim testine tabi tutulur** — Supabase'in `signUp`/`signInWithPassword` yanıtları, anlamlı
  şekilde sahtelenemeyecek oturum/kimlik anlamları taşır; yalnızca "bu yanıt ne anlama geliyor"
  dallanması (`interpretSignUpResponse`, `shouldRejectSignIn`) saf, test edilebilir fonksiyonlara
  ayrıştırılmaya değerdi.
- **Hata mesajları mümkün olduğunda Supabase'in kararlı `code` alanıyla eşleşir, mesaj metniyle
  değil** — önceki bir hata (aynı-şifre değişikliklerinin "Incorrect email or password"
  göstermesi), mesaj alt dizeleriyle eşleştirmeden kaynaklanıyordu; mesaj metni kararlı bir sözleşme
  değildir, hata kodları öyledir.
- **Küresel koyu tema, `MaterialApp` köküne uygulanır**, Notes'un gezinme alt ağacına
  sınırlandırılmaz — çünkü `ResetPasswordPage`, şifre-kurtarma derin bağlantısı için doğrudan kök
  gezinme yığınına eklenir, Notes'un kendi gezinme yığınını atlayarak; sınırlandırılmış bir tema
  geçersiz kılması bu ekranı temasız bırakırdı.
- **Kendi tablosunun politikasını atlaması gereken RLS için `SECURITY DEFINER` yardımcı
  fonksiyonları** — `is_shared_note_author()`, döngüsel bir RLS referansından kaçınır; aynı yaklaşım
  `mutual_friend_count()` (§13.6) için de yeniden kullanıldı; bu fonksiyon başka bir kullanıcının
  `friendships` satırlarını okumak zorundadır (RLS aksi hâlde her kullanıcıyı yalnızca kendi
  satırlarını görmekle sınırlar).
- **Ortak-arkadaş sayımı, toplu değil, satır başına çağrılan bir skaler RPC'dir** — uygulamaya
  geçmeden önce özel bir Plan-ajanı incelemesiyle doğrulandı (PR #57); bu uygulamanın gerçek
  ölçeğinde bir "liked by" listesinin bir avuç satırı vardır, bu yüzden SQL'in
  basitliği/incelenebilirliği, bir dizi+`unnest` toplu versiyonunun eklediği karmaşıklığa üstün
  geldi.
- **Hareket/animasyon kuralları, her ekran için ayrı kod değil, paylaşılan bileşenlerdir** —
  `PopOnChange` (aktif hâle gelince sekme efekti), `StaggeredListItem` (indekse değil öğe id'sine
  göre anahtarlanmış, kademeli solma+kayma girişi — böylece yeniden sıralama yanlış öğenin
  animasyonunu tekrarlamaz/atlamaz) ve koşullu olarak beliren içerik için tekrarlanan bir
  `AnimatedSize`/`AnimatedSwitcher` deyimi — özellikle yeni ekranların her seferinde yeni animasyon
  kodu icat etmek yerine aynı birkaç ilkeli yeniden kullanması için seçildi.
- **Yayınlama her zaman tüm arkadaş listesini hedefler**, seçilmiş bir alt kümeyi değil — daha
  basit bir model, gerçek bir sınırlama olarak kabul edildi (bkz. birikmiş işler listesi).
- **Şifre-sıfırlama hata mesajları kasıtlı olarak açığa vurmayan niteliktedir** —
  `sendPasswordResetEmail`, e-postanın kayıtlı olup olmadığından bağımsız olarak her zaman başarılı
  görünür, hesap varlığının sızdırılmasını önlemek için.
- **Uygulama yalnızca görüntü katmanında yeniden adlandırıldı ve simgesi değiştirildi** —
  `pubspec.yaml`'ın `name: new_project` alanı (her `import 'package:new_project/...'` ifadesinde
  kullanılan Dart paket tanımlayıcısı), uygulama "Mini Projects" olarak yeniden adlandırılırken
  (PR #53) kasıtlı olarak değiştirilmeden bırakıldı; paket tanımlayıcısını yeniden adlandırmak, salt
  kozmetik, kullanıcıya yönelik bir değişiklik için kod tabanındaki her import ifadesine dokunmayı
  gerektirirdi ve bu, yarattığı etki alanına değmezdi.

## 10. Riskler ve açık sorular

| Risk / soru | Notlar |
|---|---|
| Android/iOS yerel cila doğrulanmadı | Derin bağlantılar (PR #15), yerel açılış ekranları ve uygulama simgesi (PR #49/#53) hepsi uygulandı ama gerçek Android/iOS donanımında hiç test edilmedi — bu geliştirme ortamında SDK/emülatör ya da Mac yok. |
| RLS hataları birim testleriyle yakalanmıyor | Bir kez zaten oldu (PR #13'ün yazar-kendi-paylaşılan-alıcı-satırını-göremiyor hatası) — yalnızca canlı test bunu ortaya çıkardı. Yeni bir INSERT/UPDATE politikası ya da `mutual_friend_count` gibi yeni bir RPC, yalnızca gözden geçirilmek değil, canlı olarak da sağlaması yapılmalı. |
| Akış sayfalaması yok | Çok aktif arkadaş grafikleri olan kullanıcılar yalnızca en son 100 gönderiyi görür, daha eskilerin var olduğuna dair bir işaret ya da onlara ulaşmanın bir yolu olmadan. Mevcut kullanım ölçeğinde acil değil. |
| İçerik-arama alaka sıralaması yok | Arama başlık ya da içerikle eşleşir, ama sıralama/vurgulama yoktur — bir kez eşleşen çok uzun bir not, başlıkta eşleşen kısa bir nottan daha az öne çıkabilir. Henüz bilinen bir şikâyet değil, sadece incelenmemiş bir varsayım. |
| Alıcı ekleme veritabanı düzeyinde arkadaşlık kontrolü yapmıyor | `shared_note_recipients_insert_author` yalnızca ekleyenin bu paylaşılan notu yazdığını doğrular — alıcının gerçekten arkadaş olduğunu veritabanı katmanında yeniden doğrulamaz (PR #13'ün RLS özyineleme sorununu ayıklarken daha önceki bir kontrol kaldırılmıştı). "Kim alıcı olabilir" üzerindeki tek kapı, bugün uygulamanın kendi `fetchFriends()` tabanlı arayüzüdür. Uygulamanın kendi arayüzü üzerinden şu an istismar edilebilir değil, ama `shared_note_recipients`'a yeni bir yazma yolu eklenirse bilinmeye değer. |
| Ortak-arkadaş RPC'si toplu değil, satır başına | Çok sayıda arkadaş-olmayan beğeneni olan bir "liked by" listesi, o kadar sıralı ağ gidiş-dönüşü yapar. Mevcut ölçekte kabul edilebilir (bkz. §9); beğeni sayıları hiç büyürse `unnest` tabanlı toplu bir versiyon gerekecektir. |
| Otomatik görsel/animasyon regresyon testi yok | Tüm PR #47–#56 hareket-dili dağıtımı her seferinde tarayıcı önizlemesinde elle doğrulandı (Tarayıcı panelinin ekran görüntüsü aracı, bu geliştirme ortamında bilinen, çözülmemiş, aralıklı bir "pane not displayed" derleme hatasına sahip) — gelecekte, örneğin bir çapraz-geçiş süresinin ya da bir iskelet şeklinin gerçek içeriğinden sapmasının otomatik olarak yakalanmasının bir yolu yok. |

## 11. Önerilen yol haritası (sonraki adımlar, sıralanmamış)

Kullanıcı, PR'ları sabit bir sıraya bağlı kalmak yerine birer birer sıralıyor; aşağıdakiler bilinen
adaylardır, taahhüt edilmiş bir sıra değil:

1. Başka bir kullanıcının (bir arkadaşın ya da bir "liked by" listesi beğenenin) profilini
   görüntüleme — tekrarlanan özellik denetimlerinden en uzun süredir bekleyen madde, şimdi PR
   #57'nin keşif yüzeyiyle iki kat daha ilgili.
2. Yorum düzenleme/silme.
3. Android/iOS derin bağlantı, açılış ekranı ve simge çalışmasını gerçek donanım elde edildiğinde
   doğrulama.
4. Akış sayfalaması, içerik-arama alaka düzeyi, bildirimler, seçici arkadaş yayınlaması, toplu
   ortak-arkadaş-sayısı getirme ya da kullanıcının kendi başına hesap silmesi, öncelikler o yönde
   değişirse.

---

# BÖLÜM II — AYRINTILI ŞARTNAME

*Aşağıdaki her şey, uygulamanın bugün tam olarak (mevcut kaynak kod itibarıyla) nasıl davrandığını
belgeler, bir emeli değil. Alan adları, buton etiketleri ve hata dizeleri koddan birebir
kopyalanmıştır, böylece bu bölüm kendi başına işlevsel bir şartname olarak da hizmet edebilir.*

## 12. Uygulama iskeleti ve giriş noktası

- `main.dart`, Supabase'i başlatır, ardından `LearningFlutterApp`'i çalıştırır (Dart sınıf adı
  değişmedi — yalnızca kullanıcıya görünen görüntü adı değişti, aşağıya bakın), `home`'u
  `ProjectsHomePage`'dir (mini-projelerin genel gösterge paneli, kendisi de "Mini Projects" olarak
  adlandırılmıştır — Notes, doğrudan uygulamanın ana rotası değil, oraya dokunarak ulaşılan birkaç
  girişten biridir).
- **Uygulama kimliği (PR #53/#54):** uygulamanın kullanıcıya görünen adı, göründüğü her yerde
  **Mini Projects**'tir — Android başlatıcı etiketi, tarayıcı sekmesi başlığı (`MaterialApp.title`,
  Flutter'ın web motorunun çalışma zamanında `index.html`'in kendi `<title>` etiketinin üzerine
  yazmak için kullandığı değer — başlık önyüklemeden sonra boş kaldıktan sonra PR #54'te düzeltilen
  gerçek bir hata), iOS paket görüntü adı ve Windows/Linux pencere başlıkları. Özel bir simge
  (mavimsi mor `#5865F2` yuvarlak köşeli bir rozet üzerinde beyaz 2×2'lik bir uygulamalar-ızgarası
  şekli), Flutter'ın stok varsayılanının yerini her platformda alır. Dart paket tanımlayıcısı
  (`pubspec.yaml`'ın `name: new_project`'i) kasıtlı olarak değiştirilmeden bırakıldı (§9).
- **İlk çizimden itibaren her yerde yalnızca koyu tema.** `AppTheme.dark`/`ThemeMode.dark`,
  uygulama içi arayüzün tamamını kapsar; ayrıca *yerel* açılış/başlangıç ekranları da (Android
  `launch_background.xml`, iOS `LaunchScreen.storyboard` ve web sayfasının Flutter/CanvasKit
  çizim yapmadan önceki kendi arka planı) aynı koyu yüzey rengiyle (`#1E2128`) eşleşir, böylece
  hiçbir platformda soğuk başlatmada beyaz bir yanıp sönme olmaz (PR #49) — bu, düzeltilmeden önce
  "yalnızca koyu tema" bir uygulama için gerçek, görünür bir eksiklikti.
- `LearningFlutterApp`, `AppSupabase.client.auth.onAuthStateChange`'e, hangi ekranın o an
  gösterildiğinden bağımsız olarak aktif kalan, uzun ömürlü tek bir abonelik tutar. Bir
  `AuthChangeEvent.passwordRecovery` olayı gözlemlediğinde (bir kullanıcı bir şifre-sıfırlama
  e-posta bağlantısına dokunduğu ve Supabase bir "kurtarma" oturumu kurduğu anda tetiklenir):
  1. O kurtarma oturumundan `user.userMetadata['app']` değerini okur (kayıt anında ayarlanan bir
     etiket — ya `'notes'` ya da `'smart_academy'`; bu etiketten önceki eski hesaplarda bu değer
     yoktur).
  2. Etiket `'smart_academy'` ise, SmartAcademy'nin kendi şifre-sıfırlama sayfasını açar; aksi
     hâlde (etiketsiz/eski hesaplar dahil) Notes'un `ResetPasswordPage`'ini açar.
  3. Bu, küresel bir gezinici (navigator) ekleme işlemidir (`_navigatorKey.currentState?.push(...)`),
     bu yüzden bağlantı uygulamayı açtığında kullanıcının hangi ekranda olduğundan bağımsız olarak
     çalışır.

## 13. Veri modeli (Supabase / Postgres)

Tüm tablolar `public` şemasında yaşar; `auth.users`, Supabase'in yerleşik kullanıcı tablosudur. Her
tabloda Satır Düzeyinde Güvenlik (RLS) etkindir — bir satır, yalnızca eşleşen bir politika izin
veriyorsa, Postgres'in kendisi tarafından uygulama kodundan bağımsız olarak, belirli bir kullanıcıya
görünür/yazılabilir.

### 13.1 `public.notes` — bir kullanıcının özel notları

| Sütun | Tip | Notlar |
|---|---|---|
| `id` | uuid | Birincil anahtar, otomatik üretilir. |
| `user_id` | uuid | Sahip; `auth.users`'a yabancı anahtar, kullanıcı silinince zincirleme silinir. |
| `title` | text | Boş olamaz, varsayılan `''`. |
| `content` | text | Boş olamaz, varsayılan `''`. |
| `is_pinned` | boolean | Boş olamaz, varsayılan `false`. |
| `is_favorite` | boolean | Boş olamaz, varsayılan `false`. |
| `created_at` | timestamptz | Ekleme sırasında ayarlanır. |
| `updated_at` | timestamptz | Her UPDATE'te bir tetikleyici (trigger) tarafından otomatik olarak `now()`'a güncellenir. |

Hızlı, kullanıcı başına, en güncele göre sıralı listeleme için `(user_id, updated_at desc)`
üzerinde indekslenmiştir.

**RLS:** bir kullanıcı, yalnızca `user_id`'si kendi kimlik doğrulama id'sine eşit olan satırlarda
SELECT/INSERT/UPDATE/DELETE yapabilir — kesinlikle özeldir, istisnasızdır, tablo düzeyinde paylaşım
yoktur (paylaşım, bu tabloyu açığa çıkararak değil, aşağıda anlatılan `shared_notes`'a *kopyalayarak*
gerçekleşir).

### 13.2 `public.profiles` — kullanıcı başına bir satır, herkese açık kimlik

| Sütun | Tip | Notlar |
|---|---|---|
| `id` | uuid | Birincil anahtar, `auth.users` id'siyle aynı. |
| `username` | text | Boş olamaz, **global olarak benzersiz**, `^[a-zA-Z0-9_.-]{3,30}$` ile eşleşmeli (3–30 karakter: harfler, rakamlar, alt çizgi, nokta, tire). |
| `avatar_url` | text | Boş bırakılabilir — kullanıcı bir resim yükleyene kadar null'dır. |
| `created_at` / `updated_at` | timestamptz | Standart. |

**Otomatik oluşturma:** bir veritabanı tetikleyicisi her yeni `auth.users` satırında tetiklenir ve
otomatik olarak eşleşen bir `profiles` satırı ekler; başlangıç kullanıcı adını (tercih sırasına
göre) şuradan türetir: kayıt meta verisinde geçilen `username` → e-postanın `@` öncesindeki kısmı →
`user_<kullanıcı id'sinin ilk 8 karakteri>`. Bu, `ensureProfileForCurrentUser` uygulama-düzeyi
mantığı çalışmadan önce bile her kullanıcının her zaman *bir* profil satırına sahip olduğu anlamına
gelir.

**RLS:** giriş yapmış herhangi bir kullanıcı *herhangi bir* profili okuyabilir (kullanıcı adı arama
ve arkadaş bulma için gerekli) — profiller özel değildir. Bir kullanıcı yalnızca kendi profil
satırını ekleyebilir/güncelleyebilir.

### 13.3 `public.friend_requests` — arkadaşlık isteği yaşam döngüsü

| Sütun | Tip | Notlar |
|---|---|---|
| `id` | uuid | Birincil anahtar. |
| `sender_id` | uuid | İsteği kimin gönderdiği. |
| `receiver_id` | uuid | Kime gönderildiği. Tablo düzeyinde kontrol: `sender_id`'ye eşit olamaz. |
| `status` | text | `'pending'`, `'accepted'`, `'declined'`, `'cancelled'` değerlerinden biri. Varsayılan `'pending'`. |
| `created_at` / `updated_at` | timestamptz | Standart. |

Kısmi bir benzersiz indeks, tam olarak aynı yönde (aynı gönderen → aynı alıcı) iki *eşzamanlı
bekleyen* isteği önler — uygulamanın kendi mantığı, yeni bir isteğe izin vermeden önce her iki yönü
de ayrıca kontrol eder (bkz. §14.4).

**RLS:** bir kullanıcı, yalnızca gönderen veya alıcıysa bir isteği görebilir. Yalnızca gönderen bir
istek oluşturabilir (ve kendine değil). Gönderen ya da alıcı, bir isteğin durumunu güncelleyebilir
(kabul etme, reddetme ve iptal etmeyi kapsar — hepsi, o belirli geçişi yapmasına izin verilen taraf
tarafından gerçekleştirilen basit durum değişiklikleridir, uygulama mantığında zorunlu kılınır,
geçiş başına ayrı RLS kurallarıyla değil).

### 13.4 `public.friendships` — onaylanmış arkadaşlıklar

| Sütun | Tip | Notlar |
|---|---|---|
| `id` | uuid | Birincil anahtar. |
| `user_low_id` | uuid | İki arkadaş id'sinden sözlük sırasına göre küçük olanı. |
| `user_high_id` | uuid | Sözlük sırasına göre büyük olanı. |
| `created_at` | timestamptz | Arkadaşlığın kurulduğu zaman. |

Arkadaşlıklar **kurallaştırılmış sırada** saklanır (`user_low_id < user_high_id`, bir tablo
kontrolüyle zorunlu kılınır ve uygulama tarafından okuma/yazma sırasında tutarlı şekilde kullanılır),
böylece her arkadaşlık, kimin "baktığından" bağımsız olarak tam olarak bir satır olarak var olur ve
çift üzerinde bir benzersizlik kısıtlaması vardır.

**RLS:** bir kullanıcı, yalnızca iki taraftan biriyse bir arkadaşlık satırını görebilir — kritik
olarak bu, **bir istemcinin başka herhangi bir kullanıcının arkadaş listesini asla getiremeyeceği**
anlamına gelir, bu da tam olarak ortak-arkadaş sayımının (§13.6) neden düz bir sorgu yerine bir
`SECURITY DEFINER` RPC üzerinden gerçekleşmesi gerektiğinin nedenidir. Her iki taraf da satırı
ekleyebilir (bir istek kabul edildiğinde kullanılır) ya da silebilir (arkadaşlıktan çıkarma).

### 13.5 Paylaşım/akış tabloları

**`public.shared_notes`** — *yayınlanan not* başına bir satır (alıcı başına değil):

| Sütun | Tip | Notlar |
|---|---|---|
| `id` | uuid | Birincil anahtar. |
| `note_id` | uuid | Paylaşılan orijinal not; `notes`'a yabancı anahtar, silinince zincirleme silinir. |
| `author_id` | uuid | Yayınlayan kişi. |
| `title` / `content` | text | Yayınlama anındaki notun başlık/içeriğinin bir **kopyası** (yeniden yayınlandığında yeniden kopyalanır). |
| `published_at` | timestamptz | Not her (yeniden) yayınlandığında ayarlanır/tazelenir. |
| `updated_at` | timestamptz | Güncellemede otomatik olarak yükseltilir. |

`(note_id, author_id)` üzerinde benzersizdir — belirli bir not, bir seferde yalnızca bir aktif
"yayınlanmış" satıra sahip olabilir; yeniden yayınlama, bir kopya oluşturmak yerine bu satırı
yerinde günceller.

**`public.shared_note_recipients`** — birleşim tablosu, belirli bir paylaşılan notu kimin görebildiği:

| Sütun | Tip | Notlar |
|---|---|---|
| `shared_note_id` | uuid | `shared_notes`'a yabancı anahtar, zincirleme. |
| `recipient_id` | uuid | Bu gönderiyi görebilen bir arkadaş. |
| `created_at` | timestamptz | Alıcı olarak ne zaman eklendikleri. |

Birincil anahtar, `(shared_note_id, recipient_id)` çiftidir. Alıcı satırları uygulama tarafından
yalnızca eklenir, asla kaldırılmaz (zaten kapsanan bir arkadaşa yeniden yayınlamak, zararsız bir
no-op upsert'tir).

**`public.shared_note_likes`** — (gönderi, beğenen) başına bir satır:

| Sütun | Tip |
|---|---|
| `shared_note_id` | uuid, `shared_notes`'a yabancı anahtar, zincirleme |
| `user_id` | uuid, kimin beğendiği |
| `created_at` | timestamptz |

Birincil anahtar `(shared_note_id, user_id)` — bir kullanıcı belirli bir gönderiyi yalnızca bir kez
beğenebilir (iki kez beğenmek bir no-op/aç-kapa'dır, uygulama mantığında varsa-sil-yoksa-ekle olarak
ele alınır). Bu tablo hem her kartta gösterilen toplam beğeni sayısını **hem de** "liked by"
panelindeki tam beğenen listesini destekler (§13.6, §21) — panelin sorgusu
(`selectLikesForSharedNote`), aynı tablonun not-başına bir varyantıdır, mevcut not-başına yorum
sorgusunu birebir yansıtır.

**`public.shared_note_comments`** — yorum başına bir satır:

| Sütun | Tip | Notlar |
|---|---|---|
| `id` | uuid | Birincil anahtar. |
| `shared_note_id` | uuid | `shared_notes`'a yabancı anahtar, zincirleme. |
| `user_id` | uuid | Yorum yapan. |
| `content` | text | Boş olamaz; **1–500 karakter arasında olmalı** (bir veritabanı CHECK kısıtlamasıyla zorunlu kılınır, ekleme denenmeden önce uygulama düzeyinde doğrulamada da yansıtılır). |
| `created_at` | timestamptz | Standart. |

**Dört paylaşım tablosunun tamamındaki RLS**, tek, tutarlı bir kurala uyar: paylaşılan bir not
(ve beğenileri/yorumları), yazarına **ve** alıcı olarak listelenen herkese görünürdür; uygulamanın
arayüzünün ne gösterip göstermediğinden bağımsız olarak, veritabanı düzeyinde başka hiç kimse onu
hiç göremez. Yazmalar (ekleme), "notun yazarı olmalısınız" (notun kendisi ve alıcı satırları için)
ya da "kendiniz olarak hareket ediyor olmalısınız" (kendi beğenileriniz/yorumlarınız için) şeklinde
sınırlandırılmıştır. Bir yardımcı veritabanı fonksiyonu (`is_shared_note_author`), alıcılar
tablosunun görünürlük kontrolünün, `shared_notes`'un kendi politikası üzerinden döngüsel bir RLS
referansı tetiklemeden "ya da yazarsınız" durumunu içermesine özellikle izin vermek için vardır.

**Bilinen veritabanı düzeyi eksik:** bir alıcı satırı eklemeye izin veren politika yalnızca "bu
paylaşılan notu siz mi yazdınız" diye kontrol eder — alıcının veritabanı katmanında gerçekten
arkadaşınız olduğunu yeniden doğrulamaz. Bu kontrol yalnızca Dart uygulama mantığında var
(`publishNoteToFriends`, yalnızca gerçek arkadaş listenizde döner). Uygulamanın normal arayüzü
üzerinden istismar edilebilir değil, ama `shared_note_recipients`'a yazan yeni bir kod yolu
eklenmeden önce bilinmeye değer.

### 13.6 `public.mutual_friend_count` — bir tablo değil, bir RPC (PR #57)

```sql
mutual_friend_count(p_other_user_id uuid) returns integer
```

Çağıran kullanıcının `p_other_user_id` ile ortak kaç arkadaşı olduğunu, hiçbir tarafın gerçek
arkadaş-listesi satırlarını çağırana açığa çıkarmadan döndüren bir `SECURITY DEFINER` SQL
fonksiyonu (bir tablo değil) — yalnızca bir sayı döndürür. `friendships`'in RLS'i (§13.4) bir
kullanıcının yalnızca kendi arkadaşlık satırlarını görmesine izin verdiği için var; istemci
tarafında bir "arkadaşlarını getir ve kesişimi al" mimari olarak imkânsızdır. Yalnızca
`authenticated`'e verilmiştir (açıkça `anon`'a değil — çıkış yapmış bir çağıranın kimse hakkında
ortak-arkadaş sayısı hesaplamasına gerek yoktur). "Liked by" listesindeki her arkadaş-olmayan satır
için bir kez çağrılır, toplu değil (§9, §10).

### 13.7 Şema geçmişi notu

Paylaşım tablolarının önceki bir sürümü (`002` geçişi), `shared_notes`'u **(not, yazar, alıcı)
üçlüsü başına bir satır** olarak modelliyordu — yani, 5 arkadaşa yayınlamak, aynı not için 5 ayrı
satır oluşturuyordu. Bu gerçek bir hataya yol açtı: bir notun yazarı kendi *kendi* gönderisindeki
beğenileri/yorumları hiçbir zaman göremiyordu, çünkü her sorgu `recipient_id = siz` ile filtreleniyordu,
ve saf bir düzeltme, bir yerine 5 yinelenen, parçalanmış akış kartı gösterirdi. `004` geçişi bunu,
§13.5'te tarif edilen mevcut not-başına-bir-satır-artı-birleşim-tablosu şekline yıkıcı bir şekilde
yeniden tasarladı. Bu geçmiş bağlamsal olarak önemlidir (§9'un "neden"inde bahsedilmesinin sebebi
budur) ama *eski* şekil artık canlı şemada mevcut değildir.

### 13.8 Depolama

**`profile-pictures` klasörü (bucket)** — herkese açık klasör, 5 MB dosya boyutu sınırı, yalnızca
`image/jpeg`/`image/png`/`image/webp` kabul eder. Herkes içindeki herhangi bir dosyayı okuyabilir
(avatarlar tasarım gereği herkese açıktır). Bir kullanıcı yalnızca, ilk klasör segmenti kendi
kullanıcı id'siyle başlayan dosyaları yükleyebilir/güncelleyebilir/silebilir (uygulamanın kuralı
`<user_id>/avatar.<ext>`dir) — bu, yalnızca uygulama kuralıyla değil, `storage.objects` üzerindeki
RLS ile zorunlu kılınır.

## 14. Alan bazında iş kuralları

*(`NotesLogic`, arayüzün çağırdığı tek sınıftır; kalıcılığı, her biri gerçek bir Supabase
uygulaması ve yalnızca testlerde kullanılan bir sahte (fake) nesneye sahip değiştirilebilir
veri-kaynağı sınıflarına devreder.)*

### 14.1 E-posta ve kullanıcı adı geçerliliği (her yerde kullanılır)

- **Geçerli e-posta**: `^[^\s@]+@[^\s@]+\.[^\s@]+$` ile eşleşmeli (bir şey@birşey.birşey, boşluk
  yok).
- **Geçerli kullanıcı adı**: kırpılır ve küçük harfe çevrilir, ardından `^[a-zA-Z0-9_.-]{3,30}$` ile
  eşleşmelidir — yalnızca 3 ila 30 karakter, harfler/rakamlar/alt çizgi/nokta/tire.

### 14.2 Kayıt (`signUpWithUsername`)

1. Kullanıcı adı geçerli olmalı, aksi hâlde: *"Use 3-30 chars: letters, numbers, _, -, ."*
2. E-posta geçerli olmalı, aksi hâlde: *"Enter a valid email address."*
3. Supabase kaydını çağırır, hesabın meta verisini `app: 'notes'` (paylaşılan `auth.users`
   havuzunun daha sonra Notes ve SmartAcademy hesaplarını ayırt edebilmesi için) ve onay e-postası
   için bir yönlendirme adresiyle etiketler.
4. Yanıtı yorumlar:
   - Supabase e-postanın **zaten kayıtlı, onaylanmış bir hesap** olduğunu bildirirse (dönen
     kullanıcıda boş bir `identities` listesiyle tespit edilir): *"That email is already
     registered. Try logging in, or use \"Forgot password\" if you don't remember your
     password."*
   - Yeni hesap hâlâ e-posta onayına ihtiyaç duyuyorsa: Supabase'in geri verdiği herhangi bir
     oturum hemen tekrar çıkış yaptırılır (böylece onaylanmamış bir kullanıcı asla yarı-girişli
     bırakılmaz) ve arayüz bir "e-postanızı kontrol edin" mesajı gösterir ve onay e-postasını
     yeniden gönderme seçeneği sunar.
   - Hesap hemen tamamen onaylanmış ve etkinse (nadir — yalnızca e-posta onayı proje genelinde
     devre dışıysa): bir profil satırının var olması sağlanır ve arayüz giriş başarılıymış gibi
     devam eder.

### 14.3 Giriş (`signInWithEmail`)

1. E-posta geçerli olmalı, aksi hâlde *"Enter a valid email address."*
2. Supabase şifre girişini çağırır.
3. Sonuçtaki hesabın e-postası onaylanmamışsa, kullanıcı hemen tekrar çıkış yaptırılır ve şu
   gösterilir: *"Please confirm your email to activate your account."*
4. Diğer her Supabase kimlik doğrulama hatası, paylaşılan hata-insancıllaştırıcı üzerinden çevrilir
   (§14.9) — ör. yanlış şifre/e-posta, ham bir Supabase hata dizesi değil, *"Incorrect email or
   password. Please try again."* gösterir.

### 14.4 Arkadaşlık istekleri (`sendFriendRequestByUsername` ve ilgilileri)

Bir istek gönderme, sırayla, ilk ihlal edilen kuralda hızla başarısız olur:

1. Giriş yapılmış olmalı, aksi hâlde *"You are not logged in."*
2. Kullanıcı adı geçerli olmalı, aksi hâlde *"Enter a valid username."*
3. Bu kullanıcı adına sahip bir profil var olmalı, aksi hâlde *"No user found with that
   username."*
4. Kendiniz olamaz, aksi hâlde *"You cannot send a friend request to yourself."*
5. Zaten arkadaş olunamaz, aksi hâlde *"You are already friends."*
6. İkiniz arasında bekleyen bir istek zaten olamaz (**her iki** yönde de kontrol edilir), aksi
   hâlde *"A pending friend request already exists."*
7. Aksi hâlde, yeni bir bekleyen istek eklenir.

**Bir kişi satırına bir isteğin gönderilebileceği her yer** (Friends sekmesi arama sonuçları ve
"liked by" paneli), kullanıcı herhangi bir şeye dokunmadan *önce* bu durumu paylaşılan
`FriendStatusButton` bileşeni üzerinden çözer ve gösterir: `friend` (zaten arkadaş), `pending`
(zaten gönderilmiş bir istek) ya da `none` (göndermek güvenli). Bu, yukarıdaki 5. ve 6. kuralları
pratikte arayüz üzerinden fiilen erişilemez hâle getirir — bunlar mantık katmanında derinlemesine
savunma garantisi olarak kalır.

**Bir isteğe yanıt verme** (kabul/reddetme): yalnızca hâlâ *bekleyen* bir isteğin *alıcısı* yanıt
verebilir; diğer her durumda (zaten yanıtlanmış, yanlış kullanıcı, istek artık yok) aynı mesaj
gösterilir: *"This request can no longer be updated."* Kabul etme, aynı işlemde ilgili
`friendships` satırını da (kurallaştırılmış küçük/büyük sırada) oluşturur.

**Gönderilmiş bir isteği iptal etme**: yalnızca hâlâ bekleyen bir isteğin *gönderen*i iptal
edebilir; aksi hâlde *"This request can no longer be cancelled."* İptal etme, satırı silmek yerine
durumu `'cancelled'` olarak ayarlar (şemanın zaten izin verdiği bir durum).

**Bir arkadaşı çıkarma**: arkadaşlık satırını doğrudan siler; her iki taraf da bunu yapabilir
(uygulama mantığında ayrıca kontrol edilmez, RLS ile zorunlu kılınır).

### 14.5 Notları arkadaşlara yayınlama (`publishNoteToFriends` / `unpublishNoteFromFriends`)

- **Hiç arkadaşınız yoksa bir notu yayınlayamazsınız** — denemek şunu gösterir: *"Add at least
  one friend before publishing notes."*
- Gerçekten yayınlamadan önce, bir onay penceresi tam olarak kime ulaşacağını listeler (8 kullanıcı
  adı + daha büyük listeler için bir "ve N tane daha" sayısıyla sınırlıdır) — kullanıcı açıkça
  onaylamalıdır; iptal etmek notu yayınlanmamış bırakır ve düzenleyici içi aç/kapa düğmesini doğru
  şekilde geri çevrilmemiş bırakır.
- Yayınlama, notun *o anki* başlığını/içeriğini `shared_notes`'a kopyalar ve o anki tüm
  arkadaşlarınızı alıcı olarak ekler. Bir alt kümeye yayınlamanın yolu yoktur — her zaman "o an
  arkadaşım olan herkes"tir.
- Zaten yayınlanmış bir notu yeniden yayınlamak, mevcut paylaşılan kopyanın
  başlığını/içeriğini/zaman damgasını bir kopya oluşturmak yerine yerinde günceller; ayrıca son
  yayınlamadan bu yana kazanılan arkadaşları (yeniden) ekler, ama o zamandan beri arkadaşlıktan
  çıkarılmış bir alıcıyı asla kaldırmaz.
- Yayından kaldırma, `shared_notes` satırını tamamen siler, bu da alıcılarının, beğenilerinin ve
  yorumlarının da silinmesine zincirleme yol açar (hiçbir şey "yumuşak silinmez"). Yayından kaldırma
  **bir onay penceresi göstermez** (yalnızca yayınlama gösterir).

### 14.6 Akış (`fetchFriendsFeed`)

- Şunları gösterir: yazdığınız her gönderi, artı listelenen bir alıcı olduğunuz her gönderi, tek bir
  listede birleştirilmiş (gönderi id'sine göre yinelenenler kaldırılmış, en yeniden en eskiye
  sıralanmış, en son 100 ile sınırlı).
- Her öğe `isOwnPost` olarak etiketlenir, böylece arayüz kendi gönderileriniz için bir kullanıcı adı
  yerine "You" gösterebilir.
- Her öğe bir beğeni sayısı, bir yorum sayısı ve şu an *sizin* onu beğenip beğenmediğinizi taşır.

### 14.7 Yorumlar (`addFeedComment`)

- Giriş yapılmış olmalı, aksi hâlde *"You are not logged in."*
- (Kırpıldıktan sonra) boş olamaz, aksi hâlde *"Comment cannot be empty."*
- 500 karakteri aşamaz, aksi hâlde *"Comment is too long (max 500 characters)."* — bu, katı bir
  veritabanı kısıtlamasını yansıtır, bu yüzden bir istemci bu kontrolü atlasa bile hiçbir zaman
  aşılamaz.

### 14.8 Beğenenler ve ortak arkadaşlar (`fetchFeedLikers` / `fetchMutualFriendCount`, PR #57)

- `fetchFeedLikers(sharedNoteId)`, her beğeneni (id, kullanıcı adı, avatar, beğenme zaman damgası),
  en eskiden en yeniye, uygulamadaki diğer her kişi-listesinin kullandığı aynı profil-toplu-çözme
  yardımcısı üzerinden çözülmüş olarak döndürür.
- Mevcut kullanıcı, beğenenler arasındaysa, listeden **çıkarılmaz** ve en üste sıralanır, "You"
  olarak, arkadaşlık-durumu butonu olmadan gösterilir — önceki bir sürüm mevcut kullanıcıyı
  tamamen dışlıyordu, bu da görüntüleyen kişi *tek* beğenen olduğunda yanıltıcı bir "No likes yet"
  üretiyordu (aynı PR'da, canlı test bunu ortaya çıkardıktan sonra düzeltildi).
- Mevcut kullanıcıdan sonra, önce arkadaşlar sıralanır, sonra herkes başka — her grup kendi orijinal
  beğenme sırasını (en eskiden en yeniye) içeride korur.
- Her arkadaş-olmayan, kendisi-olmayan satır için `fetchMutualFriendCount` bir kez çağrılır (bkz.
  §13.6) ve sonucu çözüldüğünde "N mutual friends" olarak görüntülenir (aşamalı-iyileştirme
  yaklaşımlı bir getirme — satır hemen yalnızca bir arkadaşlık-durumu butonuyla çizilir, ardından
  o satırın RPC çağrısı tamamlandığında ortak sayı bir an sonra belirir).
- Bu listeden "Add Friend"e dokunmak, uygulamadaki her yerdeki aynı `sendFriendRequestByUsername`'i
  çağırır ve tüm listeyi yeniden yüklemeden o satırı iyimser bir şekilde `pending` durumuna
  çevirir.

### 14.9 Paylaşılan hata-insancıllaştırıcı (`userMessageForError`)

Her düşük seviyeli hata (Supabase Kimlik Doğrulama, Postgrest/veritabanı ya da Depolamadan),
kullanıcıya ulaşmadan önce tek, merkezi bir fonksiyondan çevrilir, böylece ham teknik hatalar asla
doğrudan gösterilmez. Sırayla kontrol edilen kurallar:

- Özellikle *mevcut* şifrenizle eşleştiği için reddedilen bir şifre değişikliği →
  *"Your new password must be different from your current password."* (Supabase'in kararlı
  `same_password` hata **koduyla** eşleştirilir, mesaj metniyle değil.)
- Kötü bir giriş gibi görünen herhangi bir şey (geçersiz kimlik bilgileri/şifre) →
  *"Incorrect email or password. Please try again."*
- Yinelenen bir e-postayla ilgili herhangi bir şey → *"That email is already registered."*;
  yinelenen kullanıcı adı → *"That username is already taken."*
- Onaylanmamış e-posta hataları → *"Your account needs email confirmation before login."*
- Hız sınırlama (rate-limiting) → *"Too many attempts. Please wait a moment and try again."*
- E-posta teslim/sağlayıcı yanlış yapılandırması → *"Registration email could not be sent. Please
  ask the app admin to finish Supabase email provider/SMTP setup."*
- Diğer her kimlik doğrulama hatası → genel *"Authentication failed. Please try again."*
- Bir veritabanı benzersizlik-kısıtlaması ihlali → *"That value is already in use."*; bir
  izin/RLS reddi → *"You do not have permission to do that."*
- Boyut ya da tür nedeniyle bir dosya-depolama reddi → *"That file is not supported. Use JPG,
  PNG, or WEBP up to 5MB."*; diğer her depolama hatası → *"Unable to upload file right now.
  Please try again."*
- Diğer her şey, hata mesajının düz, kırpılmış bir sürümüne, ya da mesaj boşsa çağıranın sağladığı
  bir yedek dizeye geri düşer.

---

# BÖLÜM III — SAYFA ENVANTERİ

Notes özelliğindeki her sayfa/yüzey, bir ürün bileşeni olarak belgelenmiştir: ne *için* olduğu, ne
*içerdiği*, kullanıcının ne *yapabileceği* ve onu yayınlamaya ya da ona karşı regresyon kontrolü
yapmaya uygun kılan somut kriterler. Bu bölüm, eski düz "ekran ekran gezinti" biçiminin yerini
alır — aynı bilgi burada, her sayfa kendi başına yeterli bir birim olacak şekilde düzenlenmiştir.

## 15. Not listesi (`NotesPage`, Notes sekmesi)

**Amaç:** giriş yapıldıktan sonraki varsayılan iniş yüzeyi — kendi özel notlarınıza göz atma,
düzenleme ve içlerine girme.

**İçerik:**
- "Notes" başlıklı bir uygulama çubuğu (sekmeler arasında geçişte çapraz geçiş yapar), bir Profil
  simgesi (avatarınızı, ya da yüklenirken küçük bir yükleniyor göstergesi gösterir) ve bir Çıkış
  simgesiyle birlikte.
- Bir arama kutusu (*"Search by title or content"*) ve üç filtre çipi — **All**, **Pinned**,
  **Favorites**.
- Küçük bir pencere açan bir **New** butonu (*"New Note"*, tek bir **Title** alanı) — başlığı boş
  bırakmak oluşturmayı sessizce iptal eder; başarı, doğrudan yeni not için düzenleyiciye atlar.
- Not başına bir satır (önce sabitlenmiş notlar, sonra en son güncellenene göre sıralanır), her
  biri şunları gösterir: başlık, iki satırlık bir içerik önizlemesi (ya da *"No additional
  text"*), son güncelleme zamanı, favori/sabitleme simge aç-kapaları ve **Publish to
  friends**/**Unpublish from friends** ile **Delete** (kırmızı, Publish'ten bir ayraçla ayrılmış)
  içeren 3 nokta taşma menüsü.
- Yayınlanmış bir notun önizlemesinin altında, yayınlanma durumu değiştikçe belirip kaybolarak
  canlanan bir **"Shared with friends"** rozeti belirir.
- Yükleniyor: gerçek listenin şekline benzeyen parıldayan bir iskelet. Boş (not yok, ya da mevcut
  arama/filtreyle hiçbiri eşleşmiyor): **"No notes yet — Create your first note to get
  started."** Hata: temalı bir hata bandı.

**Kullanıcı eylemleri:**
- Listeyi arama/filtreleme.
- Bir not oluşturma (hemen düzenleyiciyi açar).
- Düzenleyicide açmak için bir satıra dokunma.
- Favori/sabitlemeyi doğrudan aç-kapa yapma (aktif olurken dokunsal geri bildirim + sekme efekti).
- Taşma menüsünden yayınlama/yayından kaldırma (yayınlama önce bir alıcı-onay penceresi gösterir).
- Taşma menüsünden ya da satırı sola kaydırarak silme — ikisi de aynı sil-sonra-geri-al-bildirimi
  akışından geçer (silme kesinleşmeden önce **Undo**'ya dokunmak için birkaç saniye).
- Uygulama çubuğundan Profili açma ya da çıkış yapma.

**Kabul kriterleri:**
- Burada oluşturulan, düzenlenen, sabitlenen, favorilenen, yayınlanan ya da silinen bir not, tam
  liste yanıp sönmesi olmadan doğru ve hemen (iyimser bir şekilde) yansıtılır ve sunucudan gerçek
  bir yeniden yüklemeye dayanır.
- Arama, hem başlıkla hem de not içeriğiyle, büyük/küçük harf duyarsız şekilde eşleşir.
- Her iki yoldan da (menü ya da kaydırma) silme, bildirimin görünür süresi içinde geri alınabilir
  ve yalnızca kapatıldıktan/süresi dolduktan sonra geri alınamaz olur.
- Hiç arkadaş yokken yayınlama, genel bir hata değil, açık, belirli bir mesajla engellenir.
- Yükleniyor iskeletinin şekli, gerçek listenin düzenine geçişin görünür şekilde sıçramayacağı
  kadar yakın eşleşir.

## 16. Not düzenleyici (`NoteEditorPage`)

**Amaç:** bir notun tam içeriğini okuma ve düzenleme.

**İçerik:**
- Kenarlıksız, belge benzeri bir düzen: büyük bir başlık alanı, bir ayraç, ardından tam yükseklikte
  bir içerik alanı (yer tutucu *"Start writing..."*).
- Bir **Delete** simgesi (çöp kutusu) ve son düzenleme zamanı olan bir uygulama çubuğu.
- Başlıkta (liste satırıyla aynı simgeler/davranışla) doğrudan favori/sabitleme/yayınlama-durumu
  aç-kapaları.
- İçerik alanının altında, durumlar arasında çapraz geçiş yapan canlı bir kelime/karakter sayacı ve
  bir **"Unsaved changes"**/**"Saved"** durum rozeti.

**Kullanıcı eylemleri:**
- Başlık/içeriği düzenleme — son tuş vuruşundan 1,5 saniye sonra otomatik kaydeder (yalnızca
  değişiklik varken ve başlık boş değilken; düzenleme sırasında boş bir başlık, arka planda hata
  vermek yerine sessizce zamanlamayı atlar).
- Düzenleyiciden çıkmadan doğrudan favori/sabitleme/yayınlamayı aç-kapa yapma.
- Manuel olarak geri gitme — değişiklik varsa her zaman önce kaydetmeyi dener.
- Delete — bir onay penceresi açar (*"Delete Note"* / *"Are you sure you want to delete this
  note?"*), listenin geri-al-bildirimi kalıbının aksine, çünkü bu akış sildikten hemen sonra geri
  döner ve bir geri-alma penceresi kalıcı bir listede olduğu kadar doğal oturmaz.

**Kabul kriterleri:**
- Boş bir başlıkla kaydetmek, görünür bir bildirimle engellenir (*"Title cannot be empty."*) ve
  içeriği asla sessizce atmaz.
- Değişiklik/kaydedildi rozeti, her zaman gerçek kaydedilmemiş durumu doğru yansıtır, bir
  kaydetmeden hemen sonra ve onu izleyen yeni bir düzenlemeden hemen sonra dahil — takılı kalmış
  "Saved" ya da takılı kalmış "Unsaved" durumları yok.
- Manuel bir kaydetme/uzaklaşma zaten gerçekleştiyse otomatik kaydetme asla gereksiz bir yinelenen
  kaydetme tetiklemez.
- Buradan aç-kapa yapılan yayınlama, listedekiyle aynı alıcı-onay penceresini doğru şekilde
  gösterir ve pencere iptal edilirse yerel durumu çevirmeyi doğru şekilde reddeder.

## 17. Akış (`FeedPage`, Feed sekmesi)

**Amaç:** kendinizin ve arkadaşlarınızın yayınladığı notların birleşik, kronolojik bir görünümü.

**İçerik:**
- Yayınlanan not başına bir kart: yazar (kendi gönderileriniz için **"You"**, aksi hâlde
  **@kullanıcıadı**), yayınlama zamanı, başlık, içerik, dokunulabilir, kalın, birincil renkte bir
  sayıyla bir beğeni butonu, bir yorum simgesi + sayısı ve bir **"Read-only"** rozeti (bunun canlı
  orijinal değil, paylaşılan bir kopya olduğunu işaret eder).
- Kartlar, ilk yüklemede kademeli bir sırayla solarak+kayarak yerlerine gelir.
- Yükleniyor: kart listesine benzeyen bir iskelet. Boş: **"No shared notes yet — When your
  friends publish notes, they will appear here."**

**Kullanıcı eylemleri:**
- Yenilemek için çekme.
- Akıştan doğrudan bir kartı beğenme/beğenmekten vazgeçme (iyimser, bir dokunsal geri bildirim ve
  bir simge sekme efektiyle).
- "Liked by" panelini açmak için beğeni sayısına dokunma (§21).
- Gönderi-detay sayfasını açmak için bir karta ya da yorum simgesine dokunma (§18).

**Kabul kriterleri:**
- Akış, bir arkadaşın gönderisini o an listelenen bir alıcı olmayan birine asla göstermez ve
  kendi gönderilerinizi alıcı durumundan bağımsız olarak her zaman gösterir.
- Beğenme/beğenmekten vazgeçme, sayıyı ve simgeyi hemen günceller, başarıyla sessizce sunucuyla
  uyumlu hâle gelir ya da başarısızlıkta (bir hata bildirimiyle) geri döner.
- Görülmemiş-gönderi gezinme rozeti (§19), kullanıcının son akış ziyaretinden bu yana yayınlanan
  gönderileri doğru şekilde yansıtır ve görüntüleyenin kendi gönderilerini asla görülmemiş olarak
  saymaz.

## 18. Gönderi detayı (`FeedPostDetailPage`)

**Amaç:** akıştan ulaşılan, yayınlanmış bir notun ve yorumlarının tam görünümü.

**İçerik:**
- Yazar, yayınlama zamanı, tam başlık/içerik (uzunsa `ExpandableText`'in yumuşak yükseklik
  animasyonuyla genişletilebilir), bir beğeni satırı (simge + dokunulabilir sayı), ardından her
  yorumu (yazar, metin, tarih) satır satır listeleyen ve altında yeni bir tane eklemek için bir
  metin kutusu olan bir "Comments (N)" bölümü.
- Yükleniyor: özellikle yorumlar bölümü için bir iskelet (üstündeki başlık içeriği yeniden
  getirilmez, bu yüzden hemen çizilir).

**Kullanıcı eylemleri:**
- Beğenme/beğenmekten vazgeçme.
- "Liked by" panelini açmak için beğeni sayısına dokunma (§21).
- Tam not içeriğini okuma/genişletme.
- Yeni bir yorum gönderme (istemci tarafında boşsa engellenir; 500 karakter sınırı hem mantık
  katmanı hem de nihayetinde veritabanı tarafından zorunlu kılınır).

**Kabul kriterleri:**
- 500 karakterlik yorum sınırı, istemci tarafındaki kontrol bir şekilde atlansa da atlanmasa da
  aynı şekilde zorunlu kılınır (veritabanı CHECK kısıtlaması gerçek güvencedir).
- Bir yorum göndermek, kullanıcının sayfadan çıkıp yeniden girmesini gerektirmeden görünür yorum
  sayısını ve listeyi hemen günceller.

## 19. Friends & Feed gezinme kabuğu

**Amaç:** Notes/Feed/Friends'i kardeş sekmeler olarak barındıran, artı küresel bir Profil giriş
noktası olan kalıcı uygulama çerçevesi.

**İçerik:**
- Üç hedefi olan buzlu/yarı saydam bir alt `NavigationBar` (içinden bulanık içerik görünür) —
  Notes, Feed (rozet = görülmemiş gönderi sayısı), Friends (rozet = bekleyen gelen istek sayısı) —
  her rozet, sayısı sıfırdan sıfır-olmayana geçtiği anda bir sekme efektiyle içeri sekerek belirir.
- Uygulama çubuğunda, üç sekmenin hepsinde bulunan kalıcı bir Profil simgesi.
- Üç sekmenin hepsinde tutarlı, sekme içeriğinin arkasında yumuşak bir arka plan gradyanı.

**Kullanıcı eylemleri:**
- Sekmeler arasında geçiş yapma (her sekmenin kaydırma/arama/yüklenmiş-veri durumu, `IndexedStack`
  üzerinden geçişler arasında korunur, sıfırlanmaz).
- Herhangi bir sekmeden Profili açma.

**Kabul kriterleri:**
- Sekmeler arasında geçiş yapmak, bir sekmenin arama kutusunu, kaydırma konumunu ya da zaten
  yüklenmiş verisini asla sıfırlamaz.
- Rozet sayıları her zaman doğrudur ve sıfırdan-sıfır-olmayana her geçişte tam olarak bir kez
  canlanır, her yeniden çizimde tekrarlanmaz.

## 20. Friends (`FriendsTab`, Friends sekmesi)

**Amaç:** arkadaş grafiğini yönetme — kişileri bulma ve ekleme, isteklere yanıt verme, mevcut
arkadaşları gözden geçirme.

**İçerik:** dört bölüm, her biri kendi sınırlı kartında:
- **Arama** — bir kullanıcı adı arama kutusu + **Search** butonu; sonuçlar, kör bir "Add" değil,
  gerçek durumu yansıtan avatar/kullanıcı adı ve bir `FriendStatusButton` (Friends tik / Requested
  / Add Friend) gösterir. Eşleşme yok: **"No users found. Make sure the username is correct."**
- **Gelen istekler** (sayı rozeti, yeni bir gelişte sekme efekti) — her satır: avatar/kullanıcı
  adı + **Accept**/**Decline**. Boş: **"No pending incoming requests."**
- **Gönderilen istekler** — kaldırılabilir çipler (bekleyen giden istek başına bir tane); bir
  çipin silme simgesine dokunmak o isteği iptal eder. Boş: **"No pending outgoing requests."**
- **Friends** (başlıkta sayı) — avatar/kullanıcı adı + ne kadar süredir arkadaş olduğunuz + bir
  arkadaşlıktan-çıkarma simgesi (onay penceresi: *"Remove Friend"* / *"Remove @username from your
  friends? You'll need to send a new friend request to reconnect."*). Boş: **"No friends yet."**

Dört bölümün de içeriği, durumları değiştikçe anlık geçiş yapmak yerine yumuşak bir şekilde
yeniden boyutlanır (`AnimatedSize`).

**Kullanıcı eylemleri:**
- Bir kullanıcı adı arama ve onu eklemeye karar vermeden önce gerçek bağlantı durumunu görme.
- Bir isteği gönderme/kabul etme/reddetme/iptal etme; mevcut bir arkadaşı çıkarma.

**Kabul kriterleri:**
- Zaten arkadaş olunan ya da zaten beklemede olan biri için bir arama sonucu, dokunulduğunda
  yalnızca bir ret hatası üretecek eyleme geçirilebilir bir "Add" kontrolü asla göstermez.
- Bir isteği kabul etmek, tam olarak bir `friendships` satırı (kurallaştırılmış küçük/büyük
  sırayla) oluşturur, asla bir yinelenen değil.
- Her bölümün boş/dolu geçişi, anlık bir düzen sıçraması olmadan yumuşak bir şekilde canlanır.

## 21. "Liked by" paneli (`liked_by_sheet.dart`, PR #57)

**Amaç:** belirli bir gönderiyi kimin beğendiğini göstermek ve görüntüleyenin ortak arkadaşları
olan kişileri keşfetmesine/eklemesine yardımcı olmak.

**İçerik:** ekranın geri kalanı görünür şekilde arkasında bulanıklaştırılmış, kayan, ortalanmış,
yuvarlak köşeli bir panel (tam bir sayfa değil, kenardan kenara bir alt sayfa değil). Başlık:
"Liked by" + bir kapatma simgesi. Gövde: beğenen başına bir satır — siz de beğendiyseniz **önce
siz** ("You" olarak etiketlenmiş, durum butonu yok), sonra arkadaşlar (Friends tik), sonra
(çözüldüğünde bir ortak-arkadaş-sayısı alt başlığı ve bir Add Friend butonuyla) herkes başka.
Yükleniyor: ortalanmış bir yükleniyor göstergesi. Boş (kimse beğenmemiş, görüntüleyen de
beğenmemiş): **"No likes yet."**

**Kullanıcı eylemleri:**
- Panelin dışına (bulanık arka plana) ya da kapatma simgesine dokunarak kapatma.
- Arkadaş-olmayan bir satırda "Add Friend"e dokunma — bir istek gönderir ve listeyi yeniden
  yüklemeden o satırı iyimser bir şekilde "Requested"e çevirir.

**Kabul kriterleri:**
- Görüntüleyen tek beğenense, panel onu en üstte "You" olarak gösterir — asla yanıltıcı bir
  "No likes yet" göstermez (bu PR sırasında canlı olarak bulunup düzeltilen gerçek bir hata).
- Ortak-arkadaş sayıları, karşı tarafın gerçek arkadaş listesini asla açığa çıkarmaz, yalnızca bir
  sayı.
- Panel, zaten arkadaş olunan, zaten beklemede olan ya da görüntüleyenin kendisi olan biri için
  eyleme geçirilebilir bir Add-Friend kontrolü asla göstermez.

## 22. Profil (`NotesProfilePage`)

**Amaç:** kendi kimliğinizi yönetme — avatar, kullanıcı adı, şifre.

**İçerik:** üç bölümlü kart:
- **Avatar** — mevcut resim (değişince çapraz geçiş yapar) + **"Change profile picture"** (cihazın
  fotoğraf galerisini açar; resimler yüklenmeden önce yeniden boyutlandırılır/sıkıştırılır).
  Başarı: **"Profile picture updated."**
- **Kullanıcı adı** — tek bir alan, **"Save username"**. Başarı: **"Username updated."**
- **Şifre** — yeni/onay alanları (görünürlük aç-kapalarıyla), **"Update password"**. Başarı:
  **"Password updated."**, her iki alanı da temizler.

Yükleniyor: üç bölümün hepsinin şekline benzeyen bir iskelet.

**Kullanıcı eylemleri:** yeni bir avatar yükleme; kullanıcı adını değiştirme; şifreyi değiştirme.

**Kabul kriterleri:**
- Her alan, ağa hiç dokunmadan önce §14.1'deki aynı kurallarla istemci tarafında doğrulanır.
- Desteklenmeyen bir avatar dosya türü/boyutu, genel bir hata değil, belirli, doğru mesajı
  gösterir (§14.9).
- Başarılı bir şifre değişikliği her iki şifre alanını da temizler (asla eski bir değer görünür
  bırakmaz).

## 23. Kimlik doğrulama: Giriş / Kayıt (`NotesAuthPage`)

**Amaç:** çıkış yapmış kullanıcılar için giriş noktası.

**İçerik:** **"Welcome to Notes"** başlıklı, dairesel bir simge rozeti, bir Login/Register
segmentli aç-kapa, Email + Password (Register, üstte Username, altta görünürlük aç-kapalarıyla
Confirm password ekler) ve (yalnızca Login modunda) bir **"Forgot password?"** bağlantısı olan
tek bir kart.

**Kullanıcı eylemleri:** kayıt olma; giriş yapma; bir şifre sıfırlaması isteme; (kayıttan sonra
gösterildiğinde) bir onay e-postasını yeniden gönderme.

**Kabul kriterleri:**
- İstemci tarafı doğrulama (§14.1), herhangi bir ağ çağrısından önce geçersiz e-posta/kullanıcı
  adı/şifre şeklini yakalar.
- Şifremi-unuttum akışının yanıtı, e-postanın gerçekten kayıtlı olup olmadığından bağımsız olarak
  aynıdır (hesap-varlığı sızıntısı yok).
- Her farklı kimlik doğrulama hatası, ham bir Supabase hata dizesi değil, kendi belirli, doğru
  mesajını gösterir (§14.9).

## 24. "E-postanızı onaylayın" kapısı (`NotesActivationRequiredPage`)

**Amaç:** hesabın e-postası onaylanana kadar uygulamaya erişimi engelleme.

**İçerik:** tek bir kart: **"Please confirm your email to activate your account."** + **"Back to
login"** (çıkış yapar).

**Kullanıcı eylemleri:** çıkış yapma ve girişe dönme.

**Kabul kriterleri:** Supabase kendisi onun için bir oturum verse bile, onaylanmamış bir hesap
hiçbir kimlik doğrulamalı ekrana asla ulaşamaz.

## 25. Yeni bir şifre ayarlama (`ResetPasswordPage`)

**Amaç:** yalnızca e-postayla gönderilen bir sıfırlama bağlantısı üzerinden ulaşılan bir
şifre-sıfırlama akışını tamamlama.

**İçerik:** New password + Confirm new password (ikisi de görünürlük aç-kapalarıyla, 6 karakter
minimum, eşleşmeli).

**Kullanıcı eylemleri:** yeni bir şifre ayarlama.

**Kabul kriterleri:** başarı üzerine, uygulama nerede olursa olsun oraya geri döner ve
**"Password updated. You can now log in with it."** gösterir; akış, bağlantı uygulamayı açtığında
kullanıcının hangi ekranda olduğundan bağımsız olarak ulaşılabilirdir (küresel-gezinici ekleme,
§12).

---

# BÖLÜM IV — KABUL KRİTERLERİ

Bölüm III zaten sayfa düzeyinde kabul kriterlerini belirtir. Bu bölüm, bir üst düzeyde (bütün bir
işlevsel modül) ve ondan bir üst düzeyde (proje bütünü olarak) "tamamlanmış" sayılmanın ne anlama
geldiğini belirtir.

## 26. Modül düzeyinde kabul kriterleri

**Kimlik Doğrulama ve Hesap** — şu durumda kabul edilir: her farklı hata modu (yanlış şifre,
onaylanmamış e-posta, yinelenen e-posta/kullanıcı adı, aynı-şifre reddi, hız sınırlama) kendi doğru,
genel-olmayan mesajını gösterir; bir kullanıcı, hiçbir zaman bir çıkmaz sokağa ya da işlenmemiş bir
ham hataya çarpmadan kayıt → onay → giriş → şifremi unuttum/sıfırlama → kullanıcı adı/avatar/şifre
değiştirmeyi tamamlayabilir.

**Not CRUD'u** — şu durumda kabul edilir: oluşturma/düzenleme/silme/sabitleme/favorileme/arama,
normal kullanımda (otomatik kaydetme ve düzenleme ortasında uygulamanın arka plana alınması dahil)
hiçbir veri kaybı olmadan çalışır; silme, her iki giriş noktasından da (menü ve kaydırma) birkaç
saniyeliğine geri-alma yoluyla her zaman kurtarılabilirdir; arama başlık ve içerikle doğru ve
büyük/küçük harf duyarsız şekilde eşleşir.

**Arkadaşlar ve Sosyal Grafik** — şu durumda kabul edilir: tam istek yaşam döngüsü
(gönderme/kabul/reddetme/iptal/arkadaşlıktan çıkarma), kanıtlanabilir şekilde yinelenen-arkadaşlık
ya da yinelenen-bekleyen-istek durumlarından arınmıştır; uygulamadaki her yerdeki her kişi satırı
(arama sonuçları, liked-by listesi), paylaşılan `FriendStatusButton` üzerinden doğru, gerçek
zamanlı bağlantı durumunu gösterir, asla eski ya da yanıltıcı bir kontrol değil.

**Yayınlama ve Akış** — şu durumda kabul edilir: yayınlama her zaman yayın-öncesi pencerede
onaylanan arkadaş kümesine tam olarak ulaşır; akış, arayüzün gösterdiğinden bağımsız olarak RLS
katmanında bir gönderiyi asla alıcı-olmayan birine sızdırmaz; yayından kaldırma, bir gönderiyi ve
etkileşim verisini hiçbir yetim satır bırakmadan tamamen kaldırır.

**Etkileşim (Beğeniler/Yorumlar/Liked-by/Ortaklar)** — şu durumda kabul edilir: beğeni/yorum
sayıları her zaman akış kartı, detay sayfası ve liked-by paneli arasında tutarlıdır; liked-by
paneli, görüntüleyenin kendisi beğenmişken asla "bunu kimse beğenmedi" diye yanlış temsil etmez;
ortak-arkadaş sayıları doğrudur ve karşı tarafın gerçek arkadaş listesini asla sızdırmaz.

**Profil** — şu durumda kabul edilir: avatar/kullanıcı adı/şifre değişikliklerinin hepsi belirli,
doğru bir mesajla başarılı olur ya da başarısız olur ve başarılı bir değişiklik, bir uygulama yeniden
başlatması gerektirmeden o verinin göründüğü her yere (liste, akış, yorumlar, liked-by)
yansıtılır.

**Görsel/Hareket Tasarım Sistemi** — şu durumda kabul edilir: özellikteki her ekran, paylaşılan
koyu temayı ve paylaşılan animasyon ilkelerini kullanır (tek seferlik renkler yok, canlandırılmamış
koşullu olarak beliren içerik yok); uygulamanın kimliği (ad, simge, açılış ekranı), onu gösteren
her platform yüzeyinde tutarlıdır.

**Test Altyapısı** — şu durumda kabul edilir: önemsiz olmayan dallanma mantığına sahip her
`*Logic` metodu, kendi veri kaynağının sahte (fake) nesnesi üzerinden birim test kapsamına
sahiptir; birkaç gerçek-yalnızca-Supabase yolu (`updateUsername`'in `auth.updateUser` çağrısı,
`uploadProfileAvatar`'ın depolama yazması, gerçek RLS zorunlu kılınması) açıkça kabul edilmiş
istisnadır ve yalnızca entegrasyon testine tabidir, sessizce test edilmemiş değildir.

## 27. Projenin tamamı için kabul kriterleri

Bu, dış kullanıcısı olmayan bir öğrenme projesi olduğu için, "tamamlanmış" bir lansman tarihi ya da
kullanıcı-benimseme metriğiyle değil, nitel olarak tanımlanır:

- Bir kullanıcı, notlarını ve tüm sosyal grafiğini (arkadaşlar, yayınlama, etkileşim, keşif) hiçbir
  çıkmaz sokak, sessiz hata ya da yanıltıcı durum olmadan yönetebilir.
- Her hesap/kimlik doğrulama uç durumu, genel ya da yanıltıcı değil, doğru, belirli bir mesaj
  gösterir.
- Arayüz, özellikteki her ekranda görsel ve davranışsal olarak tutarlıdır — yalnızca ilk inşa
  edilen ekranda değil, her yerde uygulanan tek bir tasarım sistemi, tek bir hareket dili.
- Yayınlanan her artış küçük kalır, saf olduğu yerde mantık birim testine tabidir ve birleştirmeden
  önce (yalnızca gözden geçirilmez) canlı olarak doğrulanır — bu, PR #1'den beri bu depo için
  kurulmuş ve proje büyüdükçe hiç terk edilmemiş işbirliği kalıbıdır.
- Paylaşılan altyapıdaki değişiklikler (`auth.users` tetikleyicisi, kök derin-bağlantı dinleyicisi,
  `FriendStatusButton`/`PopOnChange`/`NotesErrorBanner` gibi paylaşılan bileşenler), yalnızca
  değişikliğe neden olan tüketici için değil, her tüketici için açıkça regresyon kontrolünden
  geçirilir.
- Yeni arka-uca-dokunan değişiklikler (yeni tablolar, RLS politikaları ya da RPC fonksiyonları),
  uygulamaya geçmeden önce özel bir tasarım/doğrulama sürecinden geçer — ya canlı bir Plan-ajanı
  incelemesi ya da eşdeğer bir titizlik — bu projenin yalnızca canlı testin hiç yakalayabildiği RLS
  hataları geçmişi göz önüne alındığında.
- Ürünün gerçek ayırt edici özelliği (hafif yayınlama ve etkileşime sahip, kapalı, karşılıklı bir
  arkadaş-grafiği — §4), o ayırt edici özelliğe bağlı bir neden olmadan ödünç alınan genel not
  uygulaması ya da genel sosyal-uygulama kurallarının altında kaybolmak yerine, arayüzde okunabilir
  kalır.

---

# BÖLÜM V — UÇTAN UCA KULLANICI AKIŞLARI

**A. Yeni bir kullanıcı kayıt olur, bir not yazar ve onu paylaşır:**
1. Notes'u açar → `NotesAuthPage`'i görür (giriş yapılmamış).
2. Register'a geçer, kullanıcı adı/e-posta/şifre/onay girer, gönderir.
3. *"Account created. Check your email to confirm it..."* alır, e-posta bağlantısını takip eder
   (bu aynı zamanda hesabı da onaylar), geri döner ve giriş yapar.
4. Boş not listesine iner (önce iskelet, sonra gerçek boş durum), **New**'e dokunur, bir başlık
   yazar, düzenleyiciye düşer, içerik yazar (otomatik kaydeder), geri çıkar.
5. Önce bir arkadaş ekler (Friends sekmesi → kullanıcı adı arama → henüz bağlı olunmadığı için
   "Add Friend" görür → gönderir → arkadaş kabul eder), çünkü hiç arkadaşı yokken yayınlama
   engellidir.
6. Not listesine geri döner, notun taşma menüsünü açar, **Publish to friends**'e dokunur,
   penceredeki alıcı listesini onaylar. Not artık **"Shared with friends"** rozetini gösterir.
7. Arkadaşı kendi Feed sekmesini açar (kademeli kart girişi), yeni gönderiyi görür, onu
   beğenebilir/yorumlayabilir ve başka kimin beğendiğini görmek için beğeni sayısına dokunabilir.

**B. Unutulmuş şifre (web):**
1. `NotesAuthPage`'te **"Forgot password?"**'a dokunur, e-postayı girer, sonuçtan bağımsız olarak
   nötr "eğer bir hesap varsa..." mesajını alır.
2. E-postayla gönderilen bağlantıyı takip eder → uygulama açılır, kök kimlik doğrulama dinleyicisi
   kurtarma olayını tespit eder, `app` meta veri etiketini (`'notes'`) okur ve açık olan ekrandan
   bağımsız olarak doğrudan `ResetPasswordPage`'i açar.
3. Yeni bir şifre ayarlar, bir onay bildirimi gösterilir, uygulamaya döner ve yeni şifreyle normal
   şekilde giriş yapar.

**C. Arkadaşlık isteği yaşam döngüsü:**
1. A, B'ye bir istek gönderir → B, "Incoming requests" altında bir rozetle görür; A, "Sent
   requests" altında bir çip olarak görür.
2. B reddeder → istek durumu `declined` olur; her iki listeden de kaybolur (yalnızca *bekleyen*
   istekler gösterilir), her bölümün kartı anlık geçiş yapmak yerine yumuşak bir şekilde yeniden
   boyutlanır.
3. A, o zamandan sonra istediği zaman B'ye yeni bir istek gönderebilir (bekleme süresi yok),
   1. adımı tekrarlar.
4. Alternatif olarak, A, B yanıt vermeden önce isteği kendisi iptal etmiş olabilir; bu da satırı
   silmek yerine yine sadece durumu değiştirir (`cancelled`e).

**D. Etkileşim yoluyla ortak bir bağlantı keşfetme (PR #57):**
1. A bir not yayınlar; hem B (A'nın bir arkadaşı) hem de C (A'nın görüntüleyeni D'ye bir yabancı)
   onu beğenir.
2. D — B'nin bir arkadaşı, ama C'ye henüz bağlı değil — gönderiyi açar ve beğeni sayısına dokunur.
3. "Liked by" paneli, en üstte B'yi gösterir (Friends tik, çünkü D ve B zaten bağlı), ardından
   altında bir ortak-arkadaş sayısıyla (D ve C en az bir ortak arkadaşı paylaşıyor, muhtemelen B)
   ve bir **Add Friend** butonuyla C'yi gösterir.
4. D, C'nin satırında **Add Friend**'e dokunur — hemen "Requested"e döner; C daha sonra kendi
   "Incoming requests"i altında isteğin belirdiğini görür ve onu kabul edebilir, özelliğin
   inşa edildiği keşiften-bağlantıya döngüsünü tamamlar.

---

## Sözlük

- **Paylaşılan not (Shared note)**: akışta görünen notun *yayınlanmış kopyası* — `notes`'taki özel
  orijinalden ayrıdır; yayınlandıktan sonra orijinali düzenlemek, yeniden yayınlamadıkça paylaşılan
  kopyayı güncellemez.
- **Alıcı (Recipient)**: belirli bir yayınlanmış notu görebilen bir arkadaş; alıcılar yalnızca
  yayınlama sırasında eklenir, otomatik olarak asla kaldırılmaz (ör. birini arkadaşlıktan çıkarmak,
  eski paylaşılan gönderileri geriye dönük olarak ondan gizlemez).
- **Kendi gönderisi (Own post)**: sizin yazar olduğunuz, bir kullanıcı adı yerine "You" etiketiyle
  gösterilen bir akış öğesi.
- **Beğenen (Liker)**: belirli bir yayınlanmış notu beğenmiş herkes; o notun "liked by" panelinde
  gösterilir.
- **Ortak arkadaşlar (Mutual friends)**: mevcut kullanıcının ve başka bir kişinin ortak olarak
  sahip olduğu arkadaşlar — karşı tarafın gerçek arkadaş listesini asla açığa çıkarmayan,
  yalnızca bir sayı veren, gizliliği koruyan bir RPC (§13.6) üzerinden sunucu tarafında
  hesaplanır.
- **Arkadaşlık durumu (Friend status)**: uygulamadaki her yerdeki herhangi bir kişi satırında
  paylaşılan `FriendStatusButton` üzerinden gösterilen üç durumdan biri (`friend`, `pending`,
  `none`) — böylece aynı kişi hiçbir zaman farklı yerlerde tutarsız ya da yanıltıcı şekilde
  eyleme geçirilebilir kontroller göstermez.
- **Aktivasyon** / **onaylanmış e-posta**: Supabase'in yerleşik e-posta-onayı durumu; uygulama,
  Supabase kendisi bir oturum vermiş olsa bile, onaylanmamış bir hesabı işlevsel olarak çıkış
  yapmış gibi ele alır (otomatik olarak çıkış yaptırır ve aktivasyon kapısını gösterir).
