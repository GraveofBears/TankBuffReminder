# Tank Buff Reminder

**Tank Buff Reminder** is a lightweight, combat-safe World of Warcraft addon designed to ensure you never start a pull without your essential class buffs. It displays a draggable, resizable icon when important buffs are missing, acting as a secure button to cast the missing spell with a single click.

## Core Features
* **Intelligent Tracking**: Automatically detects your class and monitors essential buffs like Righteous Fury, Thorns, or specific Stance requirements.
* **Secure Casting**: The reminder icon functions as a secure action button, allowing you to cast the missing buff directly from the UI.
* **Automation Suite**:
    * **Auto-Set Tank Role**: Automatically sets your role to "Tank" when joining a Party or LFG group.
    * **Auto-Remove Salvation**: Detects and cancels "Blessing of Salvation" or "Greater Blessing of Salvation" while tanking to ensure you don't lose threat.
* **Combat Safe**: Handles combat lockdowns gracefully, updating attributes once you leave combat to ensure no "Action Blocked" errors.
* **Visual Customization**:
    * **Pulse Speed**: Adjust the icon's pulse from a slow glow to a fast flash.
    * **Glow Color Picker**: Fully customize the glow color using an in-game color swatch to match your UI or class aesthetic.
    * **Glow Scaling**: Adjust the size of the outer glow relative to the icon.
* **Sound Selection**: Choose your preferred alert sound from a dropdown menu.
* **Toggle Individual Buffs**: Disable tracking for specific spells you don't wish to maintain via the options menu.
* **Scaling & Positioning**: Use the grabber to scale the UI (**0.5x to 3.0x**) and **Shift + Drag** to move the icon anywhere.
* **Quick Reset**: A dedicated "Reset" button in the options to instantly restore default position, size, and colors.

## Supported Classes & Spells
* **Paladin**: Righteous Fury, Devotion Aura.
* **Druid**: Thorns, Mark of the Wild (includes Gift of the Wild detection), Omen of Clarity.
* **Warrior**: Battle Shout, Commanding Shout, Defensive Stance.

## Installation
1. Download the repository.
2. Extract the `TankBuffReminder` folder into your `World of Warcraft/_classic_/Interface/AddOns/` directory.
3. Restart WoW or reload your UI (`/reload`).

## Commands
* `/tbr` — Opens the configuration and options panel.

---
**Author**: Gravebear
