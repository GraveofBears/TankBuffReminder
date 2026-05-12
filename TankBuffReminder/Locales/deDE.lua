-- Locales/deDE.lua  (Deutsch)
local locale = GetLocale()
if locale ~= "deDE" then return end

local L = TBR_L

L["Tank Buff Reminder"]                = "Tank-Buff-Erinnerung"
L["Select a tab below to configure."] = "Wähle unten einen Reiter aus."

L["Buffs"]       = "Buffs"
L["Appearance"]  = "Aussehen"
L["Alerts"]      = "Alarme"
L["Automation"]  = "Automatisierung"
L["Consumables"] = "Verbrauchsgüter"

L["Only your class section is active.  * sets cast priority (top = first shown)."] =
    "Nur dein Klassenbereich ist aktiv.  * legt die Zauberpriorität fest (oben = zuerst angezeigt)."

L["Main Bar Appearance"]   = "Hauptleiste – Aussehen"
L["Glow Size"]             = "Leuchtgröße"
L["Pulse Speed"]           = "Pulsgeschwindigkeit"
L["Frame Alpha"]           = "Rahmen-Alpha"
L["Icon Alpha"]            = "Symbol-Alpha"
L["Button Spacing"]        = "Schaltflächenabstand"
L["Glow Color"]            = "Leuchtfarbe"
L["Bar Scale"]             = "Leistenskalierung"
L["Buff Sweep Alpha"]      = "Buff-Sweep-Alpha"
L["Timer Text Alpha"]      = "Timer-Text-Alpha"
L["Text Vertical Offset"]  = "Vertikaler Textversatz"
L["Font Size"]             = "Schriftgröße"
L["Duration Text Color"]   = "Dauer-Textfarbe"

L["Consumable Bar Appearance"] = "Verbrauchsleiste – Aussehen"
L["Frame & Border Alpha"]      = "Rahmen- & Rand-Alpha"
L["Icon Alpha (Active)"]       = "Symbol-Alpha (Aktiv)"
L["Glow Alpha"]                = "Leucht-Alpha"
L["Sweep Alpha"]               = "Sweep-Alpha"
L["Cons Glow Color"]           = "Verbrauch-Leuchtfarbe"
L["Timer Font Size"]           = "Timer-Schriftgröße"
L["Timer Y Offset"]            = "Timer Y-Versatz"
L["Timer Alpha"]               = "Timer-Alpha"
L["Text Color"]                = "Textfarbe"
L["Hide until Mouseover"]      = "Bis Mauszeiger verstecken"

L["Buff Alert Sound"]                        = "Buff-Alarm-Sound"
L["Play sound when a buff is missing"]       = "Sound abspielen, wenn ein Buff fehlt"
L["Missing Buff Sound:"]                     = "Fehlender Buff-Sound:"
L["Removal Alerts"]                          = "Entfernungsalarme"
L["Enable removal alert sound (Salv/BoP)"]   = "Entfernungsalarm aktivieren (Salv/BoP)"
L["Removal Alert Sound:"]                    = "Entfernungsalarm-Sound:"
L["Taunt Alert System"]                      = "Spott-Alarmsystem"
L["Enable Taunt Failure Detection"]          = "Spott-Fehlschlag-Erkennung aktivieren"
L["Self Warning (chat message)"]             = "Eigene Warnung (Chat-Nachricht)"
L["Announce in /Say"]                        = "In /Say ankündigen"
L["Announce in /Party"]                      = "In /Party ankündigen"
L["Announce in /Raid"]                       = "In /Raid ankündigen"
L["Play sound on taunt failure"]             = "Sound bei Spott-Fehlschlag abspielen"
L["Taunt Failure Sound:"]                    = "Spott-Fehlschlag-Sound:"
L["Unknown Alert"]                           = "Unbekannter Alarm"

L["Combat Automation"]                          = "Kampfautomatisierung"
L["Tools"]                                      = "Werkzeuge"
L["Auto-set Tank Role (5-man groups)"]          = "Tank-Rolle automatisch setzen (5er-Gruppen)"
L["Auto-Repair at Merchant"]                    = "Automatisch beim Händler reparieren"
L["Show Defense Cap button on Character Sheet"] = "Verteidigungsgrenze-Schaltfläche anzeigen"
L["Open Defense Cap Chart"]                     = "Verteidigungsgrenze-Tabelle öffnen"
L["Chart Frame Color"]                          = "Tabellenrahmenfarbe"
L["Reset All Settings"]                         = "Alle Einstellungen zurücksetzen"
L["Caution: This wipes all settings!"]          = "Vorsicht: Dies löscht alle Einstellungen!"

L["Auto-remove"] = "Auto-Entfernen"
L["Show icon"]   = "Symbol anzeigen"
L["Off"]         = "Aus"

