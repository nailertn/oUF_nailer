local layout_name, layout = ...

local function style(object, unit)
	local bg = object:CreateTexture()
	bg:SetAllPoints()
	bg:SetTexture(0,0,0)
end

oUF:RegisterStyle(layout_name .. ' solo style', style)

local width, height = 300, 30

oUF:Factory(function()
	oUF:SetActiveStyle(layout_name .. ' solo style')
	
	local player = oUF:Spawn('player')
	player:SetSize(width, height)
	player:SetPoint('center', -400, 0)
	
	local target = oUF:Spawn('target')
	target:SetSize(width, height)
	target:SetPoint('center', 400, 0)
end)
