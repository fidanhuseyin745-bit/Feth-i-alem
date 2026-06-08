extends Node
## Bannerlord-style dark medieval UI theme constants and helpers.

# ── Colors ──────────────────────────────────────────────────────────────
const BG_DARK      := Color(0.10, 0.08, 0.05, 1.0)   # Main background
const BG_PANEL     := Color(0.16, 0.13, 0.09, 0.95)   # Panel backgrounds
const BG_CARD      := Color(0.20, 0.16, 0.10, 0.90)   # Card/item backgrounds
const BG_INPUT     := Color(0.12, 0.10, 0.07, 1.0)    # Input fields
const BORDER_GOLD  := Color(0.77, 0.63, 0.21, 0.8)    # Gold borders
const BORDER_DIM   := Color(0.4, 0.35, 0.25, 0.5)     # Dim borders
const TEXT_PRIMARY  := Color(0.91, 0.84, 0.69, 1.0)   # Primary text
const TEXT_SECONDARY:= Color(0.65, 0.58, 0.45, 1.0)   # Secondary text
const TEXT_GOLD     := Color(0.98, 0.78, 0.15, 1.0)   # Gold accent text
const TEXT_HEADER   := Color(0.83, 0.66, 0.25, 1.0)   # Headers
const ACCENT_GOLD   := Color(0.83, 0.66, 0.25, 1.0)   # Active/selected
const ACCENT_RED    := Color(0.85, 0.2, 0.2, 1.0)     # Danger/war
const ACCENT_GREEN  := Color(0.2, 0.7, 0.3, 1.0)      # Success/peace
const TAB_ACTIVE    := Color(0.83, 0.66, 0.25, 1.0)   # Active tab
const TAB_INACTIVE  := Color(0.45, 0.40, 0.30, 1.0)   # Inactive tab
const BTN_NORMAL    := Color(0.18, 0.15, 0.10, 1.0)
const BTN_HOVER     := Color(0.25, 0.20, 0.13, 1.0)
const BTN_PRESSED   := Color(0.30, 0.24, 0.15, 1.0)
const BTN_PRIMARY   := Color(0.50, 0.40, 0.15, 1.0)
const BTN_DANGER    := Color(0.55, 0.15, 0.10, 1.0)

# ── Dimensions ──────────────────────────────────────────────────────────
const NAV_BAR_HEIGHT := 110
const TOP_BAR_HEIGHT := 70
const PANEL_CORNER   := 8
const CARD_CORNER    := 6
const FONT_TITLE     := 28
const FONT_HEADER    := 22
const FONT_BODY      := 18
const FONT_SMALL     := 14
const FONT_TAB       := 13

# ── Style Helpers ───────────────────────────────────────────────────────

static func make_panel_style(bg: Color = BG_PANEL, corner: int = PANEL_CORNER, border: Color = BORDER_GOLD, bw: int = 1) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(corner)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func make_card_style(bg: Color = BG_CARD) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(CARD_CORNER)
	s.border_color = BORDER_DIM
	s.set_border_width_all(1)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

static func make_button_style(bg: Color = BTN_NORMAL, corner: int = CARD_CORNER, border: Color = BORDER_GOLD, bw: int = 1) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(corner)
	s.border_color = border
	s.set_border_width_all(bw)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func style_button(btn: Button, primary: bool = false, danger: bool = false):
	var bg = BTN_PRIMARY if primary else (BTN_DANGER if danger else BTN_NORMAL)
	var hover = Color(bg, 1.0)
	hover.r += 0.08
	hover.g += 0.06
	hover.b += 0.03
	var pressed = Color(bg, 1.0)
	pressed.r += 0.12
	pressed.g += 0.10
	pressed.b += 0.05
	btn.add_theme_stylebox_override("normal", make_button_style(bg))
	btn.add_theme_stylebox_override("hover", make_button_style(hover))
	btn.add_theme_stylebox_override("pressed", make_button_style(pressed))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", TEXT_GOLD)
	btn.add_theme_font_size_override("font_size", FONT_BODY)

static func style_label_header(lbl: Label):
	lbl.add_theme_color_override("font_color", TEXT_HEADER)
	lbl.add_theme_font_size_override("font_size", FONT_HEADER)

static func style_label_body(lbl: Label):
	lbl.add_theme_color_override("font_color", TEXT_PRIMARY)
	lbl.add_theme_font_size_override("font_size", FONT_BODY)

static func style_label_small(lbl: Label):
	lbl.add_theme_color_override("font_color", TEXT_SECONDARY)
	lbl.add_theme_font_size_override("font_size", FONT_SMALL)

static func make_separator() -> HSeparator:
	var sep = HSeparator.new()
	var style = StyleBoxFlat.new()
	style.bg_color = BORDER_DIM
	var empty = StyleBoxEmpty.new()
	sep.add_theme_stylebox_override("separator", style)
	sep.add_theme_constant_override("separation", 1)
	return sep

static func tier_color(tier: int) -> Color:
	match tier:
		1: return Color(0.6, 0.6, 0.6)
		2: return Color(0.3, 0.7, 0.3)
		3: return Color(0.3, 0.5, 0.9)
		4: return Color(0.9, 0.7, 0.1)
		_: return TEXT_PRIMARY

static func tier_label(tier: int) -> String:
	match tier:
		1: return "I"
		2: return "II"
		3: return "III"
		4: return "IV"
		_: return "?"
