# Lua Autocomplete Plugin for Roblox Studio

Production-ready autocomplete plugin with context-aware snippet insertion using ScriptEditorService.

## Features

- ✨ 24 built-in snippets for common Roblox patterns
- 🧠 Context-aware suggestion ranking
- ⚡ Fast performance (< 10ms autocomplete response)
- 📝 Custom snippet creation and management
- 🔄 Tab-stop navigation ($1, $2, $0)
- 👁️ Preview tooltips and inline ghost text
- 💾 Usage frequency tracking
- 🎯 Fallback mode for non-beta Studio versions

## Installation

### Via File System

1. Download or clone this repository
2. Copy the `Lua-Coding-API` folder to:
   - **Windows:** `%LOCALAPPDATA%\Roblox\Plugins\`
   - **Mac:** `~/Documents/Roblox/Plugins/`
3. Restart Roblox Studio
4. Look for "🔧 Lua Autocomplete" button in toolbar

### Via Studio

1. Open Plugin Management (Plugins → Manage Plugins)
2. Click "+" to install from folder
3. Navigate to downloaded folder
4. Click Install

## Setup

### Enabling Script Editor API (Required for Full Features)

The plugin works best with Roblox Studio's Script Editor Beta features:

1. Go to **File → Studio Settings**
2. Navigate to **Studio** tab
3. Scroll to **Script Editor** section
4. Enable **Script Editor Beta Features**
5. Restart Studio

**Without Beta features:** Plugin will use fallback mode (limited functionality, snippets insert at end of script).

## Usage

### Basic Usage

1. Click "🔧 Lua Autocomplete" toolbar button to open widget
2. In a script, start typing to trigger autocomplete
3. Select snippet from suggestions (Up/Down arrows)
4. Press Tab or Enter to insert
5. Navigate placeholders with Tab key
6. Press Escape to exit tab-stop mode

### Snippet List

#### Essential (6)

- `service` - game:GetService() pattern
- `function` - Function skeleton
- `module` - ModuleScript template
- `remote` - RemoteEvent handler
- `wait` - task.wait() loop
- `ifelse` - if/else statement

#### Common (8)

- `for` - Numeric for loop
- `forin` - pairs() iterator
- `while` - While loop
- `spawn` - Character spawn handler
- `tween` - TweenService pattern
- `signal` - BindableEvent pattern
- `part` - Create Part instance
- `pcall` - Protected call with error handling

#### Advanced (10)

- `class` - OOP class pattern
- `enum` - Enum-style table
- `maid` - Cleanup pattern
- `promise` - Async promise pattern
- `datastore` - DataStore with error handling
- `profileservice` - ProfileService pattern
- `raycast` - Workspace raycast
- `input` - UserInputService
- `context` - ContextActionService
- `coroutine` - Coroutine wrapper

### Snippet Examples

#### Service Pattern
Type: `service`

```lua
local $1 = game:GetService("$2")
```

After insertion:
1. Cursor at `$1` - type service variable name (e.g., `Players`)
2. Press Tab → cursor moves to `$2` - type service name (e.g., `Players`)
3. Press Tab → exit tab-stop mode

Result:
```lua
local Players = game:GetService("Players")
```

#### Module Template
Type: `module`

```lua
local $1 = {}

function $1:$2($3)
	$0
end

return $1
```

Creates a complete ModuleScript structure with method placeholder.

#### For Loop
Type: `for`

```lua
for i = $1, $2 do
	$0
