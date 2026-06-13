extends Node3D

## Feth-i Alem - Ana Oyun Kontrolörü
## Genshin Impact tarzı açık dünya, fetihler, kaleler, meslekler

const ConquestSystem = preload("res://scenes/3d/scripts/ConquestSystem.gd")
const ProfessionSystem = preload("res://scenes/3d/scripts/ProfessionSystem.gd")
const CastleSystem = preload("res://scenes/3d/scripts/CastleSystem.gd")
const MobileOptimizer = preload("res://scenes/3d/scripts/MobileOptimizer.gd")
const PlayerController = preload("res://scenes/3d/scripts/PlayerController.gd")

# Sistemler
var conquest_system: ConquestSystem
var profession_system: ProfessionSystem
var castle_system: CastleSystem
var mobile_optimizer: MobileOptimizer

# Oyuncu
var player: PlayerController

# Oyun durumu
var gold: int = 5000
var turn: int = 1
var food: int = 1000
var materials: int = 500

# Referanslar
@onready var cities_node = $Cities
@onready var units_node = $Units
@onready var ui = $UI

func _ready() -> void:
	# Mobil optimizasyon
	mobile_optimizer = MobileOptimizer.new()
	add_child(mobile_optimizer)
	
	# Oyun sistemleri
	conquest_system = ConquestSystem.new()
	profession_system = ProfessionSystem.new()
	castle_system = CastleSystem.new()
	
	# Dünya oluştur
	_setup_world_environment()
	_create_world()
	_create_player()
	_create_castles()
	_create_npcs()
	_setup_ui()
	_setup_mobile_controls()
	
	# Sinyaller
	_setup_signals()
	
	print("=== FETH-İ ALEM BAŞLADI ===")
	print(conquest_system.get_map_summary())

func _setup_world_environment() -> void:
	# Yüksek kalite rendering
	var env = Environment.new()
	
	# Sky
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.rayleigh = 2.5
	sky_mat.turbidity = 3.0
	sky_mat.moon_stepsize = 10
	sky.sky_material = sky_mat
	env.sky = sky
	
	# Ambient
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.6)
	env.ambient_light_energy = 0.7
	
	# Glow
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.1
	env.glow_bloom = 0.25
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	
	# Tonemapping
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	
	# SSAO
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.5
	
	# SDFGI
	env.sdfgi_enabled = true
	env.sdfgi_ray_count = 6
	
	# Fog
	env.fog_light_color = Color(0.6, 0.65, 0.75)
	env.fog_density = 0.002
	
	# Environment ayarla
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	# Güneş ışığı
	var sun = DirectionalLight3D.new()
	sun.transform.basis = Basis.from_euler(Vector3(-50, 45, 0))
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.shadow_blend = 0.5
	add_child(sun)

func _create_world() -> void:
	# Zemin
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(500, 500)
	plane.subdivide_depth = 64
	plane.subdivide_width = 64
	ground.mesh = plane
	ground.transform.origin = Vector3(0, -1, 0)
	
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.35, 0.55, 0.25)
	ground_mat.roughness = 0.9
	ground.material = ground_mat
	add_child(ground)
	
	# Ağaçlar
	_spawn_trees()
	
	# Dağlar
	_spawn_mountains()
	
	# Su
	_create_water_bodies()

func _spawn_trees() -> void:
	var tree_positions = [
		Vector3(30, 0, 40), Vector3(-40, 0, 20), Vector3(60, 0, -30),
		Vector3(-20, 0, 60), Vector3(80, 0, 50), Vector3(-60, 0, -40),
		Vector3(20, 0, 80), Vector3(-80, 0, 30), Vector3(40, 0, -60),
		Vector3(10, 0, 30), Vector3(-30, 0, -20), Vector3(50, 0, 20)
	]
	
	for pos in tree_positions:
		var tree = _create_tree()
		tree.transform.origin = pos + Vector3(randf() * 8 - 4, 0, randf() * 8 - 4)
		add_child(tree)

func _create_tree() -> Node3D:
	var tree = Node3D.new()
	
	# Gövde
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.35
	cyl.height = 3.5
	trunk.mesh = cyl
	trunk.transform.origin = Vector3(0, 1.75, 0)
	
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.25, 0.15)
	trunk_mat.roughness = 0.95
	trunk.material = trunk_mat
	tree.add_child(trunk)
	
	# Yapraklar
	for i in range(3):
		var leaves = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 2.0 - i * 0.4
		sphere.height = 2.5 - i * 0.5
		leaves.mesh = sphere
		
		var leaves_mat = StandardMaterial3D.new()
		leaves_mat.albedo_color = Color(0.15 + randf() * 0.1, 0.5 + randf() * 0.2, 0.1)
		leaves_mat.roughness = 0.85
		leaves.material = leaves_mat
		
		leaves.transform.origin = Vector3(0, 4 + i * 1.2, 0)
		tree.add_child(leaves)
	
	return tree

