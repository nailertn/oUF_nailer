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
	end
	
	layout.update_groups()
end)

function layout.update_groups()
	local previous_group
	for group_index, group in next, layout.groups do
		if group_index > visible then
			group:Hide()
		else
			if previous_group then
				group:SetPoint('topleft', previous_group, 'topright', offset, 0)
			else
				group:SetPoint('topleft', UIParent, 'bottom', -258, 470)
			end
			
			group:SetAttribute('oUF-initialConfigFunction',
				'self:SetWidth(' .. width .. ')' ..
				'self:SetHeight(' .. height .. ')'
			)
			
			group:SetSize(width, (height + offset) * #group - offset)
			
			for child_index = 1, #group do
				local child = group[child_index]
				child:SetSize(width, height)
			end
			
			previous_group = group
			group:Show()
		end
	end
end
