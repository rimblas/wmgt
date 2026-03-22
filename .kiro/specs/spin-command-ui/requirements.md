# Requirements Document

## Introduction

The `/spin` command in the WMGT Discord bot randomly selects a Walkabout Mini Golf course. Currently it uses a slash command dropdown option for difficulty filtering. This feature replaces that dropdown with a button-based UI: the command replies with three buttons (Any, Easy, Hard), and clicking a button triggers the random course selection. A new `SpinButtonHandler` service handles button clicks, `SpinService` remains unchanged, and routing is added to `index.js`. Spin-again buttons are included in the result for re-spinning without re-typing the command.

## Glossary

- **Spin_Command**: The `/spin` Discord slash command that initiates the course selection flow
- **SpinButtonHandler**: The service that processes button click interactions originating from the spin command
- **SpinService**: The existing service responsible for loading courses, filtering by difficulty, selecting a random course, and building the result embed
- **Difficulty_Filter**: A value of `null` (any), `"Easy"`, or `"Hard"` used to filter the course list
- **Button_Row**: A Discord `ActionRowBuilder` containing one or more `ButtonBuilder` components
- **Course_Embed**: A Discord `EmbedBuilder` displaying the selected course name, code, difficulty, and image
- **Spin_Again_Buttons**: A set of three buttons displayed alongside the course result, allowing the user to re-spin without re-invoking the slash command
- **Custom_ID**: A string identifier on each Discord button used to route interactions (e.g., `spin_any`, `spin_easy`, `spin_hard`)
- **Interaction_Router**: The component interaction handler in `index.js` that dispatches button clicks to the appropriate handler

## Requirements

### Requirement 1: Display Difficulty Buttons

**User Story:** As a player, I want to see difficulty filter buttons when I run `/spin`, so that I can quickly choose a difficulty without typing or navigating a dropdown.

#### Acceptance Criteria

1. WHEN a user executes the `/spin` command, THE Spin_Command SHALL reply with an ephemeral message containing a Button_Row with three buttons labeled "🎲 Any", "🟢 Easy", and "🔵 Hard"
2. WHEN a user executes the `/spin` command, THE Spin_Command SHALL include a short prompt message above the buttons (e.g., "Pick a difficulty to spin a random course!")
3. THE Spin_Command SHALL NOT accept any slash command options (the previous `difficulty` string option is removed)

### Requirement 2: Handle Button Clicks

**User Story:** As a player, I want to click a difficulty button and immediately see a randomly selected course, so that the spin experience is fast and visual.

#### Acceptance Criteria

1. WHEN a user clicks a spin button, THE SpinButtonHandler SHALL map the Custom_ID to a Difficulty_Filter (`spin_any` → `null`, `spin_easy` → `"Easy"`, `spin_hard` → `"Hard"`)
2. WHEN a user clicks a spin button, THE SpinButtonHandler SHALL load courses via SpinService, filter by the mapped difficulty, select a random course, and build a Course_Embed
3. WHEN a user clicks a spin button, THE SpinButtonHandler SHALL update the original message by replacing the difficulty buttons with the Course_Embed and a set of Spin_Again_Buttons

### Requirement 3: Spin-Again Buttons

**User Story:** As a player, I want spin-again buttons on the result so that I can re-spin without re-typing `/spin`, while keeping the original result visible to prevent re-rolling abuse.

#### Acceptance Criteria

1. WHEN a course result is displayed, THE SpinButtonHandler SHALL include a Button_Row with three Spin_Again_Buttons using the same Custom_IDs (`spin_any`, `spin_easy`, `spin_hard`)
2. WHEN a user clicks a Spin_Again_Button, THE SpinButtonHandler SHALL disable the buttons on the original message (preserving the Course_Embed) and send a new follow-up message with the new Course_Embed and fresh Spin_Again_Buttons
3. THE original Course_Embed and its result SHALL remain visible and unmodified after a re-spin, ensuring previous spin results cannot be hidden or replaced

### Requirement 4: Route Spin Button Interactions

**User Story:** As a developer, I want spin button interactions routed to the SpinButtonHandler, so that the button clicks are processed by the correct handler.

#### Acceptance Criteria

1. WHEN a button interaction with a Custom_ID starting with `spin_` is received, THE Interaction_Router SHALL dispatch the interaction to SpinButtonHandler
2. THE Interaction_Router SHALL instantiate SpinButtonHandler during bot construction

### Requirement 5: Display Selected Difficulty in Result

**User Story:** As a player, I want the course result embed to indicate which difficulty option I selected (Random Any, Random Easy, or Random Hard), so that I can see at a glance what filter was used.

#### Acceptance Criteria

1. WHEN a spin result is displayed after clicking "🎲 Any", THE Course_Embed SHALL include the text "Random Any" in the embed footer or description to indicate the selected filter
2. WHEN a spin result is displayed after clicking "🟢 Easy", THE Course_Embed SHALL include the text "Random Easy" in the embed footer or description to indicate the selected filter
3. WHEN a spin result is displayed after clicking "🔵 Hard", THE Course_Embed SHALL include the text "Random Hard" in the embed footer or description to indicate the selected filter

### Requirement 6: Error Handling

**User Story:** As a player, I want clear error messages when something goes wrong during a spin, so that I know what happened and can retry.

#### Acceptance Criteria

1. IF SpinService fails to load course data, THEN THE SpinButtonHandler SHALL reply with an error embed stating "❌ Course Data Unavailable — Unable to load course data. Please try again later."
2. IF the filtered course list is empty, THEN THE SpinButtonHandler SHALL reply with a warning embed stating "🎰 No Courses Found — No courses match the selected difficulty."
3. IF an unexpected error occurs during button handling, THEN THE SpinButtonHandler SHALL reply with a generic error embed via the existing ErrorHandler utility
