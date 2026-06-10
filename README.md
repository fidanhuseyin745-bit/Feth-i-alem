# Feth-i Alem - Açık Dünya Savaş Oyunu

## 🎮 Oyun Özeti

**Feth-i Alem**, 15. yüzyıl Osmanlı İmparatorluğu'nda geçen, açık dünya mobil strateji oyunudur. Oyuncular komutan olarak şehirleri fetheder, ordularını yönetir ve imparatorluğu genişletir.

## 🏗️ Özellikler

### 🎯 Temel Sistemler

| Sistem | Açıklama |
|--------|----------|
| **Açık Dünya** | 30+ şehir, köy ve kale içeren büyük harita |
| **Ordu Yönetimi** | Piyade, Süvari, Okçu birimleri |
| **Şehir Fethi** | Kuşatma ve kale içi savaş |
| **Kaynak Yönetimi** | Altın, Yiyecek, Malzemeler |
| **Meslek Sistemi** | 10+ farklı meslek (Savaşçı, Tüccar, Madenci...) |
| **Düşman AI** | 5 rakip fraksiyon |

### 🏰 Şehirler (30+)

**Anadolu:** İstanbul, Edirne, Bursa, Ankara, Kayseri, Konya, Sivas, Trabzon, Diyarbakır, Erzurum, Karaman, Niğde, Kırşehir, Bolu, İzmit, Biga, Sakarya

**Balkanlar:** Selanik, Filibe, Sofya, Belgrat, Budapeşte, Saraybosna, Kruje, İskodra

**Akdeniz:** Venedik, Kandiye, Rodos, Dubrovnik, Midilli

**Doğu:** Tebriz, Erivan, Kars, Musul, Halep, Şam

### ⚔️ Meslekler

| Meslek | Bonus |
|--------|-------|
| 🗡️ Savaşçı | +20% Hasar |
| 💰 Tüccar | +30% Satış |
| 🌾 Çiftçi | +50% Hasat |
| ⛏️ Madenci | +60% Maden |
| 🐟 Balıkçı | +70% Balık |
| 🔨 Demirci | +50% Silah |
| 🏹 Okçu | +50% Menzil |
| 💊 Şifacı | +50% İyileştirme |
| 🗺️ Kaşif | +60% Harita |
| 🛡️ Şövalye | +40% At |

### 🏗️ Bina Türleri

- 🏰 Kale - Savunma
- ⚔️ Kışla - Piyade üretimi
- 🐴 Ahır - Süvari üretimi
- 🏹 Okçuluk - Okçu üretimi
- 📦 Depo - Depolama
- 🕌 Cami - Gelir
- 🛁 Hamam - Gelir
- 🏪 Çarşı - Ticaret geliri

## 📁 Proje Yapısı

```
Feth-i-alem/
├── scenes/
│   ├── 3d/
│   │   ├── scripts/
│   │   │   ├── Unit.gd           # Birim sistemi
│   │   │   ├── Army.gd           # Ordu yönetimi
│   │   │   ├── City.gd           # Şehir sistemi
│   │   │   ├── CityManager.gd     # Şehir veritabanı
│   │   │   ├── WorldMap3D.gd      # Ana harita
│   │   │   ├── CameraController.gd # RTS kamera
│   │   │   ├── UnitSelection.gd   # Birim seçimi
│   │   │   ├── SiegeSystem.gd     # Kuşatma
│   │   │   ├── InteriorSystem.gd # Kale içi fetih
│   │   │   ├── EnemyAI.gd         # Düşman AI
│   │   │   ├── PlayerCharacter.gd # Oyuncu karakteri
│   │   │   ├── ProfessionSystem.gd # Meslek sistemi
│   │   │   ├── ModelFactory.gd    # 3D modeller
│   │   │   └── SoundManager.gd    # Ses sistemi
│   │   └── scenes/
│   │       └── MainGame3D.tscn   # Ana sahne
│   ├── ui/
│   │   ├── scripts/
│   │   │   ├── MobileUI.gd        # Mobil UI
│   │   │   └── GameHUD.gd        # HUD sistemi
│   │   └── scenes/
│   └── scripts/
│       ├── MainMenu.gd           # Ana menü
│       └── Utils.gd             # Yardımcı fonksiyonlar
└── project.godot                # Godot proje dosyası
```

## 🎮 Kontroller

### Mobil
- **Joystick (Sol alt)** - Hareket
- **Parmak kaydırma** - Kamera döndürme/yakınlaştırma
- **Tıklama** - Birim/sehir seçimi
- **Sağ tık / çift tık** - Hareket komutu

### PC
- **WASD / Ok tuşları** - Hareket
- **Fare tekerleği** - Zoom
- **Sol tık** - Seçim
- **Sağ tık** - Komut
- **A / D tuşları** - Kamera döndürme

## 🚀 Kurulum

1. Godot Engine 4.3+ indirin
2. Projeyi Godot'da açın
3. Ana sahneyi çalıştırın

## 🎯 Hedefler

1. **İstanbul'u Fethet** - Ana hedef
2. **Şehirleri Genişlet** - Bina inşa et
3. **Ordu Kur** - Birimler topla
4. **Ticaret Yap** - Kaynak topla
5. **Meslek Değiştir** - Farklı beceriler kazan

## 📜 Hikaye

1453 yılı... Osmanlı İmparatorluğu sınırlarını genişletmek için harekete geçti. Bizans'ın kalbi İstanbul, senin komutanlığında fethedilmeyi bekliyor. Balkanlar'dan Anadolu'ya, Akdeniz'den Ortadoğu'ya kadar tüm topraklar sana açık.

## 🛠️ Teknoloji

- **Motor:** Godot 4.3
- **Platform:** Mobil (Android) + PC
- **Grafik:** 3D
- **Dil:** GDScript

---

*☪️ Bu oyun tarihi bir kurgu oyunudur.*