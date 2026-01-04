# Local Development Guide

Quick guide to get the Cooking Timer app running locally on your Mac.

## Prerequisites

Before you start, make sure you have:

- **macOS 14+** (Sonoma or later)
- **Xcode 15+** with Command Line Tools
- **Swift 6.2+** (comes with Xcode)

### Check Your Setup

```bash
# Check macOS version
sw_vers

# Check if Xcode is installed
xcode-select -p

# Check Swift version
swift --version
```

## Quick Start (3 Steps)

### 1. Clone the Repository

```bash
git clone https://github.com/abiz1017/cooking-timer-app.git
cd cooking-timer-app
```

### 2. Open in Xcode

```bash
open Package.swift
```

This will:
- Open the project in Xcode
- Automatically resolve Swift Package Manager dependencies (SwiftSoup)
- Set up the build configuration

### 3. Build and Run

In Xcode:
- Press `⌘R` (Command + R) to build and run
- Or click the Play button in the top-left

**That's it!** The app should launch.

## Alternative: Command Line Build

If you prefer the command line:

```bash
# Build the project
swift build

# Run the app
swift run CookingTimerApp
```

## Project Structure

```
cooking-timer-app/
├── CookingTimerApp/           # Main source code
│   ├── Models/                # Data models
│   ├── ViewModels/            # Business logic
│   ├── Views/                 # SwiftUI UI
│   ├── Services/              # Recipe parsing, timer engine
│   ├── Utilities/             # Helpers
│   └── CookingTimerApp.swift  # App entry point
│
├── Package.swift              # SPM dependencies
├── Info.plist                 # App configuration
└── README.md                  # Main documentation
```

## Dependencies

The app uses **Swift Package Manager** (SPM) for dependencies:

- **SwiftSoup** (2.6.0+): HTML parsing for recipe scraping

Dependencies are automatically resolved when you open the project in Xcode.

### Manual Dependency Resolution

If dependencies don't resolve automatically:

1. In Xcode: **File → Packages → Resolve Package Versions**
2. Or from command line: `swift package resolve`

## Testing the App

### Try These Sample Recipe URLs

Once the app launches:

1. **Chocolate Chip Cookies**:
   ```
   https://www.allrecipes.com/recipe/10813/best-chocolate-chip-cookies/
   ```

2. **Classic Bolognese**:
   ```
   https://www.seriouseats.com/the-best-slow-cooked-bolognese-sauce-recipe
   ```

3. **Roasted Vegetables**:
   ```
   https://cooking.nytimes.com/recipes/1017937-roasted-vegetables
   ```

### How to Use

1. **Paste a recipe URL** in the input field
2. Click the **download button** to fetch and parse
3. **Set your desired serving time** (when you want to eat)
4. Click **"Start Timers"**
5. Watch as timers auto-start at the calculated times!

## Troubleshooting

### Build Errors

**Error: "No such module 'SwiftSoup'"**
- Solution: Wait for SPM to finish resolving dependencies
- Or: File → Packages → Resolve Package Versions

**Error: "Cannot find 'CookingTimerApp' in scope"**
- Solution: Make sure Package.swift is in the root directory
- Try: swift package clean && swift build

**Error: "Minimum deployment target"**
- Solution: Update to macOS 14+ or modify Package.swift:
  ```swift
  platforms: [
      .macOS(.v13)  // Change to your macOS version
  ]
  ```

### Runtime Issues

**App crashes on launch**
- Check Console app for crash logs
- Ensure macOS 14+ compatibility

**Recipe parsing fails**
- Check internet connection
- Try a different recipe URL
- Some sites may block automated requests

**Timers don't auto-start**
- Make sure serving time is in the future
- Check that recipe has valid step durations

## Development Workflow

### Making Changes

1. **Edit source files** in `CookingTimerApp/`
2. **Build**: `⌘B` or `swift build`
3. **Run**: `⌘R` or `swift run`
4. **Test**: `⌘U` or `swift test`

### Debugging

- Set breakpoints in Xcode
- Use `print()` statements
- Check Xcode console for logs
- Use LLDB debugger

### Code Hot Reload

SwiftUI supports live previews:
- Open any View file (e.g., `TimerCardView.swift`)
- Click **Resume** in the preview canvas (right sidebar)
- Changes reflect in real-time

## Project Configuration

### Minimum Requirements

Edit `Package.swift` to change requirements:

```swift
platforms: [
    .macOS(.v14)  // Change minimum macOS version
]
```

### App Bundle ID

Edit `Info.plist` to change bundle identifier:

```xml
<key>CFBundleIdentifier</key>
<string>com.yourname.CookingTimerApp</string>
```

## Building for Distribution

### Development Build

```bash
swift build -c debug
```

### Release Build

```bash
swift build -c release
```

The compiled binary will be in `.build/release/CookingTimerApp`

### Creating an Xcode Project

To create a full Xcode project (for advanced features):

```bash
swift package generate-xcodeproj
open CookingTimerApp.xcodeproj
```

## Environment Setup (Optional)

### API Keys for LLM Fallback

If you want to enable Claude API fallback for recipe parsing:

1. Get an API key from [Anthropic](https://console.anthropic.com/)
2. Set environment variable:
   ```bash
   export ANTHROPIC_API_KEY="your-key-here"
   ```
3. Update `RecipeViewModel` initialization to pass the key

### Notification Permissions

The app will request notification permissions on first launch for timer alerts.

## Performance Tips

### Faster Builds

```bash
# Use multiple cores for compilation
swift build -j 8

# Skip building tests
swift build --skip-tests
```

### Clean Build

If you encounter weird issues:

```bash
# Clean build artifacts
swift package clean

# Remove Package.resolved
rm Package.resolved

# Rebuild
swift build
```

## Editor Setup

### VS Code

Install these extensions:
- Swift Language Support
- CodeLLDB (for debugging)

Open project:
```bash
code .
```

### Other Editors

The project is pure Swift with SPM, so it works with:
- AppCode
- Nova
- Sublime Text with Swift plugin

## Next Steps

- Read [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for architecture details
- Check [README.md](README.md) for feature documentation
- Review [.claude/skills/mac-app-design/SKILL.md](.claude/skills/mac-app-design/SKILL.md) for design principles

## Common Tasks

### Add a New Feature

1. Create files in appropriate directory (Models, Views, etc.)
2. Update imports in dependent files
3. Build and test
4. Commit changes

### Fix a Bug

1. Reproduce the issue
2. Set breakpoints or add debug prints
3. Identify root cause
4. Fix and verify
5. Add tests to prevent regression

### Update Dependencies

```bash
# Update Package.resolved
swift package update

# Or in Xcode
# File → Packages → Update to Latest Package Versions
```

## Getting Help

If you run into issues:

1. Check [Troubleshooting](#troubleshooting) above
2. Review error messages in Xcode console
3. Check [GitHub Issues](https://github.com/abiz1017/cooking-timer-app/issues)
4. Read [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for architecture

## Success! 🎉

If you see the recipe input screen, you're all set! Try pasting a recipe URL and watching the magic happen.

---

**Happy Cooking! 👨‍🍳**
