extends Node

signal phase_changed(new_phase: TimePhase, day: int)
signal time_updated(normalized_day_progress: float, phase: TimePhase, phase_time_left: float)
signal stats_changed()
@warning_ignore("unused_signal")
signal motor_mode_changed(is_motor: bool, noise_radius: float)
signal pier_state_changed(at_pier: bool)
@warning_ignore("unused_signal")
signal wake_wave_triggered(direction: Vector3, intensity: float)
signal night_confiscated()
signal game_ended(ending_id: String, title: String, description: String)
signal notification_requested(message: String, color: Color)
signal inventory_changed()

enum TimePhase { DAY, SUNSET, NIGHT }

const DAY_DURATION: float = 150.0
const SUNSET_DURATION: float = 45.0
const GRID_COLS: int = 6
const GRID_ROWS: int = 4
const REQUIRED_PHOTOS: int = 10

var current_day: int = 1
var current_phase: TimePhase = TimePhase.DAY
var phase_elapsed: float = 0.0
var is_time_paused: bool = false
var is_game_over: bool = false

var money: int = 60
var river_health: float = 75.0
var hull_hp: float = 100.0
var max_hull_hp: float = 100.0
var photo_count: int = 0
var night_photos_pending: int = 0
var photographed_targets: Dictionary = {}
var tagged_fish_count: int = 0

var is_motor_mode: bool = false
var noise_radius: float = 0.0
var is_hidden_in_reeds: bool = false
var is_at_pier: bool = false
var docked_since_sunset: bool = false

var active_passive_nets: int = 0

var upgrades: Dictionary = {
	"remos_anchos": false,
	"cana_tacuara": false,
	"bichero_machete": false,
	"linea_trenzada": false,
	"casco_reforzado": false,
	"senuelo_litoral": false,
	"malla_extra": false,
	"teleobjetivo": false
}

const UPGRADE_CATALOG: Dictionary = {
	"remos_anchos": {
		"name": "Remos de pala ancha",
		"desc": "Mayor empuje y velocidad en modo remo silencioso (+45%).",
		"cost": 220
	},
	"cana_tacuara": {
		"name": "Caña de tacuara y reel reforzado",
		"desc": "Frena un 28% la aguja de pesca y reduce a la mitad el tirón de Surubí y Patí.",
		"cost": 260
	},
	"bichero_machete": {
		"name": "Bichero y machete afilado",
		"desc": "Corta los tramayos clandestinos en 2 s en vez de 6 s.",
		"cost": 340
	},
	"linea_trenzada": {
		"name": "Línea trenzada y carnada viva",
		"desc": "Agranda un +42% las zonas verdes de pique y suma +4 s de aguante en la línea.",
		"cost": 380
	},
	"casco_reforzado": {
		"name": "Casco de lapacho reforzado",
		"desc": "Reduce un 60% el daño por marejada de buques y golpes.",
		"cost": 460
	},
	"senuelo_litoral": {
		"name": "Señuelo artesanal del litoral",
		"desc": "Calma un 65% los giros bruscos de Dorado y Pacú y atrae ejemplares más grandes.",
		"cost": 520
	},
	"malla_extra": {
		"name": "Malla reglamentaria extra",
		"desc": "Permite calar hasta 2 redes pasivas legales durante el día.",
		"cost": 580
	},
	"teleobjetivo": {
		"name": "Cámara con teleobjetivo",
		"desc": "Duplica el alcance para fotografiar barcazas e ilícitos de noche.",
		"cost": 750
	}
}

