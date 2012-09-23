local layout_name, layout = ...

layout.event_frame = CreateFrame'Frame'
layout.event_frame:SetScript('OnEvent', function(event_frame, event, ...)
	return layout[event](event_frame, event, ...)
end)
