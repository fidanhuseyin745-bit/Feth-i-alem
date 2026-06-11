extends Node3D

## Genshin Impact tarzı 3D Açık Dünya - Yüksek Kalite Grafikler

const ConquestSystem = preload("res://scenes/3d/scripts/ConquestSystem.gd")
const ProfessionSystem = preload("res://scenes/3d/scripts/ProfessionSystem.gd")
const CastleSystem = preload("res://scenes/3d/scripts/CastleSystem.gd")

# Sistemler
var conquest_system: ConquestSystem
var profession_system: ProfessionSystem
var castle_system: CastleSystem

# Oyuncu
var player: CharacterBody3D
var player_camera: Camera3D
var joystick_input: Vector2 = Vector2.ZERO

# Dünya
var terrain: MeshInstance3D
var castles: Dictionary = {}
var regions: Dictionary = {}
var buildings: Array = []
var npcs: Array = []

# Kamera
var camera_distance: float = 10.0
var camera_angle: float = 45.0
var camera_rotation_speed: float = 2.0

# Işık
@onready var sun_light: DirectionalLight3D
@onready var ambient_light: WorldEnvironment

# UI
var ui_layer: CanvasLayer

# Mobil kontrol
var mobile_controls_enabled: bool = true
var touch_start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# FPS ayarı - mobil için
	Engine.set_target_fps(60 if OS.has_feature("mobile") else 120)
	
	# Sistemleri başlat
	conquest_system = ConquestSystem.new()
	profession_system = ProfessionSystem.new()
	castle_system = CastleSystem.new()
	
	_setup_environment()
	_create_world()
	_create_player()
	_create_castles()
	_spawn_npcs()
	_setup_ui()
	_setup_mobile_controls()
	
	# Sinyaller
	conquest_system.region_conquered.connect(_on_region_conquered)

func _setup_environment() -> void:
	# World Environment - Yüksek kalite render
	var env = Environment.new()
	
	# Sky
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.rayleigh = 2.0
	sky_material.turbidity = 5.0
	sky_material.moon_stepsize = 10
	sky_material.moon_curve = 0.5
	sky.sky_material = sky_material
	env.sky = sky
	
	# Ambient light
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.45, 0.55)
	env.ambient_light_energy = 0.8
	
	# Glow (bloom)
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.2
	env.glow_bloom = 0.3
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	
	# Tonemapping
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	
	# SSAO
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 2.0
	env.ssao_detail = 0.5
	
	# SSR
	env.ssr_enabled = true
	env.ssr_max_steps = 32
	
	# SDFGI (Global Illumination)
	env.sdfgi_enabled = true
	env.sdfgi_ray_count = 8
	env.sdfgi_bounce_feedback = 0.5
	
	# Fog
	env.fog_light_color = Color(0.6, 0.65, 0.75)
	env.fog_density = 0.001
	env.fog_sky_affect = 0.5
	
	# Background
	env.background_mode = Environment.BG_MODE_SKY
	env.background_color = Color(0.5, 0.6, 0.7)
	
	WorldEnvironment.new().environment = env
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	# Directional Light (Güneş)
	sun_light = DirectionalLight3D.new()
	sun_light.transform.basis = Basis.from_euler(Vector3(-45, 30, 0))
	sun_light.light_color = Color(1.0, 0.95, 0.8)
	sun_light.light_energy = 1.2
	sun_light.shadow_enabled = true
	sun_light.shadow_blend = 0.5
	sun_light.directional_shadow_mode = DirectionalLight3D.DIRECTIONAL_SHADOW_MODE_PCF_5
	add_child(sun_light)

func _create_world() -> void:
	# Zemin - Büyük terrain
	_create_terrain()
	
	# Ağaçlar
	_spawn_trees()
	
	# Dağlar
	_create_mountains()
	
	# Su kaynakları
	_create_lakes()