const SPECIES_CATALOG: Dictionary = {
	"sabalo": {
		"name": "Sábalo",
		"w": 1, "h": 2,
		"min_cm": 40, "range_cm": Vector2i(30, 56),
		"base_price": 18,
		"protected": false,
		"needle_speed": 1.45,
		"green_arc_deg": 56.0,
		"icon": "res://Used_Assets/ui/salmon.png",
		"color": Color(0.55, 0.68, 0.72)
	},
	"boga": {
		"name": "Boga",
		"w": 1, "h": 2,
		"min_cm": 42, "range_cm": Vector2i(32, 62),
		"base_price": 22,
		"protected": false,
		"needle_speed": 1.70,
		"green_arc_deg": 48.0,
		"icon": "res://Used_Assets/ui/flying-trout.png",
		"color": Color(0.65, 0.72, 0.52)
	},
	"pati": {
		"name": "Patí",
		"w": 1, "h": 3,
		"min_cm": 60, "range_cm": Vector2i(46, 95),
		"base_price": 45,
		"protected": false,
		"needle_speed": 2.65,
		"green_arc_deg": 32.0,
		"icon": "res://Used_Assets/ui/eel.png",
		"color": Color(0.45, 0.52, 0.64)
	},
	"surubi": {
		"name": "Surubí Pintado",
		"w": 1, "h": 4,
		"min_cm": 85, "range_cm": Vector2i(68, 135),
		"base_price": 65,
		"protected": false,
		"needle_speed": 3.05,
		"green_arc_deg": 27.0,
		"icon": "res://Used_Assets/ui/fish-monster.png",
		"color": Color(0.76, 0.64, 0.36)
	},
	"dorado": {
		"name": "Dorado (Veda)",
		"w": 1, "h": 3,
		"min_cm": 70, "range_cm": Vector2i(48, 105),
		"base_price": 25,
		"protected": true,
		"needle_speed": 3.45,
		"green_arc_deg": 25.0,
		"icon": "res://Used_Assets/ui/double-fish.png",
		"color": Color(0.92, 0.72, 0.18)
	},
	"pacu": {
		"name": "Pacú (Protegido)",
		"w": 2, "h": 2,
		"min_cm": 45, "range_cm": Vector2i(34, 68),
		"base_price": 22,
		"protected": true,
		"needle_speed": 3.25,
		"green_arc_deg": 26.0,
		"icon": "res://Used_Assets/ui/boat-fishing.png",
		"color": Color(0.84, 0.45, 0.28)
	}
}

const ORDER_TEMPLATES: Array[Dictionary] = [
	{
		"title": "Comedor Isleño",
		"species_id": "sabalo",
		"species_label": "Sábalos reglamentarios",
		"required": 3,
		"reward_money": 95,
		"reward_health": 5.0
	},
	{
		"title": "Feria Popular de la Bajada",
		"species_id": "surubi",
		"species_label": "Surubíes adultos",
		"required": 2,
		"reward_money": 180,
		"reward_health": 4.0
	},
	{
		"title": "Pescadería Ribereña",
		"species_id": "boga",
		"species_label": "Bogas de medida",
		"required": 3,
		"reward_money": 110,
		"reward_health": 4.0
	},
	{
		"title": "Cooperativa del Puerto",
		"species_id": "pati",
		"species_label": "Patíes grandes",
		"required": 2,
		"reward_money": 135,
		"reward_health": 4.0
	},
	{
		"title": "Olla Popular del Barrio",
		"species_id": "sabalo",
		"species_label": "Sábalos adultos",
		"required": 4,
		"reward_money": 125,
		"reward_health": 6.0
	}
]

var active_orders: Array[Dictionary] = []
var _order_cursor: int = 0

var grid_cells: Array[int] = []
var inventory_items: Array[Dictionary] = []
var _next_item_uid: int = 1

func _ready() -> void:
	_init_grid()
	_refresh_daily_orders(true)
	emit_signal("phase_changed", current_phase, current_day)
	emit_signal("stats_changed")

func _process(delta: float) -> void:
	if is_game_over or is_time_paused:
		return
	if current_phase == TimePhase.DAY:
		phase_elapsed += delta
		var progress: float = clampf(phase_elapsed / DAY_DURATION, 0.0, 1.0) * 0.5
		emit_signal("time_updated", progress, current_phase, maxf(0.0, DAY_DURATION - phase_elapsed))
		if phase_elapsed >= DAY_DURATION:
			_set_phase(TimePhase.SUNSET)
	elif current_phase == TimePhase.SUNSET:
		if not is_at_pier:
			phase_elapsed += delta
			var progress: float = 0.5 + clampf(phase_elapsed / SUNSET_DURATION, 0.0, 1.0) * 0.3
			emit_signal("time_updated", progress, current_phase, maxf(0.0, SUNSET_DURATION - phase_elapsed))
			if phase_elapsed >= SUNSET_DURATION:
				emit_signal("notification_requested", "Cayó la noche en el Paraná. ¡Ojo con las barcazas clandestinas!", Color(0.95, 0.65, 0.25))
				_set_phase(TimePhase.NIGHT)
		else:
			var progress: float = 0.65
			emit_signal("time_updated", progress, current_phase, maxf(0.0, SUNSET_DURATION - phase_elapsed))
	elif current_phase == TimePhase.NIGHT:
		phase_elapsed += delta
		emit_signal("time_updated", 0.95, current_phase, 0.0)

