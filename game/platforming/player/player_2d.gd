extends CharacterBody2D
class_name PlayerController

enum state {IDLE, WALKING, RUNNING, JUMPING, WALL_JUMP, DASHING, LANDING, WALL_SLIDING, CLIMBING, INTERACTING, BLOCKED}
enum inputs{JUMP, DASH, NONE}

signal interacted
signal break_interaction

@export var slow_time : bool = false
@export_group("Player Movement")
##how long an action remains queued before it gets deleted
##for example, when a player jumps before reaching the ground
@export var queue_time : float = 0.15
@export var queue_time_for_attacks : float = 1.0
@export var landing_time : float = .15
@export_subgroup("running")
##player max speed
@export var speed : float = 20.0
@export_subgroup("jump")
@export var invisibility_delay : float = 0.1
@export var jump_velocity : float = -300.0
@export var jump_floatiness : float = 0.15
##how big is gravity
@export var going_down_speed : float = 1.0
@export_subgroup("wall jump")
##the velocity in x repulsing the player from the wall
@export var wall_jump_repulsion : float = 12.5
@export var wall_jump_time : float = 0.375
@export var wall_slide_break_time : float = .1
##when the player is pressing against a wall, how much it stops falling
@export var wall_slide_gravity : float = 0.75
@export var dash_velocity : float = 30.0
@export var dash_duration : float = 0.25
@export var coyote_time : float = 0.25

@export_group("Nodes")
@export var move : GUIDEAction
@export var jump_action : GUIDEAction
@export var dash_action : GUIDEAction
@export var climb_action : GUIDEAction

@onready var checkpoint_box : Area2D = $CheckpointBox
@onready var wall_jump_right: ShapeCast2D = $WallDetectorRight
@onready var wall_jump_left: ShapeCast2D = $WallDetectorLeft
@onready var hurtbox : Area2D = $HurtBox
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
 
"""state machine"""
var current_state : state = state.IDLE:
	set(value):
		if current_state == state.INTERACTING:
			break_interaction.emit()
		current_state = value

var last_interaction : float = -1.0

var checkpoint : Vector2

var current_dash_velocity : float = 0.0
var direction_x : float = 0.0
var looking : int = 1
var jumping_time : float = 0.0
var dash_spent : bool = false
var input_queued : inputs = inputs.NONE
var airborne : bool = false
var current_gravity_force : float = 1.0
var dash_position : Vector2
  
@onready var coyote_timer: Timer = create_timer()
@onready var invisibility_timer: Timer = create_timer()
@onready var dash_reset_timer: Timer = create_timer()
@onready var queue_timer: Timer = create_timer()
@onready var landing_timer: Timer = create_timer()
@onready var down_timer : Timer = create_timer(0.2)
@onready var wall_jump_timer : Timer = create_timer(wall_jump_time)
@onready var wall_slide_timer : Timer = create_timer(wall_slide_break_time)


func create_timer(wait_time: float = 1.0, one_shot: bool = true) -> Timer:
	var timer : Timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = one_shot
	add_child(timer)
	return timer

 
func _ready() -> void: 
	jump_action.triggered.connect(queue_jump)
	dash_action.triggered.connect(queue_dash)
	checkpoint = global_position
	checkpoint_box.area_entered.connect(store_checkpoint)
	hurtbox.area_entered.connect(take_damage_and_respawn)


func queue_dash() -> void:
	input_queued = inputs.DASH
	queue_timer.start(queue_time)

func queue_jump() -> void:
	input_queued = inputs.JUMP
	queue_timer.start(queue_time)

func manage_inputs(delta : float, move_direction : Vector2) -> void:
	match input_queued:
		inputs.NONE:
			pass
		inputs.JUMP:
			jump()
		inputs.DASH:
			if dash_reset_timer.is_stopped() and !dash_spent:
				dash(move_direction)

func store_checkpoint(body : Node2D = null, _position : Vector2 = Vector2.ZERO) -> void:
	if body != null:
		checkpoint = body.global_position
	if _position != Vector2.ZERO:
		checkpoint = _position
	print_debug("current checkpoint", checkpoint)

func _physics_process(delta: float) -> void:
	if slow_time:
		Engine.time_scale = 0.25
	if queue_timer.is_stopped():
		input_queued = inputs.NONE
 
	handle_gravity(delta)
	state_machine(delta)
	move_and_slide()

func handle_gravity(delta: float) -> void:
	if invisibility_timer.is_stopped():
		animated_sprite_2d.hide()
	else:
		animated_sprite_2d.show()
	current_gravity_force = 1.0
	match current_state:
		state.WALL_SLIDING:
			if velocity.y <= 0.0:
				current_gravity_force = wall_slide_gravity
		state.CLIMBING:
			current_gravity_force = 0.0
			velocity.y = 0.0

	if is_on_floor():
		invisibility_timer.start(invisibility_delay)
		dash_spent = false
		coyote_timer.start(coyote_time)
		if airborne:
			landing_timer.start(landing_time)
			velocity.x *= 0.9
			current_state = state.LANDING

		airborne = false
	else:
		airborne = true
		velocity += get_gravity() * going_down_speed * delta * current_gravity_force
	if jumping_time < jump_floatiness:
		jumping_time += delta
		if jump_action.value_bool:
			velocity.y = jump_velocity

