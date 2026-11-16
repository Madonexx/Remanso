class_name GameHUD
extends CanvasLayer

@onready var lbl_day_phase: Label = $Root/TopBar/HBox/LblDayPhase
@onready var bar_river_health: ProgressBar = $Root/TopBar/HBox/RiverBox/BarRiverHealth
@onready var lbl_river_pct: Label = $Root/TopBar/HBox/RiverBox/LblRiverPct
@onready var lbl_hull: Label = $Root/TopBar/HBox/LblHull
@onready var lbl_money: Label = $Root/TopBar/HBox/LblMoney
@onready var lbl_photos: Label = $Root/TopBar/HBox/LblPhotos
@onready var lbl_stealth_mode: Label = $Root/TopBar/HBox/LblStealthMode
@onready var btn_cam_toggle: Button = $Root/TopBar/HBox/BtnCamToggle

@onready var lbl_notification: Label = $Root/NotificationBanner/LblNotification
@onready var notification_banner: PanelContainer = $Root/NotificationBanner
@onready var prompt_panel: PanelContainer = $Root/PromptPanel
@onready var lbl_prompt: Label = $Root/PromptPanel/VBox/LblPrompt
@onready var bar_cut_progress: ProgressBar = $Root/PromptPanel/VBox/BarCutProgress

@onready var viewfinder_overlay: Control = $Root/ViewfinderOverlay
@onready var lbl_vf_zoom: Label = $Root/ViewfinderOverlay/FramePanel/VBox/LblVfZoom
@onready var lbl_vf_target: Label = $Root/ViewfinderOverlay/FramePanel/VBox/LblVfTarget
@onready var flash_rect: ColorRect = $Root/FlashRect

@onready var radial_ring: RadialFishingRing = $Root/RadialFishingRing

@onready var catch_modal: PanelContainer = $Root/CatchModal
@onready var catch_icon: TextureRect = $Root/CatchModal/VBox/HeaderHBox/FishIcon
@onready var lbl_catch_title: Label = $Root/CatchModal/VBox/HeaderHBox/TitleVBox/LblCatchTitle
@onready var lbl_catch_size: Label = $Root/CatchModal/VBox/HeaderHBox/TitleVBox/LblCatchSize
@onready var lbl_catch_stamp: Label = $Root/CatchModal/VBox/LblCatchStamp
@onready var lbl_catch_note: Label = $Root/CatchModal/VBox/LblCatchNote
@onready var btn_keep_fish: Button = $Root/CatchModal/VBox/BtnHBox/BtnKeepFish
@onready var btn_release_fish: Button = $Root/CatchModal/VBox/BtnHBox/BtnReleaseFish

@onready var inventory_modal: PanelContainer = $Root/InventoryModal
@onready var hull_grid_view: HullGridView = $Root/InventoryModal/VBox/GridCenter/HullGridView
@onready var lbl_inv_hint: Label = $Root/InventoryModal/VBox/LblInvHint
@onready var btn_discard_fish: Button = $Root/InventoryModal/VBox/BtnRow/BtnDiscardFish
@onready var btn_close_inv: Button = $Root/InventoryModal/VBox/BtnRow/BtnCloseInv

@onready var pier_modal: PanelContainer = $Root/PierModal
@onready var tab_venta: VBoxContainer = $Root/PierModal/VBox/ContentArea/TabVenta
@onready var tab_taller: VBoxContainer = $Root/PierModal/VBox/ContentArea/TabTaller
@onready var btn_tab_venta: Button = $Root/PierModal/VBox/TabButtons/BtnTabVenta
@onready var btn_tab_taller: Button = $Root/PierModal/VBox/TabButtons/BtnTabTaller
@onready var lbl_anselmo_dialogue: Label = $Root/PierModal/VBox/ContentArea/TabVenta/DonAnselmoBox/HBox/VBox/LblAnselmoDialogue
@onready var lbl_pier_cargo: Label = $Root/PierModal/VBox/ContentArea/TabVenta/LblPierCargo
@onready var lbl_orders_list: Label = $Root/PierModal/VBox/ContentArea/TabVenta/OrdersBox/VBox/LblOrdersList
@onready var btn_sell_legal: Button = $Root/PierModal/VBox/ContentArea/TabVenta/BtnSellLegal
@onready var shady_box: PanelContainer = $Root/PierModal/VBox/ContentArea/TabVenta/ShadyBox
@onready var lbl_shady_offer: Label = $Root/PierModal/VBox/ContentArea/TabVenta/ShadyBox/HBox/VBox/LblShadyOffer
@onready var btn_sell_shady: Button = $Root/PierModal/VBox/ContentArea/TabVenta/ShadyBox/HBox/VBox/BtnSellShady
@onready var btn_repair_hull: Button = $Root/PierModal/VBox/ContentArea/TabVenta/BtnRepairHull
@onready var lbl_viera_dialogue: Label = $Root/PierModal/VBox/ContentArea/TabTaller/NegraVieraBox/HBox/VBox/LblVieraDialogue
@onready var upgrades_list: VBoxContainer = $Root/PierModal/VBox/ContentArea/TabTaller/Scroll/UpgradesList
@onready var btn_pier_night: Button = $Root/PierModal/VBox/FooterRow/BtnPierNight
@onready var btn_pier_close: Button = $Root/PierModal/VBox/FooterRow/BtnPierClose

