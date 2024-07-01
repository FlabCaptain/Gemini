-- GEMINI - Super Gem Fighter Mini Mix Training Mode - v1.06

-- Here are some command keys you might want to remap.

local SWAP_KEY = 'enter'
local MODE_KEY = 'space'
local RECORD_KEY = 'home'
local PLAY_KEY = 'end'
local PREVIOUS_SLOT_KEY = 'pagedown'
local NEXT_SLOT_KEY = 'pageup'
local CLEAR_SLOT_KEY = 'delete'
local TOGGLE_DUMMY_TURBO_KEY = 'home'
local CYCLE_FIRST_DUMMY_ACTION_KEY = 'pagedown'
local CYCLE_SECOND_DUMMY_ACTION_KEY = 'pageup'
local CYCLE_FIRST_ITEM_KEY = '1'
local CYCLE_SECOND_ITEM_KEY = '2'
local CYCLE_THIRD_ITEM_KEY = '3'
local TOGGLE_STUN_KEY = '5'
local CYCLE_RED_GEMS_KEY = '7'
local CYCLE_YELLOW_GEMS_KEY = '8'
local CYCLE_BLUE_GEMS_KEY = '9'
local CYCLE_INPUT_DELAY_KEY = 'quote'
local TOGGLE_BACKGROUND_MUSIC_KEY = 'semicolon'
local TOGGLE_HISTORY_KEY = 'leftbracket'
local TOGGLE_INFO_KEY = 'rightbracket'
local TOGGLE_HITBOXES_KEY = 'backslash'

-- And here are some settings you might want to change.

local UI_COLOR = 0x0000008F
local UI_TRANSPARENCY = true
local HITBOX_DRAW_DELAY = 2
local NUM_SLOTS = 8
local RANDOM_SLOT_PLAYBACK = false
local PLAYBACK_TURNAROUND = false
local LOAD_ON_START = false
local SAVE_ON_EXIT = false

-- OK, you probably don't want to change anything below this point.

local re, gr = memory.registerexec, memory.getregister
local rb, rw, rws, rd = memory.readbyte, memory.readword, memory.readwordsigned, memory.readdword
local wb, wba, ww = memory.writebyte, memory.writebyte_audio, memory.writeword

local DEFAULT, RECORDING, PLAYBACK, DUMMY = 1, 2, 3, 4
local START, UP, DOWN, LEFT, RIGHT, PUNCH, KICK, SPECIAL = 1, 2, 3, 4, 5, 6, 7, 8
local INPUTS = { 'Start', 'Up', 'Down', 'Left', 'Right', 'Punch', 'Kick', 'Special' }
local PLAYER_INPUTS = {
	{ 'P1 Start', 'P1 Up', 'P1 Down', 'P1 Left', 'P1 Right', 'P1 Punch', 'P1 Kick', 'P1 Special' },
	{ 'P2 Start', 'P2 Up', 'P2 Down', 'P2 Left', 'P2 Right', 'P2 Punch', 'P2 Kick', 'P2 Special' }
}
local BITS = { 128, 64, 32, 16, 8, 4, 2, 1 }
local BASE36 = {
	'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
	'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
}
local boxBuffer, throwBuffer = {}, {}

local MAP = {
	MUSIC =         0xF027,
	SELECTABLE =    0xFF8013,
	STAGE =         0xFF8181,
	TIMER_DISPLAY = 0xFF8188,
	TIMER_VALUE =   0xFF8189,
	BASE =        { 0xFF8400, 0xFF8800 },
	SELECT_TIME = { 0xFF840E, 0xFF880E },
	CHARACTER =   { 0xFF8781, 0xFF8B81 },
	COLOR =       { 0xFF879F, 0xFF8B9F },
	TAUNTS =      { 0xFF8561, 0xFF8961 },
	HEALTH =      { 0xFF8441, 0xFF8841 },
	METER =       { 0xFF8594, 0xFF8994 },
	STUN =        { 0xFF857F, 0xFF897F },
	STUN_MAX =    { 0xFF859E, 0xFF899E },
	STUN_STATE =  { 0xFF8405, 0xFF8805 },
	STATE =       { 0xFF8406, 0xFF8806 },
	AIR_ATTACK =  { 0xFF8407, 0xFF8807 },
	LOW_FLAG =    { 0xFF851E, 0xFF891E },
	IBUKI_LOW_1 = { 0xFF8493, 0xFF8893 },
	IBUKI_LOW_2 = { 0xFF8496, 0xFF8896 },
	PROJECTILE =  { 0xFF8549, 0xFF8949 },
	GEMS =        { { 0xFF85A3, 0xFF85A5, 0xFF85A7 }, { 0xFF89A3, 0xFF89A5, 0xFF89A7 } },
	SPECIALS =    { { 0xFF858A, 0xFF858B, 0xFF858C }, { 0xFF898A, 0xFF898B, 0xFF898C } },
	ITEMS =       { { 0xFF85F0, 0xFF85F1, 0xFF85F2 }, { 0xFF89F0, 0xFF89F1, 0xFF89F2 } },
	COMBO =       { 0xFF8944, 0xFF8544 }, -- Switched; easier to think about it this way.
	X =           { 0xFF8410, 0xFF8810 }, -- 2-byte value.
	Y =           { 0xFF8414, 0xFF8814 }  -- 2-byte value.
}

