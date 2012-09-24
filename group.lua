local layout_name, layout = ...

local function style(object, unit)
	local bg = object:CreateTexture()
	bg:SetAllPoints()
	bg:SetTexture(0,0,0)
end

oUF:RegisterStyle(layout_name .. ' group style', style)

local width = 108
local height = 48
local offset = 1

local function spawn_layout(name, num, visibility)
	oUF:Factory(function()
		oUF:SetActiveStyle(layout_name .. ' group style')
		
		layout[name] = {}
		
		local last
		local helper = CreateFrame('Frame', nil, UIParent)
		helper:SetSize(width * num - (num - 1), height * 5 - (5 - 1))
		helper:SetPoint('bottom', 0, 37)
		
		for index = 1, num do
			local group = oUF:SpawnHeader(nil, nil, visibility,
				'groupFilter', index,
				'showSolo', true,
				'showParty', true,
				'showPlayer', true,
				'showRaid', true,
				'yOffset', offset,
				
				'oUF-initialConfigFunction',
					'self:SetWidth(' .. width .. ')' ..
					'self:SetHeight(' .. height .. ')'
			)
			
			if last then
				group:SetPoint('topleft', last, 'topright', -offset, 0)
			else
				group:SetPoint('topleft', helper, 'topleft')
			end
			
			tinsert(layout[name], group)
			last = group
			group:Show()
		end
	end)
end

spawn_layout('layout25', 5, 'custom [@raid26,exists] hide; show')
spawn_layout('layout40', 8, 'custom [@raid26,exists] show; hide')
