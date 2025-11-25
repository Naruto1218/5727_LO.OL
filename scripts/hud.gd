extends CanvasLayer

func update_score(score) -> void:
	$ScoreLabel.text = "Score: " + str(score)
