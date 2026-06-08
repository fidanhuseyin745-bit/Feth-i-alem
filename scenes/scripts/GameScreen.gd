extends Control
## Main game screen — Bannerlord-style hub with bottom nav and content panels.

const UITheme = preload("res://scenes/scripts/UITheme.gd")

enum Tab { MAP, ARMY, KINGDOM, DIPLOMACY, CHARACTER }
var current_tab: Tab = Tab.MAP

# ── Node references ─────────────────────────────────────────────────────
var top_bar: PanelContainer
var content_area: Control
var bottom_nav: PanelContainer
var tab_buttons: Array = []
var tab_labels: Array = []

# Tab content panels
var map_panel: Control
var army_panel: Control
var kingdom_panel: Control
var diplomacy_panel: Control
var character_panel: Control

# Top bar elements
var gold_label: Label
var turn_label: Label
var income_label: Label
var time_btns: Array = []

# Map elements
var map_bg: TextureRect
var map_scroll_offset := Vector2.ZERO
var map_drag_start := Vector2.ZERO
var map_dragging := false
var settlement_markers: Dictionary = {}

# Settlement detail panel
var detail_panel: PanelContainer
var detail_visible := false

func _ready():
	_build_ui()
	_connect_signals()
	_switch_tab(Tab.MAP)
	_update_top_bar()

# ════════════════════════════════════════════════════════════════════════
#                          UI CONSTRUCTION
# ════════════════════════════════════════════════════════════════════════

func _build_ui():
	var vp = get_viewport_rect().size
	# Root fills viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dark background
	var bg = ColorRect.new()
	bg.color = UITheme.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_top_bar(vp)
	_build_content_area(vp)
	_build_bottom_nav(vp)
	_build_map_panel(vp)
	_build_army_panel(vp)
	_build_kingdom_panel(vp)
	_build_diplomacy_panel(vp)
	_build_character_panel(vp)
	_build_detail_panel(vp)

func _build_top_bar(vp: Vector2):
	top_bar = PanelContainer.new()
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(vp.x, UITheme.TOP_BAR_HEIGHT)
	top_bar.add_theme_stylebox_override("panel", UITheme.make_panel_style(UITheme.BG_PANEL, 0, UITheme.BORDER_DIM, 0))
	add_child(top_bar)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(hbox)

	# Gold
	gold_label = Label.new()
	gold_label.text = "🪙 5000"
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
	hbox.add_child(gold_label)

	# Separator
	var sep1 = Label.new()
	sep1.text = "│"
	sep1.add_theme_color_override("font_color", UITheme.BORDER_DIM)
	sep1.add_theme_font_size_override("font_size", 20)
	hbox.add_child(sep1)

	# Income
	income_label = Label.new()
	income_label.text = "+0/tur"
	income_label.add_theme_font_size_override("font_size", 16)
	income_label.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	hbox.add_child(income_label)

	var sep2 = Label.new()
	sep2.text = "│"
	sep2.add_theme_color_override("font_color", UITheme.BORDER_DIM)
	sep2.add_theme_font_size_override("font_size", 20)
	hbox.add_child(sep2)

	# Turn
	turn_label = Label.new()
	turn_label.text = "Tur: 1"
	turn_label.add_theme_font_size_override("font_size", 18)
	turn_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	hbox.add_child(turn_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Time controls
	var time_icons = ["⏸", "▶", "▶▶"]
	for i in range(3):
		var btn = Button.new()
		btn.text = time_icons[i]
		btn.custom_minimum_size = Vector2(50, 40)
		UITheme.style_button(btn, i == 1)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_time_btn.bind(i))
		hbox.add_child(btn)
		time_btns.append(btn)

	# End Turn button
	var end_btn = Button.new()
	end_btn.text = "Tur Bitir"
	end_btn.custom_minimum_size = Vector2(100, 40)
	UITheme.style_button(end_btn, true)
	end_btn.pressed.connect(_on_end_turn)
	hbox.add_child(end_btn)

func _build_content_area(vp: Vector2):
	content_area = Control.new()
	content_area.position = Vector2(0, UITheme.TOP_BAR_HEIGHT)
	content_area.size = Vector2(vp.x, vp.y - UITheme.TOP_BAR_HEIGHT - UITheme.NAV_BAR_HEIGHT)
	add_child(content_area)

