layout_name, layout = ...

local NOW
local GetTime = GetTime

local start_timer, stop_timer
do
	local function enable_accented(button)
		local container = button.__owner
		button.time:SetFont(container.font, container.font_size * 2, container.font_flags)
		button.is_accented = true
	end
	
	local function disable_accented(button)
		local container = button.__owner
		button.time:SetFont(container.font, container.font_size, container.font_flags)
		button.is_accented = false
	end
	
	local function update_timer(button, expiration)
		local value = expiration - NOW
		
		if value > 3600 then
			button.time:SetFormattedText("%dh", ceil(value / 3600))
		elseif value > 60 then
			button.time:SetFormattedText("%dm", ceil(value / 60))
		elseif value > 9 then
			button.time:SetText(ceil(value))
		elseif value > 0 then
		
			if button.accent_expiring then
				button.accent_expiring = nil
				enable_accented(button)
			end
			
			if value > 6 then
				button.time:SetFormattedText("|cffffff00%d", ceil(value))
			elseif value > 3 then
				button.time:SetFormattedText("|cffff8800%d", ceil(value))
			else
				button.time:SetFormattedText("|cffff0000%d", ceil(value))
			end		
		else
			stop_timer(button)
		end
	end
	
	local to_update = {}
	local total = 0
	local frequency = 0.1
		
	local update_frame = CreateFrame'Frame'
	update_frame:SetScript('OnUpdate', function(self, elapsed)
		total = total + elapsed
		if total < frequency then return end
		total = 0
		
		NOW = GetTime()
		
		for button, expiration in next, to_update do
			update_timer(button, expiration)
		end
		
		if not next(to_update) then
			self:Hide()
		end
	end)
	
	function start_timer(button, expiration)
		if button.__owner.accent_expiring then
			if button.is_accented then
				disable_accented(button)
			end
			
			button.accent_expiring = true			
		end
		
		to_update[button] = expiration
		update_frame:Show()
		update_timer(button, expiration)
	end
	
	function stop_timer(button)
		to_update[button] = nil
		button.time:SetText()
	end
end

local function on_update_container(self, elapsed)
	
	local exit_time = self.exit_time
	if exit_time then
		if exit_time - elapsed < 0 then
			return layout.aura_cache.force_update(self.__owner, 'exit filtered')
		end
		self.exit_time = exit_time - elapsed
	end
	
	if self.pause_filtering then
		if self:IsMouseOver() then
			self.mouseout_time = 0
		else
			self.mouseout_time = self.mouseout_time + elapsed
			if self.mouseout_time > 1 then
				self.mouseover_time = 0
				self.pause_filtering = false
				return layout.aura_cache.force_update(self.__owner, 'collapse filtered')
			end
		end
	else
		if self[1]:IsMouseOver() then
			self.mouseover_time = self.mouseover_time + elapsed
			if self.mouseover_time > 0.25 then
				self.mouseout_time = 0
				self.pause_filtering = true
				return layout.aura_cache.force_update(self.__owner, 'expand filtered')
			end
		else
			self.mouseover_time = 0
		end
	end
end

local function update_tooltip(button)
	GameTooltip:SetUnitAura(button.__owner.__owner.unit, button.index, button.__owner.type)
end

local function on_enter(button)
	GameTooltip:SetOwner(button, "ANCHOR_TOPLEFT")
	update_tooltip(button)
end

local function on_leave(button)
	GameTooltip:Hide()
end

local function on_click(button)
	if InCombatLockdown() then return end
	
	CancelUnitBuff(button.__owner.__owner.unit, button.index, button.__owner.type)
end