@onready var neighbor_modal: PanelContainer = $Root/NeighborModal
@onready var neighbor_icon: TextureRect = $Root/NeighborModal/VBox/HeaderHBox/PortraitBadge/NeighborIcon
@onready var lbl_neighbor_name: Label = $Root/NeighborModal/VBox/HeaderHBox/TitleVBox/LblNeighborName
@onready var lbl_neighbor_role: Label = $Root/NeighborModal/VBox/HeaderHBox/TitleVBox/LblNeighborRole
@onready var lbl_neighbor_dialogue: Label = $Root/NeighborModal/VBox/LblNeighborDialogue
@onready var btn_close_neighbor: Button = $Root/NeighborModal/VBox/BtnCloseNeighbor

@onready var title_overlay: PanelContainer = $Root/TitleOverlay
@onready var btn_start_game: Button = $Root/TitleOverlay/VBox/BtnStartGame

@onready var ending_modal: PanelContainer = $Root/EndingModal
@onready var lbl_ending_title: Label = $Root/EndingModal/VBox/LblEndingTitle
@onready var lbl_ending_desc: Label = $Root/EndingModal/VBox/LblEndingDesc
@onready var lbl_ending_stats: Label = $Root/EndingModal/VBox/LblEndingStats
@onready var btn_restart_game: Button = $Root/EndingModal/VBox/BtnRestartGame

var _notif_timer: float = 0.0
var _flash_alpha: float = 0.0
var _active_fishing_spot: FishingSpot = null
var _pending_catch_species: String = ""
var _pending_catch_cm: int = 0
var _passive_catch_queue: Array[Dictionary] = []
var _locked_evidence_node: Node3D = null
var _sfx_shutter: AudioStreamPlayer

func _ready() -> void:
	_sfx_shutter = AudioStreamPlayer.new()
	_sfx_shutter.stream = load("res://Used_Assets/audio/camera_shutter.wav")
	add_child(_sfx_shutter)

	notification_banner.visible = false
	catch_modal.visible = false
	inventory_modal.visible = false
	pier_modal.visible = false
	neighbor_modal.visible = false
	viewfinder_overlay.visible = false
	flash_rect.visible = false
	ending_modal.visible = false
	bar_cut_progress.visible = false

	GameState.stats_changed.connect(_refresh_top_bar)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.time_updated.connect(_on_time_updated)
	GameState.pier_state_changed.connect(_on_pier_state_changed)
	GameState.notification_requested.connect(_show_notification)
	GameState.inventory_changed.connect(_refresh_pier_ui)
	GameState.game_ended.connect(_on_game_ended)

	radial_ring.fish_caught.connect(_on_radial_fish_caught)
	radial_ring.fishing_cancelled.connect(_on_radial_cancelled)
	hull_grid_view.pending_fish_stored.connect(_on_pending_fish_stored)

	btn_keep_fish.pressed.connect(_on_keep_fish_pressed)
	btn_release_fish.pressed.connect(_on_release_fish_pressed)
	btn_discard_fish.pressed.connect(func() -> void: hull_grid_view.discard_selected_or_held())
	btn_close_inv.pressed.connect(_close_inventory)
	btn_cam_toggle.pressed.connect(_toggle_viewfinder)

	btn_tab_venta.pressed.connect(func() -> void: _switch_pier_tab(true))
	btn_tab_taller.pressed.connect(func() -> void: _switch_pier_tab(false))
	btn_sell_legal.pressed.connect(_on_sell_legal_pressed)
	btn_sell_shady.pressed.connect(_on_sell_shady_pressed)
	btn_repair_hull.pressed.connect(_on_repair_hull_pressed)
	btn_pier_night.pressed.connect(_on_pier_night_pressed)
	btn_pier_close.pressed.connect(_close_pier_modal)
	btn_close_neighbor.pressed.connect(_close_neighbor_modal)

	btn_start_game.pressed.connect(_on_start_game_pressed)
	btn_restart_game.pressed.connect(_on_restart_game_pressed)

	await _build_upgrade_rows()
	_refresh_top_bar()

	if GameState.current_day == 1 and GameState.phase_elapsed < 0.5:
		title_overlay.visible = true
		GameState.is_time_paused = true
	else:
		title_overlay.visible = false

