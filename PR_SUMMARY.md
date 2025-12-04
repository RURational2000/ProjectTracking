# Pull Request Summary: Time Display Mode Selector

## Issue
**Title:** Add global selectable displayed Total Time per project
**Description:** "Total:" time should display by instance, day, week, month, or complete project depending on what is selected in the in the Project Tracking header.

## Solution Overview
Implemented a global time display mode selector accessible from the app header that allows users to view project time in 5 different ways:

1. **Instance Mode** - Shows current active instance duration (live updates every 30s)
2. **Day Mode** - Shows total time worked today on each project
3. **Week Mode** - Shows total time worked this week (Monday-Sunday)
4. **Month Mode** - Shows total time worked this month
5. **Project Mode** - Shows complete accumulated time (default, original behavior)

## User Experience

### UI Changes
- **Clock icon (⏰)** added to app bar (top-right corner)
- Tapping icon opens popup menu with 5 mode options
- Selected mode indicated with checkmark (✓)
- Time labels update to show mode: "Day: 2h 15m", "Week: 8h 45m", etc.

### Interaction Flow
1. User taps clock icon
2. Menu appears with 5 options
3. User selects desired mode
4. Project list updates to show time in selected mode
5. Selection persists until changed (in-memory, resets on app restart)

## Technical Implementation

### Files Created
1. **lib/models/time_display_mode.dart** (39 lines)
   - Enum defining 5 display modes
   - Label and description getters for each mode

2. **FEATURE_TIME_DISPLAY_MODES.md** (255 lines)
   - Complete feature documentation
   - Implementation details
   - Testing recommendations
   - Future enhancement ideas

3. **UI_MOCKUP.md** (183 lines)
   - Text-based UI mockups
   - Shows all 5 modes visually
   - Interaction examples

### Files Modified

1. **lib/providers/tracking_provider.dart** (+56 lines)
   - Added `_timeDisplayMode` state variable (default: Project)
   - Added `setTimeDisplayMode()` to change mode
   - Added `getDisplayTimeForProject()` to calculate time based on mode
   - Added `_getWeekBounds()` and `_getMonthBounds()` helper methods
   - Added `_DateBounds` helper class for date ranges

2. **lib/services/database_service.dart** (+42 lines)
   - Added `getProjectMinutesForDate()` for day calculations
   - Added `getProjectMinutesInRange()` for week/month calculations
   - Added `_extractTotalMinutes()` helper to reduce duplication
   - Both methods use SQL SUM() on completed instances

3. **lib/screens/home_screen.dart** (+25 lines)
   - Added `PopupMenuButton<TimeDisplayMode>` in AppBar actions
   - Menu shows all modes with checkmark on selected
   - Calls `provider.setTimeDisplayMode()` on selection

4. **lib/widgets/project_list.dart** (+52 lines, -26 lines)
   - Changed from displaying `project.totalMinutes` directly
   - Now uses `FutureBuilder` to call `provider.getDisplayTimeForProject()`
   - Instance mode uses `StreamBuilder` for live updates (30s interval)
   - Optimized: Instance mode calls `getCurrentDuration()` directly
   - Updated `_formatTime()` to include mode label
   - Extracted `_buildProjectCard()` helper method

### Database Queries Added

#### Day Mode
```sql
SELECT SUM(durationMinutes) as total
FROM instances
WHERE projectId = ?
  AND endTime IS NOT NULL
  AND startTime >= ?  -- Start of day (00:00:00)
  AND startTime < ?   -- End of day (23:59:59)
```

#### Week/Month Mode
```sql
SELECT SUM(durationMinutes) as total
FROM instances
WHERE projectId = ?
  AND endTime IS NOT NULL
  AND startTime >= ?  -- Start of period
  AND startTime < ?   -- End of period
```

### Date Range Logic

- **Day**: `DateTime(now.year, now.month, now.day)` to next day
- **Week**: Monday 00:00:00 to next Monday 00:00:00
  - Handles Monday edge case: `daysToSubtract = now.weekday == 1 ? 0 : now.weekday - 1`
- **Month**: 1st of month 00:00:00 to 1st of next month 00:00:00

## Code Quality & Review

### All Review Feedback Addressed ✓

1. **Type Safety**
   - Added `<void>` type parameter to StreamBuilder
   - All type parameters properly specified