func _build_bottom_nav(vp: Vector2):
	bottom_nav = PanelContainer.new()
	bottom_nav.position = Vector2(0, vp.y - UITheme.NAV_BAR_HEIGHT)
	bottom_nav.size = Vector2(vp.x, UITheme.NAV_BAR_HEIGHT)
	var nav_style = UITheme.make_panel_style(Color(0.10, 0.08, 0.05, 0.98), 0, UITheme.BORDER_GOLD, 0)
	# Top border only
	nav_style.border_width_top = 2
	nav_style.border_color = UITheme.BORDER_GOLD
	bottom_nav.add_theme_stylebox_override("panel", nav_style)
	add_child(bottom_nav)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	bottom_nav.add_child(hbox)

	var tab_info = [
		{"icon": "🗺", "label": "Harita", "tab": Tab.MAP},
		{"icon": "⚔", "label": "Ordu", "tab": Tab.ARMY},
		{"icon": "🏰", "label": "Krallık", "tab": Tab.KINGDOM},
		{"icon": "🤝", "label": "Diplomasi", "tab": Tab.DIPLOMACY},
		{"icon": "👤", "label": "Karakter", "tab": Tab.CHARACTER},
	]

	for ti in tab_info:
		var tab_btn = Button.new()
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.custom_minimum_size = Vector2(0, UITheme.NAV_BAR_HEIGHT - 10)
		tab_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Style — flat transparent
		var flat = StyleBoxFlat.new()
		flat.bg_color = Color.TRANSPARENT
		flat.set_corner_radius_all(0)
		tab_btn.add_theme_stylebox_override("normal", flat)
		tab_btn.add_theme_stylebox_override("hover", flat)
		tab_btn.add_theme_stylebox_override("pressed", flat)

		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_CENTER)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)

		var icon_lbl = Label.new()
		icon_lbl.text = ti["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 28)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_color_override("font_color", UITheme.TAB_INACTIVE)
		vbox.add_child(icon_lbl)

		var text_lbl = Label.new()
		text_lbl.text = ti["label"]
		text_lbl.add_theme_font_size_override("font_size", UITheme.FONT_TAB)
		text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_lbl.add_theme_color_override("font_color", UITheme.TAB_INACTIVE)
		vbox.add_child(text_lbl)

		tab_btn.add_child(vbox)
		tab_btn.pressed.connect(_switch_tab.bind(ti["tab"]))
		hbox.add_child(tab_btn)
		tab_buttons.append(tab_btn)
		tab_labels.append({"icon": icon_lbl, "text": text_lbl})

# ── Map Panel ───────────────────────────────────────────────────────────

func _build_map_panel(vp: Vector2):
	map_panel = Control.new()
	map_panel.size = content_area.size
	content_area.add_child(map_panel)

	# Map background (historical map)
	map_bg = TextureRect.new()
	var map_tex = load("res://assets/maps/world_map_bg.png") if ResourceLoader.exists("res://assets/maps/world_map_bg.png") else null
	if map_tex:
		map_bg.texture = map_tex
	map_bg.expand_mode = 1  # EXPAND_IGNORE_SIZE
	map_bg.stretch_mode = 6  # STRETCH_KEEP_ASPECT_COVERED
	map_bg.size = content_area.size
	map_panel.add_child(map_bg)

	# Vignette overlay
	var vignette = TextureRect.new()
	var vig_tex = load("res://assets/textures/vignette.png") if ResourceLoader.exists("res://assets/textures/vignette.png") else null
	if vig_tex:
		vignette.texture = vig_tex
		vignette.expand_mode = 1
		vignette.stretch_mode = 6
		vignette.size = content_area.size
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_panel.add_child(vignette)

	# Settlement markers
	_create_settlement_markers()

func _create_settlement_markers():
	for sid in GameData.settlements:
		var s = GameData.settlements[sid]
		var marker = _create_marker(sid, s)
		map_panel.add_child(marker)
		settlement_markers[sid] = marker

func _create_marker(sid: String, s: Dictionary) -> Control:
	var container = Control.new()
	# Scale position to content area (positions were for 1080x1920 viewport)
	var scale_x = content_area.size.x / 1080.0
	var scale_y = content_area.size.y / 1920.0
	var pos = s["position"]
	container.position = Vector2(pos.x * scale_x - 55, (pos.y - UITheme.TOP_BAR_HEIGHT) * scale_y - 25)

	# Background card
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(110, 50)

	var faction_color = GameData.factions[s["owner"]]["color"] if GameData.factions.has(s["owner"]) else Color.WHITE
	var bg_color = Color(faction_color, 0.7)
	var style = UITheme.make_button_style(bg_color, 6, Color(1, 1, 1, 0.4), 1)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = UITheme.make_button_style(Color(faction_color, 0.9), 6, UITheme.TEXT_GOLD, 2)
	hover_style.content_margin_left = 6
	hover_style.content_margin_right = 6
	hover_style.content_margin_top = 3
	hover_style.content_margin_bottom = 3
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)

	# Settlement type icon + name
	var type_icon = GameData.get_settlement_type_icon(s["type"])
	btn.text = "%s %s" % [type_icon, s["name"]]
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	btn.pressed.connect(_on_settlement_pressed.bind(sid))
	container.add_child(btn)

	# Garrison count below
	var g_count = GameData.get_garrison_count(sid)
	var garrison_lbl = Label.new()
	garrison_lbl.text = "⚔ %d" % g_count
	garrison_lbl.position = Vector2(10, 50)
	garrison_lbl.add_theme_font_size_override("font_size", 11)
	garrison_lbl.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	container.add_child(garrison_lbl)

	return container