local BOX_COLORS = {
	HURT =      { FILL = 0x7777FF30, STROKE = 0x7777FFFF },
	HIT =       { FILL = 0xFF000030, STROKE = 0xFF0000FF },
	PUSH =      { FILL = 0x00FF0030, STROKE = 0x00FF00FF },
	PROJHURT =  { FILL = 0x00FFFF30, STROKE = 0x00FFFFFF },
	PROJHIT =   { FILL = 0xFF77FF30, STROKE = 0xFF77FFFF },
	PROJPUSH =  { FILL = 0xFF00FF30, STROKE = 0x00FF00FF },
	THROW =     { FILL = 0xFFFF0030, STROKE = 0xFFFF00FF },
	THROWABLE = { FILL = 0xF0F0F030, STROKE = 0xF0F0F0FF },
}

local BOX_STYLES = {
	{ addressOffset = 0x8C, idOffset = 0x93, idShift = 0x3, style = 'PUSH' },
	{ addressOffset = 0x8C, idOffset = 0x0B, idShift = 0x3, style = 'THROWABLE', animationOffset = 0x1C },
	{ addressOffset = 0x80, idOffset = 0x90, idShift = 0x3, style = 'HURT' },
	{ addressOffset = 0x84, idOffset = 0x91, idShift = 0x3, style = 'HURT' },
	{ addressOffset = 0x88, idOffset = 0x92, idShift = 0x5, style = 'HIT' }
}

local CHARACTERS = {
	{ NAME = 'RYU', COLORS = { 'BLUE', 'GRAY', 'MAROON' }, STUN = 40 },
	{ NAME = 'KEN', COLORS = { 'BLUE', 'WHITE', 'GRAY' }, STUN = 40 },
	{ NAME = 'CHUN-LI', COLORS = { 'GRAY', 'PINK', 'GREEN' }, STUN = 40 },
	{ NAME = 'SAKURA', COLORS = { 'PINK', 'GREEN', 'GRAY' }, STUN = 40 },
	{ NAME = 'MORRIGAN', COLORS = { 'BLUE', 'YELLOW', 'GRAY' }, STUN = 40 },
	{ NAME = 'HSIEN-KO', COLORS = { 'BLUE', 'YELLOW', 'GRAY' }, STUN = 45 },
	{ NAME = 'FELICIA', COLORS = { 'YELLOW', 'PINK', 'PURPLE' }, STUN = 35 },
	{ NAME = 'TESSA', COLORS = { 'LIGHT BLUE', 'DARK BLUE', 'RED' }, STUN = 35 },
	{ NAME = 'IBUKI', COLORS = { 'BLACK', 'WHITE', 'RED' }, STUN = 40 },
	{ NAME = 'ZANGIEF', COLORS = { 'TEAL', 'GREEN', 'BROWN' }, STUN = 50 },
	{ NAME = 'DAN', COLORS = { 'BLUE', 'GREEN', 'ORANGE' }, STUN = 35 },
	{ NAME = 'AKUMA', COLORS = { 'GRAY', 'RED', 'BROWN' }, STUN = 30 }
}

local players, buffer, info, history, data, menu = {}, {}, {}, {}, {}, { state = DEFAULT, active = 1, inactive = 2, slot = 1, frame = 0, brightness = 255, ascending = false,
	stun = true, delay = 0, music = true, cleared = false, history = true, info = true, hitboxes = false, turbo = false, live = false, replay = emu.isreplay(), defender = 0, selectable = 0 }

local function beingAttacked()
	return rb(MAP.STATE[menu.active]) == 0xA or rb(MAP.STATE[menu.active]) == 0x12 or rb(MAP.STATE[menu.active]) == 0x18 or
		rb(MAP.STATE[menu.active]) == 0x16 or rb(MAP.STATE[menu.active]) == 0xE or rb(MAP.STATE[menu.active]) == 0x10 or
		(rb(MAP.STATE[menu.active]) == 0x6 and rb(MAP.AIR_ATTACK[menu.active]) == 0x6) or rb(MAP.PROJECTILE[menu.active]) > 0x0 
end

local function isAttackLow()
	return rb(MAP.LOW_FLAG[menu.active]) > 0x0 or (rb(MAP.CHARACTER[menu.active]) == 0x8 and (rb(MAP.IBUKI_LOW_1[menu.active]) == 0x2 or rb(MAP.IBUKI_LOW_2[menu.active]) == 0x7))
end

local function isMorriganOrHsienKo()
	return rb(MAP.CHARACTER[menu.inactive]) == 4 or rb(MAP.CHARACTER[menu.inactive]) == 5
end

local function toward()
	return rw(MAP.X[menu.inactive]) > rw(MAP.X[menu.active]) and LEFT or RIGHT
end

local function away()
	return rw(MAP.X[menu.inactive]) > rw(MAP.X[menu.active]) and RIGHT or LEFT
end

local function getActiveSide()
	return rw(MAP.X[menu.inactive]) > rw(MAP.X[menu.active]) and 'l' or 'r'
end

local function getInactiveSide()
	return rw(MAP.X[menu.inactive]) > rw(MAP.X[menu.active]) and 'r' or 'l'
end

local function press(joy, pressed, ...)
	if pressed then
		for i = 1, select('#', ...) do
			local v = select(i, ...)
			if v then
				joy[PLAYER_INPUTS[menu.inactive][v]] = true
			end
		end
	end
end

-- Table containing the dummy actions.

