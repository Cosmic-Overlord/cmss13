/*
 * Holds procs designed to help with filtering text
 * Contains groups:
 * SQL sanitization
 * Text sanitization
 * Text searches
 * Text modification
 * Misc
 */


/*
 * Text sanitization
 */

//Simply removes < and > and limits the length_char of the message
/proc/strip_html_simple(t, limit=MAX_MESSAGE_LEN)
	var/list/strip_chars = list("<",">")
	t = copytext_char(t,1,limit)
	for(var/char in strip_chars)
		var/index = findtext_char(t, char)
		while(index)
			t = copytext_char(t, 1, index) + copytext_char(t, index+1)
			index = findtext_char(t, char)
	return t

//Removes a few problematic characters
/proc/sanitize_simple(text, list/repl_chars = list("\n"=" ","\t"=" ","�"=" "))
	for(var/char in repl_chars)
		text = replacetext_char(text, char, repl_chars[char])
	return text

/proc/readd_quotes(text)
	var/list/repl_chars = list("&#34;" = "\"", "&#39;" = "'")
	for(var/char in repl_chars)
		text = replacetext_char(text, char, repl_chars[char])
	return text

//Runs byond's sanitization proc along-side sanitize_simple
/proc/sanitize(input, list/repl_chars = list("\n"=" ","\t"=" ","�"=" "))
	var/output = html_encode(sanitize_simple(input, repl_chars))
	return readd_quotes(output)

//Runs byond's sanitization proc along-side strip_improper
/proc/sanitize_area(input)
	var/output = html_encode(strip_improper(input))
	return readd_quotes(output)

//Removes control chars like "\n"
/proc/sanitize_control_chars(text)
	var/static/regex/whitelistedWords = regex(@{"([^\u0020-\u8000]+)"}, "g")
	return whitelistedWords.Replace(text, "")

//Runs sanitize and strip_html_simple
//I believe strip_html_simple() is required to run first to prevent '<' from displaying as '&lt;' after sanitize() calls byond's html_encode()
/proc/strip_html(text, limit=MAX_MESSAGE_LEN)
	return copytext_char((sanitize(strip_html_simple(text))), 1, limit)

//Runs byond's sanitization proc along-side strip_html_simple
//I believe strip_html_simple() is required to run first to prevent '<' from displaying as '&lt;' that html_encode() would cause
/proc/adminscrub(text, limit=MAX_MESSAGE_LEN)
	return copytext_char((html_encode(strip_html_simple(text))), 1, limit)

//Returns null if there is any bad text in the string
/proc/reject_bad_text(text, max_length=512)
	if(length_char(text) > max_length) return //message too long
	var/non_whitespace = 0
	for(var/i=1, i<=length_char(text), i++)
		switch(text2ascii(text,i))
			if(62,60,92,47) return //rejects the text if it contains these bad characters: <, >, \ or /
			if(127 to 255) return //rejects weird letters like �
			if(0 to 31) return //more weird stuff
			if(32) continue //whitespace
			else non_whitespace = 1
	if(non_whitespace) return text //only accepts the text if it has some non-spaces

// Used to get a sanitized input.
/proc/stripped_input(mob/user, message = "", title = "", default = "", max_length=MAX_MESSAGE_LEN)
	var/name = input(user, message, title, default) as text|null
	return html_encode(trim(name, max_length))

// Used to get a properly sanitized multiline input, of max_length
/proc/stripped_multiline_input(mob/user, message = "", title = "", default = "", max_length=MAX_MESSAGE_LEN)
	var/name = input(user, message, title, default) as message|null
	return html_encode(trim(name, max_length))

