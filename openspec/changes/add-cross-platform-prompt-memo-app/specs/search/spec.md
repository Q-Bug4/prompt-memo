## ADDED Requirements

### Requirement: Full-Text Search
The system SHALL provide full-text search across prompt titles, content, and result samples.

#### Scenario: Search by keyword
- **WHEN** user enters a search term
- **THEN** all matching prompts and results are returned ranked by relevance

#### Scenario: Search with multiple keywords
- **WHEN** user enters multiple search terms
- **THEN** prompts matching all terms appear first, followed by partial matches

### Requirement: Filter by Tags
The system SHALL allow filtering prompts by associated tags.

#### Scenario: Filter by single tag
- **WHEN** user selects a tag filter
- **THEN** only prompts with that tag are displayed

#### Scenario: Filter by multiple tags
- **WHEN** user selects multiple tags
- **THEN** prompts with ANY of the selected tags are shown

### Requirement: Filter by Collections
The system SHALL allow filtering prompts by collection membership.

#### Scenario: Filter by collection
- **WHEN** user selects a collection from the dropdown
- **THEN** only prompts in that collection are displayed

### Requirement: Advanced Search Filters
The system SHALL provide advanced filtering options for date ranges and metadata.

#### Scenario: Filter by creation date
- **WHEN** user selects a date range
- **THEN** only prompts created within that range are shown

#### Scenario: Filter by prompt usage
- **WHEN** user filters by "most used"
- **THEN** prompts are sorted by usage frequency

### Requirement: Search History
The system SHALL maintain a history of recent searches for quick access.

#### Scenario: View recent searches
- **WHEN** user clicks the search bar
- **THEN** recent searches are displayed as suggestions

#### Scenario: Repeat search
- **WHEN** user selects a recent search
- **THEN** the search is executed immediately