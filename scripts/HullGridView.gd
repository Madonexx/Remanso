class_name HullGridView
extends Control

signal pending_fish_stored(species_id: String, length_cm: int)

const CELL_SIZE: float = 58.0
const COLS: int = 6
const ROWS: int = 4

# Unified cursor fish dictionary (either newly caught OR picked up / swapped from grid)
var cursor_fish: Dictionary = {}
var hover_col: int = 0
var hover_row: int = 0
var selected_uid: int = -1

var _icon_cache: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE)
	GameState.inventory_changed.connect(queue_redraw)

func start_placing_caught_fish(species_id: String, length_cm: int) -> void:
	var spec: Dictionary = GameState.SPECIES_CATALOG[species_id]
	cursor_fish = {
		"species_id": species_id,
		"name": String(spec["name"]),
		"length_cm": length_cm,
		"w": int(spec["w"]),
		"h": int(spec["h"]),
		"rotated": false,
		"icon": String(spec["icon"]),
		"color": spec["color"]
	}
	selected_uid = -1
	queue_redraw()

func has_cursor_fish() -> bool:
	return not cursor_fish.is_empty()

func flush_cursor_fish_on_close() -> void:
	if cursor_fish.is_empty():
		return
	var sp_id: String = String(cursor_fish["species_id"])
	var cm: int = int(cursor_fish["length_cm"])
	var nm: String = String(cursor_fish["name"])
	cursor_fish.clear()
	if not GameState.try_auto_add_fish(sp_id, cm):
		GameState.emit_signal("notification_requested", "%s devuelto al agua por falta de espacio en bodega." % nm, Color(0.95, 0.72, 0.35))
	queue_redraw()

func rotate_active_item() -> void:
	if not cursor_fish.is_empty():
		var tmp: int = int(cursor_fish["w"])
		cursor_fish["w"] = int(cursor_fish["h"])
		cursor_fish["h"] = tmp
		cursor_fish["rotated"] = not bool(cursor_fish["rotated"])
		queue_redraw()
		return
	var target_uid: int = selected_uid
	if target_uid == -1:
		target_uid = GameState.grid_cells[hover_row * COLS + hover_col]
	if target_uid != 0 and target_uid != -1:
		for item: Dictionary in GameState.inventory_items:
			if int(item["uid"]) == target_uid:
				var nw: int = int(item["h"])
				var nh: int = int(item["w"])
				var nrot: bool = not bool(item["rotated"])
				GameState.move_or_rotate_item(target_uid, int(item["col"]), int(item["row"]), nw, nh, nrot)
				break

func discard_selected_or_held() -> void:
	if not cursor_fish.is_empty():
		var nm: String = String(cursor_fish.get("name", "Pescado"))
		cursor_fish.clear()
		GameState.emit_signal("notification_requested", "%s devuelto al río." % nm, Color(0.55, 0.9, 0.65))
		emit_signal("pending_fish_stored", "", 0)
		queue_redraw()
		return

	var target_uid: int = selected_uid
	if target_uid == -1:
		target_uid = GameState.grid_cells[hover_row * COLS + hover_col]
	if target_uid != 0 and target_uid != -1:
		var item: Dictionary = GameState.get_item_by_uid(target_uid)
		var nm2: String = String(item.get("name", "Pescado"))
		GameState.remove_item(target_uid)
		selected_uid = -1
		GameState.emit_signal("notification_requested", "%s arrojado por la borda." % nm2, Color(0.85, 0.75, 0.5))
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		hover_col = clampi(int(floor(mm.position.x / CELL_SIZE)), 0, COLS - 1)
		hover_row = clampi(int(floor(mm.position.y / CELL_SIZE)), 0, ROWS - 1)
		queue_redraw()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if not mb.pressed:
			return
		var c: int = clampi(int(floor(mb.position.x / CELL_SIZE)), 0, COLS - 1)
		var r: int = clampi(int(floor(mb.position.y / CELL_SIZE)), 0, ROWS - 1)
		hover_col = c
		hover_row = r
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			rotate_active_item()
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(c, r)
			accept_event()

func _handle_left_click(c: int, r: int) -> void:
	if not cursor_fish.is_empty():
		var pw: int = int(cursor_fish["w"])
		var ph: int = int(cursor_fish["h"])
		if c < 0 or r < 0 or c + pw > COLS or r + ph > ROWS:
			return
		var overlaps: Array[int] = GameState.get_overlapping_uids(c, r, pw, ph)
		if overlaps.is_empty():
			var sp_id: String = String(cursor_fish["species_id"])
			var cm: int = int(cursor_fish["length_cm"])
			var rot: bool = bool(cursor_fish["rotated"])
			cursor_fish.clear()
			GameState._place_new_fish(sp_id, cm, c, r, pw, ph, rot)
			emit_signal("pending_fish_stored", sp_id, cm)
			queue_redraw()
		elif overlaps.size() == 1:
			var swap_uid: int = overlaps[0]
			var swapped_item: Dictionary = GameState.get_item_by_uid(swap_uid)
			GameState.remove_item(swap_uid)
			var sp_id2: String = String(cursor_fish["species_id"])
			var cm2: int = int(cursor_fish["length_cm"])
			var rot2: bool = bool(cursor_fish["rotated"])
			GameState._place_new_fish(sp_id2, cm2, c, r, pw, ph, rot2)
			cursor_fish = {
				"species_id": String(swapped_item["species_id"]),
				"name": String(swapped_item["name"]),
				"length_cm": int(swapped_item["length_cm"]),
				"w": int(swapped_item["w"]),
				"h": int(swapped_item["h"]),
				"rotated": bool(swapped_item["rotated"]),
				"icon": String(swapped_item["icon"]),
				"color": swapped_item["color"]
			}
			selected_uid = -1
			queue_redraw()
		return

	var clicked_uid: int = GameState.grid_cells[r * COLS + c]
	if clicked_uid != 0:
		var item: Dictionary = GameState.get_item_by_uid(clicked_uid)
		if not item.is_empty():
			GameState.remove_item(clicked_uid)
			cursor_fish = {
				"species_id": String(item["species_id"]),
				"name": String(item["name"]),
				"length_cm": int(item["length_cm"]),
				"w": int(item["w"]),
				"h": int(item["h"]),
				"rotated": bool(item["rotated"]),
				"icon": String(item["icon"]),
				"color": item["color"]
			}
			selected_uid = -1
			queue_redraw()

