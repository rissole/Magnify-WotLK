local ADDON_NAME, Magnify = ...

local panel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
panel.name = ADDON_NAME
InterfaceOptions_AddCategory(panel)

panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
panel.title:SetPoint("TOPLEFT", 16, -16)
panel.title:SetText(ADDON_NAME)

panel.EnablePersistZoom = CreateFrame("CheckButton", "MagnifyOptionsEnablePersistZoom", panel,
    "ChatConfigCheckButtonTemplate");
panel.EnablePersistZoom.tooltip = "Enable to maintain the zoom level when re-opening the map in the same zone.";
_G[panel.EnablePersistZoom:GetName() .. "Text"]:SetText("Persist zoom after closing the map");
panel.EnablePersistZoom:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -12)

panel.EnableOldPartyIcons = CreateFrame("CheckButton", "MagnifyOptionsEnableOldPartyIcons", panel,
    "ChatConfigCheckButtonTemplate");
panel.EnableOldPartyIcons.tooltip = "Tick to disable the colored party icons on the map.";
_G[panel.EnableOldPartyIcons:GetName() .. "Text"]:SetText("Uncolored party icons");
panel.EnableOldPartyIcons:SetPoint("TOPLEFT", panel.EnablePersistZoom, "BOTTOMLEFT", 0, 0)

function Magnify.InitOptions()
    panel.EnablePersistZoom:SetChecked(MagnifyOptions.enablePersistZoom)
    panel.EnablePersistZoom:SetScript("OnClick", function()
        if panel.EnablePersistZoom:GetChecked() then
            MagnifyOptions.enablePersistZoom = true
        else
            MagnifyOptions.enablePersistZoom = false
        end
    end)

    panel.EnableOldPartyIcons:SetChecked(MagnifyOptions.enableOldPartyIcons)
    panel.EnableOldPartyIcons:SetScript("OnClick", function()
        if panel.EnableOldPartyIcons:GetChecked() then
            MagnifyOptions.enableOldPartyIcons = true
        else
            MagnifyOptions.enableOldPartyIcons = false
        end
    end)
end

SLASH_MAGNIFY1 = "/magnify"
SlashCmdList["MAGNIFY"] = function(msg)
    -- Open addon panel
    InterfaceOptionsFrame_OpenToCategory(panel)
end
