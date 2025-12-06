# Time Display Modes Feature

## Overview
This feature adds a global time display mode selector that allows users to view project time in different ways throughout the application. Users can toggle between viewing instance, daily, weekly, monthly, or complete project totals via a simple button in the app header.

## User Interface

### Time Mode Selector
- **Location**: App bar (top right corner)
- **Icon**: Clock icon (⏰)
- **Interaction**: Tap to open a popup menu with 5 display mode options
- **Visual Feedback**: Selected mode is indicated with a checkmark (✓)

### Available Display Modes

1. **Instance Mode**
   - Shows the duration of the currently active instance
   - Only displays time for the active project (others show 0)
   - Updates every 30 seconds for real-time tracking
   - Label: "Instance: Xh Ym"

2. **Day Mode**
   - Shows total time worked on each project today
   - Includes all completed instances that started today
   - Label: "Day: Xh Ym"

3. **Week Mode**
   - Shows total time worked on each project this week (Monday-Sunday)
   - Includes all completed instances from the current week
   - Label: "Week: Xh Ym"

4. **Month Mode**
   - Shows total time worked on each project this month
   - Includes all completed instances from the current month
   - Label: "Month: Xh Ym"

5. **Project Mode** (Default)
   - Shows the complete accumulated time for each project
   - This is the original behavior
   - Label: "Project: Xh Ym"

## Implementation Details

### Files Modified

1. **lib/models/time_display_mode.dart** (New)
   - Enum defining the 5 display modes
   - Provides label and description for each mode

2. **lib/providers/tracking_provider.dart**
   - Added `_timeDisplayMode` state variable
   - Added `setTimeDisplayMode()` method to change the mode
   - Added `getDisplayTimeForProject()` method to calculate time based on selected mode
   - Uses existing `getCurrentDuration()` for instance mode
   - Calls database service for day/week/month calculations

3. **lib/services/database_service.dart**
   - Added `getProjectMinutesForDate()` for day calculations
   - Added `getProjectMinutesInRange()` for week/month calculations
   - Both methods query the instances table with date filters
   - Only counts completed instances (endTime IS NOT NULL)

4. **lib/screens/home_screen.dart**
   - Added PopupMenuButton in AppBar actions
   - Menu shows all 5 modes with checkmark on selected mode
   - Calls `provider.setTimeDisplayMode()` when mode is selected

5. **lib/widgets/project_list.dart**
   - Changed from displaying `project.totalMinutes` directly
   - Now uses `FutureBuilder` to call `provider.getDisplayTimeForProject()`
   - For Instance mode with active project, uses `StreamBuilder` for live updates
   - Updated `_formatTime()` to include mode label
   - Extracted card building logic to `_buildProjectCard()` helper method

### Database Queries

#### Day Mode Query
```sql
SELECT SUM(durationMinutes) as total
FROM instances
WHERE projectId = ?
  AND endTime IS NOT NULL
  AND startTime >= ?  -- Start of day
  AND startTime < ?   -- End of day
```

#### Week/Month Mode Query
```sql
SELECT SUM(durationMinutes) as total
FROM instances
WHERE projectId = ?
  AND endTime IS NOT NULL
  AND startTime >= ?  -- Start of week/month
  AND startTime < ?   -- End of week/month
```

### Date Range Calculations

- **Day**: Start of day (00:00:00) to end of day (23:59:59)
- **Week**: Monday (start of current week) to Sunday (end of current week)
  - Uses `DateTime.weekday` to calculate start of week
- **Month**: 1st of current month to 1st of next month

## Behavior Notes

1. **Active Instance Updates**
   - In Instance mode, the active project's time updates every 30 seconds
   - Other modes don't update automatically (only on state changes)

2. **Empty Values**
   - Instance mode shows 0 for non-active projects
   - Day/Week/Month modes show 0 if no work was done in that period
   - Database queries return 0 when SUM is NULL