# ── Army Panel ──────────────────────────────────────────────────────────

func _build_army_panel(vp: Vector2):
	army_panel = ScrollContainer.new()
	army_panel.size = content_area.size
	army_panel.visible = false
	content_area.add_child(army_panel)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(content_area.size.x - 20, 0)
	vbox.add_theme_constant_override("separation", 10)
	army_panel.add_child(vbox)

	# Army header
	var header_panel = PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", UITheme.make_panel_style())
	vbox.add_child(header_panel)

	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 6)
	header_panel.add_child(header_vbox)

	var title = Label.new()
	title.text = "⚔ ORDU YÖNETİMİ"
	UITheme.style_label_header(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_vbox.add_child(title)

	var stats_hbox = HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 20)
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vbox.add_child(stats_hbox)

	var count_lbl = Label.new()
	count_lbl.text = "Asker: %d/%d" % [GameData.get_army_count(), GameData.army_max]
	UITheme.style_label_body(count_lbl)
	stats_hbox.add_child(count_lbl)

	var power_lbl = Label.new()
	power_lbl.text = "Güç: %d" % GameData.get_army_power()
	UITheme.style_label_body(power_lbl)
	stats_hbox.add_child(power_lbl)

	var morale_lbl = Label.new()
	morale_lbl.text = "Moral: %d%%" % GameData.army_morale
	UITheme.style_label_body(morale_lbl)
	stats_hbox.add_child(morale_lbl)

	var cost_lbl = Label.new()
	cost_lbl.text = "Maaş: %d/tur" % GameData.get_army_daily_cost()
	UITheme.style_label_small(cost_lbl)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_vbox.add_child(cost_lbl)

	# Troop cards
	for unit in GameData.army:
		var card = _create_troop_card(unit)
		vbox.add_child(card)

func _create_troop_card(unit: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.make_card_style())
	card.custom_minimum_size = Vector2(content_area.size.x - 40, 0)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)

	var tid = unit["troop_id"]
	var td = GameData.troop_defs.get(tid, {})
	var tier = td.get("tier", 1)

	# Tier badge
	var tier_lbl = Label.new()
	tier_lbl.text = UITheme.tier_label(tier)
	tier_lbl.add_theme_font_size_override("font_size", 24)
	tier_lbl.add_theme_color_override("font_color", UITheme.tier_color(tier))
	tier_lbl.custom_minimum_size = Vector2(40, 0)
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(tier_lbl)

	# Info column
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var name_lbl = Label.new()
	name_lbl.text = td.get("name", tid)
	UITheme.style_label_body(name_lbl)
	info_vbox.add_child(name_lbl)

	var type_icon = ""
	match td.get("type", ""):
		"infantry": type_icon = "🗡"
		"cavalry": type_icon = "🐴"
		"ranged": type_icon = "🏹"
		"siege": type_icon = "💣"
	var stats_lbl = Label.new()
	stats_lbl.text = "%s  Sldr: %d  |  Atk: %d  Def: %d" % [type_icon, unit["count"], td.get("attack", 0), td.get("defense", 0)]
	UITheme.style_label_small(stats_lbl)
	info_vbox.add_child(stats_lbl)

	# Upgrade button (if available)
	var upgrade_to = td.get("upgrade_to", "")
	if upgrade_to != "":
		var up_btn = Button.new()
		var up_td = GameData.troop_defs.get(upgrade_to, {})
		up_btn.text = "↑ %s (%d🪙)" % [up_td.get("name", upgrade_to), td.get("upgrade_cost", 0)]
		up_btn.custom_minimum_size = Vector2(0, 36)
		UITheme.style_button(up_btn)
		up_btn.add_theme_font_size_override("font_size", 13)
		up_btn.pressed.connect(_on_upgrade_troop.bind(tid))
		hbox.add_child(up_btn)

	return card

