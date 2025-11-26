extends Area2D

# 攻击飞行速度（像素/秒）
@export var speed: float = 300.0

@export var damage: int = 1          # 这一发子弹造成多少伤害

# 动画名字
@export var anim_name: StringName = "default"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# 当前移动方向
var _dir: Vector2 = Vector2.ZERO

# 屏幕边界（世界坐标）
const BOUNDS_MIN := Vector2(-576, -324)
const BOUNDS_MAX := Vector2( 576,  324)
func _ready() -> void:
	# 连接碰撞信号（Godot 4 写法）
	body_entered.connect(_on_body_entered)
	
func start(player: Node2D) -> void:
	randomize()
	scale = Vector2(2, 2)
	# 1. 随机选择一条边：0=上，1=下，2=左，3=右
	var side := randi() % 4
	var spawn_pos: Vector2

	match side:
		0:
			# 上边 y = BOUNDS_MIN.y，x 在范围内随机
			spawn_pos = Vector2(
				randf_range(BOUNDS_MIN.x, BOUNDS_MAX.x),
				BOUNDS_MIN.y
			)
		1:
			# 下边 y = BOUNDS_MAX.y
			spawn_pos = Vector2(
				randf_range(BOUNDS_MIN.x, BOUNDS_MAX.x),
				BOUNDS_MAX.y
			)
		2:
			# 左边 x = BOUNDS_MIN.x
			spawn_pos = Vector2(
				BOUNDS_MIN.x,
				randf_range(BOUNDS_MIN.y, BOUNDS_MAX.y)
			)
		3:
			# 右边 x = BOUNDS_MAX.x
			spawn_pos = Vector2(
				BOUNDS_MAX.x,
				randf_range(BOUNDS_MIN.y, BOUNDS_MAX.y)
			)

	# 设置生成位置
	global_position = spawn_pos

	# 2. 计算飞向玩家的单位方向
	_dir = (player.global_position - global_position).normalized()

	# 3. 播放动画（可循环）
	if anim:
		anim.play(anim_name)


func _physics_process(delta: float) -> void:
	# 4. 每帧沿着 _dir 直线移动
	if _dir != Vector2.ZERO:
		rotation = _dir.angle()
		global_position += _dir * speed * delta

	# 5. 一旦飞出屏幕边界（加一点缓冲），就删除自己
	var margin := 50.0
	if global_position.x < BOUNDS_MIN.x - margin \
		or global_position.x > BOUNDS_MAX.x + margin \
		or global_position.y < BOUNDS_MIN.y - margin \
		or global_position.y > BOUNDS_MAX.y + margin:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# 建议：玩家加到 "player" 组里
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()   # 撞到玩家就消失
