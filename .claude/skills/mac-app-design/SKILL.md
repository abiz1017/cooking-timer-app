---
name: mac-app-design
description: Expert guidance for building excellently designed macOS applications following Apple's 2025/2026 standards, including the Liquid Glass design system, SwiftUI best practices, accessibility requirements, and modern macOS features.
---

# Mac App Design Excellence

## Overview

This skill provides comprehensive guidance for building native macOS applications that follow Apple's Human Interface Guidelines (2025/2026), including the new Liquid Glass design system introduced with macOS 26 "Tahoe".

## Core Design Principles (2025)

### Liquid Glass Design System

The most significant visual redesign since 2013, emphasizing:
- **Translucency and Depth**: Dynamic materials that refract and reflect content
- **Fluid Responsiveness**: Interfaces adapt to content and context
- **Universal Language**: Consistent across all Apple platforms (iOS 26, macOS 26, etc.)

### Three Pillars: Hierarchy, Harmony, Consistency

**Hierarchy**
- Clear visual organization through size, color, and positioning
- Guide user attention to important elements
- Strong visual hierarchy throughout

**Harmony**
- Cohesive visual language across all elements
- Balanced composition and consistent styling

**Consistency**
- Predictable patterns across the platform
- Familiar interactions and unified experience

## Technology Stack

### SwiftUI (Preferred Framework)
- **Primary choice** for new macOS apps in 2025/2026
- Performance now matches iOS (handles 10,000+ items smoothly)
- Native integration with Swift concurrency (async/await)
- ObservableObject for reactive UI updates

### Swift 6.2 Features
- **Approachable Concurrency**: Single-threaded by default with @MainActor
- **Inline Arrays**: Compile-time optimizations for performance
- **Span Type**: Safe memory access without unsafe pointers
- Enhanced debugging with named tasks and async stepping

### Recommended Architectures

**MVVM (Model-View-ViewModel)**
- Clear separation of concerns
- Perfect fit for SwiftUI's reactive nature
- Recommended for most applications

**The Composable Architecture (TCA)**
- For complex state management needs
- Modular and testable
- Centralized store for predictable state

## Key UI Components

### Sidebars
- **Width**: 220-260pt for natural feel
- Use `NSSplitViewController` with `SplitViewItem`
- `NSOutlineView` for automatic scaling
- Support all three sidebar sizes
- Updated with Liquid Glass refraction effects

### Toolbars
- Rounded corners matching modern hardware
- Keep sidebar toggle left-aligned and pinned to window controls
- Avoid "moving target" controls
- Concentric design with window controls

### Inspectors
- Use `UISplitViewController` for inspector panes
- Dynamic, resizable columns
- Follow system patterns (like Mail, Preview)

### Windows
- Support Split View (side-by-side in dedicated space)
- Window tiling for flexible layouts
- Proper window management and state restoration

## SF Symbols 7 (2025)

### Features
- **6,900+ symbols** in library
- Nine weights and three scales
- Draw animations and variable rendering
- Gradient support
- Auto-alignment with San Francisco font

### Usage Guidelines
- ✅ Use for UI elements and icons
- ✅ Customize colors, sizes, weights
- ❌ Do NOT use in app icons or logos
- ❌ Cannot customize Apple product symbols
- ❌ No trademark-related use

### App Icons
- Create 1024px x 1024px for App Store
- Use Icon Composer for layered Liquid Glass icons
- Multi-layer format for cross-platform consistency

## System Integration

### App Intents (Critical for Modern Apps)

Makes content and actions discoverable system-wide through:
- **Spotlight**: Direct action execution without opening app
- **Siri**: Voice commands (iOS 18.4+)
- **Shortcuts**: Expose app functionality for automation
- **Control Center**: Quick access to frequently used features
- **Apple Intelligence**: Gateway for AI integration

### Menu Bar Apps
- Use SwiftUI's `MenuBarExtra` scene
- `NSPopover` for displaying content
- Popular for utilities and quick-access tools
- Can complement main app or be standalone

### Widgets
- Built with SwiftUI
- Multiple sizes and families supported
- Live Activities for real-time updates
- Integrate with Liquid Glass design system

## Accessibility (Required, Not Optional)

### Core Features to Support

**VoiceOver**
- Screen reader with keyboard/trackpad gestures
- Enable/disable: Command + F5
- All interactive elements must have proper labels

**Voice Control**
- Full app control via voice commands
- All buttons and controls must be voice-accessible

**Dynamic Type**
- Support larger text sizes
- Use system font sizes that scale

**Sufficient Contrast**
- Follow WCAG guidelines
- Test in both light and dark modes

**Reduced Motion**
- Respect motion preferences
- Provide alternatives to animations

**Captions**
- For any audio/video content

### Accessibility Nutrition Labels (Fall 2025)
- App Store highlights accessibility features
- Required for enterprise/government markets
- Demonstrates commitment to inclusive design

### Implementation Checklist
- Use `.accessibilityLabel()` for all interactive elements
- Add `.accessibilityValue()` for dynamic content (progress bars, counters)
- Provide `.accessibilityHint()` for complex actions
- Test with VoiceOver from the start, not as an afterthought
- Verify full keyboard navigation without mouse

## Performance Standards

### Expectations
- **60fps minimum** (120fps for ProMotion displays)
- Snappy, responsive UI at all times
- Efficient memory usage
- Proper async/await to prevent main thread blocking
- Optimized list and scroll performance

### Common Performance Issues

