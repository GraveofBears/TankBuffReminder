-- Config.lua
TankBuffReminderConfig = {
    buffs = {
        -- Paladin
        { key = "righteousFury",   spellID = 25780, name = "Righteous Fury",   class = "PALADIN" },
        { key = "devotionAura",    spellID = 10293, name = "Devotion Aura",    class = "PALADIN" },

        -- Warrior
        { key = "battleShout",     spellID = 2048,  name = "Battle Shout",     class = "WARRIOR" },
        { key = "commandingShout", spellID = 469,   name = "Commanding Shout", class = "WARRIOR" },
        { key = "defensiveStance", spellID = 71,    name = "Defensive Stance", class = "WARRIOR" },

        -- Druid
        { key = "thorns",          spellID = 26992, name = "Thorns",           class = "DRUID" },
        { key = "markOfTheWild",   spellID = 26990, name = "Mark of the Wild", class = "DRUID" },
        { key = "omenOfClarity",   spellID = 16864, name = "Omen of Clarity",  class = "DRUID" },
    },

    -- Buffs to auto-cancel whenever detected (in or out of combat).
    -- Not tracked as reminder icons — CancelUnitBuff handles removal directly.
    autoRemove = {
        {
            key            = "salvation",
            dbKey          = "autoRemoveSalvation",
            showIconDbKey  = "showIconSalvation",
            label          = "Blessing of Salvation",
            watchNames     = { "Blessing of Salvation", "Greater Blessing of Salvation" },
        },
        {
            key            = "bop",
            dbKey          = "autoRemoveBoP",
            showIconDbKey  = "showIconBoP",
            label          = "Blessing of Protection",
            watchNames     = { "Blessing of Protection", "Greater Blessing of Protection" },
        },
    },

    sounds = {
        { name = "Default Alert", id = 8959 },
        { name = "Bell",          id = 3175 },
        { name = "Auction",       id = 5274 },
        { name = "Succubus",      id = 7096 },
        { name = "Ready Check",   id = 8960 },
        { name = "Quest Failed",  id = 847 },
        { name = "Murloc",        id = 416 },
        { name = "Chicken",       id = 8352 },
        { name = "Oof",           id = 1321 },
    },

    defaults = {
        playSound = true,
        pulseSpeed = 4,
        soundID = 8959,
        glowSize = 2,
        glowColor = { r = 1, g = 1, b = 0.6, a = 1 },
        autoRemoveSalvation = false,
        autoRemoveBoP       = false,
        showIconSalvation   = false,
        showIconBoP         = false,
        removeSoundEnabled  = true,
        removeSoundID       = 569143,
        autoSetTankRole     = false,
        autoRepair          = true,
        defCapBtnShow       = true,
        frameAlpha          = 1.0,
        buffAlpha           = 1.0,
        sweepAlpha          = 0.6,
        timerTextOffsetY    = 0,
        timerTextColor      = { r = 1, g = 1, b = 1 },
        timerFontSize       = 12,
        timerAlpha          = 1.0,
		defCapColor = { r = 0.6, g = 0.5, b = 0.2, a = 1 },

        -- Taunt System Defaults
        tauntEnabled      = true,
        tauntWarning      = true,
        tauntSay          = false,
        tauntParty        = false,
        tauntRaid         = false,
        tauntSoundEnabled = true,
        tauntSoundID      = 8959,

        -- Main Bar
        buttonPadding       = 4,

        -- Consumable Bar
        consBarEnabled      = true,
        consFrameAlpha      = 0.3,
        consScale           = 1.0,
        consAlpha           = 0.4,
        consPadding         = 4,
        consMouseover       = false,
		consPulseSpeed      = 3,

        -- Consumable Timers
        consTimerFontSize   = 12,
        consTimerOffsetY    = 0,
        consTimerAlpha      = 1.0,
        consSweepAlpha      = 0.6,

        -- Consumable Colors
        consTextColor       = { r = 1, g = 1, b = 1 },
        consGlowColor       = { r = 0, g = 1, b = 0, a = 1 },
        consGlowAlpha       = 1.0,
    },
	
	consumables = {
        -- Recovery
        { key="healthstone",  label="Healthstone",            category="Recovery",  itemIDs={22103, 22104, 22105}, icon="Interface\\Icons\\inv_misc_food_55", defaultOn=false, isPotionType=false, druidInstant=true,  druidWarn=false },
        { key="bandage",      label="Bandage",                category="Recovery",  itemIDs={21991, 21990},        icon="Interface\\Icons\\inv_misc_bandage_12", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true  },
        { key="nightmareSeed",label="Nightmare Seed",         category="Recovery",  itemIDs={22797},               icon="Interface\\Icons\\inv_misc_herb_nightmareseed", defaultOn=false, isPotionType=false, druidInstant=true,  druidWarn=false },

        -- Potions
        { key="healPotion",      label="Healing Potion",          category="Potions", itemIDs={22829}, icon="Interface\\Icons\\inv_potion_167", defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="manaPotion",      label="Mana Potion",             category="Potions", itemIDs={22832}, icon="Interface\\Icons\\inv_potion_168", defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="ironshield",      label="Ironshield Potion",       category="Potions", itemIDs={22849}, icon="Interface\\Icons\\inv_potion_155", defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="hastePotion",     label="Haste Potion",            category="Potions", itemIDs={22838}, icon="Interface\\Icons\\inv_potion_156", defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="destroPotion",    label="Destruction Potion",      category="Potions", itemIDs={22839}, icon="Interface\\Icons\\inv_potion_162", defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="mightyRage",      label="Mighty Rage Potion",      category="Potions", itemIDs={13442}, icon="Interface\\Icons\\inv_potion_41",  defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="freeAction",      label="Free Action Potion",      category="Potions", itemIDs={5634},  icon="Interface\\Icons\\inv_potion_04",  defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="superRejuv",      label="Super Rejuvenation",      category="Potions", itemIDs={22850}, icon="Interface\\Icons\\inv_potion_150", defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="auchenaiMana",    label="Auchenai Mana Potion",    category="Potions", itemIDs={32948}, icon="Interface\\Icons\\inv_potion_171", defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="nethergonVapor",  label="Bottled Nethergon Vapor", category="Potions", itemIDs={32905}, icon="Interface\\Icons\\inv_potion_143", defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        { key="nethergonEnergy", label="Bottled Nethergon Energy", category="Potions", itemIDs={32902}, icon="Interface\\Icons\\inv_potion_147", defaultOn=false, isPotionType=true,  druidInstant=true, druidWarn=false },
        
        -- Protection Potions
        { key="protFrost",  label="Major Frost Protection",  category="Potions", itemIDs={22823}, icon="Interface\\Icons\\inv_potion_145", defaultOn=false, isPotionType=true, druidInstant=true, druidWarn=false },
        { key="protNature", label="Major Nature Protection", category="Potions", itemIDs={22844}, icon="Interface\\Icons\\inv_potion_159", defaultOn=false, isPotionType=true, druidInstant=true, druidWarn=false },
        { key="protFire",   label="Major Fire Protection",   category="Potions", itemIDs={22841}, icon="Interface\\Icons\\inv_potion_141", defaultOn=false, isPotionType=true, druidInstant=true, druidWarn=false },
        { key="protShadow", label="Major Shadow Protection", category="Potions", itemIDs={22846}, icon="Interface\\Icons\\inv_potion_161", defaultOn=false, isPotionType=true, druidInstant=true, druidWarn=false },
        { key="protArcane", label="Major Arcane Protection", category="Potions", itemIDs={22845}, icon="Interface\\Icons\\inv_potion_149", defaultOn=false, isPotionType=true, druidInstant=true, druidWarn=false },
        
        -- Flasks
        { key="flaskFortification", label="Flask of Fortification",      category="Flasks", itemIDs={22851, 32901}, icon="Interface\\Icons\\inv_potion_155", defaultOn=false, druidInstant=true, druidWarn=false },
        { key="flaskRelentless",    label="Flask of Relentless Assault", category="Flasks", itemIDs={22854, 32903}, icon="Interface\\Icons\\inv_potion_154", defaultOn=false, druidInstant=true, druidWarn=false },
        { key="flaskChromatic",     label="Flask of Chromatic Wonder",   category="Flasks", itemIDs={33208},        icon="Interface\\Icons\\inv_potion_157", defaultOn=false, druidInstant=true, druidWarn=false },
        { key="flaskBlinding",      label="Flask of Blinding Light",     category="Flasks", itemIDs={22861, 32902}, icon="Interface\\Icons\\inv_potion_151", defaultOn=false, druidInstant=true, druidWarn=false },

        -- Guardian Elixirs
        { key="elixirMajorMageblood", label="Elixir of Major Mageblood",   category="Guardian Elixirs", itemIDs={22840}, icon="Interface\\Icons\\inv_potion_170", defaultOn=false, druidInstant=true, druidWarn=false, buffSpellID=38913 },
        { key="elixirMajorDefense",   label="Elixir of Major Defense",     category="Guardian Elixirs", itemIDs={22834}, icon="Interface\\Icons\\inv_potion_158", defaultOn=false, druidInstant=true, druidWarn=false, buffSpellID=32839 },
        { key="elixirMajorFort",      label="Elixir of Major Fortitude",   category="Guardian Elixirs", itemIDs={32062}, icon="Interface\\Icons\\inv_potion_155", defaultOn=false, druidInstant=true, druidWarn=false, buffSpellID=32844 },
        { key="giftArthas",           label="Gift of Arthas",              category="Guardian Elixirs", itemIDs={9088},  icon="Interface\\Icons\\inv_potion_28",  defaultOn=false, druidInstant=true, druidWarn=false, buffSpellID=11390 },

        -- Battle Elixirs
        { key="elixirMajorAgility",  label="Elixir of Major Agility",    category="Battle Elixirs", itemIDs={22831}, icon="Interface\\Icons\\inv_potion_152", defaultOn=false, druidInstant=true, druidWarn=false, buffSpellID=32833 },
        { key="elixirMajorStrength", label="Elixir of Major Strength",   category="Battle Elixirs", itemIDs={22824}, icon="Interface\\Icons\\inv_potion_153", defaultOn=false, druidInstant=true, druidWarn=false, buffSpellID=32854 },
        { key="elixirGreaterArcane", label="Greater Arcane Elixir",      category="Battle Elixirs", itemIDs={13454}, icon="Interface\\Icons\\inv_potion_25",  defaultOn=false, druidInstant=true, druidWarn=false, buffSpellID=17539 },
        { key="elixirDemonslaying",  label="Elixir of Demonslaying",     category="Battle Elixirs", itemIDs={9224},  icon="Interface\\Icons\\inv_potion_29",  defaultOn=false, druidInstant=true, druidWarn=false, buffSpellID=11406 },
        
        -- Scrolls
        { key="scrollAgility",    label="Scroll of Agility V",    category="Scrolls", itemIDs={27498}, icon="Interface\\Icons\\inv_scroll_02", defaultOn=false, druidInstant=true,  druidWarn=false, buffSpellID=33077 },
        { key="scrollStrength",   label="Scroll of Strength V",   category="Scrolls", itemIDs={27503}, icon="Interface\\Icons\\inv_scroll_01", defaultOn=false, druidInstant=true,  druidWarn=false, buffSpellID=33082 },
        { key="scrollProtection", label="Scroll of Protection V", category="Scrolls", itemIDs={27500}, icon="Interface\\Icons\\inv_scroll_04", defaultOn=false, druidInstant=true,  druidWarn=false, buffSpellID=33079 },
        { key="scrollStamina",    label="Scroll of Stamina V",    category="Scrolls", itemIDs={27502}, icon="Interface\\Icons\\inv_scroll_07", defaultOn=false, druidInstant=true,  druidWarn=false, buffSpellID=33080 },

        -- Weapon Buffs
        { key="stoneAdamantiteWeight", label="Adamantite Weightstone",  category="Weapon", itemIDs={28421}, icon="Interface\\Icons\\inv_stone_weightstone_05", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true },
        { key="stoneAdamantiteSharp",  label="Adamantite Sharpening",   category="Weapon", itemIDs={23529}, icon="Interface\\Icons\\inv_stone_sharpeningstone_05", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true },
        { key="oilSuperiorWizard",     label="Superior Wizard Oil",     category="Weapon", itemIDs={22522}, icon="Interface\\Icons\\inv_potion_105", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true },
        { key="oilSuperiorMana",       label="Superior Mana Oil",       category="Weapon", itemIDs={22521}, icon="Interface\\Icons\\inv_potion_100", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true },
        
        -- Engineering & Utility
        { key="superSapper",       label="Super Sapper Charge",   category="Engineering", itemIDs={23827}, icon="Interface\\Icons\\inv_gizmo_supersappercharge", defaultOn=false, isPotionType=false, druidInstant=true,  druidWarn=false },
        { key="goblinSapper",      label="Goblin Sapper Charge",  category="Engineering", itemIDs={10646}, icon="Interface\\Icons\\inv_gizmo_01",                defaultOn=false, isPotionType=false, druidInstant=true,  druidWarn=false },
        { key="adamantiteGrenade", label="Adamantite Grenade",    category="Engineering", itemIDs={23737}, icon="Interface\\Icons\\inv_misc_bombs_07",          defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true  },
        { key="runeWarding",       label="Greater Rune of Warding",category="Utility",     itemIDs={25521}, icon="Interface\\Icons\\inv_misc_rune_08",          defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true  },
        { key="deviateDelight",    label="Savory Deviate Delight", category="Utility",     itemIDs={6657},  icon="Interface\\Icons\\inv_misc_food_33",          defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID={8219, 8222} },
        { key="noggenfogger",      label="Noggenfogger Elixir",    category="Utility",     itemIDs={8529},  icon="Interface\\Icons\\inv_potion_83",            defaultOn=false, isPotionType=false, druidInstant=true,  druidWarn=false },

        -- Food Buffs
        { key="foodFishermansFeast",  label="Fisherman's Feast",    category="Food", itemIDs={33052}, icon="Interface\\Icons\\inv_misc_food_88_bluegill", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=43764 },
        { key="foodSpicyCrawdad",     label="Spicy Crawdad",        category="Food", itemIDs={27667}, icon="Interface\\Icons\\inv_misc_food_85_crawdad", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=33268 },
        { key="foodBlackenedBasilisk", label="Blackened Basilisk",   category="Food", itemIDs={27657}, icon="Interface\\Icons\\inv_misc_food_81_basilisk", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=33259 },
        { key="foodWarpBurger",       label="Warp Burger",          category="Food", itemIDs={27659}, icon="Interface\\Icons\\inv_misc_food_83_warpstalker", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=33261 },
        { key="foodElderberryPie",    label="Elderberry Pie",       category="Food", itemIDs={23435}, icon="Interface\\Icons\\inv_misc_food_10", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=46598 },
        { key="foodFireToastedBun",   label="Fire-toasted Bun",      category="Food", itemIDs={23327}, icon="Interface\\Icons\\inv_misc_food_11", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=46599 },
        { key="foodMinceFruitcake",   label="Mince Meat Fruitcake", category="Food", itemIDs={21215}, icon="Interface\\Icons\\inv_misc_food_12", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=24732 },
        { key="foodSpicyTalbuk",      label="Spicy Hot Talbuk",     category="Food", itemIDs={33872}, icon="Interface\\Icons\\inv_misc_food_86_talbuk", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=33263 },
        { key="foodRavagerDog",       label="Ravager Dog",          category="Food", itemIDs={27655}, icon="Interface\\Icons\\inv_misc_food_82_ravager", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=33256 },
        { key="foodKiblersBits",      label="Kibler's Bits",        category="Food", itemIDs={33874}, icon="Interface\\Icons\\inv_misc_food_93_kiblersbits", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=43771 },
        { key="foodGrilledMudfish",   label="Grilled Mudfish",      category="Food", itemIDs={27664}, icon="Interface\\Icons\\inv_misc_food_87_mudfish", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=33261 },
        { key="foodRoastedClefthoof", label="Roasted Clefthoof",    category="Food", itemIDs={27658}, icon="Interface\\Icons\\inv_misc_food_80_clefthoof", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=33257 },
        { key="foodFeltailDelight",   label="Feltail Delight",      category="Food", itemIDs={27662}, icon="Interface\\Icons\\inv_misc_food_84_feltail", defaultOn=false, isPotionType=false, druidInstant=false, druidWarn=true, buffSpellID=33293 },
    },
}