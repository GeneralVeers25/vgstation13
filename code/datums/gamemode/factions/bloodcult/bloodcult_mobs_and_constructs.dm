
/////////////////Juggernaut///////////////
/mob/living/simple_animal/construct/armoured/perfect
	icon_state = "juggernaut2"
	icon_living = "juggernaut2"
	icon_dead = "juggernaut2"
	construct_spells = list(
		/spell/aoe_turf/conjure/forcewall/greater,
		/spell/juggerdash,
		)
	see_in_dark = 7
	var/dash_dir = null
	var/turf/crashing = null

/mob/living/simple_animal/construct/armoured/perfect/New()
	..()
	setupfloat()

/mob/living/simple_animal/construct/armoured/perfect/to_bump(var/atom/obstacle)
	if(src.throwing)
		var/breakthrough = 0
		if(istype(obstacle, /obj/structure/window/))
			var/obj/structure/window/W = obstacle
			W.shatter()
			breakthrough = 1

		else if(istype(obstacle, /obj/structure/grille/))
			var/obj/structure/grille/G = obstacle
			G.health = (0.25*initial(G.health))
			G.healthcheck()
			breakthrough = 1

		else if(istype(obstacle, /obj/structure/table))
			var/obj/structure/table/T = obstacle
			T.destroy()
			breakthrough = 1

		else if(istype(obstacle, /obj/structure/rack))
			new /obj/item/weapon/rack_parts(obstacle.loc)
			qdel(obstacle)
			breakthrough = 1

		else if(istype(obstacle, /turf/simulated/wall))
			var/turf/simulated/wall/W = obstacle
			if (W.hardness <= 60)
				playsound(W, 'sound/weapons/heavysmash.ogg', 75, 1)
				W.dismantle_wall(1)
				breakthrough = 1
			else
				src.throwing = 0
				src.crashing = null

		else if(istype(obstacle, /obj/structure/reagent_dispensers/fueltank))
			obstacle.ex_act(1)

		else if(istype(obstacle, /mob/living))
			var/mob/living/L = obstacle
			if (L.flags & INVULNERABLE)
				src.throwing = 0
				src.crashing = null
			else if (!(L.status_flags & CANKNOCKDOWN) || (M_HULK in L.mutations) || istype(L,/mob/living/silicon))
				//can't be knocked down? you'll still take the damage.
				src.throwing = 0
				src.crashing = null
				L.take_overall_damage(5,0)
				if(L.locked_to)
					L.locked_to.unlock_atom(L)
			else
				L.take_overall_damage(5,0)
				if(L.locked_to)
					L.locked_to.unlock_atom(L)
				L.Stun(2)
				L.Knockdown(2)
				L.apply_effect(5, STUTTER)
				playsound(src, 'sound/weapons/heavysmash.ogg', 50, 0, 0)
				breakthrough = 1
		else
			src.throwing = 0
			src.crashing = null

		if(breakthrough)
			if(crashing && !istype(crashing,/turf/space))
				spawn(1)
					src.throw_at(crashing, 50, src.throw_speed)
			else
				spawn(1)
					crashing = get_distant_turf(get_turf(src), dash_dir, 2)
					src.throw_at(crashing, 50, src.throw_speed)

	if(istype(obstacle, /obj))
		var/obj/O = obstacle
		if(!O.anchored)
			step(obstacle,src.dir)
		else
			obstacle.Bumped(src)
	else if(istype(obstacle, /mob))
		step(obstacle,src.dir)
	else
		obstacle.Bumped(src)


////////////////////Wraith/////////////////////////


/mob/living/simple_animal/construct/wraith/perfect
	icon_state = "wraith2"
	icon_living = "wraith2"
	icon_dead = "wraith2"
	see_in_dark = 7
	construct_spells = list(
		/spell/targeted/ethereal_jaunt/shift/alt,
		/spell/wraith_warp,
		/spell/aoe_turf/conjure/path_entrance,
		/spell/aoe_turf/conjure/path_exit,
		)
	var/warp_ready = FALSE

