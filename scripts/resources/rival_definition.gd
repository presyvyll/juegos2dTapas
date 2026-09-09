class_name RivalDefinition
extends Resource
@export var id := ""
@export var display_name := ""
@export var favorite_cap: CapDefinition
@export var profile: AIProfile
@export_multiline var personality := ""
@export var favorite_powerups: PackedStringArray = ["recharge"]
@export_range(0, 10) var rivalry_level: int = 0
@export var intro_line := ""
@export var victory_line := ""
@export var champion_cup_id := ""
@export var intro_audio: AudioStream
@export var victory_audio: AudioStream
