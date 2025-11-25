extends Area2D

signal hit_enemy(enemy)

@export var speed = 1000

func _physics_process(delta: float) -> void:
	position += Vector2.UP.rotated(rotation) * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		hit_enemy.emit(body)
		queue_free()


func _on_visible_on_screen_notifier_2d_2_screen_exited() -> void:
	queue_free()
