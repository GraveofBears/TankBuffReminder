-- Locales/enUS.lua
-- English (enUS / enGB). This is the master string table.
-- All other locales fall back to these keys when a translation is missing.
-- Value of `true` means "use the key itself as the display string".

local locale = GetLocale()
if locale ~= "enUS" and locale ~= "enGB" then return end

local L = TBR_L

-- ── Options Panel ─────────────────────────────────────────────────────────────
L["Tank Buff Reminder"]                = true
L["Select a tab below to configure."] = true

-- Tab names
L["Buffs"]       = true
L["Appearance"]  = true
L["Alerts"]      = true
L["Automation"]  = true
L["Consumables"] = true

-- Buffs tab
L["Only your class section is active.  * sets cast priority (top = first shown)."] = true

-- Appearance tab — Main Bar
L["Main Bar Appearance"]   = true
L["Glow Size"]             = true
L["Pulse Speed"]           = true
L["Frame Alpha"]           = true
L["Icon Alpha"]            = true
L["Button Spacing"]        = true
L["Glow Color"]            = true
L["Bar Scale"]             = true
L["Buff Sweep Alpha"]      = true
L["Timer Text Alpha"]      = true
L["Text Vertical Offset"]  = true
L["Font Size"]             = true
L["Duration Text Color"]   = true

-- Appearance tab — Consumable Bar
L["Consumable Bar Appearance"] = true
L["Frame & Border Alpha"]      = true
L["Icon Alpha (Active)"]       = true
L["Glow Alpha"]                = true
L["Sweep Alpha"]               = true
L["Cons Glow Color"]           = true
L["Timer Font Size"]           = true
L["Timer Y Offset"]            = true
L["Timer Alpha"]               = true
L["Text Color"]                = true
L["Hide until Mouseover"]      = true
L["Hide Empty Buttons"]        = true
L["Bar Orientation"]           = true
L["Horizontal"]                = true
L["Vertical"]                  = true
L["Minimap Button Settings"]  = true
L["Show Minimap Button"]      = true
L["Minimap Angle"]            = true
L["Minimap Distance"]         = true

-- Alerts tab
L["Buff Alert Sound"]                        = true
L["Play sound when a buff is missing"]       = true
L["Missing Buff Sound:"]                     = true
L["Removal Alerts"]                          = true
L["Enable removal alert sound (Salv/BoP)"]   = true
L["Removal Alert Sound:"]                    = true
L["Taunt Alert System"]                      = true
L["Enable Taunt Failure Detection"]          = true
L["Self Warning (chat message)"]             = true
L["Announce in /Say"]                        = true
L["Announce in /Yell"]                       = true
L["Announce in /Party"]                      = true
L["Announce in /Raid"]                       = true
L["Play sound on taunt failure"]             = true
L["Taunt Failure Sound:"]                    = true
L["Unknown Alert"]                           = true

-- Low Threat Alert System
L["Low Threat Alert System"]           = true
L["Enable Low Threat Alert"]      = true
L["Track Spell Misses"]           = true
L["Track Spell Resists"]          = true
L["Track CC / Stuns"]                    = true
L["CC Alerts last for entire combat"]    = true
L["Alert Window (sec)"]           = true
L["Play sound on threat alert"]   = true
L["Threat Alert Sound:"]          = true
L["THREAT_ALERT_PREFIX"] =
    "Threat Warning: "
L["THREAT_MISS"]   = "Miss"
L["THREAT_RESIST"] = "Resist"
L["THREAT_IMMUNE"] = "Immune"
L["THREAT_DODGE"]  = "Dodge"
L["THREAT_PARRY"]  = "Parry"
L["THREAT_BLOCK"]  = "Block"

-- Automation tab
L["Combat Automation"]                          = true
L["Tools"]                                      = true
L["Maintenance & Roles"]                        = true
L["Auto-set Tank Role (5-man groups)"]          = true
L["Auto-set Tank Role (Raids)"]                 = true
L["Auto-Repair at Merchant"]                    = true
L["Show Defense Cap button on Character Sheet"] = true
L["Open Defense Cap Chart"]                     = true
L["Chart Frame Color"]                          = true
L["Chart Font Size"]                            = true
L["Chart Scale"]                                = true
L["Reset All Settings"]                         = true
L["Caution: This wipes all settings!"]          = true

-- Automation radio labels (MakeRemovalRadioRow)
L["Auto-remove"] = true
L["Show icon"]   = true
L["Off"]         = true

L["Removal UI Scale"]                           = true
L["Unlock Removal Buttons (drag to move)"]      = true

-- Automation tab note (colour codes kept intentionally — translators may leave as-is)
L["AUTOMATION_NOTE"] =
    "• |cff00ff00Auto-remove|r: Removes buff |cffaaaaaaout of combat|r, shows icon |cffaaaaaawhile in combat|r.\n\n" ..
    "• |cff00ccffShow Icon|r: Only shows reminder icon (never removes).\n\n" ..
    "• |cffff5555Off|r: Disables both auto-removal and icon."

