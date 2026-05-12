-- Locales/frFR.lua  (Français)
local locale = GetLocale()
if locale ~= "frFR" then return end

local L = TBR_L

L["Tank Buff Reminder"]                = "Rappel de Buffs du Tank"
L["Select a tab below to configure."] = "Sélectionnez un onglet ci-dessous."

L["Buffs"]       = "Buffs"
L["Appearance"]  = "Apparence"
L["Alerts"]      = "Alertes"
L["Automation"]  = "Automatisation"
L["Consumables"] = "Consommables"

L["Only your class section is active.  * sets cast priority (top = first shown)."] =
    "Seule votre section de classe est active.  * définit la priorité de lancement (haut = affiché en premier)."

L["Main Bar Appearance"]   = "Apparence de la barre principale"
L["Glow Size"]             = "Taille de l'éclat"
L["Pulse Speed"]           = "Vitesse de pulsation"
L["Frame Alpha"]           = "Alpha du cadre"
L["Icon Alpha"]            = "Alpha de l'icône"
L["Button Spacing"]        = "Espacement des boutons"
L["Glow Color"]            = "Couleur de l'éclat"
L["Bar Scale"]             = "Échelle de la barre"
L["Buff Sweep Alpha"]      = "Alpha du balayage de buff"
L["Timer Text Alpha"]      = "Alpha du texte du minuteur"
L["Text Vertical Offset"]  = "Décalage vertical du texte"
L["Font Size"]             = "Taille de police"
L["Duration Text Color"]   = "Couleur du texte de durée"

L["Consumable Bar Appearance"] = "Apparence de la barre de consommables"
L["Frame & Border Alpha"]      = "Alpha du cadre et de la bordure"
L["Icon Alpha (Active)"]       = "Alpha de l'icône (Actif)"
L["Glow Alpha"]                = "Alpha de l'éclat"
L["Sweep Alpha"]               = "Alpha du balayage"
L["Cons Glow Color"]           = "Couleur d'éclat (consommables)"
L["Timer Font Size"]           = "Taille de police du minuteur"
L["Timer Y Offset"]            = "Décalage Y du minuteur"
L["Timer Alpha"]               = "Alpha du minuteur"
L["Text Color"]                = "Couleur du texte"
L["Hide until Mouseover"]      = "Masquer jusqu'au survol"

L["Buff Alert Sound"]                        = "Son d'alerte de buff"
L["Play sound when a buff is missing"]       = "Jouer un son quand un buff est manquant"
L["Missing Buff Sound:"]                     = "Son de buff manquant :"
L["Removal Alerts"]                          = "Alertes de suppression"
L["Enable removal alert sound (Salv/BoP)"]   = "Activer le son d'alerte de suppression (Salv/BoP)"
L["Removal Alert Sound:"]                    = "Son d'alerte de suppression :"
L["Taunt Alert System"]                      = "Système d'alerte de provocation"
L["Enable Taunt Failure Detection"]          = "Activer la détection d'échec de provocation"
L["Self Warning (chat message)"]             = "Avertissement personnel (message de chat)"
L["Announce in /Say"]                        = "Annoncer en /Say"
L["Announce in /Party"]                      = "Annoncer en /Party"
L["Announce in /Raid"]                       = "Annoncer en /Raid"
L["Play sound on taunt failure"]             = "Jouer un son lors d'un échec de provocation"
L["Taunt Failure Sound:"]                    = "Son d'échec de provocation :"
L["Unknown Alert"]                           = "Alerte inconnue"

L["Combat Automation"]                          = "Automatisation au combat"
L["Tools"]                                      = "Outils"
L["Auto-set Tank Role (5-man groups)"]          = "Définir automatiquement le rôle de tank (groupes de 5)"
L["Auto-Repair at Merchant"]                    = "Réparation automatique chez le marchand"
L["Show Defense Cap button on Character Sheet"] = "Afficher le bouton plafond de défense"
L["Open Defense Cap Chart"]                     = "Ouvrir le tableau du plafond de défense"
L["Chart Frame Color"]                          = "Couleur du cadre du tableau"
L["Reset All Settings"]                         = "Réinitialiser tous les paramètres"
L["Caution: This wipes all settings!"]          = "Attention : Ceci efface tous les paramètres !"

L["Auto-remove"] = "Suppression auto"
L["Show icon"]   = "Afficher l'icône"
L["Off"]         = "Désactivé"

