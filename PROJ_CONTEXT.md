# FETH-İ-ALEM - Proje Bağlam ve Geliştirme Kılavuzu

## 📋 Proje Genel Bakış

| Özellik | Değer |
|---------|-------|
| **Proje Adı** | Feth-i Alem |
| **Tür** | Açık Dünya Mobil Strateji Oyunu |
| **Dönem** | 15. yüzyıl Osmanlı İmparatorluğu |
| **Engine** | Godot Engine 4.3+ |
| **Dil** | GDScript |
| **Platform** | Mobil (Android) + PC |
| **Mimari** | Autoload Singleton + Resource Sınıfları |

---

## 🎯 Proje Hedefleri

1. **Ana Hedef**: İstanbul'u fethetmek
2. **Yan Hedefler**: 
   - 30+ şehir ve bölge kontrolü
   - Ordu yönetimi (Piyade, Süvari, Okçu)
   - Kaynak ekonomisi (Altın, Yiyecek, Malzemeler)
   - Kale ve şehir fetih sistemleri
   - Meslek sistemi (10+ meslek)
   - Düşman AI fraksiyonları

---

## 📁 Mevcut Dosya Hiyerarşisi

```
Feth-i-alem/
├── PROJ_CONTEXT.md              # Proje bağlam ve kılavuz
├── README.md                     # Proje dokümantasyonu
├── project.godot                  # Godot proje konfigürasyonu (Autoload: ResourceManager, ResourceTypes)
├── export_presets.cfg            # Android export ayarları
│
├── autoloads/                    # Singleton Autoload sistemi
│   ├── ResourceTypes.gd         # Kaynak türleri enum
│   └── ResourceManager.gd       # Kaynak yönetim sistemi
│
├── scenes/
│   ├── MainMenu.tscn             # Ana menü sahnesi
│   ├── WorldMap.tscn              # Dünya haritası (2D)
│   │
│   ├── 3d/
│   │   ├── Game.gd               # 3D ana oyun döngüsü
│   │   ├── Game.tscn             # 3D sahne konteyneri
│   │   └── scenes/
│   │       └── MainGame3D.tscn   # 3D ana sahne
│   │
│   ├── scripts/
│   │   ├── game_state.gd        # [CORE] Oyun durumu (RefCounted, testlenebilir)
│   │   ├── WorldMap.gd           # 2D harita kontrolü
│   │   ├── MainMenu.gd           # Menü sistemi
│   │   └── Utils.gd              # Yardımcı fonksiyonlar
│   │
│   └── ui/
│       ├── scripts/
│       │   ├── MobileUI.gd       # Mobil UI controller
│       │   └── GameHUD.gd        # Oyun HUD sistemi
│       └── scenes/
│           └── GameHUD.tscn      # HUD sahne dosyası
│
├── tests/
│   └── unit/
│       └── test_game_state.gd    # GUT birim testleri
│
└── addons/
    └── gut/                       # Godot Unit Testing framework
```

---

## 🏗️ Mimari Kararlar

### Singleton (Autoload) Sistemi
```
Oyunun temel sistemleri Autoload olarak yüklenecek:
├── ResourceManager  → Kaynak toplama ve ekonomi yönetimi ✅
├── ResourceTypes    → Kaynak türleri enum ✅
├── ArmyManager      → Ordu ve birim yönetimi
├── CityManager      → Şehir ve kale veritabanı
├── GameState        → Oyuncu verisi, altın, tur sayısı, bölgeler
└── AudioManager      → Ses efekti ve müzik yönetimi
```

### Resource Sınıfları
```
Kaynak türleri Resource (.tres) dosyaları olarak tanımlanacak:
├── Resources/
│   ├── Gold.tres
│   ├── Food.tres
│   ├── Materials.tres
│   └── Units/
│       ├── Infantry.tres
│       ├── Cavalry.tres
│       └── Archer.tres
```

---

## 📊 Mevcut Autoload Sistemi

| Sistem | Durum | Dosya |
|--------|-------|-------|
| ResourceManager | ✅ Hazır | `autoloads/ResourceManager.gd` |
| ResourceTypes | ✅ Hazır | `autoloads/ResourceTypes.gd` |
| ArmyManager | ⏳ Planlanıyor | - |
| CityManager | ⏳ Planlanıyor | - |
| GameState | ⏳ Mevcut | `scenes/scripts/game_state.gd` |