func _spawn_mountains() -> void:
	var positions = [
		Vector3(-200, 0, -150), Vector3(200, 0, -180), Vector3(0, 0, -250),
		Vector3(-150, 0, 150), Vector3(180, 0, 120)
	]
	
	for pos in positions:
		var mountain = MeshInstance3D.new()
		var cone = ConeMesh.new()
		cone.radius = 40 + randf() * 20
		cone.height = 60 + randf() * 30
		mountain.mesh = cone
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.5, 0.55)
		mountain.material = mat
		
		mountain.transform.origin = pos
		mountain.transform.origin.y = mountain.mesh.height / 2
		mountain.scale = Vector3(2, 1.5, 2)
		add_child(mountain)

func _create_water_bodies() -> void:
	var positions = [
		Vector3(-50, -0.8, 30), Vector3(70, -0.8, -40)
	]
	
	for pos in positions:
		var water = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(25, 18)
		water.mesh = plane
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.35, 0.65)
		mat.metallic = 0.2
		mat.roughness = 0.15
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.75
		water.material = mat
		
		water.transform.origin = pos
		add_child(water)

func _create_player() -> void:
	player = PlayerController.new()
	player.name = "Player"
	player.transform.origin = Vector3(0, 0, 0)
	add_child(player)

func _create_castles() -> void:
	# Kale sisteminden görsel kaleler oluştur
	var castles_data = castle_system.castles
	
	for castle_id in castles_data:
		var data = castles_data[castle_id]
		var castle = _create_castle_visual(data)
		castle.transform.origin = data["position"]
		add_child(castle)
		
		# Şehir node'u
		var city = _create_city_visual(data)
		city.transform.origin = data["position"] + Vector3(5, 0, 5)
		add_child(city)

func _create_castle_visual(data: Dictionary) -> Node3D:
	var castle = Node3D.new()
	
	var faction_colors = {
		"ottoman": Color(0.9, 0.7, 0.1),
		"byzantine": Color(0.3, 0.5, 0.9),
		"karamanid": Color(0.2, 0.7, 0.4),
		"albania": Color(0.85, 0.2, 0.2),
		"venice": Color(0.6, 0.3, 0.8),
		"akkoyunlu": Color(0.9, 0.5, 0.1)
	}
	
	var owner_color = faction_colors.get(data["owner"], Color.WHITE)
	
	# Ana kale gövdesi
	var main = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(6 + data["level"], 5 + data["level"] * 2, 6 + data["level"])
	main.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = owner_color * 0.8
	mat.metallic = 0.3
	mat.roughness = 0.7
	main.material = mat
	castle.add_child(main)
	
	# Kuleler
	for i in range(data["level"]):
		var tower = MeshInstance3D.new()
		var tower_mesh = CylinderMesh.new()
		tower_mesh.top_radius = 1.2
		tower_mesh.bottom_radius = 1.5
		tower_mesh.height = 4
		tower.mesh = tower_mesh
		
		var tower_mat = StandardMaterial3D.new()
		tower_mat.albedo_color = owner_color
		tower.material = tower_mat
		
		tower.transform.origin = Vector3(-2.5 + i * 5, 4.5 + data["level"], -2.5)
		castle.add_child(tower)
		
		# Bayrak
		var flag = MeshInstance3D.new()
		var flag_mesh = PlaneMesh.new()
		flag_mesh.size = Vector2(0.8, 0.5)
		flag.mesh = flag_mesh
		
		var flag_mat = StandardMaterial3D.new()
		flag_mat.albedo_color = owner_color
		flag_mat.emission_enabled = true
		flag_mat.emission = owner_color * 0.3
		flag.material = flag_mat
		
		flag.transform.origin = Vector3(-2.5 + i * 5, 7 + data["level"], -2.5)
		castle.add_child(flag)
	
	# Duvarlar (yüksek seviye)
	if data["level"] >= 3:
		for angle in range(4):
			var wall = MeshInstance3D.new()
			var wall_mesh = BoxMesh.new()
			wall_mesh.size = Vector3(0.4, 2.5, 2.5)
			wall.mesh = wall_mesh
			
			var rot = angle * PI / 2
			wall.transform.origin = Vector3(cos(rot) * 4, 1.25, sin(rot) * 4)
			wall.transform.basis = Basis.from_euler(Vector3(0, rot, 0))
			
			var wall_mat = StandardMaterial3D.new()
			wall_mat.albedo_color = owner_color * 0.6
			wall.material = wall_mat
			castle.add_child(wall)
	
	return castle