2. **Edge Cases**
   - Fixed Monday week calculation (avoid negative Duration)
   - Added null check for `project.id`
   - Added empty result check in database queries

3. **Code Organization**
   - Refactored duplicate null-check code into `_extractTotalMinutes()`
   - Extracted week/month calculations into helper methods
   - Created `_DateBounds` class for better organization

4. **Performance**
   - Optimized Instance mode: calls `getCurrentDuration()` directly
   - Removed nested FutureBuilder in StreamBuilder
   - Efficient database queries with existing indexes

### Code Metrics
- **Total lines added**: ~214
- **Total lines removed**: ~57
- **Net change**: +157 lines
- **Files changed**: 7 (3 new, 4 modified)
- **Commits**: 6

## Testing Recommendations

### Manual Testing Checklist
Since Flutter is not available in the build environment, the following should be tested manually:

#### Mode Selection
- [ ] Clock icon visible in app bar
- [ ] Popup menu opens on tap
- [ ] All 5 modes displayed
- [ ] Selected mode shows checkmark
- [ ] Tapping mode closes menu and updates display

#### Instance Mode
- [ ] Shows 0 for all projects when no instance active
- [ ] Shows live duration for active project
- [ ] Updates every 30 seconds
- [ ] Shows 0 immediately after ending instance

#### Day Mode
- [ ] Shows 0 for projects with no work today
- [ ] Correctly sums instances started today
- [ ] Works across midnight boundary

#### Week Mode
- [ ] Week starts on Monday
- [ ] Shows 0 for projects with no work this week
- [ ] Correctly sums all instances from current week

#### Month Mode
- [ ] Month starts on 1st
- [ ] Shows 0 for projects with no work this month
- [ ] Correctly sums all instances from current month

#### Project Mode
- [ ] Matches original total time behavior
- [ ] Accumulates time from all instances

### Edge Cases to Test
- Switching modes while instance is active
- Creating new project in different modes
- Ending instance and checking mode updates
- Projects with instances across multiple periods
- Empty database (no projects)
- Month boundary (Dec → Jan)
- Leap year February

## Future Enhancements

### Short Term
- Persist selected mode to SharedPreferences
- Add tooltip descriptions to mode menu items
- Add visual indicator of current mode in app bar

### Medium Term
- Custom date range picker
- "Last 7 Days" and "Last 30 Days" modes
- "Yesterday" and "Last Week" modes
- Export reports filtered by mode

### Long Term
- Charts showing time distribution by mode
- Progress bars/goals per mode
- Color coding for time thresholds
- Weekly/monthly summaries

## Deployment Notes

### No Breaking Changes
- All changes are additive
- Default mode is "Project" (existing behavior)
- Existing data structure unchanged
- No database migrations required

### Backwards Compatibility
- Old code paths still work
- New features are opt-in via UI
- No API changes

### Performance Impact
- Minimal: Only executes queries when mode is active
- Database queries use existing indexes
- Instance mode optimized to avoid database calls

## Documentation

All documentation is comprehensive and ready for users:

1. **FEATURE_TIME_DISPLAY_MODES.md** - Complete technical documentation
2. **UI_MOCKUP.md** - Visual representation of UI states
3. **Code comments** - Clear documentation in all modified files
4. **This summary** - Overview and testing guide

## Screenshots

Unfortunately, Flutter is not available in the build environment, so screenshots cannot be provided. However, the UI_MOCKUP.md file provides detailed text-based representations of all UI states.

The repository owner should:
1. Test the feature manually
2. Take screenshots of:
   - Clock icon in app bar
   - Popup menu with all 5 modes
   - Project list in each mode
   - Live updates in Instance mode
3. Add screenshots to the PR for review

## Conclusion

This implementation successfully addresses the issue requirements:

✅ **Simple button press** - Clock icon with popup menu  
✅ **Adjust displayed time** - 5 selectable modes  
✅ **Instance time added** - Instance mode shows current duration  
✅ **Minimal changes** - Surgical updates to existing code  
✅ **High quality** - All review feedback addressed  
✅ **Well documented** - Comprehensive documentation provided  
✅ **Performance optimized** - Efficient queries and rendering  

The feature is ready for manual testing and merging pending successful verification.
