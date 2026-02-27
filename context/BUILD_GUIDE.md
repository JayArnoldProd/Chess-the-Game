# Chess-the-Game — Build Guide

**Last Updated:** 2026-02-27

---

## Requirements

### IDE & Runtime Versions

| Component | Version | Notes |
|-----------|---------|-------|
| **GameMaker IDE** | 2024.13.1.193 | Required — 2024.14 has prefab bug |
| **Runtime** | 2024.13.1.242 | Matches IDE version |
| **Igor CLI** | (bundled with runtime) | Command-line build tool |

### File Locations

| Item | Path |
|------|------|
| Project | `C:\Users\jayar\Documents\GitHub\Chess-the-Game\Chess the Game.yyp` |
| Igor | `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242\bin\igor\windows\x64\Igor.exe` |
| Runtime | `C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242` |
| User Folder | `C:\Users\jayar\AppData\Roaming\GameMakerStudio2\jayarnoldproduces_1544617` |
| License | `{User Folder}\licence.plist` |

---

## Building with IDE

### Quick Test
1. Open `Chess the Game.yyp` in GameMaker
2. Press **F5** or click the Run button
3. Game compiles and launches

### Clean Build
1. **Build → Clean** (removes cached compiled files)
2. **Build → Run** (full recompile)

---

## Building with Igor CLI

Igor is the command-line build tool for compiling without opening the IDE.

### Basic Compile & Run

```powershell
# Set paths
$igor = "C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242\bin\igor\windows\x64\Igor.exe"
$project = "C:\Users\jayar\Documents\GitHub\Chess-the-Game\Chess the Game.yyp"
$runtimePath = "C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242"
$userFolder = "C:\Users\jayar\AppData\Roaming\GameMakerStudio2\jayarnoldproduces_1544617"
$cache = "C:\Users\jayar\clawd\temp\gms2-build\cache"
$temp = "C:\Users\jayar\clawd\temp\gms2-build\temp"

# Create directories if needed
New-Item -ItemType Directory -Force -Path $cache | Out-Null
New-Item -ItemType Directory -Force -Path $temp | Out-Null

# Compile and run
& $igor --project="$project" --runtimePath="$runtimePath" --user="$userFolder" --cache="$cache" --temp="$temp" -r=VM -j=8 --ignorecache windows Run
```

### Igor Options

| Option | Description |
|--------|-------------|
| `--project` | Path to .yyp file |
| `--runtimePath` | Path to runtime folder |
| `--user` | User folder containing license |
| `--cache` | Build cache directory |
| `--temp` | Temporary files directory |
| `-r=VM` | Use VM runtime (faster compile) |
| `-r=YYC` | Use YYC runtime (faster execution, slower compile) |
| `-j=8` | Number of parallel jobs |
| `--ignorecache` | Force full recompile |
| `-v` | Verbose output |

### Worker Commands

| Command | Description |
|---------|-------------|
| `windows Run` | Compile and launch game |
| `windows Package` | Build Windows installer |
| `windows PackageZip` | Build zip archive |
| `windows Clean` | Clean build cache |

### Capturing Debug Output

GameMaker's `show_debug_message()` output goes to stdout when launched via Igor:

```powershell
& $igor --project="$project" ... windows Run 2>&1 | Tee-Object -FilePath "game-output.log"
```

---

## Development Workflow

### Arnold/Sub-Agent Workflow