func _create_city_visual(data: Dictionary) -> Node3D:
	var city = Node3D.new()
	
	# Şehir binaları
	var faction_colors = {
		"ottoman": Color(0.9, 0.7, 0.1),
		"byzantine": Color(0.3, 0.5, 0.9),
		"karamanid": Color(0.2, 0.7, 0.4)
	}
	
	var color = faction_colors.get(data["owner"], Color.WHITE)
	
	for i in range(5):
		var building = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1.5, 2 + randf() * 2, 1.5)
		building.mesh = box
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color * (0.7 + randf() * 0.3)
		building.material = mat
		
		building.transform.origin = Vector3(randf() * 6 - 3, box.size.y / 2, randf() * 6 - 3)
		city.add_child(building)
	
	# İsim
	var label = Label3D.new()
	label.text = data["name"]
	label.font_size = 24
	label.position = Vector3(0, 6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	var label_mat = StandardMaterial3D.new()
	label_mat.albedo_color = Color.WHITE
	label.material = label_mat
	city.add_child(label)
	
	return city

func _create_npcs() -> void:
	var npc_types = [
		{"pos": Vector3(-30, 0, 20), "type": "merchant", "name": "Tüccar Ahmet"},
		{"pos": Vector3(40, 0, 30), "type": "guard", "name": "Muhafız"},
		{"pos": Vector3(-50, 0, -20), "type": "villager", "name": "Köylü"}
	]
	
	for npc_data in npc_types:
		var npc = _create_npc_visual(npc_data)
		npc.transform.origin = npc_data["pos"]
		add_child(npc)

func _create_npc_visual(data: Dictionary) -> Node3D:
	var npc = CharacterBody3D.new()
	
	var body = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.5
	body.mesh = capsule
	
	var mat = StandardMaterial3D.new()
	match data["type"]:
		"merchant":
			mat.albedo_color = Color(0.6, 0.4, 0.2)
		"guard":
			mat.albedo_color = Color(0.3, 0.3, 0.5)
		"villager":
			mat.albedo_color = Color(0.5, 0.4, 0.3)
	
	body.material = mat
	npc.add_child(body)
	
	# İsim
	var label = Label3D.new()
	label.text = data["name"]
	label.font_size = 14
	label.position = Vector3(0, 2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	npc.add_child(label)
	
	return npc

func _setup_ui() -> void:
	if not ui:
		return
	
	# UI güncelle
	var gold_label = ui.get_node_or_null("Gold")
	if gold_label:
		gold_label.text = "🪙 %d" % gold
	
	var turn_label = ui.get_node_or_null("Turn")
	if turn_label:
		turn_label.text = "Tur: %d" % turn

func _setup_mobile_controls() -> void:
	# Joystick gibi mobil kontroller için hazırlık
	pass

func _setup_signals() -> void:
	conquest_system.region_conquered.connect(_on_region_conquered)
	castle_system.castle_upgraded.connect(_on_castle_upgraded)

func _on_region_conquered(region_id: String, new_owner: String) -> void:
	print("Bölge fethedildi: %s -> %s" % [region_id, new_owner])
	show_notification("%s fethedildi!" % conquest_system.regions[region_id]["name"])

func _on_castle_upgraded(castle_id: String, new_level: int) -> void:
	print("Kale yükseltildi: %s -> Lv.%d" % [castle_id, new_level])

func end_turn() -> void:
	turn += 1
	
	# Gelir hesapla
	var income = conquest_system.get_faction_total_income("ottoman")
	gold += income
	
	# Düşman AI
	conquest_system.simulate_enemy_turn()
	
	# UI güncelle
	_update_ui()
	
	show_notification("Tur %d — +%d altın" % [turn, income])

func _update_ui() -> void:
	if not ui:
		return
	
	var gold_label = ui.get_node_or_null("Gold")
	if gold_label:
		gold_label.text = "🪙 %d" % gold
	
	var turn_label = ui.get_node_or_null("Turn")
	if turn_label:
		turn_label.text = "Tur: %d" % turn

func show_notification(msg: String) -> void:
	var msg_label = ui.get_node_or_null("Msg")
	if msg_label:
		msg_label.text = msg
		msg_label.visible = true
		
		# 3 saniye sonra gizle
		var timer = Timer.new()
		timer.one_shot = true
		timer.timeout.connect(func(): msg_label.visible = false)
		add_child(timer)
		timer.start(3)

func show_msg(m: String) -> void:
	show_notification(m)

func _on_end_turn_pressed() -> void:
	end_turn()

# Saldırı sistemi
func attack_region(region_id: String, troops: int) -> Dictionary:
	return conquest_system.attack_region(region_id, troops, "ottoman")

# Kale işlemleri
func build_castle(region_id: String, position: Vector3) -> Dictionary:
	return castle_system.build_castle(region_id, position, "ottoman", gold)

func upgrade_castle(castle_id: String) -> Dictionary:
	var result = castle_system.upgrade_castle(castle_id, gold)
	if result.get("success"):
		gold -= result["cost"]
	return result

# Meslek işlemleri
func change_profession(profession_id: int) -> bool:
	if profession_system.unlock_profession(profession_id, gold):
		profession_system.change_profession(profession_id)
		return true
	return false

func get_profession_info() -> Dictionary:
	return {
		"name": profession_system.get_profession_name(),
		"icon": profession_system.get_profession_icon(),
		"stats": profession_system.stats,
		"skills": profession_system.get_all_skills(),
		"level": profession_system.profession_level
	}