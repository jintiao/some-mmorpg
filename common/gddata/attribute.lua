local health_max = {
	warrior = {
		[1] = 100,
		[2] = 300,
		[3] = 500,
	},

	mage = {
		[1] = 80,
		[2] = 160,
		[3] = 240,
	},
}

local strength = {
	human = {
		[1] = 22,
		[2] = 24,
		[3] = 26,
	},
	orc = {
		[1] = 24,
		[2] = 27,
		[3] = 30,
	},
}

local stamina = {
	human = {
		[1] = 21,
		[2] = 23,
		[3] = 25,
	},
	orc = {
		[1] = 23,
		[2] = 26,
		[3] = 29,
	},
}

local attribute = {
	health_max = health_max,
	strength = strength,
	stamina = stamina,
}


return attribute