func calculate_scientific_tag_bonus(species_id: String, length_cm: int) -> int:
	if not SPECIES_CATALOG.has(species_id):
		return 60
	var spec: Dictionary = SPECIES_CATALOG[species_id]
	var rng: Vector2i = spec["range_cm"] as Vector2i
	var t: float = clampf(float(length_cm - rng.x) / maxf(1.0, float(rng.y - rng.x)), 0.0, 1.0)
	return roundi(lerpf(55.0, 85.0, t))

func get_don_anselmo_daily_dialogue() -> String:
	var base_beat: String = ""
	match current_day:
		1:
			base_beat = "Día 1: \"Escuchame bien, hermano: en 7 días es la Audiencia Pública Ambiental. Arrancá con los Sábalos y Bogas en el Bajío, y si clavás un Dorado o Pacú, marcalo para los biólogos (+$55 a $85) y devolvelo al agua.\""
		2:
			base_beat = "Día 2: \"Anoche bajaron barcazas frigoríficas sin bandera por los riachos. Juntá unos pesos con los pedidos del comedor y fijate si La Negra Viera te arma una caña de tacuara para pelear los Patíes del Pozo.\""
		3:
			base_beat = "Día 3: \"Los furtivos están cerrando las bocas de laguna con tramayos ciegos. De noche llevate la cámara [F] y el machete: necesitamos llegar a %d fotos verificadas antes del séptimo día.\"" % REQUIRED_PHOTOS
		4:
			base_beat = "Día 4: \"Mitad de semana, che. El 'Turco' anda rondando el muelle al atardecer buscando pescado en veda para sus camiones... No le des de comer a esa mafia que nos mata el río.\""
		5:
			base_beat = "Día 5: \"Los biólogos del CONICET felicitaron a la Cooperativa: ya llevamos %d ejemplar(es) marcados y devueltos. Con el Señuelo Litoral y el Teleobjetivo vas a dominar el estero.\"" % tagged_fish_count
		6:
			base_beat = "Día 6: \"Mañana es el último día antes de la Audiencia Pública. Revisá cuántas pruebas fotográficas tenemos (%d/%d) y cuidame la Salud del Río (%d%%).\"" % [photo_count, REQUIRED_PHOTOS, roundi(river_health)]
		_:
			base_beat = "Día 7 (Última Jornada): \"Hoy se define el futuro del Paraná en la Audiencia. Asegurá las últimas fotos esta noche (%d/%d) y mantengamos el cauce arriba del 70%%.\"" % [photo_count, REQUIRED_PHOTOS]
	return base_beat

func get_negra_viera_dialogue() -> String:
	if not bool(upgrades.get("cana_tacuara", false)):
		return "La Negra Viera (Carpintera): \"Con la línea a mano los Surubíes y Dorados te van a bailar, che. Llevate la Caña de tacuara ($260) y la Línea trenzada ($380) para domar a los grandes.\""
	if not bool(upgrades.get("bichero_machete", false)):
		return "La Negra Viera (Carpintera): \"Para salir de noche entre los reflectores, afilá el Bichero y machete ($340): cortás los tramayos en 2 segundos y te escurrís al juncal.\""
	if not bool(upgrades.get("teleobjetivo", false)):
		return "La Negra Viera (Carpintera): \"Si querés sacarle fotos a las barcazas sin pegarte al reflector, ahorrá para el Teleobjetivo ($750): duplicás la distancia de foco.\""
	return "La Negra Viera (Carpintera): \"Tenés la canoa equipada como una reina del Paraná. Cuidá ese casco de lapacho cuando crucen los buques cerealeros.\""

