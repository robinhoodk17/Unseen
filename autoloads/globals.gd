extends Node

# What goes into globals.gd?
# If the function depends on the something in the game, it's a global.
# If it's independent, it (probably) belongs in utils.gd

## Use UI/MessageBox to display a status update message to the player
@warning_ignore("unused_signal")
signal post_ui_message(text: String)

## Emitted by UI/Controls when a action is remapped
@warning_ignore("unused_signal")
signal controls_changed(config: GUIDERemappingConfig)
var damage_boost_duration : float = 15.0
var collectibles_speed : float = 1.5
var destructible_hp : float = 2.0
var weak_point_hp : float = 50.0
var wagon_hp : float = 80.0
const DAMAGED_MATERIAL = preload("res://game/driving/prefabs/destructible/damaged_material.tres")
