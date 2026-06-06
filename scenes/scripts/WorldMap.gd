[gd_scene format=3]

[node name="WorldMap" type="Node2D"]
script = ExtResource("res://scripts/WorldMap.gd")

[node name="Camera2D" type="Camera2D" parent="."]
zoom = Vector2(1.2, 1.2)

[node name="Regions" type="Node2D" parent="."]

[node name="UI" type="CanvasLayer" parent="."]

[node name="HUD" type="Control" parent="UI"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="TopBar" type="PanelContainer" parent="UI/HUD"]
anchor_right = 1.0
offset_bottom = 70

[node name="TopBarContent" type="HBoxContainer" parent="UI/HUD/TopBar"]
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_constants/separation = 20

[node name="FactionLabel" type="Label" parent="UI/HUD/TopBar/TopBarContent"]
text = "☽ Osmanlı"
theme_override_font_sizes/font_size = 16

[node name="GoldLabel" type="Label" parent="UI/HUD/TopBar/TopBarContent"]
text = "🪙 5000"
theme_override_font_sizes/font_size = 16

[node name="TurnLabel" type="Label" parent="UI/HUD/TopBar/TopBarContent"]
text = "Tur: 1"
theme_override_font_sizes/font_size = 16

[node name="EndTurnBtn" type="Button" parent="UI/HUD/TopBar/TopBarContent"]
text = "Tur Bitir"
custom_minimum_size = Vector2(120, 50)
theme_override_font_sizes/font_size = 15

[node name="RegionPanel" type="PanelContainer" parent="UI/HUD"]
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = -180
visible = false

[node name="RegionContent" type="VBoxContainer" parent="UI/HUD/RegionPanel"]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="RegionName" type="Label" parent="UI/HUD/RegionPanel/RegionContent"]
text = "Bölge"
theme_override_font_sizes/font_size = 18

[node name="RegionInfo" type="Label" parent="UI/HUD/RegionPanel/RegionContent"]
text = "Sahip: —"
theme_override_font_sizes/font_size = 14

[node name="ActionButtons" type="HBoxContainer" parent="UI/HUD/RegionPanel/RegionContent"]

[node name="AttackBtn" type="Button" parent="UI/HUD/RegionPanel/RegionContent/ActionButtons"]
text = "⚔ Saldır"
custom_minimum_size = Vector2(110, 50)

[node name="DiplomacyBtn" type="Button" parent="UI/HUD/RegionPanel/RegionContent/ActionButtons"]
text = "🤝 Diplomasi"
custom_minimum_size = Vector2(110, 50)

[node name="BuildBtn" type="Button" parent="UI/HUD/RegionPanel/RegionContent/ActionButtons"]
text = "🏗 İnşa Et"
custom_minimum_size = Vector2(110, 50)
