local ADDON_NAME = "Magnify-WotLK"

local MIN_ZOOM = 1.0
local MAX_ZOOM = 4.0
local ZOOM_STEP = 0.2

local MINIMODE_MIN_ZOOM = 1.0
local MINIMODE_MAX_ZOOM = 10.0
local MINIMODE_ZOOM_STEP = 0.1

local function UpdatePointRelativeTo(frame, newRelativeFrame)
	local currentPoint, _currentRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY = frame:GetPoint()
	frame:ClearAllPoints()
	frame:SetPoint(currentPoint, newRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY)
end

local function GetElvUI()
	if ElvUI and ElvUI[1] then
		return ElvUI[1]
	end
	return nil
end

local function MagnifySetDetailFrameScale(num)
	WorldMapDetailFrame:SetScale(num)

	-- Adjust frames to inversely scale with the detail frame so they maintain relative screen size
	WorldMapFrameAreaFrame:SetScale(1/WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size)
	WorldMapPOIFrame:SetScale(1/WORLDMAP_SETTINGS.size)

	WorldMapPlayer:SetScale(1/WorldMapDetailFrame:GetScale())
	WorldMapDeathRelease:SetScale(1/WorldMapDetailFrame:GetScale())
	WorldMapCorpse:SetScale(1/WorldMapDetailFrame:GetScale())
	local numFlags = GetNumBattlefieldFlagPositions()
	for i=1, numFlags do
		local flagFrameName = "WorldMapFlag"..i;
		if (_G[flagFrameName]) then
			_G[flagFrameName]:SetScale(1/WorldMapDetailFrame:GetScale())
		end
	end

	for i=1, MAX_PARTY_MEMBERS do
		if (_G["WorldMapParty"..i]) then
			_G["WorldMapParty"..i]:SetScale(1/WorldMapDetailFrame:GetScale())
		end
	end

	for i=1, MAX_RAID_MEMBERS do
		if (_G["WorldMapRaid"..i]) then
			_G["WorldMapRaid"..i]:SetScale(1/WorldMapDetailFrame:GetScale())
		end
	end

	for i=1, #MAP_VEHICLES do
		if (MAP_VEHICLES[i]) then
			MAP_VEHICLES[i]:SetScale(1/WorldMapDetailFrame:GetScale())
		end
	end
end

local function ElvUI_SetupWorldMapFrame()
	local worldMap = GetElvUI():GetModule("WorldMap")
	if not worldMap then
		return
	end
	
	if (worldMap.coordsHolder and worldMap.coordsHolder.playerCoords) then
		UpdatePointRelativeTo(worldMap.coordsHolder.playerCoords, WorldMapScrollFrame)
	end

	if (WorldMapDetailFrame.backdrop) then
		WorldMapDetailFrame.backdrop:Hide()

		local _, worldMapRelativeFrame = WorldMapFrame.backdrop
		if (worldMapRelativeFrame == WorldMapDetailFrame) then
			UpdatePointRelativeTo(WorldMapFrame.backdrop, WorldMapScrollFrame)
		end
	end
	
	if (WorldMapFrame.backdrop) then
		-- We will take over the SetPoint behavior ElvUI, I'm sorry
		WorldMapFrame.backdrop.Point = function() return; end

		WorldMapFrame.backdrop:ClearAllPoints()
		if (WorldMapZoneMinimapDropDown:IsVisible()) then
			WorldMapFrame.backdrop:SetPoint("TOPLEFT", WorldMapZoneMinimapDropDown, "TOPLEFT", -20, 40)
		else
			WorldMapFrame.backdrop:SetPoint("TOPLEFT", WorldMapTitleButton, "TOPLEFT", 0, 0)
		end
		WorldMapFrame.backdrop:SetPoint("BOTTOM", WorldMapQuestShowObjectives, "BOTTOM", 0, 0)
		WorldMapFrame.backdrop:SetPoint("RIGHT", WorldMapFrameCloseButton, "RIGHT", 0, 0)
	end
end