//Filters out undesirable characters from names
/proc/reject_bad_name(t_in, allow_numbers = 0, max_length = MAX_NAME_LEN, allow_signs = TRUE)
	if(!t_in || length_char(t_in) > max_length)
		return //Rejects the input if it is null or if it is longer then the max length_char allowed

	var/number_of_alphanumeric = 0
	var/last_char_group = 0
	var/t_out = ""

	for(var/i=1, i<=length_char(t_in), i++)
		var/ascii_char = text2ascii(t_in,i)
		switch(ascii_char)
			// A  .. Z
			if(65 to 90) //Uppercase Letters
				t_out += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// a  .. z
			if(97 to 122) //Lowercase Letters
				if(last_char_group<2)
					t_out += ascii2text(ascii_char-32) //Force uppercase first character
				else
					t_out += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// 0  .. 9
			if(48 to 57) //Numbers
				if(!last_char_group || !allow_numbers) //suppress at start of string
					continue
				t_out += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 3

			// '  -  .
			if(39,45,46) //Common name punctuation
				if(!last_char_group || !allow_signs)
					continue
				t_out += ascii2text(ascii_char)
				last_char_group = 2

			// ~  |  @  :  #  $  %  &  *  +
			if(126,124,64,58,35,36,37,38,42,43) //Other symbols that we'll allow (mainly for AI)
				if(!last_char_group || !allow_numbers || !allow_signs) //suppress at start of string
					continue
				t_out += ascii2text(ascii_char)
				last_char_group = 2

			//Space
			if(32)
				if(last_char_group <= 1)
					continue //suppress double-spaces and spaces at start of string
				t_out += ascii2text(ascii_char)
				last_char_group = 1
			else
				return

	if(number_of_alphanumeric < 2)
		return //protects against tiny names like "A" and also names like "' ' ' ' ' ' ' '"

	if(last_char_group == 1)
		t_out = copytext_char(t_out,1,length_char(t_out)) //removes the last character (in this case a space)

	for(var/bad_name in list("space","floor","wall","r-wall","monkey","unknown","inactive ai")) //prevents these common metagamey names
		if(cmptext(t_out,bad_name))
			return //(not case sensitive)

	return t_out

/*
 * Text searches
 */

//Adds 'u' number of zeros ahead of the text 't'
/proc/add_zero(t, u)
	while (length_char(t) < u)
		t = "0[t]"
	return t

//Adds 'u' number of spaces ahead of the text 't'
/proc/add_lspace(t, u)
	while(length_char(t) < u)
		t = " [t]"
	return t

//Adds 'u' number of spaces behind the text 't'
/proc/add_tspace(t, u)
	while(length_char(t) < u)
		t = "[t] "
	return t

//Returns a string with reserved characters and spaces before the first letter removed
/proc/trim_left(text)
	for (var/i in 1 to length_char(text))
		if (text2ascii(text, i) > 32)
			return copytext_char(text, i)
	return ""

//Returns a string with reserved characters and spaces after the last letter removed
/proc/trim_right(text)
	for (var/i in length_char(text) to 1 step -1)
		if (text2ascii(text, i) > 32)
			return copytext_char(text, 1, i + 1)

	return ""

//Returns a string with reserved characters and spaces before the first word and after the last word removed.
/proc/trim(text)
	return trim_left(trim_right(text))

//Returns a string with the first element of the string capitalized.
/proc/capitalize(t as text)
	return uppertext(copytext_char(t, 1, 2)) + copytext_char(t, 2)

/proc/stringpercent(text,character = "*")
//This proc returns the number of chars of the string that is the character
//This is used for detective work to determine fingerprint completion.
	if(!text || !character)
		return 0
	var/count = 0
	for(var/i = 1, i <= length_char(text), i++)
		var/a = copytext_char(text,i,i+1)
		if(a == character)
			count++
	return count

/proc/reverse_text(text = "")
	var/new_text = ""
	for(var/i = length_char(text); i > 0; i--)
		new_text += copytext_char(text, i, i+1)
	return new_text

//Used in preferences' SetFlavorText and human's set_flavor verb
//Previews a string of len or less length_char
/proc/TextPreview(string, len=40)
	var/string_length = length_char(string)
	if(!string_length)
		return "\[...\]"
	else if(string_length <= len)
		return string
	else
		return "[copytext_char(string, 1, len - 3)]..."

/proc/strip_improper(input_text)
	return replacetext_char(replacetext_char(input_text, "\proper", ""), "\improper", "")

// Used to remove the string shortcuts for a clean transfer
/proc/sanitize_filename(t)
	return sanitize_simple(t, list("\n"="", "\t"="", "/"="", "\\"="", "?"="", "%"="", "*"="", ":"="", "|"="", "\""="", "<"="", ">"=""))

/proc/deep_string_equals(A, B)
	if(length_char(A) != length_char(B))
		return FALSE
	for(var/i = 1 to length_char(A))
		if (text2ascii(A, i) != text2ascii(B, i))
			return FALSE
	return TRUE

