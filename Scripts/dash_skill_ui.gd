extends TextureRect

@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var cooldown_text: Label = $CooldownText

var player: Node = null
var is_cooldown: bool = false
var cooldown_timer: float = 0.0
var total_cooldown: float = 0.0

func _ready() -> void:
	# 初始状态
	cooldown_overlay.visible = false
	cooldown_text.text = ""
	modulate = Color(1, 1, 1, 1)  # 正常颜色
	
	# 调试信息
	print("UI节点路径：", get_path())
	
	# 延迟一帧再查找玩家，确保场景树完全加载
	await get_tree().process_frame
	# 尝试自动获取玩家引用
	_find_player()

# 修改 _find_player() 函数：
func _find_player():
	print("开始查找玩家节点...")
	
	# 方法1：通过节点路径查找
	var root = get_tree().root
	player = root.get_node_or_null("Dodge/player")  # 根据你的场景结构调整
	
	if not player:
		# 方法2：通过组查找
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			print("通过组找到玩家：", player.name)
	
	if not player:
		# 方法3：通过类型查找
		for node in get_tree().get_nodes_in_group("player"):
			if node.has_method("take_damage"):
				player = node
				print("通过方法找到玩家：", player.name)
				break
	
	if player:
		_connect_to_player()
	else:
		print("错误：未找到玩家节点！")
		

func _connect_to_player():
	if player == null:
		return
	
	# 连接玩家信号
	if player.has_signal("dash_cooldown_started"):
		player.dash_cooldown_started.connect(_on_cooldown_started)
		print("已连接 dash_cooldown_started 信号")
	
	if player.has_signal("dash_cooldown_updated"):
		player.dash_cooldown_updated.connect(_on_cooldown_updated)
		print("已连接 dash_cooldown_updated 信号")
	
	if player.has_signal("dash_cooldown_finished"):
		player.dash_cooldown_finished.connect(_on_cooldown_finished)
		print("已连接 dash_cooldown_finished 信号")

func _on_cooldown_started(total_time: float):
	is_cooldown = true
	total_cooldown = total_time
	cooldown_timer = total_time
	
	# 显示冷却效果
	cooldown_overlay.visible = true
	modulate = Color(0.5, 0.5, 0.5, 0.8)  # 变暗
	
	print("冷却开始：", total_time, "秒")

func _on_cooldown_updated(remaining: float, total: float):
	if not is_cooldown:
		return
	
	cooldown_timer = remaining
	
	# 更新冷却覆盖层（从下往上减少）
	var ratio = remaining / total
	var current_height = size.y * ratio
	cooldown_overlay.size.y = current_height
	cooldown_overlay.position.y = size.y - current_height
	
	# 更新文字
	if remaining > 1.0:
		cooldown_text.text = str(int(ceil(remaining)))
	else:
		cooldown_text.text = "%.1f" % remaining

func _on_cooldown_finished():
	is_cooldown = false
	cooldown_overlay.visible = false
	cooldown_text.text = ""
	modulate = Color(1, 1, 1, 1)  # 恢复正常
	
	# 播放就绪动画
	play_ready_effect()
	
	print("冷却结束")

func play_ready_effect():
	# 简单缩放动画
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