local function MagnifySetupWorldMapFrame()
	WorldMapScrollFrameScrollBar:Hide()
	WorldMapFrame:EnableMouse(true)
	WorldMapScrollFrame:EnableMouse(true)
	WorldMapScrollFrame.panning = false
	WorldMapScrollFrame.moved = false
	
	if (WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE) then
		WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -726, -99);
		WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 8, 4);
	elseif (WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE) then
		WorldMapScrollFrame:SetPoint("TOPLEFT", 37, -66);
		WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9);

		WorldMapFrame:SetPoint("TOPLEFT", WorldMapScreenAnchor, 0, 0);
		WorldMapFrame:SetScale(WorldMapScreenAnchor.preferredMinimodeScale);
		WorldMapFrame:SetMovable("true");
		WorldMapTitleButton:Show()
		WorldMapTitleButton:ClearAllPoints()
		WorldMapTitleButton:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 13, -13)
		WorldMapFrameTitle:Show()
		WorldMapFrameTitle:ClearAllPoints();
		WorldMapFrameTitle:SetPoint("CENTER", WorldMapTitleButton, "CENTER", 32, 0)
	else
		WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -502, -69);
		WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9);
	end

	WorldMapScrollFrame:SetScale(WORLDMAP_SETTINGS.size);
	
	MagnifySetDetailFrameScale(1)
	WorldMapDetailFrame:SetAllPoints(WorldMapScrollFrame)
	
	WorldMapButton:SetScale(1)
	WorldMapButton:SetAllPoints(WorldMapDetailFrame)
	WorldMapButton:SetParent(WorldMapDetailFrame)

	WorldMapPOIFrame:SetParent(WorldMapDetailFrame)
	WorldMapPlayer:SetParent(WorldMapDetailFrame)

	UpdatePointRelativeTo(WorldMapQuestScrollFrame, WorldMapScrollFrame);
	UpdatePointRelativeTo(WorldMapQuestDetailScrollFrame, WorldMapScrollFrame);

	if (GetElvUI()) then
		ElvUI_SetupWorldMapFrame()
	end
end

local function WorldMapScrollFrame_OnPan(cursorX, cursorY)
	local dX = WorldMapScrollFrame.cursorX - cursorX
	local dY = cursorY - WorldMapScrollFrame.cursorY
	dX = dX / this:GetEffectiveScale()
	dY = dY / this:GetEffectiveScale()
	if abs(dX) >= 1 or abs(dY) >= 1 then
		WorldMapScrollFrame.moved = true

		local x
		x = max(0, dX + WorldMapScrollFrame.x)
		x = min(x, WorldMapScrollFrame.maxX)
		WorldMapScrollFrame:SetHorizontalScroll(x)

		local y
		y = max(0, dY + WorldMapScrollFrame.y)
		y = min(y, WorldMapScrollFrame.maxY)
		WorldMapScrollFrame:SetVerticalScroll(y)
	end
end

