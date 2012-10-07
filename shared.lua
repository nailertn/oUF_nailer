layout_name, layout = ...

-- event dispatcher
do
	local event_frame = CreateFrame'Frame'
	local registry = {}
	
	local RegisterEvent = event_frame.RegisterEvent
	function event_frame:RegisterEvent(event, func)
		if registry[event] then
			registry[event][func] = true
		else
			registry[event] = { [func] = true }
			RegisterEvent(event_frame, event)
		end
	end
	
	local UnregisterEvent = event_frame.UnregisterEvent
	function event_frame:UnregisterEvent(event, func)
		if registry[event] and func then
			registry[event][func] = nil
			if not next(registry[event]) then
				registry[event] = nil
				UnregisterEvent(event_frame, event)
			end
		end
	end
	
	function event_frame:IsEventRegistered(event, func)
		return registry[event] and registry[event][func]
	end

	event_frame:SetScript('OnEvent', function(self, event, ...)
		if registry[event] then
			for func in next, registry[event] do
				func(self, event, ...)
			end
		end
	end)

	layout.event_frame = event_frame
end

-- saved variables
local function get_saved_variables()
	layout.event_frame:UnregisterEvent('ADDON_LOADED', get_saved_variables)
	
	layout.saved_variables = _G[layout_name .. '_saved_variables'] or {}
	_G[layout_name .. '_saved_variables'] = layout.saved_variables
end
layout.event_frame:RegisterEvent('ADDON_LOADED', get_saved_variables)

-- media and settings
layout.solid = "Interface\\Buttons\\WHITE8X8"
layout.texture = "Interface\\AddOns\\" .. layout_name .. "\\media\\lyn"
layout.backdrop = { bgFile = layout.solid, edgeFile = layout.solid, edgeSize = 1 }

layout.font1 = "Interface\\AddOns\\" .. layout_name .. "\\media\\charriot_deluxe.ttf"
layout.font1_size = 10
layout.font1_flags = "OUTLINEMONOCHROME"

layout.font2 = "Interface\\AddOns\\" .. layout_name .. "\\media\\tama_mini01.ttf"
layout.font2_size = 20
layout.font2_flags = "OUTLINEMONOCHROME"

oUF.colors.disconnected = { 0.59, 0.04, 0.04 }

layout.heal_threshold = 10000