class_name ResMgr
## ResMgr - Kaynak Yöneticisi - Singleton Autoload
## Oyunun kaynak ekonomisini yönetir
## Mobil performans için optimize edilmiştir (minimum döngü)

extends Node

## Sinyaller
signal resources_changed(resource_type: int, new_amount: int)
signal insufficient_resources(resource_type: int, required: int, available: int)
signal resource_gained(resource_type: int, amount: int)

## Başlangıç değerleri
const INITIAL_GOLD := 5000
const INITIAL_FOOD := 1000
const INITIAL_MATERIALS := 500
const INITIAL_WOOD := 300
const INITIAL_IRON := 100
const INITIAL_HORSES := 50

## Kaynaklar (enum değeri -> miktar)
var _resources: Dictionary = {
	ResTypes.Type.GOLD: INITIAL_GOLD,
	ResTypes.Type.FOOD: INITIAL_FOOD,
	ResTypes.Type.MATERIALS: INITIAL_MATERIALS,
	ResTypes.Type.WOOD: INITIAL_WOOD,
	ResTypes.Type.IRON: INITIAL_IRON,
	ResTypes.Type.HORSES: INITIAL_HORSES,
}

## Maksimum kaynak limitleri
var _max_resources: Dictionary = {
	ResTypes.Type.GOLD: 999999,
	ResTypes.Type.FOOD: 50000,
	ResTypes.Type.MATERIALS: 25000,
	ResTypes.Type.WOOD: 15000,
	ResTypes.Type.IRON: 10000,
	ResTypes.Type.HORSES: 5000,
}

## Kaynak toplama oranları (tur başına)
var _production_rates: Dictionary = {
	ResTypes.Type.GOLD: 100,
	ResTypes.Type.FOOD: 50,
	ResTypes.Type.MATERIALS: 25,
	ResTypes.Type.WOOD: 15,
	ResTypes.Type.IRON: 10,
	ResTypes.Type.HORSES: 5,
}

## Önbelleklenmiş değerler (performans için)
var _cached_total: int = 0


func _ready() -> void:
	_calculate_total()


## ── Temel Get/Set İşlemleri ─────────────────────────────────────

## Kaynak miktarını al
func get_resource(type: ResTypes.Type) -> int:
	return _resources.get(type, 0)


## Tüm kaynakları sözlük olarak al
func get_all_resources() -> Dictionary:
	return _resources.duplicate(true)


## Kaynak miktarını ayarla
func set_resource(type: ResTypes.Type, amount: int) -> void:
	var clamped := clampi(amount, 0, _max_resources.get(type, 999999))
	var old := _resources.get(type, 0)
	if old != clamped:
		_resources[type] = clamped
		_calculate_total()
		resources_changed.emit(type, clamped)


## ── Kaynak İşlemleri ─────────────────────────────────────────────

## Kaynak ekle
func add_resource(type: ResTypes.Type, amount: int) -> bool:
	if amount <= 0:
		return false
	var current := get_resource(type)
	var new_amount := mini(current + amount, _max_resources.get(type, 999999))
	if new_amount > current:
		_resources[type] = new_amount
		_calculate_total()
		resources_changed.emit(type, new_amount)
		resource_gained.emit(type, new_amount - current)
		return true
	return false


## Kaynak harca (yeterli ise)
func spend_resource(type: ResTypes.Type, amount: int) -> bool:
	if amount <= 0:
		return true
	var current := get_resource(type)
	if current >= amount:
		_resources[type] = current - amount
		_calculate_total()
		resources_changed.emit(type, _resources[type])
		return true
	else:
		insufficient_resources.emit(type, amount, current)
		return false


## Birden fazla kaynak harca
func spend_resources(costs: Dictionary) -> bool:
	## Önce tüm maliyetleri kontrol et (performans için tek geçiş)
	for type in costs:
		if get_resource(type) < costs[type]:
			return false
	
	## Tüm maliyetleri uygula
	for type in costs:
		spend_resource(type, costs[type])
	return true


## ── Üretim ve Tur Sistemi ────────────────────────────────────────

## Tur sonu üretimini uygula
func process_turn_production() -> Dictionary:
	var produced := {}
	for type in _production_rates:
		var rate: int = _production_rates[type]
		if rate > 0:
			var added := mini(rate, _max_resources.get(type, 999999) - get_resource(type))
			if added > 0:
				_resources[type] = get_resource(type) + added
				produced[type] = added
				resource_gained.emit(type, added)
	
	_calculate_total()
	## Değişen tüm kaynaklar için sinyal
	for type in produced:
		resources_changed.emit(type, get_resource(type))
	
	return produced


## Üretim oranını ayarla
func set_production_rate(type: ResTypes.Type, rate: int) -> void:
	_production_rates[type] = maxi(0, rate)


## Üretim oranını al
func get_production_rate(type: ResTypes.Type) -> int:
	return _production_rates.get(type, 0)


## ── Bilgi Sorguları ──────────────────────────────────────────────

## Toplam kaynak değerini al
func get_total_resources() -> int:
	return _cached_total


## Yeterli kaynak var mı?
func has_resource(type: ResTypes.Type, amount: int) -> bool:
	return get_resource(type) >= amount


## Tüm kaynakların yeterli olup olmadığını kontrol et
func has_resources(costs: Dictionary) -> bool:
	for type in costs:
		if not has_resource(type, costs[type]):
			return false
	return true


## Maksimum kaynak limitini al
func get_max_resource(type: ResTypes.Type) -> int:
	return _max_resources.get(type, 999999)


## Maksimum limit ayarla
func set_max_resource(type: ResTypes.Type, max_amount: int) -> void:
	_max_resources[type] = maxi(0, max_amount)


## Kaynak yüzdesini al (0.0 - 1.0)
func get_resource_percentage(type: ResTypes.Type) -> float:
	var current := get_resource(type)
	var max_val := get_max_resource(type)
	if max_val <= 0:
		return 0.0
	return float(current) / float(max_val)


## ── Formatted Strings ────────────────────────────────────────────

## Kaynak bilgisini formatla
func get_resource_text(type: ResTypes.Type) -> String:
	var info := ResTypes.get_info(type)
	return "%s %d" % [info["icon"], get_resource(type)]


## Tüm kaynakları formatla
func get_all_resources_text() -> String:
	var lines := []
	for type in ResTypes.get_all_types():
		lines.append(get_resource_text(type))
	return "\n".join(lines)


## ── Yardımcı Fonksiyonlar ─────────────────────────────────────────

## Önbelleklenmiş toplamı güncelle
func _calculate_total() -> void:
	_cached_total = 0
	for type in _resources:
		_cached_total += _resources[type]


## Kaynakları sıfırla (yeni oyun için)
func reset() -> void:
	for type in ResTypes.get_all_types():
		match type:
			ResTypes.Type.GOLD:
				_resources[type] = INITIAL_GOLD
			ResTypes.Type.FOOD:
				_resources[type] = INITIAL_FOOD
			ResTypes.Type.MATERIALS:
				_resources[type] = INITIAL_MATERIALS
			ResTypes.Type.WOOD:
				_resources[type] = INITIAL_WOOD
			ResTypes.Type.IRON:
				_resources[type] = INITIAL_IRON
			ResTypes.Type.HORSES:
				_resources[type] = INITIAL_HORSES
		resources_changed.emit(type, _resources[type])
	_calculate_total()