local function Magnify_WorldMapButton_OnUpdate(self, elapsed)
	local x, y = GetCursorPosition();
	x = x / self:GetEffectiveScale();
	y = y / self:GetEffectiveScale();

	local centerX, centerY = self:GetCenter();
	local width = self:GetWidth();
	local height = self:GetHeight();
	local adjustedY = (centerY + (height/2) - y ) / height;
	local adjustedX = (x - (centerX - (width/2))) / width;
	
	local name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY
	if ( self:IsMouseOver() ) then
		name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = UpdateMapHighlight( adjustedX, adjustedY );
	end

	WorldMapFrame.areaName = name;
	if ( not WorldMapFrame.poiHighlight ) then
		WorldMapFrameAreaLabel:SetText(name);
	end
	if ( fileName ) then
		WorldMapHighlight:SetTexCoord(0, texPercentageX, 0, texPercentageY);
		WorldMapHighlight:SetTexture("Interface\\WorldMap\\"..fileName.."\\"..fileName.."Highlight");
		textureX = textureX * width;
		textureY = textureY * height;
		scrollChildX = scrollChildX * width;
		scrollChildY = -scrollChildY * height;
		if ( (textureX > 0) and (textureY > 0) ) then
			WorldMapHighlight:SetWidth(textureX);
			WorldMapHighlight:SetHeight(textureY);
			WorldMapHighlight:SetPoint("TOPLEFT", "WorldMapDetailFrame", "TOPLEFT", scrollChildX, scrollChildY);
			WorldMapHighlight:Show();
			--WorldMapFrameAreaLabel:SetPoint("TOP", "WorldMapHighlight", "TOP", 0, 0);
		end
		
	else
		WorldMapHighlight:Hide();
	end
	--Position player
	UpdateWorldMapArrowFrames();
	local playerX, playerY = GetPlayerMapPosition("player");
	if ( (playerX == 0 and playerY == 0) ) then
		ShowWorldMapArrowFrame(nil);
		WorldMapPing:Hide();
		WorldMapPlayer:Hide();
	else
		playerX = playerX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size
		playerY = -playerY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size
		PositionWorldMapArrowFrame("CENTER", "WorldMapDetailFrame", "TOPLEFT", playerX, playerY);
		ShowWorldMapArrowFrame(nil);

		WorldMapPlayer:SetAllPoints(PlayerArrowFrame);
		WorldMapPlayer.Icon:SetRotation(PlayerArrowFrame:GetFacing())
		WorldMapPlayer:Show();
	end

	--Position groupmates
	local playerCount = 0;
	if ( GetNumRaidMembers() > 0 ) then
		for i=1, MAX_PARTY_MEMBERS do
			local partyMemberFrame = _G["WorldMapParty"..i];
			partyMemberFrame:Hide();
		end
		for i=1, MAX_RAID_MEMBERS do
			local unit = "raid"..i;
			local partyX, partyY = GetPlayerMapPosition(unit);
			local partyMemberFrame = _G["WorldMapRaid"..(playerCount + 1)];
			if ( (partyX == 0 and partyY == 0) or UnitIsUnit(unit, "player") ) then
				partyMemberFrame:Hide();
			else
				partyX = partyX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
				partyY = -partyY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
				partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY);
				partyMemberFrame.name = nil;
				partyMemberFrame.unit = unit;
				partyMemberFrame:Show();
				playerCount = playerCount + 1;
			end
		end
	else
		for i=1, MAX_PARTY_MEMBERS do
			local partyX, partyY = GetPlayerMapPosition("party"..i);
			local partyMemberFrame = _G["WorldMapParty"..i];
			if ( partyX == 0 and partyY == 0 ) then
				partyMemberFrame:Hide();
			else
				partyX = partyX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
				partyY = -partyY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
				partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY);
				partyMemberFrame:Show();
			end
		end
	end
	-- Position Team Members
	local numTeamMembers = GetNumBattlefieldPositions();
	for i=playerCount+1, MAX_RAID_MEMBERS do
		local partyX, partyY, name = GetBattlefieldPosition(i - playerCount);
		local partyMemberFrame = _G["WorldMapRaid"..i];
		if ( partyX == 0 and partyY == 0 ) then
			partyMemberFrame:Hide();
		else
			partyX = partyX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
			partyY = -partyY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
			partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY);
			partyMemberFrame.name = name;
			partyMemberFrame.unit = nil;
			partyMemberFrame:Show();
		end
	end

	-- Position flags
	local numFlags = GetNumBattlefieldFlagPositions();
	for i=1, numFlags do
		local flagX, flagY, flagToken = GetBattlefieldFlagPosition(i);
		local flagFrameName = "WorldMapFlag"..i;
		local flagFrame = _G[flagFrameName];
		if ( flagX == 0 and flagY == 0 ) then
			flagFrame:Hide();
		else
			flagX = flagX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
			flagY = -flagY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
			flagFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", flagX, flagY);
			local flagTexture = _G[flagFrameName.."Texture"];
			flagTexture:SetTexture("Interface\\WorldStateFrame\\"..flagToken);
			flagFrame:Show();
		end
	end
	for i=numFlags+1, NUM_WORLDMAP_FLAGS do
		local flagFrame = _G["WorldMapFlag"..i];
		flagFrame:Hide();
	end

	-- Position corpse
	local corpseX, corpseY = GetCorpseMapPosition();
	if ( corpseX == 0 and corpseY == 0 ) then
		WorldMapCorpse:Hide();
	else
		corpseX = corpseX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
		corpseY = -corpseY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
		
		WorldMapCorpse:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", corpseX, corpseY);
		WorldMapCorpse:Show();
	end

	-- Position Death Release marker
	local deathReleaseX, deathReleaseY = GetDeathReleasePosition();
	if ((deathReleaseX == 0 and deathReleaseY == 0) or UnitIsGhost("player")) then
		WorldMapDeathRelease:Hide();
	else
		deathReleaseX = deathReleaseX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
		deathReleaseY = -deathReleaseY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
		
		WorldMapDeathRelease:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", deathReleaseX, deathReleaseY);
		WorldMapDeathRelease:Show();
	end
	
	-- position vehicles
	local numVehicles;
	if ( GetCurrentMapContinent() == WORLDMAP_WORLD_ID or (GetCurrentMapContinent() ~= -1 and GetCurrentMapZone() == 0) ) then
		-- Hide vehicles on the worldmap and continent maps
		numVehicles = 0;
	else
		numVehicles = GetNumBattlefieldVehicles();
	end
	local totalVehicles = #MAP_VEHICLES;
	local index = 0;
	for i=1, numVehicles do
		if (i > totalVehicles) then
			local vehicleName = "WorldMapVehicles"..i;
			MAP_VEHICLES[i] = CreateFrame("FRAME", vehicleName, WorldMapButton, "WorldMapVehicleTemplate");
			MAP_VEHICLES[i].texture = _G[vehicleName.."Texture"];
		end
		local vehicleX, vehicleY, unitName, isPossessed, vehicleType, orientation, isPlayer, isAlive = GetBattlefieldVehicleInfo(i);
		if ( vehicleX and isAlive and not isPlayer and VEHICLE_TEXTURES[vehicleType]) then
			local mapVehicleFrame = MAP_VEHICLES[i];
			vehicleX = vehicleX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
			vehicleY = -vehicleY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale() * WORLDMAP_SETTINGS.size;
			mapVehicleFrame.texture:SetRotation(orientation);
			mapVehicleFrame.texture:SetTexture(WorldMap_GetVehicleTexture(vehicleType, isPossessed));
			mapVehicleFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", vehicleX, vehicleY);
			mapVehicleFrame:SetWidth(VEHICLE_TEXTURES[vehicleType].width);
			mapVehicleFrame:SetHeight(VEHICLE_TEXTURES[vehicleType].height);
			mapVehicleFrame.name = unitName;
			mapVehicleFrame:Show();
			index = i;	-- save for later
		else
			MAP_VEHICLES[i]:Hide();
		end
		
	end
	if (index < totalVehicles) then
		for i=index+1, totalVehicles do
			MAP_VEHICLES[i]:Hide();
		end
	end

	if WorldMapScrollFrame.panning then
		WorldMapScrollFrame_OnPan(GetCursorPosition())
	end
