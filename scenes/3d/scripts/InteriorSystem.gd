extends Node
class_name InteriorSystem

## İç Mekan Sistemi - Binalar ve Yapılar

signal room_entered(room_id: int)
signal room_exited(room_id: int)
signal interact_triggered(item_id: int)

@export var enable_interiors: bool = true
@export var interior_load_radius: float = 50.0

var current_interior: Node = null
var current_room_id: int = -1
var loaded_rooms: Dictionary = {}
var interactables: Array = []

func _ready():
	print("İç mekan sistemi hazır")

func enter_building(building_id: int):
	if not enable_interiors:
		return
	
	# Eski iç mekanı kaldır
	if current_interior:
		exit_current_room()
	
	# Yeni iç mekanı yükle
	_load_interior(building_id)
	emit_signal("room_entered", building_id)
	print("Bina girildi: " + str(building_id))

func _load_interior(building_id: int):
	# İç mekan sahnesi oluştur
	var interior_scene = Node3D.new()
	interior_scene.name = "Interior_" + str(building_id)
	add_child(interior_scene)
	current_interior = interior_scene
	
	# Basit iç mekan oluştur
	_create_default_interior(building_id, interior_scene)

func _create_default_interior(building_id: int, parent: Node):
	# Zemin
	var floor = MeshInstance3D.new()
	floor.name = "Floor"
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(20, 0.5, 20)
	floor.mesh = floor_mesh
	floor.position = Vector3(0, 0, 0)
	parent.add_child(floor)
	
	# Duvarlar
	for i in range(4):
		var wall = MeshInstance3D.new()
		wall.name = "Wall_" + str(i)
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(20, 5, 0.5)
		wall.mesh = wall_mesh
		wall.position = Vector3(0, 2.5, 9.75) if i == 0 else Vector3(0, 2.5, -9.75) if i == 2 else Vector3(9.75, 2.5, 0) if i == 1 else Vector3(-9.75, 2.5, 0)
		parent.add_child(wall)
	
	# Eşyalar
	_create_interactables(parent)

func _create_interactables(parent: Node):
	# Sandık
	var chest = MeshInstance3D.new()
	chest.name = "Chest"
	var chest_mesh = BoxMesh.new()
	chest_mesh.size = Vector3(2, 1, 1.5)
	chest.mesh = chest_mesh
	chest.position = Vector3(3, 0.5, 3)
	chest.add_to_group("interactable")
	parent.add_child(chest)
	interactables.append(chest)
	
	# Masa
	var table = MeshInstance3D.new()
	table.name = "Table"
	var table_mesh = BoxMesh.new()
	table_mesh.size = Vector3(4, 0.8, 2)
	table.mesh = table_mesh
	table.position = Vector3(-3, 0.4, -2)
	table.add_to_group("interactable")
	parent.add_child(table)
	interactables.append(table)
	
	# Sandalye
	var chair = MeshInstance3D.new()
	chair.name = "Chair"
	var chair_mesh = BoxMesh.new()
	chair_mesh.size = Vector3(1, 1.2, 1)
	chair.mesh = chair_mesh
	chair.position = Vector3(-3, 0.6, 0)
	chair.add_to_group("interactable")
	parent.add_child(chair)
	interactables.append(chair)

func exit_current_room():
	if current_interior:
		current_interior.queue_free()
		current_interior = null
		current_room_id = -1
		interactables.clear()
		print("Odadan çıkıldı")

func interact_with_object(object_name: String):
	for item in interactables:
		if item.name == object_name:
			_activate_interactable(item)
			return
	print("Etkileşim: " + object_name)

func _activate_interactable(item: Node):
	var item_id = interactables.find(item)
	emit_signal("interact_triggered", item_id)
	
	# Eşya türüne göre işlem yap
	match item.name:
		"Chest":
			_open_chest(item)
		"Table":
			_use_table(item)
		"Chair":
			_sit_on_chair(item)

func _open_chest(chest: MeshInstance3D):
	print("Sandık açıldı!")
	# Animasyon vs eklenebilir

func _use_table(table: MeshInstance3D):
	print("Masa kullanıldı!")

func _sit_on_chair(chair: MeshInstance3D):
	print("Sandalyeye oturuldu!")

func get_current_interior() -> Node:
	return current_interior

func get_interactables() -> Array:
	return interactables

func is_inside_building() -> bool:
	return current_interior != null