L["AUTOMATION_NOTE"] =
    "• |cff00ff00Suppression auto|r : Supprime le buff |cffaaaaaaaen dehors du combat|r, affiche l'icône |cffaaaaaaen combat|r.\n\n" ..
    "• |cff00ccffAfficher l'icône|r : Affiche uniquement l'icône de rappel (ne supprime jamais).\n\n" ..
    "• |cffff5555Désactivé|r : Désactive la suppression auto et l'icône."

L["Blessing of Salvation"]  = "Bénédiction de Salut"
L["Blessing of Protection"] = "Bénédiction de Protection"

L["Consumable Bar"]          = "Barre de consommables"
L["Show Consumable Bar"]     = "Afficher la barre de consommables"
L["Shift+drag the bar to move.   |cff999999Color Legend:|r "] =
    "Maj+Glisser pour déplacer.   |cff999999Légende des couleurs :|r "
L["Druid-Safe (instant)  "]  = "Sûr pour Druide (instant)  "
L["Drops Form (cast time)"]  = "Quitte la forme (temps d'incantation)"
L["CONS_TIMING_NOTE"] =
    "|cffffd100Remarque :|r De rares problèmes de synchronisation serveur peuvent occasionnellement vous laisser en forme de lanceur de sorts."

L["Auto-repair: %s%s%s"]                   = "Réparation auto : %s%s%s"
L["TAUNT FAILED: "]                         = "PROVOCATION ÉCHOUÉE : "
L["[TBR] Defense Chart module not found."] = "[TBR] Module du tableau de défense introuvable."
L["Defense Cap Reference"]                  = "Référence du plafond de défense"
L["Click to view crit-immunity chart."]     = "Cliquez pour voir le tableau d'immunité critique."
L["Shift+drag to move."]                    = "Maj+Glisser pour déplacer."

L["Defense Skill"]  = "Compétence de défense"
L["Rating Needed"]  = "Cote nécessaire"
L["Resil Needed"]   = "Résil. nécessaire"

L["Druid |cff999999(Survival of the Fittest)|r"] = "Druide |cff999999(Survie du plus apte)|r"
L["Warrior"]                                       = "Guerrier"
L["Paladin"]                                       = "Paladin"

L["Cannot set hotkeys in combat."]  = "Impossible de définir des raccourcis en combat."
L["Set Hotkey"]                     = "Définir raccourci"
L["HOTKEY_PROMPT"] =
    "Appuyez sur une combinaison de touches…\n|cff888888Échap pour annuler  •  Retour arrière pour effacer|r"
L["HOTKEY_CONFLICT_ADDON"] =
    "|cffff6060Déjà attribué à :\n%s|r\nAppuyez à nouveau pour remplacer, Échap pour annuler."
L["HOTKEY_CONFLICT_WOW"] =
    "|cffff8800Déjà utilisé par :\n|cffffffff%s|r\n|cffff8800Appuyez à nouveau pour confirmer, Échap pour annuler.|r"
L["Cancel"] = "Annuler"

L["Total in Bags:"]                                                           = "Total dans les sacs :"
L["Hotkey:"]                                                                  = "Raccourci :"
L["|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind"]     =
    "|cff888888Retour arrière|r pour effacer  •  |cff888888Ctrl+Clic|r pour réassigner"
L["|cff888888Ctrl+Click|r to set a hotkey"]                                   =
    "|cff888888Ctrl+Clic|r pour définir un raccourci"
L["|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use."]             =
    "|cff00ff00Sûr pour l'ours :|r Retourne en forme Ours ou Félin après utilisation."
L["|cffff8800Warning:|r drops Bear Form."]                                    =
    "|cffff8800Attention :|r Quitte la forme Ours."

L["Righteous Fury"]   = "Fureur Vertueuse"
L["Devotion Aura"]    = "Aura de Dévotion"
L["Battle Shout"]     = "Cri de Guerre"
L["Commanding Shout"] = "Cri de Commandement"
L["Defensive Stance"] = "Posture Défensive"
L["Thorns"]           = "Épines"
L["Mark of the Wild"] = "Marque de la Nature"
L["Omen of Clarity"]  = "Présage de Clarté"

L["Recovery"]          = "Récupération"
L["Potions"]           = "Potions"
L["Flasks"]            = "Fioles"
L["Guardian Elixirs"]  = "Élixirs de gardien"
L["Battle Elixirs"]    = "Élixirs de combat"
L["Scrolls"]           = "Parchemins"
L["Weapon"]            = "Arme"
L["Engineering"]       = "Ingénierie"
L["Utility"]           = "Utilitaire"
L["Food"]              = "Nourriture"