end
```

Quick numeric loop with start/end placeholders.

### Custom Snippets

1. Click **+ Add** button in widget
2. Fill in form:
   - **Name:** Trigger word (e.g., "mysnippet")
   - **Description:** Brief description
   - **Template:** Code with placeholders ($1, $2, $0)
3. Click **Add**

**Placeholder syntax:**
- `$1`, `$2`, `$3` - Tab stops in order
- `$0` - Final cursor position
- Example: `local $1 = Instance.new("$2")`

**Example custom snippet:**
- **Name:** `print`
- **Description:** Debug print statement
- **Template:** `print("$1:", $1)`

### Settings

Click **⚙ Settings** to configure:

- **Suggestion Style:** Inline / Popup
- **Trigger Key:** Tab / Enter / Both
- **Show Preview:** Enable/disable preview tooltips
- **Preview Style:** Tooltip / Ghost text / Both
- **Reset Usage Stats:** Clear frequency tracking

Settings are saved per-place and persist across Studio restarts.

## Keyboard Shortcuts

### In autocomplete list

- `Up/Down` - Navigate suggestions
- `Tab/Enter` - Accept suggestion
- `Escape` - Close suggestions

### In tab-stop mode

- `Tab` - Next placeholder
- `Shift+Tab` - Previous placeholder
- `Escape` - Exit tab-stop mode

## Troubleshooting

### "Script Editor API unavailable" warning

**Cause:** Script Editor Beta features not enabled

**Solution:**
1. File → Studio Settings
2. Studio tab → Script Editor section
3. Enable "Script Editor Beta Features"
4. Restart Studio

### Autocomplete not triggering

**Check:**
- Plugin enabled (toggle in widget header)
- Typing in a script (not in Command Bar)
- Not inside string literal or comment
- Script Editor Beta features enabled

### Snippet inserts at end of script

**Cause:** Fallback mode active (Script Editor API not available)

**Solution:** Enable Script Editor Beta features (see above)

### Performance issues

**If autocomplete is slow:**
- Check snippet count (< 100 recommended)
- Disable preview tooltips in settings
- Clear usage statistics (Settings → Reset Usage Stats)

## Context-Aware Ranking

The plugin intelligently ranks snippets based on your current code context:

### Empty Script
- Prioritizes: `module` template
- Secondary: `service`, `function`

### After `game:`
- Prioritizes: `service` snippet
- Suggests service-related completions

### After `local `
- Prioritizes: Variable-creating snippets
- Suggests: `service`, `function`, `part`

### After `:Connect(`
- Prioritizes: `function` snippet
- Suggests callback patterns

### After `for `
- Prioritizes: Loop snippets
- Suggests: `for`, `forin`, `while`

### Usage Frequency
- Tracks how often you use each snippet
- Boosts frequently-used snippets in rankings
- Can be reset via Settings

## Architecture

### Plugin Components

**Core Modules:**
- `SnippetLibrary.lua` - Snippet definitions and template expansion
- `AutocompleteEngine.lua` - ScriptEditorService integration
- `ContextParser.lua` - Code context analysis
- `TabStopManager.lua` - Tab-stop navigation
- `ApiIndex.lua` - Bundled Roblox API reference

**UI Modules:**
- `PluginWidget.lua` - Main DockWidget UI
- `SnippetList.lua` - Snippet list rendering
- `SettingsDialog.lua` - Settings configuration
- `AddSnippetDialog.lua` - Custom snippet creation

**Entry Point:**
- `plugin.lua` - Initialization and coordination

### Performance Targets

- **Autocomplete callback:** < 10ms response time
- **Snippet ranking:** Context (50%) + Frequency (30%) + Prefix match (20%)
- **Memory:** Offline-first with bundled API data

### API Modes

**Primary Mode (Recommended):**
- Full ScriptEditorService integration
- Live autocomplete in editor
- Cursor position tracking
- Tab-stop navigation
- Preview tooltips

**Fallback Mode:**
- Script.Source manipulation
- Manual snippet insertion
- Insert at end of script
- Limited functionality

## Privacy & Safety

- **No code execution:** Plugin only inserts text, never runs code automatically
- **No external requests:** Works offline with bundled API data
- **Optional refresh:** API refresh requires user confirmation (not currently functional due to plugin HTTP restrictions)
- **Local storage:** Settings stored per-place via `plugin:SetSetting()`

## Contributing

Contributions welcome! Please ensure:

- All snippets follow TextMate `$1`, `$2`, `$0` format
- No code execution in snippets
- Comments and documentation for functions
- Test snippets before submitting

### Adding New Snippets

1. Open `modules/SnippetLibrary.lua`
2. Add to `DEFAULT_SNIPPETS` table:
```lua
{
	name = "yoursnippet",
	description = "What your snippet does",
	template = "your code with $1 and $2 placeholders",
	category = "essential", -- or "common" or "advanced"
	tags = {"tag1", "tag2"}
}
```
3. Test the snippet in Studio
4. Submit pull request

## Known Limitations

- **No HTTP requests:** Plugin cannot fetch live API updates due to Roblox security restrictions
- **Beta features required:** Full functionality requires Script Editor Beta features
- **Per-place settings:** Settings don't sync globally across all places
- **Single cursor:** Tab-stop mode works with single cursor only (no multi-cursor support)

## Roadmap

Planned features for future versions:

- [ ] Multi-cursor support for tab-stops
- [ ] Snippet import/export
- [ ] Snippet marketplace/sharing
- [ ] AI-powered snippet suggestions
- [ ] Snippet usage analytics dashboard
- [ ] Integration with external snippet repositories

## License

MIT License

Copyright (c) 2025 Lua-Coding-API Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Credits

- Built with Roblox Plugin API
- API data from https://robloxapi.github.io/ref/
- Inspired by VSCode snippets system

## Support

- **Issues:** Report bugs or request features via GitHub Issues
- **Documentation:** Full documentation in this README
- **Studio Output:** Check Output window for plugin status messages

## Version History

### v1.0.0 - Initial Release

- 24 default snippets (6 essential, 8 common, 10 advanced)
- ScriptEditorService integration with fallback mode
- Context-aware ranking algorithm
- Tab-stop navigation system
- Custom snippet creation
- Settings persistence
- Usage frequency tracking
- Bundled API index (50+ services, 150+ instances, 70+ enums)

---

**Made with ❤️ for the Roblox development community**