# ── Kingdom Panel ───────────────────────────────────────────────────────

func _build_kingdom_panel(vp: Vector2):
	kingdom_panel = ScrollContainer.new()
	kingdom_panel.size = content_area.size
	kingdom_panel.visible = false
	content_area.add_child(kingdom_panel)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(content_area.size.x - 20, 0)
	vbox.add_theme_constant_override("separation", 12)
	kingdom_panel.add_child(vbox)

	# Kingdom header
	var header = PanelContainer.new()
	header.add_theme_stylebox_override("panel", UITheme.make_panel_style())
	vbox.add_child(header)

	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 6)
	header.add_child(header_vbox)

	var faction = GameData.factions.get(GameData.player_faction, {})
	var title = Label.new()
	title.text = "%s %s" % [faction.get("symbol", ""), faction.get("name", "")]
	title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE)
	title.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_vbox.add_child(title)

	var leader_lbl = Label.new()
	leader_lbl.text = "Lider: %s" % faction.get("leader", "")
	UITheme.style_label_body(leader_lbl)
	leader_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_vbox.add_child(leader_lbl)

	# Economy summary
	var econ = PanelContainer.new()
	econ.add_theme_stylebox_override("panel", UITheme.make_card_style())
	vbox.add_child(econ)

	var econ_vbox = VBoxContainer.new()
	econ_vbox.add_theme_constant_override("separation", 4)
	econ.add_child(econ_vbox)

	var econ_title = Label.new()
	econ_title.text = "💰 EKONOMİ"
	UITheme.style_label_header(econ_title)
	econ_vbox.add_child(econ_title)

	for entry in [
		["Gelir", "+%d/tur" % GameData.get_total_income(), UITheme.ACCENT_GREEN],
		["Gider", "-%d/tur" % GameData.get_total_expenses(), UITheme.ACCENT_RED],
		["Net", "%+d/tur" % GameData.get_net_income(), UITheme.TEXT_GOLD],
	]:
		var row = HBoxContainer.new()
		var k = Label.new()
		k.text = entry[0]
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_label_body(k)
		row.add_child(k)
		var v = Label.new()
		v.text = entry[1]
		v.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		v.add_theme_color_override("font_color", entry[2])
		row.add_child(v)
		econ_vbox.add_child(row)

	# Territory list
	var terr_title = Label.new()
	terr_title.text = "🏰 TOPRAKLAR"
	UITheme.style_label_header(terr_title)
	vbox.add_child(terr_title)

	var owned = GameData.get_owned_settlements()
	for sid in owned:
		var s = GameData.settlements[sid]
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.make_card_style())
		vbox.add_child(card)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var icon_l = Label.new()
		icon_l.text = GameData.get_settlement_type_icon(s["type"])
		icon_l.add_theme_font_size_override("font_size", 24)
		row.add_child(icon_l)

		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var n = Label.new()
		n.text = s["name"]
		UITheme.style_label_body(n)
		info.add_child(n)

		var d = Label.new()
		d.text = "Garnizon: %d  |  Gelir: %d" % [GameData.get_garrison_count(sid), s["income"]]
		UITheme.style_label_small(d)
		info.add_child(d)

# ── Diplomacy Panel ─────────────────────────────────────────────────────

