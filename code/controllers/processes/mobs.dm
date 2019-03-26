datum/controller/process/mobs

datum/controller/process/mobs/setup()
	name = "Other Mobs"
	schedule_interval = 20 //2 seconds
	own_data = living_misc_mobs

datum/controller/process/mobs/doWork()

	for(var/mob/living/L in living_misc_mobs)
		if(L)
			L.Life()
			individual_ticks++
			continue
		living_misc_mobs -= L