func _set_phase(new_phase: TimePhase) -> void:
	current_phase = new_phase
	phase_elapsed = 0.0
	if new_phase == TimePhase.SUNSET:
		emit_signal("notification_requested", "Atardecer: Volvé al Muelle Cooperativo para vender y zarpar de noche.", Color(1.0, 0.72, 0.3))
	elif new_phase == TimePhase.NIGHT:
		docked_since_sunset = false
		photographed_targets.clear()
	emit_signal("phase_changed", current_phase, current_day)
	emit_signal("stats_changed")

func set_at_pier(docked: bool) -> void:
	if is_at_pier == docked:
		return
	is_at_pier = docked
	if docked:
		if current_phase == TimePhase.NIGHT:
			complete_night_and_advance_day()
		elif current_phase == TimePhase.SUNSET:
			docked_since_sunset = true
	else:
		if current_phase == TimePhase.SUNSET and docked_since_sunset:
			emit_signal("notification_requested", "Zarpando en plena noche. Apagá el motor cerca de las patrullas.", Color(0.55, 0.8, 1.0))
			_set_phase(TimePhase.NIGHT)
	emit_signal("pier_state_changed", is_at_pier)

func depart_into_night() -> void:
	docked_since_sunset = false
	_set_phase(TimePhase.NIGHT)

func complete_night_and_advance_day() -> void:
	var banked: int = night_photos_pending
	if banked > 0:
		photo_count += banked
		night_photos_pending = 0
	hull_hp = max_hull_hp
	current_day += 1
	if current_day > 7:
		current_day = 7
		emit_signal("stats_changed")
		_evaluate_day_7_ending()
		return
	docked_since_sunset = false
	_refresh_daily_orders(false)
	_set_phase(TimePhase.DAY)
	emit_signal("stats_changed")
	if banked > 0:
		emit_signal("notification_requested", "¡Día %d / 7! Don Anselmo reveló %d foto(s) de prueba en la Cooperativa." % [current_day, banked], Color(0.4, 0.95, 0.55))
	else:
		emit_signal("notification_requested", "Día %d de 7 — Amanece en el Paraná." % current_day, Color(0.95, 0.9, 0.55))

func confiscate_night_and_respawn() -> void:
	var lost: int = night_photos_pending
	night_photos_pending = 0
	apply_hull_damage(30.0, true)
	emit_signal("night_confiscated")
	if lost > 0:
		emit_signal("notification_requested", "¡Patrulla te interceptó! Te confiscaron %d foto(s) de esta noche." % lost, Color(1.0, 0.35, 0.35))
	else:
		emit_signal("notification_requested", "¡Patrulla clandestina te descubrió! Remolcado al muelle con daños.", Color(1.0, 0.35, 0.35))
	current_day += 1
	if current_day > 7:
		current_day = 7
		emit_signal("stats_changed")
		_evaluate_day_7_ending()
		return
	docked_since_sunset = false
	_refresh_daily_orders(false)
	_set_phase(TimePhase.DAY)
	emit_signal("stats_changed")

func _refresh_daily_orders(force_reset: bool) -> void:
	if force_reset:
		active_orders.clear()
		_order_cursor = 0
	for i: int in range(active_orders.size() - 1, -1, -1):
		if bool(active_orders[i].get("completed", false)):
			active_orders.remove_at(i)
	while active_orders.size() < 2:
		var tpl: Dictionary = ORDER_TEMPLATES[_order_cursor % ORDER_TEMPLATES.size()].duplicate()
		_order_cursor += 1
		tpl["progress"] = 0
		tpl["completed"] = false
		active_orders.append(tpl)

func record_sold_legal_fish(species_id: String, count: int) -> void:
	if count <= 0:
		return
	for order: Dictionary in active_orders:
		if bool(order.get("completed", false)):
			continue
		if String(order["species_id"]) == species_id:
			order["progress"] = mini(int(order["required"]), int(order["progress"]) + count)
			if int(order["progress"]) >= int(order["required"]):
				order["completed"] = true
				var bonus_money: int = int(order["reward_money"])
				var bonus_hp: float = float(order["reward_health"])
				money += bonus_money
				modify_river_health(bonus_hp, "¡Pedido cumplido (%s)! +$%d" % [String(order["title"]), bonus_money])
	_refresh_daily_orders(false)
	emit_signal("stats_changed")

