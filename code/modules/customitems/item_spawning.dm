//switch this out to use a database at some point
//list of ckey/ real_name and item paths
//gives item to specific people when they join if it can
//for multiple items just add mutliple entries, unless i change it to be a listlistlist
//yes, it has to be an item, you can't pick up nonitems

GLOBAL_LIST_FILE_LOAD(custom_items, "config/custom_items.txt")

/proc/EquipCustomItems(mob/living/carbon/human/M)
	for(var/line in GLOB.custom_items)
		// split & clean up
		var/list/Entry = splittext_char(line, ":")
		for(var/i = 1 to Entry.len)
			Entry[i] = trim(Entry[i])

		if(Entry.len < 3)
			continue;

		if(Entry[1] == M.ckey && Entry[2] == M.real_name)
			var/list/Paths = splittext_char(Entry[3], ",")
			for(var/P in Paths)
				var/ok = 0  // 1 if the item was placed successfully
				P = trim(P)
				var/path = text2path(P)
				if(!path) continue

				var/obj/item/Item = new path()
				if(istype(Item,/obj/item/card/id))
					var/obj/item/card/id/I = Item
					for(var/obj/item/card/id/C in M)
						//default settings
						I.name = "[M.real_name]'s ID Card ([M.job])"
						I.registered_name = M.real_name
						I.registered_ref = WEAKREF(M)
						I.registered_gid = M.gid
						I.access = C.access
						I.assignment = C.assignment
						I.blood_type = C.blood_type
						//replace old ID
						qdel(C)
						ok = M.equip_if_possible(I, WEAR_ID, 0) //if 1, last argument deletes on fail
						break
				else if(istype(Item,/obj/item/storage/belt))
					var/obj/item/storage/belt/I = Item
					if(istype(M.belt,/obj/item/storage/belt))
						qdel(M.belt)
						M.belt=null
						ok = M.equip_if_possible(I, WEAR_WAIST, 0)
						break
				else
					for(var/obj/item/storage/S in M.contents) // Try to place it in any item that can store stuff, on the mob.
						if (S.handle_item_insertion(Item, TRUE))
							ok = 1
							break

				if (ok == 0) // Finally, since everything else failed, place it on the ground
					Item.forceMove(get_turf(M.loc))
