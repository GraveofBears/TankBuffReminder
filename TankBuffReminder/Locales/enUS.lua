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
L["Announce in /Party"]                      = true
L["Announce in /Raid"]                       = true
L["Play sound on taunt failure"]             = true
L["Taunt Failure Sound:"]                    = true
L["Unknown Alert"]                           = true

-- Automation tab
L["Combat Automation"]                          = true
L["Tools"]                                      = true
L["Auto-set Tank Role (5-man groups)"]          = true
L["Auto-Repair at Merchant"]                    = true
L["Show Defense Cap button on Character Sheet"] = true
L["Open Defense Cap Chart"]                     = true
L["Chart Frame Color"]                          = true
L["Reset All Settings"]                         = true
L["Caution: This wipes all settings!"]          = true

-- Automation radio labels (MakeRemovalRadioRow)
L["Auto-remove"] = true
L["Show icon"]   = true
L["Off"]         = true

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

-- Defense chart column headers (DefenseCap.lua)
L["Defense Skill"]  = true
L["Rating Needed"]  = true
L["Resil Needed"]   = true

-- Defense chart class labels
L["Druid |cff999999(Survival of the Fittest)|r"] = true
L["Warrior"]                                       = true
L["Paladin"]                                       = true

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
