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
    end_turn_btn.pressed.connect(_on_end_turn)
    update_hud()

func update_hud():
    gold_label.text = "🪙 " + str(gold)
    turn_label.text = "Tur: " + str(current_turn)

func _on_end_turn():
    current_turn += 1
    gold += 200
    update_hud()

func select_region(region):
    selected_region = region
    region_panel.visible = true
    region_name.text = region.region_name
    region_info.text = "Sahip: " + region.owner_name
