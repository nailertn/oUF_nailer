local function update(object, event, unit)
	if object.unit ~= unit and event ~= 'PLAYER_TARGET_CHANGED' then return end
	
	local unit = object.unit
	local edge = object.edge
	
	if UnitIsUnit(unit, 'target') then
		edge:SetVertexColor(1,1,1)
	elseif (UnitThreatSituation(unit) or 0) > 1 then
		edge:SetVertexColor(1,0,0)
	else
		local incoming = UnitGetIncomingHeals(unit) or 0
		local threshold = edge.heal_threshold or 0
		
		if incoming > threshold then
			edge:SetVertexColor(0,1,0)
		else
			return edge:Hide()
		end
	end
	
	edge:Show()
end

local function enable(object)
	if object.edge then
		object:RegisterEvent('PLAYER_TARGET_CHANGED', update)
		object:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE',update)
		object:RegisterEvent('UNIT_HEAL_PREDICTION', update)
		
		return true
	end
end

local function disable(object)
	if object.edge then
		object:UnregisterEvent('PLAYER_TARGET_CHANGED', update)
		object:UnregisterEvent('UNIT_THREAT_SITUATION_UPDATE', update)
		object:UnregisterEvent('UNIT_HEAL_PREDICTION', update)
		
		object.edge:Hide()
	end
end

oUF:AddElement('edge', update, enable, disable)
