extends Node
class_name MobileOptimizer

## Mobil cihazlar için performans optimizasyonu

signal quality_changed(level: int)
signal fps_warning(fps: int)

enum QualityLevel {
	LOW,      # Düşük - Eski cihazlar
	MEDIUM,   # Orta - Çoğu cihaz
	HIGH,     # Yüksek - Yeni cihazlar
	ULTRA     # Ultra - Flagship cihazlar
}

var current_quality: QualityLevel = QualityLevel.MEDIUM
var target_fps: int = 30
var is_monitoring: bool = false

# FPS istatistikleri
var fps_history: Array = []
var avg_fps: float = 60.0
var min_fps: int = 60

# LOD sistemi
var lod_distances: Dictionary = {
	QualityLevel.LOW: {"high": 50, "medium": 100, "low": 200},
	QualityLevel.MEDIUM: {"high": 80, "medium": 150, "low": 300},
	QualityLevel.HIGH: {"high": 120, "medium": 250, "low": 500},
	QualityLevel.ULTRA: {"high": 200, "medium": 400, "low": 800}
}

# Optimize edilecek nesneler
var monitored_nodes: Array = []
var shadow_casters: Array = []
var particle_systems: Array = []

func _ready() -> void:
	_detect_device_capability()
	_apply_quality_settings()
	_start_monitoring()

func _detect_device_capability() -> void:
	# Cihaz yeteneklerini tespit et
	var device_model = OS.get_model_name().to_lower()
	var processor_count = OS.get_processor_count()
	var mem_total = OS.get_memory_info().total / (1024 * 1024 * 1024)  # GB
	
	# Basit heuristic
	var capability_score = 0
	
	# RAM'e göre
	if mem_total >= 8:
		capability_score += 3
	elif mem_total >= 6:
		capability_score += 2
	elif mem_total >= 4:
		capability_score += 1
	
	# İşlemciye göre
	if processor_count >= 8:
		capability_score += 2
	elif processor_count >= 4:
		capability_score += 1
	
	# Cihaz modeline göre (bilinen güçlü/yetersiz cihazlar)
	var high_end_patterns = ["iphone 1", "galaxy s2", "pixel 6", "snapdragon 8"]
	var low_end_patterns = ["galaxy j", "redmi 8", "cihaz"]
	
	for pattern in high_end_patterns:
		if device_model.find(pattern) >= 0:
			capability_score += 2
			break
	
	for pattern in low_end_patterns:
		if device_model.find(pattern) >= 0:
			capability_score -= 1
			break
	
	# Kalite seviyesini belirle
	if capability_score >= 6:
		current_quality = QualityLevel.ULTRA
		target_fps = 60
	elif capability_score >= 4:
		current_quality = QualityLevel.HIGH
		target_fps = 45
	elif capability_score >= 2:
		current_quality = QualityLevel.MEDIUM
		target_fps = 30
	else:
		current_quality = QualityLevel.LOW
		target_fps = 24
	
	Engine.set_target_fps(target_fps)

func _apply_quality_settings() -> void:
	match current_quality:
		QualityLevel.LOW:
			_apply_low_settings()
		QualityLevel.MEDIUM:
			_apply_medium_settings()
		QualityLevel.HIGH:
			_apply_high_settings()
		QualityLevel.ULTRA:
			_apply_ultra_settings()

func _apply_low_settings() -> void:
	# Düşük kalite ayarları
	RenderingServer.global_set_parameter("rendering/environment/default_clear_color", Color(0.5, 0.5, 0.5))
	
	# Viewport
	get_viewport().size = Vector2(960, 540)
	get_viewport().size_inherited = false
	
	# Shadows
	RenderingServer.projections_set_shadow_caching(RenderingServer.SHADOW_CACHING_NONE)
	
	# Anti-aliasing
	get_viewport().fxaa = false
	
	# Düşük çözünürlük UI
	get_viewport().canvas_items_default_texture_filter = Viewport.TEXTURE_FILTER_NEAREST

func _apply_medium_settings() -> void:
	RenderingServer.global_set_parameter("rendering/environment/default_clear_color", Color(0.5, 0.6, 0.7))
	
	get_viewport().size = Vector2(1280, 720)
	get_viewport().size_inherited = false
	
	# Basit shadow
	RenderingServer.projections_set_shadow_caching(RenderingServer.SHADOW_CACHING_PCF_2)
	
	get_viewport().fxaa = false
	
	get_viewport().canvas_items_default_texture_filter = Viewport.TEXTURE_FILTER_BILINEAR

func _apply_high_settings() -> void:
	RenderingServer.global_set_parameter("rendering/environment/default_clear_color", Color(0.5, 0.6, 0.7))
	
	# Dinamik çözünürlük
	get_viewport().size_inherited = true
	
	RenderingServer.projections_set_shadow_caching(RenderingServer.SHADOW_CACHING_PCF_5)
	
	get_viewport().fxaa = true
	
	get_viewport().canvas_items_default_texture_filter = Viewport.TEXTURE_FILTER_TRILINEAR

func _apply_ultra_settings() -> void:
	RenderingServer.global_set_parameter("rendering/environment/default_clear_color", Color(0.5, 0.6, 0.7))
	
	get_viewport().size_inherited = true
	
	RenderingServer.projections_set_shadow_caching(RenderingServer.SHADOW_CACHING_PCF_8)
	
	get_viewport().fxaa = true
	get_viewport().msaa_3d = Viewport.MSAA_4X
	
	get_viewport().canvas_items_default_texture_filter = Viewport.TEXTURE_FILTER_TRILINEAR
	get_viewport().canvas_items_default_texture_repeat = true