func _process(delta: float) -> void:
	if _notif_timer > 0.0:
		_notif_timer -= delta
		if _notif_timer <= 0.0:
			notification_banner.visible = false

	if _flash_alpha > 0.0:
		_flash_alpha = move_toward(_flash_alpha, 0.0, delta * 3.2)
		flash_rect.color = Color(1.0, 0.98, 0.9, _flash_alpha)
		flash_rect.visible = (_flash_alpha > 0.01)

	_update_stealth_badge()
	_process_illegal_net_cutting(delta)
	_update_viewfinder_target()
	_update_context_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_game_over or title_overlay.visible:
		return

	if event.is_action_pressed("rotate_item") and inventory_modal.visible:
		hull_grid_view.rotate_active_item()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_inventory") and not catch_modal.visible and not pier_modal.visible and not neighbor_modal.visible and not radial_ring.is_active:
		if inventory_modal.visible:
			_close_inventory()
		else:
			_open_inventory()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_camera_mode") and not catch_modal.visible and not pier_modal.visible and not inventory_modal.visible and not neighbor_modal.visible and not radial_ring.is_active:
		_toggle_viewfinder()
		get_viewport().set_input_as_handled()
		return

	if viewfinder_overlay.visible and event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_try_snap_photo()
			get_viewport().set_input_as_handled()
			return
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_set_viewfinder(false)
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("interact"):
		if neighbor_modal.visible:
			_close_neighbor_modal()
			get_viewport().set_input_as_handled()
			return
		if viewfinder_overlay.visible:
			_try_snap_photo()
			get_viewport().set_input_as_handled()
			return
		if radial_ring.is_active:
			radial_ring.attempt_strike()
			get_viewport().set_input_as_handled()
			return
		if catch_modal.visible or inventory_modal.visible or pier_modal.visible:
			return
		_try_context_interact()

	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_ESCAPE:
			if viewfinder_overlay.visible:
				_set_viewfinder(false)
			elif neighbor_modal.visible:
				_close_neighbor_modal()
			elif radial_ring.is_active:
				radial_ring.stop_minigame()
				GameState.is_time_paused = false
			elif inventory_modal.visible:
				_close_inventory()
			elif pier_modal.visible:
				_close_pier_modal()

func _toggle_viewfinder() -> void:
	_set_viewfinder(not viewfinder_overlay.visible)

func _set_viewfinder(active: bool) -> void:
	viewfinder_overlay.visible = active
	var boat: PlayerBoat = get_tree().get_first_node_in_group("player_boat") as PlayerBoat
	if boat:
		boat.is_viewfinder_active = active
		if active:
			boat.viewfinder_pitch = -4.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE

func _update_viewfinder_target() -> void:
	_locked_evidence_node = null
	if not viewfinder_overlay.visible:
		return
	var has_tele: bool = bool(GameState.upgrades.get("teleobjetivo", false))
	var max_range: float = 56.0 if has_tele else 28.0
	lbl_vf_zoom.text = "VISOR DE PRUEBAS — %s (Alcance: %dm)  |  [Mouse] Apuntar  |  [F / Esc] Salir" % [
		"Teleobjetivo 2.0x" if has_tele else "Lente Estándar 1.0x",
		roundi(max_range)
	]

	var boat: PlayerBoat = get_tree().get_first_node_in_group("player_boat") as PlayerBoat
	if boat == null or boat.camera_3d == null:
		return

	var cam_pos: Vector3 = boat.camera_3d.global_position
	var cam_fwd: Vector3 = -boat.camera_3d.global_transform.basis.z.normalized()
	var best_dist: float = max_range

	for node: Node in get_tree().get_nodes_in_group("photo_evidence_target"):
		if node is Node3D and node.has_method("is_evidence_available"):
			if not bool(node.call("is_evidence_available")):
				continue
			var n3d: Node3D = node as Node3D
			var target_center: Vector3 = n3d.global_position + Vector3(0.0, 1.0, 0.0)
			var to_n: Vector3 = target_center - cam_pos
			var d: float = to_n.length()
			if d <= best_dist and d > 0.5:
				var dot_val: float = cam_fwd.dot(to_n.normalized())
				if dot_val >= 0.80:
					best_dist = d
					_locked_evidence_node = n3d

	if _locked_evidence_node != null:
		var lbl: String = String(_locked_evidence_node.call("get_evidence_label"))
		lbl_vf_target.text = "🎯 EN FOCO: %s (%dm) — [Click Izq / E] SACAR FOTO" % [lbl, roundi(best_dist)]
		lbl_vf_target.modulate = Color(0.35, 0.98, 0.52)
	else:
		lbl_vf_target.text = "Mové el mouse para encuadrar una barcaza clandestina o tramayo ilegal..."
		lbl_vf_target.modulate = Color(0.92, 0.86, 0.7)