/mob/living/simple_animal/construct/wraith/perfect/New()
	..()
	setupfloat()

/mob/living/simple_animal/construct/wraith/perfect/toggle_throw_mode()
	var/spell/wraith_warp/WW = locate() in spell_list
	WW.perform(src)


////////////////////Artificer/////////////////////////

/mob/living/simple_animal/construct/builder/perfect
	icon_state = "artificer2"
	icon_living = "artificer2"
	icon_dead = "artificer2"
	see_in_dark = 7
	construct_spells = list(
		/spell/aoe_turf/conjure/struct,
		/spell/aoe_turf/conjure/wall,
		/spell/aoe_turf/conjure/floor,
		/spell/aoe_turf/conjure/door,
		/spell/aoe_turf/conjure/pylon,
		/spell/aoe_turf/conjure/construct/lesser/alt,
		/spell/aoe_turf/conjure/soulstone,
		/spell/aoe_turf/conjure/hex,
		)
	var/mob/living/simple_animal/construct/heal_target = null
	var/obj/effect/overlay/artificerray/ray = null
	var/heal_range = 2
	var/list/minions = list()

/mob/living/simple_animal/construct/builder/perfect/New()
	..()
	setupfloat()

/mob/living/simple_animal/construct/builder/perfect/Life()
	if(timestopped)
		return 0
	. = ..()
	if(. && heal_target)
		heal_target.health = min(heal_target.maxHealth, heal_target.health + round(heal_target.maxHealth/10))
		anim(target = heal_target, a_icon = 'icons/effects/effects.dmi', flick_anim = "const_heal", lay = NARSIE_GLOW, plane = LIGHTING_PLANE)
		move_ray()
		process_construct_hud(src)

/mob/living/simple_animal/construct/builder/perfect/Move(NewLoc,Dir=0,step_x=0,step_y=0,var/glide_size_override = 0)
	. = ..()
	if (ray)
		move_ray()

/mob/living/simple_animal/construct/builder/perfect/proc/start_ray(var/mob/living/simple_animal/construct/target)
	if (!istype(target))
		return
	if (locate(src) in target.healers)
		to_chat(src, "<span class='warning'>You are already healing \the [target].</span>")
		return
	if (ray)
		end_ray()
	target.healers.Add(src)
	heal_target = target
	ray = new (loc)
	to_chat(src, "<span class='notice'>You are now healing \the [target].</span>")
	move_ray()

/mob/living/simple_animal/construct/builder/perfect/proc/move_ray()
	if(heal_target && ray && heal_target.health < heal_target.maxHealth && get_dist(heal_target, src) <= heal_range && isturf(loc) && isturf(heal_target.loc))
		ray.forceMove(loc)
		var/disty = heal_target.y - src.y
		var/distx = heal_target.x - src.x
		var/newangle
		if(!disty)
			if(distx >= 0)
				newangle = 90
			else
				newangle = 270
		else
			newangle = arctan(distx/disty)
			if(disty < 0)
				newangle += 180
			else if(distx < 0)
				newangle += 360
		var/matrix/M = matrix()
		if (ray.oldloc_source && ray.oldloc_target && get_dist(src,ray.oldloc_source) <= 1 && get_dist(heal_target,ray.oldloc_target) <= 1)
			animate(ray, transform = turn(M.Scale(1,sqrt(distx*distx+disty*disty)),newangle),time = 1)
		else
			ray.transform = turn(M.Scale(1,sqrt(distx*distx+disty*disty)),newangle)
		ray.oldloc_source = src.loc
		ray.oldloc_target = heal_target.loc
	else
		end_ray()

/mob/living/simple_animal/construct/builder/perfect/proc/end_ray()
	if (heal_target)
		heal_target.healers.Remove(src)
		heal_target = null
	if (ray)
		qdel(ray)
		ray = null

/obj/effect/overlay/artificerray
	name = "ray"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "artificer_ray"
	layer = FLY_LAYER
	plane = LYING_MOB_PLANE
	anchored = 1
	mouse_opacity = 0
	pixel_x = -32
	pixel_y = -29
	var/turf/oldloc_source = null
	var/turf/oldloc_target = null

