# Grocy Pharo Client

An integrated desktop client for the Grocy household and organization ERP, implemented in Pharo Smalltalk. The application consolidates the management of recurring duties (Chores), one-time to-dos (Tasks), and the Shopping List inside a unified Spec2 tabbed dashboard.

## Features

* **Recurring Duties (Chores):** Lists cyclic chores with real-time tracking of remaining calendar days. Supports completion and skipping actions executed directly via the row context menu.
* **One-Time Tasks (Tasks):** Queries and displays open tasks exclusively. Supports closing tasks while properly transmitting the required ISO timestamp (`done_time`) to the Grocy API.
* **Shopping List:** Fully integrates with the generic Grocy Objects API (`/api/objects/shopping_list`). Features a local product cache that pulls all inventory items once to resolve nested foreign keys efficiently. Free-text notes lacking an explicit product relation are handled gracefully without breaking the payload parser. Supports deleting single rows as well as completely clearing the list.
* **User Interface & Filtering:** Implements a global real-time text filter that narrows down records across all three modules simultaneously. Column sorting (both alphabetical and numerical based on days remaining) is natively available by clicking the respective table headers.
* **Background Processing:** An asynchronous background process polls the server every 5 minutes. Critical or overdue deadlines trigger native operating system notifications (Windows via PowerShell/UTF-16LE encoding, macOS via AppleScript, Linux via notify-send) without freezing the UI thread. A stateful deduplication set prevents repetitive alerts for the same deadline.
* **Developer Tools:** Integrates a seamless hot-reload shortcut (`Ctrl + R` / `Cmd + R`) that captures the current window position and dimensions, terminates the active timers, and reinstantiates the interface state using the freshly compiled code.

## Installation

Execute the following Metacello script within a Pharo Playground to load the package and its baseline directly from GitHub:

```smalltalk
Metacello new
	repository: 'github://Nikoshi/grocy-chores:master';
	baseline: 'GrocyClient';
	load.
```

## Configuration and Startup

On its initial run, the application verifies the availability of an API key. If the class variable is unassigned, a native input prompt requests the token. The key is securely cached inside the image environment to skip future validation.

Launch the user interface using:

```smalltalk
GrocyChoreBrowser new open.
```

## Architecture and Integration

The project relies strictly on modular separation of concerns:
* **Domain Models:** `GrocyChore`, `GrocyTask`, and `GrocyShoppingItem` encapsulate the structural logic of incoming Grocy JSON payloads.
* **API Client:** `GrocyChoreClient` isolates HTTP transactions using Zinc Client and manages robust error handling for unexpected API schemas.
* **UI Interface:** `GrocyChoreBrowser` manages the Spec2 layout graph and delegates long-running tasks using background processes on the global `Processor`.

The framework registers itself with the system `SessionManager` for automated boot-up handling and utilizes the `<worldMenu>` pragma to append a launch item inside Pharo's desktop environment under the *Tools* category.
