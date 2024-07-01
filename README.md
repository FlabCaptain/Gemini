## Overview

**Gemini** is a training mode script for Super Gem Fighter Mini Mix, primarily for use with Fightcade/FinalBurn Neo.

To use this script:
1. Download and unzip the latest source code archive from [Releases](https://github.com/FlabCaptain/Gemini/releases/latest).
2. Open Super Gem Fighter Mini Mix in FinalBurn Neo.
3. From the menu, click *Game* → *Lua Scripting* → *New Lua Script Window*.
4. Click *Browse* and choose the 'gemini.lua' script you unzipped, then click *Run*.

This script has two primary modes: **Studio Mode** and **Dummy Mode** ('S' or 'D' in the upper-left corner of the UI).
* In Studio Mode, you can record inputs and play them back to practice against.
* In Dummy Mode, you can work with a training dummy and set basic actions for it to perform.

This script also includes a passive **Spectator Mode**.
* To utilize this, simply run the script while spectating a live match or watching a replay.
* Only toggling the background music, input history UI panes, info UI panes, and hitboxes will be available.

You can control the script with the key commands below. All keys are remappable- see [Remapping](#remapping).

## Universal Commands

**Space**

Switches between Studio Mode and Dummy Mode.
* This command is not available while recording or during playback of a recording.
* This command can also be performed with the Service input.

**Enter**

Swaps control between P1 and P2.
* This command is not available while recording or during playback of a recording.
* This command can also be performed with the P1 Coin input.

**1 / 2 / 3**

Cycles through items in the first (1), second (2), and third (3) positions.
* These commands affect whichever player you are currently controlling.

**5**

Toggles stun for both players.

**7 / 8 / 9**

Cycles through levels 1, 2, and 3 for Red (7), Yellow (8), and Blue (9) Gem Meters.
* These commands affect whichever player you are currently controlling.

**Quote**

Cycles the number of input delay frames, up to a maximum of 7.
* You can set this to the value you use in Fightcade to simulate online match delay.
* When non-zero, the number of delay frames will be visible in the upper-right corner of the UI.

**Semicolon**

Toggles the background music.

**Left Bracket**

Toggles the input history UI panes.

**Right Bracket**

Toggles the info UI panes.

**Backslash**

Toggles the hitbox display.

## Studio Mode Commands

**Home**

Starts recording in the selected slot. Press again to stop recording.
* This command is not available during playback of a recording.
* This command can also be performed with the Volume Down input.

**End**

Starts playback of the recording in the selected slot. Press again to stop playback.
* This command is not available while recording.
* This command can also be performed with the Volume Up input.

**Page Down / Page Up**

Selects the previous or next slot, respectively.
* These commands are not available while recording or during playback of a recording.

**Delete**

Clears the recording in the selected slot.
* This command is not available while recording or during playback of a recording.

## Dummy Mode Commands

**Home**

Toggles dummy button press speed between normal and turbo (as fast as possible).
* The Dummy Mode 'D' will turn orange when this has been set to turbo.

**Page Down**

Cycles through actions for the dummy's first action.
* This action is performed while the dummy has full health.
* This command can also be performed with the Volume Down input.

**Page Up**

Cycles through actions for the dummy's second action.
* This action is performed while the dummy has less than full health.
* This command can also be performed with the Volume Up input.

## Stage Select

To select the stage, hold a direction before the 'VS' screen appears:

* **Up** - Dee Jay's Bar 'Maximum'
* **Up + Right** - Toy Shop 'Dhalsim'
* **Right** - Ski Resort 'La Menkoi'
* **Down + Right** - Beach House 'Safrill'
* **Down** - Gen's Restaurant 'Daihanjyo'
* **Down + Left** - Tessa's Den
* **Left** - Moonlight Dark Castle
* **Up + Left** - Demitri's Moving Mansion

## Remapping

To remap a command's key, edit the string value of the corresponding variable near the top of the script. For example, you can change `local SWAP_KEY = 'enter'` to `local SWAP_KEY = 'Q'`. Be sure to save your changes, and then re-run the script.

* Valid key values are: backspace, tab, enter, shift, control, alt, pause, capslock, escape, space, pageup, pagedown, end, home, left, up, right, down, insert, delete, 0, 1, ... 9, A, B, ... Z, numpad0, numpad1, ... numpad9, numpad*, numpad+, numpad-, numpad., numpad/, F1, F2, ... F24, numlock, scrolllock, semicolon, plus, comma, minus, period, slash, tilde, leftbracket, backslash, rightbracket, and quote.

## Settings

To change a setting, edit the value of the corresponding variable near the top of the script. For example, you can change `local NUM_SLOTS = 8` to `local NUM_SLOTS = 20`. Be sure to save your changes, and then re-run the script.

**UI_COLOR**

The hexadecimal color value for the UI panes. This should be of the form 0xRRGGBBAA.

**UI_TRANSPARENCY**

If true, allow UI_COLOR values with transparency and draw transparent UI details.
* If you're having performance issues while running the script, try setting this to false.
* If set to false, the alpha portion of UI_COLOR will automatically increase to 0xFF (opaque).

**HITBOX_DRAW_DELAY**

The number of frames to delay the hitboxes being drawn. This should generally be set to 0, 1, or 2 to offset your runahead setting.
* Due to the game's frameskip behavior, hitboxes may still appear early or late in some cases.

**NUM_SLOTS**

The number of available recording slots. This should be a non-negative, non-zero integer.

**RANDOM_SLOT_PLAYBACK**

If true, randomly change slots at the end of each playback loop.
* This is useful for practicing against multiple options, mix-ups, etc.
* Only non-empty slots will be chosen when using this feature.

**PLAYBACK_TURNAROUND**

If true, reverse recorded left/right inputs on playback if the player switches sides with the opponent.

**LOAD_ON_START**

If true, try to load slot data from a 'data.rep' file in the same directory as the script on startup.
* NUM_SLOTS will automatically adjust to match the number of slots in the loaded data.

**SAVE_ON_EXIT**

If true, save all slot data to a 'data.rep' file in the same directory as the script on exit.
* You should click 'Stop' to explicitly stop the script before closing FinalBurn Neo.
* If a 'data.rep' file already exists in this directory, it will be overwritten!

## Credits

Created and maintained by [FlabCaptain](https://github.com/FlabCaptain), based on a script originally written by [peon2](https://github.com/peon2) and adapted for Super Gem Fighter Mini Mix by [turtle dude](https://github.com/turtlethug).

This script also contains code from the *invaluable* CPS-2 hitboxes script, originally written by Dammit.
