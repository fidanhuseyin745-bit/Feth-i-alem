extends Node
class_name ModelFactory

## 3D Model Fabrikası - Basit mesh placeholder sistemi

static func create_unit_mesh(unit_type: String, team: String = "player") -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	
	# Renk - takım ve tipe göre
	match team:
		"player":
			material.albedo_color = _get_player_color(unit_type)
		"enemy":
			material.albedo_color = _get_enemy_color(unit_type)
		_:
			material.albedo_color = Color(0.5, 0.5, 0.5)
	
	material.metallic = 0.2
	material.roughness = 0.8
	
	var geometry
	
	match unit_type:
		"piyade", "infantry":
			geometry = _create_infantry_mesh()
		"süvari", "cavalry":
			geometry = _create_cavalry_mesh()
		"okçu", "archer":
			geometry = _create_archer_mesh()
		"komutan", "commander":
			geometry = _create_commander_mesh()
		_:
			geometry = _create_infantry_mesh()
	
	mesh.mesh = geometry
	mesh.material = material
	
	return mesh

static func _get_player_color(unit_type: String) -> Color:
	match unit_type:
		"piyade", "infantry": return Color(0.2, 0.5, 0.2)  # Yeşil
		"süvari", "cavalry": return Color(0.6, 0.4, 0.1)   # Kahverengi
		"okçu", "archer": return Color(0.3, 0.6, 0.1)     # Koyu yeşil
		"komutan", "commander": return Color(0.9, 0.7, 0.1) # Altın sarısı
		_: return Color(0.2, 0.2, 0.5)

static func _get_enemy_color(unit_type: String) -> Color:
	match unit_type:
		"piyade", "infantry": return Color(0.8, 0.2, 0.2)  # Kırmızı
		"süvari", "cavalry": return Color(0.7, 0.1, 0.1)   # Koyu kırmızı
		"okçu", "archer": return Color(0.6, 0.1, 0.1)     # Bordo
		"komutan", "commander": return Color(0.5, 0.1, 0.5) # Mor
		_: return Color(0.5, 0.2, 0.2)

static func _create_infantry_mesh() -> Mesh:
	# Piyade - Silindir + küre kafa
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.35
	cylinder.height = 1.2
	return cylinder

static func _create_cavalry_mesh() -> Mesh:
	# Süvari - At + binici (küçük silindir)
	var box = BoxMesh.new()
	box.size = Vector3(1.5, 1.0, 2.5)
	return box

static func _create_archer_mesh() -> Mesh:
	# Okçu - İnce silindir
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.25
	cylinder.bottom_radius = 0.3
	cylinder.height = 1.3
	return cylinder

static func _create_commander_mesh() -> Mesh:
	# Komutan - Büyük silindir + küre kafa
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.4
	cylinder.bottom_radius = 0.45
	cylinder.height = 1.5
	return cylinder

