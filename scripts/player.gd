extends Area2D

signal hit
signal bullet_shot

@export var speed = 300 # How fast the player will move (pixels/sec)
var screen_size # Size of the game window.

var target_position: Vector2
var is_moving: bool = false

func _ready():
	screen_size = get_viewport_rect().size
	target_position = position
	

func _input(event: InputEvent) -> void:
	# 检测鼠标右键点击
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			target_position = get_global_mouse_position()
			is_moving = true

func _physics_process(delta: float) -> void:
	var velocity = Vector2.ZERO # The player's movement vector.
	
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x-= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y-= 1
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		position += velocity * delta
	elif is_moving:
		var mouse_direction = (target_position - position).normalized()
		var mouse_velocity = mouse_direction * speed
		position += mouse_velocity * delta
		
		# 检查是否到达目标
		if position.distance_to(target_position) < 10.0:
			is_moving = false
	#限制屏幕以内
	position = position.clamp(Vector2.ZERO, screen_size)


func _on_body_entered(body: Node2D) -> void:
	hide()
	hit.emit()
	$CollisionPolygon2D.set_deferred("disabled", true) # must be deferred due to a physics engine restriction

func reset() -> void:
	show()
	$CollisionPolygon2D.disabled = false
	rotation = 0

func _process(delta: float) -> void:
	if Input.is_action_pressed("shoot"):
		bullet_shot.emit()