1. **Make code changes** (edit .gml files)
2. **Compile with Igor** (launches game on Jay's machine)
3. **Jay playtests** (game pops up automatically)
4. **Arnold reads debug logs** (via `show_debug_message()` output)
5. **Fix any issues** without needing direction
6. **Repeat** until clean

### Common Tasks

**Add a new script:**
1. Create `scripts/my_script/my_script.gml`
2. Create `scripts/my_script/my_script.yy` (JSON manifest)
3. Add reference to `Chess the Game.yyp`
4. Compile to verify

**Modify an object:**
1. Edit the appropriate `.gml` file in `objects/{ObjectName}/`
2. Compile to check for syntax errors

**Test AI behavior:**
1. Set difficulty with F1 menu or keys 1-5
2. Toggle debug display with F2
3. Watch AI state and search progress

---

## Common Errors

### "cannot redeclare a builtin variable"

GameMaker reserves certain variable names. Don't use these as parameters or local variables:

| Reserved | Alternative |
|----------|-------------|
| `score` | `_score` |
| `board` | `_board` |
| `depth` | `_depth` |
| `sign` | `_sign` |
| `health` | `health_` |
| `x`, `y` | `_x`, `_y` |

### "Failed to load Options from local_settings.json"

This warning can be safely ignored — Igor continues without it.

### "License file not found"

Ensure the user folder path is correct and contains `licence.plist`.

### "Syntax error"

Check for:
- Missing semicolons at end of statements
- Mismatched braces `{ }`
- Typos in function/variable names
- Using reserved words

---

## Known Compatibility Issues

### IDE 2024.14 Prefab Bug

Version 2024.14 has a bug with prefabs that breaks the project. **Stay on 2024.13.1.193.**

### Audio via Igor

Music and sound effects may not play when the game is launched via Igor CLI. They work correctly when launched from the IDE. This appears to be an Igor quirk, not a project issue.

---

## Project Structure

```
Chess-the-Game/
├── Chess the Game.yyp      # Main project file
├── objects/                 # All game objects
│   ├── {ObjectName}/
│   │   ├── Create_0.gml
│   │   ├── Step_0.gml
│   │   ├── Draw_0.gml
│   │   └── {ObjectName}.yy
├── scripts/                 # All scripts
│   ├── {script_name}/
│   │   ├── {script_name}.gml
│   │   └── {script_name}.yy
├── rooms/                   # Level definitions
│   ├── {RoomName}/
│   │   └── {RoomName}.yy
├── sprites/                 # Sprite assets
├── sounds/                  # Audio assets
├── fonts/                   # Font assets
├── tilesets/               # Tileset definitions
└── context/                # Documentation
    ├── ARCHITECTURE.md
    ├── GAME_MECHANICS.md
    ├── AI_SYSTEM.md
    ├── OBJECTS_REFERENCE.md
    ├── KNOWN_ISSUES.md
    ├── BUILD_GUIDE.md
    ├── RESUME.md
    └── design-docs/
```

---

## GML Gotchas

### Variable Naming
- Prefix parameters with `_` to avoid shadowing
- Use `_score` not `score`, `_board` not `board`

### Instance Access
- Always check `instance_exists(obj)` before accessing `obj.variable`
- Use `noone` check: `if (piece != noone)`

### Array Iteration
```gml
// Correct
for (var i = 0; i < array_length(arr); i++) {
    var item = arr[i];
}

// Modern GML also allows
for (var item in arr) {
    // ...
}
```

### Struct Access
```gml
var data = { name: "test", value: 42 };
var n = data.name;      // Dot notation
var v = data[$ "value"]; // Dynamic key access
```

### With Statement
```gml
// Runs code in context of all instances of Type
with (Chess_Piece_Obj) {
    if (piece_type == 1) {
        // 'self' is the Chess_Piece_Obj instance
        // 'other' is the original calling instance
    }
}
```

---

## Output Locations

| Build Type | Output Path |
|------------|-------------|
| VM Run | In-memory (temporary) |
| Package | `C:\Users\jayar\clawd\output\Chess the Game\` |
| Debug Log | Console stdout (capture with Tee-Object) |

---

## Quick Reference

### Build & Run (One-liner)

```powershell
$igor="C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242\bin\igor\windows\x64\Igor.exe"; $p="C:\Users\jayar\Documents\GitHub\Chess-the-Game\Chess the Game.yyp"; $r="C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242"; $u="C:\Users\jayar\AppData\Roaming\GameMakerStudio2\jayarnoldproduces_1544617"; & $igor --project="$p" --runtimePath="$r" --user="$u" --cache="$env:TEMP\gms" --temp="$env:TEMP\gms" -r=VM -j=8 windows Run
```

### Clean Build (Force Recompile)

```powershell
Remove-Item -Recurse -Force "C:\Users\jayar\clawd\temp\gms2-build\cache" -ErrorAction SilentlyContinue
# Then run normal build command
```
