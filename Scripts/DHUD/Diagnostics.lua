local Diagnostics = {}

function Diagnostics.Register(Key, Player, HUD, Enemies, Constants)
    RegisterKeyBind(Key.F2, function()
        local nearbyMonsterNames = Enemies.GetNearbyMonsterNames()
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