local function create_button(container)
	container.created_buttons = (container.created_buttons or 0) + 1
	
	local button = CreateFrame('Button', nil, container)
	button:SetSize(container.size, container.size)
	button.__owner = container
	tinsert(container, button)
	
	local background = button:CreateTexture(nil, 'BACKGROUND')
	background:SetAllPoints()
	background:SetTexture(0,0,0)
	
	button.border = button:CreateTexture(nil, 'BORDER')
	button.border:SetPoint('topleft', 1, -1)
	button.border:SetPoint('bottomright', -1, 1)
	button.border:SetTexture('Interface\\Buttons\\WHITE8X8')
	button.border:SetVertexColor(1,1,1)
	
	local outline = button:CreateTexture(nil, 'BORDER', nil, 2)
	outline:SetPoint('topleft', 2, -2)
	outline:SetPoint('bottomright', -2, 2)
	outline:SetTexture(0,0,0)
	
	button.icon = button:CreateTexture(nil, 'ARTWORK')
	button.icon:SetPoint('topleft', 3, -3)
	button.icon:SetPoint('bottomright', -3, 3)
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	
	button.time = button:CreateFontString(nil, 'OVERLAY')
	button.time:SetPoint('center')
	button.time:SetFont(container.font, container.font_size, container.font_flags)
	
	button.count = button:CreateFontString(nil, 'OVERLAY')
	button.count:SetPoint('topright', -4, -4)
	button.count:SetFont(container.font, container.font_size, container.font_flags)
	
	button.UpdateTooltip = update_tooltip
	button:SetScript('OnEnter', on_enter)
	button:SetScript('OnLeave', on_leave)
	
	button:RegisterForClicks("RightButtonUp")
	button:SetScript('OnClick', on_click)
	
	return button
end

local function enable_filter_button(container, num_filtered)
	local button = container[1] or create_button(container)
	
	if container.debuff_coloring then
		button.border:SetVertexColor(container.color.r, container.color.g, container.color.b)
	end
	
	button.icon:SetTexture('Interface\\Icons\\Inv_misc_grouplooking')
	button.count:SetText(num_filtered)
	button.time:SetText()
	button:Show()
end

local function sort_auras(a, b)
	if a.duration == 0 then
		if b.duration == 0 then
			return a.name < b.name
		else
			return true
		end
	elseif b.duration == 0 then
		return false
	else
		return a.expiration > b.expiration
	end
end

local function filter_auras(container, cache)
	local counter = 0
	local exit_first
	
	for index, entry in next, cache do
		local is_filtered
		
		if entry.consolidate then
			is_filtered = true
			
			if entry.duration > 30 then
				local exit_time = entry.expiration - NOW - max(10, entry.duration / 10)
				
				if exit_time > 0 then
					exit_first = exit_first and min(exit_time, exit_first) or exit_time
				else
					is_filtered = false
				end
			end
		end
		
		entry.is_filtered = is_filtered
		
		if is_filtered then
			counter = counter + 1
		end
	end
	
	return counter > 1 and counter, exit_first
end

local function update_auras(container, cache, is_filtered)
	local index = 1
	local hidden = 0
	local visible = is_filtered and 1 or 0
	
	while visible < container.max do
		local entry = cache[index]
		local button = container[visible + hidden + 1]
		
		if entry then
			if not is_filtered or not entry.is_filtered then
				button = button or create_button(container)
				
				if container.debuff_coloring then
					local color = DebuffTypeColor[entry.debuff_type] or container.border_color
					button.border:SetVertexColor(color.r, color.g, color.b)
				end
				
				button.icon:SetTexture(entry.icon)
				
				button.count:SetText((entry.count or 0) > 1 and entry.count or nil)
				
				if entry.duration > 0 then
					start_timer(button, entry.expiration)
				else
					stop_timer(button)
				end
				
				button.index = entry.index
				
				button:Show()
				visible = visible + 1
			end
		elseif button then
			stop_timer(button)
			
			button:Hide()
			hidden = hidden + 1
		else
			break
		end
		
		index = index + 1
	end
	
	return visible
end

local function resize_container(container, visible)
	local width = min(container.per_row, visible) * (container.size + container.spacing) - container.spacing
	local height = ceil(visible / container.per_row) * (container.size + container.spacing) - container.spacing
	
	container:SetSize(width, height)
