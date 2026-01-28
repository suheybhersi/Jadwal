# Usage Mode Implementation Guide

This document describes the implementation of the Usage Mode feature in Jadwal, which allows users to choose how structured their Quran memorization experience should be.

## Overview

The Usage Mode system provides two distinct modes of engagement:

1. **Flexible Mode** - For inconsistent students or those who prefer minimal pressure
2. **Intensive Mode** - Full functionality with SM-2 algorithm, reviews, statistics, and all features

## Architecture

### Core Components

#### 1. UserPreferencesService (`lib/services/user_preferences_service.dart`)

Central service for managing user preferences using `ChangeNotifier` pattern.

**Key Features:**
- Enum-based mode selection: `UsageMode.flexible`, `UsageMode.intensive`
- Persistent storage using `SharedPreferences`
- Derived properties based on mode:
  - `shouldScheduleReviews` - Whether to show scheduled reviews
  - `shouldShowPressureMetrics` - Whether to show streaks and missed items

**Mode Defaults:**
- **Flexible**: No reviews, no streaks, no missed items warnings
- **Intensive**: All features enabled - SM-2 algorithm, reviews, statistics, streaks, achievements

#### 2. Usage Mode Selection Page (`lib/pages/onboarding/usage_mode_selection.dart`)

Onboarding screen shown to new users after authentication.

**Features:**
- Visual card-based selection
- Clear mode descriptions and features
- Recommended badge on Intensive mode
- Reassurance message about changing later

#### 3. Usage Mode Settings Page (`lib/pages/screens/SettingsPage/usage_mode_page.dart`)

Settings page for changing mode after initial selection.

**Features:**
- Shows current mode
- Visual selection with confirmation
- Information about progress preservation
- Save button only shows when changes are made

### Integration Points

#### 1. Main App (`lib/main.dart`)

```dart
ChangeNotifierProvider(create: ((context) => UserPreferencesService())),
```

Provides `UserPreferencesService` to the entire app via Provider.

#### 2. Authentication Flow (`lib/pages/auth/auth_page.dart`)

```dart
if (!prefsService.hasCompletedModeSelection) {
  return UsageModeSelectionPage(onComplete: () { ... });
}
```

Shows mode selection screen for first-time users before they create a plan.

#### 3. Settings Page (`lib/pages/screens/SettingsPage/settings_page.dart`)

Added "Memorization Mode" option in Preferences section:

```dart
_buildSettingTile(
  icon: Iconsax.chart,
  title: 'Memorization Mode',
  description: 'Choose how structured your experience is',
  onTap: () { Navigator.push(...UsageModePage()...) },
),
```

#### 4. Home Page Reviews (`lib/pages/screens/HomePage/upcoming_section.dart`)

Conditionally shows review cards based on mode:

```dart
Consumer<UserPreferencesService>(
  builder: (context, prefsService, child) {
    if (!prefsService.shouldScheduleReviews || reviews.isEmpty) {
      return SizedBox();
    }
    return /* Review Card */;
  },
),
```

#### 5. Completion Feedback (`lib/services/completion_feedback_service.dart`)

Conditionally shows streak information:

```dart
if (prefsService.showStreaks)
  StatisticItem(
    label: 'Current Streak',
    value: '$streak days',
    icon: Iconsax.flash,
  ),
```

## User Flow

### First-Time User

1. User signs up/logs in
2. `AuthPage` checks `hasCompletedModeSelection` (false for new users)
3. Shows `UsageModeSelectionPage`
4. User selects their preferred mode
5. Mode is saved and `hasCompletedModeSelection` set to true
6. User continues to plan creation

### Existing User

1. User navigates to Settings
2. Taps "Memorization Mode"
3. Sees current mode and can select a different one
4. Changes are saved immediately
5. App UI updates based on new mode

### Mode Changes

When a user changes modes:
- All data is preserved (no migrations needed)
- UI elements are shown/hidden based on new preferences
- Review scheduling behavior adjusts automatically
- Statistics remain accurate regardless of mode

## Feature Visibility Matrix

