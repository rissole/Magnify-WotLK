local ADDON_NAME, Magnify = ...

-- Constants
Magnify.MIN_ZOOM = 1.0
Magnify.MAX_ZOOM = 4.0
Magnify.ZOOM_STEP = 0.2

Magnify.MINIMODE_MIN_ZOOM = 1.0
Magnify.MINIMODE_MAX_ZOOM = 10.0
Magnify.MINIMODE_ZOOM_STEP = 0.1

Magnify.WORLDMAP_POI_MIN_X = 12
Magnify.WORLDMAP_POI_MIN_Y = -12
Magnify.worldmapPoiMaxX = nil -- changes based on current scale, see SetPOIMaxBounds
Magnify.worldmapPoiMaxY = nil -- changes based on current scale, see SetPOIMaxBounds

Magnify.PLAYER_ARROW_SIZE = 36

-- If you open the map and the zone was the same, we want to remember the previous state
Magnify.PreviousState = {
    panX = 0,
    panY = 0,
    scale = 1,
    zone = 0
}

MagnifyOptions = {
    enablePersistZoom = false,
    enableOldPartyIcons = false,
}

local function updatePointRelativeTo(frame, newRelativeFrame)
    local currentPoint, _currentRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY = frame:GetPoint()
    frame:ClearAllPoints()
    frame:SetPoint(currentPoint, newRelativeFrame, currentRelativePoint, currentOffsetX, currentOffsetY)
end

local function resizePOI(poiButton)
    if (poiButton) then
        local _, _, _, x, y = poiButton:GetPoint()
        local mapsterScale = 1
        local mapster, mapsterPoiScale = Magnify.GetMapster("poiScale")
        if (mapster) then
            -- Sorry mapster I need to take the wheel
            mapster.WorldMapFrame_DisplayQuestPOI = function()
            end
        end
        if x ~= nil and y ~= nil then
            local s = WORLDMAP_SETTINGS.size / WorldMapDetailFrame:GetEffectiveScale() * (mapsterScale or 1)

            local posX = x * 1 / s
            local posY = y * 1 / s
            poiButton:SetScale(s)
            poiButton:SetPoint("CENTER", poiButton:GetParent(), "TOPLEFT", posX, posY)

            if (posY > Magnify.WORLDMAP_POI_MIN_Y) then
                posY = Magnify.WORLDMAP_POI_MIN_Y
            elseif (posY < Magnify.worldmapPoiMaxY) then
                posY = Magnify.worldmapPoiMaxY
            end
            if (posX < Magnify.WORLDMAP_POI_MIN_X) then
                posX = Magnify.WORLDMAP_POI_MIN_X
            elseif (posX > Magnify.worldmapPoiMaxX) then
                posX = Magnify.worldmapPoiMaxX
            end
        end
    end
end

function Magnify.PersistMapScrollAndPan()
    Magnify.PreviousState.panX = WorldMapScrollFrame:GetHorizontalScroll()
    Magnify.PreviousState.panY = WorldMapScrollFrame:GetVerticalScroll()
    Magnify.PreviousState.scale = WorldMapDetailFrame:GetScale()
    Magnify.PreviousState.zone = GetCurrentMapZone()
end

function Magnify.AfterScrollOrPan()
    Magnify.PersistMapScrollAndPan()
    if (WORLDMAP_SETTINGS.selectedQuest) then
        WorldMapBlobFrame:DrawQuestBlob(WORLDMAP_SETTINGS.selectedQuestId, false);
        WorldMapBlobFrame:DrawQuestBlob(WORLDMAP_SETTINGS.selectedQuestId, true);
    end
end

