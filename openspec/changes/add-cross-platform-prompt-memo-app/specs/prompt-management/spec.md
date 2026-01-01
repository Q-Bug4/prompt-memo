## ADDED Requirements

### Requirement: Prompt Creation
The system SHALL allow users to create new prompts with title, content, and optional metadata.

#### Scenario: Create prompt with title and content
- **WHEN** user selects "Create New Prompt"
- **AND** enters a title and prompt content
- **THEN** the prompt is saved to local storage

#### Scenario: Create prompt with tags
- **WHEN** user adds one or more tags while creating a prompt
- **THEN** the tags are associated with the prompt for future filtering

### Requirement: Prompt Viewing and Editing
The system SHALL allow users to view and edit existing prompts with their result samples.

#### Scenario: View prompt details
- **WHEN** user selects a prompt from the list
- **THEN** the full prompt content, result sample, and metadata are displayed

#### Scenario: Edit prompt content
- **WHEN** user modifies prompt content and saves
- **THEN** the changes are persisted with a version history

### Requirement: Result Sample Management
The system SHALL allow users to save and organize result samples linked to prompts. Result samples are stored as files (txt, images, videos) in the local filesystem.

#### Scenario: Save text result sample
- **WHEN** user generates a text result from an AI model
- **AND** chooses to save it
- **THEN** the result is stored as a .txt file and linked to the originating prompt

#### Scenario: Save image result sample
- **WHEN** user generates an image result from an AI model
- **AND** chooses to save it
- **THEN** the result is stored as an image file and linked to the originating prompt

#### Scenario: Save video result sample
- **WHEN** user generates a video result from an AI model
- **AND** chooses to save it
- **THEN** the result is stored as a video file and linked to the originating prompt

#### Scenario: Multiple result samples
- **WHEN** a prompt has multiple saved results
- **THEN** all result files are accessible and timestamped

#### Scenario: View result file
- **WHEN** user selects a result sample
- **THEN** the file content is displayed based on its type (text preview, image, or video player)

### Requirement: Collection Organization
The system SHALL allow users to organize prompts into collections for better categorization.

#### Scenario: Create collection
- **WHEN** user creates a new collection
- **THEN** they can add prompts to this collection

#### Scenario: Move prompts between collections
- **WHEN** user moves a prompt to a different collection
- **THEN** the prompt's collection association is updated