extends CharacterBody2D

@export var move_speed: float = 200.0  # 角色移动速度（像素/秒）

var target_pos: Vector2   # 要移动到的目标位置
@export var max_hp: int = 1	      # 最大血量，可在 Inspector 里调
var hp: int                           # 当前血量

func _ready() -> void:
	# 一开始先把目标点设成当前的位置
	target_pos = global_position
	hp = max_hp
	# 加入一个 "player" 组，方便子弹识别
	add_to_group("player")


# 处理鼠标点击：更新目标点
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		# 获取鼠标在世界中的坐标
		target_pos = get_global_mouse_position()


# 用物理帧来移动角色
func _physics_process(delta: float) -> void:
	var dir = target_pos - global_position

	# 如果离目标还有一段距离，就继续移动
	if dir.length() > 2.0:
		dir = dir.normalized()
		velocity = dir * move_speed
	else:
		# 基本到达目标，停下来
		velocity = Vector2.ZERO

	move_and_slide()
	
# 受伤
func take_damage(amount: int = 1) -> void:
	hp -= amount
	if hp <= 0:
		hp = 0
		#die()  # 调用死亡逻辑
	print("HP:", hp, "/", max_hp)

func die() -> void:
	print("Player Dead")
	# 这里可以加死亡动画、游戏结束逻辑等
