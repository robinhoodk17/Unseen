extends StaticBody3D

func takeDamage(amount) -> void:
	get_parent().takeDamage(amount)
