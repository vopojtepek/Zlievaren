extends Node

var ambient_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS: int = 16

var sfx_coin: AudioStream
var sfx_pour: AudioStream
var sfx_steam: AudioStream
var sfx_clank: AudioStream
var sfx_wash: AudioStream
var sfx_alarm: AudioStream
var amb_furnace: AudioStream

func _ready() -> void:
	ambient_player = AudioStreamPlayer.new()
	ambient_player.bus = "Ambient" if AudioServer.get_bus_index("Ambient") != -1 else "Master"
	add_child(ambient_player)
	
	for i in range(MAX_SFX_PLAYERS):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
		add_child(p)
		sfx_players.append(p)
		
	_load_assets()
	_connect_events()

func _load_assets() -> void:
	if ResourceLoader.exists("res://assets/audio/sfx/coin.wav"):
		sfx_coin = load("res://assets/audio/sfx/coin.wav")
	if ResourceLoader.exists("res://assets/audio/sfx/pour.wav"):
		sfx_pour = load("res://assets/audio/sfx/pour.wav")
	if ResourceLoader.exists("res://assets/audio/sfx/steam.wav"):
		sfx_steam = load("res://assets/audio/sfx/steam.wav")
	if ResourceLoader.exists("res://assets/audio/sfx/clank.wav"):
		sfx_clank = load("res://assets/audio/sfx/clank.wav")
	if ResourceLoader.exists("res://assets/audio/sfx/wash.wav"):
		sfx_wash = load("res://assets/audio/sfx/wash.wav")
	if ResourceLoader.exists("res://assets/audio/sfx/alarm.wav"):
		sfx_alarm = load("res://assets/audio/sfx/alarm.wav")
	if ResourceLoader.exists("res://assets/audio/ambient/furnace_hum.wav"):
		amb_furnace = load("res://assets/audio/ambient/furnace_hum.wav")
		play_ambient(amb_furnace)

func _connect_events() -> void:
	EventBus.money_changed.connect(func(_new_balance: int, _delta: int):
		play_sfx(sfx_coin, randf_range(0.95, 1.05))
	)
	EventBus.trade_executed.connect(func(_item: String, _side: String, _q: int, _price: int):
		play_sfx(sfx_coin, randf_range(0.98, 1.04))
	)
	EventBus.contract_fulfilled.connect(func(_cid: String, _reward: int):
		play_sfx(sfx_coin, 1.15, 2.0)
	)
	EventBus.wages_paid.connect(func(_paid: int, _debt: int):
		play_sfx(sfx_coin, 0.9)
	)
	EventBus.batch_finished.connect(func(_slot: int, _product: String):
		play_sfx(sfx_steam, randf_range(0.95, 1.05))
	)
	EventBus.reject_occurred.connect(func(_slot: int, _product: String):
		play_sfx(sfx_alarm, 1.0, 2.0)
	)
	EventBus.material_unloaded_to_pallet.connect(func(_slot: int, _product: String):
		play_sfx(sfx_clank, randf_range(0.95, 1.05))
	)
	EventBus.washer_cycle_started.connect(func(_product: String):
		play_sfx(sfx_wash, 1.0)
	)
	EventBus.washer_cycle_finished.connect(func(_product: String):
		play_sfx(sfx_clank, 1.1)
	)

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch_scale
			p.volume_db = volume_db
			p.play()
			return
	var p0 = sfx_players[0]
	p0.stream = stream
	p0.pitch_scale = pitch_scale
	p0.volume_db = volume_db
	p0.play()

func play_ambient(stream: AudioStream) -> void:
	if stream == null:
		return
	if ambient_player.stream != stream:
		ambient_player.stream = stream
		ambient_player.volume_db = -10.0
		ambient_player.play()