-- Automation spell names (used as radio row labels)
L["Blessing of Salvation"]  = true
L["Blessing of Protection"] = true

-- Consumables tab
L["Consumable Bar"]          = true
L["Show Consumable Bar"]     = true
L["Shift+drag the bar to move.   |cff999999Color Legend:|r "] = true
L["Druid-Safe (instant)  "]  = true
L["Drops Form (cast time)"]  = true
L["CONS_TIMING_NOTE"] =
    "|cffffd100Note:|r Rare server-timing issues (CC landing during a shift) may occasionally leave you in caster form."

-- ── Runtime / Chat Messages ───────────────────────────────────────────────────

-- Auto-repair (TankBuffReminder.lua)
-- %s%s%s = gold/silver/copper strings assembled by the caller
L["Auto-repair: %s%s%s"] = true

-- Taunt fail (Taunt.lua)
L["TAUNT FAILED: "] = true

-- Defense chart (Options.lua / DefenseCap.lua)
L["[TBR] Defense Chart module not found."] = true
L["Defense Cap Reference"]                 = true
L["Click to view crit-immunity chart."]    = true
L["Shift+drag to move."]                   = true

-- Defense chart boss level dropdown
L["Target Boss Level:"]              = true
L["Level 70 (Heroic — Easy)"]        = true
L["Level 71 (Heroic — Mid)"]         = true
L["Level 72 (Heroic — Hard)"]        = true
L["Level 73 (Raid Boss — Default)"]  = true

-- Defense chart column headers (DefenseCap.lua)
L["Defense Skill"]  = true
L["Rating Needed"]  = true
L["Resil Needed"]   = true

-- Defense chart class labels
L["Druid |cff999999(Survival of the Fittest)|r"] = true
L["Warrior"]                                       = true
L["Paladin"]                                       = true

-- Stats panel
L["Tank Stats"]                    = true
L["Click to toggle stats panel."]  = true
L["Avoidance"]                     = true
L["Dodge"]                         = true
L["Parry"]                         = true
L["Block"]                         = true
L["Miss"]                          = true
L["Total Avoid"]                   = true
L["Defense"]                       = true
L["Def Skill"]                     = true
L["Def Rating"]                    = true
L["Crit Immune"]                   = true
L["Yes"]                           = true
L["Offense"]                       = true
L["Hit"]                           = true
L["Expertise"]                     = true
L["Survivability"]                 = true
L["Health"]                        = true
L["Armor"]                         = true
L["Dmg Reduction"]                 = true
L["Resilience"]                    = true
L["EHP"]                           = true

-- Hotkey dialog (ConsumableBar.lua)
L["Cannot set hotkeys in combat."]   = true
L["Set Hotkey"]                      = true
L["HOTKEY_PROMPT"] =
    "Press any key combination…\n|cff888888Esc to cancel  •  Backspace clears|r"
L["HOTKEY_CONFLICT_ADDON"] =
    "|cffff6060Already bound to:\n%s|r\nPress again to override, Esc to cancel."
L["HOTKEY_CONFLICT_WOW"] =
    "|cffff8800Already used by:\n|cffffffff%s|r\n|cffff8800Press again to use anyway, Esc to cancel.|r"
L["Cancel"] = true

-- Consumable bar tooltips (ConsumableBar.lua)
L["Total in Bags:"]                                                           = true
L["Hotkey:"]                                                                  = true
L["|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind"]     = true
L["|cff888888Ctrl+Click|r to set a hotkey"]                                   = true
L["|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use."]             = true
L["|cffff8800Warning:|r drops Bear Form."]                                    = true

-- ── Buff Names (Options Buffs tab) ───────────────────────────────────────────
-- These match the .name field in Config.lua and are used as checkbox labels.
L["Righteous Fury"]   = true
L["Devotion Aura"]    = true
L["Battle Shout"]     = true
L["Commanding Shout"] = true
L["Defensive Stance"] = true
L["Thorns"]           = true
L["Mark of the Wild"] = true
L["Omen of Clarity"]  = true

-- ── Consumable Category Names (Options tab headers) ───────────────────────────
L["Recovery"]          = true
L["Potions"]           = true
L["Flasks"]            = true
L["Guardian Elixirs"]  = true
L["Battle Elixirs"]    = true
L["Scrolls"]           = true
L["Weapon"]            = true
L["Engineering"]       = true
L["Utility"]           = true
L["Food"]              = true

