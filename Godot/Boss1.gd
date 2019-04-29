extends RigidBody2D

export var cooldown = 0.2
export var laser_cooldown = 1
export var laser_duration = 0.3
export var turn_time = 1
export var HEALTH = 50000
export var MAX_HEALTH = 50000

var laser_active = false
var player_hit_by_current_laser = false

var timeSinceLastShot = 0 #Does NOT shoot immediately
var directionVector = Vector2(-1,0)

var alive = true

var timeSinceLastRotationChange = 0
var waiting_to_change_rotation = false


onready var Layer = $"/root/Base".Layer
const PROJECTILE = preload("Enemy_Projectile.tscn")
var fight_time = 0
var boss_mode = 1 #1 = Spinning, 2 = Shooting, 3 = Laser
var timeSinceLastModeChange = 0
const boss_mode_durations = {1:4,2:6,3:8} #Duration of first mode must be divisible by 2, second mode by 3, last mode by 4. Otherwise bad rotational things happen!
var rotation_direction = 1

func _ready():
	$HealthBar.max_value = MAX_HEALTH
	$HealthBar.value = HEALTH
	$HealthBar.set('z',10) #Not effective sadly

func _draw():
	if boss_mode == 3:
		if timeSinceLastShot > laser_cooldown:
			timeSinceLastShot = 0
			laser_active = true
			player_hit_by_current_laser = false
			draw_line(1.5*$Laser.position, $Laser.position.normalized()*3000, Color.yellow, 5, true)
		elif laser_active and timeSinceLastShot < laser_duration:
			draw_line(1.5*$Laser.position, $Laser.position.normalized()*3000, Color.yellow, 5, true)
		else:
			laser_active = false

func maybeShoot(delta,playerPos):
	if not alive:
		return
	fight_time += delta

	if boss_mode == 1:
		set_angular_velocity(3*PI) #Permanently spins
		for entity in [$HealthBar, $Left_Gun, $Right_Gun, $Laser]:
			correct_rotation(entity)
		correct_position()
	elif boss_mode == 2: #Slow spin, spamming bullets from both guns
		set_angular_velocity(2*PI/3)
		correct_healthbar()
		timeSinceLastShot += delta
		if timeSinceLastShot > cooldown:
			timeSinceLastShot = 0
			shoot($Left_Gun)
			shoot($Right_Gun)
	elif boss_mode == 3: #Slow spin, shooting lasers
		if should_change_direction(playerPos):
			waiting_to_change_rotation = true
		if waiting_to_change_rotation:
			timeSinceLastRotationChange += delta
			if timeSinceLastRotationChange > turn_time:
				timeSinceLastRotationChange = 0
				waiting_to_change_rotation = false
				rotation_direction *= -1
		set_angular_velocity((rotation_direction)*PI/4)
		correct_healthbar()
		timeSinceLastShot += delta
		update() #Will turn the laser on / off 
		
		if laser_active:
			shoot_laser_rays()
		
	var speed = 50
	if boss_mode == 1:
		speed = 100
	set_linear_velocity((playerPos - position).normalized() * speed)
	follow_player(playerPos)
	stop_before_wall() #Prevents it from hitting a wall (using several raycasts)
	
	timeSinceLastModeChange += delta
	if timeSinceLastModeChange > boss_mode_durations[boss_mode]:
		timeSinceLastModeChange = 0
		var new_boss_mode = boss_mode
		
		while new_boss_mode == boss_mode:
			new_boss_mode = randi()%3 + 1
		
		#Exiting previous boss_mode
		if boss_mode == 1:
			self.set_rotation(0)
			for entity in [$HealthBar, $Left_Gun, $Right_Gun, $Laser]:
				correct_rotation(entity)
			correct_position()
		elif boss_mode == 2: #Pull guns back in
			self.set_rotation(0)
			for entity in [$HealthBar, $Left_Gun, $Right_Gun, $Laser]:
				correct_rotation(entity)
			correct_position()
			#$Left_Gun.global_position += Vector2(14,0)
			#$Right_Gun.global_position += Vector2(-14,0)
		elif boss_mode == 3: #Pull laser back in
			self.set_rotation(0)
			for entity in [$HealthBar, $Left_Gun, $Right_Gun, $Laser]:
				correct_rotation(entity)
			correct_position()
			#$Laser.global_position += Vector2(0,-10)
		
		#Enter new boss_mode
		if new_boss_mode == 2: #Pull guns out
			$Left_Gun.global_position += Vector2(-14,0)
			$Right_Gun.global_position += Vector2(14,0)
		elif new_boss_mode == 3: #Pull out laser
			$Laser.global_position += Vector2(0,10)

		boss_mode = new_boss_mode
		print(boss_mode)

