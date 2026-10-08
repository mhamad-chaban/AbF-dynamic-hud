-- Mods/DynamicHUD/scripts/main.lua

local AFUtils = require("AFUtils.AFUtils")

local Key = Key
local isHudVisible = true

-- Master list of elements to toggle opacity on
local TARGET_HUD_PROPERTIES = {
    -- Always-visible HUD elements & icons
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

    -- Dynamic auto-hide widgets
    "W_HUD_BuffBar",
    "W_HUD_TemperatureBar",
    "W_HUD_GadgetBar_ActiveFlashlight"
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

local function SetGameplayHUDVisibility(visible)
    local mainHUD = GetMainHUDWidget()
    if not mainHUD or not mainHUD:IsValid() then
        print("[DynamicHUD] Error: Could not locate W_PlayerHUD_Main_C instance.")
        return
    end

    local targetOpacity = visible and 1.0 or 0.0
    local successCount = 0

    for _, propName in ipairs(TARGET_HUD_PROPERTIES) do
        local element = GetWidgetProperty(mainHUD, propName)
        if element then
            local success = pcall(function()
                element:SetRenderOpacity(targetOpacity)
            end)
            if success then
                successCount = successCount + 1
            end
        end
    end

    print(string.format("[DynamicHUD] HUD Opacity set to %.1f (%d/%d elements updated)",
        targetOpacity, successCount, #TARGET_HUD_PROPERTIES))
end

-- Keybind Toggle (F8)
RegisterKeyBind(Key.F8, function()
    isHudVisible = not isHudVisible
    SetGameplayHUDVisibility(isHudVisible)
end)

print("[DynamicHUD] Specific target whitelist active!")



-- Distance threshold in Unreal Units (100 units = 1 meter)
local DETECTION_RADIUS = 1500.0

-- Helper to get player position vector
local function GetPlayerLocation()
    local pc = GetMyPlayerController()

    if pc and pc:IsValid() and pc.Pawn and pc.Pawn:IsValid() then
        return pc.Pawn:K2_GetActorLocation()
    end
    return nil
end

RegisterKeyBind(Key.F2, function()
    local playerLoc, localPawn = GetPlayerLocation()
    if not playerLoc then
        print("[DynamicHUD] Player location unavailable.")
        return
    end

    print("--- [DynamicHUD] NEARBY ACTOR DIAGNOSTIC ---")
    local count = 0

    -- Query broad actor base classes in memory
    local candidates = FindAllOf("Character") or FindAllOf("Pawn") or {}

    for _, actor in ipairs(candidates) do
        if actor and actor:IsValid() and actor ~= localPawn then
            local loc = nil
            pcall(function() loc = actor:K2_GetActorLocation() end)

            if loc then
                local dx = playerLoc.X - loc.X
                local dy = playerLoc.Y - loc.Y
                local dz = playerLoc.Z - loc.Z
                local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

                -- 3000 units = 30 meters
                if dist <= 1500.0 then
                    count = count + 1
                    local fullName = actor:GetFullName() or "Unknown"
                    local meters = dist / 100.0


                    print(string.format("     Path: %s", fullName))
                end
            end
        end
    end

    if count == 0 then
        print("[DynamicHUD] No nearby Pawns/Characters found within 30m.")
    end
    print("--------------------------------------------")
end)
