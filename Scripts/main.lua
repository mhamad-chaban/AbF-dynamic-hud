-- Mods/DynamicHUD/scripts/main.lua

local AFUtils = require("AFUtils.AFUtils")
local Constants = require("Constants")
local TARGET_HUD_PROPERTIES = require("HUDProperties")

local Key = Key
local lastAppliedState = nil
local visibilityMode = "auto"
local hudUnavailableLogged = false
local playerHealthPercent = nil
local playerStaminaPercent = nil
local HEALTH_HUD_PROPERTIES = { "HealthBar", "W_PlayerHUD_BodyDiagram" }
local STAMINA_HUD_PROPERTIES = { "StaminaBar", "StaminaExertionBar" }

local function GetMainHUDWidget()
    local widgets = FindAllOf("UserWidget") or {}
    for _, widget in ipairs(widgets) do
        if widget and widget:IsValid() then
            local fullName = ""
            pcall(function() fullName = widget:GetFullName() end)

            if string.find(fullName, "W_PlayerHUD_Main_C_") or string.find(fullName, "W_PlayerHUD_Main_C$") then
                if not string.find(fullName, "WidgetTree") then
                    return widget
                end
            end
        end
    end
    return nil
end

local function GetWidgetProperty(parent, propName)
    if not parent or type(parent) ~= "userdata" or not parent:IsValid() then
        return nil
    end

    local prop = nil
    pcall(function()
        prop = parent[propName]
    end)

    if prop and type(prop) == "userdata" and prop:IsValid() then
        return prop
    end

    return nil
end

local function SetHUDElementOpacity(mainHUD, propertyName, opacity)
    local element = GetWidgetProperty(mainHUD, propertyName)
    if not element then
        return false
    end

    return pcall(function()
        element:SetRenderOpacity(opacity)
    end)
end

local function SetGameplayHUDState(opacity, healthLow, staminaLow)
    local mainHUD = GetMainHUDWidget()
    if not mainHUD or not mainHUD:IsValid() then
        if not hudUnavailableLogged then
            print("[DynamicHUD] Error: Could not locate W_PlayerHUD_Main_C instance.")
            hudUnavailableLogged = true
        end
        return false
    end

    local healthOpacity = healthLow and 1 or opacity
    local staminaOpacity = staminaLow and 1 or opacity
    local successCount = 0

    for _, propName in ipairs(TARGET_HUD_PROPERTIES) do
        if SetHUDElementOpacity(mainHUD, propName, opacity) then
            successCount = successCount + 1
        end
    end

    for _, propName in ipairs(HEALTH_HUD_PROPERTIES) do
        if SetHUDElementOpacity(mainHUD, propName, healthOpacity) then
            successCount = successCount + 1
        end
    end

    for _, propName in ipairs(STAMINA_HUD_PROPERTIES) do
        if SetHUDElementOpacity(mainHUD, propName, staminaOpacity) then
            successCount = successCount + 1
        end
    end

    if successCount == 0 then
        if not hudUnavailableLogged then
            print("[DynamicHUD] Error: No target HUD elements could be updated.")
            hudUnavailableLogged = true
        end
        return false
    end

    hudUnavailableLogged = false
    return true
end

local function ApplyHUDState(opacity, healthLow, staminaLow)
    opacity = math.max(0, math.min(1, opacity))
    local healthOpacity = healthLow and 1 or opacity
    local staminaOpacity = staminaLow and 1 or opacity

    if lastAppliedState
        and math.abs(lastAppliedState.opacity - opacity) < 0.001
        and math.abs(lastAppliedState.healthOpacity - healthOpacity) < 0.001
        and math.abs(lastAppliedState.staminaOpacity - staminaOpacity) < 0.001 then
        return
    end

    if SetGameplayHUDState(opacity, healthLow, staminaLow) then
        lastAppliedState = {
            opacity = opacity,
            healthOpacity = healthOpacity,
            staminaOpacity = staminaOpacity
        }
    end
end

local function GetPlayerLocation()
    local pc = GetMyPlayerController()

    if pc and pc:IsValid() and pc.Pawn and pc.Pawn:IsValid() then
        local pawn = pc.Pawn
        return pawn:K2_GetActorLocation(), pawn
    end
    return nil