end

local function WorldMapScrollFrame_OnMouseWheel()
	if (IsControlKeyDown() and WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE) then
		local oldScale = WorldMapFrame:GetScale()
		local newScale = oldScale + arg1 * MINIMODE_ZOOM_STEP
		newScale = max(MINIMODE_MIN_ZOOM, newScale)
		newScale = min(MINIMODE_MAX_ZOOM, newScale)

		WorldMapFrame:SetScale(newScale)
		WorldMapScreenAnchor.preferredMinimodeScale = newScale
		return
	end

	local oldScrollH = this:GetHorizontalScroll()
	local oldScrollV = this:GetVerticalScroll()

	local cursorX, cursorY = GetCursorPosition()
	cursorX = cursorX / this:GetEffectiveScale()
	cursorY = cursorY / this:GetEffectiveScale()

	local frameX = cursorX - this:GetLeft()
	local frameY = this:GetTop() - cursorY

	local oldScale = WorldMapDetailFrame:GetScale()
	local newScale
	newScale = oldScale + arg1 * ZOOM_STEP
	newScale = max(MIN_ZOOM, newScale)
	newScale = min(MAX_ZOOM, newScale)

	MagnifySetDetailFrameScale(newScale)

	this.maxX = ((WorldMapDetailFrame:GetWidth() * newScale) - this:GetWidth()) / newScale
	this.maxY = ((WorldMapDetailFrame:GetHeight() * newScale) - this:GetHeight()) / newScale
	this.zoomedIn = WorldMapDetailFrame:GetScale() > MIN_ZOOM

	local centerX = oldScrollH + frameX / oldScale
	local centerY = oldScrollV + frameY / oldScale
	local newScrollH = centerX - frameX / newScale
	local newScrollV = centerY - frameY / newScale

	newScrollH = min(newScrollH, this.maxX)
	newScrollH = max(0, newScrollH)
	newScrollV = min(newScrollV, this.maxY)
	newScrollV = max(0, newScrollV)

	this:SetHorizontalScroll(newScrollH)
	this:SetVerticalScroll(newScrollV)
end

