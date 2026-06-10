extends Node3D

var gold = 5000
var turn = 1
var cities = []
var units = []

@onready var ground = $Ground/Mesh
@onready var cities_node = $Cities
@onready var units_node = $Units
@onready var ui = $UI

func _ready():
	Engine.set_target_fps(30)
	setup_cities()
	spawn_units()
	update_ui()

func setup_cities():
	cities = [
		{"name": "İstanbul", "x": 0, "y": 0, "owner": "byzantine", "troops": 3000, "income": 500},
		{"name": "Edirne", "x": -80, "y": -30, "owner": "ottoman", "troops": 5000, "income": 300},
		{"name": "Bursa", "x": 50, "y": 60, "owner": "ottoman", "troops": 2000, "income": 200},
		{"name": "Selanik", "x": -60, "y": 50, "owner": "ottoman", "troops": 1500, "income": 180},
		{"name": "Karaman", "x": 100, "y": 80, "owner": "karamanid", "troops": 2500, "income": 160},
	]
	
	for c in cities:
		var m = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(8, 5, 8)
		m.mesh = box
		m.position = Vector3(c["x"], 2.5, c["y"])
		
		var mat = StandardMaterial3D.new()
		if c["owner"] == "ottoman":
			mat.albedo_color = Color(0.9, 0.7, 0.1)
		elif c["owner"] == "byzantine":
			mat.albedo_color = Color(0.3, 0.5, 0.9)
		else:
			mat.albedo_color = Color(0.2, 0.7, 0.4)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material = mat
		
		var l = Label3D.new()
		l.text = c["name"]
		l.font_size = 32
		l.position = Vector3(0, 6, 0)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.add_child(l)
		
		cities_node.add_child(m)

func spawn_units():
	for i in range(5):
		var u = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1, 1.5, 1)
		u.mesh = box
		u.position = Vector3(-80 + randf() * 20, 0.75, -30 + randf() * 20)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.6, 0.2)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		u.material = mat
		
		units_node.add_child(u)
		units.append(u)

func end_turn():
	turn += 1
	var income = 0
	for c in cities:
		if c["owner"] == "ottoman":
			income += c["income"]
	gold += income
	update_ui()
	show_msg("Tur %d +%d altın" % [turn, income])

func update_ui():
	ui.get_node("Gold").text = "🪙 %d" % gold
	ui.get_node("Turn").text = "Tur: %d" % turn

func show_msg(m):
	ui.get_node("Msg").text = m
	ui.get_node("Msg").visible = true
	await get_tree().create_timer(3).timeout
	ui.get_node("Msg").visible = false

func _on_end_turn_pressed():
	end_turn()