func _try_snap_photo() -> void:
	_sfx_shutter.play()
	_flash_alpha = 0.85
	if _locked_evidence_node == null:
		GameState.emit_signal("notification_requested", "Foto sin objetivo claro. Acercate o encuadrá una barcaza/tramayo.", Color(0.95, 0.75, 0.35))
		return
	var ev_id: String = String(_locked_evidence_node.get("evidence_id"))
	var lbl: String = String(_locked_evidence_node.call("get_evidence_label"))
	GameState.photographed_targets[ev_id] = true
	GameState.night_photos_pending += 1
	GameState.emit_signal("stats_changed")
	GameState.emit_signal(
		"notification_requested",
		"📸 ¡Prueba registrada: %s! (1 por objetivo/noche). Volvé al Muelle para revelarla." % lbl,
		Color(0.42, 0.98, 0.62)
	)
	_update_viewfinder_target()

func _process_illegal_net_cutting(delta: float) -> void:
	var holding_e: bool = Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE)
	var active_cut_ratio: float = 0.0
	for node: Node in get_tree().get_nodes_in_group("illegal_net"):
		if node is IllegalNet:
			var inet: IllegalNet = node as IllegalNet
			if inet.player_inside and inet.is_active_net():
				active_cut_ratio = inet.process_cutting(delta, holding_e and not viewfinder_overlay.visible)
				break
	bar_cut_progress.visible = (active_cut_ratio > 0.01)
	bar_cut_progress.value = active_cut_ratio * 100.0

func _try_context_interact() -> void:
	if GameState.is_at_pier:
		if GameState.current_phase == GameState.TimePhase.NIGHT:
			GameState.complete_night_and_advance_day()
			if not GameState.is_game_over:
				_open_pier_modal()
		else:
			_open_pier_modal()
		return

	for node: Node in get_tree().get_nodes_in_group("neighbor_boat"):
		if node is NeighborBoat:
			var nboat: NeighborBoat = node as NeighborBoat
			if nboat.player_inside and nboat.is_available():
				_open_neighbor_modal(nboat)
				return

	for node: Node in get_tree().get_nodes_in_group("fishing_spot"):
		if node is FishingSpot:
			var spot: FishingSpot = node as FishingSpot
			if spot.player_inside and spot.is_available():
				_active_fishing_spot = spot
				GameState.is_time_paused = true
				radial_ring.start_minigame(spot.pick_random_species())
				return

	for node: Node in get_tree().get_nodes_in_group("passive_net_spot"):
		if node is PassiveNetSpot:
			var pnet: PassiveNetSpot = node as PassiveNetSpot
			if pnet.player_inside and GameState.current_phase != GameState.TimePhase.NIGHT:
				var harvested: Array[Dictionary] = pnet.interact_net()
				if not harvested.is_empty():
					_passive_catch_queue.clear()
					for h_entry: Dictionary in harvested:
						_passive_catch_queue.append(h_entry)
					_pop_next_passive_catch()
				return

func _open_neighbor_modal(nboat: NeighborBoat) -> void:
	_set_viewfinder(false)
	GameState.is_time_paused = true
	neighbor_icon.texture = load(nboat.portrait_icon)
	lbl_neighbor_name.text = nboat.fisher_name
	lbl_neighbor_role.text = nboat.fisher_role
	lbl_neighbor_dialogue.text = nboat.dialogue_text
	neighbor_modal.visible = true

func _close_neighbor_modal() -> void:
	neighbor_modal.visible = false
	if not title_overlay.visible and not GameState.is_game_over:
		GameState.is_time_paused = false

func _pop_next_passive_catch() -> void:
	if _passive_catch_queue.is_empty():
		return
	var entry: Dictionary = _passive_catch_queue.pop_front()
	_show_catch_card(String(entry["species_id"]), int(entry["length_cm"]))

func _update_context_prompt() -> void:
	if title_overlay.visible or ending_modal.visible or neighbor_modal.visible or radial_ring.is_active or catch_modal.visible or inventory_modal.visible or pier_modal.visible:
		prompt_panel.visible = false
		return

	if GameState.is_at_pier:
		prompt_panel.visible = true
		if GameState.current_phase == GameState.TimePhase.NIGHT:
			lbl_prompt.text = "[E] Amarrar y Revelar Fotos (Terminar Noche)"
		else:
			lbl_prompt.text = "[E] Amarrar en la Cooperativa (Don Anselmo y La Negra Viera)"
		return

	for node: Node in get_tree().get_nodes_in_group("illegal_net"):
		if node is IllegalNet:
			var inet: IllegalNet = node as IllegalNet
			if inet.player_inside and inet.is_active_net():
				prompt_panel.visible = true
				var secs: int = roundi(inet.get_required_cut_time())
				lbl_prompt.text = "[Mantener E] Cortar tramayo ilegal en %s (%ds)" % [inet.net_location, secs]
				return

	for node: Node in get_tree().get_nodes_in_group("neighbor_boat"):
		if node is NeighborBoat:
			var nboat: NeighborBoat = node as NeighborBoat
			if nboat.player_inside and nboat.is_available():
				prompt_panel.visible = true
				lbl_prompt.text = "[E] Charlar con pescador vecino — %s" % nboat.fisher_name
				return

	for node: Node in get_tree().get_nodes_in_group("fishing_spot"):
		if node is FishingSpot:
			var spot: FishingSpot = node as FishingSpot
			if spot.player_inside and spot.is_available():
				prompt_panel.visible = true
				lbl_prompt.text = spot.get_habitat_prompt()
				return

	for node: Node in get_tree().get_nodes_in_group("passive_net_spot"):
		if node is PassiveNetSpot:
			var pnet: PassiveNetSpot = node as PassiveNetSpot
			if pnet.player_inside:
				var txt: String = pnet.get_prompt_text()
				if txt != "":
					prompt_panel.visible = true
					lbl_prompt.text = txt
					return

	prompt_panel.visible = false

