extends Node

# Globally accessible flower data (registered as autoload "FlowerDB").
# Add more flower types by extending the arrays.

enum Type { RED, YELLOW, BLUE }
const TYPE_COUNT := 3

const TYPE_NAMES := ["Red", "Yellow", "Blue"]
const TYPE_COLORS := [
	Color(0.92, 0.20, 0.30),
	Color(0.96, 0.85, 0.20),
	Color(0.30, 0.50, 0.95),
]
# Seconds from planting (with continuous water) to bloom
const GROW_TIME := [13.0, 12.0, 14.0]
# Water level decreases at this many %/sec while growing
const WATER_DRAIN := [5.0, 4.0, 6.0]
# Seconds at 0% water before plant dies
const DRY_TIME := [20.0, 25.0, 17.0]
# Seconds bloomed flower lasts in pot before wilting
const BLOSSOM_DECAY := [25.0, 22.0, 20.0]
# Sale price contributed per flower in a bouquet
const PRICE := [4, 3, 5]