end

local function ReadNumberProperty(object, propertyName)
    local value = nil
    local success = pcall(function()
        value = object[propertyName]
    end)

    if success and type(value) == "number" and value == value then
        return value
    end
    return nil
end

local function GetPlayerVitalPercentages()
    local pc = GetMyPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        return nil, nil
    end

    local healthPercent = nil
    local mainHUD = GetMainHUDWidget()
    if mainHUD and mainHUD:IsValid() then
        healthPercent = ReadNumberProperty(mainHUD, "LastHealthPercentage")
    end

    local staminaPercent = nil
    local currentStamina = ReadNumberProperty(pc.Pawn, "CurrentStamina")
    local maxStamina = ReadNumberProperty(pc.Pawn, "MaxStamina")
    if currentStamina and maxStamina and maxStamina > 0 then
        staminaPercent = math.max(0, math.min(1, currentStamina / maxStamina))
    end

    if healthPercent then
        healthPercent = math.max(0, math.min(1, healthPercent))
    end
    return healthPercent, staminaPercent
end

local function GetNearbyMonsterNames()
    local playerLoc, localPawn = GetPlayerLocation()
    if not playerLoc then
        return nil
    end

    local candidates = FindAllOf("Character")
    if not candidates or #candidates == 0 then
        candidates = FindAllOf("Pawn")
    end
    candidates = candidates or {}

    local nearbyMonsterNames = {}
    for _, actor in ipairs(candidates) do
        if actor and actor:IsValid() and actor ~= localPawn then
            local fullName = nil
            pcall(function() fullName = actor:GetFullName() end)

            if fullName and string.find(fullName, Constants.MONSTER_CLASS_MARKER, 1, true) then
                local loc = nil
                pcall(function() loc = actor:K2_GetActorLocation() end)

                if loc then
                    local dx = playerLoc.X - loc.X
                    local dy = playerLoc.Y - loc.Y
                    local dz = playerLoc.Z - loc.Z
                    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

                    if dist <= Constants.DETECTION_RADIUS then
                        table.insert(nearbyMonsterNames, fullName)
                    end
                end
            end
        end
    end

    return nearbyMonsterNames
end

local function PrintVitalFields(label, object)
    if not object or not object:IsValid() then
        print(string.format("[DynamicHUD] %s unavailable.", label))
        return
    end

    local fullName = "unknown object"
    pcall(function() fullName = object:GetFullName() end)
    print(string.format("[DynamicHUD] %s: %s", label, fullName))
    local foundField = false

    for _, fieldName in ipairs(Constants.VITAL_FIELD_CANDIDATES) do
        local value = nil
        local success = pcall(function()
            value = object[fieldName]
        end)

        if success and (type(value) == "number" or type(value) == "string" or type(value) == "boolean") then
            foundField = true
            print(string.format("     %s = %s", fieldName, tostring(value)))
        end
    end

    if not foundField then
        print("     No matching direct health/stamina fields found.")
    end
end

local function PrintHUDHealthPercentage(hud)
    if not hud or not hud:IsValid() then
        print("[DynamicHUD] HUD health percentage unavailable.")
        return
    end

    local percentage = nil
    local success = pcall(function()
        percentage = hud.LastHealthPercentage
    end)

    if success and type(percentage) == "number" then
        print(string.format("[DynamicHUD] HUD LastHealthPercentage = %.4f", percentage))
    else
        print("[DynamicHUD] Could not read HUD LastHealthPercentage.")
    end
end

RegisterKeyBind(Key.F3, function()
    local pc = GetMyPlayerController()
    if not pc or not pc:IsValid() or not pc.Pawn or not pc.Pawn:IsValid() then
        print("[DynamicHUD] Player character unavailable for vitals diagnostic.")
        return
    end

    local playerPawn = pc.Pawn
    local mainHUD = GetMainHUDWidget()
    local hudCharacter = GetWidgetProperty(mainHUD, "OwningCharacter")
    local playerPawnName = nil
    local hudCharacterName = nil
    pcall(function() playerPawnName = playerPawn:GetFullName() end)
    pcall(function()
        if hudCharacter then
            hudCharacterName = hudCharacter:GetFullName()
        end
    end)

    print("--- [DynamicHUD] PLAYER VITALS DIAGNOSTIC ---")
    PrintVitalFields("Player pawn", playerPawn)
    if hudCharacter and hudCharacterName ~= playerPawnName then
        PrintVitalFields("HUD owning character", hudCharacter)
    end

    PrintHUDHealthPercentage(mainHUD)
    print("--------------------------------------------")
end)

