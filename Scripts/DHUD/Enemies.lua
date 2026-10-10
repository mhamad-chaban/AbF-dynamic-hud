local Config = require("DHUD.Config")
local Player = require("DHUD.Player")

local Enemies = {}

local function IsEnemyNPC(fullName)
    local className = fullName:match("^([^%s]+)")
    if not className or className:sub(1, #Config.NPC_ACTOR_PREFIX) ~= Config.NPC_ACTOR_PREFIX then
        return false
    end

    for _, friendlyPrefix in ipairs(Config.FRIENDLY_NPC_PREFIXES) do
        if className:sub(1, #friendlyPrefix) == friendlyPrefix then
            return false
        end
    end
    return true
end

function Enemies.GetNearbyNPCNames()
    local playerLocation, localPawn = Player.GetLocation()
    if not playerLocation then
        return nil
    end

    local candidates = {}
    local seenNames = {}
    for _, className in ipairs({ "Character", "Pawn" }) do
        for _, actor in ipairs(FindAllOf(className) or {}) do
            if actor and actor:IsValid() and actor ~= localPawn then
                local fullName = nil
                pcall(function() fullName = actor:GetFullName() end)
                if fullName and not seenNames[fullName] then
                    seenNames[fullName] = true
                    table.insert(candidates, { actor = actor, fullName = fullName })
                end
            end
        end
    end

    local nearbyEnemyNames = {}
    for _, candidate in ipairs(candidates) do
        if IsEnemyNPC(candidate.fullName) then
            local location = nil
            pcall(function() location = candidate.actor:K2_GetActorLocation() end)
            if location then
                local dx = playerLocation.X - location.X
                local dy = playerLocation.Y - location.Y
                local dz = playerLocation.Z - location.Z
                local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
                if distance <= Config.DETECTION_RADIUS then
                    table.insert(nearbyEnemyNames, candidate.fullName)
                end
            end
        end
    end

    return nearbyEnemyNames
end

return Enemies