func _on_radial_fish_caught(species_id: String, length_cm: int) -> void:
	var final_cm: int = length_cm
	if _active_fishing_spot != null:
		if _active_fishing_spot.habitat_type == FishingSpot.HabitatType.BAJIO_COSTA and species_id == "dorado":
			final_cm = randi_range(48, 66)
		_active_fishing_spot.consume_catch()
		_active_fishing_spot = null
	_show_catch_card(species_id, final_cm)

func _on_radial_cancelled() -> void:
	_active_fishing_spot = null
	GameState.is_time_paused = false

func _show_catch_card(species_id: String, length_cm: int) -> void:
	_set_viewfinder(false)
	GameState.is_time_paused = true
	_pending_catch_species = species_id
	_pending_catch_cm = length_cm
	var spec: Dictionary = GameState.SPECIES_CATALOG[species_id]
	var min_cm: int = int(spec["min_cm"])
	var is_prot: bool = bool(spec["protected"])
	var is_legal: bool = (length_cm >= min_cm) and not is_prot

	catch_icon.texture = load(String(spec["icon"]))
	lbl_catch_title.text = String(spec["name"])
	lbl_catch_size.text = "Talla medida: %d cm  |  Mínimo legal: %d cm  |  Celdas: %dx%d" % [
		length_cm, min_cm, int(spec["w"]), int(spec["h"])
	]

	if is_prot:
		var tag_bonus: int = GameState.calculate_scientific_tag_bonus(species_id, length_cm)
		lbl_catch_stamp.text = "⚠ ESPECIE PROTEGIDA — PROGRAMA DE MARCADO CIENTÍFICO"
		lbl_catch_stamp.modulate = Color(0.18, 0.58, 0.32)
		lbl_catch_note.text = "Marcarlo y devolverlo al río paga Bono Científico (+$%d y +4%% Salud del Río). Guardarlo en bodega para El 'Turco' daña el cauce (-12%%)." % tag_bonus
		btn_release_fish.text = "Marcar y Devolver (+$%d / +4%% Río)" % tag_bonus
	elif not is_legal:
		lbl_catch_stamp.text = "⚠ JUVENIL BAJO TALLA REGLAMENTARIA"
		lbl_catch_stamp.modulate = Color(0.92, 0.45, 0.15)
		lbl_catch_note.text = "Aún no se reprodujo. Devolvelo al cauce (+3%% Salud del Río). Guardarlo reduce la Salud del Río (-8%%)."
		btn_release_fish.text = "Devolver al río (+3% Río)"
	else:
		lbl_catch_stamp.text = "✓ TALLA REGLAMENTARIA LEGAL"
		lbl_catch_stamp.modulate = Color(0.18, 0.62, 0.32)
		lbl_catch_note.text = "Ejemplar adulto apto para la venta en la Cooperativa ($%d) y Pedidos Comunitarios." % int(spec["base_price"])
		btn_release_fish.text = "Devolver al río"

	catch_modal.visible = true

func _on_keep_fish_pressed() -> void:
	catch_modal.visible = false
	var spec: Dictionary = GameState.SPECIES_CATALOG[_pending_catch_species]
	var min_cm: int = int(spec["min_cm"])
	var is_prot: bool = bool(spec["protected"])
	if is_prot:
		GameState.modify_river_health(-12.0, "Retuviste especie protegida (%s)" % String(spec["name"]))
	elif _pending_catch_cm < min_cm:
		GameState.modify_river_health(-8.0, "Retuviste juvenil bajo talla (%s)" % String(spec["name"]))

	if GameState.try_auto_add_fish(_pending_catch_species, _pending_catch_cm):
		GameState.emit_signal("notification_requested", "%s (%d cm) guardado en bodega. [Tab/I] para acomodar." % [String(spec["name"]), _pending_catch_cm], Color(0.55, 0.9, 0.7))
		if not _passive_catch_queue.is_empty():
			_pop_next_passive_catch()
		else:
			GameState.is_time_paused = false
	else:
		inventory_modal.visible = true
		hull_grid_view.start_placing_caught_fish(_pending_catch_species, _pending_catch_cm)
		lbl_inv_hint.text = "Bodega llena: Click Izq sobre un pez para intercambiar, [R] rotar o Tirar por la borda."

