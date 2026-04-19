-- Config.lua
TankBuffReminderConfig = {
    buffs = {
        -- Paladin
        { key = "righteousFury",   spellID = 25780, name = "Righteous Fury" },
        { key = "devotionAura",    spellID = 10293, name = "Devotion Aura" },
        
        -- Warrior
        { key = "battleShout",     spellID = 2048,  name = "Battle Shout" },
        { key = "commandingShout", spellID = 469,   name = "Commanding Shout" },
        { key = "defensiveStance", spellID = 71,    name = "Defensive Stance" },
        
        -- Druid
        { key = "thorns",          spellID = 26992, name = "Thorns" },
        { key = "markOfTheWild",   spellID = 26990, name = "Mark of the Wild" },
        { key = "omenOfClarity",   spellID = 16864, name = "Omen of Clarity" },
    },

    sounds = {
        { name = "Default Alert", id = 8959 },
        { name = "Bell",          id = 3175 },
        { name = "Auction",       id = 5274 },
        { name = "Succubus",      id = 7096 },
    },

    defaults = {
        playSound = true,
        pulseSpeed = 4,
        soundID = 8959,
        glowSize = 1.5,
        glowColor = { r = 1, g = 1, b = 0.6, a = 1 },
        autoRemoveSalvation = true,
        autoSetTankRole = true,
        autoRepair = true,
        
        -- Taunt System Defaults
        tauntEnabled = true,   -- Enables/disables the detection logic
        tauntWarning = true,   -- Self-only warning message in chat
        tauntSay     = false,  -- Send message to /say
        tauntParty   = false,  -- Send message to /party
        tauntRaid    = false,  -- Send message to /raid
    }
}