local function WorldMapButton_OnMouseDown()
	if arg1 == 'LeftButton' and WorldMapScrollFrame.zoomedIn then
		WorldMapScrollFrame.panning = true

		local x, y = GetCursorPosition()

		WorldMapScrollFrame.cursorX = x
		WorldMapScrollFrame.cursorY = y
		WorldMapScrollFrame.x = WorldMapScrollFrame:GetHorizontalScroll()
		WorldMapScrollFrame.y = WorldMapScrollFrame:GetVerticalScroll()
		WorldMapScrollFrame.moved = false
	end
end

local function WorldMapButton_OnMouseUp()
	WorldMapScrollFrame.panning = false

	if not WorldMapScrollFrame.moved then
		WorldMapButton_OnClick(WorldMapButton, arg1)

		MagnifySetDetailFrameScale(MIN_ZOOM)

		WorldMapScrollFrame:SetHorizontalScroll(0)
		WorldMapScrollFrame:SetVerticalScroll(0)

		WorldMapScrollFrame.zoomedIn = false
	end

	WorldMapScrollFrame.moved = false
end

local function MagnifyOnFirstLoad()
	WorldMapScrollFrame:SetScrollChild(WorldMapDetailFrame)
	WorldMapScrollFrame:SetScript("OnMouseWheel",WorldMapScrollFrame_OnMouseWheel)
	WorldMapButton:SetScript("OnMouseDown",WorldMapButton_OnMouseDown)
	WorldMapButton:SetScript("OnMouseUp",WorldMapButton_OnMouseUp)
	WorldMapDetailFrame:SetParent(WorldMapScrollFrame)

	WorldMapFrameAreaFrame:SetPoint("TOP", WorldMapScrollFrame, "TOP", 0, -10)

	-- Not worth getting this ugly ping working
	WorldMapPing.Show = function() return end
	WorldMapPing:SetModelScale(0)

	-- Add higher definition arrow that will get masked correctly on pan
	-- (Default player arrow stays visible even if you pan it to be off the map)
	WorldMapPlayer.Icon = WorldMapPlayer:CreateTexture(nil, 'ARTWORK')
	WorldMapPlayer.Icon:SetSize(36, 36)
	WorldMapPlayer.Icon:SetPoint("CENTER", 0, 0)
	WorldMapPlayer.Icon:SetTexture('Interface\\AddOns\\'..ADDON_NAME..'\\assets\\WorldMapArrow')
	
	hooksecurefunc("WorldMapFrame_SetFullMapView", MagnifySetupWorldMapFrame);
	hooksecurefunc("WorldMapFrame_SetQuestMapView", MagnifySetupWorldMapFrame);
	hooksecurefunc("WorldMap_ToggleSizeDown", MagnifySetupWorldMapFrame);
	hooksecurefunc("WorldMap_ToggleSizeUp", MagnifySetupWorldMapFrame);

	_G["WorldMapQuestShowObjectives_AdjustPosition"] = function ()
		if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
			WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOMRIGHT", -30 - WorldMapQuestShowObjectivesText:GetWidth(), -9);
		else
			WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOMRIGHT", -15 - WorldMapQuestShowObjectivesText:GetWidth(), 4);
		end
	end

	WorldMapScreenAnchor:StartMoving();
	WorldMapScreenAnchor:SetPoint("TOPLEFT", 10, -118);
	WorldMapScreenAnchor:StopMovingOrSizing();

	-- Magic good default scale ratio based on screen height
	WorldMapScreenAnchor.preferredMinimodeScale = 1+(0.56 * WorldFrame:GetHeight() / WorldMapFrame:GetHeight())

	WorldMapTitleButton:SetScript("OnDragStart", function()
		WorldMapScreenAnchor:ClearAllPoints();
		WorldMapFrame:ClearAllPoints();
		WorldMapFrame:StartMoving();	
	end)

	WorldMapTitleButton:SetScript("OnDragStop", function()
		WorldMapFrame:StopMovingOrSizing();

		-- move the anchor
		WorldMapScreenAnchor:StartMoving();
		WorldMapScreenAnchor:SetPoint("TOPLEFT", WorldMapFrame);
		WorldMapScreenAnchor:StopMovingOrSizing();
	end)

	WorldMapButton:SetScript("OnUpdate", Magnify_WorldMapButton_OnUpdate)

	local original_WorldMapFrame_OnShow = WorldMapFrame:GetScript("OnShow")
	WorldMapFrame:SetScript("OnShow", function (self) 
		original_WorldMapFrame_OnShow(self)
		MagnifySetupWorldMapFrame()
	end)
end

local function OnEvent(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
		MagnifyOnFirstLoad()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnEvent)
