/mob/living/silicon/say_quote(text)
	var/ending = copytext_char(text, length_char(text))

	if (ending == "?")
		return speak_query
	else if (ending == "!")
		return speak_exclamation

	return speak_statement

#define IS_AI 1
#define IS_ROBOT 2

/mob/living/silicon/say_understands(mob/other, datum/language/speaking = null)
	//These only pertain to common. Languages are handled by mob/say_understands()
	if (!speaking)
		if (istype(other, /mob/living/carbon))
			return 1
		if (isSilicon(other))
			return 1
		if (istype(other, /mob/living/brain))
			return 1
	return ..()

/mob/living/silicon/say(message)
	if (!message)
		return

	if (src.client)
		if(client.prefs.muted & MUTE_IC)
			to_chat(src, SPAN_DANGER("You cannot send IC messages (muted)."))
			return
		if (src.client.handle_spam_prevention(message,MUTE_IC))
			return

	message = trim(strip_html(message))

	if (stat == 2)
		return say_dead(message)

	if(copytext_char(message,1,2) == "*")
		if(!findtext_char(message, "*", 2)) //Second asterisk means it is markup for *bold*, not an *emote.
			return emote(lowertext(copytext_char(message,2)))

	var/bot_type = 0 //Let's not do a fuck ton of type checks, thanks.
	if(isAI(src))
		bot_type = IS_AI
	else if(isrobot(src))
		bot_type = IS_ROBOT

	var/mob/living/silicon/ai/AI = src //and let's not declare vars over and over and over for these guys.
	var/mob/living/silicon/robot/R = src

	//Must be concious to speak
	if (stat)
		return

	var/verb = say_quote(message)

	//parse radio key and consume it
	var/message_mode = parse_message_mode(message, "general")
	if (message_mode)
		if (message_mode == "general")
			message = trim(copytext_char(message,2))
		else
			message = trim(copytext_char(message,3))

	//parse language key and consume it
	var/datum/language/speaking = parse_language(message)
	if (speaking)
		verb = speaking.speech_verb
		message = copytext_char(message,3)

		if(speaking.flags & HIVEMIND)
			speaking.broadcast(src,trim(message))
			return

	// Currently used by drones.
	if(local_transmit)
		var/list/listeners = hearers(5,src)
		listeners |= src

		for(var/mob/living/silicon/D in listeners)
			if(D.client && istype(D,src.type))
				to_chat(D, "<b>[src]</b> transmits, \"[message]\"")

		for (var/mob/M in GLOB.player_list)
			if (istype(M, /mob/new_player))
				continue
			else if((M.stat == DEAD || isobserver(M)) &&  M.client.prefs.toggles_chat & CHAT_GHOSTEARS)
				if(M.client) to_chat(M, "<b>[src]</b> transmits, \")[message]\"")
		return

	if(message_mode && bot_type == IS_ROBOT && !R.is_component_functioning("radio"))
		to_chat(src, SPAN_DANGER("Your radio isn't functional at this time."))
		return

	switch(message_mode)
		if("department")
			switch(bot_type)
				if(IS_AI)
					return AI.holopad_talk(message)
				if(IS_ROBOT)
					log_say("[key_name(src)] : [message]")
					R.radio.talk_into(src,message,message_mode,verb,speaking)
			return 1

		if("general")
			switch(bot_type)
				if(IS_AI)
					if (AI.aiRadio.disabledAi)
						to_chat(src, SPAN_DANGER("System Error - Transceiver Disabled"))
						return
					else
						log_say("[key_name(src)] : [message]")
						AI.aiRadio.talk_into(src,message,null,verb,speaking)
				if(IS_ROBOT)
					log_say("[key_name(src)] : [message]")
					R.radio.talk_into(src,message,null,verb,speaking)
			return 1

		else
			if(message_mode)
				switch(bot_type)
					if(IS_AI)
						if (AI.aiRadio.disabledAi)
							to_chat(src, SPAN_DANGER("System Error - Transceiver Disabled"))
							return
						else
							log_say("[key_name(src)] : [message]")
							AI.aiRadio.talk_into(src,message,message_mode,verb,speaking)
					if(IS_ROBOT)
						log_say("[key_name(src)] : [message]")
						R.radio.talk_into(src,message,message_mode,verb,speaking)
				return 1

	return ..(message,speaking,verb)

//For holopads only. Usable by AI.
/mob/living/silicon/ai/proc/holopad_talk(message)

	log_say("[key_name(src)] : [message]")

	message = trim(message)

	if (!message)
		return

	var/obj/structure/machinery/hologram/holopad/T = src.holo
	if(T && T.hologram && T.master == src)//If there is a hologram and its master is the user.
		var/verb = say_quote(message)

		//Human-like, sorta, heard by those who understand humans.
		var/rendered_a = "<span class='game say'><span class='name'>[name]</span> [verb], <span class='message'>\"[message]\"</span></span>"
		//Speach distorted, heard by those who do not understand AIs.
		var/message_stars = stars(message)

		var/rendered_b = "<span class='game say'><span class='name'>[voice_name]</span> [verb], <span class='message'>\"[message_stars]\"</span></span>"

		to_chat(src, "<i><span class='game say'>Holopad transmitted, <span class='name'>[real_name]</span> [verb], <span class='message'>[message]</span></span></i>")//The AI can "hear" its own message.
		for(var/mob/M in hearers(T.loc))//The location is the object, default distance.
			if(M.say_understands(src))//If they understand AI speak. Humans and the like will be able to.
				M.show_message(rendered_a, SHOW_MESSAGE_AUDIBLE)
			else//If they do not.
				M.show_message(rendered_b, SHOW_MESSAGE_AUDIBLE)
		/*Radios "filter out" this conversation channel so we don't need to account for them.
		This is another way of saying that we won't bother dealing with them.*/
	else
		to_chat(src, "No holopad connected.")
		return
	return 1

#undef IS_AI
#undef IS_ROBOT
