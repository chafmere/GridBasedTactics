extends AnimatedSprite3D

var max_frames: int  = 100

func _ready() -> void:
	max_frames = sprite_frames.get_frame_count("health")

func reduct_health_bar(health_percentage: float) -> void:
	var health_bar_frames: float = max_frames - (max_frames * health_percentage)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "frame",health_bar_frames,.5)


func _on_health_health_remaining(health_percentage: float) -> void:
	print(health_percentage)
	reduct_health_bar(health_percentage)
