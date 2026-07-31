Config = {}

Config.Debug = false

Config.Command = 'strength'
Config.AdminAce = 'node7.strength.admin'

Config.MaxLevel = 100
Config.BaseXP = 100
Config.XPPerLevel = 45
Config.XPCurve = 8

Config.DailyXPCap = 750
Config.TrainingCooldown = 300
Config.FightXPCooldown = 25
Config.SameTargetFightCooldown = 180

Config.StrengthTitles = {
    { min = 1,  max = 10,  title = 'Greenhorn' },
    { min = 11, max = 25,  title = 'Scrapper' },
    { min = 26, max = 50,  title = 'Brawler' },
    { min = 51, max = 75,  title = 'Bruiser' },
    { min = 76, max = 99,  title = 'Ironhand' },
    { min = 100, max = 100, title = 'Frontier Strongman' }
}

Config.Multipliers = {
    MaxPunchBonus = 0.12,
    MaxCarryBonus = 0.20,
    MaxStaminaBonus = 0.18,
    MaxTrainingSpeedBonus = 0.08,
    MaxKnockdownResist = 0.10
}

Config.Effects = {
    EnableMeleeModifier = true,
    EnableStaminaSupport = true,
    EnableFightXP = true,
    FightXP = 4,
    TrainingXP = 25,
    UIPopupTime = 4500
}

Config.Decay = {
    Enabled = false,
    DaysBeforeDecay = 14,
    XPPerDecayTick = 25
}

Config.TrainingPromptKey = 0xCEFD9220 -- INPUT_CONTEXT / E
Config.TrainingPromptText = 'Train Strength'
Config.TrainingPromptGroup = 'NODE7 Strength Training'

Config.Training = {
    {
        name = 'Valentine Lumber Yard',
        label = 'Lift Supply Crate',
        coords = vector3(-384.18, 790.32, 115.90),
        radius = 2.0,
        drawDistance = 18.0,
        duration = 8500,
        xp = 25,
        scenario = 'WORLD_HUMAN_HAMMERING'
    },
    {
        name = 'Blackwater Docks',
        label = 'Dock Worker Lift',
        coords = vector3(-751.23, -1268.35, 44.05),
        radius = 2.0,
        drawDistance = 18.0,
        duration = 8500,
        xp = 25,
        scenario = 'WORLD_HUMAN_HAMMERING'
    },
    {
        name = 'Saint Denis Worker Yard',
        label = 'Heavy Labor Drill',
        coords = vector3(2502.42, -1455.41, 46.31),
        radius = 2.0,
        drawDistance = 18.0,
        duration = 8500,
        xp = 25,
        scenario = 'WORLD_HUMAN_HAMMERING'
    },
    {
        name = 'Rhodes Farm Yard',
        label = 'Farmhand Strength Drill',
        coords = vector3(1377.84, -1308.12, 77.04),
        radius = 2.0,
        drawDistance = 18.0,
        duration = 8500,
        xp = 25,
        scenario = 'WORLD_HUMAN_HAMMERING'
    },
    {
        name = 'Annesburg Mine',
        label = 'Mine Labor Drill',
        coords = vector3(2921.58, 1361.11, 45.18),
        radius = 2.0,
        drawDistance = 18.0,
        duration = 8500,
        xp = 25,
        scenario = 'WORLD_HUMAN_PICKAXE_WALL'
    },
    {
        name = 'Strawberry Lumber Camp',
        label = 'Lumber Strength Drill',
        coords = vector3(-1817.71, -421.28, 160.06),
        radius = 2.0,
        drawDistance = 18.0,
        duration = 8500,
        xp = 25,
        scenario = 'WORLD_HUMAN_HAMMERING'
    }
}

Config.UI = {
    Brand = 'NODE7',
    Title = 'PLAYER STRENGTH',
    Position = 'right'
}

function Config.GetTitle(level)
    for _, entry in ipairs(Config.StrengthTitles) do
        if level >= entry.min and level <= entry.max then
            return entry.title
        end
    end

    return 'Greenhorn'
end

function Config.GetXPNeeded(level)
    if level >= Config.MaxLevel then return 0 end
    return math.floor(Config.BaseXP + ((level - 1) * Config.XPPerLevel) + (((level - 1) * (level - 1)) * Config.XPCurve))
end

function Config.GetProgress(level)
    local rank = math.max(0, math.min(Config.MaxLevel, tonumber(level) or 1))
    return rank / Config.MaxLevel
end

function Config.GetBrawlMultiplier(level)
    local progress = Config.GetProgress(level)
    return 1.0 + (Config.Multipliers.MaxPunchBonus * progress)
end

function Config.GetCarryMultiplier(level)
    local progress = Config.GetProgress(level)
    return 1.0 + (Config.Multipliers.MaxCarryBonus * progress)
end

function Config.GetStaminaMultiplier(level)
    local progress = Config.GetProgress(level)
    return 1.0 + (Config.Multipliers.MaxStaminaBonus * progress)
end

function Config.GetKnockdownResist(level)
    local progress = Config.GetProgress(level)
    return Config.Multipliers.MaxKnockdownResist * progress
end
