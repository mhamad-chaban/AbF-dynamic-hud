return {
    -- Distance in Unreal units (100 units = 1 meter).
    DETECTION_RADIUS = 1000,
    MONSTER_CLASS_MARKER = "NPC_Monster",
    SCAN_INTERVAL_MS = 1000,
    HUD_UPDATE_INTERVAL_MS = 100,
    VISIBLE_GRACE_PERIOD_MS = 10000,
    FADE_IN_DURATION_MS = 500,
    FADE_OUT_DURATION_MS = 2000,
    STAMINA_HIDE_ABOVE_PERCENT = 0.5,
    HEALTH_SHOW_BELOW_PERCENT = 0.9,
    VITAL_FIELD_CANDIDATES = {
        "CurrentHealth_Head",
        "CurrentHealth_Torso",
        "CurrentHealth_LeftArm",
        "CurrentHealth_RightArm",
        "CurrentHealth_LeftLeg",
        "CurrentHealth_RightLeg",
        "Stamina",
        "CurrentStamina",
        "MaxStamina",
        "StaminaCurrent",
        "StaminaMax"
    }
}