func _on_release_fish_pressed() -> void:
	catch_modal.visible = false
	var spec: Dictionary = GameState.SPECIES_CATALOG[_pending_catch_species]
	var min_cm: int = int(spec["min_cm"])
	var is_prot: bool = bool(spec["protected"])
	if is_prot:
		var tag_bonus: int = GameState.calculate_scientific_tag_bonus(_pending_catch_species, _pending_catch_cm)
		GameState.tagged_fish_count += 1
		GameState.add_money(tag_bonus)
		GameState.modify_river_health(4.0, "🏷 ¡Marcado Científico de %s (%d cm)! +$%d" % [String(spec["name"]), _pending_catch_cm, tag_bonus])
	elif _pending_catch_cm < min_cm:
		GameState.modify_river_health(3.0, "Devolviste juvenil de %s al cauce" % String(spec["name"]))
	else:
		GameState.emit_signal("notification_requested", "Devolviste el ejemplar al río.", Color(0.55, 0.85, 0.95))

	if not _passive_catch_queue.is_empty():
		_pop_next_passive_catch()
	else:
		GameState.is_time_paused = false

func _on_pending_fish_stored(_sp_id: String, _cm: int) -> void:
	lbl_inv_hint.text = "Click Izq: Agarrar / Intercambiar  |  [R] o Click Der: Rotar 90°"
	if not _passive_catch_queue.is_empty():
		inventory_modal.visible = false
		_pop_next_passive_catch()

func _open_inventory() -> void:
	_set_viewfinder(false)
	GameState.is_time_paused = true
	inventory_modal.visible = true
	lbl_inv_hint.text = "Click Izq: Agarrar / Intercambiar  |  [R] o Click Der: Rotar 90°"
	hull_grid_view.queue_redraw()

func _close_inventory() -> void:
	hull_grid_view.flush_cursor_fish_on_close()
	inventory_modal.visible = false
	if not catch_modal.visible and not pier_modal.visible and not title_overlay.visible:
		GameState.is_time_paused = false

func _on_pier_state_changed(at_pier: bool) -> void:
	if at_pier and not GameState.is_game_over and not title_overlay.visible:
		_open_pier_modal()
	elif not at_pier and pier_modal.visible:
		_close_pier_modal()

func _open_pier_modal() -> void:
	_set_viewfinder(false)
	GameState.is_time_paused = true
	pier_modal.visible = true
	_switch_pier_tab(true)
	_refresh_pier_ui()

func _close_pier_modal() -> void:
	pier_modal.visible = false
	if not title_overlay.visible and not GameState.is_game_over:
		GameState.is_time_paused = false

func _switch_pier_tab(show_venta: bool) -> void:
	tab_venta.visible = show_venta
	tab_taller.visible = not show_venta
	_refresh_pier_ui()

func _refresh_pier_ui() -> void:
	if not is_node_ready():
		return
	var legal_count: int = 0
	var legal_value: int = 0
	var illegal_count: int = 0
	var illegal_shady_val: int = 0

	for item: Dictionary in GameState.inventory_items:
		var base_p: int = int(item["base_price"])
		if bool(item["is_legal_size"]) and not bool(item["is_protected"]):
			legal_count += 1
			legal_value += base_p
		else:
			illegal_count += 1
			illegal_shady_val += base_p * 3

	if lbl_anselmo_dialogue:
		lbl_anselmo_dialogue.text = GameState.get_don_anselmo_daily_dialogue()
	if lbl_viera_dialogue:
		lbl_viera_dialogue.text = GameState.get_negra_viera_dialogue()

	lbl_pier_cargo.text = "Bodega: %d reglamentario(s) ($%d)  |  %d en infracción/veda  |  🏷 Marcados: %d" % [
		legal_count, legal_value, illegal_count, GameState.tagged_fish_count
	]
	btn_sell_legal.text = "Vender Pesca Reglamentaria a Don Anselmo (+$%d)" % legal_value
	btn_sell_legal.disabled = (legal_count == 0)

	if lbl_orders_list:
		var lines: PackedStringArray = PackedStringArray()
		for order: Dictionary in GameState.active_orders:
			lines.append("• %s: %d %s (%d/%d) — Premio: +$%d, +%d%% Salud" % [
				String(order["title"]),
				int(order["required"]),
				String(order["species_label"]),
				int(order["progress"]),
				int(order["required"]),
				int(order["reward_money"]),
				roundi(float(order["reward_health"]))
			])
		lbl_orders_list.text = "\n".join(lines)

	shady_box.visible = (illegal_count > 0)
	if illegal_count > 0:
		lbl_shady_offer.text = "El \"Turco\" (Acopiador Clandestino): \"Arrimate callado... Te pago triple ($%d) en efectivo por esos %d pescados en veda o bajo medida para el frigorífico.\" (-15%% Salud del Río)" % [
			illegal_shady_val, illegal_count
		]
		btn_sell_shady.text = "Vender a El \"Turco\" (+$%d / -15%% Río)" % illegal_shady_val

	var hull_missing: int = roundi(GameState.max_hull_hp - GameState.hull_hp)
	var repair_cost: int = maxi(15, roundi(float(hull_missing) * 1.2))
	btn_repair_hull.visible = (hull_missing > 2)
	btn_repair_hull.text = "Calafatear y Reparar Casco (-$%d)" % repair_cost
	btn_repair_hull.disabled = (GameState.money < repair_cost)

	if GameState.current_phase == GameState.TimePhase.DAY:
		btn_pier_close.text = "Zarpar a pescar (Día %d)" % GameState.current_day
		btn_pier_night.text = "Salir de Patrulla Nocturna 🌙"
		btn_pier_night.visible = true
	elif GameState.current_phase == GameState.TimePhase.SUNSET:
		btn_pier_close.text = "Seguir en el Río (Atardecer)"
		btn_pier_night.text = "Salir de Patrulla Nocturna 🌙"
		btn_pier_night.visible = true
	else:
		btn_pier_close.text = "Zarpar a pescar (Día %d)" % GameState.current_day
		btn_pier_night.visible = false

	_refresh_upgrade_buttons()