end

local function anchor_buttons(container, from, to)
	local size = container.size + container.spacing
	local anchor = container.anchor
	local dir_x = container.grow_x == 'right' and 1 or -1
	local dir_y = container.grow_y == 'up' and 1 or -1
	local per_row = container.per_row

	for index = from, to do
		local button = container[index]
		
		local col = (index - 1) % per_row
		local row = floor((index - 1) / per_row)
		button:SetPoint(anchor, col * size * dir_x, row * size * dir_y)
	end
end

local function update_container(container, event, cache)
	if container.filtering_enabled then
		if container.pause_filtering then
			container.has_filtered, container.exit_time = false, false
		else
			container.has_filtered, container.exit_time = filter_auras(container, cache)
		end
		
		if container.has_filtered then
			enable_filter_button(container, container.has_filtered)
		end
		
		if container.pause_filtering or container.has_filtered then
			if not container:GetScript('OnUpdate') then
				container:SetScript('OnUpdate', on_update_container)
				container.mouseover_time, container.mouseout_time = 0, 0
			end
		else
			container:SetScript('OnUpdate', nil)
		end
	end
	
	if container.sort then
		sort(cache, container.sort)
	end
	
	local visible = update_auras(container, cache, container.has_filtered)
	
	if container.filtering_enabled and (event == 'OnShow' or (container.visible == 0 and visible ~= 0)) then
		container.mouseover_time, container.mouseout_time = 0, 0
	end
	
	if container.anchored_buttons < container.created_buttons then
		anchor_buttons(container, container.anchored_buttons + 1, container.created_buttons)
		container.anchored_buttons = container.created_buttons
	end
	
	if container.visible ~= visible then
		container.visible = visible
		resize_container(container, visible)
	end
	
	if visible == 0 then
		container:Hide()
	else
		container:Show()
	end
end

local function update_object(object, event, cache)
	NOW = GetTime()
	
	if object.buffs then
		update_container(object.buffs, event, cache.buffs)
	end
	
	if object.debuffs then
		update_container(object.debuffs, event, cache.debuffs)
	end
end

local defaults = setmetatable({
	size 				= 40,
	spacing 			= 1,
	anchor				= "bottomleft",
	grow_x				= "right",
	grow_y				= "up",
	max 				= 24,
	per_row				= 8,
	font				= "Fonts\\FRIZQT__.TTF",
	font_size			= 10,
	font_flags			= nil,
	border_color		= { r = 1, g = 1, b = 1 },
	debuff_coloring		= true,
	sort				= sort_auras,
	filtering_enabled	= true,
	mouseout_delay		= 2,
	accent_expiring		= true,
}, getmetatable(CreateFrame'Frame'))
defaults.__index = defaults

local function enable_container(object, container, type)
	setmetatable(container, defaults)
	container.__owner = object
	container.type = type
	container.created_buttons = 0
	container.anchored_buttons = 0
	container.visible = 0
	container.pause_filtering = nil
	container.debuff_coloring = container.debuff_coloring and type == 'HARMFUL'
	
	return container
end

local function disable_container(object, container)
	container:SetScript('OnUpdate', nil)
	container:Hide()
	
	for _, button in ipairs(container) do
		stop_timer(button)
	end
	
	return container
end

local function enable_object(object)
	local buffs = object.buffs and enable_container(object, object.buffs, 'HELPFUL')
	local debuffs = object.debuffs and enable_container(object, object.debuffs, 'HARMFUL')
	
	if buffs or debuffs then
		layout.aura_cache.register_callback(object, update_object)
	end
end

local function disable_object(object)
	local buffs = object.buffs and disable_container(object, object.buffs)
	local debuffs = object.debuffs and disable_container(object, object.debuffs)
	
	if buffs or debuffs then
		layout.aura_cache.unregister_callback(object, update_object)
	end
end

oUF:AddElement("aura", nil, enable_object, disable_object)