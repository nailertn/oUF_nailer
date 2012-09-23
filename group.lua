local layout_name, layout = ...

local function style(object, unit)
	local bg = object:CreateTexture()
	bg:SetAllPoints()
	bg:SetTexture(0,0,0)
end

oUF:RegisterStyle(layout_name .. ' group style')

local width = 100
local height = 70
local offset = 4

oUF:Factory(function()
	oUF:SetActiveStyle(layout_name .. ' solo style')
	
	layout.groups = {}
	
	for group_index = 1, NUM_RAID_GROUPS do
		local group = oUF:SpawnHeader(nil, nil, nil,
			'groupFilter', group_index,
			'showSolo', true,
			'showParty', true,
			'showPlayer', true,
			'showRaid', true,
			'yOffset', -offset,
			
			'oUF-initialConfigFunction',
				'self:SetWidth(' .. width .. ')' ..
				'self:SetHeight(' .. height .. ')'
		)
		
		tinsert(layout.groups, group)
		group:Show()
	end
	
	layout.update_groups()
end)