//Used for applying byonds text macros to strings that are loaded at runtime
/proc/apply_text_macros(string)
	var/next_backslash = findtext_char(string, "\\")
	if(!next_backslash)
		return string

	var/leng = length_char(string)

	var/next_space = findtext_char(string, " ", next_backslash + 1)
	if(!next_space)
		next_space = leng - next_backslash

	if(!next_space) //trailing bs
		return string

	var/base = next_backslash == 1 ? "" : copytext_char(string, 1, next_backslash)
	var/macro = lowertext(copytext_char(string, next_backslash + 1, next_space))
	var/rest = next_backslash > leng ? "" : copytext_char(string, next_space + 1)

	//See http://www.byond.com/docs/ref/info.html#/DM/text/macros
	switch(macro)
		//prefixes/agnostic
		if("the")
			rest = text("\the []", rest)
		if("a")
			rest = text("\a []", rest)
		if("an")
			rest = text("\an []", rest)
		if("proper")
			rest = text("\proper []", rest)
		if("improper")
			rest = text("\improper []", rest)
		if("roman")
			rest = text("\roman []", rest)
		//postfixes
		if("th")
			base = text("[]\th", rest)
		if("s")
			base = text("[]\s", rest)
		if("he")
			base = text("[]\he", rest)
		if("she")
			base = text("[]\she", rest)
		if("his")
			base = text("[]\his", rest)
		if("himself")
			base = text("[]\himself", rest)
		if("herself")
			base = text("[]\herself", rest)
		if("hers")
			base = text("[]\hers", rest)

	. = base
	if(rest)
		. += .(rest)
// Returns the location of the atom as a string in the following format:
// "Area Name (X, Y, Z)"
// Mainly used for logging
/proc/get_location_in_text(atom/A, include_jmp_link = TRUE)
	var/message
	if(!A.loc)
		message = "Invalid location"
	else
		if(include_jmp_link)
			message = "<a HREF='?_src_=admin_holder;[HrefToken(forceGlobal = TRUE)];adminplayerobservecoodjump=1;X=[A.x];Y=[A.y];Z=[A.z]'>[get_area(A)]</a> ([A.x], [A.y], [A.z])"
		else
			message = "[get_area(A)] ([A.x], [A.y], [A.z])"
	return message

//Adds 'char' ahead of 'text' until there are 'count' characters total
/proc/add_leading(text, count, char = " ")
	var/charcount = count - length_char(text)
	var/list/chars_to_add[max(charcount + 1, 0)]
	return jointext(chars_to_add, char) + text

/// Finds the first letter of each word in the provided string and capitalize them
/proc/capitalize_first_letters(string)
	var/list/text = splittext_char(string, " ")
	var/list/finalized_text = list()
	for(var/word in text)
		finalized_text += capitalize(word)
	return jointext(finalized_text, " ")

// Aurorastation Markup System
// For processing simple markup, similar to what Skype and Discord use.
// Enabled from a config setting.
/proc/process_chat_markup(message, list/ignore_tags = list())
	if (!message)
		return ""

	// ---Begin URL caching.
	var/list/urls = list()
	var/i = 1
	while (url_find_lazy.Find(message))
		urls["\ref[urls]-[i]"] = url_find_lazy.match
		i++

	for (var/ref in urls)
		message = replacetextEx_char(message, urls[ref], ref)
	// ---End URL caching

	var/regex/tag_markup
	for (var/tag in (markup_tags - ignore_tags))
		tag_markup = markup_regex[tag]
		message = tag_markup.Replace_char(message, "$2[markup_tags[tag][1]]$3[markup_tags[tag][2]]$5")

	// ---Unload URL cache
	for (var/ref in urls)
		message = replacetextEx_char(message, ref, urls[ref])

	return message

#define SMALL_FONTS(FONTSIZE, MSG) "<span style=\"font-family: 'Small Fonts'; -dm-text-outline: 1 black; font-size: [FONTSIZE]px;\">[MSG]</span>"
#define SMALL_FONTS_CENTRED(FONTSIZE, MSG) "<center><span style=\"font-family: 'Small Fonts'; -dm-text-outline: 1 black; font-size: [FONTSIZE]px;\">[MSG]</span></center>"
#define SMALL_FONTS_COLOR(FONTSIZE, MSG, COLOR) "<span style=\"font-family: 'Small Fonts'; -dm-text-outline: 1 black; font-size: [FONTSIZE]px; color: [COLOR];\">[MSG]</span>"

//finds the first occurrence of one of the characters from needles argument inside haystack
//it may appear this can be optimised, but it really can't. findtext_char() is so much faster than anything you can do in byondcode.
//stupid byond :(
/proc/findchar(haystack, needles, start=1, end=0)
	var/char = ""
	var/len = length_char(needles)
	for(var/i = 1, i <= len, i += length_char(char))
		char = needles[i]
		. = findtextEx(haystack, char, start, end)
		if(.)
			return
	return 0
