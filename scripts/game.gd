extends Node
@export var enemy_scenes: Array[PackedScene] = []
@onready var enemy_container = $EnemyContainer
@onready var player = $Player

@export var bullet_interval = 1
@onready var bullet_container = $BulletContainer
var bullet_scene = preload("res://scenes/bullet.tscn")
var last_bullet_time = 0

func _on_enemy_spawn_timer_timeout() -> void:
	var new_enemy = enemy_scenes.pick_random().instantiate()
	
	
	# 窗口尺寸
	var screen_width = 1960
	var screen_height = 1280
	
	# 随机选择生成边缘 (0:上, 1:右, 2:下, 3:左)
	var edge = randi() % 4
	var spawn_position = Vector2()
	
	match edge:
		0: # 上边缘
			spawn_position = Vector2(randi_range(0, screen_width), 0)
		1: # 右边缘
			spawn_position = Vector2(screen_width, randi_range(0, screen_height))
		2: # 下边缘
			spawn_position = Vector2(randi_range(0, screen_width), screen_height)
		3: # 左边缘
			spawn_position = Vector2(0, randi_range(0, screen_height))
	
	new_enemy.global_position = spawn_position
	new_enemy.move_speed = randi_range(400,600)
	new_enemy.linear_velocity = (player.position - new_enemy.position).normalized() * new_enemy.move_speed
	new_enemy.rotation = new_enemy.linear_velocity.angle() + PI / 2
	enemy_container.add_child(new_enemy)


var score = 0 # ideally, this line should be put above all functions
func _on_score_timer_timeout() -> void:
	score+=1
	$HUD.update_score(score)


func _on_player_hit() -> void:
	print("GG!")
	print("Score is ", score)
	stop_game()
	$GameOverScreen.show()


func stop_game() -> void:
	player.hide()
	$EnemySpawnTimer.stop()
	$ScoreTimer.stop()

func start_game() -> void:
	$MainMenu.hide() 
	# remove all existing enemies, if any, before a new game
	for c in enemy_container.get_children():
		c.queue_free()
	player.reset()
	player.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	score = 0
	$EnemySpawnTimer.start()
	$ScoreTimer.start()
	$HUD.show()
	$HUD.update_score(score)
	print("START!")
	
func _ready() -> void:
	stop_game() 
	$GameOverScreen.hide()
	$HUD.hide()
	
func _on_main_menu_start_game() -> void:
	start_game()


func _on_game_over_screen_retry_game() -> void:
	stop_game()
	start_game()
	$GameOverScreen.hide()
	
	


func _on_player_bullet_shot() -> void:
	var now = Time.get_unix_time_from_system()
	if now -last_bullet_time > bullet_interval:
		var new_bullet = bullet_scene.instantiate()
		new_bullet.position = player.position
		new_bullet.rotation = player.rotation
		new_bullet.hit_enemy.connect(_on_enemy_hit)
		bullet_container.add_child(new_bullet)
		#$BulletSound.play()
		last_bullet_time = now
		
func _on_enemy_hit(enemy: Enemy) -> void:
	# $ExplosionSound.play()
	enemy.queue_free()
	score = score + 3
