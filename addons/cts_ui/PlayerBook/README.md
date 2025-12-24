# PlayerBook UI System

A modular, data-driven UI system for displaying player information in a "Book" format with tabs.

## Features

- **Unified Container**: `PlayerBook` manages visibility and input for all tabs.
- **Generic Pages**: `SkillsPage` and `InventoryPage` are driven by configuration resources, making them reusable across different games.
- **Signal-First**: All updates are driven by signals from the `EventBus` or `AffixSignalRegistry`.
- **Theming**: Apply a Theme to the `PlayerBook` root to style all pages automatically.

## Usage

1.  **Instantiate**: Add `PlayerBook.tscn` to your main UI canvas layer.
2.  **Configure**:
    - Add child pages (e.g., `SkillsPage.tscn`, `AffixPage.tscn`) to the `PlayerBook` node.
    - For `SkillsPage`, create a `StatPageConfig` resource and assign it to the `config` export.
3.  **Setup**:
    - In your game's initialization (e.g., Main Level script), call `player_book.setup(EventBus, PlayerNode)`.
    - Ensure your Player node has the components expected by the pages (e.g., "Stats", "AffixContainer").

## Creating New Pages

1.  Inherit from `BookPage`.
2.  Override `setup(event_bus, data_provider)`.
3.  Implement your UI logic using signals.
