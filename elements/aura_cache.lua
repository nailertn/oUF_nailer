local layout_name, layout = ...

local aura_cache = CreateFrame("Frame")

local recycled, callback, throttle, buffs, debuffs, directory = {}, {}, {}, {}, {}, {}

local function GetTable(cache, index)
	local t = recycled[#recycled] or { ['1'] = nil, ['2'] = nil, ['3'] = nil, ['4'] = nil, ['5'] = nil, ['6'] = nil, ['7'] = nil, ['8'] = nil, ['9'] = nil }
	recycled[#recycled] = nil
	cache[index] = t
	return t
end

local UnitAura = UnitAura
local function scan_auras(cache, unit, filter)
	local index = 1
	
	while true do
		local entry = cache[index] or GetTable(cache, index)
		
		entry.name, _, entry.icon, entry.count, entry.debuff_type, entry.duration, entry.expiration, entry.caster, _, _, entry.id = UnitAura(unit, index, filter)
		if not entry.name then break end
		
		entry.index = index
		directory[entry.name] = entry
		
		index = index + 1
	end
	
	for i = index, #cache do
		recycled[#recycled + 1] = cache[i]
		cache[i] = nil
	end
end

local function update(object, unit)
	for k in next, directory do
		directory[k] = nil
	end
	
	scan_auras(buffs, unit, "HELPFUL")
	scan_auras(debuffs, unit, "HARMFUL")
	
	for func in next, callback[object] do
		func(object, aura_cache)
	end
end

local timer = 1
aura_cache:SetScript("OnUpdate", function(self, elapsed)
	timer = timer + elapsed
	if timer < .1 then return end
	timer = 0
	self:Hide()
	
	for object, unit in next, throttle do
		throttle[object] = nil
		update(object, unit)
	end
end)

local function UNIT_AURA(object, event, unit)
	if unit ~= object.unit then return end
	throttle[object] = unit
	return aura_cache:Show()
end

function aura_cache.force_update(object, event)
	if not object.unit then return end
	throttle[object] = nil
	return update(object, object.unit)
end

function aura_cache.register_callback(object, func)
	callback[object] = callback[object] or {}
	
	if not next(callback[object]) then
		object:RegisterEvent("UNIT_AURA", UNIT_AURA)
		tinsert(object.__elements, aura_cache.force_update)
	end
	
	callback[object][func] = true
end

function aura_cache.unregister_callback(object, func)
	if not callback[object] then return end
	
	callback[object][func] = nil
	
	if not next(callback[object]) then
		throttle[object] = nil
		object:UnregisterEvent("UNIT_AURA", UNIT_AURA)
		for i,f in next, object.__elements do
			if f == aura_cache.force_update then
				return tremove(object.__elements, i)
			end
		end
	end
end

aura_cache.buffs, aura_cache.debuffs, aura_cache.directory = buffs, debuffs, directory
layout.aura_cache = aura_cache