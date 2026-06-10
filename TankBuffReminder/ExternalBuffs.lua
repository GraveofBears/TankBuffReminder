-- ExternalBuffs.lua
-- Data table for external (raid/party) buff tracking.
-- Buffs cast ON the player BY other players.
-- Each entry: key, name, buffName (string or {table}), icon, sourceClass, spellID
--
-- Sourced from BuffBuddy CLASS_DATA cross-reference + TBC buff compendium.
-- Greater Blessing variants are included in buffName tables so the bar correctly
-- recognises both the single-target and raid-wide versions.

TankBuffReminderExternalBuffs = {

    -- ── PRIEST ──────────────────────────────────────────────────────────────
    {
        key         = "ext_fortitude",
        name        = "Prayer of Fortitude",
        buffName    = { "Power Word: Fortitude", "Prayer of Fortitude" },
        icon        = "Interface\\Icons\\Spell_Holy_WordFortitude",
        sourceClass = "PRIEST",
        spellID     = 21562,
    },
    {
        key         = "ext_shadowProt",
        name        = "Prayer of Shadow Protection",
        buffName    = { "Shadow Protection", "Prayer of Shadow Protection" },
        icon        = "Interface\\Icons\\Spell_Holy_PrayerOfShadowProtection",
        sourceClass = "PRIEST",
        spellID     = 27683,
    },
    {
        key         = "ext_divineSpirit",
        name        = "Divine Spirit",
        buffName    = { "Divine Spirit", "Prayer of Spirit" },
        icon        = "Interface\\Icons\\Spell_Holy_DivineSpirit",
        sourceClass = "PRIEST",
        spellID     = 27841,
    },
    {
        key         = "ext_fearWard",
        name        = "Fear Ward",
        buffName    = "Fear Ward",
        icon        = "Interface\\Icons\\spell_holy_excorcism",
        sourceClass = "PRIEST",
        spellID     = 6346,
    },
    {
        key         = "ext_innerFire",
        name        = "Inner Fire",
        buffName    = "Inner Fire",
        icon        = "Interface\\Icons\\Spell_Holy_InnerFire",
        sourceClass = "PRIEST",
        spellID     = 25431,
    },

    -- ── MAGE ────────────────────────────────────────────────────────────────
    {
        key         = "ext_arcaneBrilliance",
        name        = "Arcane Brilliance",
        buffName    = { "Arcane Brilliance", "Arcane Intellect" },
        icon        = "Interface\\Icons\\Spell_Holy_MagicalSentry",
        sourceClass = "MAGE",
        spellID     = 27127,
    },

    -- ── DRUID ───────────────────────────────────────────────────────────────
    {
        key         = "ext_markOfTheWild",
        name        = "Mark of the Wild",
        buffName    = { "Mark of the Wild", "Gift of the Wild" },
        icon        = "Interface\\Icons\\Spell_Nature_Regeneration",
        sourceClass = "DRUID",
        spellID     = 26990,
    },
    {
        key         = "ext_thorns",
        name        = "Thorns",
        buffName    = "Thorns",
        icon        = "Interface\\Icons\\Spell_Nature_Thorns",
        sourceClass = "DRUID",
        spellID     = 26992,
    },

    -- ── PALADIN ─────────────────────────────────────────────────────────────
    {
        key         = "ext_blessingOfKings",
        name        = "Blessing of Kings",
        buffName    = { "Blessing of Kings", "Greater Blessing of Kings" },
        icon        = "Interface\\Icons\\Spell_Magic_MageArmor",
        sourceClass = "PALADIN",
        spellID     = 20217,
    },
    {
        key         = "ext_blessingOfMight",
        name        = "Blessing of Might",
        buffName    = { "Blessing of Might", "Greater Blessing of Might" },
        icon        = "Interface\\Icons\\Spell_Holy_FistOfJustice",
        sourceClass = "PALADIN",
        spellID     = 27140,
    },
    {
        key         = "ext_blessingOfWisdom",
        name        = "Blessing of Wisdom",
        buffName    = { "Blessing of Wisdom", "Greater Blessing of Wisdom" },
        icon        = "Interface\\Icons\\Spell_Holy_SealOfWisdom",
        sourceClass = "PALADIN",
        spellID     = 27142,
    },
    {
        key         = "ext_blessingOfSanctuary",
        name        = "Blessing of Sanctuary",
        buffName    = { "Blessing of Sanctuary", "Greater Blessing of Sanctuary" },
        icon        = "Interface\\Icons\\Spell_Holy_SealOfSalvation",
        sourceClass = "PALADIN",
        spellID     = 20911,
    },
    {
        key         = "ext_blessingOfLight",
        name        = "Blessing of Light",
        buffName    = { "Blessing of Light", "Greater Blessing of Light" },
        icon        = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02",
        sourceClass = "PALADIN",
        spellID     = 27144,
    },
}