func _get_icon(path: String) -> Texture2D:
	if not _icon_cache.has(path):
		_icon_cache[path] = load(path)
	return _icon_cache[path] as Texture2D

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var hovered_uid: int = GameState.grid_cells[hover_row * COLS + hover_col]

	# 1. Draw base 6x4 grid cells
	for r: int in range(ROWS):
		for c: int in range(COLS):
			var rect: Rect2 = Rect2(c * CELL_SIZE, r * CELL_SIZE, CELL_SIZE - 2.0, CELL_SIZE - 2.0)
			draw_rect(rect, Color(0.08, 0.12, 0.13, 0.94), true)
			draw_rect(rect, Color(0.788, 0.604, 0.271, 0.38), false, 1.5)

	# 2. Draw placed items
	for item: Dictionary in GameState.inventory_items:
		var uid: int = int(item["uid"])
		var ic: int = int(item["col"])
		var ir: int = int(item["row"])
		var iw: int = int(item["w"])
		var ih: int = int(item["h"])
		var irect: Rect2 = Rect2(ic * CELL_SIZE + 2.0, ir * CELL_SIZE + 2.0, iw * CELL_SIZE - 6.0, ih * CELL_SIZE - 6.0)
		var base_col: Color = item["color"] as Color
		var is_bad: bool = bool(item["is_protected"]) or not bool(item["is_legal_size"])
		var fill_col: Color = Color(0.45, 0.18, 0.16, 0.88) if is_bad else Color(base_col.r * 0.45, base_col.g * 0.45, base_col.b * 0.45, 0.9)
		draw_rect(irect, fill_col, true)
		var is_hi: bool = (uid == selected_uid or (cursor_fish.is_empty() and uid == hovered_uid))
		var border_col: Color = Color(0.98, 0.88, 0.48) if is_hi else (Color(0.95, 0.35, 0.3) if is_bad else Color(0.788, 0.604, 0.271, 0.9))
		draw_rect(irect, border_col, false, 2.5 if is_hi else 2.0)

		var tex: Texture2D = _get_icon(String(item["icon"]))
		if tex:
			var icon_sz: float = minf(irect.size.x, irect.size.y) * 0.56
			var icon_pos: Vector2 = irect.position + (irect.size - Vector2(icon_sz, icon_sz)) * 0.5
			draw_texture_rect(tex, Rect2(icon_pos, Vector2(icon_sz, icon_sz)), false, Color(0.95, 0.92, 0.84, 0.92))

		var lbl: String = "%s (%dcm)" % [String(item["name"]).substr(0, 7), int(item["length_cm"])]
		draw_string(font, irect.position + Vector2(5.0, 14.0), lbl, HORIZONTAL_ALIGNMENT_LEFT, irect.size.x - 8.0, 11, Color(0.95, 0.92, 0.82))

	# 3. Draw ghost preview for cursor_fish
	if not cursor_fish.is_empty():
		var gw: int = int(cursor_fish["w"])
		var gh: int = int(cursor_fish["h"])
		var in_bounds: bool = (hover_col >= 0 and hover_row >= 0 and hover_col + gw <= COLS and hover_row + gh <= ROWS)
		var overlaps: Array[int] = []
		if in_bounds:
			overlaps = GameState.get_overlapping_uids(hover_col, hover_row, gw, gh)
		var can_place_or_swap: bool = in_bounds and overlaps.size() <= 1
		var g_col: Color = Color(0.25, 0.88, 0.45, 0.58) if (in_bounds and overlaps.is_empty()) else (
			Color(0.95, 0.78, 0.25, 0.62) if can_place_or_swap else Color(0.95, 0.28, 0.25, 0.58)
		)
		var grect: Rect2 = Rect2(hover_col * CELL_SIZE + 2.0, hover_row * CELL_SIZE + 2.0, gw * CELL_SIZE - 6.0, gh * CELL_SIZE - 6.0)
		draw_rect(grect, g_col, true)
		draw_rect(grect, Color.WHITE, false, 2.0)
		var action_lbl: String = "Intercambiar" if (can_place_or_swap and overlaps.size() == 1) else "Colocar"
		var ghost_name: String = "%s (%dx%d) — %s [R: Rotar]" % [String(cursor_fish["name"]), gw, gh, action_lbl]
		draw_string(font, grect.position + Vector2(6.0, 18.0), ghost_name, HORIZONTAL_ALIGNMENT_LEFT, 240.0, 12, Color.WHITE)
