extends RigidBody2D

const cooldown = 0.5

var timeSinceLastShot = 0 #Does NOT shoot immediately
var directionVector = Vector2(-1,0)

var alive = true

export var HEALTH = 1000
export var MAX_HEALTH = 1000

onready var Layer = $"/root/Base".Layer

func _ready():
	$HealthBar.max_value = MAX_HEALTH
	$HealthBar.value = HEALTH
	$HealthBar.set('z',10)
	set_contact_monitor(true)
	set_max_contacts_reported(5)
	set_angular_damp(0)
	set_gravity_scale(0)

func maybeShoot(delta,playerPos):
	if not alive:
		return
	set_angular_velocity(5) #Permanently spins
	$HealthBar.set_rotation(-self.rotation)
	$HealthBar.rect_global_position = position + Vector2(-32,-100)
	timeSinceLastShot += delta
	if timeSinceLastShot > cooldown:
		timeSinceLastShot = 0
		shoot()
	set_linear_velocity((playerPos - position).normalized() * 60)
	follow_player(playerPos)
	stop_before_wall() #Prevents it from hitting a wall (using several raycasts)

func follow_player(playerPos):
	var vectorDifference = playerPos - position
	directionVector = vectorDifference.normalized()

func stop_before_wall():
	var surroundings = get_world_2d().direct_space_state
	var vectors = [Vector2(110,0),Vector2(-110,0),Vector2(0,110),Vector2(0,-110)]
	for p in range(4):
		for i in range(4):
			var result = surroundings.intersect_ray(position + vectors[p]/2,position + vectors[p]/2 + vectors[i], [self], Layer.ENEMY + Layer.ENVIRONMENT)
			if result.size() != 0:
				if 'Solid_Wall' in result.collider.name:
					if i == 0:
						set_linear_velocity(Vector2(min(0,get_linear_velocity().x),get_linear_velocity().y))
					elif i == 1:
						set_linear_velocity(Vector2(max(0,get_linear_velocity().x),get_linear_velocity().y))
					elif i == 2:
						set_linear_velocity(Vector2(get_linear_velocity().x,min(0,get_linear_velocity().y)))
					elif i == 3:
						set_linear_velocity(Vector2(get_linear_velocity().x,max(0,get_linear_velocity().y)))

func take_damage(damage):
	print("Boss took " + str(damage) + " damage!")
	HEALTH = max(0,HEALTH - damage)
	onHealthChange(-damage)

func onHealthChange(change):
	print(HEALTH)
	$HealthBar.value = HEALTH
	if HEALTH == 0:
		$HealthBar.visible = false #Hides it. Using queue_free() causes issues everywhere
		onBossDeath()

func shoot():
	pass

func onProjectileHit(damage,bodypart):
	if bodypart == 'Body' or bodypart == 'ArmHookTip':
		take_damage(damage*0.75)
	elif bodypart == 'Arm' or bodypart == 'ArmHook':
		take_damage(damage)
	elif bodypart == 'Spikes':
		take_damage(2*damage)
	else:
		print("Unexpected bodypart " + str(bodypart))

func onBossDeath():
	self.alive = false
	set_linear_velocity(Vector2())
	set_angular_velocity(0)
	print("Playing death animation!")
	$AnimationPlayer.play("death_animation")

func change_opacity():
	$AnimatedSprite.modulate.a = max(0,$AnimatedSprite.modulate.a - 0.1)

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "death_animation":
		var keyScene = load("res://Key.tscn")
		var positions = [Vector2(-30,-30),Vector2(-30,30),Vector2(30,-30),Vector2(30,30)]
		for i in range(4):
			var key = keyScene.instance()
			$"/root/Base".current_scene.add_child(key)
			key.set_position(position + positions[i])
		self.queue_free()


func _on_Boss_body_shape_entered(body_id, body, body_shape, local_shape):
	if body.name == 'Player':
		if local_shape == 0: #Body
			body.takeDamage(100)
			body.playerMotion = directionVector*300
			body.set_position(body.position + body.playerMotion / 50)
			body.move_disabled_time = 0.15
		elif local_shape == 1 or local_shape == 2: #Arm or ArmHook
			pass #Nothing happens
		elif local_shape == 3: #ArmHookTip
			body.takeDamage(50)
			body.playerMotion = Vector2(1,0).rotated(rotation)*500
			body.set_position(body.position + body.playerMotion / 20)
			body.move_disabled_time = 0.5
		elif local_shape == 4: #Spikes
			body.takeDamage(999999) #Instant-kill unless immune