func _build_diplomacy_panel(vp: Vector2):
	diplomacy_panel = ScrollContainer.new()
	diplomacy_panel.size = content_area.size
	diplomacy_panel.visible = false
	content_area.add_child(diplomacy_panel)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(content_area.size.x - 20, 0)
	vbox.add_theme_constant_override("separation", 12)
	diplomacy_panel.add_child(vbox)

	var title = Label.new()
	title.text = "🤝 DİPLOMASİ"
	title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE)
	title.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for fid in GameData.factions:
		if fid == GameData.player_faction:
			continue
		var f = GameData.factions[fid]
		var rel = GameData.relations.get(fid, 0)
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.make_card_style())
		vbox.add_child(card)

		var card_vbox = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 6)
		card.add_child(card_vbox)

		# Faction name row
		var name_row = HBoxContainer.new()
		card_vbox.add_child(name_row)

		var sym = Label.new()
		sym.text = f.get("symbol", "")
		sym.add_theme_font_size_override("font_size", 28)
		name_row.add_child(sym)

		var fname = Label.new()
		fname.text = "  %s" % f["name"]
		fname.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_label_body(fname)
		name_row.add_child(fname)

		var rel_lbl = Label.new()
		rel_lbl.text = "%s (%+d)" % [GameData.get_relation_text(fid), rel]
		rel_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		rel_lbl.add_theme_color_override("font_color", GameData.get_relation_color(fid))
		name_row.add_child(rel_lbl)

		# Leader
		var leader = Label.new()
		leader.text = "Lider: %s" % f.get("leader", "?")
		UITheme.style_label_small(leader)
		card_vbox.add_child(leader)

		# Territory count
		var terr = GameData.get_faction_settlements(fid)
		var terr_lbl = Label.new()
		terr_lbl.text = "Toprak: %d yerleşim" % terr.size()
		UITheme.style_label_small(terr_lbl)
		card_vbox.add_child(terr_lbl)

		# Action buttons
		var btn_row = HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 8)
		card_vbox.add_child(btn_row)

		if rel <= -60:
			var peace_btn = Button.new()
			peace_btn.text = "Barış Teklif (1000🪙)"
			UITheme.style_button(peace_btn)
			peace_btn.add_theme_font_size_override("font_size", 14)
			peace_btn.pressed.connect(_on_propose_peace.bind(fid))
			btn_row.add_child(peace_btn)
		else:
			var war_btn = Button.new()
			war_btn.text = "Savaş İlan Et"
			UITheme.style_button(war_btn, false, true)
			war_btn.add_theme_font_size_override("font_size", 14)
			war_btn.pressed.connect(_on_declare_war.bind(fid))
			btn_row.add_child(war_btn)

		var envoy_btn = Button.new()
		envoy_btn.text = "Elçi Gönder (500🪙)"
		UITheme.style_button(envoy_btn)
		envoy_btn.add_theme_font_size_override("font_size", 14)
		envoy_btn.pressed.connect(_on_send_envoy.bind(fid))
		btn_row.add_child(envoy_btn)

# ── Character Panel ─────────────────────────────────────────────────────

func _build_character_panel(vp: Vector2):
	character_panel = ScrollContainer.new()
	character_panel.size = content_area.size
	character_panel.visible = false
	content_area.add_child(character_panel)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(content_area.size.x - 20, 0)
	vbox.add_theme_constant_override("separation", 12)
	character_panel.add_child(vbox)

	# Character header
	var header = PanelContainer.new()
	header.add_theme_stylebox_override("panel", UITheme.make_panel_style())
	vbox.add_child(header)

	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 6)
	header.add_child(header_vbox)

	var name_lbl = Label.new()
	name_lbl.text = "👤 %s" % GameData.player_name
	name_lbl.add_theme_font_size_override("font_size", UITheme.FONT_TITLE)
	name_lbl.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_vbox.add_child(name_lbl)

	var faction_lbl = Label.new()
	var pf = GameData.factions.get(GameData.player_faction, {})
	faction_lbl.text = "%s %s" % [pf.get("symbol", ""), pf.get("name", "")]
	UITheme.style_label_body(faction_lbl)
	faction_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_vbox.add_child(faction_lbl)

	# Stats
	var stats_title = Label.new()
	stats_title.text = "📊 YETENEKLER"
	UITheme.style_label_header(stats_title)
	vbox.add_child(stats_title)

	var stat_names = {
		"leadership": "Liderlik",
		"warfare": "Savaş Sanatı",
		"diplomacy": "Diplomasi",
		"economy": "Ekonomi",
	}

	for stat_id in GameData.player_stats:
		var val = GameData.player_stats[stat_id]
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.make_card_style())
		vbox.add_child(card)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)

		var sname = Label.new()
		sname.text = stat_names.get(stat_id, stat_id)
		sname.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_label_body(sname)
		row.add_child(sname)

		var val_lbl = Label.new()
		val_lbl.text = str(val)
		val_lbl.add_theme_font_size_override("font_size", 24)
		val_lbl.add_theme_color_override("font_color", UITheme.tier_color(clampi(val / 3, 1, 4)))
		row.add_child(val_lbl)

		# Progress bar (simple)
		var bar_bg = ColorRect.new()
		bar_bg.custom_minimum_size = Vector2(200, 12)
		bar_bg.color = Color(0.15, 0.12, 0.08)
		row.add_child(bar_bg)

		var bar_fill = ColorRect.new()
		bar_fill.custom_minimum_size = Vector2(val * 20, 12)
		bar_fill.color = UITheme.tier_color(clampi(val / 3, 1, 4))
		bar_bg.add_child(bar_fill)

	# Description
	var desc_card = PanelContainer.new()
	desc_card.add_theme_stylebox_override("panel", UITheme.make_card_style())
	vbox.add_child(desc_card)

	var desc = Label.new()
	desc.text = pf.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	UITheme.style_label_body(desc)
	desc_card.add_child(desc)

