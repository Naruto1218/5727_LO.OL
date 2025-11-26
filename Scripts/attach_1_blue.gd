extends Area2D

@export var offset_min: Vector2 = Vector2(-120, -80)   # 相对玩家的随机范围
@export var offset_max: Vector2 = Vector2(120,  80)
@export var anim_name: StringName = "default"           # 动画名字
@export var damage: int = 1                            # 造成多少伤害
@export var safe_frames: int = 5    
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
				   # 前多少帧不造成伤害

var can_damage: bool = false                           # 是否已经可以伤害角色
func _ready() -> void:
# 连接碰撞信号
	body_entered.connect(_on_body_entered)

func start(player: Node2D) -> void:
	# 1. 根据“出现规则”确定位置（这里是：玩家附近一个随机矩形区域）
	var base_pos: Vector2 = player.global_position
	var dx: float = randf_range(offset_min.x, offset_max.x)
	var dy: float = randf_range(offset_min.y, offset_max.y)
	global_position = base_pos + Vector2(dx, dy)

	# 2. 设置形状 / 大小（比如根据玩家距离、随机大小等）
	#    这里简单示例：放大一点：
	scale = Vector2(2, 2)  # 你可以改成根据规则计算

	# 3. 播放动画并在播放完后自动删除
	if anim:
		can_damage = false               # 每次出现先重置为无伤害
		anim.play(anim_name)
		anim.frame_changed.connect(_on_frame_changed)
		_auto_free()
	else:
		queue_free()   # 防止没配置好也不崩


func _auto_free() -> void:
	await anim.animation_finished   # Godot 4.5 写法
	queue_free()
func _on_frame_changed() -> void:
	# frame 从 0 开始：0,1,2,3,4 是前 5 帧，不伤害
	if anim.frame >= safe_frames:
		can_damage = true	
func _on_body_entered(body: Node2D) -> void:
	# 如果还在“无伤害前摇”阶段，直接返回
	if not can_damage:
		return

	# 建议玩家节点在 _ready() 里加 add_to_group("player")
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		# 如果这次攻击只打一次就消失，可以在这里删掉自己
		# queue_free()