func _start_monitoring() -> void:
	is_monitoring = true
	_process_fps_monitoring()

func _process_fps_monitoring() -> void:
	if not is_monitoring:
		return
	
	var current_fps = Engine.get_frames_per_second()
	fps_history.append(current_fps)
	
	# Son 60 FPS'i sakla
	if fps_history.size() > 60:
		fps_history.pop_front()
	
	# Ortalama hesapla
	var sum = 0
	for fps_val in fps_history:
		sum += fps_val
	avg_fps = float(sum) / float(fps_history.size())
	
	# Minimum FPS
	if fps_history.size() > 0:
		min_fps = fps_history.min()
	
	# FPS düşerse otomatik kalite düşür
	if avg_fps < target_fps * 0.7:
		_decrease_quality()
	elif avg_fps > target_fps * 1.2 and current_quality < QualityLevel.ULTRA:
		# FPS yüksek, kalite artırabilir
		pass
	
	# Uyarı
	if min_fps < 20:
		fps_warning.emit(min_fps)

func _decrease_quality() -> void:
	if current_quality == QualityLevel.LOW:
		return  # En düşük seviyede
	
	var old_quality = current_quality
	current_quality = QualityLevel.values()[current_quality - 1]
	
	# Hedef FPS güncelle
	target_fps = [24, 30, 45, 60][current_quality]
	Engine.set_target_fps(target_fps)
	
	_apply_quality_settings()
	quality_changed.emit(current_quality)
	
	# LOD güncelle
	update_all_lod_levels()

func set_quality_level(level: QualityLevel) -> void:
	current_quality = level
	target_fps = [24, 30, 45, 60][level]
	Engine.set_target_fps(target_fps)
	_apply_quality_settings()
	quality_changed.emit(level)

func get_lod_distance(lod_level: String) -> float:
	if lod_distances.has(current_quality):
		return lod_distances[current_quality].get(lod_level, 100.0)
	return 100.0

func register_node(node: Node3D) -> void:
	if not monitored_nodes.has(node):
		monitored_nodes.append(node)
		_setup_lod_for_node(node)

func _setup_lod_for_node(node: Node3D) -> void:
	# LOD script ekle
	var lod_component = Node3D.new()
	lod_component.name = "LODComponent"
	node.add_child(lod_component)

func update_all_lod_levels() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var camera_pos = camera.global_transform.origin
	
	for node in monitored_nodes:
		if is_instance_valid(node):
			var distance = camera_pos.distance_to(node.global_transform.origin)
			_apply_lod_based_on_distance(node, distance)

func _apply_lod_bod_on_distance(node: Node3D, distance: float) -> void:
	var high_dist = get_lod_distance("high")
	var medium_dist = get_lod_distance("medium")
	var low_dist = get_lod_distance("low")
	
	if distance < high_dist:
		_set_lod_level(node, 2)  # Yüksek
	elif distance < medium_dist:
		_set_lod_level(node, 1)  # Orta
	elif distance < low_dist:
		_set_lod_level(node, 0)  # Düşük
	else:
		_set_lod_level(node, -1)  # Gizle

func _set_lod_level(node: Node3D, level: int) -> void:
	match level:
		2:  # Yüksek detay
			node.visible = true
			_set_node_scale(node, 1.0)
			_enable_shadows(node, true)
		1:  # Orta detay
			node.visible = true
			_set_node_scale(node, 0.8)
			_enable_shadows(node, false)
		0:  # Düşük detay
			node.visible = true
			_set_node_scale(node, 0.5)
			_enable_shadows(node, false)
		-1:  # Gizli
			node.visible = false

func _set_node_scale(node: Node3D, scale: float) -> void:
	if node is MeshInstance3D:
		# LOD mesh değiştirme (varsa)
		pass

func _enable_shadows(node: Node3D, enable: bool) -> void:
	if node is Light3D:
		node.shadow_enabled = enable

func pause_when_background() -> void:
	# Arka planda FPS'i düşür
	get_tree().process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func reduce_particle_quality() -> void:
	for ps in particle_systems:
		if is_instance_valid(ps) and ps is CPUParticles3D:
			ps.draw_pass_1 = 1  # Düşük particle sayısı

func get_performance_stats() -> Dictionary:
	return {
		"quality": QualityLevel.keys()[current_quality],
		"target_fps": target_fps,
		"current_fps": Engine.get_frames_per_second(),
		"avg_fps": avg_fps,
		"min_fps": min_fps,
		"monitored_nodes": monitored_nodes.size(),
		"lod_distances": lod_distances[current_quality]
	}

func force_low_power_mode() -> void:
	# Pil tasarrufu modu
	current_quality = QualityLevel.LOW
	target_fps = 24
	Engine.set_target_fps(24)
	_apply_low_settings()
	
	# Ekran karartma
	get_viewport().transparent_bg = false
	
	# VSync aç
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

func enable_performance_mode() -> void:
	# Maksimum performans
	target_fps = 120
	Engine.set_target_fps(120)
	
	get_viewport().size_inherited = true
	RenderingServer.projections_set_shadow_caching(RenderingServer.SHADOW_CACHING_PCF_8)
	get_viewport().msaa_3d = Viewport.MSAA_4X