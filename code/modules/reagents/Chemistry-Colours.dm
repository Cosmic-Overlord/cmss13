/proc/mix_color_from_reagents(list/reagent_list)
	if(!reagent_list || !length_char(reagent_list))
		return 0

	var/contents = length_char(reagent_list)
	var/list/weight = new /list(contents)
	var/list/redcolor = new /list(contents)
	var/list/greencolor = new /list(contents)
	var/list/bluecolor = new /list(contents)
	var/i

	//fill the list of weights
	for(i=1; i<=contents; i++)
		var/datum/reagent/re = reagent_list[i]
		var/reagentweight = re.volume
		if(istype(re, /datum/reagent/paint))
			reagentweight *= 20 //Paint colours a mixture twenty times as much
		weight[i] = max(reagentweight,1)


	//fill the lists of colours
	for(i=1; i<=contents; i++)
		var/datum/reagent/re = reagent_list[i]
		var/hue = re.color
		if(length_char(hue) != 7)
			return 0
		redcolor[i]=hex2num(copytext_char(hue,2,4))
		greencolor[i]=hex2num(copytext_char(hue,4,6))
		bluecolor[i]=hex2num(copytext_char(hue,6,8))

	//mix all the colors
	var/red = mixOneColor(weight,redcolor)
	var/green = mixOneColor(weight,greencolor)
	var/blue = mixOneColor(weight,bluecolor)

	//assemble all the pieces
	var/finalcolor = rgb(red, green, blue)
	return finalcolor

/proc/mixOneColor(list/weight, list/color)
	if (!weight || !color || length_char(weight)!=length_char(color))
		return 0

	var/contents = length_char(weight)
	var/i

	//normalize weights
	var/listsum = 0
	for(i=1; i<=contents; i++)
		listsum += weight[i]
	for(i=1; i<=contents; i++)
		weight[i] /= listsum

	//mix them
	var/mixedcolor = 0
	for(i=1; i<=contents; i++)
		mixedcolor += weight[i]*color[i]
	mixedcolor = round(mixedcolor)

	//until someone writes a formal proof for this algorithm, let's keep this in
// if(mixedcolor<0x00 || mixedcolor>0xFF)
// return 0
	//that's not the kind of operation we are running here, nerd
	mixedcolor=min(max(mixedcolor,0),255)

	return mixedcolor

/proc/mix_burn_colors(list/reagent_list)
	var/contents = length_char(reagent_list)
	var/list/weight = new /list(contents)
	var/list/redcolor = new /list(contents)
	var/list/greencolor = new /list(contents)
	var/list/bluecolor = new /list(contents)

	for(var/i in 1 to contents)
		//fill the list of weights
		var/datum/reagent/re = reagent_list[i]
		weight[i] = max(re.volume,1) * re.burncolormod
		//fill the lists of colours
		var/hue = re.burncolor
		if(length_char(hue) != 7)
			return 0
		redcolor[i]=hex2num(copytext_char(hue,2,4))
		greencolor[i]=hex2num(copytext_char(hue,4,6))
		bluecolor[i]=hex2num(copytext_char(hue,6,8))

	//mix all the colors
	var/red = mixOneColor(weight,redcolor)
	var/green = mixOneColor(weight,greencolor)
	var/blue = mixOneColor(weight,bluecolor)

	//assemble all the pieces
	var/finalcolor = rgb(red, green, blue)
	return finalcolor

