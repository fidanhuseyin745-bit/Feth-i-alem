## Kaynak Türleri Enum
## Oyun içindeki tüm kaynak türlerini tanımlar

extends RefCounted

enum Type {
	GOLD = 0,
	FOOD = 1,
	MATERIALS = 2,
	WOOD = 3,
	IRON = 4,
	HORSES = 5,
}

## Kaynak türü bilgileri
static func get_info(type: Type) -> Dictionary:
	var info := {
		Type.GOLD: {
			"name": "Altın",
			"icon": "🪙",
			"color": Color(1.0, 0.84, 0.0),
			"description": "Temel para birimi"
		},
		Type.FOOD: {
			"name": "Yiyecek",
			"icon": "🌾",
			"color": Color(0.6, 0.8, 0.2),
			"description": "Orduyu beslemek için gerekli"
		},
		Type.MATERIALS: {
			"name": "Malzeme",
			"icon": "📦",
			"color": Color(0.7, 0.5, 0.3),
			"description": "İnşaat ve üretim için"
		},
		Type.WOOD: {
			"name": "Odun",
			"icon": "🪵",
			"color": Color(0.55, 0.35, 0.2),
			"description": "İnşaat ve ok yapımı"
		},
		Type.IRON: {
			"name": "Demir",
			"icon": "⚙️",
			"color": Color(0.4, 0.4, 0.45),
			"description": "Silah ve zırh üretimi"
		},
		Type.HORSES: {
			"name": "At",
			"icon": "🐴",
			"color": Color(0.8, 0.6, 0.4),
			"description": "Süvari birimleri için"
		}
	}
	return info.get(type, {"name": "Bilinmeyen", "icon": "❓", "color": Color.GRAY})

## Tüm kaynak türlerini listele
static func get_all_types() -> Array[Type]:
	return [Type.GOLD, Type.FOOD, Type.MATERIALS, Type.WOOD, Type.IRON, Type.HORSES]

## Tür adını al
static func get_name(type: Type) -> String:
	return get_info(type)["name"]

## Tür ikonunu al
static func get_icon(type: Type) -> String:
	return get_info(type)["icon"]