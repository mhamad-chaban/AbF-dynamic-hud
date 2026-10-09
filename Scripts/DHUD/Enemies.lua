local Constants = require("DHUD.Constants")
local Player = require("DHUD.Player")

local Enemies = {}

function Enemies.GetNearbyMonsterNames()
    local playerLocation, localPawn = Player.GetLocation()
    if not playerLocation then
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
                local location = nil
                pcall(function() location = actor:K2_GetActorLocation() end)
                if location then
                    local dx = playerLocation.X - location.X
                    local dy = playerLocation.Y - location.Y
                    local dz = playerLocation.Z - location.Z
                    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
                    if distance <= Constants.DETECTION_RADIUS then
                        table.insert(nearbyMonsterNames, fullName)
                    end
                end
            end
        end
    end

    return nearbyMonsterNames
end

return Enemies
