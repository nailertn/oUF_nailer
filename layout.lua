local layout_name, layout = ...

local function style(object, unit)
	object:SetSize(300, 30)
	
	local bg = object:CreateTexture()
	bg:SetAllPoints()
	bg:SetTexture(0,0,0)
end

oUF:RegisterStyle('style', style)
oUF:Spawn('player'):SetPoint('center', -400, 0)
oUF:Spawn('target'):SetPoint('center', 400, 0)