static func create_building_mesh(building_type: String, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	material.metallic = 0.1
	material.roughness = 0.9
	
	var geometry
	
	match building_type:
		"kale":
			material.albedo_color = Color(0.4, 0.4, 0.4)
			geometry = _create_fortress_mesh(size)
		"kışla":
			material.albedo_color = Color(0.5, 0.3, 0.2)
			geometry = _create_barracks_mesh(size)
		"cami":
			material.albedo_color = Color(0.9, 0.9, 0.8)
			geometry = _create_mosque_mesh(size)
		"pazar":
			material.albedo_color = Color(0.8, 0.6, 0.4)
			geometry = _create_market_mesh(size)
		"depo":
			material.albedo_color = Color(0.6, 0.5, 0.3)
			geometry = _create_storage_mesh(size)
		"sur":
			material.albedo_color = Color(0.5, 0.45, 0.4)
			geometry = _create_wall_mesh(size)
		_:
			material.albedo_color = Color(0.6, 0.5, 0.4)
			geometry = BoxMesh.new()
			geometry.size = size
	
	mesh.mesh = geometry
	mesh.material = material
	
	return mesh

static func _create_fortress_mesh(size: Vector3) -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(size.x * 1.2, size.y * 2, size.z * 1.2)
	return box

static func _create_barracks_mesh(size: Vector3) -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(size.x, size.y * 0.8, size.z)
	return box

static func _create_mosque_mesh(size: Vector3) -> Mesh:
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = size.x * 0.4
	cylinder.bottom_radius = size.x * 0.5
	cylinder.height = size.y * 1.5
	return cylinder

static func _create_market_mesh(size: Vector3) -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(size.x * 0.8, size.y * 0.5, size.z * 0.8)
	return box

static func _create_storage_mesh(size: Vector3) -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(size.x * 0.7, size.y * 0.6, size.z * 0.7)
	return box

static func _create_wall_mesh(size: Vector3) -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(size.x, size.y * 1.5, size.z * 0.3)
	return box

static func create_city_mesh(city_type: int, owner: String = "ottoman") -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	material.metallic = 0.3
	material.roughness = 0.7
	material.albedo_color = _get_city_color(owner)
	
	var geometry
	
	match city_type:
		0:  # Village
			geometry = _create_village_mesh()
		1:  # Town
			geometry = _create_town_mesh()
		2:  # City
			geometry = _create_city_mesh()
		3:  # Fortress
			geometry = _create_fortress_mesh_full()
		4:  # Capital
			geometry = _create_capital_mesh()
		_:
			geometry = _create_town_mesh()
	
	mesh.mesh = geometry
	mesh.material = material
	
	return mesh

static func _get_city_color(owner: String) -> Color:
	match owner:
		"ottoman": return Color(0.9, 0.7, 0.1)
		"byzantine": return Color(0.3, 0.5, 0.9)
		"karamanid": return Color(0.2, 0.7, 0.4)
		"albania": return Color(0.85, 0.2, 0.2)
		"venice": return Color(0.6, 0.3, 0.8)
		"akkoyunlu": return Color(0.9, 0.5, 0.1)
		_: return Color(0.5, 0.5, 0.5)

static func _create_village_mesh() -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(6, 3, 6)
	return box

static func _create_town_mesh() -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(10, 5, 10)
	return box

static func _create_city_mesh() -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(15, 8, 15)
	return box

static func _create_fortress_mesh_full() -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(12, 10, 12)
	return box

static func _create_capital_mesh() -> Mesh:
	var box = BoxMesh.new()
	box.size = Vector3(20, 12, 20)
	return box

static func create_flag_pole(owner: String = "ottoman") -> MeshInstance3D:
	var pole = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.1
	mesh.bottom_radius = 0.1
	mesh.height = 8
	pole.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = _get_city_color(owner)
	material.metallic = 0.5
	pole.material = material
	
	return pole

static func create_tree() -> MeshInstance3D:
	var tree = MeshInstance3D.new()
	var trunk = CylinderMesh.new()
	trunk.top_radius = 0.2
	trunk.bottom_radius = 0.3
	trunk.height = 3
	tree.mesh = trunk
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.25, 0.1)
	tree.material = material
	
	return tree

static func create_rock() -> MeshInstance3D:
	var rock = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = randf_range(0.5, 1.5)
	sphere.height = randf_range(1, 3)
	rock.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.4, 0.35)
	rock.material = material
	
	return rock

static func create_selection_circle(team: String = "player") -> MeshInstance3D:
	var circle = MeshInstance3D.new()
	var ring = TorusMesh.new()
	ring.inner_radius = 0.8
	ring.outer_radius = 1.0
	circle.mesh = ring
	
	var material = StandardMaterial3D.new()
	if team == "player":
		material.albedo_color = Color(0.9, 0.7, 0.1, 0.5)
	else:
		material.albedo_color = Color(0.9, 0.2, 0.2, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle.material = material
	
	return circle

static func create_health_bar() -> MeshInstance3D:
	var bar = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 0.1, 0.1)
	bar.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 0.2)
	bar.material = material
	
	return bar

static func create_arrow() -> MeshInstance3D:
	var arrow = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.05
	cylinder.height = 1.5
	arrow.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.3, 0.1)
	arrow.material = material
	
	return arrow