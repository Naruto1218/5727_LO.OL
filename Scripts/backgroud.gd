extends Node2D

@export var player: Node2D

@export var attack1_scene: PackedScene
@export var attack2_scene: PackedScene
@export var attack3_scene: PackedScene
@export var attack4_scene: PackedScene
@export var attack5_scene: PackedScene
@export var attack6_scene: PackedScene

@export var attack1_times: Array[float] = [1.0,1.1]
@export var attack2_times: Array[float] = [2]
@export var attack3_times: Array[float] = [3]
@export var attack4_times: Array[float] = [4]
@export var attack5_times: Array[float] = [5]
@export var attack6_times: Array[float] = [1,2,3,4,5]

var t: float = 0.0
var idx1 := 0
var idx2 := 0
var idx3 := 0
var idx4 := 0
var idx5 := 0
var idx6 := 0


func _ready() -> void:
	randomize()
	attack1_times.sort()
	attack2_times.sort()
	attack3_times.sort()
	attack4_times.sort()
	attack5_times.sort()
	attack6_times.sort()


func _process(delta: float) -> void:
	t += delta

	_check_spawn(attack1_scene, attack1_times, 1)
	_check_spawn(attack2_scene, attack2_times, 2)
	_check_spawn(attack3_scene, attack3_times, 3)
	_check_spawn(attack4_scene, attack4_times, 4)
	_check_spawn(attack5_scene, attack5_times, 5)
	_check_spawn(attack6_scene, attack6_times, 6)


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