| Feature | Flexible | Intensive |
|---------|----------|-----------|
| Scheduled Reviews | ❌ | ✅ |
| Streak Counter | ❌ | ✅ |
| Missed Items Warnings | ❌ | ✅ |
| SM-2 Algorithm | ❌ | ✅ |
| Review Statistics | ❌ | ✅ |
| Priority Queues | ❌ | ✅ |
| Manual Quizzes | ✅ | ✅ |
| Progress Tracking | ✅ | ✅ |
| Achievements | Basic | Full |

## Technical Considerations

### Data Model

The system uses a **latent capability, dormant UI** approach:

- All data (reviews, streaks, statistics) is always collected and stored
- UI elements are shown/hidden based on user preferences
- Users can "upgrade" modes without losing any data
- No database migrations needed when switching modes

### State Management

- Uses Provider pattern for reactive updates
- `UserPreferencesService` extends `ChangeNotifier`
- UI rebuilds automatically when preferences change
- `Consumer` widgets wrap mode-dependent UI elements

### Persistence

- Uses `SharedPreferences` for local storage
- Preferences load asynchronously on app start
- Changes are persisted immediately
- No server-side synchronization needed

## Future Enhancements

### 1. Graduation Prompts

After X completed hifdhs in Flexible mode, show a gentle prompt:
```dart
if (completedHifdhs >= 10 && mode == UsageMode.flexible) {
  showDialog(...'Would you like to try gentle review reminders?'...);
}
```

### 2. Customizable Preferences

Allow users to mix-and-match features:
```dart
// Future: Could add granular settings for Intensive mode
if (mode == UsageMode.intensive) {
  // Show toggle for individual features
  - Enable/disable streaks
  - Enable/disable missed warnings
  - Adjust review frequency
}
```

### 3. Analytics

Track mode adoption and switching patterns:
- Which mode is most popular?
- How often do users switch modes?
- Correlation between mode and completion rates?

### 4. Smart Recommendations

Based on user behavior, suggest mode changes:
```dart
if (consistencyRate > 0.9 && mode == UsageMode.flexible) {
  // Suggest upgrading to Intensive
}
```

## Testing Checklist

- [ ] New users see mode selection after authentication
- [ ] Existing users don't see mode selection
- [ ] Mode selection saves correctly
- [ ] Settings page shows current mode
- [ ] Mode changes update UI immediately
- [ ] Reviews hidden in Flexible mode
- [ ] Streaks hidden in Flexible mode
- [ ] Celebrations adjust based on mode
- [ ] Data preserved when switching modes
- [ ] App doesn't crash when switching modes

## Troubleshooting

### Users Not Seeing Mode Selection

Check:
1. Is `UserPreferencesService` provided in `main.dart`?
2. Is the user authenticated?
3. Has `hasCompletedModeSelection` been set?

### UI Not Updating After Mode Change

Check:
1. Is the widget wrapped in a `Consumer<UserPreferencesService>`?
2. Is `notifyListeners()` called after mode change?
3. Is the correct preference property being checked?

### Mode Resets on App Restart

Check:
1. Is `SharedPreferences` properly initialized?
2. Are preferences being saved with correct keys?
3. Is `_loadPreferences()` called in constructor?

## Migration Guide

If you need to add mode-specific features:

1. **Add preference property** to `UserPreferencesService`
2. **Update `_applyModeDefaults()`** to set default for each mode
3. **Wrap UI element** in `Consumer<UserPreferencesService>`
4. **Check preference** before showing/hiding element

Example:
```dart
// 1. Add property
bool _showAdvancedStats = false;
bool get showAdvancedStats => _showAdvancedStats;

// 2. Update defaults
void _applyModeDefaults() {
  switch (_usageMode) {
    case UsageMode.intensive:
      _showAdvancedStats = true;
      break;
    default:
      _showAdvancedStats = false;
  }
}

// 3. Wrap UI
Consumer<UserPreferencesService>(
  builder: (context, prefs, child) {
    if (!prefs.showAdvancedStats) return SizedBox();
    return AdvancedStatsWidget();
  },
)
```

## Summary

The Usage Mode system provides a compassionate, flexible experience that adapts to different user needs. By using a "latent capability" approach, users can freely switch modes without losing data or progress. The implementation is clean, maintainable, and easily extensible for future features.