func _create_terrain() -> void:
	# Büyük terrain mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(500, 500)
	plane_mesh.subdivide_depth = 128
	plane_mesh.subdivide_width = 128
	
	terrain = MeshInstance3D.new()
	terrain.mesh = plane_mesh
	terrain.transform.origin = Vector3(0, -1, 0)
	
	# Terrain shader
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://scenes/3d/shaders/terrain.gdshader")
	shader_material.set_shader_parameter("albedo", Color(0.45, 0.65, 0.35))
	shader_material.set_shader_parameter("albedo2", Color(0.35, 0.55, 0.25))
	shader_material.set_shader_parameter("detail_albedo", Color(0.55, 0.75, 0.45))
	shader_material.set_shader_parameter("roughness", 0.85)
	shader_material.set_shader_parameter("metallic", 0.0)
	shader_material.set_shader_parameter("uv_scale", 0.02)
	
	terrain.material = shader_material
	add_child(terrain)
	
	# Collision
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(500, 2, 500)
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	terrain.add_child(static_body)

func _spawn_trees() -> void:
	# Genshin tarzı ağaçlar
	var tree_positions = [
		Vector3(30, 0, 40), Vector3(-40, 0, 20), Vector3(60, 0, -30),
		Vector3(-20, 0, 60), Vector3(80, 0, 50), Vector3(-60, 0, -40),
		Vector3(20, 0, 80), Vector3(-80, 0, 30), Vector3(40, 0, -60)
	]
	
	for pos in tree_positions:
		var tree = _create_tree()
		tree.transform.origin = pos + Vector3(randf() * 10 - 5, 0, randf() * 10 - 5)
		add_child(tree)

func _create_tree() -> Node3D:
	var tree = Node3D.new()
	
	# Gövde
	var trunk = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.2
	cylinder.bottom_radius = 0.4
	cylinder.height = 4
	trunk.mesh = cylinder
	trunk.transform.origin = Vector3(0, 2, 0)
	
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.25, 0.15)
	trunk_mat.roughness = 0.9
	trunk.material = trunk_mat
	tree.add_child(trunk)
	
	# Yapraklar (çok katmanlı)
	for i in range(3):
		var leaves = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 2.5 - i * 0.5
		sphere.height = 3 - i * 0.5
		leaves.mesh = sphere
		
		var leaves_mat = StandardMaterial3D.new()
		leaves_mat.albedo_color = Color(0.2 + randf() * 0.1, 0.5 + randf() * 0.2, 0.15)
		leaves_mat.roughness = 0.8
		leaves.material = leaves_mat
		
		leaves.transform.origin = Vector3(0, 5 + i * 1.5, 0)
		tree.add_child(leaves)
	
	return tree

func _create_mountains() -> void:
	# Arka plan dağları
	var mountain_positions = [
		Vector3(-200, 0, -150), Vector3(200, 0, -200), Vector3(0, 0, -250)
	]
	
	for pos in mountain_positions:
		var mountain = _create_mountain()
		mountain.transform.origin = pos
		mountain.scale = Vector3(3, 2, 3)
		add_child(mountain)

func _create_mountain() -> Node3D:
	var mountain = MeshInstance3D.new()
	var cone = ConeMesh.new()
	cone.radius = 50
	cone.height = 80
	mountain.mesh = cone
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.55)
	mat.roughness = 0.9
	mountain.material = mat
	
	return mountain

func _create_lakes() -> void:
	# Su gölleri
	var lake_positions = [
		Vector3(-50, -0.5, 30), Vector3(70, -0.5, -40)
	]
	
	for pos in lake_positions:
		var lake = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(30, 20)
		lake.mesh = plane
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.4, 0.7)
		mat.metallic = 0.3
		mat.roughness = 0.2
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.8
		lake.material = mat
		
		lake.transform.origin = pos
		add_child(lake)