function Magnify.ResizeQuestPOIs()
    local QUEST_POI_MAX_TYPES = 4;
    local POI_TYPE_MAX_BUTTONS = 25;

    for i = 1, QUEST_POI_MAX_TYPES do
        for j = 1, POI_TYPE_MAX_BUTTONS do
            local buttonName = "poiWorldMapPOIFrame" .. i .. "_" .. j;
            resizePOI(_G[buttonName])
        end
    end

    resizePOI(QUEST_POI_SWAP_BUTTONS["WorldMapPOIFrame"])
end

function Magnify.SetPOIMaxBounds()
    Magnify.worldmapPoiMaxY = WorldMapDetailFrame:GetHeight() * -WORLDMAP_SETTINGS.size + 12;
    Magnify.worldmapPoiMaxX = WorldMapDetailFrame:GetWidth() * WORLDMAP_SETTINGS.size + 12;
end

function Magnify.SetDetailFrameScale(num)
    WorldMapDetailFrame:SetScale(num)
    Magnify.SetPOIMaxBounds() -- Calling Magnify method

    -- Adjust frames to inversely scale with the detail frame so they maintain relative screen size
    WorldMapPOIFrame:SetScale(1 / WORLDMAP_SETTINGS.size)
    WorldMapBlobFrame:SetScale(num)

    WorldMapPlayer:SetScale(1 / WorldMapDetailFrame:GetScale())
    WorldMapDeathRelease:SetScale(1 / WorldMapDetailFrame:GetScale())
    WorldMapCorpse:SetScale(1 / WorldMapDetailFrame:GetScale())
    local numFlags = GetNumBattlefieldFlagPositions()
    for i = 1, numFlags do
        local flagFrameName = "WorldMapFlag" .. i;
        if (_G[flagFrameName]) then
            _G[flagFrameName]:SetScale(1 / WorldMapDetailFrame:GetScale())
        end
    end

    for i = 1, MAX_PARTY_MEMBERS do
        if (_G["WorldMapParty" .. i]) then
            _G["WorldMapParty" .. i]:SetScale(1 / WorldMapDetailFrame:GetScale())
        end
    end

    for i = 1, MAX_RAID_MEMBERS do
        if (_G["WorldMapRaid" .. i]) then
            _G["WorldMapRaid" .. i]:SetScale(1 / WorldMapDetailFrame:GetScale())
        end
    end

    for i = 1, #MAP_VEHICLES do
        if (MAP_VEHICLES[i]) then
            MAP_VEHICLES[i]:SetScale(1 / WorldMapDetailFrame:GetScale())
        end
    end

    WorldMapFrame_OnEvent(WorldMapFrame, "DISPLAY_SIZE_CHANGED")
    if (WorldMapFrame_UpdateQuests() > 0) then
        Magnify.RedrawSelectedQuest() -- Calling Magnify method
    end
end

function Magnify.GetElvUI()
    if ElvUI and ElvUI[1] then
        return ElvUI[1]
    end
    return nil
end

--- Get Mapster object, and configuration value for given key provided (or nil)
---@param configName string
function Magnify.GetMapster(configName)
    if (LibStub and LibStub:GetLibrary("AceAddon-3.0", true)) then
        local mapster = LibStub:GetLibrary("AceAddon-3.0"):GetAddon("Mapster", true)
        if (not mapster) then
            return mapster, nil
        end
        if (mapster.db and mapster.db.profile) then
            return mapster, mapster.db.profile[configName]
        end
    end
    return nil, nil
end

function Magnify.ElvUI_SetupWorldMapFrame()
    local worldMap = Magnify.GetElvUI():GetModule("WorldMap")
    if not worldMap then
        return
    end

    if (worldMap.coordsHolder and worldMap.coordsHolder.playerCoords) then
        updatePointRelativeTo(worldMap.coordsHolder.playerCoords, WorldMapScrollFrame)
    end

    if (WorldMapDetailFrame.backdrop) then
        WorldMapDetailFrame.backdrop:Hide()

        local _, worldMapRelativeFrame = WorldMapFrame.backdrop
        if (worldMapRelativeFrame == WorldMapDetailFrame) then
            updatePointRelativeTo(WorldMapFrame.backdrop, WorldMapScrollFrame)
        end
    end

    if (WorldMapFrame.backdrop) then
        -- We will take over the SetPoint behavior ElvUI, I'm sorry
        WorldMapFrame.backdrop.Point = function()
            return;
        end

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

