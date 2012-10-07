local layout_name, layout = ...

local NOW
local GetTime = GetTime

local indicator_metatable
do
	local to_update = {}
	local total = 0
	local frequency = 0.1
	
	local update_frame = CreateFrame'Frame'
	update_frame:SetScript('OnUpdate', function(self, elapsed)
		total = total + elapsed
		if total < frequency then return end
		total = 0
		
		NOW = GetTime()
		
		for indicator, expiration in next, to_update do
			indicator:update(expiration, NOW)
		end
		
		if not next(to_update) then
			self:Hide()
		end
	end)
	
	indicator_metatable = setmetatable({
	
		start_update = function(self, entry)
			self.update = entry.custom_update
			self:update(entry.expiration)
			to_update[self] = entry.expiration
			update_frame:Show()
		end,
		
		stop_update = function(self)
			to_update[self] = nil
		end,
		
		update = function(self, expiration)
			if NOW < expiration then
				self.text:SetFormattedText("%d", ceil(expiration - NOW))
			else
				self:stop_update()
			end
		end,
		
	}, getmetatable(CreateFrame'Frame'))
	indicator_metatable.__index = indicator_metatable
end

local create_indicator
do
	local backdrop = layout.backdrop or {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1
	}
	
	function create_indicator(grid, id)
		local settings = grid.indicator_settings[id]
		
		local indicator = CreateFrame('Frame', nil, grid)
		indicator:SetPoint(settings.anchor, settings.x_offset, settings.y_offset)
		indicator:SetSize(settings.width, settings.height)
		indicator:SetBackdrop(backdrop)
		indicator:SetBackdropBorderColor(0,0,0)
		
		if settings.icon then
			local outline = indicator:CreateTexture(nil, 'BORDER')
			outline:SetPoint('topleft', 2, -2)
			outline:SetPoint('bottomright', -2, 2)
			outline:SetTexture(0,0,0)
			
			indicator.icon = indicator:CreateTexture(nil, "ARTWORK")
			indicator.icon:SetPoint("topleft", 3, -3)
			indicator.icon:SetPoint("bottomright", -3, 3)
			indicator.icon:SetTexCoord(.08, .92, .08, .92)
		end
		
		if settings.text then
			indicator.text = indicator:CreateFontString(nil, "OVERLAY")
			
			if id == "center" then
				indicator.text:SetPoint("bottom", 2, -2)
			else
				indicator.text:SetPoint("center", 2, 2)
			end
			
			indicator.text:SetFont(grid.font, grid.font_size, grid.font_flags)
		end
		
		indicator.priority = 0
		
		grid.indicators[id] = indicator
		setmetatable(indicator, indicator_metatable)
		
		if grid.post_create_indicator then
			grid:post_create_indicator(indicator, id)
		end
		
		return indicator
	end
end

local function init_indicators(grid, indicators, aura_cache)
	NOW = GetTime()
	
	for _, indicator in next, indicators do
		if indicator.priority > 0 then
			local entry = indicator.entry
			local settings = indicator.settings
			
			if settings.custom_init then
				settings.custom_init(grid, indicator, aura_cache, entry)
			else
				if indicator.icon then
					indicator.icon:SetTexture(settings.icon or entry.icon)
				end
				
				local color = (settings.color2 and settings["color" .. entry.count]) or settings.color or grid.default_color
				indicator:SetBackdropColor(color[1], color[2], color[3])
				
				if indicator.text then
					if settings.update and (settings.update ~= 'mine' or entry.caster == 'player') and entry.expiration > 0 then
						indicator:start_update(entry)
					else
						if settings.count and (settings.count ~= 'mine' or entry.caster == 'player') then
							indicator.text:SetText(entry.count > 0 and entry.count)
						else
							indicator.text:SetText()
						end
						
						indicator:stop_update()
					end
				end
				
				indicator:Show()
			end
		else
			indicator:stop_update()
			indicator:Hide()
		end
	end
end

local function filter_active_auras(grid, indicators, db, cache)
	for _, entry in next, cache do
		local settings = db[entry.id] or db[entry.name]
		local indicator = settings and (indicators[settings.indicator] or create_indicator(grid, settings.indicator))
		local priority = settings and (entry.caster == 'player' and settings.priority + 0.1 or settings.priority)
		
		if (priority and indicator.priority < priority) and (
				(settings.custom_filter and settings.custom_filter(grid, indicator, cache, entry))
			or
				((not settings.mine or entry.caster == "player") and
				(not settings.min_count or settings.min_count <= entry.count) and
				(not settings.max_count or settings.max_count >= entry.count))
		) then
			indicator.entry = entry
			indicator.settings = settings
			indicator.priority = priority
		end
	end