func correct_rotation(entity):
	entity.set_rotation(-self.rotation)

func correct_healthbar():
	correct_rotation($HealthBar)
	$HealthBar.rect_global_position = position + Vector2(-35,-100)

func correct_position():
	$HealthBar.rect_global_position = position + Vector2(-35,-100)
	$Left_Gun.global_position = position + Vector2(-19,0)
	$Right_Gun.global_position = position + Vector2(19,0)
	$Laser.global_position = position + Vector2(0,25)
	
func follow_player(playerPos):
	var vectorDifference = playerPos - position
	directionVector = vectorDifference.normalized()

func stop_before_wall():
	var surroundings = get_world_2d().direct_space_state
	var vectors = [Vector2(105,0),Vector2(-105,0),Vector2(0,105),Vector2(0,-105)]
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

func shoot(gun):
	var bullet = PROJECTILE.instance()
	get_parent().add_child(bullet)
	bullet.shoot(gun.global_position,-(position - gun.global_position).normalized(),200)

func shoot_laser():
	print("Shooting laser!")
	draw_line($Laser.global_position,position + ($Laser.position).normalized()*999, Color.red, 5)

func onProjectileHit(damage,bodypart):
	if bodypart == 'Body' or bodypart == 'ArmHookTip':
		take_damage(damage*0.75)
	elif bodypart == 'Arm' or bodypart == 'ArmHook':
		take_damage(damage)
	elif bodypart == 'Spikes' or bodypart in ['Left_Gun','Right_Gun']:
		take_damage(2*damage)
	elif bodypart == 'Laser':
		take_damage(3*damage)
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
		print("collided with " + str(local_shape))
		if local_shape == 0 or local_shape == 5: #Body or Gun
			body.takeDamage(100)
			body.playerMotion = directionVector*300
			#body.set_position(body.position + body.playerMotion / 50) #May push player into a wall
			body.move_disabled_time = 0.15
		elif local_shape == 1 : #Arm
			body.playerMotion = Vector2(-1,0).rotated(rotation)*200
			body.move_disabled_time = 0.05
		elif local_shape == 2 or local_shape == 3: #ArmHook or ArmHookTip
			body.takeDamage(50)
			body.playerMotion = Vector2(1,0).rotated(rotation)*1000
			#body.set_position(body.position + body.playerMotion / 20) #May push player into a wall
			body.move_disabled_time = 0.5
		elif local_shape == 4: #Spikes
			body.takeDamage(999999) #Instant-kill unless immune
	elif 'Destructible_Wall' in body.name:
		body.takeDamage(1000)

func should_change_direction(playerPos):
	if (position-playerPos).angle_to(Vector2(1,0).rotated(rotation - PI/2)) > 0:
		return rotation_direction != -1
	else:
		return rotation_direction != 1
		
func shoot_laser_rays():
	var entities_to_ignore = [self]
	while true:
		var first_collision = get_world_2d().direct_space_state.intersect_ray(position,position + Vector2(0,1).rotated(rotation) * 3000 , entities_to_ignore, Layer.ENVIRONMENT + Layer.ENEMY + Layer.PLAYER)
		print(first_collision.position)
		if first_collision.size() != 0 and not ('Solid_Wall' in first_collision.collider.name) and not ('Boundary' in first_collision.collider.name) and not ('Level' in first_collision.collider.name):
			entities_to_ignore.append(first_collision.collider)
			if first_collision.collider.has_method('takeDamage'):
				if first_collision.collider.name == 'Player' and not player_hit_by_current_laser:
					first_collision.collider.takeDamage(300)
					player_hit_by_current_laser = true
				if first_collision.collider.name != 'Player':
					first_collision.collider.takeDamage(40)
					
			else:
				print("Entity got hit by laser but cannot take damage!")
				print(first_collision.collider.name)
		else: #Empty dictionary or solid wall or world boundary (hopefully!)
			break