local layout_name, layout = ...

local function style(object, unit)
	local bg = object:CreateTexture()
	bg:SetAllPoints()
	bg:SetTexture(0,0,0)
end

oUF:RegisterStyle(layout_name .. ' solo style')
