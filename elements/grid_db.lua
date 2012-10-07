local layout_name, layout = ...

local grid_db, active_auras, missing_auras = {}, {}, {}

local pvp = {
	--immunities
	['Divine Shield'] = { priority = 100, update = true },
	['Hand of Protection'] = { priority = 100, update = true },
	['Ice Block'] = { priority = 101, update = true },
	['The Beast Within'] = { priority = 101, update = true },
	['Deterrence'] = { priority = 102, update = true },
	
	--cc
	['Banish'] = { priority = 102, update = true },
	['Cyclone'] = { priority = 103, update = true },
	['Polymorph'] = { priority = 81, update = true },
	['Fear'] = { priority = 82, update = true },
	['Hibernate'] = { priority = 81, update = true },
	['Sap'] = { priority = 81, update = true },
	['Repentance'] = { priority = 81, update = true },
	['Entangling Roots'] = { priority = 80, update = true },
	['Blind'] = { priority = 81, update = true },
	['Hex'] = { priority = 83, update = true },
	['Hammer of Justice'] = { priority = 85, update = true },
	['Deep Freeze'] = { priority = 85, update = true },
	['Frost Trap'] = { priority = 81, update = true },
	['Wyvern Sting'] = { priority = 81, update = true },
	['Hungering Cold'] = { priority = 81, update = true },
	['Maim'] = { priority = 81, update = true },
	['Scatter Shot'] = { priority = 81, update = true },
	['Shockwave'] = { priority = 81, update = true },
	['Kidney Shot'] = { priority = 85, update = true },
	['Cheap Shot'] = { priority = 85, update = true },
	['Bash'] = { priority = 85, update = true },
	['Gnaw'] = { priority = 85, update = true },
	['Gouge'] = { priority = 81, update = true },
	['Psychic Scream'] = { priority = 81, update = true },
	['Intimidating Shout'] = { priority = 81, update = true },
	['Seduction'] = { priority = 81, update = true },
	['Death Coil'] = { priority = 81, update = true },
	['Shadow Fury'] = { priority = 81, update = true },
	['Frost Nova'] = { priority = 80, update = true },
	['Howl of Terror'] = { priority = 81, update = true },
	['Strangulate'] = { priority = 79, update = true },
	['Silence'] = { priority = 79, update = true },
	['Silencing Shot'] = { priority = 79, update = true },
	['Silenced - Improved Counterspell'] = { priority = 79, update = true },
	['Psychic Horror'] = { priority = 79, update = true },
		
	--mitigation
	['Life Cocoon'] = { priority = 75, update = true },
	['Divine Protection'] = { priority = 74, update = true },
	['Icebound Fortitude'] = { priority = 71, update = true },
	['Barkskin'] = { priority = 70, update = true },
	['Fortifying Brew'] = { priority = 70, update = true },
	['Shield Wall'] = { priority = 74, update = true },
	['Shield Block'] = { priority = 72, update = true },
	['Pain Suppression'] = { priority = 71, update = true },
	['Hand of Sacrifice'] = { priority = 74, update = true },
	['Guardian Spirit'] = { priority = 75, update = true },
	['Anti-Magic Shell'] = { priority = 70, update = true },
	['Last Stand'] = { priority = 71, update = true },
	['Survival Instincts'] = { priority = 71, update = true },
	['Cloak of Shadows'] = { priority = 74, update = true },
	['Evasion'] = { priority = 74, update = true, icon_check = select(3, GetSpellInfo(5277)) },
	['Cheat Death'] = { priority = 74, update = true },
	
	--ms
	['Mortal Strike'] = { priority = 62, update = true },
	['Aimed Shot'] = { priority = 61, update = true },
	['Wound Poison'] = { priority = 60, update = true },
	
	['Abolish Poison'] = { priority = 90, update = true },
	['Fade'] = { priority = 90, update = true }
}

local healer = {
	['Beacon of Light']	= { indicator = 'bottomleft_1', color = { 0.66, 0.00, 0.40 } },
	['Weakened Soul'] = { indicator = 'bottomleft_2', color = { 0.50, 0.00, 0.00 } },
	['Power Word: Shield'] = { indicator = 'bottomleft_2', priority = 51, color = { 0.50, 0.40, 0.25 } },
	['Twilight Renewal'] = { priority = 51, mine = true, update = true },
}

local class = select(2, UnitClass('player'))

