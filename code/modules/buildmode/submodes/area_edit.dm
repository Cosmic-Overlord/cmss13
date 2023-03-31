/datum/buildmode_mode/area_edit
	key = "areaedit"
	help = "Left Mouse Button on obj/turf/mob = Select corner\n\
	Left Mouse Button + Alt on turf/obj/mob = Paint area/span>\n\
	Right Mouse Button on obj/turf/mob = Select area to paint\n\
	Right Mouse Button on buildmode button = Create new area"
	use_corner_selection = TRUE
	var/area/storedarea
	var/image/areaimage

/datum/buildmode_mode/area_edit/New()
	areaimage = image('icons/turf/overlays.dmi', null, "yellow")
	..()

/datum/buildmode_mode/area_edit/enter_mode(datum/buildmode/BM)
	BM.holder.images += areaimage

/datum/buildmode_mode/area_edit/exit_mode(datum/buildmode/BM)
	areaimage.loc = null // de-color the area
	BM.holder.images -= areaimage
	return ..()

/datum/buildmode_mode/area_edit/Destroy()
	QDEL_NULL(areaimage)
	storedarea = null
	return ..()

/datum/buildmode_mode/area_edit/change_settings(client/c)
	var/target_path = input(c, "Enter typepath:", "Typepath", "/area")
	var/areatype = text2path(target_path)
	if(ispath(areatype,/area))
		var/areaname = input(c, "Enter area name:", "Area name", "Area")
		if(!areaname || !length_char(areaname))
			return
		storedarea = new areatype
		storedarea.power_equip = 0
		storedarea.power_light = 0
		storedarea.power_environ = 0
		storedarea.always_unpowered = 0
		storedarea.name = areaname
		areaimage.loc = storedarea // color our area

/datum/buildmode_mode/area_edit/when_clicked(client/c, params, object)
	var/list/modifiers = params2list(params)

	if(LAZYACCESS(modifiers, LEFT_CLICK))
		if(!storedarea)
			to_chat(c, SPAN_WARNING("Configure or select the area you want to paint first!"))
			return
		if(LAZYACCESS(modifiers, ALT_CLICK))
			var/turf/T = get_turf(object)
			if(get_area(T) != storedarea)
				log_admin("Build Mode: [key_name(c)] added [AREACOORD(T)] to [storedarea]")
				storedarea.contents.Add(T)
			return
		return ..()
	else if(LAZYACCESS(modifiers, RIGHT_CLICK))
		var/turf/T = get_turf(object)
		storedarea = get_area(T)
		areaimage.loc = storedarea // color our area

/datum/buildmode_mode/area_edit/handle_selected_area(client/c, params)
	var/list/modifiers = params2list(params)

	if(LAZYACCESS(modifiers, LEFT_CLICK))
		var/choice = alert("Are you sure you want to fill area?", "Area Fill Confirmation", "Yes", "No")
		if(choice != "Yes")
			return
		for(var/turf/T in block(get_turf(cornerA),get_turf(cornerB)))
			storedarea.contents.Add(T)
		log_admin("Build Mode: [key_name(c)] set the area of the region from [AREACOORD(cornerA)] through [AREACOORD(cornerB)] to [storedarea].")