func modify_river_health(amount: float, reason: String = "") -> void:
	river_health = clampf(river_health + amount, 0.0, 100.0)
	emit_signal("stats_changed")
	if reason != "":
		var col: Color = Color(0.4, 0.95, 0.5) if amount >= 0.0 else Color(1.0, 0.4, 0.35)
		emit_signal("notification_requested", "%s (Salud del río: %d%%)" % [reason, roundi(river_health)], col)
	if river_health <= 0.0 and not is_game_over:
		is_game_over = true
		emit_signal("game_ended", "colapso", "COLAPSO DEL CAUCE", "La sobrepesca, los tramayos y el negocio sucio de El 'Turco' agotaron la vida del Paraná. Don Anselmo y La Negra Viera tuvieron que cerrar la Cooperativa.")

func apply_hull_damage(raw_damage: float, bypass_armor: bool = false) -> void:
	var mult: float = 0.4 if (upgrades.get("casco_reforzado", false) and not bypass_armor) else 1.0
	hull_hp = clampf(hull_hp - raw_damage * mult, 0.0, max_hull_hp)
	emit_signal("stats_changed")
	if hull_hp <= 0.0:
		hull_hp = max_hull_hp * 0.5
		modify_river_health(-8.0, "Tu canoa zozobró en el río")
		emit_signal("night_confiscated")

func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	emit_signal("stats_changed")

func get_max_passive_nets() -> int:
	return 2 if upgrades.get("malla_extra", false) else 1

func _evaluate_day_7_ending() -> void:
	is_game_over = true
	if river_health >= 70.0 and photo_count >= REQUIRED_PHOTOS:
		emit_signal(
			"game_ended",
			"soberano",
			"FINAL SOBERANO — VICTORIA EN LA AUDIENCIA",
			"Don Anselmo presentó tus %d/%d fotografías y el registro de %d Dorados/Pacúes marcados en la Audiencia Pública. Clausuraron los frigoríficos furtivos de El 'Turco', La Negra Viera amplió el taller ribereño y la Cooperativa declaró Reserva Pesquera Artesanal al humedal (%d%% Salud del Río)." % [photo_count, REQUIRED_PHOTOS, tagged_fish_count, roundi(river_health)]
		)
	elif river_health >= 50.0:
		emit_signal(
			"game_ended",
			"resistencia",
			"FINAL DE RESISTENCIA — LUCHA EN LA RIBERA",
			"Sostuviste el ecosistema (%d%% Salud, %d ejemplares marcados) junto a Don Anselmo y La Negra Viera, pero con %d/%d pruebas fotográficas la justicia no clausuró a todas las barcazas clandestinas. Las canoas de la Cooperativa siguen resistiendo en el río." % [roundi(river_health), tagged_fish_count, photo_count, REQUIRED_PHOTOS]
		)
	else:
		emit_signal(
			"game_ended",
			"colapso",
			"COLAPSO DEL CAUCE",
			"Al séptimo día la salud del Paraná cayó a %d%%. Sin cardúmenes reproductores ni fuerzas en la Cooperativa, las flotas furtivas vaciaron los esteros ante la mirada triste de Don Anselmo." % roundi(river_health)
		)

# --- DREDGE 6x4 SPATIAL INVENTORY ---
func _init_grid() -> void:
	grid_cells.resize(GRID_COLS * GRID_ROWS)
	grid_cells.fill(0)
	inventory_items.clear()

func can_place_item(col: int, row: int, w: int, h: int, ignore_uid: int = -1) -> bool:
	if col < 0 or row < 0 or col + w > GRID_COLS or row + h > GRID_ROWS:
		return false
	for r: int in range(row, row + h):
		for c: int in range(col, col + w):
			var cell_val: int = grid_cells[r * GRID_COLS + c]
			if cell_val != 0 and cell_val != ignore_uid:
				return false
	return true