if class == 'DRUID' then
	healer['Rejuvenation'] = { indicator = 'topleft_1', color = { 0.50, 0.00, 0.50 }, update = 'mine' }
	healer['Regrowth'] = { indicator = 'topleft_2', color = { 0.00, 0.50, 0.50 }, update = 'mine' }
	healer['Wild Growth'] = { indicator = 'topright_2', color = { 0.50, 0.25, 0.00 }, update = 'mine' }
	healer['Lifebloom'] = {
		indicator = 'topright_1',
		color1 = { 0.00, 0.50, 0.00 },
		color2 = { 0.50, 0.50, 0.00 },
		color3 = { 0.50, 0.00, 0.00 },
		update = 'mine',
		fast_update = 'true',
		update_indicator = function(handler, indicator, expiration, now)
			local i, f = modf(expiration - now)
		
			if expiration - now < 1 then
				indicator.text:SetFormattedText('.%d', f * 10)
			else
				indicator.text:SetFormattedText('%d%d', i, f * 10)
			end
		end
	}
elseif class == 'MONK' then
	healer['Enveloping Mist'] = { indicator = 'topright_2', color = { 0.50, 0.25, 0.00 }, update = 'mine' }
	healer[119611] = { -- renewing mist
		indicator = 'topleft_1',
		priority = 49,
		color = { 0.50, 0.00, 0.50 },
		update = 'mine',
		custom_init = function(grid, indicator, aura_cache, entry)
			local spread_count
			
			for _, entry in next, aura_cache.buffs do
				if entry.id == 119607 then
					spread_count = entry.count
					break
				end
			end
			
			if spread_count and spread_count > 0 then
				indicator:SetBackdropColor(0.75, 0.75, 0.00)
			else
				indicator:SetBackdropColor(0.50, 0.00, 0.50)
			end
			
			if entry.expiration > 0 and entry.caster == 'player' then
				indicator:start_update(entry)
			else
				indicator.text:SetText()
				indicator:stop_update()
			end
			
			indicator:Show()
		end
	}
	
	--healer[119607] = { indicator = 'topleft_1', priority = 50, color = { 0.75, 0.75, 0.00 }, count = 'mine', min_count = 1 } -- renewing mist spread
	healer[115175] = { indicator = 'topright_1', priority = 50, color = { 0.00, 0.50, 0.50 }, update = 'mine' } -- soothing mist
	healer[125950] = { indicator = 'topright_1', priority = 49, color = { 0.75, 0.75, 0.00 }, update = 'mine' } -- soothing mist replica
elseif class == 'PALADIN' then
	healer['Beacon of Light'] = { indicator = 'topleft_1', color = { 0.66, 0.00, 0.40 }, update = 'mine' }
	healer['Sacred Shield'] = { indicator = 'topright_1', color = { 0.50, 0.35, 0.00 }, update = 'mine' }
elseif class == 'PRIEST' then
	healer['Renew'] = { indicator = 'topleft_1', color = { 0.40, 0.55, 0.00 }, update = 'mine' }
	healer['Prayer of Mending'] = { indicator = 'topright_2', color = { 0.25, 0.50, 0.66 }, count = 'mine' }
	healer['Weakened Soul'] = { indicator = 'topright_1', color = { 0.50, 0.00, 0.00 }, update = true }
	healer['Power Word: Shield'] = { indicator = 'topright_1', priority = 51, color = { 0.50, 0.40, 0.25 }, update = 'mine' }
elseif class == 'SHAMAN' then
	healer['Earth Shield'] = { indicator = 'topleft_1', color = { 0.66, 0.25, 0.00 }, count = 'mine' }
	healer['Riptide'] = { indicator = 'topright_1', color = { 0.25, 0.50, 0.66 }, update = 'mine' }
	healer['Ancestral Fortitude'] = { indicator = 'topright_2', color = { 0.66, 0.00, 0.40 }, update = 'mine' }
	healer['Earthliving'] = { indicator = 'topleft_2', color = { 0.75, 0.74, 0.34 }, update = 'mine' }
end

for _, group in next, { pvp, healer } do
	for key, settings in next, group do
		settings.priority = settings.priority or 50
		settings.indicator = settings.indicator or 'center'
		active_auras[key] = settings
	end
end

grid_db.active_auras, grid_db.missing_auras = active_auras, missing_auras
layout.grid_db = grid_db