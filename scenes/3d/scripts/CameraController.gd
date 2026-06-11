extends Camera3D
class_name CameraController

## RTS Kamera Kontrolörü - Mobil ve PC için

signal camera_moved(position: Vector3)

@export var move_speed: float = 50.0
@export var rotate_speed: float = 2.0
@export var zoom_min: float = 20.0
@export var zoom_max: float = 150.0
@export var zoom_speed: float = 10.0

var current_zoom: float = 60.0
var target_position: Vector3
var is_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO

# Touch controls
var touch_start_pos: Vector2 = Vector2.ZERO
var is_touching: bool = false

func _ready():
	target_position = global_position
	print("Kamera hazır - RTS modu")

func _process(delta: float):
	# Smooth movement
	global_position = global_position.lerp(target_position, delta * 5)
	
	# Clamp zoom
	current_zoom = clamp(current_zoom, zoom_min, zoom_max)
	
	# Update camera position based on zoom
	if has_node(".."):
		var offset = Vector3(0, current_zoom * 0.5, current_zoom)
		# Keep looking at target position

func _input(event: InputEvent):
	# Keyboard controls (PC)
	if event is InputEventKey and event.pressed:
		_handle_keyboard(event)
	
	# Mouse controls (PC)
	if event is InputEventMouseButton:
		_handle_mouse(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	
	# Touch controls (Mobile)
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		_handle_touch(event)

func _handle_keyboard(event: InputEventKey):
	var move_amount = move_speed * 0.1
	
	match event.keycode:
		KEY_W, KEY_UP:
			target_position.z -= move_amount
		KEY_S, KEY_DOWN:
			target_position.z += move_amount
		KEY_A, KEY_LEFT:
			target_position.x -= move_amount
		KEY_D, KEY_RIGHT:
			target_position.x += move_amount
		KEY_Q:
			rotate_camera(-rotate_speed)
		KEY_E:
			rotate_camera(rotate_speed)
		KEY_Z:
			zoom_in()
		KEY_X:
			zoom_out()

func _handle_mouse(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_RIGHT:
		is_dragging = event.pressed
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_in()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_out()

func _handle_mouse_motion(event: InputEventMouseMotion):
	if is_dragging:
		var delta = event.relative * 0.1
		target_position.x -= delta.x
		target_position.z -= delta.y

func _handle_touch(event):
	if event is InputEventScreenTouch:
		is_touching = event.pressed
		if event.pressed:
			touch_start_pos = event.position
	elif event is InputEventScreenDrag and is_touching:
		var delta = event.relative * 0.5
		target_position.x -= delta.x
		target_position.z -= delta.y

func rotate_camera(amount: float):
	# Rotate around Y axis
	var rotation_offset = Vector3(
		cos(rotation.y + amount) * 50,
		current_zoom * 0.5,
		sin(rotation.y + amount) * 50
	)
	rotation.y += amount

func zoom_in():
	current_zoom -= zoom_speed

func zoom_out():
	current_zoom += zoom_speed

func set_position(new_pos: Vector3):
	target_position = new_pos

func get_current_zoom() -> float:
	return current_zoom

func reset_camera():
	target_position = Vector3.ZERO
	current_zoom = 60.0