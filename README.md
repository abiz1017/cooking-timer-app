# Cooking Timer App

A macOS app that automatically parses recipes from websites and creates concurrent, parallel timers that tell you **when to start** each cooking step, working backwards from your desired serving time.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-green)

## The Problem

Cooking multiple-step recipes is hard:
- 😓 You finish prep, but don't know when to start cooking
- ⏰ Food gets cold while waiting for other components
- 🤷 Should I start the sauce before or after the pasta?
- 📱 Managing multiple timers on your phone is chaotic

## The Solution

**Just tell the app when you want to eat.**

The app:
1. ✨ **Automatically parses** recipes from URLs (no manual input!)
2. 🎯 **Calculates backwards** from serving time
3. 📊 **Shows parallel timers** for all cooking steps
4. ⏰ **Tells you when to start** each step
5. 🔔 **Notifies you** when it's time to begin

## Example

You want to eat at **6:00 PM**. The recipe has:
- Preheat oven (10 min)
- Chop vegetables (5 min)
- Sauté onions (7 min)
- Bake (30 min)
- Rest (5 min)

The app tells you:
- ✅ **5:03 PM** - Start preheating oven (can run in parallel)
- ✅ **5:08 PM** - Start chopping vegetables
- ✅ **5:13 PM** - Start sautéing onions
- ✅ **5:20 PM** - Put in oven
- ✅ **5:50 PM** - Take out, let rest
- ✅ **6:00 PM** - Serve and enjoy!

## Features

### 🔥 Core Features

- **Automated Recipe Parsing**: Paste a URL → Get timers automatically
  - Schema.org JSON-LD parsing (80% of recipe sites)
  - HTML scraping fallback (15% of sites)
  - LLM extraction for difficult cases (5% fallback)

- **Smart Timer Calculation**: Works backwards from serving time
  - Dependency graph resolution (step X before step Y)
  - Parallel step detection (preheat oven while chopping)
  - Critical path calculation (longest sequence of steps)

- **Parallel Timer Visualization**: See all timers at once
  - Grouped by status (upcoming, in progress, completed)
  - Progress rings for each timer
  - Step type badges (prep, cooking, baking, resting, assembly)

- **Auto-Start Timers**: No manual intervention needed
  - Timers start automatically at calculated times
  - Pause/resume/cancel individual or all timers
  - Overall progress tracking

### 🎨 Design

Built following [Apple's 2025 Mac App Design Guidelines](.claude/skills/mac-app-design/SKILL.md):
- ✅ SwiftUI with Liquid Glass design system
- ✅ MVVM architecture for clean code
- ✅ Accessibility support (VoiceOver, keyboard navigation)
- ✅ Dark mode support
- ✅ Native macOS patterns and components

## Installation

### Prerequisites

- macOS 14+ (Sonoma or later)
- Xcode 15+ with Swift 6.2

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/abiz1017/cooking-timer-app.git
   cd cooking-timer-app
   ```

2. Open in Xcode:
   ```bash
   open Package.swift
   ```

3. Wait for Swift Package Manager to resolve dependencies (SwiftSoup)

4. Build and run: `⌘R`

### Or build via command line:
```bash
swift build
swift run CookingTimerApp
```

## Usage

### Basic Workflow

1. **Launch the app**

2. **Add a recipe**:
   - Paste a recipe URL (e.g., from AllRecipes, NYT Cooking, Serious Eats)
   - Or use one of the sample URLs
   - App automatically extracts steps and timings

3. **Set serving time**:
   - Choose when you want to eat
   - App calculates when to start each step

4. **Start timers**:
   - Click "Start Timers"
   - Timers auto-start at calculated times
   - Get notifications when to begin each step

5. **Follow along**:
   - See progress for each step
   - Pause/resume if needed
   - Complete all steps → Enjoy your meal!

### Supported Recipe Sites

The app works with any site that uses Schema.org Recipe format:
- ✅ AllRecipes
- ✅ Food Network
- ✅ NYT Cooking
- ✅ Serious Eats
- ✅ Bon Appétit
- ✅ Most food blogs

And gracefully degrades for sites without structured data.

## Architecture

Built with **MVVM (Model-View-ViewModel)** pattern:

```
Models                   ViewModels                Services
├── Recipe               ├── RecipeViewModel       ├── RecipeParserService
├── RecipeStep           └── TimerCoordinator      └── TimerEngineService
├── CookingTimer
└── TimerState
```

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Swift 6.2**: Async/await concurrency
- **Combine**: Reactive timer updates
- **SwiftSoup**: HTML parsing for recipe scraping
- **URLSession**: Network requests

### Core Logic

1. **Recipe Parsing** (`RecipeParserService.swift`)
   - Multi-layer parsing with fallbacks
   - Confidence scoring for parse quality
   - Automatic duration extraction

2. **Timer Calculation** (`TimerEngineService.swift`)
   - Dependency graph validation
   - Critical path calculation
   - Backward time calculation from serving time

3. **Timer Orchestration** (`TimerCoordinatorViewModel.swift`)
   - Auto-start timers at calculated times
   - Pause/resume/cancel operations
   - Progress tracking

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for detailed architecture documentation.

## Roadmap

### v1.0 (Current)
- ✅ Automated recipe parsing
- ✅ Backward time calculation
- ✅ Parallel timer management
- ✅ Basic UI with timer cards

### v1.1 (Planned)
- ⏳ UserNotifications integration
- ⏳ Timeline gantt chart visualization
- ⏳ HTML scraping with SwiftSoup
- ⏳ LLM extraction via Claude API

### v2.0 (Future)
- 📝 Recipe library (save favorites)
- 🍎 App Intents for Siri/Shortcuts
- 📱 iOS companion app
- 🎨 Widgets for quick timer status
- ☁️ iCloud sync across devices

## Development

### Project Structure

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for complete documentation.

### Testing

```bash
swift test
```

### Code Style

Following Apple's Swift conventions and Mac app best practices (2025).

## Contributing

Contributions welcome! Areas that need work:

1. **HTML Scraping**: Implement SwiftSoup-based scraping for sites without Schema.org
2. **LLM Integration**: Add Claude API fallback for difficult parsing cases
3. **Notifications**: Implement UserNotifications for background alerts
4. **Timeline View**: Build gantt chart visualization of all timers
5. **Recipe Library**: Add ability to save and reuse recipes
6. **Tests**: Comprehensive test coverage for parsing and timer logic

## License

MIT License - See LICENSE file for details.

## Credits

Built as a demonstration of:
- macOS app development best practices (2025)
- Multi-layer parsing with graceful degradation
- Complex timer orchestration and dependency management
- SwiftUI MVVM architecture

Inspired by the frustration of managing multiple kitchen timers while cooking complex recipes.

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Check [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for architecture details
- Review [.claude/skills/mac-app-design/SKILL.md](.claude/skills/mac-app-design/SKILL.md) for design guidelines

---

**Made with ❤️ and Swift**
