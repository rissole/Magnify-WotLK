local ADDON_NAME, Magnify = ...

-- Constants
Magnify.ENABLEPERSISTZOOM_DEFAULT = false
Magnify.ENABLEOLDPARTYICONS_DEFAULT = false

Magnify.MAXZOOM_DEFAULT = 4.0
Magnify.MAXZOOM_SLIDER_MIN = 2.0
Magnify.MAXZOOM_SLIDER_MAX = 10.0
Magnify.MAXZOOM_SLIDER_STEP = 0.5

Magnify.ZOOMSTEP_DEFAULT = 0.1
Magnify.ZOOMSTEP_SLIDER_MIN = 0.01
Magnify.ZOOMSTEP_SLIDER_MAX = 0.5
Magnify.ZOOMSTEP_SLIDER_STEP = 0.01

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

panel.MaxZoom = CreateFrame("Slider", "MagnifyOptionsMaxZoom", panel, 
    "MagnifySliderTemplate");
panel.MaxZoom:SetMinMaxValues(Magnify.MAXZOOM_SLIDER_MIN, Magnify.MAXZOOM_SLIDER_MAX);
panel.MaxZoom:SetValueStep(Magnify.MAXZOOM_SLIDER_STEP);
_G[panel.MaxZoom:GetName() .. "Text"]:SetText("Maximum Zoom");
_G[panel.MaxZoom:GetName() .. "Low"]:SetText(Magnify.MAXZOOM_SLIDER_MIN);
_G[panel.MaxZoom:GetName() .. "High"]:SetText(Magnify.MAXZOOM_SLIDER_MAX);
panel.MaxZoom:SetPoint("TopLeft", panel.EnableOldPartyIcons, "BOTTOMLEFT", 0, -15);

panel.ZoomStep = CreateFrame("Slider", "MagnifyOptionsZoomStep", panel, 
    "MagnifySliderTemplate");
panel.ZoomStep:SetMinMaxValues(Magnify.ZOOMSTEP_SLIDER_MIN, Magnify.ZOOMSTEP_SLIDER_MAX);
panel.ZoomStep:SetValueStep(Magnify.ZOOMSTEP_SLIDER_STEP);
_G[panel.ZoomStep:GetName() .. "Text"]:SetText("Zoom Speed");
_G[panel.ZoomStep:GetName() .. "Low"]:SetText(Magnify.ZOOMSTEP_SLIDER_MIN);
_G[panel.ZoomStep:GetName() .. "High"]:SetText(Magnify.ZOOMSTEP_SLIDER_MAX);
panel.ZoomStep:SetPoint("TopLeft", panel.MaxZoom, "BOTTOMLEFT", 0, -30);

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

    panel.MaxZoom:SetValue(MagnifyOptions.maxZoom or Magnify.MAXZOOM_DEFAULT)
    _G[panel.MaxZoom:GetName() .. "CurrentValueText"]:SetFormattedText("%.2f", panel.MaxZoom:GetValue())
    panel.MaxZoom:SetScript("OnValueChanged", function()
        MagnifyOptions.maxZoom = panel.MaxZoom:GetValue()
        _G[panel.MaxZoom:GetName() .. "CurrentValueText"]:SetFormattedText("%.2f", panel.MaxZoom:GetValue())
    end)

    panel.ZoomStep:SetValue(MagnifyOptions.zoomStep or Magnify.ZOOMSTEP_DEFAULT)
    _G[panel.ZoomStep:GetName() .. "CurrentValueText"]:SetFormattedText("%.2f", panel.ZoomStep:GetValue())
    panel.ZoomStep:SetScript("OnValueChanged", function()
        MagnifyOptions.zoomStep = panel.ZoomStep:GetValue()
        _G[panel.ZoomStep:GetName() .. "CurrentValueText"]:SetFormattedText("%.2f", panel.ZoomStep:GetValue())
    end)
end

SLASH_MAGNIFY1 = "/magnify"
SlashCmdList["MAGNIFY"] = function(msg)
    -- Open addon panel
    InterfaceOptionsFrame_OpenToCategory(panel)
end
