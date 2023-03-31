/var/create_mob_html = null
/datum/admins/proc/create_mob(mob/user)
	if (!create_mob_html)
		var/mobjs = null
		mobjs = jointext(typesof(/mob), ";")
		create_mob_html = file2text('html/create_object.html')
		create_mob_html = replacetext_char(create_mob_html, "null /* object types */", "\"[mobjs]\"")
		create_mob_html = replacetext_char(create_mob_html, "/* href token */", RawHrefToken(forceGlobal = TRUE))

	show_browser(user, replacetext_char(create_mob_html, "/* ref src */", "\ref[src]"), "Create Mob", "create_mob", "size=425x475")
