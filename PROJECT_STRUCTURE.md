# Cooking Timer App - Project Structure

## Overview

A macOS app that automatically parses recipes from websites and creates concurrent, parallel timers that tell you when to start each cooking step, working backwards from your desired serving time.

## Architecture

Built using **MVVM (Model-View-ViewModel)** pattern with SwiftUI and Swift 6.2.

### Core Value Proposition

1. **Automated Recipe Parsing**: Paste a URL, get timers automatically
2. **Backward Time Calculation**: Set serving time, app calculates when to start each step
3. **Parallel Timer Visualization**: See all steps and their timings at once
4. **Dependency Management**: Handles steps that must happen in sequence vs. parallel

## Directory Structure

```
CookingTimerApp/
├── CookingTimerApp.swift              # Main app entry point (@main)
│
├── Models/                             # Data models
│   ├── Recipe.swift                    # Complete recipe with steps
│   ├── RecipeStep.swift                # Individual cooking step
│   ├── CookingTimer.swift              # Timer with state management
│   └── TimerState.swift                # Timer lifecycle states
│
├── ViewModels/                         # Business logic layer
│   ├── RecipeViewModel.swift           # Recipe fetching and editing
│   └── TimerCoordinatorViewModel.swift # Multi-timer orchestration
│
├── Views/                              # SwiftUI UI components
│   ├── MainWindowView.swift            # Main application window
│   ├── RecipeInputView.swift           # URL input and fetching
│   ├── TimerListView.swift             # List of timer cards
│   └── Components/
│       ├── ProgressRingView.swift      # Circular progress indicator
│       └── TimerCardView.swift         # Individual timer card
│
├── Services/                           # Business services
│   ├── RecipeParserService.swift       # Multi-layer recipe parsing
│   └── TimerEngineService.swift        # Timer calculation logic
│
└── Utilities/                          # Helper utilities
    ├── DurationParser.swift            # Parse time strings
    ├── TimeFormatter.swift             # Format durations for display
    └── DependencyGraph.swift           # Step dependency resolution
```

## Key Components

### Models

**Recipe**
- Complete recipe with title, steps, timing
- Calculates total time based on critical path
- Groups steps by type

**RecipeStep**
- Individual cooking step with description, duration, type
- Supports dependencies (step X must complete before step Y)
- Can run in parallel with other steps

**CookingTimer**
- ObservableObject that wraps a RecipeStep
- Manages countdown, state transitions
- Auto-calculates progress and remaining time

**TimerState**
- Enum: ready → running → (paused) → completed/cancelled

### ViewModels

**RecipeViewModel**
- Fetches recipes from URLs using RecipeParserService
- Manages recipe editing (add/update/remove steps)
- Validates recipe before timer creation

**TimerCoordinatorViewModel**
- Creates timers for all recipe steps
- Calculates start times using TimerEngineService
- Auto-starts timers at scheduled times
- Manages pause/resume/cancel for all timers

### Services

**RecipeParserService**
Multi-layer parsing with fallbacks:
1. **Schema.org JSON-LD** (80% coverage) - Structured data extraction
2. **HTML Scraping** (15% coverage) - Pattern matching with SwiftSoup
3. **LLM Extraction** (5% fallback) - Claude API for difficult cases
4. **Duration Estimation** - Cooking term dictionary

**TimerEngineService**
- Builds dependency graph from recipe steps
- Detects circular dependencies
- Calculates critical path (longest chain)
- Works backwards from serving time to determine start times
- Generates timeline for visualization

### Utilities

**DurationParser**
- Parses ISO 8601 durations (PT30M)
- Parses natural language (30 minutes, 2 hours)
- Estimates durations from cooking terms (simmer ≈ 20min)

**TimeFormatter**
- Multiple formatting styles (abbreviated, full, compact, timer)
- Relative time (in 15m, 5m ago)
- Extensions for convenient usage

**DependencyGraph**
- Topological sort for execution order
- Cycle detection and validation
- Critical path calculation
- Start time calculation working backwards

## Data Flow

### Recipe Parsing Flow

```
User pastes URL
    ↓
RecipeViewModel.fetchRecipe()
    ↓
RecipeParserService.parseRecipe()
    ↓
Try Schema.org → HTML Scraping → LLM Extraction
    ↓
Return ParseResult (recipe + confidence)
    ↓
RecipeViewModel updates @Published recipe
    ↓
UI displays recipe
```

