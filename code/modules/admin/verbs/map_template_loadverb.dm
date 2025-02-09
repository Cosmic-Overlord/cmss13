/client/proc/map_template_load()
	set category = "Admin.Events"
	set name = "Map Template - Place"

	var/datum/map_template/template

	var/map = tgui_input_list(src, "Choose a Map Template to place at your CURRENT LOCATION","Place Map Template", sortList(SSmapping.map_templates))
	if(!map)
		return
	template = SSmapping.map_templates[map]

	var/turf/T = get_turf(mob)
	if(!T)
		return

	var/centered = alert(src, "Do you want this to be created from the center, or from the bottom left corner of your map?", "Spawn Position", "Center", "Bottom Left") == "Center" ? TRUE : FALSE
	var/delete = alert(src, "Do you want to delete atoms in your load area?", "Atom Deletion", "Yes", "No") == "Yes" ? TRUE : FALSE

	var/list/preview = list()
	for(var/S in template.get_affected_turfs(T, centered))
		var/image/item = image('icons/turf/overlays.dmi',S,"greenOverlay")
		item.plane = ABOVE_LIGHTING_PLANE
		preview += item
	images += preview
	if(alert(src,"Confirm location.","Template Confirm","Yes","No") == "Yes")
		if(template.load(T, centered, delete))
			/*var/affected = template.get_affected_turfs(T, centered=TRUE)
			for(var/AT in affected)
				for(var/obj/docking_port/mobile/P in AT)
					if(istype(P, /obj/docking_port/mobile))
						template.post_load(P)
						break*/
			message_admins(SPAN_ADMINNOTICE("[key_name_admin(src)] has placed a map template ([template.name]) at [key_name_admin(T)]"))
		else
			to_chat(src, "Failed to place map", confidential = TRUE)
	images -= preview

/client/proc/map_template_upload()
	set category = "Admin.Events"
	set name = "Map Template - Upload"

	var/map = input(src, "Choose a Map Template to upload to template storage","Upload Map Template") as null|file
	if(!map)
		return
	if(copytext_char("[map]", -4) != ".dmm")//4 == length_char(".dmm")
		to_chat(src, SPAN_WARNING("Filename must end in '.dmm': [map]"), confidential = TRUE)
		return
	var/datum/map_template/M
	switch(alert(src, "What kind of map is this?", "Map type", "Normal", "Cancel")) // TODO: shuttle
		if("Normal")
			M = new /datum/map_template(map, "[map]", TRUE)
		if("Shuttle")
			M = new /datum/map_template/shuttle(map, "[map]", TRUE)
		else
			return
	if(!M.cached_map)
		to_chat(src, SPAN_WARNING("Map template '[map]' failed to parse properly."), confidential = TRUE)
		return

	var/datum/map_report/report = M.cached_map.check_for_errors()
	var/report_link
	if(report)
		report.show_to(src)
		report_link = " - <a href='?src=[REF(report)];show=1'>validation report</a>" // TODO: hreftoken
		to_chat(src, SPAN_WARNING("Map template '[map]' <a href='?src=[REF(report)];show=1'>failed validation</a>."), confidential = TRUE) // TODO: hreftoken
		if(report.loadable)
			var/response = alert(src, "The map failed validation, would you like to load it anyways?", "Map Errors", "Cancel", "Upload Anyways")
			if(response != "Upload Anyways")
				return
		else
			alert(src, "The map failed validation and cannot be loaded.", "Map Errors", "Oh Darn")
			return

	SSmapping.map_templates[M.name] = M
	message_admins(SPAN_ADMINNOTICE("[key_name_admin(src)] has uploaded a map template '[map]' ([M.width]x[M.height])[report_link]."))
	to_chat(src, SPAN_NOTICE("Map template '[map]' ready to place ([M.width]x[M.height])"), confidential = TRUE)
