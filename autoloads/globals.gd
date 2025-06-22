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
var collectibles_speed : float = 1.0
var destructible_hp : float = 3.0
var weak_point_hp : float = 25.0
var wagon_hp : float = 30.0
const DAMAGED_MATERIAL = preload("res://game/driving/prefabs/destructible/damaged_material.tres")
var camera_shake : bool = true