function Magnify.SetupWorldMapFrame()
    WorldMapScrollFrameScrollBar:Hide()
    WorldMapFrame:EnableMouse(true)
    WorldMapScrollFrame:EnableMouse(true)
    WorldMapScrollFrame.panning = false
    WorldMapScrollFrame.moved = false

    if (WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE) then
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -726, -99);
        WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 8, 4);
    elseif (WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE) then
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT", 18, -43);
        WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9);

        WorldMapFrame:SetPoint("TOPLEFT", WorldMapScreenAnchor, 0, 0);
        WorldMapFrame:SetScale(WorldMapScreenAnchor.preferredMinimodeScale);
        WorldMapFrame:SetMovable("true");
        WorldMapTitleButton:Show()
        WorldMapTitleButton:ClearAllPoints()
        WorldMapTitleButton:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", 13, 0)
        WorldMapFrameTitle:Show()
        WorldMapFrameTitle:ClearAllPoints();
        WorldMapFrameTitle:SetPoint("CENTER", WorldMapTitleButton, "CENTER", 32, 0)
    else
        WorldMapScrollFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOPLEFT", 11, -70.5);
        WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, -9);
    end

    WorldMapScrollFrame:SetScale(WORLDMAP_SETTINGS.size);

    Magnify.SetDetailFrameScale(1)
    WorldMapDetailFrame:SetAllPoints(WorldMapScrollFrame)
    WorldMapScrollFrame:SetHorizontalScroll(0)
    WorldMapScrollFrame:SetVerticalScroll(0)

    if (MagnifyOptions.enablePersistZoom and GetCurrentMapZone() == Magnify.PreviousState.zone) then
        Magnify.SetDetailFrameScale(Magnify.PreviousState.scale)
        WorldMapScrollFrame:SetHorizontalScroll(Magnify.PreviousState.panX)
        WorldMapScrollFrame:SetVerticalScroll(Magnify.PreviousState.panY)
    end

    WorldMapButton:SetScale(1)
    WorldMapButton:SetAllPoints(WorldMapDetailFrame)
    WorldMapButton:SetParent(WorldMapDetailFrame)

    WorldMapPOIFrame:SetParent(WorldMapDetailFrame)
    WorldMapBlobFrame:SetParent(WorldMapDetailFrame)
    WorldMapBlobFrame:ClearAllPoints()
    WorldMapBlobFrame:SetAllPoints(WorldMapDetailFrame)

    WorldMapPlayer:SetParent(WorldMapDetailFrame)

    updatePointRelativeTo(WorldMapQuestScrollFrame, WorldMapScrollFrame);
    updatePointRelativeTo(WorldMapQuestDetailScrollFrame, WorldMapScrollFrame);

    if (Magnify.GetElvUI()) then -- Calling Magnify method
        Magnify.ElvUI_SetupWorldMapFrame() -- Calling Magnify method
    end
end

function Magnify.WorldMapScrollFrame_OnPan(cursorX, cursorY)
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
        Magnify.AfterScrollOrPan()
    end
end

function Magnify.ColorWorldMapPartyMemberFrame(partyMemberFrame, unit)
    local classColor = RAID_CLASS_COLORS[select(2, UnitClass(unit))];
    if (classColor and not MagnifyOptions.enableOldPartyIcons) then
        partyMemberFrame.colorIcon:Show();
        partyMemberFrame.icon:Hide();
        partyMemberFrame.colorIcon:SetVertexColor(classColor.r, classColor.g, classColor.b, 1);
    else
        partyMemberFrame.colorIcon:Hide();
        partyMemberFrame.icon:Show();
    end