func handle_lateral_movement(delta : float, _direction : float) -> void:
	if abs(velocity.x) > speed * 1.1:
		if _direction * velocity.x > 0:
			velocity.x = move_toward(velocity.x, velocity.x * _direction * speed, delta)
			return
		
	velocity.x = _direction * speed
	if _direction > 0:
		animated_sprite_2d.flip_h = false
		looking = 1
	elif _direction < 0:
		animated_sprite_2d.flip_h = true
		looking = -1
	direction_x = looking

func jump() -> void:
	if !coyote_timer.is_stopped() or current_state == state.WALL_SLIDING or current_state == state.CLIMBING:
		input_queued = inputs.NONE
	else:
		return

	coyote_timer.stop()

	if current_state == state.WALL_SLIDING or current_state == state.CLIMBING:
		do_wall_jump()
		return
	
	current_state = state.JUMPING
	jumping_time = 0.0
	velocity.y = jump_velocity
	#velocity += get_platform_velocity()/4.0	

func do_wall_jump() -> void:
	invisibility_timer.start(invisibility_delay)
	velocity.y = jump_velocity * 1.25
	current_state = state.WALL_JUMP
	var _sign : int = 1
	#if wall_jump_right.is_colliding()
	if !animated_sprite_2d.flip_h:
		_sign = -1
	animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
	looking = _sign
	direction_x = _sign
	wall_jump_timer.start(wall_jump_time)

func dash(direction : Vector2) -> void:
	print_debug("dashing")
	current_dash_velocity = dash_velocity
	if direction == Vector2.ZERO:
		dash_position = Vector2(looking, 0)
	else:
		dash_position = direction.normalized()
	dash_spent = true
	velocity = direction.normalized() * dash_velocity
	current_state = state.DASHING
	dash_reset_timer.start(dash_duration)

func state_machine(delta: float) -> void:
	var move_direction : Vector2 = move.value_axis_2d

	var aiming_for_wall : bool = false

	manage_inputs(delta, move_direction)

	match current_state:
		state.IDLE:
			if is_on_floor():
				animated_sprite_2d.play("idle")
			else:
				animated_sprite_2d.play("air")
			if move_direction.x != 0.0:
				current_state = state.WALKING
				velocity.x = speed * move_direction.x

		state.CLIMBING:
			velocity.y = 0.0
			coyote_timer.start(coyote_time)
			invisibility_timer.start(invisibility_delay)
			if is_on_floor():
				current_state = state.WALKING

		state.WALL_SLIDING:
			if !wall_jump_left.is_colliding() and !wall_jump_right.is_colliding():
				current_state = state.WALKING
			else:
				if move_direction.x * looking > 0.0:
					wall_slide_timer.start(wall_slide_break_time)
			if wall_slide_timer.is_stopped():
				current_state = state.WALKING
			if climb_action.value_bool:
				current_state = state.CLIMBING

		state.WALKING:
			handle_lateral_movement(delta, move_direction.x)
			if move_direction.x == 0.0:
				current_state = state.IDLE
				velocity.x = 0.0
			if is_on_floor():
				animated_sprite_2d.play("walk")
			else:
				animated_sprite_2d.play("air")

		state.DASHING:
			velocity = dash_position * current_dash_velocity
			current_dash_velocity = move_toward(current_dash_velocity, 0, delta * 20.0)
			if is_on_floor():
				pass
			else:
				animated_sprite_2d.play("air")
			if dash_reset_timer.is_stopped():
				current_state = state.WALKING
			return
		
		state.INTERACTING:
			return
		
		state.BLOCKED:
			return

		state.WALL_JUMP:
			animated_sprite_2d.play("wall_jump")
			velocity.x = wall_jump_repulsion * looking
			if wall_jump_timer.is_stopped():
				current_state = state.WALKING
				velocity.x *= .75
			if looking < 0:
				if wall_jump_left.is_colliding() and !is_on_floor():
					current_state = state.WALL_SLIDING
			if looking > 0:
				if wall_jump_right.is_colliding() and !is_on_floor():
					current_state = state.WALL_SLIDING
			return

		state.JUMPING:
			handle_lateral_movement(delta, move_direction.x)
			animated_sprite_2d.play("jump")
			if jumping_time > jump_floatiness:
				current_state = state.WALKING

		state.LANDING:
			handle_lateral_movement(delta, move_direction.x)
			animated_sprite_2d.play("land")
			if landing_timer.is_stopped():
				current_state = state.WALKING

	if current_state == state.WALL_JUMP:
		return

	if (wall_jump_right.is_colliding() or wall_jump_left.is_colliding()) and !is_on_floor():
		aiming_for_wall = (direction_x * looking) > 0
		if aiming_for_wall and current_state != state.CLIMBING:
			if current_state != state.WALL_SLIDING:
				if velocity.y < 0:
					velocity.y/= 2
			current_state = state.WALL_SLIDING

func change_state(new_state : state) -> void: 
	current_state = new_state

func take_damage_and_respawn(_body : Node2D) -> void:
	await Ui.fade_to_black(0.25)
	current_state = state.BLOCKED
	velocity = Vector2.ZERO
	global_position = checkpoint
	await Ui.fade_to_clear(0.25)
	current_state = state.IDLE
