class_name ChampionshipDefinition
extends Resource
## Cup configuration; CupProgress and SaveManager own standings and rewards.
## Typed string arrays are verified through the Android binary resource export.
@export var id := ""
@export var display_name := ""
@export var track_ids: Array[String] = []
@export_range(1, 3) var laps: int = 1
@export var rival_ids: Array[String] = []
@export var rival_names: Array[String] = []
## Temporary six-cap roster until the arcade roster migration is implemented.
@export var legacy_rival_cap_ids: Array[String] = []
@export_enum("easy", "normal", "hard") var difficulty := "normal"
@export var champion_id := ""
@export var champion_line := ""
@export var champion_accent := Color("69e7d4")
@export var prerequisite_cup_id := ""
@export var position_points: PackedInt32Array = [10, 7, 4, 2]
@export var podium_cap_ids: PackedStringArray = []
@export var champion_cap_id := ""
@export var cosmetic_reward_id := ""
@export var coin_reward: int = 0
@export var xp_reward: int = 0
@export var intro_audio: AudioStream
@export var race_audio: AudioStream
@export var complete_audio: AudioStream
