local Config = require("DHUD.Config")

local Player = {}

function Player.GetPawn()
    local controller = GetMyPlayerController()
    if controller and controller:IsValid() and controller.Pawn and controller.Pawn:IsValid() then
        return controller.Pawn
    end
    return nil
end

function Player.GetLocation()
    local pawn = Player.GetPawn()
    if pawn then
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

function Player.GetVitalPercentages(HUD)
    local pawn = Player.GetPawn()
    if not pawn then
        return nil, nil
    end

    local healthPercent = nil
    local mainHUD = HUD.GetMainWidget()
    if mainHUD and mainHUD:IsValid() then
        healthPercent = ReadNumberProperty(mainHUD, "LastHealthPercentage")
    end

    local currentStamina = ReadNumberProperty(pawn, "CurrentStamina")
    local maxStamina = ReadNumberProperty(pawn, "MaxStamina")
    local staminaPercent = nil
    if currentStamina and maxStamina and maxStamina > 0 then
        staminaPercent = math.max(0, math.min(1, currentStamina / maxStamina))
    end

    if healthPercent then
        healthPercent = math.max(0, math.min(1, healthPercent))
    end
    return healthPercent, staminaPercent
end

function Player.GetHotbarSelectionKey()
    local pawn = Player.GetPawn()
    if not pawn then
        return nil
    end

    local selection = nil
    local success = pcall(function()
        selection = pawn.CurrentHotbarSlotSelected
    end)
    if not success or selection == nil then
        return nil
    end

    local inventory = nil
    local index = nil
    success = pcall(function()
        inventory = selection.Inventory_2_B69CD60741EFD551F09ED5AFF44B1E46
        index = selection.Index_5_6BDC7B3944A5DE0B319F9FA20720872F
    end)
    if not success or index == nil then
        return nil
    end

    local inventoryName = "no-inventory"
    if inventory then
        local gotFullName = pcall(function()
            inventoryName = inventory:GetFullName()
        end)
        if not gotFullName then
            inventoryName = tostring(inventory)
        end
    end
    return tostring(inventoryName) .. ":" .. tostring(index)
end

function Player.PrintVitalFields(label, object)
    if not object or not object:IsValid() then
        print(string.format("[DynamicHUD] %s unavailable.", label))
        return
    end

    local fullName = "unknown object"
    pcall(function() fullName = object:GetFullName() end)
    print(string.format("[DynamicHUD] %s: %s", label, fullName))
    local foundField = false

    for _, fieldName in ipairs(Config.VITAL_FIELD_CANDIDATES) do
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

function Player.PrintHealthPercentage(hud)
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

return Player