L["AUTOMATION_NOTE"] =
    "• |cff00ff00Auto-Entfernen|r: Entfernt den Buff |cffaaaaaaaußerhalb des Kampfes|r, zeigt Symbol |cffaaaaaaim Kampf|r.\n\n" ..
    "• |cff00ccffSymbol anzeigen|r: Zeigt nur das Erinnerungssymbol (entfernt nie).\n\n" ..
    "• |cffff5555Aus|r: Deaktiviert Auto-Entfernen und Symbol."

L["Blessing of Salvation"]  = "Segen der Errettung"
L["Blessing of Protection"] = "Segen des Schutzes"

L["Consumable Bar"]          = "Verbrauchsleiste"
L["Show Consumable Bar"]     = "Verbrauchsleiste anzeigen"
L["Shift+drag the bar to move.   |cff999999Color Legend:|r "] =
    "Shift+Ziehen zum Verschieben.   |cff999999Farblegende:|r "
L["Druid-Safe (instant)  "]  = "Druiden-sicher (sofort)  "
L["Drops Form (cast time)"]  = "Verlässt Form (Zauberzeit)"
L["CONS_TIMING_NOTE"] =
    "|cffffd100Hinweis:|r Seltene Server-Timing-Probleme können dazu führen, dass du gelegentlich in der Caster-Form bleibst."

L["Auto-repair: %s%s%s"]                   = "Auto-Reparatur: %s%s%s"
L["TAUNT FAILED: "]                         = "SPOTT FEHLGESCHLAGEN: "
L["[TBR] Defense Chart module not found."] = "[TBR] Verteidigungsdiagramm-Modul nicht gefunden."
L["Defense Cap Reference"]                  = "Verteidigungsgrenze-Referenz"
L["Click to view crit-immunity chart."]     = "Klicken zum Anzeigen der Kritisch-Immunitäts-Tabelle."
L["Shift+drag to move."]                    = "Shift+Ziehen zum Verschieben."

L["Defense Skill"]  = "Verteidigung"
L["Rating Needed"]  = "Benötigter Wert"
L["Resil Needed"]   = "Benötigte Resilienz"

L["Druid |cff999999(Survival of the Fittest)|r"] = "Druide |cff999999(Überleben des Stärksten)|r"
L["Warrior"]                                       = "Krieger"
L["Paladin"]                                       = "Paladin"

L["Cannot set hotkeys in combat."]  = "Tastenkürzel können im Kampf nicht gesetzt werden."
L["Set Hotkey"]                     = "Tastenkürzel festlegen"
L["HOTKEY_PROMPT"] =
    "Drücke eine Tastenkombination…\n|cff888888Esc zum Abbrechen  •  Rücktaste zum Löschen|r"
L["HOTKEY_CONFLICT_ADDON"] =
    "|cffff6060Bereits belegt durch:\n%s|r\nNochmals drücken zum Überschreiben, Esc zum Abbrechen."
L["HOTKEY_CONFLICT_WOW"] =
    "|cffff8800Bereits verwendet von:\n|cffffffff%s|r\n|cffff8800Nochmals drücken zum Bestätigen, Esc zum Abbrechen.|r"
L["Cancel"] = "Abbrechen"

L["Total in Bags:"]                                                           = "Gesamt in Taschen:"
L["Hotkey:"]                                                                  = "Tastenkürzel:"
L["|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind"]     =
    "|cff888888Rücktaste|r zum Löschen  •  |cff888888Strg+Klick|r zum Neu-Belegen"
L["|cff888888Ctrl+Click|r to set a hotkey"]                                   =
    "|cff888888Strg+Klick|r zum Festlegen eines Tastenkürzels"
L["|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use."]             =
    "|cff00ff00Bärensicher:|r Betritt nach der Verwendung erneut Bären- oder Katzenform."
L["|cffff8800Warning:|r drops Bear Form."]                                    =
    "|cffff8800Warnung:|r Verlässt die Bärenform."

L["Righteous Fury"]   = "Gerechter Zorn"
L["Devotion Aura"]    = "Aura der Ergebenheit"
L["Battle Shout"]     = "Kampfschrei"
L["Commanding Shout"] = "Befehlsschrei"
L["Defensive Stance"] = "Defensive Haltung"
L["Thorns"]           = "Dornen"
L["Mark of the Wild"] = "Zeichen der Wildnis"
L["Omen of Clarity"]  = "Omen der Klarheit"

L["Recovery"]          = "Heilung"
L["Potions"]           = "Tränke"
L["Flasks"]            = "Fläschchen"
L["Guardian Elixirs"]  = "Schutz-Elixiere"
L["Battle Elixirs"]    = "Kampf-Elixiere"
L["Scrolls"]           = "Schriftrollen"
L["Weapon"]            = "Waffe"
L["Engineering"]       = "Ingenieurskunst"
L["Utility"]           = "Hilfsmittel"
L["Food"]              = "Essen"