# ── Settlement Detail Panel ─────────────────────────────────────────────

func _build_detail_panel(vp: Vector2):
	detail_panel = PanelContainer.new()
	detail_panel.position = Vector2(20, content_area.size.y * 0.45)
	detail_panel.size = Vector2(vp.x - 40, content_area.size.y * 0.52)
	detail_panel.add_theme_stylebox_override("panel", UITheme.make_panel_style(UITheme.BG_PANEL, UITheme.PANEL_CORNER, UITheme.BORDER_GOLD, 2))
	detail_panel.visible = false
	content_area.add_child(detail_panel)

# ════════════════════════════════════════════════════════════════════════
#                           INTERACTIONS
# ════════════════════════════════════════════════════════════════════════

func _connect_signals():
	GameData.message.connect(_on_game_message)
	GameData.gold_changed.connect(_on_gold_changed)
	GameData.turn_ended.connect(_on_turn_ended)
	GameData.settlement_conquered.connect(_on_settlement_conquered)

func _switch_tab(tab: Tab):
	current_tab = tab
	map_panel.visible = (tab == Tab.MAP)
	army_panel.visible = (tab == Tab.ARMY)
	kingdom_panel.visible = (tab == Tab.KINGDOM)
	diplomacy_panel.visible = (tab == Tab.DIPLOMACY)
	character_panel.visible = (tab == Tab.CHARACTER)
	detail_panel.visible = false

	# Update tab button colors
	for i in range(tab_labels.size()):
		var is_active = (i == int(tab))
		var color = UITheme.TAB_ACTIVE if is_active else UITheme.TAB_INACTIVE
		tab_labels[i]["icon"].add_theme_color_override("font_color", color)
		tab_labels[i]["text"].add_theme_color_override("font_color", color)

func _update_top_bar():
	if gold_label:
		gold_label.text = "🪙 %d" % GameData.gold
	if turn_label:
		turn_label.text = "Tur: %d" % GameData.turn
	if income_label:
		var net = GameData.get_net_income()
		income_label.text = "%+d/tur" % net
		income_label.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if net >= 0 else UITheme.ACCENT_RED)

func _on_time_btn(speed: int):
	match speed:
		0: GameData.time_speed = 0
		1: GameData.time_speed = 1
		2: GameData.time_speed = 4
	for i in range(time_btns.size()):
		UITheme.style_button(time_btns[i], i == speed)

func _on_end_turn():
	GameData.end_turn()
	_refresh_all()

func _on_settlement_pressed(sid: String):
	_show_settlement_detail(sid)

