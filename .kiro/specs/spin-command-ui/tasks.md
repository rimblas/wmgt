# Tasks

## Task 1: Update Spin Command Handler
- [x] 1.1 Remove the `difficulty` string option from the SlashCommandBuilder in `bots/src/commands/spin.js`
- [x] 1.2 Replace the `execute` method to reply with an ephemeral message containing a Button_Row with three buttons: "🎲 Any" (`spin_any`), "🟢 Easy" (`spin_easy`), "🔵 Hard" (`spin_hard`) and a prompt message
- [x] 1.3 Remove all course loading, filtering, selection, and embed logic from the command handler (this moves to SpinButtonHandler)

## Task 2: Create SpinButtonHandler Service
- [x] 2.1 Create `bots/src/services/SpinButtonHandler.js` with a `SpinButtonHandler` class that instantiates `SpinService` and a child logger
- [x] 2.2 Implement `handleSpin(interaction)` method that parses difficulty from `customId` (`spin_any` → `null`, `spin_easy` → `"Easy"`, `spin_hard` → `"Hard"`), loads courses, filters, selects random, and builds embed
- [x] 2.3 Add a selected-difficulty indicator to the Course_Embed footer showing "Random Any", "Random Easy", or "Random Hard" based on the clicked button
- [x] 2.4 Include Spin_Again_Buttons (same three custom IDs) in the result message alongside the Course_Embed
- [x] 2.5 On initial spin (from `/spin` prompt buttons): update the original message replacing prompt buttons with the Course_Embed and Spin_Again_Buttons
- [x] 2.6 On re-spin (from spin-again buttons): disable the buttons on the original message (preserving the Course_Embed) and send a new follow-up message with the new Course_Embed and fresh Spin_Again_Buttons
- [x] 2.7 Handle error cases: course data unavailable (error embed), empty filter results (warning embed), and unexpected errors (ErrorHandler)

## Task 3: Add Routing in index.js
- [x] 3.1 Import `SpinButtonHandler` in `bots/src/index.js`
- [x] 3.2 Instantiate `SpinButtonHandler` in the `DiscordTournamentBot` constructor
- [x] 3.3 Add routing in the existing component interaction handler to dispatch `spin_*` button interactions to `SpinButtonHandler.handleSpin`

## Task 4: Write Tests
- [x] 4.1 Write unit tests for the updated spin command (no options, replies with buttons)
- [x] 4.2 Write unit tests for `SpinButtonHandler.handleSpin` (difficulty mapping, spin flow, error paths)
- [x] 4.3 [PBT] Property 1: Difficulty mapping is total — *For any* valid spin button Custom_ID in `{spin_any, spin_easy, spin_hard}`, the mapping function produces a defined difficulty value
- [x] 4.4 [PBT] Property 2: Spin always returns a course from the filtered set — *For any* non-empty course list and any difficulty filter, filtering then selecting always returns a valid course from the filtered set
