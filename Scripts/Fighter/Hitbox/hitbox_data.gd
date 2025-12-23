class_name HitboxData

extends Resource

enum range_type {LOW, MID, HIGH}

@export var damage: int
@export var damage_range: range_type
@export var x_knockback: float
@export var y_knockback: float
@export var x_knockback_on_block: float
@export var y_knockback_on_block: float
@export var x_knockback_is_relative: bool
@export var x_knockback_is_additive: bool
@export var y_knockback_is_additive: bool
@export var knockback_power: int
@export var knockdown_power: float

@export var hitstun_duration_frames: int
@export var hitstun_duration_frames_on_block: int
@export var self_hitstun_duration_frames: int
@export var self_hitstun_duration_frames_on_block: int
@export var force_hurt_duration_frames: int
@export var force_hurt_duration_frames_on_block: int

@export var impact_fx: String