func _show_settlement_detail(sid: String):
	if not GameData.settlements.has(sid):
		return
	var s = GameData.settlements[sid]

	# Clear previous detail content
	for child in detail_panel.get_children():
		child.queue_free()

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(detail_panel.size.x - 50, 0)
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# Close button
	var close_row = HBoxContainer.new()
	vbox.add_child(close_row)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_row.add_child(spacer)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 36)
	UITheme.style_button(close_btn)
	close_btn.pressed.connect(func(): detail_panel.visible = false)
	close_row.add_child(close_btn)

	# Title
	var faction_data = GameData.factions.get(s["owner"], {})
	var faction_color = faction_data.get("color", Color.WHITE)
	var title = Label.new()
	title.text = "%s %s" % [GameData.get_settlement_type_icon(s["type"]), s["name"]]
	title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE)
	title.add_theme_color_override("font_color", faction_color)
	vbox.add_child(title)

	# Owner
	var owner_lbl = Label.new()
	owner_lbl.text = "Sahip: %s %s" % [faction_data.get("symbol", ""), faction_data.get("name", s["owner"])]
	UITheme.style_label_body(owner_lbl)
	vbox.add_child(owner_lbl)

	# Stats grid
	var stats = [
		["Garnizon", "⚔ %d" % GameData.get_garrison_count(sid)],
		["Savunma Gücü", "🛡 %d" % GameData.get_garrison_power(sid)],
		["Gelir", "🪙 %d/tur" % s["income"]],
		["Nüfus", "👥 %d" % s.get("population", 0)],
		["Sadakat", "❤ %d%%" % s.get("loyalty", 0)],
		["Refah", "📈 %d%%" % s.get("prosperity", 0)],
	]
	for entry in stats:
		var row = HBoxContainer.new()
		var k = Label.new()
		k.text = entry[0]
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_label_small(k)
		row.add_child(k)
		var v = Label.new()
		v.text = entry[1]
		UITheme.style_label_body(v)
		row.add_child(v)
		vbox.add_child(row)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = s.get("desc", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	UITheme.style_label_small(desc_lbl)
	vbox.add_child(desc_lbl)

	# Buildings
	if s["buildings"].size() > 0:
		var bld_title = Label.new()
		bld_title.text = "🏗 Binalar"
		UITheme.style_label_header(bld_title)
		vbox.add_child(bld_title)
		for bid in s["buildings"]:
			var bd = GameData.building_defs.get(bid, {})
			var bl = Label.new()
			bl.text = "%s %s" % [bd.get("icon", ""), bd.get("name", bid)]
			UITheme.style_label_body(bl)
			vbox.add_child(bl)

	# Action buttons (only for own settlements or enemy)
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	if s["owner"] == GameData.player_faction:
		# Build button
		var build_btn = Button.new()
		build_btn.text = "🏗 İnşa Et"
		UITheme.style_button(build_btn, true)
		build_btn.pressed.connect(_on_build_settlement.bind(sid))
		btn_row.add_child(build_btn)

		# Recruit button
		var recruit_btn = Button.new()
		recruit_btn.text = "⚔ Asker Topla"
		UITheme.style_button(recruit_btn)
		recruit_btn.pressed.connect(_on_recruit.bind(sid))
		btn_row.add_child(recruit_btn)
	else:
		# Attack button
		var attack_btn = Button.new()
		attack_btn.text = "⚔ Saldır"
		UITheme.style_button(attack_btn, false, true)
		attack_btn.pressed.connect(_on_attack_settlement.bind(sid))
		btn_row.add_child(attack_btn)

	detail_panel.visible = true

func _on_attack_settlement(sid: String):
	var result = GameData.attack_settlement(sid)
	_show_battle_result(result)
	_refresh_all()

func _show_battle_result(result: Dictionary):
	detail_panel.visible = false
	# Create battle result overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_area.add_child(overlay)

	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.make_panel_style(UITheme.BG_PANEL, 12, UITheme.BORDER_GOLD, 2))
	panel.position = Vector2(60, content_area.size.y * 0.2)
	panel.size = Vector2(content_area.size.x - 120, content_area.size.y * 0.5)
	overlay.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "⚔ SAVAŞ SONUCU ⚔"
	title.add_theme_font_size_override("font_size", UITheme.FONT_TITLE)
	title.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var result_lbl = Label.new()
	if result.get("success", false):
		result_lbl.text = "🏆 ZAFER! %s fethedildi!" % result.get("settlement_name", "")
		result_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	else:
		result_lbl.text = "💀 YENİLGİ! Ordular geri çekildi."
		result_lbl.add_theme_color_override("font_color", UITheme.ACCENT_RED)
	result_lbl.add_theme_font_size_override("font_size", UITheme.FONT_HEADER)
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(result_lbl)

	# Stats
	for entry in [
		["Saldırı Gücü", str(result.get("att_power", 0))],
		["Savunma Gücü", str(result.get("def_power", 0))],
		["Kazanma Şansı", "%d%%" % int(result.get("win_prob", 0) * 100)],
		["Kayıplarımız", str(result.get("att_losses", 0))],
		["Düşman Kayıpları", str(result.get("def_losses", 0))],
	]:
		var row = HBoxContainer.new()
		var k = Label.new()
		k.text = entry[0]
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_label_body(k)
		row.add_child(k)
		var v = Label.new()
		v.text = entry[1]
		UITheme.style_label_body(v)
		row.add_child(v)
		vbox.add_child(row)

	if result.get("loot", 0) > 0:
		var loot_lbl = Label.new()
		loot_lbl.text = "💰 Ganimet: %d altın" % result["loot"]
		loot_lbl.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
		loot_lbl.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
		loot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(loot_lbl)

	var close_btn = Button.new()
	close_btn.text = "Tamam"
	close_btn.custom_minimum_size = Vector2(200, 50)
	UITheme.style_button(close_btn, true)
	close_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_btn)

