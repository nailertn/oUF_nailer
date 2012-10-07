local layout_name, layout = ...

local function menu(self)
	local dropdown = _G[string.gsub(self.unit, '^.', string.upper)..'FrameDropDown']
	if(dropdown) then
		ToggleDropDownMenu(1, nil, dropdown, 'cursor')
	end
end

local function health_post_update(health, unit, min, max)
	local object = health.__owner
	
	if health.disconnected then
		local color = object.colors.disconnected
		health:SetStatusBarColor(color[1], color[2], color[3])
	end
	
	local heal = object.HealPrediction
	if heal then
		local r, g, b = health:GetStatusBarColor()
		
		if heal.heal_bar then
			heal.heal_bar:SetStatusBarColor(r * 0.5, g * 0.5, b * 0.5)
		end
	end
end

local function heal_prediction_override(object, event, unit)
	if object.unit ~= unit then return end

	local heal = object.HealPrediction
	local incoming = UnitGetIncomingHeals(unit) or 0
	
	if (incoming == 0) or (heal.heal_threshold and incoming < heal.heal_threshold) then
		if heal.heal_bar then
			heal.heal_bar:Hide()
		end
		
		if heal.heal_box then
			heal.heal_box:Hide()
		end
	else
		local health, health_max = UnitHealth(unit), UnitHealthMax(unit)

		if health + incoming > health_max * heal.overflow then
			incoming = health_max * heal.overflow - health
		end
		
		if heal.heal_bar then
			heal.heal_bar:SetMinMaxValues(0, health_max)
			heal.heal_bar:SetValue(incoming)
			heal.heal_bar:Show()
		end
		
		if heal.heal_box then
			heal.heal_box:Show()
		end
	end
end

local abbreviate_number = function(number)
	local x = abs(number)
	
	if x < 1e3 then
		return '%d', number
	elseif x < 1e6 then
		return '%dk', number / 1e3
	else
		return '%.2fm', number / 1e6
	end
end

oUF.Tags.Events['my_threatcolor'] = 'UNIT_THREAT_SITUATION_UPDATE'
oUF.Tags.Methods['my_threatcolor'] = function(unit)
	return (UnitThreatSituation(unit) or 0) > 1 and '|cffff0000'
end

oUF.Tags.Events['my_status'] = 'UNIT_CONNECTION UNIT_MAXHEALTH UNIT_HEALTH INCOMING_RESURRECT_CHANGED UNIT_PHASE'
oUF.Tags.Methods['my_status'] = function(unit)
	if not UnitIsConnected(unit) then
		return 'DC'
	elseif not UnitInPhase(unit) then
		return 'phase'
	elseif UnitHasIncomingResurrection(unit) then
		return 'res'
	elseif UnitIsDead(unit) then
		return UnitAura(unit, 'Soulstone Resurrection') and 'SS' or 'dead'
	elseif UnitIsGhost(unit) then
		return 'ghost'
	else
		local missing = UnitHealthMax(unit) - UnitHealth(unit)
		return missing > 0 and format(abbreviate_number(-missing))
	end
end

local grid_post_create_indicator
do
	local function update_status_visibility(indicator)
		if indicator:IsShown() then
			indicator.status:Hide()
		else
			indicator.status:Show()
		end
	end
	
	function grid_post_create_indicator(grid, indicator, id)
		if id ~= 'center' then return end
		
		indicator.text:ClearAllPoints()
		indicator.text:SetPoint("bottom", 2, -2)
		
		indicator:HookScript('OnShow', update_status_visibility)
		indicator:HookScript('OnHide', update_status_visibility)
		indicator.status = grid.__owner.status
		update_status_visibility(indicator)
	end
end

local function range_update_disconnected_alpha(object, event, unit)
	if object.unit ~= unit then return end
	object:SetAlpha(object.Range.insideAlpha)
end

local width = 108
local height = 48
local offset = 1