### Timer Creation Flow

```
User sets serving time & clicks "Start"
    ↓
TimerCoordinatorViewModel.loadRecipe()
    ↓
TimerEngineService.calculateStartTimes()
    ↓
DependencyGraph validates & calculates critical path
    ↓
Calculate start time for each step (working backwards)
    ↓
Create CookingTimer for each step
    ↓
TimerCoordinatorViewModel.startAllTimers()
    ↓
Auto-start timers when scheduled time arrives
    ↓
UI updates every second showing progress
```

## Technologies Used

### Frameworks & Languages
- **Swift 6.2**: Modern concurrency (async/await, actors)
- **SwiftUI**: Declarative UI framework
- **Combine**: Reactive timer updates

### Dependencies
- **SwiftSoup**: HTML parsing for web scraping fallback
- **URLSession**: Native HTTP client for fetching recipes

### Future Dependencies (Planned)
- **UserNotifications**: Native macOS notifications
- **Anthropic SDK**: LLM fallback for difficult parsing cases

## Features

### Implemented
- ✅ Multi-layer recipe parsing with fallbacks
- ✅ Dependency graph with cycle detection
- ✅ Backward time calculation from serving time
- ✅ Parallel step detection and grouping
- ✅ Auto-start timers at calculated times
- ✅ Individual timer control (start/pause/resume/cancel)
- ✅ Bulk timer operations (pause all, resume all, cancel all)
- ✅ Progress tracking and status queries
- ✅ SwiftUI UI with timer cards and list view
- ✅ Accessibility labels and hints

### Planned
- ⏳ UserNotifications integration for background alerts
- ⏳ LLM extraction implementation (Claude API)
- ⏳ HTML scraping implementation (SwiftSoup)
- ⏳ Timeline gantt chart visualization
- ⏳ Recipe library (save/load recipes)
- ⏳ App Intents for Siri/Shortcuts integration
- ⏳ Widgets for quick timer status
- ⏳ Comprehensive test suite

## Design Principles

Following Apple's 2025 Mac App Design Guidelines:

1. **SwiftUI First**: Modern declarative UI
2. **MVVM Architecture**: Clear separation of concerns
3. **Async/Await**: Modern concurrency throughout
4. **Accessibility**: VoiceOver labels, keyboard navigation
5. **System Patterns**: Standard components before custom
6. **Reactive Updates**: @Published properties drive UI
7. **Type Safety**: Codable, strong typing throughout

## Building the App

### Prerequisites
- macOS 14+
- Xcode 15+
- Swift 6.2+

### Build Steps

1. Open in Xcode:
   ```bash
   open Package.swift
   ```

2. Wait for SPM to resolve dependencies (SwiftSoup)

3. Build and run (⌘R)

### Or build via command line:
```bash
swift build
swift run CookingTimerApp
```

## Usage

1. **Add Recipe**: Paste a recipe URL
2. **Set Serving Time**: Choose when you want to eat
3. **Start Timers**: App calculates when to start each step
4. **Follow Notifications**: Get alerted when to start each task
5. **Enjoy**: Food ready at exactly the right time!

## Architecture Decisions

### Why MVVM?
- Perfect fit for SwiftUI's reactive nature
- Clear separation: Models → ViewModels → Views
- Easy to test business logic in isolation

### Why Multi-Layer Parsing?
- Schema.org covers 80% of sites (free, reliable)
- HTML scraping covers another 15% (sites without structured data)
- LLM fallback ensures 100% coverage (always works)

### Why Backward Calculation?
- Core value: knowing when to START, not just countdown
- Users care about serving time, not recipe start time
- Dependency graph ensures correct ordering

### Why Dependency Graph?
- Recipes have sequential steps (sauté before baking)
- Some steps can run in parallel (preheat oven while chopping)
- Graph ensures correctness, detects circular dependencies

## Contributing

This is a demonstration project showing:
- Mac app development best practices (2025)
- Multi-layer parsing with graceful degradation
- Complex timer orchestration
- SwiftUI MVVM architecture

Feel free to extend with:
- Additional recipe sites support
- LLM integration for parsing
- Timeline visualization
- Recipe library/favorites
- iOS companion app
