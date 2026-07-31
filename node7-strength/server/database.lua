Node7StrengthDB = Node7StrengthDB or {}

local function now()
    return os.time()
end

local function today()
    return os.date('%Y-%m-%d')
end

local function cloneStats(row)
    if not row then return nil end

    local level = tonumber(row.level) or 1
    local xp = tonumber(row.xp) or 0

    return {
        citizenid = row.citizenid,
        level = level,
        xp = xp,
        total_xp = tonumber(row.total_xp) or 0,
        daily_xp = tonumber(row.daily_xp) or 0,
        daily_reset = row.daily_reset or today(),
        last_train = tonumber(row.last_train) or 0,
        last_fight_xp = tonumber(row.last_fight_xp) or 0,
        last_decay_check = tonumber(row.last_decay_check) or now(),
        xp_needed = Config.GetXPNeeded(level),
        title = Config.GetTitle(level),
        brawl_multiplier = Config.GetBrawlMultiplier(level),
        carry_multiplier = Config.GetCarryMultiplier(level),
        stamina_multiplier = Config.GetStaminaMultiplier(level),
        knockdown_resist = Config.GetKnockdownResist(level)
    }
end

function Node7StrengthDB.EnsureSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `node7_strength` (
            `citizenid` VARCHAR(64) NOT NULL,
            `level` INT NOT NULL DEFAULT 1,
            `xp` INT NOT NULL DEFAULT 0,
            `total_xp` INT NOT NULL DEFAULT 0,
            `daily_xp` INT NOT NULL DEFAULT 0,
            `daily_reset` VARCHAR(16) NOT NULL DEFAULT '',
            `last_train` INT NOT NULL DEFAULT 0,
            `last_fight_xp` INT NOT NULL DEFAULT 0,
            `last_decay_check` INT NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

function Node7StrengthDB.Get(citizenid)
    if not citizenid or citizenid == '' then return nil end

    local row = MySQL.single.await('SELECT * FROM node7_strength WHERE citizenid = ? LIMIT 1', { citizenid })

    if not row then
        Node7StrengthDB.Create(citizenid)
        row = MySQL.single.await('SELECT * FROM node7_strength WHERE citizenid = ? LIMIT 1', { citizenid })
    end

    if row.daily_reset ~= today() then
        row.daily_xp = 0
        row.daily_reset = today()
        MySQL.update.await('UPDATE node7_strength SET daily_xp = 0, daily_reset = ? WHERE citizenid = ?', { today(), citizenid })
    end

    return cloneStats(row)
end

function Node7StrengthDB.Create(citizenid)
    if not citizenid or citizenid == '' then return false end

    MySQL.insert.await([[
        INSERT IGNORE INTO node7_strength
        (citizenid, level, xp, total_xp, daily_xp, daily_reset, last_train, last_fight_xp, last_decay_check)
        VALUES (?, 1, 0, 0, 0, ?, 0, 0, ?)
    ]], { citizenid, today(), now() })

    return true
end

function Node7StrengthDB.Save(stats)
    if not stats or not stats.citizenid then return false end

    MySQL.update.await([[
        UPDATE node7_strength
        SET level = ?, xp = ?, total_xp = ?, daily_xp = ?, daily_reset = ?, last_train = ?, last_fight_xp = ?, last_decay_check = ?
        WHERE citizenid = ?
    ]], {
        tonumber(stats.level) or 1,
        tonumber(stats.xp) or 0,
        tonumber(stats.total_xp) or 0,
        tonumber(stats.daily_xp) or 0,
        stats.daily_reset or today(),
        tonumber(stats.last_train) or 0,
        tonumber(stats.last_fight_xp) or 0,
        tonumber(stats.last_decay_check) or now(),
        stats.citizenid
    })

    return true
end

function Node7StrengthDB.SetLevel(citizenid, level)
    level = math.floor(tonumber(level) or 1)
    level = math.max(1, math.min(Config.MaxLevel, level))

    Node7StrengthDB.Create(citizenid)

    MySQL.update.await('UPDATE node7_strength SET level = ?, xp = 0 WHERE citizenid = ?', { level, citizenid })

    return Node7StrengthDB.Get(citizenid)
end

function Node7StrengthDB.Reset(citizenid)
    Node7StrengthDB.Create(citizenid)

    MySQL.update.await([[
        UPDATE node7_strength
        SET level = 1, xp = 0, total_xp = 0, daily_xp = 0, daily_reset = ?, last_train = 0, last_fight_xp = 0, last_decay_check = ?
        WHERE citizenid = ?
    ]], { today(), now(), citizenid })

    return Node7StrengthDB.Get(citizenid)
end

function Node7StrengthDB.AddXP(citizenid, amount, ignoreCap)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return Node7StrengthDB.Get(citizenid), 0, false, 'invalid_amount'
    end

    local stats = Node7StrengthDB.Get(citizenid)
    if not stats then return nil, 0, false, 'missing_stats' end

    if stats.level >= Config.MaxLevel then
        stats.level = Config.MaxLevel
        stats.xp = 0
        Node7StrengthDB.Save(stats)
        return cloneStats(stats), 0, false, 'max_level'
    end

    if stats.daily_reset ~= today() then
        stats.daily_xp = 0
        stats.daily_reset = today()
    end

    local awarded = amount

    if not ignoreCap then
        local remaining = math.max(0, Config.DailyXPCap - (tonumber(stats.daily_xp) or 0))
        awarded = math.min(amount, remaining)
    end

    if awarded <= 0 then
        return cloneStats(stats), 0, false, 'daily_cap'
    end

    local oldLevel = stats.level

    stats.xp = (tonumber(stats.xp) or 0) + awarded
    stats.total_xp = (tonumber(stats.total_xp) or 0) + awarded
    stats.daily_xp = (tonumber(stats.daily_xp) or 0) + awarded

    while stats.level < Config.MaxLevel do
        local needed = Config.GetXPNeeded(stats.level)
        if needed <= 0 or stats.xp < needed then break end
        stats.xp = stats.xp - needed
        stats.level = stats.level + 1
    end

    if stats.level >= Config.MaxLevel then
        stats.level = Config.MaxLevel
        stats.xp = 0
    end

    Node7StrengthDB.Save(stats)

    local fresh = Node7StrengthDB.Get(citizenid)
    return fresh, awarded, fresh.level > oldLevel, 'ok'
end

function Node7StrengthDB.SetLastTrain(citizenid, timestamp)
    timestamp = tonumber(timestamp) or now()
    MySQL.update.await('UPDATE node7_strength SET last_train = ? WHERE citizenid = ?', { timestamp, citizenid })
end

function Node7StrengthDB.SetLastFight(citizenid, timestamp)
    timestamp = tonumber(timestamp) or now()
    MySQL.update.await('UPDATE node7_strength SET last_fight_xp = ? WHERE citizenid = ?', { timestamp, citizenid })
end