func get_overlapping_uids(col: int, row: int, w: int, h: int) -> Array[int]:
	var uids: Array[int] = []
	if col < 0 or row < 0 or col + w > GRID_COLS or row + h > GRID_ROWS:
		return uids
	for r: int in range(row, row + h):
		for c: int in range(col, col + w):
			var cell_val: int = grid_cells[r * GRID_COLS + c]
			if cell_val != 0 and not uids.has(cell_val):
				uids.append(cell_val)
	return uids

func get_item_by_uid(uid: int) -> Dictionary:
	for item: Dictionary in inventory_items:
		if int(item["uid"]) == uid:
			return item.duplicate()
	return {}

func try_auto_add_fish(species_id: String, length_cm: int) -> bool:
	if not SPECIES_CATALOG.has(species_id):
		return false
	var spec: Dictionary = SPECIES_CATALOG[species_id]
	var base_w: int = int(spec["w"])
	var base_h: int = int(spec["h"])
	for rot: int in [0, 1]:
		var w: int = base_w if rot == 0 else base_h
		var h: int = base_h if rot == 0 else base_w
		for r: int in range(GRID_ROWS - h + 1):
			for c: int in range(GRID_COLS - w + 1):
				if can_place_item(c, r, w, h):
					_place_new_fish(species_id, length_cm, c, r, w, h, rot == 1)
					return true
	return false

func _place_new_fish(species_id: String, length_cm: int, col: int, row: int, w: int, h: int, rotated: bool) -> void:
	var uid: int = _next_item_uid
	_next_item_uid += 1
	var spec: Dictionary = SPECIES_CATALOG[species_id]
	var is_legal_size: bool = length_cm >= int(spec["min_cm"])
	var is_protected: bool = bool(spec["protected"])
	var item: Dictionary = {
		"uid": uid,
		"species_id": species_id,
		"name": String(spec["name"]),
		"length_cm": length_cm,
		"min_cm": int(spec["min_cm"]),
		"is_legal_size": is_legal_size,
		"is_protected": is_protected,
		"base_price": int(spec["base_price"]),
		"col": col,
		"row": row,
		"w": w,
		"h": h,
		"rotated": rotated,
		"icon": String(spec["icon"]),
		"color": spec["color"]
	}
	for r: int in range(row, row + h):
		for c: int in range(col, col + w):
			grid_cells[r * GRID_COLS + c] = uid
	inventory_items.append(item)
	emit_signal("inventory_changed")

func move_or_rotate_item(uid: int, new_col: int, new_row: int, new_w: int, new_h: int, rotated: bool) -> bool:
	if not can_place_item(new_col, new_row, new_w, new_h, uid):
		return false
	for i: int in range(grid_cells.size()):
		if grid_cells[i] == uid:
			grid_cells[i] = 0
	for item: Dictionary in inventory_items:
		if int(item["uid"]) == uid:
			item["col"] = new_col
			item["row"] = new_row
			item["w"] = new_w
			item["h"] = new_h
			item["rotated"] = rotated
			for r: int in range(new_row, new_row + new_h):
				for c: int in range(new_col, new_col + new_w):
					grid_cells[r * GRID_COLS + c] = uid
			emit_signal("inventory_changed")
			return true
	return false

func remove_item(uid: int) -> void:
	for i: int in range(grid_cells.size()):
		if grid_cells[i] == uid:
			grid_cells[i] = 0
	for idx: int in range(inventory_items.size() - 1, -1, -1):
		if int(inventory_items[idx]["uid"]) == uid:
			inventory_items.remove_at(idx)
	emit_signal("inventory_changed")

func reset_game() -> void:
	current_day = 1
	current_phase = TimePhase.DAY
	phase_elapsed = 0.0
	is_time_paused = false
	is_game_over = false
	money = 60
	river_health = 75.0
	hull_hp = 100.0
	photo_count = 0
	night_photos_pending = 0
	photographed_targets.clear()
	tagged_fish_count = 0
	is_motor_mode = false
	noise_radius = 0.0
	is_hidden_in_reeds = false
	is_at_pier = false
	docked_since_sunset = false
	active_passive_nets = 0
	for k: String in upgrades.keys():
		upgrades[k] = false
	_init_grid()
	_refresh_daily_orders(true)
	emit_signal("phase_changed", current_phase, current_day)
	emit_signal("stats_changed")
	emit_signal("inventory_changed")
