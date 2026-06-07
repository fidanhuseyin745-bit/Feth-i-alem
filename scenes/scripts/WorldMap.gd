extends Node2D

var current_turn = 1
var gold = 5000
var selected_region = null

@onready var faction_label = $UI/HUD/TopBar/TopBarContent/FactionLabel
@onready var gold_label = $UI/HUD/TopBar/TopBarContent/GoldLabel
@onready var turn_label = $UI/HUD/TopBar/TopBarContent/TurnLabel
@onready var region_panel = $UI/HUD/RegionPanel
@onready var region_name = $UI/HUD/RegionPanel/RegionContent/RegionName
@onready var region_info = $UI/HUD/RegionPanel/RegionContent/RegionInfo
@onready var end_turn_btn = $UI/HUD/TopBar/TopBarContent/EndTurnBtn

func _ready():
    if not end_turn_btn:
        push_error("WorldMap: EndTurnBtn node not found at expected path")
        return
    if not gold_label or not turn_label:
        push_error("WorldMap: HUD label nodes not found — check scene tree paths")
        return
    end_turn_btn.pressed.connect(_on_end_turn)
    update_hud()

func update_hud():
    if not gold_label or not turn_label:
        push_error("WorldMap.update_hud: HUD labels are null, cannot update")
        return
    gold_label.text = "🪙 " + str(gold)
    turn_label.text = "Tur: " + str(current_turn)

func _on_end_turn():
    current_turn += 1
    gold += 200
    update_hud()

func select_region(region):
    if region == null:
        push_error("WorldMap.select_region: received null region")
        return
    selected_region = region
    if not region_panel or not region_name or not region_info:
        push_error("WorldMap.select_region: region panel nodes are null")
        return
    region_panel.visible = true
    region_name.text = region.region_name if "region_name" in region else "Unknown"
    region_info.text = "Sahip: " + (region.owner_name if "owner_name" in region else "Unknown")
