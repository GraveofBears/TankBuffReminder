![](https://noobtrap.eu/images/crystallights/Tonk.png) **Tank Buff Reminder** is a powerful all‑in‑one toolkit designed to help tanks maintain optimal buffs, consumables, and awareness while reducing mental load during raids and dungeons. It features a dynamic buff bar, a smart consumable bar (with druid‑safe instant‑shift macros), automated buff removal, taunt and threat alerts, a defense cap reference tool, and a full configuration UI.

Now with translation support for all 7 additional locales covering all retail WoW regions: `enUS` · `deDE` · `frFR` · `esES` · `ruRU` · `zhCN` · `zhTW` · `koKR`

***

## Core Features

### Dynamic Buff Bar

*   **Real‑time Tracking:** Instant visibility of essential tanking buffs. Missing buffs glow and pulse to grab your attention.
*   **Secure Actions:** Interactive layout allows you to click any missing buff icon to cast it instantly.
*   **Layout Freedom:** Draggable via Shift+Click, fully resizable, with customizable padding and scale.
*   **Class‑Specific Tracking:**
    *   **Druid:** Thorns, Mark/Gift of the Wild, Omen of Clarity.
    *   **Warrior:** Battle Shout, Commanding Shout, Defensive Stance.
    *   **Paladin:** Righteous Fury, Devotion Aura.

### Consumable Bar

*   **Comprehensive Catalog:** Smart tracking for Healthstones, Potions, Food, Weapon Buffs, Scrolls, Engineering items, and more.
*   **Quick Bindings:** Bind any hotkey instantly using **CTRL+Click** on an item slot; clear bindings using **Backspace**.
*   **Feral Druid Protection:** Built-in druid-safe macros automate shifting out, using the item, and re-forming immediately.
*   **CC Safeguard:** Integrated crowd control protection prevents accidental shape manipulation or cancellation while you are stunned, feared, or silenced.
*   **Visual Controls:** Configure scale, glow, pulse speed, colors, duration timers, mouseover visibility, and layout orientation. Shows accurate item counts and tracks shared potion cooldowns.

### Smart Buff Removal

Helps to quickly purge unwanted buffs (like Blessing of Salvation or Blessing of Protection) that can be accidentally cast on a tank, endangering aggro or boss positioning.

*   **Auto‑Remove:** Automatically cancels specified unwanted buffs the moment you are **out of combat**.
*   **In‑Combat Fallback:** Displays a pulsing red warning icon that can be manually clicked to cancel the buff mid-encounter.
*   **Show Icon Only:** Disables automatic removal entirely, functioning strictly as a clickable reminder icon.
*   **Off:** Disables the buff removal system entirely.
*   **UI Controls:** Fully movable, scalable, and spacing-adjustable via the options configuration panel.

### Automation & Quality of Life

*   **Role Enforcement:** Automatically checks and sets your dungeon/raid group role to Tank.
*   **Auto-Repair:** Automatically handles vendor repairs at merchants and prints a clear cost summary to your chat frame.
*   **Taunt Failure Detection:** Instantly monitors taunt misses, resists, or immunities with smart batching mechanics to prevent log spam.
*   **Custom Alerts:** Supports multiple announcement channels and includes a full sound picker for auditory warnings.
*   **PvP-Safe Integration:** Automatically silences alerts and updates while inside Battlegrounds or Arenas.

### Threat Alert System

Detects early-pull threat issues before they wipe your group, providing instant notification the moment an opening sequence goes wrong.

*   **Spell Miss & Resist Tracking:** Alerts you immediately when opening threat abilities fail to land on your target.
*   **CC Detection Engine:** Tracks Stuns, Fears, Roots, Silences, Disarms, and Snares landing on you at the start of a pull. Powered by a comprehensive spell list synced with LoseControl TBC, covering every class, pet, racial, item, dungeon, and raid CC in the game.
*   **Alert Window:** Configurable time window (5–25 seconds) after establishing a pull during which miss/resist alerts will fire. CC alerts can optionally be toggled to persist for the entire duration of combat.
*   **Announce Channels:** Supports localized warnings (chat print), `/say`, `/yell`, `/party`, and `/raid`.
*   **Smart Tank Verification:** Only triggers when you are actively assigned the Tank role (Druids are additionally verified to be in Bear or Dire Bear Form).
*   **Configuration:** Easily managed via the **Alerts** tab inside `/tbr`.

### Defense Cap & Tank Stats Reference Tool

An all-in-one diagnostic panel for classic tanks (Warriors, Druids, and Paladins) that tracks critical mitigation caps, combat ratings, and dynamic threat performance.

#### Panel Features

*   **Paperdoll Integration:** Adds a quick-access, movable shield icon directly to your Character Paperdoll screen providing instant status indicators (✓/✗) for critical immunity.
*   **Dynamic Target Benchmarking:** Switch seamlessly between target level presets (**70–73/Raid Boss**) to instantly recalculate your required baseline defenses.
*   **Mitigation Tracking:** Live readout of your Defense Skill, Resilience Rating, Avoidance breakdowns, Armor Damage Reduction, and true **Effective Health Pools (EHP)**.
*   **Predictive Threat Profiling:** A specialized **TPS (Threat Per Second)** modeling engine that evaluates tank performance in real-time based on active equipment, spec talents, and consumables.
*   **UI Personalization:** Integrates with the addon's master options panel, featuring modular font scaling, alpha sliding, and a custom Color Theme Picker.

> **Important Note on TPS Estimates:** The Threat Per Second (TPS) readout is a predictive baseline estimate derived strictly from your current gear, stats, and passive modifiers. It is **not** a live combat simulator, it does not actively log your real-time actions, and it does not calculate individual spell casts or specific ability rotations. It is intended solely as a benchmarking tool to show how your gear upgrades, consumables, and stat changes scale your baseline threat potential.

#### Mechanics & Predictive Threat Modeling (The Math)

The tool tracks your character sheet statistics (`UnitAttackPower`, `GetCritChance`, and `GetCombatRatingBonus`) and evaluates them through custom class algorithms to project your baseline threat generation:

**Druid (Bear Stance Simulation):** The script isolates your core Feral tanking metrics to benchmark authentic mitigation threat, intentionally bypassing out-of-form stat inflation. It simulates a 2.5s base weapon swing speed matched with a 1.9x Dire Bear physical damage modifier. It then multiplies your projected damage output by **1.495x** to account for the multiplicative stacking of standard Bear Stance threat (1.3x) and a fully-talented 3/3 _Feral Instinct_ spec (1.15x). An active rotational modifier of 1.3x is applied to factor in high-threat ability use (Maul and Mangle execution priority).

```
**Estimated Druid TPS** = (Total AP / 14 \* 2.5) \* 1.9 \* 1.3 \* Hit Factor \* 1.495 \* Crit Bonus
```

**Warrior (Rotational Simulation):** Calculates threat generation assuming a standard, fast-mitigation tanking weapon speed profile (1.6s). It takes your raw attack power weapon DPS framework and runs it through a compounded **2.4x rotational multiplier**. This multiplier bundles the passive threat coefficient of Defensive Stance (1.10x), 5/5 _Defiance_ (1.15x), your melee hit rate factor, and the hardcoded flat bonus threat values generated by a high-priority _Shield Slam_ and _Revenge_ rotation.

```
**Estimated Warrior TPS** = (Total AP / 14 \* 1.6) \* 2.4 \* Hit Factor \* Crit Bonus
```

**Paladin (Holy Spell-Power Engine):** Driven primarily by holy spell modifiers and blocking mechanics rather than physical attack power calculations. It scans your active character data for **Holy Spell Power** (`GetSpellBonusDamage(2)`) and your sheet **Shield Block Value** (`GetShieldBlockValue`). It projects the baseline DPS ticks of _Consecration_, factors in _Holy Shield_ reactive spikes scaled by your block value, and multiplies total Holy damage by **1.9x** to account for a talented 3/3 _Righteous Fury_ stance. A minor physical baseline component scaled by melee hit metrics is added to complete the calculation.

```
**Estimated Paladin TPS** = ((Base Holy DPS + Holy Shield DPS) \* 1.9) + (Physical DPS \* Hit Factor)
```

***

## Customization

Access the comprehensive master configuration layout via `/tbr`. Settings are saved per-character and update your user interface instantly upon modification across 5 tabs:

*   **Buffs:** Toggle specific tracked buffs and customize the priority casting layout for your class.
*   **Appearance:** Complete aesthetic control over the buff and consumable bars, including glow effects, scale, pulse frequencies, durations, colors, and alpha opacity sliders.
*   **Alerts:** Manage audio indicators for buff expirations, successful purges, taunt failures, and early-pull Threat Alert criteria.
*   **Automation:** Toggle group role auto-assignment, vendor repairs, conditional buff removal scripts, and customize the placement of the removal frame.
*   **Consumables:** Enable or disable tracking for specific inventory consumables, adjust bar orientation, toggle mouseover hiding, and suppress empty slots.

***

## Commands

*   `/tbr` — Open the main Options Configuration Panel.
*   `/tbrcap` — Toggle the Defense Cap and Tank Stats Reference window.

***

## Installation

1.  Download the latest release version.
2.  Extract the `TankBuffReminder` folder into your World of Warcraft directory:  
    `World of Warcraft/_classic_/Interface/AddOns/`
3.  Launch the game, or type `/reload` if you are already logged in.

***

## Author

**Gravebear**

### Special Thanks

Heartfelt appreciation to the tanks who dedicated their time to test, refine, and provide feedback:

*   Anthal
*   Bambàm
*   BearStance
*   Bison
*   Krek