func _on_sell_legal_pressed() -> void:
	var earned: int = 0
	var to_remove: Array[int] = []
	var sold_by_species: Dictionary = {}
	for item: Dictionary in GameState.inventory_items:
		if bool(item["is_legal_size"]) and not bool(item["is_protected"]):
			earned += int(item["base_price"])
			to_remove.append(int(item["uid"]))
			var sp_id: String = String(item["species_id"])
			sold_by_species[sp_id] = int(sold_by_species.get(sp_id, 0)) + 1
	for uid: int in to_remove:
		GameState.remove_item(uid)
	if earned > 0:
		GameState.add_money(earned)
		GameState.modify_river_health(2.0, "Venta responsable en la Cooperativa (+$" + str(earned) + ")")
		for sp_key: String in sold_by_species.keys():
			GameState.record_sold_legal_fish(sp_key, int(sold_by_species[sp_key]))
	_refresh_pier_ui()

func _on_sell_shady_pressed() -> void:
	var earned: int = 0
	var to_remove: Array[int] = []
	for item: Dictionary in GameState.inventory_items:
		if not bool(item["is_legal_size"]) or bool(item["is_protected"]):
			earned += int(item["base_price"]) * 3
			to_remove.append(int(item["uid"]))
	for uid: int in to_remove:
		GameState.remove_item(uid)
	if earned > 0:
		GameState.add_money(earned)
		GameState.modify_river_health(-15.0, "Vendiste pesca en veda a El 'Turco'")
	_refresh_pier_ui()

func _on_repair_hull_pressed() -> void:
	var hull_missing: int = roundi(GameState.max_hull_hp - GameState.hull_hp)
	var repair_cost: int = maxi(15, roundi(float(hull_missing) * 1.2))
	if GameState.money >= repair_cost:
		GameState.add_money(-repair_cost)
		GameState.hull_hp = GameState.max_hull_hp
		GameState.emit_signal("stats_changed")
		GameState.emit_signal("notification_requested", "La Negra Viera calafateó el casco a nuevo.", Color(0.5, 0.95, 0.65))
		_refresh_pier_ui()

func _build_upgrade_rows() -> void:
	if not is_node_ready():
		await ready
	if upgrades_list == null:
		return
	for child: Node in upgrades_list.get_children():
		child.queue_free()
	for upg_id: String in GameState.UPGRADE_CATALOG.keys():
		var data: Dictionary = GameState.UPGRADE_CATALOG[upg_id]
		var row: HBoxContainer = HBoxContainer.new()
		row.name = "Row_" + upg_id
		row.add_theme_constant_override("separation", 12)

		var info_v: VBoxContainer = VBoxContainer.new()
		info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title_lbl: Label = Label.new()
		title_lbl.text = "%s ($%d)" % [String(data["name"]), int(data["cost"])]
		title_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
		var desc_lbl: Label = Label.new()
		desc_lbl.text = String(data["desc"])
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		info_v.add_child(title_lbl)
		info_v.add_child(desc_lbl)

		var buy_btn: Button = Button.new()
		buy_btn.name = "Btn_" + upg_id
		buy_btn.custom_minimum_size = Vector2(145, 38)
		buy_btn.pressed.connect(_on_buy_upgrade.bind(upg_id))

		row.add_child(info_v)
		row.add_child(buy_btn)
		upgrades_list.add_child(row)

func _refresh_upgrade_buttons() -> void:
	if upgrades_list == null:
		return
	for upg_id: String in GameState.UPGRADE_CATALOG.keys():
		var data: Dictionary = GameState.UPGRADE_CATALOG[upg_id]
		var cost: int = int(data["cost"])
		var owned: bool = bool(GameState.upgrades.get(upg_id, false))
		var btn: Button = upgrades_list.find_child("Btn_" + upg_id, true, false) as Button
		if btn:
			if owned:
				btn.text = "✓ Instalado"
				btn.disabled = true
			else:
				btn.text = "Comprar ($%d)" % cost
				btn.disabled = (GameState.money < cost)

