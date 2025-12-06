extends Node2D

@onready var select_sfx: AudioStreamPlayer2D = $StartMenu/select
@onready var death: AudioStreamPlayer2D = $death

# 计分板相关：ScoreLabel 下有 score 和 count 两个 Label
@onready var score_root: CanvasLayer = $ScoreLabel
@onready var score_count_label: Label = $ScoreLabel/count

@export var player: Node2D

@export var attack1_scene: PackedScene
@export var attack2_scene: PackedScene
@export var attack3_scene: PackedScene
@export var attack4_scene: PackedScene
@export var attack5_scene: PackedScene
@export var attack6_scene: PackedScene

@export var attack1_times: Array[float] = []
@export var attack2_times: Array[float] = []
@export var attack3_times: Array[float] = []
@export var attack4_times: Array[float] = []
@export var attack5_times: Array[float] = []
@export var attack6_times: Array[float] = []

@onready var dash_skill_ui: TextureRect = $UICanvas/SkillBar/DashSkillUI

# --- game status ---
@onready var start_menu: Control = $StartMenu/MenuContainer
@onready var game_over_menu: Control = $GameOverMenu/GameOverContainer
@onready var final_score: Label = $GameOverMenu/GameOverContainer/MenuItems/Score

#@onready var start_menu: CanvasLayer = $StartMenu
#@onready var game_over_menu: CanvasLayer = $GameOverMenu

enum GameState { MENU, PLAYING, GAME_OVER }
var current_state: GameState = GameState.MENU
var game_started: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# --- 计分相关变量 ---
var score_value: int = 0           # 当前分数
var score_time_acc: float = 0.0    # 用来累积 delta 实现“每秒+1”

func _ready() -> void:
	rng.randomize()
	
	# 初始状态：显示开始菜单，隐藏游戏结束菜单
	if start_menu:
		start_menu.visible = true
	if game_over_menu:
		game_over_menu.visible = false
	
	# 初始隐藏E技能图标
	if dash_skill_ui:
		dash_skill_ui.visible = false
		print("E技能图标初始隐藏")
	
	# 初始隐藏计分板
	if score_root:
		score_root.visible = false
	_reset_score_ui()  # 确保 count 显示为 0
	
	# 暂停游戏逻辑
	game_started = false
	set_process(false)
	
	generate_attack_schedule(120)  # 生成 120 秒的攻击时间表
	
	# 确保UI引用正确
	if dash_skill_ui:
		dash_skill_ui.player = player  # 传递玩家引用
	
	# 或者延迟设置
	await get_tree().process_frame
	if dash_skill_ui and player:
		dash_skill_ui.player = player
	
	# 连接玩家死亡信号
	if player:
		player.player_died.connect(on_player_died)


func set_game_state(new_state: GameState):
	current_state = new_state
	
	match new_state:
		GameState.MENU:
			print("显示开始菜单，隐藏游戏结束菜单")
			# 显示开始菜单，隐藏游戏结束菜单
			if start_menu:
				start_menu.visible = true
			if game_over_menu:
				game_over_menu.visible = false
			
			if dash_skill_ui:
				dash_skill_ui.visible = false
			
			# 隐藏计分板并重置分数
			if score_root:
				score_root.visible = false
			_reset_score()     # 回到菜单，分数清零
			
			# 暂停游戏逻辑
			game_started = false
			set_process(false)  # 停止 _process 更新
			
			# 重置计时器
			t = 0.0
			idx1 = 0
			idx2 = 0
			idx3 = 0
			idx4 = 0
			idx5 = 0
			idx6 = 0

			# 清理所有攻击
			_cleanup_all_attacks()

			print("游戏状态：菜单")
			
		GameState.PLAYING:
			print("隐藏所有菜单，开始游戏")
			
			reset_game_state()
			
			# 隐藏所有菜单
			if start_menu:
				start_menu.visible = false
			if game_over_menu:
				game_over_menu.visible = false
			
			if dash_skill_ui:
				dash_skill_ui.visible = true
			
			# 显示计分板，并重置分数（新的一局从0开始）
			if score_root:
				score_root.visible = true
			_reset_score()
			
			# 开始游戏逻辑
			game_started = true
			set_process(true)  # 启用 _process 更新
			
			# 生成攻击时间表
			generate_attack_schedule(120)

			# 重置玩家（如果存在）
			if player:
				player.reset_player()

			print("游戏状态：进行中")
			
		GameState.GAME_OVER:
			print("显示游戏结束菜单")
			final_score.text=str("Your Score: ", score_value)
			# 显示游戏结束菜单
			if start_menu:
				start_menu.visible = false
			if game_over_menu:
				game_over_menu.visible = true
				# 可以在这里更新得分等信息（比如显示最终分数）
			
			if dash_skill_ui:
				dash_skill_ui.visible = false
			
			_cleanup_all_attacks()
			
			# 不重置分数，保留这局的分数给玩家看
			# 计分板保持当前显示状态（PLAYING 时已经显示）

			# 停止游戏逻辑
			game_started = false
			set_process(false)
			
			print("游戏状态：结束")


# --- 计分相关函数 ---
func _reset_score():
	score_value = 0
	score_time_acc = 0.0
	_reset_score_ui()

func _reset_score_ui():
	if score_count_label:
		score_count_label.text = str(score_value)