func _create_player() -> void:
	# Oyuncu karakteri
	player = CharacterBody3D.new()
	player.name = "Player"
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.height = 2.0
	shape.radius = 0.5
	collision.shape = shape
	player.add_child(collision)
	
	# Görsel - Genshin tarzı karakter
	var body = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	body.mesh = capsule
	
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://scenes/3d/shaders/character.gdshader")
	mat.set_shader_parameter("skin_color", Color(0.9, 0.75, 0.65))
	mat.set_shader_parameter("cloth_color", Color(0.2, 0.15, 0.4))
	mat.set_shader_parameter("cloth_accent", Color(0.9, 0.7, 0.1))
	body.material = mat
	player.add_child(body)
	
	# Şapka
	var hat = MeshInstance3D.new()
	var cone = ConeMesh.new()
	cone.radius = 0.3
	cone.height = 0.4
	hat.mesh = cone
	hat.transform.origin = Vector3(0, 1.4, 0)
	var hat_mat = StandardMaterial3D.new()
	hat_mat.albedo_color = Color(0.8, 0.2, 0.1)
	hat.material = hat_mat
	player.add_child(hat)
	
	# Kamera
	player_camera = Camera3D.new()
	player_camera.fov = 60
	player_camera.far = 500
	player_camera.position = Vector3(0, 3, 8)
	player.add_child(player_camera)
	
	# Başlangıç pozisyonu
	player.transform.origin = Vector3(0, 0, 0)
	
	add_child(player)

func _create_castles() -> void:
	# Kale sisteminden kaleleri oluştur
	var castle_data = castle_system.castles
	
	for castle_id in castle_data:
		var data = castle_data[castle_id]
		var castle = _create_castle_mesh(data)
		castle.transform.origin = data["position"]
		add_child(castle)
		castles[castle_id] = castle

func _create_castle_mesh(data: Dictionary) -> Node3D:
	var castle = Node3D.new()
	castle.name = data["id"]
	
	# Ana gövde
	var main_building = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(8, 6 + data["level"], 8)
	main_building.mesh = box
	
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://scenes/3d/shaders/castle.gdshader")
	
	# Renk - sahip olan fraksiyona göre
	var faction_colors = {
		"ottoman": Color(0.9, 0.7, 0.1),
		"byzantine": Color(0.3, 0.5, 0.9),
		"karamanid": Color(0.2, 0.7, 0.4),
		"albania": Color(0.85, 0.2, 0.2),
		"venice": Color(0.6, 0.3, 0.8),
		"akkoyunlu": Color(0.9, 0.5, 0.1)
	}
	
	if faction_colors.has(data["owner"]):
		mat.set_shader_parameter("stone_color", faction_colors[data["owner"]] * 0.8)
	
	main_building.material = mat
	castle.add_child(main_building)
	
	# Kule (seviyeye göre)
	for i in range(data["level"]):
		var tower = MeshInstance3D.new()
		var tower_mesh = CylinderMesh.new()
		tower_mesh.top_radius = 1.5
		tower_mesh.bottom_radius = 2
		tower_mesh.height = 4
		tower.mesh = tower_mesh
		tower.transform.origin = Vector3(-3 + i * 6, 5 + data["level"] / 2, -3)
		
		var tower_mat = StandardMaterial3D.new()
		tower_mat.albedo_color = faction_colors.get(data["owner"], Color.WHITE)
		tower.material = tower_mat
		castle.add_child(tower)
		
		# Bayrak
		var flag = MeshInstance3D.new()
		var flag_mesh = PlaneMesh.new()
		flag_mesh.size = Vector2(1, 0.7)
		flag.mesh = flag_mesh
		flag.transform.origin = Vector3(-3 + i * 6, 8 + data["level"], -3)
		flag.transform.basis = Basis.from_euler(Vector3(0, i * 0.5, 0))
		
		var flag_mat = StandardMaterial3D.new()
		flag_mat.albedo_color = faction_colors.get(data["owner"], Color.WHITE)
		flag_mat.emission_enabled = true
		flag_mat.emission = faction_colors.get(data["owner"], Color.WHITE) * 0.3
		flag.material = flag_mat
		castle.add_child(flag)
	
	# Kalkan duvarı (yüksek seviye)
	if data["level"] >= 3:
		for angle in range(4):
			var wall = MeshInstance3D.new()
			var wall_mesh = BoxMesh.new()
			wall_mesh.size = Vector3(0.5, 3, 3)
			wall.mesh = wall_mesh
			var rot = angle * PI / 2
			wall.transform.origin = Vector3(cos(rot) * 5, 1.5, sin(rot) * 5)
			wall.transform.basis = Basis.from_euler(Vector3(0, rot, 0))
			castle.add_child(wall)
	
	return castle

