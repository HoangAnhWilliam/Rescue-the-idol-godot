extends Resource
class_name PlayerStats

# Base Stats
@export var max_hp: float = 100.0
@export var max_mana: float = 50.0
@export var lucky: float = 1.0

# Combat Stats
@export var move_speed: float = 200.0
@export var attack_speed: float = 1.0
@export var attack_damage: float = 10.0
@export var base_damage: float = 10.0  # For upgrade system
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0

# Regeneration
@export var hp_regen_per_second: float = 0.5
@export var mana_regen_per_second: float = 2.0

# Additional Stats (for upgrades)
@export var pickup_range: float = 100.0
@export var cooldown_reduction: float = 0.0  # 0.0 to 0.5 (50% max)
@export var lifesteal: float = 0.0  # 0.0 to 1.0

# Permanent Upgrades (saved)
@export var permanent_hp_upgrades: int = 0
@export var permanent_luck_upgrades: int = 0
@export var permanent_mana_threshold: int = 0
