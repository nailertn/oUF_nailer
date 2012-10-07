local highlight
do
	highlight = CreateFrame'Frame'
	highlight:SetFrameStrata('LOW')
	
	local size = 13
	local thickness = 2
	local r, g, b = 1, 1, 0

	for _, position in next, {
		{ "bottomleft", 1, 1 },
		{ "bottomright", -1, 1 },
		{ "topleft", 1, -1 },
		{ "topright", -1, -1 },
	} do
		local anchor, mod_x, mod_y = unpack(position)
		
		local v_bg = highlight:CreateTexture(nil, "BACKGROUND")
		v_bg:SetPoint(anchor)
		v_bg:SetSize(thickness, size)
		v_bg:SetTexture(0,0,0)
		
		v_fg = highlight:CreateTexture(nil, "BORDER")
		v_fg:SetPoint(anchor, mod_x, mod_y)
		v_fg:SetSize(thickness - 1, size - 2)
		v_fg:SetTexture(r,g,b)
		
		local h_bg = highlight:CreateTexture(nil, "BACKGROUND")
		h_bg:SetPoint(anchor, mod_x * thickness, 0)
		h_bg:SetSize(size - thickness, thickness)
		h_bg:SetTexture(0,0,0)
			
		h_fg = highlight:CreateTexture(nil, "BORDER")
		h_fg:SetPoint(anchor, mod_x * thickness, mod_y)
		h_fg:SetSize(size - thickness - 1, thickness - 1)
		h_fg:SetTexture(r,g,b)
	end
end

local function enter(object)
	highlight:SetAllPoints(object)
	highlight:Show()
end

local function leave(object)
	highlight:Hide()
end

local function enable(object)
	if object.highlight then
		object:HookScript('OnEnter', enter)
		object:HookScript('OnLeave', leave)
	end
end

local function disable(object)
	if object.highlight then
		object.highlight = false
	end
end

oUF:AddElement('highlight', nil, enable, disable)