extends BossState # Matches your custom state machine base class

@export var stun_duration: float = 0.4 # Time locked in hitstun
var stun_timer: float = 0.0

func enter() -> void:
	stun_timer = stun_duration
	
	if actor:
		# 1. Freeze all momentum so he doesn't slide while flinching
		actor.velocity = Vector3.ZERO
		
		# 2. Play the hurt animation loop
		if actor.animation_player.has_animation("hurt"):
			actor.animation_player.play("hurt")
			
		# 3. ─── VISUAL RED FLASH TWEEN ───
		if actor.sprite:
			var tween = actor.create_tween()
			# Flash solid crimson red over 0.1 seconds
			tween.tween_property(actor.sprite, "modulate", Color(1, 0, 0, 1), 0.1) 
			# Return smoothly to standard white colors over 0.1 seconds
			tween.tween_property(actor.sprite, "modulate", Color(1, 1, 1, 1), 0.1)
			
		print("[STATE MACHINE] Lich King flinching and flashing red.")

func physics_update(delta: float) -> void:
	if not actor: return
	
	stun_timer -= delta
	if stun_timer <= 0.0:
		_recover_from_damage()

func _recover_from_damage() -> void:
	# 1. Clear the hurt flag on the main actor body safely
	actor.is_hurt = false
	
	# 2. Automatically sort him back into the proper state based on his live phase
	if actor.current_phase == 2:
		state_machine.change_state("Phase2")
	else:
		state_machine.change_state("Phase1")