Research shows 87% of performance problems trace to five concurrency misuse patterns:
1. Blocking main thread with synchronous operations
2. Inefficient state updates causing excessive re-renders
3. Memory leaks from strong reference cycles
4. Unnecessary UI refreshes
5. Poor background task management

### Tools
- **Instruments**: Swift Concurrency template for profiling
- **LLDB**: Async stepping and task context visibility
- **Named Tasks**: Human-readable debugging
- **XCTest**: Performance tests and benchmarks

## Testing Requirements

### XCTest Framework

Apple's native testing framework supports:

**Unit Tests**
- Core logic validation
- Isolated component testing
- Fast, deterministic

**Integration Tests**
- Component interaction validation
- Service integration testing

**UI Tests**
- User flow automation
- End-to-end testing
- Accessibility testing

**Performance Tests**
- Benchmarks and optimization
- Regression detection

### Quality Checklist
- ✅ Functionality validation across use cases
- ✅ Stability under various conditions
- ✅ Accessibility compliance (all features)
- ✅ Performance benchmarks met (60fps minimum)
- ✅ Real device testing (not just simulator)
- ✅ Memory leak detection with Instruments
- ✅ Thread safety validation
- ✅ CI/CD integration for automated testing

## Best Practices

### Design
1. **Use System Patterns First**: Leverage standard components before creating custom ones
2. **Follow HIG**: Apple's Human Interface Guidelines are the definitive source
3. **Embrace Liquid Glass**: Use modern translucent, adaptive materials
4. **Consistent Spacing**: Use system-defined margins and padding
5. **Dark Mode Support**: Design for both light and dark appearances from day one

### Development
1. **SwiftUI First**: Start with SwiftUI, fall back to AppKit only when necessary
2. **Async/Await**: Use modern Swift concurrency throughout
3. **@MainActor**: Ensure UI updates happen on main thread
4. **ObservableObject**: For reactive state management
5. **Minimize Dependencies**: Rely on system frameworks when possible

### Performance
1. **Profile Early**: Use Instruments to identify bottlenecks before they become problems
2. **Lazy Loading**: Load content as needed, not upfront
3. **Background Work**: Keep main thread free for UI updates only
4. **Efficient Updates**: Only refresh what changed, not entire views
5. **Memory Management**: Watch for retain cycles with weak/unowned references

### Accessibility
1. **Design Inclusive**: Consider accessibility from day one, not as an afterthought
2. **Semantic Elements**: Use proper SwiftUI components with built-in accessibility
3. **Alternative Text**: Describe all meaningful images and icons
4. **Keyboard Navigation**: Ensure full app control without mouse
5. **Test Regularly**: VoiceOver testing during development, not just at the end

## Anti-Patterns to Avoid

❌ **Over-Engineering**: Don't add features or abstractions not explicitly needed
❌ **Custom UI When Standard Exists**: Use system components before building custom
❌ **Blocking Main Thread**: Always use async for long-running operations
❌ **Ignoring Accessibility**: Not optional in 2025 - required for broad market access
❌ **Manual Layout**: Use SwiftUI's declarative layout system
❌ **Hard-Coded Values**: Use system colors, spacing, and fonts for adaptability
❌ **Skipping Tests**: Quality requires comprehensive testing from the start
❌ **AppKit When SwiftUI Works**: Prefer modern frameworks unless specific need

## Implementation Guidelines

### When Building a New Mac App

1. **Project Setup**
   - Create project with SwiftUI + Swift Package Manager
   - Set minimum deployment target (macOS 14+ recommended)
   - Configure Info.plist with proper permissions

2. **Architecture**
   - Implement MVVM pattern for clear separation
   - Use @StateObject for view model ownership
   - Use @ObservedObject for passed-in models
   - Keep views focused on presentation only

3. **UI Development**
   - Design with both light and dark modes
   - Use SF Symbols for all icons
   - Apply proper spacing and alignment
   - Test at different window sizes

4. **Accessibility**
   - Add labels from the start
   - Test with VoiceOver enabled (Command + F5)
   - Verify keyboard navigation
   - Support dynamic type scaling

5. **Performance**
   - Use async/await for network and file operations
   - Profile with Instruments during development
   - Implement lazy loading for large data sets
   - Monitor memory usage

6. **Testing**
   - Set up XCTest target
   - Write unit tests for business logic
   - Add UI tests for critical flows
   - Include accessibility tests

7. **Integration**
   - Implement App Intents for system integration
   - Add Spotlight support for discoverability
   - Consider widgets for quick access
   - Plan for future Apple Intelligence integration

## Quick Reference

### Essential Apple Resources
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)

### WWDC 2025 Sessions
- "Get to know the new design system" (Liquid Glass overview)
- "Get to know App Intents" (System integration)
- "What's new in SwiftUI" (Latest framework features)

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Swift 6.2**: Latest language with improved concurrency
- **App Intents**: System integration and Apple Intelligence gateway
- **SF Symbols 7**: 6,900+ professional icons with animations
- **XCTest**: Comprehensive testing framework

## Conclusion

Building an excellent macOS app in 2025/2026 requires:
- Embracing SwiftUI and modern Swift concurrency
- Following the Liquid Glass design system
- Prioritizing accessibility as a core feature, not an add-on
- Integrating with the system via App Intents
- Testing comprehensively with XCTest
- Using system patterns before creating custom solutions
- Delivering smooth, responsive 60fps+ performance

Follow these guidelines to create apps that feel native, accessible, and delightful to use on macOS.