end

function Magnify.WorldMapButton_OnUpdate(self, elapsed)
    local x, y = GetCursorPosition();
    x = x / self:GetEffectiveScale();
    y = y / self:GetEffectiveScale();

    local centerX, centerY = self:GetCenter();
    local width = self:GetWidth();
    local height = self:GetHeight();
    local adjustedY = (centerY + (height / 2) - y) / height;
    local adjustedX = (x - (centerX - (width / 2))) / width;

    local name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY
    if (self:IsMouseOver()) then
        name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY =
            UpdateMapHighlight(adjustedX, adjustedY);
    end

    WorldMapFrame.areaName = name;
    if (not WorldMapFrame.poiHighlight) then
        WorldMapFrameAreaLabel:SetText(name);
    end
    if (fileName) then
        WorldMapHighlight:SetTexCoord(0, texPercentageX, 0, texPercentageY);
        WorldMapHighlight:SetTexture("Interface\\WorldMap\\" .. fileName .. "\\" .. fileName .. "Highlight");
        textureX = textureX * width;
        textureY = textureY * height;
        scrollChildX = scrollChildX * width;
        scrollChildY = -scrollChildY * height;
        if ((textureX > 0) and (textureY > 0)) then
            WorldMapHighlight:SetWidth(textureX);
            WorldMapHighlight:SetHeight(textureY);
            WorldMapHighlight:SetPoint("TOPLEFT", "WorldMapDetailFrame", "TOPLEFT", scrollChildX, scrollChildY);
            WorldMapHighlight:Show();
            -- WorldMapFrameAreaLabel:SetPoint("TOP", "WorldMapHighlight", "TOP", 0, 0);
        end

    else
        WorldMapHighlight:Hide();
    end
    -- Position player
    UpdateWorldMapArrowFrames();
    local playerX, playerY = GetPlayerMapPosition("player");
    if ((playerX == 0 and playerY == 0)) then
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
        local _, mapsterArrowScale = Magnify.GetMapster('arrowScale') -- Calling Magnify method
        WorldMapPlayer.Icon:SetSize(Magnify.PLAYER_ARROW_SIZE * (mapsterArrowScale or 1),
            Magnify.PLAYER_ARROW_SIZE * (mapsterArrowScale or 1))
        WorldMapPlayer:Show();
    end

    -- Position groupmates
    local playerCount = 0;
    if (GetNumRaidMembers() > 0) then
        for i = 1, MAX_PARTY_MEMBERS do
            local partyMemberFrame = _G["WorldMapParty" .. i];
            partyMemberFrame:Hide();
        end
        for i = 1, MAX_RAID_MEMBERS do
            local unit = "raid" .. i;
            local partyX, partyY = GetPlayerMapPosition(unit);
            local partyMemberFrame = _G["WorldMapRaid" .. (playerCount + 1)];
            if ((partyX == 0 and partyY == 0) or UnitIsUnit(unit, "player")) then
                partyMemberFrame:Hide();
            else
                partyX = partyX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale()
                partyY = -partyY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()
                partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY);
                partyMemberFrame.name = nil;
                partyMemberFrame.unit = unit;
                Magnify.ColorWorldMapPartyMemberFrame(partyMemberFrame, unit);
                partyMemberFrame:Show();
                playerCount = playerCount + 1;
            end
        end
    else
        for i = 1, MAX_PARTY_MEMBERS do
            local partyX, partyY = GetPlayerMapPosition("party" .. i);
            local partyMemberFrame = _G["WorldMapParty" .. i];
            if (partyX == 0 and partyY == 0) then
                partyMemberFrame:Hide();
            else
                partyX = partyX * WorldMapButton:GetWidth() * WorldMapDetailFrame:GetScale();
                partyY = -partyY * WorldMapButton:GetHeight() * WorldMapDetailFrame:GetScale();
                partyMemberFrame:SetPoint("CENTER", "WorldMapButton", "TOPLEFT", partyX, partyY);
                Magnify.ColorWorldMapPartyMemberFrame(partyMemberFrame, "party" .. i);
                partyMemberFrame:Show();
            end
        end
    end
    -- Position Team Members
    local numTeamMembers = GetNumBattlefieldPositions();
    for i = playerCount + 1, MAX_RAID_MEMBERS do
        local partyX, partyY, name = GetBattlefieldPosition(i - playerCount);
        local partyMemberFrame = _G["WorldMapRaid" .. i];
        if (partyX == 0 and partyY == 0) then
            partyMemberFrame:Hide();
        else
            partyX = partyX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale()
            partyY = -partyY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()
            partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY);
            partyMemberFrame.name = name;
            partyMemberFrame.unit = nil;
            partyMemberFrame.colorIcon:Hide();
            partyMemberFrame.icon:Show();
            partyMemberFrame:Show();
        end
    end

    -- Position flags
    local numFlags = GetNumBattlefieldFlagPositions();
    for i = 1, numFlags do
        local flagX, flagY, flagToken = GetBattlefieldFlagPosition(i);
        local flagFrameName = "WorldMapFlag" .. i;
        local flagFrame = _G[flagFrameName];
        if (flagX == 0 and flagY == 0) then
            flagFrame:Hide();
        else
            flagX = flagX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale()
            flagY = -flagY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()
            flagFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", flagX, flagY);
            local flagTexture = _G[flagFrameName .. "Texture"];
            flagTexture:SetTexture("Interface\\WorldStateFrame\\" .. flagToken);
            flagFrame:Show();
        end
    end
    for i = numFlags + 1, NUM_WORLDMAP_FLAGS do
        local flagFrame = _G["WorldMapFlag" .. i];
        flagFrame:Hide();
    end

    -- Position corpse
    local corpseX, corpseY = GetCorpseMapPosition();
    if (corpseX == 0 and corpseY == 0) then
        WorldMapCorpse:Hide();
    else
        corpseX = corpseX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale();
        corpseY = -corpseY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale()

        WorldMapCorpse:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", corpseX, corpseY);
        WorldMapCorpse:Show();
    end

    -- Position Death Release marker
    local deathReleaseX, deathReleaseY = GetDeathReleasePosition();
    if ((deathReleaseX == 0 and deathReleaseY == 0) or UnitIsGhost("player")) then
        WorldMapDeathRelease:Hide();
    else
        deathReleaseX = deathReleaseX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale();
        deathReleaseY = -deathReleaseY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale();

        WorldMapDeathRelease:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", deathReleaseX, deathReleaseY);
        WorldMapDeathRelease:Show();
    end

    -- position vehicles
    local numVehicles;
    if (GetCurrentMapContinent() == WORLDMAP_WORLD_ID or (GetCurrentMapContinent() ~= -1 and GetCurrentMapZone() == 0)) then
        -- Hide vehicles on the worldmap and continent maps
        numVehicles = 0;
    else
        numVehicles = GetNumBattlefieldVehicles();
    end
    local totalVehicles = #MAP_VEHICLES;
    local index = 0;
    for i = 1, numVehicles do
        if (i > totalVehicles) then
            local vehicleName = "WorldMapVehicles" .. i;
            MAP_VEHICLES[i] = CreateFrame("FRAME", vehicleName, WorldMapButton, "WorldMapVehicleTemplate");
            MAP_VEHICLES[i].texture = _G[vehicleName .. "Texture"];
        end
        local vehicleX, vehicleY, unitName, isPossessed, vehicleType, orientation, isPlayer, isAlive =
            GetBattlefieldVehicleInfo(i);
        if (vehicleX and isAlive and not isPlayer and VEHICLE_TEXTURES[vehicleType]) then
            local mapVehicleFrame = MAP_VEHICLES[i];
            vehicleX = vehicleX * WorldMapDetailFrame:GetWidth() * WorldMapDetailFrame:GetScale();
            vehicleY = -vehicleY * WorldMapDetailFrame:GetHeight() * WorldMapDetailFrame:GetScale();
            mapVehicleFrame.texture:SetRotation(orientation);
            mapVehicleFrame.texture:SetTexture(WorldMap_GetVehicleTexture(vehicleType, isPossessed));
            mapVehicleFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", vehicleX, vehicleY);
            mapVehicleFrame:SetWidth(VEHICLE_TEXTURES[vehicleType].width);
            mapVehicleFrame:SetHeight(VEHICLE_TEXTURES[vehicleType].height);
            mapVehicleFrame.name = unitName;
            mapVehicleFrame:Show();
            index = i; -- save for later
        else
            MAP_VEHICLES[i]:Hide();
        end

    end
    if (index < totalVehicles) then
        for i = index + 1, totalVehicles do
            MAP_VEHICLES[i]:Hide();
        end
    end

    if WorldMapScrollFrame.panning then
        Magnify.WorldMapScrollFrame_OnPan(GetCursorPosition()) -- Calling Magnify method
    end