func _on_buy_upgrade(upg_id: String) -> void:
	var data: Dictionary = GameState.UPGRADE_CATALOG[upg_id]
	var cost: int = int(data["cost"])
	if bool(GameState.upgrades.get(upg_id, false)) or GameState.money < cost:
		return
	GameState.upgrades[upg_id] = true
	GameState.add_money(-cost)
	GameState.emit_signal("notification_requested", "¡La Negra Viera instaló: %s!" % String(data["name"]), Color(0.45, 0.95, 0.65))
	_refresh_pier_ui()

func _on_pier_night_pressed() -> void:
	_close_pier_modal()
	GameState.depart_into_night()
	GameState.emit_signal("notification_requested", "Zarpaste de patrulla nocturna. Cortá tramayos [E] y fotografiá barcazas [F].", Color(0.55, 0.82, 1.0))

func _on_start_game_pressed() -> void:
	title_overlay.visible = false
	GameState.is_time_paused = false
	GameState.emit_signal("notification_requested", "Día 1 en el Paraná: Charlalo a Don Anselmo en el muelle o salí a pescar.", Color(0.95, 0.88, 0.55))

func _on_game_ended(_ending_id: String, title: String, desc: String) -> void:
	_set_viewfinder(false)
	catch_modal.visible = false
	inventory_modal.visible = false
	pier_modal.visible = false
	neighbor_modal.visible = false
	GameState.is_time_paused = true
	lbl_ending_title.text = title
	lbl_ending_desc.text = desc
	lbl_ending_stats.text = "Salud del Río: %d%%   |   Pruebas: %d / %d   |   Marcados: %d   |   Fondos: $%d" % [
		roundi(GameState.river_health), GameState.photo_count, GameState.REQUIRED_PHOTOS, GameState.tagged_fish_count, GameState.money
	]
	ending_modal.visible = true

func _on_restart_game_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.reset_game()
	get_tree().reload_current_scene()

func _refresh_top_bar() -> void:
	if not is_node_ready():
		return
	var phase_str: String = "Día"
	if GameState.current_phase == GameState.TimePhase.SUNSET:
		phase_str = "Atardecer"
	elif GameState.current_phase == GameState.TimePhase.NIGHT:
		phase_str = "Noche"
	lbl_day_phase.text = "Día %d / 7 — %s" % [GameState.current_day, phase_str]
	bar_river_health.value = GameState.river_health
	lbl_river_pct.text = "Salud del Río: %d%%" % roundi(GameState.river_health)
	lbl_hull.text = "Casco: %d%%" % roundi(GameState.hull_hp)
	lbl_money.text = "$ %d" % GameState.money
	if GameState.night_photos_pending > 0:
		lbl_photos.text = "📷 %d/%d (+%d)" % [GameState.photo_count, GameState.REQUIRED_PHOTOS, GameState.night_photos_pending]
	else:
		lbl_photos.text = "📷 Pruebas: %d/%d" % [GameState.photo_count, GameState.REQUIRED_PHOTOS]

func _on_phase_changed(_new_phase: GameState.TimePhase, _day: int) -> void:
	_refresh_top_bar()
	if pier_modal.visible:
		_refresh_pier_ui()

func _on_time_updated(_prog: float, phase: GameState.TimePhase, time_left: float) -> void:
	if not is_node_ready():
		return
	var phase_str: String = "Día (%ds)" % ceili(time_left)
	if phase == GameState.TimePhase.SUNSET:
		phase_str = "Atardecer (%ds)" % ceili(time_left)
	elif phase == GameState.TimePhase.NIGHT:
		phase_str = "Noche Cerrada"
	lbl_day_phase.text = "Día %d / 7 — %s" % [GameState.current_day, phase_str]

func _update_stealth_badge() -> void:
	if GameState.is_hidden_in_reeds and not GameState.is_motor_mode:
		lbl_stealth_mode.text = "🌿 Oculto en Juncos"
		lbl_stealth_mode.modulate = Color(0.45, 0.95, 0.58)
	elif GameState.is_motor_mode:
		lbl_stealth_mode.text = "🔊 Motor Activo [M]"
		lbl_stealth_mode.modulate = Color(1.0, 0.55, 0.32)
	else:
		lbl_stealth_mode.text = "🚣 Remo Silencioso [M]"
		lbl_stealth_mode.modulate = Color(0.62, 0.88, 0.96)

func _show_notification(msg: String, col: Color) -> void:
	if not is_node_ready():
		return
	lbl_notification.text = msg
	lbl_notification.modulate = col
	notification_banner.visible = true
	_notif_timer = 4.2