func _spawn_npcs() -> void:
	# Bölge NPC'leri
	var npc_positions = [
		{"pos": Vector3(-30, 0, 20), "type": "merchant"},
		{"pos": Vector3(40, 0, 30), "type": "guard"},
		{"pos": Vector3(-50, 0, -20), "type": "villager"}
	]
	
	for npc_data in npc_positions:
		var npc = _create_npc(npc_data["type"])
		npc.transform.origin = npc_data["pos"]
		add_child(npc)
		npcs.append(npc)

func _create_npc(type: String) -> Node3D:
	var npc = CharacterBody3D.new()
	
	var body = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	body.mesh = capsule
	
	var mat = StandardMaterial3D.new()
	match type:
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
	label.text = type.capitalize()
	label.font_size = 16
	label.transform.origin = Vector3(0, 2.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	npc.add_child(label)
	
	return npc

func _setup_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)
	
	# Üst bar - Kaynaklar
	var top_bar = _create_panel(10, 10, 400, 60, Color(0.1, 0.1, 0.15, 0.8))
	ui_layer.add_child(top_bar)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_bar.add_child(hbox)
	
	# Altın
	var gold_label = Label.new()
	gold_label.text = "🪙 5000"
	gold_label.add_theme_font_size_override("font_size", 24)
	gold_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	hbox.add_child(gold_label)
	
	# Tur
	var turn_label = Label.new()
	turn_label.text = " | Tur: 1"
	turn_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(turn_label)
	
	# Meslek göstergesi
	var prof_label = Label.new()
	prof_label.text = " ⚔️ Savaşçı"
	prof_label.add_theme_font_size_override("font_size", 20)
	prof_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prof_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	prof_label.position = Vector2(-200, 10)
	ui_layer.add_child(prof_label)
	
	# Alt butonlar
	var bottom_bar = _create_panel(0, 0, 0, 80, Color(0.1, 0.1, 0.15, 0.8))
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ui_layer.add_child(bottom_bar)
	
	var action_hbox = HBoxContainer.new()
	action_hbox.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	action_hbox.position = Vector2(-300, -70)
	bottom_bar.add_child(action_hbox)
	
	var actions = [
		{"name": "Saldır", "icon": "⚔️"},
		{"name": "İnşa", "icon": "🏗️"},
		{"name": "Ticaret", "icon": "💰"},
		{"name": "Meslek", "icon": "⚔️"},
		{"name": "Harita", "icon": "🗺️"}
	]
	
	for action in actions:
		var btn = Button.new()
		btn.text = action["icon"] + " " + action["name"]
		btn.custom_minimum_size = Vector2(100, 50)
		btn.pressed.connect(_on_action_button.bind(action["name"]))
		action_hbox.add_child(btn)

