local layout_name, layout = ...

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
