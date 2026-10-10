local Diagnostics = {}

function Diagnostics.Register(Key, Player, HUD, Config)
    RegisterKeyBind(Key.F2, function()
        local playerLocation, localPawn = Player.GetLocation()
        if not playerLocation then
            print("[DynamicHUD] Player location unavailable.")
            return
        end

        local candidates = {}
        local seenNames = {}
        local candidateClasses = { "Character", "Pawn" }
        for _, className in ipairs(candidateClasses) do
            local classCandidates = FindAllOf(className) or {}
            for _, actor in ipairs(classCandidates) do
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

        print("--- [DynamicHUD] NEARBY PAWN DIAGNOSTIC ---")
        local nearbyCount = 0
        for _, candidate in ipairs(candidates) do
            local location = nil
            pcall(function() location = candidate.actor:K2_GetActorLocation() end)
            if location then
                local dx = playerLocation.X - location.X
                local dy = playerLocation.Y - location.Y
                local dz = playerLocation.Z - location.Z
                local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
                if distance <= Config.DETECTION_RADIUS then
                    nearbyCount = nearbyCount + 1
                    print(string.format("     Path: %s (%.1fm)", candidate.fullName, distance / 100.0))
                end
            end
        end
        if nearbyCount == 0 then
            print("[DynamicHUD] No nearby pawns/characters found within "
                .. Config.DETECTION_RADIUS / 100.0 .. "m.")
        end
        print("--------------------------------------------")
    end)

    RegisterKeyBind(Key.F3, function()
        local playerPawn = Player.GetPawn()
        if not playerPawn then
            print("[DynamicHUD] Player character unavailable for vitals diagnostic.")
            return
        end

        local mainHUD = HUD.GetMainWidget()
        local hudCharacter = HUD.GetProperty(mainHUD, "OwningCharacter")
        local playerPawnName = nil
        local hudCharacterName = nil
        pcall(function() playerPawnName = playerPawn:GetFullName() end)
        pcall(function()
            if hudCharacter then
                hudCharacterName = hudCharacter:GetFullName()
            end
        end)

        print("--- [DynamicHUD] PLAYER VITALS DIAGNOSTIC ---")
        Player.PrintVitalFields("Player pawn", playerPawn)
        if hudCharacter and hudCharacterName ~= playerPawnName then
            Player.PrintVitalFields("HUD owning character", hudCharacter)
        end
        Player.PrintHealthPercentage(mainHUD)
        print("--------------------------------------------")
    end)
end

return Diagnostics
