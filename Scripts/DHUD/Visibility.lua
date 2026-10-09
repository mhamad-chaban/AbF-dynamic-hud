local Visibility = {}

function Visibility.Start(Key, Constants, HUD, Player, Enemies)
    local mode = "auto"
    local elapsedMs = 0
    local lastMonsterSeenMs = nil
    local lastHotbarChangeMs = nil
    local previousHotbarSelection = nil
    local nearbyMonsters = false
    local hudOpacity = 0
    local playerHealthPercent = nil
    local playerStaminaPercent = nil

    RegisterKeyBind(Key.F8, function()
        if mode == "auto" then
            mode = "manual_hidden"
            print("[DynamicHUD] Manual override: HUD hidden. Press F8 to show it.")
        elseif mode == "manual_hidden" then
            mode = "manual_visible"
            print("[DynamicHUD] Manual override: HUD visible. Press F8 to resume automatic mode.")
        else
            mode = "auto"
            print("[DynamicHUD] Automatic HUD visibility resumed.")
        end

        if mode == "manual_hidden" then
            hudOpacity = 0
            HUD.ApplyState(0, false, false)
        elseif mode == "manual_visible" then
            hudOpacity = 1
            HUD.ApplyState(1, true, true)
        end
    end)

    LoopAsync(Constants.HUD_UPDATE_INTERVAL_MS, function()
        elapsedMs = elapsedMs + Constants.HUD_UPDATE_INTERVAL_MS

        local hotbarSelection = Player.GetHotbarSelectionKey()
        if hotbarSelection then
            if previousHotbarSelection and hotbarSelection ~= previousHotbarSelection then
                lastHotbarChangeMs = elapsedMs
            end
            previousHotbarSelection = hotbarSelection
        else
            previousHotbarSelection = nil
        end

        if elapsedMs % Constants.SCAN_INTERVAL_MS == 0 then
            local nearbyMonsterNames = Enemies.GetNearbyMonsterNames()
            if nearbyMonsterNames then
                nearbyMonsters = #nearbyMonsterNames > 0
                if nearbyMonsters then
                    lastMonsterSeenMs = elapsedMs
                end
            else
                nearbyMonsters = false
            end
            playerHealthPercent, playerStaminaPercent = Player.GetVitalPercentages(HUD)
        end

        if mode == "manual_hidden" then
            HUD.ApplyState(0, false, false)
        elseif mode == "manual_visible" then
            HUD.ApplyState(1, true, true)
        else
            local targetOpacity = 0
            local lastActivityMs = lastMonsterSeenMs
            if lastHotbarChangeMs and (not lastActivityMs or lastHotbarChangeMs > lastActivityMs) then
                lastActivityMs = lastHotbarChangeMs
            end

            if nearbyMonsters then
                targetOpacity = 1
            elseif lastActivityMs then
                local timeSinceLastActivityMs = elapsedMs - lastActivityMs
                if timeSinceLastActivityMs <= Constants.VISIBLE_GRACE_PERIOD_MS then
                    targetOpacity = 1
                end
            end

            local fadeDurationMs = targetOpacity > hudOpacity
                and Constants.FADE_IN_DURATION_MS
                or Constants.FADE_OUT_DURATION_MS
            local opacityStep = Constants.HUD_UPDATE_INTERVAL_MS / fadeDurationMs
            if targetOpacity > hudOpacity then
                hudOpacity = math.min(targetOpacity, hudOpacity + opacityStep)
            elseif targetOpacity < hudOpacity then
                hudOpacity = math.max(targetOpacity, hudOpacity - opacityStep)
            end

            local healthLow = playerHealthPercent ~= nil
                and playerHealthPercent <= Constants.HEALTH_SHOW_BELOW_PERCENT
            local staminaLow = playerStaminaPercent ~= nil
                and playerStaminaPercent <= Constants.STAMINA_HIDE_ABOVE_PERCENT
            HUD.ApplyState(hudOpacity, healthLow, staminaLow)
        end
    end)

    print(string.format(
        "[DynamicHUD] Automatic monster detection active (scan every %ds, %ds visible grace, %ds fade-in, %ds fade-out).",
        Constants.SCAN_INTERVAL_MS / 1000,
        Constants.VISIBLE_GRACE_PERIOD_MS / 1000,
        Constants.FADE_IN_DURATION_MS / 1000,
        Constants.FADE_OUT_DURATION_MS / 1000
    ))
end

return Visibility