local dummy = {
	{ name = 'IDLE', action = function(joy) press(joy, math.random(1000000) == 777777, START) end }, -- Easter egg. :)
	{ name = 'BLOCK STANDING', action = function(joy) press(joy, beingAttacked(), away()) end },
	{ name = 'BLOCK CROUCHING', action = function(joy) press(joy, beingAttacked(), away(), DOWN) end },
	{ name = 'BLOCK ALL', action = function(joy) press(joy, beingAttacked(), away(), isAttackLow() and DOWN or nil) end },
	{ name = 'BLOCK RANDOM', action = function(joy) press(joy, beingAttacked(), away(), players[menu.inactive].blockLow and DOWN or nil) end },
	{ name = 'WALK IN', action = function(joy) press(joy, true, toward()) end },
	{ name = 'WALK BACK', action = function(joy) press(joy, true, away()) end },
	{ name = 'DASH IN', action = function(joy) press(joy, emu.framecount() % (menu.turbo and 2 or 14) == 1, toward()) end },
	{ name = 'DASH BACK', action = function(joy) press(joy, emu.framecount() % (menu.turbo and 2 or 14) == 1, away()) end },
	{ name = 'NEUTRAL JUMP', action = function(joy) press(joy, true, UP) end },
	{ name = 'JUMP IN', action = function(joy) press(joy, true, UP, toward()) end },
	{ name = 'JUMP BACK', action = function(joy) press(joy, true, UP, away()) end },
	{ name = 'PUNCH', action = function(joy, pressed) press(joy, pressed, PUNCH) end },
	{ name = 'KICK', action = function(joy, pressed) press(joy, pressed, KICK) end },
	{ name = 'ANTI-AIR', action = function(joy, pressed) press(joy, pressed, PUNCH, DOWN, toward()) end },
	{ name = 'SWEEP', action = function(joy, pressed) press(joy, pressed, KICK, DOWN, not isMorriganOrHsienKo() and toward() or nil) end },
	{ name = 'NORMAL THROW', action = function(joy, pressed) press(joy, pressed, PUNCH, KICK) end },
	{ name = 'BACK THROW', action = function(joy, pressed) press(joy, pressed, PUNCH, KICK, away()) end },
	{ name = 'R. GUARD CANCEL', action = function(joy, pressed) press(joy, pressed, SPECIAL) end },
	{ name = 'Y. GUARD CANCEL', action = function(joy, pressed) press(joy, pressed, SPECIAL, toward()) end },
	{ name = 'B. GUARD CANCEL', action = function(joy, pressed) press(joy, pressed, SPECIAL, DOWN) end },
	{ name = 'GUARD RETURN', action = function(joy, pressed) press(joy, pressed, SPECIAL, away()) end },
	actions = { 1, 4 }
}
dummy[#dummy + 1] = { name = 'RANDOM', action = function(joy, pressed) dummy[math.random(#dummy - 1)].action(joy, pressed) end }

-- Table containing the menu commands.

local commands = { 
	{
		key = SWAP_KEY, joy = 'P1 Coin',
		condition = function() return not menu.replay and (menu.state == DUMMY or menu.state == DEFAULT) end,
		action = function()
			menu.active, menu.inactive = menu.inactive, menu.active
			for i = 1, menu.delay do
				buffer[i] = 0
			end
		end
	},
	{
		key = MODE_KEY, joy = 'Service',
		condition = function() return not menu.replay and menu.live and (menu.state == DUMMY or menu.state == DEFAULT) end,
		action = function() menu.state = menu.state == DEFAULT and DUMMY or DEFAULT end
	},
	{
		key = RECORD_KEY, joy = 'Volume Down',
		condition = function() return not menu.replay and menu.live and (menu.state == RECORDING or menu.state == DEFAULT) end,
		action = function()
			menu.state = menu.state == DEFAULT and RECORDING or DEFAULT
			if menu.state == RECORDING then
				data[menu.slot] = { side = getActiveSide() }
				menu.frame = 0
				menu.brightness = 255
				menu.ascending = false
			end
		end
	},
	{
		key = PLAY_KEY, joy = 'Volume Up',
		condition = function() return not menu.replay and menu.live and (menu.state == PLAYBACK or (menu.state == DEFAULT and #data[menu.slot] > 0)) end,
		action = function()
			menu.state = menu.state == DEFAULT and PLAYBACK or DEFAULT
			if menu.state == PLAYBACK then
				menu.frame = 0
				menu.brightness = 255
				menu.ascending = false
			end
		end
	},
	{
		key = PREVIOUS_SLOT_KEY,
		condition = function() return not menu.replay and menu.live and menu.state == DEFAULT end,
		action = function() menu.slot = menu.slot == 1 and NUM_SLOTS or menu.slot - 1 end
	},
	{
		key = NEXT_SLOT_KEY,
		condition = function() return not menu.replay and menu.live and menu.state == DEFAULT end,
		action = function() menu.slot = menu.slot == NUM_SLOTS and 1 or menu.slot + 1 end
	},
	{
		key = CLEAR_SLOT_KEY,
		condition = function() return not menu.replay and menu.live and menu.state == DEFAULT and #data[menu.slot] > 0 end,
		action = function() data[menu.slot] = {} end
	},
	{
		key = TOGGLE_DUMMY_TURBO_KEY,
		condition = function() return not menu.replay and menu.live and menu.state == DUMMY end,
		action = function() menu.turbo = not menu.turbo end
	},
	{
		key = CYCLE_FIRST_DUMMY_ACTION_KEY, joy = 'Volume Down',
		condition = function() return not menu.replay and menu.live and menu.state == DUMMY end,
		action = function() dummy.actions[1] = dummy.actions[1] == #dummy and 1 or dummy.actions[1] + 1 end
	},
	{
		key = CYCLE_SECOND_DUMMY_ACTION_KEY, joy = 'Volume Up',
		condition = function() return not menu.replay and menu.live and menu.state == DUMMY end,
		action = function() dummy.actions[2] = dummy.actions[2] == #dummy and 1 or dummy.actions[2] + 1 end
	},
	{
		key = CYCLE_FIRST_ITEM_KEY,
		condition = function() return not menu.replay and menu.live end,
		action = function() wb(MAP.ITEMS[menu.active][1], rb(MAP.ITEMS[menu.active][1]) == 6 and 1 or rb(MAP.ITEMS[menu.active][1]) + 1) end
	},
	{
		key = CYCLE_SECOND_ITEM_KEY,
		condition = function() return not menu.replay and menu.live end,
		action = function() wb(MAP.ITEMS[menu.active][2], rb(MAP.ITEMS[menu.active][2]) == 6 and 1 or rb(MAP.ITEMS[menu.active][2]) + 1) end
	},
	{
		key = CYCLE_THIRD_ITEM_KEY,
		condition = function() return not menu.replay and menu.live end,
		action = function() wb(MAP.ITEMS[menu.active][3], rb(MAP.ITEMS[menu.active][3]) == 6 and 1 or rb(MAP.ITEMS[menu.active][3]) + 1) end
	},
	{
		key = TOGGLE_STUN_KEY,
		condition = function() return not menu.replay and menu.live end,
		action = function() menu.stun = not menu.stun end
	},
	{
		key = CYCLE_RED_GEMS_KEY,
		condition = function() return not menu.replay and menu.live end,
		action = function() players[menu.active].gems[1] = players[menu.active].gems[1] == 2 and 0 or players[menu.active].gems[1] + 1 end
	},
	{
		key = CYCLE_YELLOW_GEMS_KEY,
		condition = function() return not menu.replay and menu.live end,
		action = function() players[menu.active].gems[2] = players[menu.active].gems[2] == 2 and 0 or players[menu.active].gems[2] + 1 end
	},
	{
		key = CYCLE_BLUE_GEMS_KEY,
		condition = function() return not menu.replay and menu.live end,
		action = function() players[menu.active].gems[3] = players[menu.active].gems[3] == 2 and 0 or players[menu.active].gems[3] + 1 end
	},
	{
		key = CYCLE_INPUT_DELAY_KEY,
		condition = function() return not menu.replay end,
		action = function()
			menu.delay = menu.delay == 7 and 0 or menu.delay + 1
			if menu.delay == 0 then
				buffer = {}
			else
				buffer[menu.delay] = 0
			end
		end
	},
	{
		key = TOGGLE_BACKGROUND_MUSIC_KEY,
		condition = function() return true end,
		action = function()
			menu.music = not menu.music
			wba(MAP.MUSIC, menu.music and 0x9B or 0x0)
		end
	},
	{
		key = TOGGLE_HISTORY_KEY,
		condition = function() return menu.live end,
		action = function() menu.history = not menu.history end
	},
	{
		key = TOGGLE_INFO_KEY,
		condition = function() return menu.live end,
		action = function() menu.info = not menu.info end
	},
	{
		key = TOGGLE_HITBOXES_KEY,
		condition = function() return menu.live end,
		action = function() menu.hitboxes = not menu.hitboxes end
	},
	pressed = false
}

-- Code that runs before each frame is emulated.

local function clearTables(clearHistory)
	for i = 1, 2 do
		players[i] = { health = 144, gems = { 0, 0, 0 }, freeFrame = -1, state = 0, blockLow = math.random(2) == 2 }
		info[i] = { lastHitDamage = 0, comboDamage = 0, comboCount = 0, advantage = 0 }
		if clearHistory then
			history[i] = {}
			for j = 1, 14 do
				history[i][j] = {}
				for _, b in ipairs(INPUTS) do
					history[i][j][b] = false
					history[i][j].count = 0
				end
			end
		end
		throwBuffer[MAP.BASE[i]] = {}
	end
	for i = 1, HITBOX_DRAW_DELAY + 1 do
		boxBuffer[i] = {}
	end
	menu.cleared = true
end

-- Methods to encode/decode a table of inputs to/from an 8-bit number.

local function encode(t)
	local n = 0
	for i, v in ipairs(PLAYER_INPUTS[menu.active]) do
		n = n + (t[v] and BITS[i] or 0)
	end
	return n
end

local function decode(n, t, p)
	for i, v in ipairs(PLAYER_INPUTS[p]) do
		t[v] = n >= BITS[i]
		n = n - (n >= BITS[i] and BITS[i] or 0)
	end
end

-- Code that runs after each frame is emulated.

local function updateCommands(keys, joy)
	for _, c in ipairs(commands) do
		if (keys[c.key] or (c.joy and joy[c.joy])) and c.condition() then
			if not commands.pressed then
				commands.pressed = true
				c.action()
			end
			return
		end
	end
	commands.pressed = false
end

local function updateMenu(joy)
	if menu.state == RECORDING then
		data[menu.slot][menu.frame] = encode(joy)
	elseif menu.state == PLAYBACK then
		if menu.frame > #data[menu.slot] then
			menu.frame = 1
			if RANDOM_SLOT_PLAYBACK then
				repeat
					menu.slot = math.random(NUM_SLOTS)
				until #data[menu.slot] > 0
			end
		end
		decode(data[menu.slot][menu.frame], joy, menu.inactive)
		if PLAYBACK_TURNAROUND and data[menu.slot].side ~= getInactiveSide() then
			joy[PLAYER_INPUTS[menu.inactive][LEFT]], joy[PLAYER_INPUTS[menu.inactive][RIGHT]] = joy[PLAYER_INPUTS[menu.inactive][RIGHT]], joy[PLAYER_INPUTS[menu.inactive][LEFT]]
		end
	elseif not menu.replay then
		for _, b in ipairs(PLAYER_INPUTS[menu.inactive]) do
			joy[b] = false
		end
		if menu.state == DUMMY then
			dummy[dummy.actions[rb(MAP.HEALTH[menu.inactive]) < 0x90 and 2 or 1]].action(joy, emu.framecount() % (menu.turbo and 2 or 15) == 1)
		end
	end
end

local function updateHistory(joy)
	for i = 1, 2 do
		local changed = false
		for j = 1, #INPUTS do
			if history[i][#history[i]][INPUTS[j]] ~= joy[PLAYER_INPUTS[i][j]] then
				for k = 1, #history[i] do
					for l = 1, #INPUTS do
						if k == #history[i] then
							history[i][k][INPUTS[l]] = joy[PLAYER_INPUTS[i][l]]
							history[i][k].count = 1
						else
							history[i][k][INPUTS[l]] = history[i][k + 1][INPUTS[l]]
							history[i][k].count = history[i][k + 1].count
						end
					end
				end
				changed = true
				break
			end
		end
		if not changed then
			history[i][#history[i]].count = math.min(history[i][#history[i]].count + 1, 99)
		end
	end
end

local function updateBefore()
	local joy = joypad.get()
	if menu.active ~= 1 then
		for i = 1, #INPUTS do
			joy[PLAYER_INPUTS[1][i]], joy[PLAYER_INPUTS[2][i]] = joy[PLAYER_INPUTS[2][i]], joy[PLAYER_INPUTS[1][i]]
		end
	end
	local current = encode(joy)
	for i = 1, menu.delay do
		if i == menu.delay then
			buffer[i] = current
		else
			if i == 1 then
				decode(buffer[i], joy, menu.active)
			end
			buffer[i] = buffer[i + 1]
		end
	end
	if rd(0xFF8004) == 0x40000 and rd(0xFF8008) == 0x40000 and not menu.live then
		clearTables(true)
	end
	menu.state = (menu.live and (rd(0xFF8004) ~= 0x40000 or rd(0xFF8008) ~= 0x40000)) and DEFAULT or menu.state
	menu.live = rd(0xFF8004) == 0x40000 and rd(0xFF8008) == 0x40000
	if not menu.live and not menu.replay then
		if menu.selected == 0 and rb(MAP.SELECTABLE) ~= 0x0 then
			if joy[PLAYER_INPUTS[menu.active][2]] then
				if joy[PLAYER_INPUTS[menu.active][4]] then
					wb(MAP.STAGE, 0xE)
				elseif joy[PLAYER_INPUTS[menu.active][5]] then
					wb(MAP.STAGE, 0x2)
				else
					wb(MAP.STAGE, 0x0)
				end
			elseif joy[PLAYER_INPUTS[menu.active][3]] then
				if joy[PLAYER_INPUTS[menu.active][4]] then
					wb(MAP.STAGE, 0xA)
				elseif joy[PLAYER_INPUTS[menu.active][5]] then
					wb(MAP.STAGE, 0x6)
				else
					wb(MAP.STAGE, 0x8)
				end
			elseif joy[PLAYER_INPUTS[menu.active][4]] then
				wb(MAP.STAGE, 0xC)
			elseif joy[PLAYER_INPUTS[menu.active][5]] then
				wb(MAP.STAGE, 0x4)
			end
		end
		menu.selected = rb(MAP.SELECTABLE)
	end
	updateCommands(input.get(), joy)
	if menu.live then
		if menu.state == RECORDING or menu.state == PLAYBACK then
			menu.frame = menu.frame + 1
			menu.brightness = menu.ascending and menu.brightness + 3 or menu.brightness - 3
			if menu.brightness == 255 or menu.brightness == 192 then
				menu.ascending = not menu.ascending
			end
		end
		updateMenu(joy)
		updateHistory(joy)
	end
	joypad.set(joy)
end

emu.registerbefore(updateBefore)

-- Code that runs after each frame is emulated.

local function validateBox(o, b)
	if b.style == 'PUSH' then
		return not (rb(o.base + 0x1AA) > 0x0 or rb(o.base + 0x93) == 0x0)
	elseif b.style == 'THROWABLE' then
		return not (o.projectile or (rb(o.base + 0x143) > 0x0 or rb(o.base + 0x188) > 0x0 or (rb(o.base + 0x119) == 0x0 and rw(o.base + 0x4) == 0x202) or
			rw(b.id_base + 0x8) == 0x0 or (rb(o.base + 0x105) > 0x0 and rb(o.base + 0x1BE) == 0x0 and rb(b.id_base + 0x17) == 0x0)))
	elseif b.style == 'HURT' then
		return not (rb(o.base + 0x147) > 0x0 or rb(o.base + 0x132) > 0x0 or rb(o.base + 0x11B) > 0x0)
	elseif b.style == 'HIT' then
		return not (rb(o.base + 0xB1) > 0x0)
	elseif b.style == 'THROW' then
		return not (rb(o.base + 0x143) > 0x0 or rb(o.base + 0x188) > 0x0 or (rb(o.base + 0x119) == 0x0 and rw(o.base + 0x4) == 0x202))
	end
end

local function createBox(o, b)
	if not b.id then
		b.id_base = (b.animationOffset and rd(o.base + b.animationOffset)) or o.base
		b.id = rb(b.id_base + b.idOffset)
	end
	if b.id ~= 0 and validateBox(o, b) then
		local address = rd(o.base + b.addressOffset) + bit.lshift(b.id, b.idShift)
		b.w = rw(address + 0x4)
		b.h = rw(address + 0x6)
		b.x = o.x + rws(address) * o.flip - b.w / 2
		b.y = o.y - rws(address + 0x2) - b.h / 2
		b.style = string.format('%s%s', o.projectile and 'PROJ' or '', b.style)
		return b
	end
	return nil
end

local function createObject(o)
	o.flip = rb(o.base + 0xB) > 0 and -1 or 1
	o.x = rws(o.base + 0x10) - boxBuffer[HITBOX_DRAW_DELAY + 1].screenLeft
	o.y = emu.screenheight() - (rws(o.base + 0x14) - 0x10) + boxBuffer[HITBOX_DRAW_DELAY + 1].screenTop
	for _, b in ipairs(BOX_STYLES) do
		table.insert(o, createBox(o, copytable(b)))
	end
	return o
end

local function updateBoxes()
	for i = 1, HITBOX_DRAW_DELAY do
		boxBuffer[i] = copytable(boxBuffer[i + 1])
	end
	boxBuffer[HITBOX_DRAW_DELAY + 1] = { screenLeft = rws(0xFF8290), screenTop = rws(0xFF8294) }

	for i = 1, 2 do
		local o = { base = MAP.BASE[i] }
		if rb(o.base) > 0 then
			table.insert(o, throwBuffer[o.base][1])
			for frame = 1, #throwBuffer[o.base] - 1 do
				throwBuffer[o.base][frame] = throwBuffer[o.base][frame + 1]
			end
			table.remove(throwBuffer[o.base])
			table.insert(boxBuffer[HITBOX_DRAW_DELAY + 1], createObject(o)) 
		end
	end
	for i = 1, 14 do
		local b = 0xFF8C00 + (i - 1) * 0x100
		if rw(b) > 0x100 and rb(b + 0x4) >= 0x2 then
			table.insert(boxBuffer[HITBOX_DRAW_DELAY + 1], createObject({ base = b, projectile = true }))
		end
	end
end

local function updateAfter()
	if menu.live then
		updateBoxes()
		if rw(MAP.TIMER_VALUE) > 0x633A and not menu.cleared then
			clearTables(false)
		elseif rw(MAP.TIMER_VALUE) <= 0x633A and menu.cleared then
			menu.cleared = false
		end
		if not menu.replay and rw(MAP.TIMER_VALUE) <= 0x633A then
			wb(MAP.TIMER_DISPLAY, 0x99)
			ww(MAP.TIMER_VALUE, 0x633A)
		end
		for i, p in ipairs(players) do
			if not menu.replay then
				ww(MAP.METER[i], 0x960)
				wb(MAP.SPECIALS[i][1], p.gems[1])
				wb(MAP.SPECIALS[i][2], p.gems[2])
				wb(MAP.SPECIALS[i][3], p.gems[3])
				wb(MAP.GEMS[i][1], p.gems[1] * 48)
				wb(MAP.GEMS[i][2], p.gems[2] * 48)
				wb(MAP.GEMS[i][3], p.gems[3] * 48)
				wb(MAP.TAUNTS[i], 0xF)
				if rb(MAP.STATE[i]) == 0x0 and players[i].state ~= 0x0 then
					players[i].blockLow = math.random(2) == 2
				end
				players[i].state = rb(MAP.STATE[i])
				if not menu.stun then
					wb(MAP.STUN[i], 0x0)
					wb(MAP.STUN_MAX[i], CHARACTERS[rb(MAP.CHARACTER[i]) + 1].STUN)
				end
				if rb(MAP.STATE[i]) == 0x0 and rb(MAP.STUN_STATE[i]) == 0x0 then
					wb(MAP.HEALTH[i], 0x90)
				end
			end
			
			local other = i == 1 and 2 or 1
			if p.health > 0 and players[other].health > 0 and rw(MAP.TIMER_VALUE) <= 0x633A then
				if rb(MAP.HEALTH[i]) < p.health or (rb(MAP.COMBO[other]) > 0 and info[other].comboCount ~= rb(MAP.COMBO[other])) then
					info[other].lastHitDamage = math.max(p.health - rb(MAP.HEALTH[i]), 0)
					if (rb(MAP.COMBO[other]) > info[other].comboCount) or
						((rb(MAP.COMBO[other]) == info[other].comboCount) and info[other].comboCount > 1) then
						info[other].comboDamage = info[other].comboDamage + info[other].lastHitDamage
					elseif rb(MAP.COMBO[other]) > 0x0 then
						info[other].comboDamage = info[other].lastHitDamage
					else
						info[other].comboDamage = 0
					end
					info[other].comboCount = rb(MAP.COMBO[other])
				end
				p.health = rb(MAP.HEALTH[i])
			end
			
			if rb(MAP.STUN_STATE[i]) == 0x2 and rb(MAP.STATE[i]) == 0x0 then
				menu.defender = i
				players[1].freeFrame = -1
				players[2].freeFrame = -1
			end
			if (menu.defender > 0 and players[i].freeFrame == -1) and
				((i == menu.defender and rb(MAP.STUN_STATE[i]) == 0x0) or
				(i ~= menu.defender and (rb(MAP.STATE[i]) == 0x0 or (rb(MAP.STATE[i]) == 0x2 and rb(MAP.STUN_STATE[i]) == 0x0) or rb(MAP.STATE[i]) == 0x4 or rb(MAP.STATE[i]) == 0x14 or (rb(MAP.STATE[i]) == 0x6 and rb(MAP.AIR_ATTACK[i]) ~= 0x6)))) then
				players[i].freeFrame = emu.framecount()
			end
		end
		
		if menu.defender > 0 and players[1].freeFrame ~= -1 and players[2].freeFrame ~= -1 then
			info[1].advantage = players[2].freeFrame - players[1].freeFrame
			info[2].advantage = players[1].freeFrame - players[2].freeFrame
			if rw(MAP.TIMER_VALUE) > 0x633A then
				info[1].advantage = 0
				info[2].advantage = 0
			end
			menu.defender = 0
		end
	elseif not menu.replay then
		for i = 1, 2 do
			ww(MAP.SELECT_TIME[i], 0x6363)
		end
	end
end

emu.registerafter(updateAfter)

-- Drawing code that runs each time the screen is updated.

local function pane(x, y, w, h)
	gui.box(x, y, x + w, y + h, UI_COLOR, 0x00)
	gui.line(x + 2, y, x + w - 2, y, UI_COLOR)
	gui.line(x + 2, y + h, x + w - 2, y + h, UI_COLOR)
end

local function text(x, y, s, c)
	gui.text(x, y, s, c or 0xFFFFFFFF)
end

local function dpad(x, y, h, v)
	gui.box(x - 1, y + 1, x + 7, y + 5, 0xFF, 0x00)
	gui.box(x + 1, y - 1, x + 5, y + 7, 0xFF, 0x00)
	gui.line(x + 2, y + 3, x + 1, y + 3, h < 0 and 0xFF0000FF or 0x8C8A8CFF)
	gui.line(x + 4, y + 3, x + 5, y + 3, h > 0 and 0xFF0000FF or 0x8C8A8CFF)
	gui.line(x + 3, y + 2, x + 3, y + 1, v < 0 and 0xFF0000FF or 0x8C8A8CFF)
	gui.line(x + 3, y + 4, x + 3, y + 5, v > 0 and 0xFF0000FF or 0x8C8A8CFF)
end

local function draw()
	gui.clearuncommitted()
	local infoText = ''
	if not menu.replay then
		local x = menu.live and 220 or 314
		local w = menu.live and 156 or 62
		if menu.delay > 0 then
			if menu.live then
				w = w - 15
			else
				x = x - 15
			end
		end
		pane(x, 4, w, 10)
		if menu.live and rb(MAP.CHARACTER[1]) == rb(MAP.CHARACTER[2]) then
			infoText = rb(MAP.COLOR[menu.active]) > 0 and CHARACTERS[rb(MAP.CHARACTER[menu.active]) + 1].COLORS[rb(MAP.COLOR[menu.active])]..' ' or 'DEFAULT '
		end
		text(x + 4, 6, 'CONTROLLING P'..menu.active..(menu.live and ' - '..infoText..CHARACTERS[rb(MAP.CHARACTER[menu.active]) + 1].NAME or ''))
	end
	
	if menu.live then
		if menu.hitboxes then
			for _, o in ipairs(boxBuffer[1]) do
				for _, b in ipairs(o) do
					gui.box(b.x, b.y, b.x + b.w, b.y + b.h, UI_TRANSPARENCY and BOX_COLORS[b.style].FILL or 0x00, BOX_COLORS[b.style].STROKE)
				end
			end
		end
		if not menu.replay then
			pane(7, 4, 10, 10)
			text(11, 6, menu.state == DUMMY and 'D' or 'S', (menu.state == DUMMY and menu.turbo) and 0xFF9A00FF or 0xFFFF00FF)
			pane(18, 4, 145, 10)
			local infoColor = 0xFFFFFFFF
			if menu.state == DUMMY then
				infoText = string.format('%s / %s', dummy[dummy.actions[1]].name, dummy[dummy.actions[2]].name)
			elseif menu.state == RECORDING then
				infoText = string.format('SLOT %s RECORDING (%s)', menu.slot, menu.frame)
				infoColor = tonumber(string.format('%02x0000FF', menu.brightness), 16)
			elseif menu.state == PLAYBACK then
				infoText = string.format('SLOT %s PLAYBACK (%s / %s)', menu.slot, menu.frame, #data[menu.slot])
				infoColor = tonumber(string.format('00%02x00FF', menu.brightness), 16)
			else
				infoText = string.format('SLOT %s (%s)', menu.slot, #data[menu.slot] > 0 and (#data[menu.slot]..' FRAMES') or 'EMPTY')
			end
			text(22, 6, infoText, infoColor)
		end
	
		local x = 7
		if menu.history then
			for i = 1, #players do
				local y = 177
				pane(x, y - 119, 55, 127)
				for _, h in ipairs(history[i]) do
					if h['Up'] ~= h['Down'] or h['Left'] ~= h['Right'] then
						dpad(x + 14, y, h['Left'] ~= h['Right'] and (h['Left'] and -1 or 1) or 0, h['Up'] ~= h['Down'] and (h['Up'] and -1 or 1) or 0)
					end
					if h.count > 0 then
						text(x + 4, y, string.format('%02d', h.count))
					end
					local cx = x + 25
					if h['Punch'] then
						text(cx, y, 'P', 0xFF659CFF)
						cx = cx + 8
					end
					if h['Kick'] then
						if h['Punch'] then
							text(cx - 4, y, '+')
						end
						text(cx, y, 'K', 0x008AFFFF)
						cx = cx + 8
					end
					if h['Special'] then
						if h['Punch'] or h['Kick'] then
							text(cx - 4, y, '+')
						end
						text(cx, y, 'S', 0xFFBA52FF)
						cx = cx + 8
					end
					if h['Start'] then
						if h['Punch'] or h['Kick'] or h['Special'] then
							text(cx - 4, y, '+')
						end
						text(cx, y, 'T', 0x8C8A8CFF)
					end
					y = y - 9
				end
				x = x + 314
			end
		end
		if menu.info then
			x = menu.history and 63 or 7
			for i, p in ipairs(info) do
				pane(x, 58, 74, 46)
				text(x + 4, 60, string.format('HIT DAMAGE: %s', p.lastHitDamage))
				text(x + 4, 69, string.format('COMBO DAMAGE: %s', p.comboDamage))
				text(x + 4, 78, string.format('COMBO COUNT: %s', p.comboCount))
				text(x + 4, 87, string.format('ADVANTAGE: %s%s', p.advantage > 0 and '+' or '', p.advantage))
				text(x + 4, 96, string.format('STUN: %s', menu.stun and string.format('%s / %s', rb(MAP.STUN[i]), rb(MAP.STUN_MAX[i])) or 'DISABLED'))
				x = x + (menu.history and 183 or 295)
			end
		end
	end
	if menu.delay > 0 then
		pane(362, 4, 14, 10)
		text(366, 6, string.format('%sF', menu.delay))
	end
end

gui.register(draw)

-- Code that runs when the script starts and exits.

local function split(s, delimiter)
	local t = {}
	local n = 1
	for part in string.gmatch(s, '[^'..delimiter..']+') do
		t[n] = part
		n = n + 1
	end
	return t
end

local function base36(n)
	return n < 36 and BASE36[n + 1] or BASE36[math.floor(n / 36) % 36 + 1]..BASE36[n % 36 + 1]
end

local function loadData()
	local file, err = io.open('data.rep', 'r')
	if not err then
		data = {}
		local work = split(file:read(), ',')
		for i, slot in ipairs(work) do
			data[i] = { side = slot:sub(1, 1) }
			if slot ~= '' then
				for j = 2, #slot, 4 do
					local value = tonumber(slot:sub(j, j + 1), 16)
					local count = tonumber(slot:sub(j + 2, j + 3), 36)
					while count > 0 do
						data[i][#data[i] + 1] = value
						count = count - 1
					end
				end
			end
		end
		file:close()
		NUM_SLOTS = #data
	end
end

local function start()
	print('Gemini - Super Gem Fighter Mini Mix Training Mode - v1.06')
	math.randomseed(os.time())
	clearTables(true)
	re(0x12800, function()
		if menu.live then
			for _, o in ipairs(boxBuffer[HITBOX_DRAW_DELAY + 1]) do
				if o.base == bit.band(gr('m68000.a6'), 0xFFFFFF) then
					table.insert(throwBuffer[o.base], createBox(o, { id = bit.band(gr('m68000.d0'), 0xFF), addressOffset = 0x88, idOffset = 0x98, idShift = 0x5, style = 'THROW' }))
				end
			end
		end
	end)
	UI_COLOR = (UI_TRANSPARENCY or bit.band(UI_COLOR, 0xFF) == 0x0) and UI_COLOR or bit.bor(UI_COLOR, 0xFF)
	for i = 1, NUM_SLOTS do
		data[i] = { side = 'r' }
	end
	if LOAD_ON_START and not menu.replay then
		loadData()
	end
end

local function saveData()
	local file, err = io.open('data.rep', 'w')
	if not err then
		local work = {}
		for i, slot in ipairs(data) do
			work[#work + 1] = slot.side
			local previous = 999
			local count = 1
			for _, frame in ipairs(slot) do
				if frame ~= previous or count == 1295 then
					if previous ~= 999 then
						work[#work + 1] = string.format('%02x%02s', previous, base36(count))
						count = 1
					end
					previous = frame
				else
					count = count + 1
				end
			end
			work[#work + 1] = #slot > 0 and string.format('%02x%02s', previous, base36(count)) or nil
			work[#work + 1] = i ~= #data and ',' or nil
		end
		file:write(table.concat(work))
		file:close()
	end
end

emu.registerstart(start)
emu.registerexit((SAVE_ON_EXIT and not menu.replay) and saveData or nil)
