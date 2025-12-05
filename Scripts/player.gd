extends CharacterBody2D

@export var move_speed: float = 200.0  # 角色移动速度（像素/秒）
@export var hp_segments: int = 10      # 血条分成多少份（10格）
@export var max_hp: int = 10           # 最大血量
var target_pos: Vector2                # 要移动到的目标位置
var hp: int                            # 当前血量

# --- MP / 护盾相关 ---
@export var max_mp: float = 100.0      # MP 最大值
@export var mp_charge_rate: float = 10.0  # 每秒充能多少 MP（按住走路时）
var mp: float = 0.0                    # 当前 MP
var shield_active: bool = false        # 护盾是否激活

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# HP 条
@onready var health_bar: Node2D = $HealthBar
@onready var health_fill: Sprite2D = $HealthBar/HP
var _full_region: Rect2

# MP 条
@onready var mp_bar: Node2D = $MPBar
@onready var mp_fill: Sprite2D = $HealthBar/MP
var _mp_full_region: Rect2

# 护盾
@onready var shield: Node2D = $Shield

# --- 冲刺（Dash）相关 ---
@export var dash_speed: float = 500.0      # 冲刺速度
@export var dash_distance: float = 100.0   # 最大冲刺距离（像素）
var is_dashing: bool = false               # 是否正在冲刺
var dash_direction: Vector2 = Vector2.ZERO # 冲刺方向
var dash_distance_left: float = 0.0        # 冲刺剩余距离

@export var dash_cooldown: float = 5.0  # 冲刺冷却时间（秒）
var dash_cooldown_timer: float = 0.0
var can_dash: bool = true

# 添加dash信号定义：
signal dash_cooldown_started(cooldown_time: float)
signal dash_cooldown_updated(remaining_time: float, cooldown_time: float)
signal dash_cooldown_finished()

# --- 死亡信号 ---
signal player_died

# 添加发射信号的辅助函数：
func emit_dash_cooldown_started():
	dash_cooldown_started.emit(dash_cooldown)

func emit_dash_cooldown_updated():
	dash_cooldown_updated.emit(dash_cooldown_timer, dash_cooldown)

func emit_dash_cooldown_finished():
	dash_cooldown_finished.emit()


func _ready() -> void:
	target_pos = global_position
	hp = max_hp
	mp = 0.0
	add_to_group("player")

	# --- HP 条设置：左上角对齐，从右边被裁 ---
	health_fill.centered = false
	health_fill.region_enabled = true
	if health_fill.texture:
		_full_region = Rect2(Vector2.ZERO, health_fill.texture.get_size())
	else:
		_full_region = health_fill.region_rect
	health_fill.region_rect = _full_region
	health_fill.position.x -= _full_region.size.x / 2.0
	health_fill.position.y -= _full_region.size.y / 2.0

	# -------- MP 条设置：左对齐，从左向右增长 --------
	mp_fill.region_enabled = true
	if mp_fill.texture:
		_mp_full_region = Rect2(Vector2.ZERO, mp_fill.texture.get_size())
	else:
		_mp_full_region = mp_fill.region_rect

	mp_fill.region_rect = _mp_full_region

	# 关键：改用左上角对齐 + 把位置补回来
	mp_fill.centered = false
	mp_fill.position.x -= _mp_full_region.size.x / 2.0
	mp_fill.position.y -= _mp_full_region.size.y / 2.0

	# --- 护盾一开始是关闭的 ---
	shield_active = false
	shield.visible = false

	dash_cooldown_timer = 0.0
	can_dash = true

	# 连接死亡信号到游戏控制器
	player_died.connect(_on_player_died)

	update_hp_bar()
	update_mp_bar()

func _on_player_died():
	# 可以在这里添加玩家死亡后的本地效果
	print("玩家死亡信号已发送")
	
	# 可选：禁用玩家控制
	set_process_input(false)
	set_physics_process(false)
	velocity = Vector2.ZERO

# 处理输入：鼠标 + 停止
func _unhandled_input(event: InputEvent) -> void:
	# 鼠标左键：设置移动目标
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.pressed:
		target_pos = get_global_mouse_position()

	# 按下 S 键：立刻停止移动
	elif event is InputEventKey \
			and event.pressed \
			and not event.echo:
		if event.keycode == KEY_S:
			target_pos = global_position
			velocity = Vector2.ZERO
		elif event.keycode == KEY_E:
			if can_dash:
				start_dash()



# 用物理帧来移动角色 + 走路充能 MP
func _physics_process(delta: float) -> void:
	var dir: Vector2 = target_pos - global_position

# --- 速度计算：冲刺优先，其次正常移动 ---
	if is_dashing and dash_distance_left > 0.0:
		# 本帧理论上要走的距离
		var step: float = dash_speed * delta
		# 实际不能超过剩余距离
		var move_len: float = step
		if move_len > dash_distance_left:
			move_len = dash_distance_left

		# 根据本帧要走的距离，算出对应速度（这样 move_and_slide 后刚好走 move_len）
		if delta > 0.0:
			velocity = dash_direction * (move_len / delta)
		else:
			velocity = Vector2.ZERO

		dash_distance_left -= move_len

		# 如果剩余距离很小了，就结束冲刺
		if dash_distance_left <= 0.5:
			is_dashing = false
			dash_distance_left = 0.0
	else:
		# 原来的移动逻辑
		if dir.length() > 2.0:
			dir = dir.normalized()
			velocity = dir * move_speed
		else:
			velocity = Vector2.ZERO

	move_and_slide()

	# --- 角色在移动时充能 MP ---
	if velocity.length() > 1.0:
		mp += mp_charge_rate * delta
		if mp > max_mp:
			mp = max_mp
		update_mp_bar()

		# MP 满了且还没有护盾 -> 激活护盾
		if (not shield_active) and mp >= max_mp:
			activate_shield()
			
	if not can_dash:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			dash_cooldown_timer = 0
			can_dash = true
			emit_dash_cooldown_finished()
			print("Dash ready")
	# 发出冷却更新信号（用于UI更新）
	emit_dash_cooldown_updated()