func _create_panel(x: int, y: int, w: int, h: int, color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.position = Vector2(x, y)
	if w > 0:
		panel.custom_minimum_size = Vector2(w, h)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	return panel

func _setup_mobile_controls() -> void:
	if not OS.has_feature("mobile"):
		return
	
	# Joystick
	var joystick_base = PanelContainer.new()
	joystick_base.name = "JoystickBase"
	joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick_base.offset_left = 30
	joystick_base.offset_bottom = -30
	joystick_base.custom_minimum_size = Vector2(150, 150)
	
	var joystick_style = StyleBoxFlat.new()
	joystick_style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	joystick_style.set_corner_radius_all(75)
	joystick_base.add_theme_stylebox_override("panel", joystick_style)
	
	var knob = PanelContainer.new()
	knob.name = "Knob"
	knob.custom_minimum_size = Vector2(60, 60)
	
	var knob_style = StyleBoxFlat.new()
	knob_style.bg_color = Color(0.9, 0.7, 0.1, 0.8)
	knob_style.set_corner_radius_all(30)
	knob.add_theme_stylebox_override("panel", knob_style)
	
	joystick_base.add_child(knob)
	ui_layer.add_child(joystick_base)

func _on_action_button(action: String) -> void:
	match action:
		"Saldır":
			_show_attack_menu()
		"İnşa":
			_show_build_menu()
		"Ticaret":
			_show_trade_menu()
		"Meslek":
			_show_profession_panel()
		"Harita":
			_show_map()

func _show_attack_menu() -> void:
	# Saldırı menüsü
	pass

func _show_build_menu() -> void:
	# İnşa menüsü
	pass

func _show_trade_menu() -> void:
	# Ticaret menüsü
	pass

func _show_profession_panel() -> void:
	# ProfessionSystem penceresi
	var professions = profession_system.get_all_professions_data()
	# UI göster
	pass

func _show_map() -> void:
	# Mini harita
	pass

func _process(delta: float) -> void:
	# Kamera kontrolü
	_update_camera(delta)
	
	# Oyuncu hareketi
	_update_player_movement(delta)
	
	# NPC animasyonları
	_update_npcs(delta)
	
	# Kale animasyonları
	_update_castles(delta)

func _update_camera(delta: float) -> void:
	if not player:
		return
	
	# Mouse/touch ile kamera döndürme
	var camera_offset = Vector3.ZERO
	camera_offset.x = sin(camera_rotation_speed * 0.01) * camera_distance
	camera_offset.z = cos(camera_rotation_speed * 0.01) * camera_distance
	
	player_camera.position = player.transform.origin + Vector3(0, 3, 8)
	player_camera.look_at(player.transform.origin + Vector3(0, 1, 0))

func _update_player_movement(delta: float) -> void:
	if not player:
		return
	
	var velocity = Vector3.ZERO
	
	# Joystick input
	if joystick_input.length() > 0.1:
		var forward = Vector3(0, 0, -1)
		var right = Vector3(1, 0, 0)
		
		velocity = (forward * joystick_input.y + right * joystick_input.x) * 5
		velocity.y = 0
	
	# Keyboard (PC)
	if Input.is_action_pressed("ui_up"):
		velocity.z -= 5
	if Input.is_action_pressed("ui_down"):
		velocity.z += 5
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 5
	if Input.is_action_pressed("ui_right"):
		velocity.x += 5
	
	player.velocity = velocity
	player.move_and_slide()

func _update_npcs(delta: float) -> void:
	for npc in npcs:
		# Basit yürüme animasyonu
		var time_offset = randf() * 10
		npc.transform.origin.y = sin(Time.get_ticks_msec() * 0.005 + time_offset) * 0.05

func _update_castles(delta: float) -> void:
	# Bayrak dalgalanması
	for castle_id in castles:
		var castle = castles[castle_id]
		for child in castle.get_children():
			if child.name.begins_with("Flag"):
				var t = Time.get_ticks_msec() * 0.003
				child.transform.basis = Basis.from_euler(Vector3(sin(t) * 0.2, child.transform.basis.get_euler().y, 0))

func _input(event: InputEvent) -> void:
	# Mobil kontrol
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
		else:
			joystick_input = Vector2.ZERO
	
	elif event is InputEventScreenDrag:
		if touch_start_pos.distance_to(event.position) < 200:
			joystick_input = (event.position - touch_start_pos) / 100
			joystick_input = joystick_input.limit_length(1.0)

func _on_region_conquered(region_id: String, new_owner: String) -> void:
	# Bölge fethedildi - görsel güncelleme
	_update_castle_owner(region_id, new_owner)

func _update_castle_owner(region_id: String, owner: String) -> void:
	var castle_id = region_id + "_castle"
	if castles.has(castle_id):
		var castle = castles[castle_id]
		# Renk güncelleme
		var faction_colors = {
			"ottoman": Color(0.9, 0.7, 0.1),
			"byzantine": Color(0.3, 0.5, 0.9),
			"karamanid": Color(0.2, 0.7, 0.4)
		}
		if faction_colors.has(owner):
			for child in castle.get_children():
				if child is MeshInstance3D:
					child.material.set_shader_parameter("stone_color", faction_colors[owner])

func set_joystick_input(input: Vector2) -> void:
	joystick_input = input