local function style(object, unit)
	object.menu = menu
	object:RegisterForClicks'AnyUp'
	
	object:SetScript('OnEnter', UnitFrame_OnEnter)
	object:SetScript('OnLeave', UnitFrame_OnLeave)
	
	-- health
	local health = CreateFrame('StatusBar', nil, object)
	health:SetPoint('topleft', 4, -4)
	health:SetPoint('bottomright', -4, 4)
	health:SetStatusBarTexture(layout.texture)
	health.frequentUpdates = true
	health.colorReaction = true
	health.colorClass = true
	health.PostUpdate = health_post_update
	object.Health = health
	
	local health_bg = object:CreateTexture()
	health_bg:SetPoint('topleft', 3, -3)
	health_bg:SetPoint('bottomright', -3, 3)
	health_bg:SetTexture(0,0,0)
	
	-- edge
	local edge = CreateFrame('Frame', nil, object)
	edge:SetPoint('topleft', 1, -1)
	edge:SetPoint('bottomright', -1, 1)
	edge:SetBackdrop({ edgeFile = layout.solid, edgeSize = 2 })
	edge.SetVertexColor = edge.SetBackdropBorderColor
	edge.heal_threshold = layout.heal_threshold
	object.edge = edge
	
	local edge_bg = CreateFrame('Frame', nil, edge)
	edge_bg:SetAllPoints(object)
	edge_bg:SetBackdrop({ edgeFile = layout.solid, edgeSize = 1 })
	edge_bg:SetBackdropBorderColor(0,0,0)
	
	-- heal
	local heal_bar = CreateFrame('StatusBar', nil, object)
	heal_bar:SetPoint('left', health:GetStatusBarTexture(), 'right', 1, 0)
	heal_bar:SetSize(width - 8, height - 8)
	heal_bar:SetStatusBarTexture(layout.texture)
	
	local heal_box = CreateFrame('Frame', nil, health)
	heal_box:SetPoint('bottomleft', -1, -1)
	heal_box:SetSize(17, 9)
	heal_box:SetBackdrop(layout.backdrop)
	heal_box:SetBackdropColor(0,1,0)
	heal_box:SetBackdropBorderColor(0,0,0)
	
	object.HealPrediction = {
		heal_bar = heal_bar,
		heal_box = heal_box,
		overflow = 1,
		heal_threshold = layout.heal_threshold,
		Override = heal_prediction_override,
	}
	
	-- strings
	local name = health:CreateFontString()
	name:SetPoint('top', 0, -12)
	name:SetFont(layout.font1, layout.font1_size, layout.font1_flags)
	object:Tag(name, '[my_threatcolor][name]')
	object.name = name
	
	local status = health:CreateFontString()
	status:SetPoint('bottom', 0, 3)
	status:SetFont(layout.font1, layout.font1_size, layout.font1_flags)
	object:Tag(status, '[my_status]')
	object.status = status
	
	-- grid
	local grid = CreateFrame('Frame', nil, health)
	grid:SetAllPoints()
	grid.font = layout.font2
	grid.font_size = layout.font2_size
	grid.font_flags = layout.font2_flags
	grid.active_auras = layout.grid_db.active_auras
	grid.post_create_indicator = grid_post_create_indicator
	object.grid = grid
	
	-- range
	object.Range = {
		insideAlpha = 1,
		outsideAlpha = 0.3,
	}
	
	object:RegisterEvent('UNIT_CONNECTION', range_update_disconnected_alpha)
	
	-- overlay
	local overlay = CreateFrame('Frame', nil, object)
	overlay:SetAllPoints(health_bg)
	overlay:SetFrameStrata('HIGH')
	object.overlay = overlay
	
	local role = overlay:CreateTexture()
	role:SetPoint('center', health, 'bottomleft')
	role:SetSize(14, 14)
	object.LFDRole = role
	
	local readycheck = overlay:CreateTexture()
	readycheck:SetPoint('center', health, 'center', 0, -15)
	readycheck:SetSize(30, 30)
	object.ReadyCheck = readycheck
	
	local raidicon = overlay:CreateTexture(nil, 'ARTWORK')
	raidicon:SetPoint('top', 0, 3)
	raidicon:SetSize(22, 22)
	object.RaidIcon = raidicon
	
	-- misc
	object.highlight = true
end

oUF:RegisterStyle(layout_name .. '_group_style', style)

local function spawn_layout(name, num, visibility)
	oUF:Factory(function()
		oUF:SetActiveStyle(layout_name .. '_group_style')
		
		layout[name] = {}
		
		local last
		local helper = CreateFrame('Frame', layout_name .. '_helper_' .. name, UIParent)
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