# 更新 HP 条
func update_hp_bar() -> void:
	if max_hp <= 0 or hp_segments <= 0:
		return

	var hp_ratio: float = float(hp) / float(max_hp)
	if hp_ratio < 0.0:
		hp_ratio = 0.0
	elif hp_ratio > 1.0:
		hp_ratio = 1.0

	var visible_segments: int = int(ceil(hp_ratio * float(hp_segments)))
	if visible_segments < 0:
		visible_segments = 0
	elif visible_segments > hp_segments:
		visible_segments = hp_segments

	var seg_ratio: float = float(visible_segments) / float(hp_segments)
	var new_region: Rect2 = _full_region
	new_region.size.x = _full_region.size.x * seg_ratio

	health_fill.region_rect = new_region


# 更新 MP 条（0 ~ max_mp 的连续值）
func update_mp_bar() -> void:
	if max_mp <= 0.0:
		return

	var mp_ratio: float = mp / max_mp
	if mp_ratio < 0.0:
		mp_ratio = 0.0
	elif mp_ratio > 1.0:
		mp_ratio = 1.0

	var new_region: Rect2 = _mp_full_region
	new_region.size.x = _mp_full_region.size.x * mp_ratio

	mp_fill.region_rect = new_region


# 激活护盾（MP 满时调用）
func activate_shield() -> void:
	shield_active = true
	shield.visible = true
	# MP 保持满值，等被打掉才清空


# 耗尽护盾（挡下攻击后调用）
func consume_shield() -> void:
	shield_active = false
	shield.visible = false
	mp = 0.0
	update_mp_bar()


# 受伤
func take_damage(amount: int = 1) -> void:
	# 优先检查护盾：有护盾则抵挡一次攻击，不扣血
	if shield_active:
		consume_shield()
		print("Shield blocked the damage!")
		return

	if hp <= 0:
		return

	hp -= amount
	if hp < 0:
		hp = 0

	update_hp_bar()
	flash_on_hit()

	print("HP:", hp, "/", max_hp)

	if hp <= 0:
		die()


func die() -> void:
	print("Player Dead")
	player_died.emit()  # 发射死亡信号
	# 这里可以加死亡动画、游戏结束逻辑等

# --- 新增：重置玩家状态的方法 ---
func reset_player():
	print("重置玩家状态")
	
	# 重置位置
	global_position = Vector2(0, 0)  # 设置一个初始位置，可以根据需要调整
	target_pos = global_position
	velocity = Vector2.ZERO

	# 重置血量
	hp = max_hp
	update_hp_bar()
	
	# 重置MP和护盾
	mp = 0.0
	shield_active = false
	shield.visible = false
	update_mp_bar()

	# 重置冲刺状态
	is_dashing = false
	dash_distance_left = 0.0
	can_dash = true
	dash_cooldown_timer = 0.0

	# 重置动画和颜色
	if sprite:
		sprite.modulate.a = 1.0
		sprite.modulate = Color(1, 1, 1, 1)
	
	# 重新激活输入
	set_process_input(true)
	set_physics_process(true)

	print("玩家状态已重置")

func start_dash() -> void:
	# 已在冲刺中就不重复开始
	if is_dashing:
		return

	# 冲刺方向：优先用当前移动方向，其次用目标方向
	var dir: Vector2 = velocity
	if dir.length() < 0.1:
		dir = target_pos - global_position

	if dir.length() < 0.1:
		# 静止且没有目标，不冲刺
		return

	dash_direction = dir.normalized()

	# 计算到目标点的剩余距离
	var dist_to_target: float = (target_pos - global_position).length()

	# 本次能冲的距离 = min(最大冲刺距离, 距离目标点)
	dash_distance_left = dash_distance
	if dist_to_target > 0.0 and dist_to_target < dash_distance_left:
		dash_distance_left = dist_to_target

	# 没有距离可以冲，就不开始
	if dash_distance_left <= 0.0:
		return
	
	is_dashing = true
	can_dash = false
	dash_cooldown_timer = dash_cooldown
	
	emit_dash_cooldown_started()

# 受伤闪烁效果：快速改变透明度几次
func flash_on_hit() -> void:
	var times: int = 3           # 闪烁次数
	var interval: float = 0.07   # 每次闪烁间隔秒数

	for i in range(times):
		sprite.modulate.a = 0.2
		await get_tree().create_timer(interval).timeout

		sprite.modulate.a = 1.0
		await get_tree().create_timer(interval).timeout

# 添加获取冷却状态的函数（供UI调用）：
func get_dash_cooldown_info() -> Dictionary:
	return {
		"can_dash": can_dash,
		"remaining_time": dash_cooldown_timer,
		"total_cooldown": dash_cooldown,
		"cooldown_ratio": 1.0 - (dash_cooldown_timer / dash_cooldown) if dash_cooldown > 0 else 1.0
	}
