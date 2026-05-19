extends Node

# Globally accessible flower data (registered as autoload "FlowerDB").
# Add more flower types by extending the arrays.

enum Type {RED, YELLOW, BLUE}
const TYPE_COUNT := 3

const TYPE_NAMES := ["Red", "Yellow", "Blue"]
const TYPE_COLORS := [
	Color(0.92, 0.20, 0.30),
	Color(0.96, 0.85, 0.20),
	Color(0.30, 0.50, 0.95),
]

# ── Base flower characteristics ────────────────────────────────────────
# Pot capacities in liters.
const RED_POT_CAPACITY := 2.5
const YELLOW_POT_CAPACITY := 1.5
const BLUE_POT_CAPACITY := 3.5

# Watering requirements as percentage of pot capacity.
const RED_WATERING_PCT := 1.5 # 175%
const YELLOW_WATERING_PCT := 2.0 # 200%
const BLUE_WATERING_PCT := 1.5 # 150%

# Time to bloom (in seconds) when continuously watered.
const RED_GROW_TIME := 10.0
const YELLOW_GROW_TIME := 13.0
const BLUE_GROW_TIME := 16.0

# ── Derived arrays (used by gameplay) ──────────────────────────────────
const WATER_CAPACITY := [RED_POT_CAPACITY, YELLOW_POT_CAPACITY, BLUE_POT_CAPACITY]
const WATER_REQUIREMENT := [RED_POT_CAPACITY * RED_WATERING_PCT, YELLOW_POT_CAPACITY * YELLOW_WATERING_PCT, BLUE_POT_CAPACITY * BLUE_WATERING_PCT]
# Drain rate = required liters / grow time (so growth speed matches drain speed)
const WATER_DRAIN := [WATER_REQUIREMENT[0] / RED_GROW_TIME, WATER_REQUIREMENT[1] / YELLOW_GROW_TIME, WATER_REQUIREMENT[2] / BLUE_GROW_TIME]

# Seconds at 0 L water before plant dies.
const DRY_TIME := [15, 10, 13]
# Seconds bloomed flower lasts in pot before wilting.
const BLOSSOM_DECAY := [20, 17, 15]
# Sale price contributed per flower in a bouquet.
const PRICE := [3, 4, 6]
