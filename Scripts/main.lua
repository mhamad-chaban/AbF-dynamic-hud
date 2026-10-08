-- Mods/DynamicHUD/scripts/main.lua

local AFUtils = require("AFUtils.AFUtils")

local Key = Key
local hudOpacity = nil
local visibilityMode = "auto"
local hudUnavailableLogged = false

-- Master list of elements to toggle opacity on
local TARGET_HUD_PROPERTIES = {
    "HealthBar",
    "W_PlayerHUD_Hotbar",
    "W_PlayerHUD_BodyDiagram",
    "W_HUD_AmmoCounter",
    "Hbox_Gadgets",
    "HealthHeartIcon",
    "Icon_Inventory",
    "Icon_RadialWheel_Gestures",
    "Icon_RadialWheel_Health",
    "icon_watch",
    "Journal_Icon",
    "JournalPrompt",
    "Keybind_Backpack",
    "Keybind_Emote",
    "Keybind_HealthPanel",
    "Keybind_Shield",
    "Keybind_Watch",
    "SitIcon",
    "PagerIcon",
    "DEBUG_NavMesh",
    "W_HUD_QuestObjective",
    "W_HUD_BuffBar",
    "W_HUD_TemperatureBar",
    "W_HUD_GadgetBar_ActiveFlashlight",
    "W_SkillXPGain"
}

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

local function SetGameplayHUDOpacity(opacity)
    local mainHUD = GetMainHUDWidget()
    if not mainHUD or not mainHUD:IsValid() then
        if not hudUnavailableLogged then
            print("[DynamicHUD] Error: Could not locate W_PlayerHUD_Main_C instance.")
            hudUnavailableLogged = true
        end
        return false
    end

    local successCount = 0

    for _, propName in ipairs(TARGET_HUD_PROPERTIES) do
        local element = GetWidgetProperty(mainHUD, propName)
        if element then
            local success = pcall(function()
                element:SetRenderOpacity(opacity)
            end)
            if success then
                successCount = successCount + 1
            end
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

-- Distance threshold in Unreal Units (100 units = 1 meter)
local DETECTION_RADIUS = 500
local MONSTER_CLASS_MARKER = "NPC_Monster"
local SCAN_INTERVAL_MS = 1000
local HUD_UPDATE_INTERVAL_MS = 100
local VISIBLE_GRACE_PERIOD_MS = 10000
local FADE_OUT_DURATION_MS = 2000

local function GetPlayerLocation()
    local pc = GetMyPlayerController()

    if pc and pc:IsValid() and pc.Pawn and pc.Pawn:IsValid() then
        local pawn = pc.Pawn
        return pawn:K2_GetActorLocation(), pawn
    end
    return nil
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

            if fullName and string.find(fullName, MONSTER_CLASS_MARKER, 1, true) then
                local loc = nil
                pcall(function() loc = actor:K2_GetActorLocation() end)

                if loc then
                    local dx = playerLoc.X - loc.X
                    local dy = playerLoc.Y - loc.Y
                    local dz = playerLoc.Z - loc.Z
                    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

                    if dist <= DETECTION_RADIUS then
                        table.insert(nearbyMonsterNames, fullName)
                    end
                end
            end
        end
    end

    return nearbyMonsterNames
end

local function ApplyHUDOpacity(opacity)
    opacity = math.max(0, math.min(1, opacity))
    if hudOpacity and math.abs(hudOpacity - opacity) < 0.001 then
        return
    end

    if SetGameplayHUDOpacity(opacity) then
        hudOpacity = opacity
    end
end

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
        ApplyHUDOpacity(0)
    elseif visibilityMode == "manual_visible" then
        ApplyHUDOpacity(1)
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
        print("[DynamicHUD] No nearby monsters found within " .. DETECTION_RADIUS / 100.0 .. "m.")
    end
    print("--------------------------------------------")
end)

local elapsedMs = 0
local lastMonsterSeenMs = nil
local nearbyMonsters = false

LoopAsync(HUD_UPDATE_INTERVAL_MS, function()
    elapsedMs = elapsedMs + HUD_UPDATE_INTERVAL_MS

    if elapsedMs % SCAN_INTERVAL_MS == 0 then
        local nearbyMonsterNames = GetNearbyMonsterNames()
        if nearbyMonsterNames then
            nearbyMonsters = #nearbyMonsterNames > 0
            if nearbyMonsters then
                lastMonsterSeenMs = elapsedMs
            end
        else
            nearbyMonsters = false
        end
    end

    if visibilityMode == "manual_hidden" then
        ApplyHUDOpacity(0)
    elseif visibilityMode == "manual_visible" then
        ApplyHUDOpacity(1)
    elseif nearbyMonsters then
        ApplyHUDOpacity(1)
    elseif lastMonsterSeenMs then
        local timeSinceLastMonsterMs = elapsedMs - lastMonsterSeenMs
        if timeSinceLastMonsterMs <= VISIBLE_GRACE_PERIOD_MS then
            ApplyHUDOpacity(1)
        else
            local fadeProgress = (timeSinceLastMonsterMs - VISIBLE_GRACE_PERIOD_MS) / FADE_OUT_DURATION_MS
            ApplyHUDOpacity(1 - fadeProgress)
        end
    else
        ApplyHUDOpacity(0)
    end
end)

print(string.format(
    "[DynamicHUD] Automatic monster detection active (scan every %ds, %ds visible grace, %ds fade-out).",
    SCAN_INTERVAL_MS / 1000,
    VISIBLE_GRACE_PERIOD_MS / 1000,
    FADE_OUT_DURATION_MS / 1000
))