### Kaynak Türleri
| Tür | Başlangıç | Üretim/Tur | Max |
|-----|-----------|------------|-----|
| 🪙 Altın | 5000 | +100 | 999999 |
| 🌾 Yiyecek | 1000 | +50 | 50000 |
| 📦 Malzeme | 500 | +25 | 25000 |
| 🪵 Odun | 300 | +15 | 15000 |
| ⚙️ Demir | 100 | +10 | 10000 |
| 🐴 At | 50 | +5 | 5000 |

---

## 🔧 Kod Standartları

### Dosya Adlandırma
- **Script dosyaları**: `PascalCase.gd`
- **Sahne dosyaları**: `PascalCase.tscn`
- **Kaynak dosyaları**: `PascalCase.tres`

### Fonksiyon Adlandırma
- **Public fonksiyonlar**: `camelCase()` veya `snake_case()`
- **Private fonksiyonlar**: `_leading_underscore()`
- **Signal fonksiyonları**: `on_signal_name()`

### Kod Yapısı
```gdscript
class_name MyClass
extends Node

# Sinyaller
signal my_signal(value: int)

# Önemli değişkenler
@export var my_export: int = 10
var _private_var: int = 5

# Onready değişkenleri
@onready var _node = $Path/To/Node

func _ready() -> void:
    pass

func public_function() -> void:
    pass

func _private_function() -> void:
    pass
```

---

## ⚡ Performans Kuralları

### Mobil Optimizasyon
1. **Döngüden kaçınma**: `for i in range(n)` yerine `while` kullanın
2. **Nodeleri az tutma**: 100+ node yerine `_level_of_detail` kullanın
3. **Texture boyutları**: Maksimum 1024x1024 pixel
4. **Shader karmaşıklığı**: Basit shaderlar tercih edin
5. **Frame rate**: 30 FPS hedef (Engine.set_target_fps(30))

### Kod Optimizasyonu
```gdscript
# KÖTÜ - Her frame'de obje oluşturma
func _process(delta):
    var arr = []  # Her frame yeni array
    for i in get_children():
        arr.append(i.name)

# İYİ - Önceden oluşturulmuş değişkenler
var _cached_names: Array = []
func _ready():
    for i in get_children():
        _cached_names.append(i.name)
```

---

## 🔄 Git Branch Stratejisi

```
main                    → Kararlı sürüm
├── feature/*           → Yeni özellikler
│   ├── feature/resource-system
│   ├── feature/army-manager
│   └── feature/city-conquest
├── fix/*               → Hata düzeltmeleri
│   ├── fix/mobile-ui-bug
│   └── fix/performance-issue
└── refactor/*          → Kod yeniden yapılandırma
```

### Commit Mesajları
```
feat: Yeni özellik eklendi
fix: Hata düzeltildi
refactor: Kod yeniden yapılandırıldı
docs: Dokümantasyon güncellendi
test: Test eklendi/güncellendi
perf: Performans iyileştirmesi
```

---

## 🚀 CI/CD Pipeline

GitHub Actions ile otomatik:
1. **Lint**: GDScript syntax kontrolü
2. **Test**: GUT birim testleri
3. **Build**: Android APK derleme
4. **Deploy**: (Gelecekte) Play Store

---

## 📝 Geliştirme Aşamaları

### Aşama 1: Temel Sistemler (Tamamlandı ✅)
- [x] Proje yapısı kurulumu
- [x] GameState temel sınıfı
- [x] **ResourceTypes enum** ✅
- [x] **ResourceManager Singleton** ✅
- [x] Kaynak toplama mekanizması
- [x] GUT birim testleri

### Aşama 2: Ordu Sistemi
- [ ] ArmyManager Singleton
- [ ] Birim üretimi (Piyade, Süvari, Okçu)
- [ ] Ordu hareket sistemi

### Aşama 3: Şehir ve Fetih
- [ ] CityManager Singleton
- [ ] Kale inşaat sistemi
- [ ] Şehir fetih mekanizması

### Aşama 4: UI/UX
- [ ] Mobil joystick kontrolü
- [ ] HUD yeniden tasarımı
- [ ] Animasyonlar

---

## 📚 Referans Kaynaklar

- [Godot 4.3 Dökümantasyonu](https://docs.godotengine.org/)
- [GUT Testing Framework](https://github.com/bitwes/Gut)
- [Mobil Optimizasyon Rehberi](https://docs.godotengine.org/en/stable/tutorials/mobile/)

---

*Bu dosya otomatik olarak oluşturulmuştur. Son güncelleme: 2026-06-13*