-- ── Consumable Item Labels (Options checkboxes + bar tooltips) ────────────────
L["Healthstone"]              = true
L["Bandage"]                  = true
L["Nightmare Seed"]           = true
L["Healing Potion"]           = true
L["Mana Potion"]              = true
L["Ironshield Potion"]        = true
L["Haste Potion"]             = true
L["Destruction Potion"]       = true
L["Mighty Rage Potion"]       = true
L["Free Action Potion"]       = true
L["Super Rejuvenation"]       = true
L["Auchenai Mana Potion"]     = true
L["Bottled Nethergon Vapor"]  = true
L["Bottled Nethergon Energy"] = true
L["Major Frost Protection"]   = true
L["Major Nature Protection"]  = true
L["Major Fire Protection"]    = true
L["Major Shadow Protection"]  = true
L["Major Arcane Protection"]  = true
L["Flask of Fortification"]      = true
L["Flask of Relentless Assault"] = true
L["Flask of Chromatic Wonder"]   = true
L["Flask of Blinding Light"]     = true
L["Elixir of Major Mageblood"]  = true
L["Elixir of Major Defense"]    = true
L["Elixir of Major Fortitude"]  = true
L["Gift of Arthas"]             = true
L["Elixir of Major Agility"]   = true
L["Elixir of Major Strength"]  = true
L["Greater Arcane Elixir"]     = true
L["Elixir of Demonslaying"]    = true
L["Scroll of Agility V"]       = true
L["Scroll of Strength V"]      = true
L["Scroll of Protection V"]    = true
L["Scroll of Stamina V"]       = true
L["Adamantite Weightstone"]    = true
L["Adamantite Sharpening"]     = true
L["Superior Wizard Oil"]       = true
L["Superior Mana Oil"]         = true
L["Super Sapper Charge"]       = true
L["Goblin Sapper Charge"]      = true
L["Adamantite Grenade"]        = true
L["Greater Rune of Warding"]   = true
L["Savory Deviate Delight"]    = true
L["Noggenfogger Elixir"]       = true
L["Fisherman's Feast"]         = true
L["Spicy Crawdad"]             = true
L["Blackened Basilisk"]        = true
L["Warp Burger"]               = true
L["Elderberry Pie"]            = true
L["Fire-toasted Bun"]          = true
L["Mince Meat Fruitcake"]      = true
L["Spicy Hot Talbuk"]          = true
L["Ravager Dog"]               = true
L["Kibler's Bits"]             = true
L["Grilled Mudfish"]           = true
L["Roasted Clefthoof"]         = true
L["Feltail Delight"]           = true

-- ── Consumable Item Labels (newer additions) ──────────────────────────────────
L["Charged Crystal Focus"]        = true
L["Crystal Healing Potion"]       = true
L["Crystal Mana Potion"]          = true
L["Red Ogre Brew Special"]        = true
L["Blue Ogre Brew Special"]       = true
L["Unstable Flask of the Bandit"] = true
L["Unstable Flask of the Soldier"] = true
L["Unstable Flask of the Beast"]  = true
L["Healing Potion Injector"]      = true
L["Mana Potion Injector"]         = true

-- CC type labels (ThreatAlert display)
L["Stun"]   = "Stunned"
L["Fear"]   = "Feared"
L["Sleep"]  = "Slept"
L["Incap"]  = "Incapacitated"
L["MC"]     = "Mind Controlled"
L["Poly"]   = "Polymorphed"
L["Blind"]  = "Blinded"
L["Banish"] = "Banished"

-- DefenseCap stats panel — TPS section
L["Attack Power"]  = true
L["Crit Chance"]   = true
L["TPS Estimate"]  = true
L["Est. TPS"]      = true

-- ── Append to Locales/enUS.lua ──────────────────────────────────────────────
-- External Buffs — Buffs tab
L["External Buffs"]                    = true
L["Only show when in a raid or party"] = true
L["Source"]                            = true
-- Buff names
L["Prayer of Fortitude"]         = true
L["Prayer of Shadow Protection"] = true
L["Divine Spirit"]               = true
L["Fear Ward"]                   = true
L["Arcane Brilliance"]           = true
L["Blessing of Kings"]           = true
L["Blessing of Might"]           = true
L["Blessing of Wisdom"]          = true
L["Blessing of Sanctuary"]       = true
L["Blessing of Light"]           = true
-- Appearance tab
L["External Buff Bar Appearance"] = true
-- Alerts tab
L["External Buff Alerts"]                        = true
L["Play sound when an external buff is missing"] = true
L["Announce Channel (click icon):"]              = true
L["Say"]                                         = true
L["Party"]                                       = true
L["Raid"]                                        = true
L["Yell"]                                        = true
L["EXT_ANNOUNCE_NOTE"] = "Click any icon on the external\nbuff bar to announce missing buffs."
-- Chat output
L["EXT_BUFF_REQUEST_PREFIX"]         = "Buffs needed: "
L["Click to announce missing buffs"] = true

-- ── External Buff Bar unlock ───────────────────────────────────────────────────
L["Unlock External Buff Bar (drag to move)"] = true