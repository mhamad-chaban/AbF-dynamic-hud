local Config = require("DHUD.Config")
local HUDProperties = require("DHUD.HUDProperties")

local HUD = {}
local unavailableLogged = false
local lastAppliedState = nil

local HEALTH_HUD_PROPERTIES = { "HealthBar", "W_PlayerHUD_BodyDiagram", "HealthArrowVBox" }
local STAMINA_HUD_PROPERTIES = { "StaminaBar", "StaminaExertionBar" }

function HUD.GetMainWidget()
    local widgets = FindAllOf("UserWidget") or {}
    for _, widget in ipairs(widgets) do
        if widget and widget:IsValid() then
            local fullName = ""
            pcall(function() fullName = widget:GetFullName() end)

            if string.find(fullName, "W_PlayerHUD_Main_C_")
                or string.find(fullName, "W_PlayerHUD_Main_C$") then
                if not string.find(fullName, "WidgetTree") then
                    return widget
                end
            end
        end
    end
    return nil
end

function HUD.GetProperty(parent, propertyName)
    if not parent or type(parent) ~= "userdata" or not parent:IsValid() then
        return nil
    end

    local property = nil
    pcall(function()
        property = parent[propertyName]
    end)

    if property and type(property) == "userdata" and property:IsValid() then
        return property
    end
    return nil
end

local function SetElementOpacity(mainHUD, propertyName, opacity)
    local element = HUD.GetProperty(mainHUD, propertyName)
    if not element then
        return false
    end

    return pcall(function()
        element:SetRenderOpacity(opacity)
    end)
end

function HUD.ApplyState(opacity, healthLow, staminaLow)
    opacity = math.max(0, math.min(1, opacity))
    local healthOpacity = healthLow and 1 or opacity
    local staminaOpacity = staminaLow and 1 or opacity

    if lastAppliedState
        and math.abs(lastAppliedState.opacity - opacity) < 0.001
        and math.abs(lastAppliedState.healthOpacity - healthOpacity) < 0.001
        and math.abs(lastAppliedState.staminaOpacity - staminaOpacity) < 0.001 then
        return
    end

    local mainHUD = HUD.GetMainWidget()
    if not mainHUD or not mainHUD:IsValid() then
        if not unavailableLogged then
            print("[DynamicHUD] Error: Could not locate W_PlayerHUD_Main_C instance.")
            unavailableLogged = true
        end
        return
    end

    local successCount = 0
    for _, propertyName in ipairs(HUDProperties) do
        if SetElementOpacity(mainHUD, propertyName, opacity) then
            successCount = successCount + 1
        end
    end
    local hotbarOpacity = Config.HIDE_HOTBAR and opacity or 1
    if SetElementOpacity(mainHUD, "W_PlayerHUD_Hotbar", hotbarOpacity) then
        successCount = successCount + 1
    end
    local waypointOpacity = Config.HIDE_WAYPOINT_OVERLAY and opacity or 1
    if SetElementOpacity(mainHUD, "W_WaypointOverlay", waypointOpacity) then
        successCount = successCount + 1
    end
    for _, propertyName in ipairs(HEALTH_HUD_PROPERTIES) do
        if SetElementOpacity(mainHUD, propertyName, healthOpacity) then
            successCount = successCount + 1
        end
    end
    for _, propertyName in ipairs(STAMINA_HUD_PROPERTIES) do
        if SetElementOpacity(mainHUD, propertyName, staminaOpacity) then
            successCount = successCount + 1
        end
    end

    if successCount == 0 then
        if not unavailableLogged then
            print("[DynamicHUD] Error: No target HUD elements could be updated.")
            unavailableLogged = true
        end
        return
    end

    unavailableLogged = false
    lastAppliedState = {
        opacity = opacity,
        healthOpacity = healthOpacity,
        staminaOpacity = staminaOpacity
    }
end

return HUD
