# Meowmux 🐱

Meowmux is a lightweight, TUI-based CLI project manager written in Zig (0.15.2). It simplifies workflow by allowing you to quickly manage and switch between projects, automatically launching them in `tmux` sessions.

## Features

- **Interactive TUI:** Navigate your project list with ease using Vim-style keys (`j`/`k`) or arrow keys.
- **Project Management:** Add, Edit, and Delete projects directly from the interface.
- **Tmux Integration:** Automatically creates or attaches to a named `tmux` session for the selected project.
- **Path Autocomplete:** **(New!)** Supports tab-completion for file paths when adding or editing projects.
- **Config persistence:** Safely stores your project list in `~/.config/meowmux/projects.json`.

## Prerequisites

- **Zig:** (Version 0.15.2 or later) Required to build the project.
- **Tmux:** Required to run the sessions.

## Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd meowmux
    ```

2.  **Build the project:**
    Navigate to the `app` directory and run the build command.
    ```bash
    cd app
    zig build -Doptimize=ReleaseSafe
    ```

3.  **Install the binary:**
    The executable will be located in `zig-out/bin/meowmux`. You can move this to a directory in your `$PATH` for easy access.
    ```bash
    cp zig-out/bin/meowmux ~/.local/bin/
    ```

## Usage

Run Meowmux from your terminal:

```bash
meowmux
```

### Main Menu Navigation

- **Navigation:** Use `Up`/`Down` arrows or `k`/`j` to scroll through the project list.
- **Select:** Press `Enter` to open the selected project in a tmux session.
- **Quit:** Press `q` or `Ctrl+C` to exit.

### Management Actions

From the main menu, use the following keys to manage your projects:

- **`o`**: Open mode (Default selection mode).
- **`a`**: **Add** a new project.
  - Enter the project Name.
  - Enter the project Path (Use `Tab` to autocomplete the path!).
- **`e`**: **Edit** the currently selected project.
  - Pre-fills existing values for easy modification.
  - Use `Tab` to autocomplete paths.
- **`d`**: **Delete** the currently selected project.

## Configuration

While Meowmux provides a UI for management, you can also manually edit the configuration.
Meowmux reads project information from a JSON file located at `~/.config/meowmux/projects.json`.

**Example `projects.json`:**
```json
[
  {
    "name": "meowmux",
    "path": "~/projects/meowmux"
  },
  {
    "name": "website",
    "path": "/var/www/html/my-website"
  }
]
```

## License

MIT