RegisterKeyBind(Key.F8, function()
    if visibilityMode == "auto" then
        visibilityMode = "manual_hidden"
        print("[DynamicHUD] Manual override: HUD hidden. Press F8 to show it.")
    elseif visibilityMode == "manual_hidden" then
        visibilityMode = "manual_visible"
        print("[DynamicHUD] Manual override: HUD visible. Press F8 to resume automatic mode.")
    else
        visibilityMode = "auto"
        print("[DynamicHUD] Automatic HUD visibility resumed.")
    end

    if visibilityMode == "manual_hidden" then
        ApplyHUDState(0, false, false)
    elseif visibilityMode == "manual_visible" then
        ApplyHUDState(1, true, true)
    end
end)

RegisterKeyBind(Key.F2, function()
    local nearbyMonsterNames = GetNearbyMonsterNames()
    if not nearbyMonsterNames then
        print("[DynamicHUD] Player location unavailable.")
        return
    end

    print("--- [DynamicHUD] NEARBY MONSTER DIAGNOSTIC ---")
    for _, fullName in ipairs(nearbyMonsterNames) do
        print(string.format("     Path: %s", fullName))
    end

    if #nearbyMonsterNames == 0 then
        print("[DynamicHUD] No nearby monsters found within " .. Constants.DETECTION_RADIUS / 100.0 .. "m.")
    end
    print("--------------------------------------------")
end)

local elapsedMs = 0
local lastMonsterSeenMs = nil
local nearbyMonsters = false

LoopAsync(Constants.HUD_UPDATE_INTERVAL_MS, function()
    elapsedMs = elapsedMs + Constants.HUD_UPDATE_INTERVAL_MS

    if elapsedMs % Constants.SCAN_INTERVAL_MS == 0 then
        local nearbyMonsterNames = GetNearbyMonsterNames()
        if nearbyMonsterNames then
            nearbyMonsters = #nearbyMonsterNames > 0
            if nearbyMonsters then
                lastMonsterSeenMs = elapsedMs
            end
        else
            nearbyMonsters = false
        end

        playerHealthPercent, playerStaminaPercent = GetPlayerVitalPercentages()
    end

    if visibilityMode == "manual_hidden" then
        ApplyHUDState(0, false, false)
    elseif visibilityMode == "manual_visible" then
        ApplyHUDState(1, true, true)
    else
        local hudOpacity = 0
        if nearbyMonsters then
            hudOpacity = 1
        elseif lastMonsterSeenMs then
            local timeSinceLastMonsterMs = elapsedMs - lastMonsterSeenMs
            if timeSinceLastMonsterMs <= Constants.VISIBLE_GRACE_PERIOD_MS then
                hudOpacity = 1
            else
                local fadeProgress = (timeSinceLastMonsterMs - Constants.VISIBLE_GRACE_PERIOD_MS)
                    / Constants.FADE_OUT_DURATION_MS
                hudOpacity = 1 - fadeProgress
            end
        end

        local healthLow = playerHealthPercent ~= nil
            and playerHealthPercent <= Constants.HEALTH_SHOW_BELOW_PERCENT
        local staminaLow = playerStaminaPercent ~= nil
            and playerStaminaPercent <= Constants.STAMINA_HIDE_ABOVE_PERCENT
        ApplyHUDState(hudOpacity, healthLow, staminaLow)
    end
end)

print(string.format(
    "[DynamicHUD] Automatic monster detection active (scan every %ds, %ds visible grace, %ds fade-out).",
    Constants.SCAN_INTERVAL_MS / 1000,
    Constants.VISIBLE_GRACE_PERIOD_MS / 1000,
    Constants.FADE_OUT_DURATION_MS / 1000
))