func _on_build_settlement(sid: String):
	if not GameData.settlements.has(sid):
		return
	var s = GameData.settlements[sid]
	# Show build options
	detail_panel.visible = false

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_area.add_child(overlay)

	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.make_panel_style(UITheme.BG_PANEL, 12, UITheme.BORDER_GOLD, 2))
	panel.position = Vector2(40, content_area.size.y * 0.15)
	panel.size = Vector2(content_area.size.x - 80, content_area.size.y * 0.65)
	overlay.add_child(panel)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(panel.size.x - 50, 0)
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	var title = Label.new()
	title.text = "🏗 İNŞA ET — %s" % s["name"]
	title.add_theme_font_size_override("font_size", UITheme.FONT_HEADER)
	title.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
	vbox.add_child(title)

	for bid in GameData.building_defs:
		var bd = GameData.building_defs[bid]
		var already_built = bid in s["buildings"]
		var can_build = not already_built
		if bid == "shipyard" and not s.get("coastal", false):
			can_build = false

		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.make_card_style())
		vbox.add_child(card)

		var card_vbox = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 4)
		card.add_child(card_vbox)

		var name_row = HBoxContainer.new()
		card_vbox.add_child(name_row)

		var icon = Label.new()
		icon.text = bd["icon"]
		icon.add_theme_font_size_override("font_size", 24)
		name_row.add_child(icon)

		var bname = Label.new()
		bname.text = "  %s" % bd["name"]
		bname.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_label_body(bname)
		name_row.add_child(bname)

		if already_built:
			var done = Label.new()
			done.text = "İnşa Edildi"
			done.add_theme_font_size_override("font_size", 14)
			done.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
			name_row.add_child(done)
		elif can_build:
			var cost_lbl = Label.new()
			cost_lbl.text = "%d🪙" % bd["cost"]
			UITheme.style_label_body(cost_lbl)
			name_row.add_child(cost_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = bd["desc"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		UITheme.style_label_small(desc_lbl)
		card_vbox.add_child(desc_lbl)

		if can_build and not already_built:
			var build_btn = Button.new()
			build_btn.text = "İnşa Et (%d🪙)" % bd["cost"]
			UITheme.style_button(build_btn, true)
			build_btn.add_theme_font_size_override("font_size", 14)
			build_btn.pressed.connect(func():
				GameData.build_in_settlement(sid, bid)
				overlay.queue_free()
				_refresh_all()
			)
			card_vbox.add_child(build_btn)

	var close_btn = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(200, 50)
	UITheme.style_button(close_btn)
	close_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_btn)

func _on_recruit(sid: String):
	if not GameData.settlements.has(sid):
		return
	# Recruit 10 tier-1 troops
	var recruited = GameData.recruit_troops(sid, "acemi_oglan", 10)
	if recruited:
		_refresh_all()

func _on_upgrade_troop(troop_id: String):
	GameData.upgrade_troops(troop_id, 5)
	_refresh_all()

func _on_propose_peace(faction_id: String):
	GameData.propose_peace(faction_id)
	_refresh_all()

func _on_declare_war(faction_id: String):
	GameData.declare_war(faction_id)
	_refresh_all()

func _on_send_envoy(faction_id: String):
	GameData.try_diplomacy(faction_id)
	_refresh_all()

# ── Signal handlers ─────────────────────────────────────────────────────

func _on_game_message(text: String):
	_show_toast(text)

func _on_gold_changed(_new_gold: int):
	_update_top_bar()

func _on_turn_ended(_turn: int, _income: int):
	_update_top_bar()

func _on_settlement_conquered(_sid: String, _sname: String):
	_refresh_map_markers()

func _show_toast(msg: String):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", UITheme.TEXT_GOLD)
	lbl.position = Vector2(100, content_area.size.y * 0.4)
	lbl.z_index = 100
	content_area.add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 80, 2.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 2.0)
	tw.tween_callback(lbl.queue_free)

# ── Refresh ─────────────────────────────────────────────────────────────

func _refresh_all():
	_update_top_bar()
	_refresh_map_markers()
	# Rebuild panels by re-switching to current tab
	_rebuild_dynamic_panels()

func _refresh_map_markers():
	for sid in settlement_markers:
		settlement_markers[sid].queue_free()
	settlement_markers.clear()
	_create_settlement_markers()

func _rebuild_dynamic_panels():
	# Remove and rebuild army/kingdom/diplomacy/character panels
	var panels_to_rebuild = [army_panel, kingdom_panel, diplomacy_panel, character_panel]
	for p in panels_to_rebuild:
		if p:
			p.queue_free()

	var vp = get_viewport_rect().size
	_build_army_panel(vp)
	_build_kingdom_panel(vp)
	_build_diplomacy_panel(vp)
	_build_character_panel(vp)

	# Restore visibility
	_switch_tab(current_tab)
