class_name Hitbox
extends Area3D

enum HitboxFlags {
	BLOCK_HIGH = 1,
	BLOCK_LOW = 2,
	HIT_GRAB = 4,
	CONNECT_GRAB = 8,
	END_GRAB = 16,
	BREAK_GRAB = 32,
	UNBLOCK_INESCAP = 64,
	HIT_GROUND = 128,
	HIT_AIR = 256,
	HIT_OTG = 512,
	SUPER = 1024,
	NO_KO = 2048,
	IGNORE_EDGE = 4096,
	NO_COMBO_COUNT = 8192,
	NO_SCALING_CHANGE = 16384,
}
enum StateEffects {
	NONE = 0,
	KNOCKDOWN = 1,
	LAUNCHER = 2,
	COLLAPSE = 3,
	BOUNCE = 4,
}

@export_category("Damage")
@export var damage_hit : float
@export var damage_block : float
@export_category("Stun")
@export var stun_hit : int
@export var stun_block : int
@export var hitstop_hit : int
@export var hitstop_block : int
@export_category("Knockback")
@export var kback_hit : Vector3
@export var kback_block : Vector3
@export_category("Audio")
@export var on_hit_sound : AudioStream
@export var on_block_sound : AudioStream
@export_category("Misc")
@export var lifetime : int
@export var is_projectile : bool
@export var hit_priority : int
@export_flags(
	"Block High:1", "Block Low:2", "Block Any:3",
	"Hit Grab:4", "Connect Grab:8", "Ends Grab:16", "Breaks Grab:32",
	"Unblockable/Inescapable:64",
	"Hits Grounded:128", "Hits Airborne:256", "G+A:384", "Hits OTG:512", "Always Hits:896",
	"Super Attack:1024", "Cannot KO:2048", "Ignore Stage Edge:4096", "Don't Increment Combo Counter:8192",
	"Don't Affect Scaling:16384"
	) var hitbox_flags : int = 0
@export_enum("None", "Knockdown", "Launcher", "Collapse", "Camera/Wall Bounce") var state_effect : int
@export var on_hit : Array
@export var on_block : Array

var invalid := false
var paused := false

func _physics_process(_d):
	if paused:
		return
	if lifetime > 0:
		lifetime -= 1
	if lifetime == 0:
		queue_free()

func _to_string() -> String:
	var hitbox_flag_str = ""
	var hitbox_flag_working = hitbox_flags
	while hitbox_flag_working > 0:
		var yoinked_flag = int(floor(log(hitbox_flag_working) / log(2)))
		var val_actual = int(pow(2, yoinked_flag))
		hitbox_flag_str += Hitbox.HitboxFlags.keys()[yoinked_flag] + " "
		hitbox_flag_working -= val_actual
	return "name: %s\ndamage: %s (chip: %s)\nstun: %s (block: %s)\nknockback: %s (blockback: %s)\nlifetime: %s\nhit priority: %s\nhitbox flags: %s\n" % [name if not is_projectile else get_parent().name, damage_hit, damage_block, stun_hit, stun_block, kback_hit, kback_block, lifetime, hit_priority, hitbox_flag_str]
