class_name ChampionshipDefinition
extends Resource
## Definition only. Runtime standings and rewards belong in a persistent session.
@export var id := ""
@export var display_name := ""
@export var track_ids: PackedStringArray = []
@export_range(1, 3) var laps: int = 1
@export var rival_ids: PackedStringArray = []
@export var champion_id := ""
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