end

function Magnify.WorldMapScrollFrame_OnMouseWheel()
    if (IsControlKeyDown() and WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE) then
        local oldScale = WorldMapFrame:GetScale()
        local newScale = oldScale + arg1 * Magnify.MINIMODE_ZOOM_STEP
        newScale = max(Magnify.MINIMODE_MIN_ZOOM, newScale)
        newScale = min(Magnify.MINIMODE_MAX_ZOOM, newScale)

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
    newScale = oldScale + arg1 * Magnify.ZOOM_STEP
    newScale = max(Magnify.MIN_ZOOM, newScale)
    newScale = min(Magnify.MAX_ZOOM, newScale)

    Magnify.SetDetailFrameScale(newScale)

    this.maxX = ((WorldMapDetailFrame:GetWidth() * newScale) - this:GetWidth()) / newScale
    this.maxY = ((WorldMapDetailFrame:GetHeight() * newScale) - this:GetHeight()) / newScale
    this.zoomedIn = WorldMapDetailFrame:GetScale() > Magnify.MIN_ZOOM

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
    Magnify.AfterScrollOrPan()
end

function Magnify.WorldMapButton_OnMouseDown()
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

function Magnify.WorldMapButton_OnMouseUp()
    WorldMapScrollFrame.panning = false

    if not WorldMapScrollFrame.moved then
        WorldMapButton_OnClick(WorldMapButton, arg1)

        Magnify.SetDetailFrameScale(Magnify.MIN_ZOOM)

        WorldMapScrollFrame:SetHorizontalScroll(0)
        WorldMapScrollFrame:SetVerticalScroll(0)
        Magnify.AfterScrollOrPan()

        WorldMapScrollFrame.zoomedIn = false
    end

    WorldMapScrollFrame.moved = false
