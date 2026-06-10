extends Camera3D
class_name RTSCamera

## RTS tarzı kamera kontrolü - Mobil uyumlu

signal camera_moved(pos: Vector3)

@export var move_speed: float = 20.0
@export var rotate_speed: float = 2.0
@export var zoom_speed: float = 5.0
@export var min_zoom: float = 10.0
@export var max_zoom: float = 80.0
@export var min_height: float = 15.0
@export var max_height: float = 60.0

@export var edge_scroll_margin: float = 30.0
@export var edge_scroll_speed: float = 30.0

var current_zoom: float = 40.0
var target_zoom: float = 40.0
var rotation_angle: float = 45.0

var is_dragging: bool = false
var last_touch_position: Vector2 = Vector2.ZERO
var drag_start_position: Vector3 = Vector3.ZERO

# Mobil touch pozisyonu
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_start_zoom: float = 40.0
var touch_start_camera_height: float = 40.0
var is_zooming: bool = false

func _ready():
	# Başlangıç pozisyonu
	global_position = Vector3(0, current_zoom, 20)
	look_at(Vector3(0, 0, 0))

func _input(event):
	_handle_desktop_input(event)
	_handle_touch_input(event)

func _handle_desktop_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)
	
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_RIGHT:
			rotation_angle -= event.relative.x * rotate_speed * 0.1
			target_zoom = clamp(target_zoom + event.relative.y * 0.5, min_zoom, max_zoom)
	
	# Klavye ile hareket
	if Input.is_action_pressed("camera_rotate_left"):
		rotation_angle -= rotate_speed * get_process_delta_time() * 30
	if Input.is_action_pressed("camera_rotate_right"):
		rotation_angle += rotate_speed * get_process_delta_time() * 30

func _handle_touch_input(event: InputEvent):
	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event is InputEventScreenTouch:
		_handle_screen_touch(event)

func _handle_screen_touch(event: InputEventScreenTouch):
	if event.pressed:
		touch_start_pos = event.position
		touch_start_zoom = target_zoom
		touch_start_camera_height = current_zoom
		is_dragging = true
	else:
		is_dragging = false
		is_zooming = false

func _handle_screen_drag(event: InputEventScreenDrag):
	var drag_delta = event.position - touch_start_pos
	
	if event.position.distance_to(touch_start_pos) > 10:
		# Tek parmak - kamera döndürme ve kaydırma
		if not is_zooming:
			rotation_angle -= drag_delta.x * rotate_speed * 0.2
			target_zoom = clamp(touch_start_zoom - drag_delta.y * 0.3, min_zoom, max_zoom)
	
	# Ekran kenarı kaydırma (edge scroll)
	_handle_edge_scroll(event.position)

func _handle_edge_scroll(screen_pos: Vector2):
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Üst kenar
	if screen_pos.y < edge_scroll_margin:
		_move_camera(Vector3(0, 0, 1))
	# Alt kenar
	elif screen_pos.y > viewport_size.y - edge_scroll_margin:
		_move_camera(Vector3(0, 0, -1))
	# Sol kenar
	if screen_pos.x < edge_scroll_margin:
		_move_camera(Vector3(-1, 0, 0))
	# Sağ kenar
	elif screen_pos.x > viewport_size.x - edge_scroll_margin:
		_move_camera(Vector3(1, 0, 0))

func _move_camera(direction: Vector3):
	var rotated_dir = direction.rotated(Vector3.UP, deg_to_rad(rotation_angle))
	global_position += rotated_dir * move_speed * get_process_delta_time()
	camera_moved.emit(global_position)

func _physics_process(delta):
	# Zoom animasyonu
	current_zoom = lerp(current_zoom, target_zoom, delta * 8)
	
	# Kamerayı yeni pozisyona ayarla
	var camera_offset = Vector3(
		sin(deg_to_rad(rotation_angle)) * current_zoom,
		current_zoom * 0.6,
		cos(deg_to_rad(rotation_angle)) * current_zoom
	)
	
	global_position = global_position.lerp(target_position + camera_offset, delta * 5)
	
	# Kamerayı hedefe bakacak şekilde ayarla
	var look_target = global_position - camera_offset
	look_target.y = 0
	look_at(look_target)

# Haritayı sınırlarla kontrol etme
func clamp_to_bounds(pos: Vector3, min_bound: Vector3, max_bound: Vector3) -> Vector3:
	return Vector3(
		clamp(pos.x, min_bound.x, max_bound.x),
		pos.y,
		clamp(pos.z, min_bound.z, max_bound.z)
	)

# Belirli bir noktaya odaklan
func focus_on(target_pos: Vector3):
	target_position = target_pos
	global_position = target_pos + Vector3(
		sin(deg_to_rad(rotation_angle)) * current_zoom,
		current_zoom * 0.6,
		cos(deg_to_rad(rotation_angle)) * current_zoom
	)

# Minimap için harita koordinatı alma
func get_map_position(screen_pos: Vector2) -> Vector3:
	var from = project_ray_origin(screen_pos)
	var to = from + project_ray_normal(screen_pos) * 1000
	var plane = Plane(Vector3.UP, 0)
	var intersection = plane.intersects_ray(from, to)
	if intersection:
		return intersection
	return Vector3.ZERO

# Seçim için 3D pozisyon
func screen_to_world(screen_pos: Vector2) -> Vector3:
	var from = project_ray_origin(screen_pos)
	var to = from + project_ray_normal(screen_pos) * 1000
	
	# Y=0 düzleminde kesişim
	var plane = Plane(Vector3.UP, 0)
	var intersection = plane.intersects_ray(from, to)
	
	if intersection:
		return intersection
	return Vector3.ZERO