func _cleanup_all_attacks():
	var count = 0
	print("=== 开始清理攻击节点 ===")
	
	# 先打印所有子节点信息
	print("当前所有子节点:")
	for i in range(get_child_count()):
		var child = get_child(i)
		print("  [%d] %s (%s)" % [i, child.name, child.get_class()])
	
	print("\n开始清理...")
	
	# 遍历清理（使用倒序遍历，避免索引问题）
	for i in range(get_child_count() - 1, -1, -1):
		var child = get_child(i)
		
		# 绝对保留的节点
		if child == player:
			print("  保留: 玩家节点")
			continue
		
		if child is CanvasLayer:
			print("  保留: CanvasLayer UI节点")
			continue
		
		if "Menu" in child.name:
			print("  保留: 菜单节点")
			continue
		
		if child == dash_skill_ui:
			print("  保留: 技能UI节点")
			continue
		
		if "UICanvas" in child.name:
			print("  保留: UI画布节点")
			continue
		
		# 判断是否为攻击节点
		var is_attack = false
		var reason = ""
		
		# 判断条件1：有start方法
		if child.has_method("start"):
			is_attack = true
			reason = "有start方法"
		
		# 判断条件2：名称包含"attach"
		elif "attach" in child.name.to_lower():
			is_attack = true
			reason = "名称包含'attach'"

		# 判断条件3：是Area2D类型（你的攻击都是Area2D）
		elif child is Area2D and child != player:
			is_attack = true
			reason = "Area2D类型（非玩家）"
		
		# 执行清理或保留
		if is_attack:
			print("  清理攻击节点: %s (理由: %s)" % [child.name, reason])
			child.queue_free()
			count += 1
		else:
			print("  保留未知节点: %s (%s)" % [child.name, child.get_class()])
	
	print("\n=== 清理完成，总共清理了 %d 个攻击节点 ===" % count)



func generate_attack_schedule(total_seconds: int) -> void:
	# 先清空原来的
	attack1_times.clear()
	attack2_times.clear()
	attack3_times.clear()
	attack4_times.clear()
	attack5_times.clear()
	attack6_times.clear()

	for i in range(total_seconds):
		var t1: float = float(i) + 1.0    # 第 i 秒：时间点是 1,2,...,60
		var atk_id: int = rng.randi_range(1, 6)  # 随机选 1~6 号攻击

		match atk_id:
			1:
				attack1_times.append(t1)
			2:
				attack2_times.append(t1)
			3:
				attack3_times.append(t1)
			4:
				attack4_times.append(t1)
			5:
				attack5_times.append(t1)
			6:
				attack6_times.append(t1)


var t: float = 0.0
var idx1 := 0
var idx2 := 0
var idx3 := 0
var idx4 := 0
var idx5 := 0
var idx6 := 0


func _process(delta: float) -> void:
	if not game_started or current_state != GameState.PLAYING:
		return
	t += delta

	# 每秒加一分的计分逻辑
	score_time_acc += delta
	while score_time_acc >= 1.0:
		score_time_acc -= 1.0
		score_value += 1
		_reset_score_ui()

	_check_spawn(attack1_scene, attack1_times, 1)
	_check_spawn(attack2_scene, attack2_times, 2)
	_check_spawn(attack3_scene, attack3_times, 3)
	_check_spawn(attack4_scene, attack4_times, 4)
	_check_spawn(attack5_scene, attack5_times, 5)
	_check_spawn(attack6_scene, attack6_times, 6)


# 添加重置游戏状态的函数
func reset_game_state():
	print("=== 重置游戏状态 ===")
	
	# 1. 重置计时器
	t = 0.0
	print("  重置计时器 t = 0.0")
	
	# 2. 重置攻击生成索引
	idx1 = 0
	idx2 = 0
	idx3 = 0
	idx4 = 0
	idx5 = 0
	idx6 = 0
	print("  重置攻击索引: 全部设为0")
	
	# 3. 清理所有攻击
	_cleanup_all_attacks()
	
	# 4. 重新生成攻击时间表
	generate_attack_schedule(120)
	print("  重新生成攻击时间表")
		
	# 5. 重置玩家状态
	if player:
		player.reset_player()
		print("  玩家状态已重置")
	
	print("=== 游戏状态重置完成 ===")


func _check_spawn(scene: PackedScene, times: Array[float], which: int) -> void:
	if scene == null:
		return

	var idx := 0
	match which:
		1: idx = idx1
		2: idx = idx2
		3: idx = idx3
		4: idx = idx4
		5: idx = idx5
		6: idx = idx6

	if idx >= times.size():
		return

	if t >= times[idx]:
		var atk = scene.instantiate()
		add_child(atk)

		# **强制调用 start(player)**，不做任何 if 判断
		if atk.has_method("start"):
			atk.start(player)
		else:
			push_warning("Attack scene %d 没有 start(player) 方法" % which)

		# 回写索引
		match which:
			1: idx1 += 1
			2: idx2 += 1
			3: idx3 += 1
			4: idx4 += 1
			5: idx5 += 1
			6: idx6 += 1


# --- 按钮信号处理 ---
func _on_start_button_pressed():
	print("开始游戏按钮被点击")
	if select_sfx:
		select_sfx.play()
	set_game_state(GameState.PLAYING)

func _on_restart_button_pressed():
	print("重新开始按钮被点击")
	set_game_state(GameState.PLAYING)

func _on_back_to_menu_button_pressed():
	print("返回菜单按钮被点击")
	set_game_state(GameState.MENU)

# 玩家死亡时调用
func on_player_died():
	print("玩家死亡，显示游戏结束菜单")
	if death:
		death.play()
	set_game_state(GameState.GAME_OVER)
