# Tank Buff Reminder

**Tank Buff Reminder** World of Warcraft addon designed to ensure you never start a pull without your essential class buffs or get alerts for missed/immune taunts. It displays a draggable, resizable icon when important buffs are missing, acting as a secure button to cast the missing spell with a single click.

## Core Features
* **Intelligent Tracking**: Automatically detects your class and monitors essential buffs like Righteous Fury, Thorns, or specific Stance requirements.
* **Taunt Alert System**: Monitors the combat log for failed taunts (Resist, Immune, or Miss). 
    * **AOE Batching**: Condenses multi-target resists (like Challenging Shout or Righteous Defense) into a single, clean notification.
    * **Flexible Announcing**: Toggle failure alerts for yourself, or announce them to /Say, /Party, or /Raid.
* **Secure Casting**: The reminder icon functions as a secure action button, allowing you to cast the missing buff directly from the UI.
* **Automation Suite**:
    * **Auto-Set Tank Role**: Automatically sets your role to "Tank" when joining a group (with built-in throttle logic to prevent duplicate chat messages).
    * **Auto-Remove Salvation**: Automatically cancels "Blessing of Salvation" or "Greater Blessing of Salvation" to maximize threat generation.
    * **Auto-Repair**: Automatically repairs your equipment when interacting with a repair-capable merchant.
* **Visual & Audio Customization**:
    * **Pulse Speed**: Adjust the icon's pulse from a slow glow to a fast flash.
    * **Glow Color Picker**: Fully customize the glow color using an in-game color swatch.
    * **Sound Selection**: Choose your preferred alert sound for both buff reminders and taunt failures from a dropdown menu.
* **Scaling & Positioning**: Use the grabber to scale the UI (**0.5x to 3.0x**) and **Shift + Drag** to move the icon anywhere.

## Supported Classes & Spells
* **Paladin**: Righteous Fury, Devotion Aura, Righteous Defense.
* **Druid**: Thorns, Mark of the Wild (includes Gift of the Wild detection), Omen of Clarity, Growl, Challenging Roar.
* **Warrior**: Battle Shout, Commanding Shout, Defensive Stance, Taunt, Challenging Shout.

## Installation
1. Download the repository.
2. Extract the `TankBuffReminder` folder into your `World of Warcraft/_classic_/Interface/AddOns/` directory.
3. Restart WoW or reload your UI (`/reload`).

## Commands
* `/tbr` — Opens the configuration and options panel.

---
**Author**: Gravebear
**Version**: 1.0.0