end

local function filter_missing_auras(grid, indicators, db, cache)
	for key, settings in next, db do
		local indicator = indicators[settings.indicator] or create_indicator(grid, settings.indicator)
		
		if settings.priority > indicator.priority then
			local name = key
			local id = tonumber(key)
			
			local found = cache[name]
			
			if not found and id then
				for _, entry in next, cache do
					if entry.id == id then
						found = true
						break
					end
				end
			end
			
			if not found then
				indicator.settings = settings
				indicator.priority = priority
			end
		end
	end
end

local filter_debuff_types
do
	local debuff_type_settings = {
		Curse	= { 0.60, 0.00, 1.00 },
		Disease	= { 0.60, 0.40, 0.00 },
		Magic	= { 0.20, 0.60, 1.00 },
		Poison	= { 0.00, 0.60, 0.00 },
	}
	
	for k,t in next, debuff_type_settings do
		t.color = t
	end
	
	function filter_debuff_types(grid, indicators, cache)
		for _, entry in next, cache do
			local debuff_type = entry.debuff_type
			
			if debuff_type and debuff_type ~= '' then
				local indicator = indicators[debuff_type] or create_indicator(grid, debuff_type)
				
				indicator.priority = 1
				indicator.settings = debuff_type_settings[debuff_type]
			end
		end
	end
end

local function update(object, event, aura_cache)
	local grid = object.grid
	local indicators, db = grid.indicators
	
	for _, indicator in next, indicators do
		indicator.priority = 0
	end
	
	db = grid.active_auras
	if db then
		filter_active_auras(grid, indicators, db, aura_cache.buffs)
		filter_active_auras(grid, indicators, db, aura_cache.debuffs)
	end
	
	db = grid.missing_auras
	if db then
		filter_missing_auras(grid, indicators, db, aura_cache.directory)
	end
	
	if grid.filter_debuff_types then
		filter_debuff_types(grid, indicators, aura_cache.debuffs)
	end
	
	init_indicators(grid, indicators, aura_cache)
end

local defaults = setmetatable({
	filter_debuff_types	= true,
	default_color		= { 1.00, 1.00, 1.00 },
	font				= 'Fonts\\FRIZQT__.TTF',
	font_size			= 10,
	font_flags			= nil,
	indicator_settings	= {
	
		center 			= { height = 26, width = 26, anchor = "bottom", x_offset = 0, y_offset = -4, text = true, icon = true },
		topleft_1 		= { height = 13, width = 17, anchor = "topleft", x_offset = -1, y_offset = 1, text = true },
		topleft_2 		= { height = 13, width = 17, anchor = "topleft", x_offset = 15, y_offset = 1, text = true },
		topright_1 		= { height = 13, width = 17, anchor = "topright", x_offset = 1, y_offset = 1, text = true },
		topright_2 		= { height = 13, width = 17, anchor = "topright", x_offset = -15, y_offset = 1, text = true },
		bottomleft_1	= { height = 9, width = 17, anchor = "bottomleft", x_offset = -1, y_offset = -1, increase_level = 1 },
		bottomleft_2	= { height = 9, width = 17, anchor = "bottomleft", x_offset = 15, y_offset = -1, increase_level = 1 },
		Poison 			= { height = 9, width = 9, anchor = "bottomright", x_offset = 1, y_offset = -1 },
		Magic 			= { height = 9, width = 9, anchor = "bottomright", x_offset = -7, y_offset = -1 },
		Disease			= { height = 9, width = 9, anchor = "bottomright", x_offset = -15, y_offset = -1 },
		Curse			= { height = 9, width = 9, anchor = "bottomright", x_offset = -23, y_offset = -1 },
	},
}, getmetatable(CreateFrame'Frame'))
defaults.__index = defaults

local function enable(object)
	local grid = object.grid
	if grid then
		grid.__owner = object
		grid.indicators = grid.indicators or {}
		setmetatable(grid, defaults)
		
		if rawget(grid, 'indicator_settings') then
			setmetatable(grid.indicator_settings, defaults.indicator_settings)
		end
		
		layout.aura_cache.register_callback(object, update)
	end
end

local function disable(object)
	local grid = object.grid
	if grid then
		for _, indicator in next, indicators do
			indicator:stop_timer()
			indicator:Hide()
		end
		
		layout.aura_cache.unregister_callback(object, update)
	end
end

oUF:AddElement('grid', nil, enable, disable)