/proc/emoji_parse(text) //turns :ai: into an emoji in text.
	. = text
	if(!CONFIG_GET(flag/emojis))
		return
	var/static/list/emojis = icon_states(icon(EMOJI_SET))
	var/parsed = ""
	var/pos = 1
	var/search = 0
	var/emoji = ""
	while(1)
		search = findtext_char(text, ":", pos)
		parsed += copytext_char(text, pos, search)
		if(search)
			pos = search
			search = findtext_char(text, ":", pos + length_char(text[pos]))
			if(search)
				emoji = lowertext(copytext_char(text, pos + length_char(text[pos]), search))
				var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/chat)
				var/tag = sheet.icon_tag("emoji-[emoji]")
				if(tag)
					parsed += tag
					pos = search + length_char(text[pos])
				else
					parsed += copytext_char(text, pos, search)
					pos = search
				emoji = ""
				continue
			else
				parsed += copytext_char(text, pos, search)
		break
	return parsed

/proc/emoji_sanitize(text) //cuts any text that would not be parsed as an emoji
	. = text
	if(!CONFIG_GET(flag/emojis))
		return
	var/static/list/emojis = icon_states(icon(EMOJI_SET))
	var/final = "" //only tags are added to this
	var/pos = 1
	var/search = 0
	while(1)
		search = findtext_char(text, ":", pos)
		if(search)
			pos = search
			search = findtext_char(text, ":", pos + length_char(text[pos]))
			if(search)
				var/word = lowertext(copytext_char(text, pos + length_char(text[pos]), search))
				if(word in emojis)
					final += lowertext(copytext_char(text, pos, search + length_char(text[search])))
				pos = search + length_char(text[search])
				continue
		break
	return final