3. **State Persistence**
   - Selected mode is stored in memory (TrackingProvider)
   - Resets to "Project" mode when app restarts
   - Future enhancement: Could persist to SharedPreferences

4. **Performance**
   - Uses FutureBuilder to avoid blocking UI
   - Database queries are indexed on projectId
   - SUM aggregation is efficient for instance counts

## User Workflow

### Typical Usage Scenario

1. User opens the app (default: Project mode showing total time)
2. User taps the clock icon in the app bar
3. User selects "Day" mode to see today's progress
4. Project list updates to show only today's time for each project
5. User starts tracking a project
6. User switches to "Instance" mode to focus on current session
7. Active project time updates every 30 seconds
8. User ends the session
9. User switches back to "Project" mode to see overall totals

### Example Display Changes

**Project Mode (Default)**
```
Project A - Project: 10h 30m
Project B - Project: 5h 15m
Project C - Project: 0m
```

**Day Mode (Same Projects)**
```
Project A - Day: 2h 15m
Project B - Day: 1h 0m
Project C - Day: 0m
```

**Instance Mode (Project A Active)**
```
Project A - Instance: 0h 45m  (actively updating)
Project B - Instance: 0m
Project C - Instance: 0m
```

## Testing Recommendations

### Manual Testing Checklist

1. **Mode Selection**
   - [ ] Can open time mode menu from app bar
   - [ ] All 5 modes are displayed
   - [ ] Selected mode shows checkmark
   - [ ] Tapping a mode closes menu and updates display

2. **Instance Mode**
   - [ ] Shows 0 for all projects when no instance is active
   - [ ] Shows current duration for active project
   - [ ] Updates every 30 seconds
   - [ ] Shows 0 immediately after ending instance

3. **Day Mode**
   - [ ] Shows 0 for projects with no work today
   - [ ] Correctly sums all instances started today
   - [ ] Works correctly across midnight boundary

4. **Week Mode**
   - [ ] Week starts on Monday
   - [ ] Shows 0 for projects with no work this week
   - [ ] Correctly sums all instances from current week

5. **Month Mode**
   - [ ] Month starts on 1st
   - [ ] Shows 0 for projects with no work this month
   - [ ] Correctly sums all instances from current month

6. **Project Mode**
   - [ ] Matches the original total time behavior
   - [ ] Accumulates time from all instances

### Edge Cases to Test

- Switching modes while an instance is active
- Creating a new project in different modes
- Ending an instance and checking mode updates
- Projects with instances across multiple days/weeks/months
- Empty database (no projects or instances)
- Leap year February month calculations
- December to January month boundary

## Future Enhancements

1. **Persistent Mode Selection**
   - Save selected mode to SharedPreferences
   - Restore on app launch

2. **Custom Date Ranges**
   - "Last 7 Days" mode
   - "Last 30 Days" mode
   - Custom date picker for arbitrary ranges

3. **Additional Time Displays**
   - Year mode (current year total)
   - Yesterday mode
   - Last week/month modes

4. **Visual Indicators**
   - Chart/graph showing time distribution
   - Progress bars in each mode
   - Color coding for time thresholds

5. **Export by Mode**
   - Export day/week/month reports
   - Filter log files by selected mode

## Architecture Decisions

### Why These Modes?
- **Instance**: For focus on current work session
- **Day**: For daily planning and tracking
- **Week**: For sprint planning and weekly reviews
- **Month**: For billing and monthly reporting
- **Project**: For overall project management

### Why FutureBuilder?
- Prevents UI blocking during database queries
- Handles async nature of time calculations
- Provides loading states (though queries are fast)

### Why StreamBuilder for Instance Mode?
- Provides real-time updates every 30 seconds
- Matches behavior of ActiveTrackingPanel
- Minimal overhead (only for active project)

### Why Not Include Active Instance in Day/Week/Month?
- Active instances have no duration yet (endTime IS NULL)
- Only completed instances are counted
- Consistent with database architecture
- Users can switch to Instance mode to see current session