/obj/effect/overlay/artificerray/cultify()
	return

/obj/effect/overlay/artificerray/ex_act()
	return

/obj/effect/overlay/artificerray/emp_act()
	return

/obj/effect/overlay/artificerray/blob_act()
	return

/obj/effect/overlay/artificerray/singularity_act()
	return


/mob/living/simple_animal/hostile/hex
	name = "\improper Hex"
	desc = "A lesser construct, crafted by an Artificer."
	stop_automated_movement_when_pulled = 1
	ranged_cooldown_cap = 1
	icon = 'icons/mob/mob.dmi'
	icon_state = "hex"
	icon_living = "hex"
	icon_dead = "hex"
	speak_chance = 0
	turns_per_move = 8
	response_help = "gently taps"
	response_disarm = "shoves"
	response_harm = "hits"
	speed = 0.2
	maxHealth = 50
	health = 50
	can_butcher = 0
	ranged = 1
	retreat_distance = 4
	minimum_distance = 4
	projectilesound = 'sound/effects/forge.ogg'
	projectiletype = /obj/item/projectile/bloodslash
	move_to_delay = 1
	mob_property_flags = MOB_SUPERNATURAL
	harm_intent_damage = 10
	melee_damage_lower = 15
	melee_damage_upper = 15
	attacktext = "grips"
	attack_sound = 'sound/weapons/rapidslice.ogg'
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0
	minbodytemp = 0
	speed = 5
	supernatural = 1
	faction = "cult"
	flying = 1
	environment_smash_flags = 0
	var/mob/living/simple_animal/construct/builder/perfect/master = null


/mob/living/simple_animal/hostile/hex/New()
	..()

	animate(src, pixel_y = 4 * PIXEL_MULTIPLIER , time = 10, loop = -1, easing = SINE_EASING)
	animate(pixel_y = 2 * PIXEL_MULTIPLIER, time = 10, loop = -1, easing = SINE_EASING)

/mob/living/simple_animal/hostile/hex/proc/setupglow(glowcolor)
	overlays = 0
	var/overlay_layer = ABOVE_LIGHTING_LAYER
	var/overlay_plane = LIGHTING_PLANE
	if(layer != MOB_LAYER) // ie it's hiding
		overlay_layer = FLOAT_LAYER
		overlay_plane = FLOAT_PLANE

	var/icon/glowicon = icon(icon,"glow-[icon_state]")
	glowicon.Blend(glowcolor, ICON_ADD)
	var/image/glow = image(icon = glowicon, layer = overlay_layer)
	glow.plane = overlay_plane
	overlays += glow

/mob/living/simple_animal/hostile/hex/Destroy()
	if (master)
		master.minions.Remove(src)
	master = null
	..()

/mob/living/simple_animal/hostile/hex/Cross(var/atom/movable/mover, var/turf/target, var/height=1.5, var/air_group = 0)
	if(istype(mover, /obj/item/projectile/bloodslash))//stop hitting yourself ffs!
		return 1
	return ..()

/mob/living/simple_animal/hostile/hex/death(var/gibbed = FALSE)
	..(TRUE) //If they qdel, they gib regardless
	for(var/i=0;i<3;i++)
		new /obj/item/weapon/ectoplasm (src.loc)
	visible_message("<span class='warning'>\The [src] collapses in a shattered heap. </span>")
	qdel (src)

/mob/living/simple_animal/hostile/hex/Found(var/atom/the_target)
	if(ismob(the_target))
		var/mob/M = the_target
		if(isanycultist(M))
			return 0
	return ..(the_target)


/mob/living/simple_animal/hostile/hex/CanAttack(var/atom/the_target)
	if(ismob(the_target))
		var/mob/M = the_target
		if(isanycultist(M))
			return 0
	return ..(the_target)

/mob/living/simple_animal/hostile/hex/cultify()
	return
