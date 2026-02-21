# Requirements Document

## Introduction

The Spin Command feature adds a `/spin` Discord slash command to the WMGT bot that randomly selects a Walkabout Mini Golf course. Players can spin for any course, or filter by difficulty (Easy or Hard). The course data is loaded from a structured JSON file maintained in the bot's data directory, with `docs/courses-list.md` serving as the source of truth.

## Glossary

- **Spin_Command**: The `/spin` Discord slash command that randomly selects a course
- **Course_Data_File**: A JSON file located at `bots/data/courses.json` containing all course information
- **Course**: A single playable course variant in Walkabout Mini Golf, identified by a short code, name, and difficulty
- **Course_Group**: A pair of related courses sharing the same theme, one Easy and one Hard variant
- **Course_Image_URL**: A URL to the course image, constructed as `https://objectstorage.us-ashburn-1.oraclecloud.com/n/idw1nygcxpvm/b/wmgt-assets/o/{CODE}_FULL.jpg` where `{CODE}` is the course short code
- **Difficulty_Filter**: An optional command parameter allowing the user to restrict the random selection to "Easy" or "Hard" courses
- **Course_Embed**: A Discord rich embed message displaying the selected course details
- **Bot**: The WMGT Discord bot application

## Requirements

### Requirement 1: Course Data File

**User Story:** As a bot developer, I want course data stored in a structured JSON file, so that the spin command can load and select courses without parsing markdown.

#### Acceptance Criteria

1. THE Course_Data_File SHALL contain an array of course objects, each with fields: code, name, and difficulty
2. THE Course_Data_File SHALL include all 74 courses (37 Easy and 37 Hard) matching the source of truth in `docs/courses-list.md`
3. WHEN the Course_Data_File is loaded, THE Bot SHALL parse the JSON into an in-memory array of course objects

### Requirement 2: Random Course Selection

**User Story:** As a player, I want to spin for a random course, so that I can get a fun and spontaneous course suggestion to play.

#### Acceptance Criteria

1. WHEN a user invokes the Spin_Command without a Difficulty_Filter, THE Spin_Command SHALL select one course uniformly at random from all available courses
2. WHEN a user invokes the Spin_Command with a Difficulty_Filter of "Easy", THE Spin_Command SHALL select one course uniformly at random from only Easy courses
3. WHEN a user invokes the Spin_Command with a Difficulty_Filter of "Hard", THE Spin_Command SHALL select one course uniformly at random from only Hard courses
4. WHEN a course is selected, THE Spin_Command SHALL return a course that exists in the Course_Data_File

### Requirement 3: Course Result Display

**User Story:** As a player, I want to see details about the randomly selected course, so that I know what course was picked and its key stats.

#### Acceptance Criteria

1. WHEN a course is selected, THE Spin_Command SHALL display a Course_Embed containing the course name, short code, and difficulty
2. WHEN a course is selected, THE Course_Embed SHALL use a visually distinct color based on difficulty (one color for Easy, another for Hard)
3. WHEN a course is selected, THE Course_Embed SHALL include the course image using the Course_Image_URL constructed from the course short code

### Requirement 4: Command Registration

**User Story:** As a player, I want the spin command available as a Discord slash command, so that I can invoke it easily from any channel.

#### Acceptance Criteria

1. THE Spin_Command SHALL be registered as a Discord slash command with the name "spin"
2. THE Spin_Command SHALL include an optional "difficulty" parameter with choices: "Easy" and "Hard"
3. THE Spin_Command SHALL include a description that communicates its purpose to users

### Requirement 5: Error Handling

**User Story:** As a player, I want clear feedback when something goes wrong, so that I understand the issue and can try again.

#### Acceptance Criteria

1. IF the Course_Data_File cannot be loaded or parsed, THEN THE Spin_Command SHALL reply with an error embed explaining that course data is unavailable
2. IF the filtered course list is empty after applying a Difficulty_Filter, THEN THE Spin_Command SHALL reply with a message indicating no courses match the filter
3. IF an unexpected error occurs during command execution, THEN THE Spin_Command SHALL log the error and reply with a generic error message
