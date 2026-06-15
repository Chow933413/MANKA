extends BossState # Or whichever base class your state machine inherits from

func enter() -> void:
	# Keep his momentum completely dead when waiting
	if actor:
		actor.velocity = Vector3.ZERO
		
		if actor.animation_player.has_animation("idle"):
			actor.animation_player.play("idle")
		print("[STATE MANAGER] Lich King is resting peacefully in Idle State.")

func physics_update(_delta: float) -> void:
	# We intentionally leave this completely blank!
	# He will sit here forever until 'state_machine.change_state("phase1")' 
	# is forcefully called by the level's trigger line.
	pass