end

function Magnify.RedrawSelectedQuest()
    if (WORLDMAP_SETTINGS.selectedQuestId) then
        -- try to select previously selected quest
        WorldMapFrame_SelectQuestById(WORLDMAP_SETTINGS.selectedQuestId);
    else
        -- select the first quest
        WorldMapFrame_SelectQuestFrame(_G["WorldMapQuestFrame1"]);
    end
end

function Magnify.CreateClassColorIcon(partyMemberFrame)
    if (partyMemberFrame) then
        partyMemberFrame.colorIcon = partyMemberFrame:CreateTexture(nil, "ARTWORK"); 
        partyMemberFrame.colorIcon:SetAllPoints(partyMemberFrame);
        partyMemberFrame.colorIcon:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\assets\\WorldMapPlayer');
        partyMemberFrame.icon:Hide();
    end
end

function Magnify.OnFirstLoad()
    WorldMapScrollFrame:SetScrollChild(WorldMapDetailFrame)
    WorldMapScrollFrame:SetScript("OnMouseWheel", Magnify.WorldMapScrollFrame_OnMouseWheel)
    WorldMapButton:SetScript("OnMouseDown", Magnify.WorldMapButton_OnMouseDown)
    WorldMapButton:SetScript("OnMouseUp", Magnify.WorldMapButton_OnMouseUp)
    WorldMapDetailFrame:SetParent(WorldMapScrollFrame)

    WorldMapFrameAreaFrame:SetParent(WorldMapFrame)
    WorldMapFrameAreaFrame:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL)
    WorldMapFrameAreaFrame:SetPoint("TOP", WorldMapScrollFrame, "TOP", 0, -10)

    -- Not worth getting this ugly ping working
    WorldMapPing.Show = function()
        return
    end
    WorldMapPing:SetModelScale(0)

    -- Add higher definition arrow that will get masked correctly on pan
    -- (Default player arrow stays visible even if you pan it to be off the map)
    WorldMapPlayer.Icon = WorldMapPlayer:CreateTexture(nil, 'ARTWORK')
    WorldMapPlayer.Icon:SetSize(Magnify.PLAYER_ARROW_SIZE, Magnify.PLAYER_ARROW_SIZE)
    WorldMapPlayer.Icon:SetPoint("CENTER", 0, 0)
    WorldMapPlayer.Icon:SetTexture('Interface\\AddOns\\' .. ADDON_NAME .. '\\assets\\WorldMapArrow')

    hooksecurefunc("WorldMapFrame_SetFullMapView", Magnify.SetupWorldMapFrame);
    hooksecurefunc("WorldMapFrame_SetQuestMapView", Magnify.SetupWorldMapFrame);
    hooksecurefunc("WorldMap_ToggleSizeDown", Magnify.SetupWorldMapFrame);
    hooksecurefunc("WorldMap_ToggleSizeUp", Magnify.SetupWorldMapFrame);
    hooksecurefunc("WorldMapFrame_UpdateQuests", Magnify.ResizeQuestPOIs);
    hooksecurefunc("WorldMapFrame_SetPOIMaxBounds", Magnify.SetPOIMaxBounds);

    hooksecurefunc("WorldMapQuestShowObjectives_AdjustPosition", function()
        if (WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE) then
            WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOMRIGHT",
                -30 - WorldMapQuestShowObjectivesText:GetWidth(), -9);
        else
            WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOMRIGHT",
                -15 - WorldMapQuestShowObjectivesText:GetWidth(), 4);
        end
    end);

    WorldMapScreenAnchor:StartMoving();
    WorldMapScreenAnchor:SetPoint("TOPLEFT", 10, -118);
    WorldMapScreenAnchor:StopMovingOrSizing();

    -- Magic good default scale ratio based on screen height
    WorldMapScreenAnchor.preferredMinimodeScale = 1 + (0.4 * WorldMapFrame:GetHeight() / WorldFrame:GetHeight())

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

    WorldMapButton:SetScript("OnUpdate", Magnify.WorldMapButton_OnUpdate)

    local original_WorldMapFrame_OnShow = WorldMapFrame:GetScript("OnShow")
    WorldMapFrame:SetScript("OnShow", function(self)
        original_WorldMapFrame_OnShow(self)
        Magnify.SetupWorldMapFrame()
    end)

    -- Create class color textures for party and raid frames
    for i = 1, MAX_RAID_MEMBERS do
        Magnify.CreateClassColorIcon(_G["WorldMapParty" .. i]);
        Magnify.CreateClassColorIcon(_G["WorldMapRaid" .. i]);
    end
end

function Magnify.OnEvent(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        Magnify.OnFirstLoad()
        Magnify.InitOptions()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", Magnify.OnEvent)