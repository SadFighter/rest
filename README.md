```text
                                                                          ---.
                                                                      .*@@#-
                                                                      .*@@#-
.:-----:    ..:---:        .-+###*=:            .-+**###*+=-      :-==+%@@%+=====-.
-#@@@@@@+=+%@@@@@@%-.   .=%@@@@@@@@@@#.       =@@@@@@@@@@@@@:    -@@@@@@@@@@@@@@@@-.
 .:=@@@%@@@%*+=-:.    :#@@%=.    :#@@%:     -@@@+                    :*@@%-.
 .:=@@@@@*-.         :*@@#-       :#@@*     :@@@@#=.                 .*@@#-
 .:=@@@#=.          .-@@@@@@@@@@@@@@@@#.     .+%@@@@@@@@#-.          .*@@#-
 .:=@@@+:.          .-%@@%+=----------.          .:-=*%@@@@+         .*@@#-
 .:=@@@+:.           :+@@@+:                           .#@@%:        .+@@%=.              .:=%@@@*:
:+*#%@@@%#***=:        :+@@@@%#*+===-        :#*++=====+%@@@+          -%@@@@%#*++-        .-%@@@@@#
+@@@@@@@@@@@@+.         .:=*%@@@@@@@*        +@@@@@@@@@@@#+:             -*%@@@@@@@-.       .+@@@@%=
                                                ........
```

# rest. - Nightly

[![Nightly](https://img.shields.io/badge/Channel-Nightly-orange?style=flat)](https://github.com/SadFighter/rest/tree/nightly)
[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python&logoColor=white)](https://www.python.org/)
[![Firefox](https://img.shields.io/badge/Firefox-Supported-FF7139?logo=firefox-browser&logoColor=white)](https://www.mozilla.org/firefox/)
[![Linux](https://img.shields.io/badge/Linux-Supported-FCC624?logo=linux&logoColor=black)](https://github.com/SadFighter/rest)
[![macOS](https://img.shields.io/badge/macOS-Supported-000000?logo=apple&logoColor=white)](https://github.com/SadFighter/rest)
[![Windows](https://img.shields.io/badge/Windows-Supported-0078D4?logo=windows&logoColor=white)](https://github.com/SadFighter/rest)
[![GitHub Stars](https://img.shields.io/github/stars/SadFighter/rest?style=flat&logo=github)](https://github.com/SadFighter/rest)

> [!WARNING]
> This is the **Nightly development branch** of rest. It contains the latest experimental changes and may be unstable. Bugs, incomplete features, and breaking changes are expected. Use at your own discretion.

A custom, reactive ASCII homepage for Firefox featuring animated backgrounds, time-based greetings, a digital clock, and a fully customizable search and bookmark system.

![Demo of rest.](assets/examples.gif)

## About

rest. transforms your browser's homepage into a dynamic, terminal-inspired experience.

The Nightly branch is where active development happens. It receives experimental features, interface changes, improvements, and fixes before they are considered ready for a stable release.

Things may change frequently, and not every commit is guaranteed to work as expected.

## Features

- **Dynamic ASCII Backgrounds** — Rotates through 20+ curated ASCII scenes from [ascii.rest](https://ascii.rest), providing a different visual experience whenever the browser starts.
- **Time-Based Greetings** — Displays dynamic ASCII banners that adapt to the time of day: morning, afternoon, evening, and night.
- **Digital Clock** — A live ASCII clock synchronized with your system time.
- **Smart Search** — Search the web or navigate directly to URLs. Supports Brave, Google, and DuckDuckGo.
- **Custom Bookmarks** — Add, edit, and remove bookmarks. Each bookmark is displayed as an ASCII circle with its corresponding favicon or custom icon.
- **Lightweight & Local** — Runs entirely through a local Python server. No browser extensions, telemetry, or unnecessary background services.

## Getting Started

### Requirements

- **Python 3** — Required to run the local server.
- **Firefox** — Recommended browser. Other modern browsers may also work.

### Installation

Clone the Nightly branch:

```bash
git clone -b nightly https://github.com/SadFighter/rest.git
cd rest
```

Run the installer for your operating system.

**Linux**
```bash
chmod +x install-linux.sh
./install-linux.sh
```

**macOS**
```bash
chmod +x install-macos.sh
./install-macos.sh
```

**Windows**

Open PowerShell as Administrator, navigate to the project directory, and run:

```powershell
.\install-windows.ps1
```

Follow the interactive menu and select `1) Install`.

The installer will:

1. Configure the local Python server.
2. Set up automatic startup when you log in.
3. Map `rest.home` to your local machine through the system hosts file.
4. Start the server.

Once installation is complete, open Firefox and navigate to:

```text
http://rest.home:8000
```

Optionally, set this address as your Firefox homepage or New Tab page.

## The Installer

The cross-platform installers provide an interactive terminal interface for managing the local server.

| Option | Description |
|---|---|
| `1) Install` | Installs and configures the server. |
| `2) Start` | Starts the server if it is not running. |
| `3) Stop` | Stops the server and releases port 8000. |
| `4) Status` | Checks the current server status. |
| `5) Uninstall` | Removes the server, startup configuration, and hosts mapping. |

## Usage & Customization

### Bookmarks

- **Add:** Click the `+` icon below the search bar.
- **Edit:** Hover over a bookmark and open its three-dots menu.
- **Remove:** Select the removal option from the bookmark menu.
- **Custom Icons:** Upload your own icon or let rest. retrieve the website's favicon automatically.

Bookmarks are stored locally using `localStorage`.

### Background Scenes

The background changes automatically whenever Firefox is restarted.

To customize the available scenes, modify the `SCENE` array inside `index.html`. Add, remove, or replace ASCII scenes to personalize your homepage.

## Nightly Development

This branch is updated as development progresses and serves as the testing ground for upcoming changes.

### What to Expect

- Experimental features and interface changes.
- Frequent fixes and improvements.
- Potential regressions and unexpected behavior.
- Features that may be incomplete or subject to removal.
- Changes that may not be documented immediately.

### Updating

To pull the latest Nightly changes:

```bash
git switch nightly
git pull origin nightly
```

**Note:** Updating the repository does not necessarily update an already installed server or its files. Follow the installer's update procedure, if available, or reinstall as appropriate.

### Reporting Issues

Found a bug or something that doesn't work as expected?

Open an issue on the [GitHub repository](https://github.com/SadFighter/rest/issues), preferably including:

- Your operating system.
- Your Python version.
- The steps required to reproduce the issue.
- Any relevant error messages or screenshots.

Reports from Nightly users are particularly useful for identifying regressions before stable releases.

## Project Structure

```text
rest/
├── index.html
├── install-linux.sh
├── install-macos.sh
├── install-windows.ps1
├── assets/
│   └── examples.gif
└── README.md
```

## Credits & Acknowledgments

A significant portion of rest.'s visual foundation comes from [ascii.rest](https://ascii.rest).

This includes the ASCII art generation engine, animated scenes, digital clock, banner text generator, and core layout styles.

Original development focuses primarily on:

- Custom search bar logic and search engine selection.
- Bookmark management, including adding, editing, removing, and displaying icons through `localStorage`.
- Cross-platform installation and local server management scripts.

Special thanks to the creators and contributors behind ascii.rest for making this project possible.

## Current Development

The Nightly branch is currently undergoing active development, with a focus on expanding user customization and localization.

### In Progress

- [ ] **Configuration Menu** — A dedicated settings interface allowing users to customize their rest. experience:
  - Choose their preferred ASCII scene cycle from the available scenes.
  - Change the interface language.
  - Switch between 12-hour and 24-hour clock formats.
  - Select their preferred browser.

  \<sub>Currently under development. The configuration menu is not yet fully functional and may temporarily interfere with bookmark functionality, including adding new bookmarks.\</sub>

### Planned

- [ ] **JSON-Based Configuration & Localization** - Introduce an extensible JSON configuration system to manage user preferences and language resources.
- [ ] **Community Translations** - Make localization easier to extend, allowing contributors to translate rest. into additional languages through dedicated JSON language files.

These features are planned for future Nightly iterations and are not included in the current release.

## Troubleshooting

| Issue | Solution |
|---|---|
| Python not found | Install Python 3 and ensure it is available in your system PATH. |
| Permission denied | Run `chmod +x install-*.sh` on Linux or macOS. |
| Homepage does not load | Check the server using `4) Status` in the installer. |
| Port 8000 already in use | Stop the application occupying the port before starting rest. |
| Windows administrator error | Run PowerShell as Administrator. The installer needs elevated permissions to modify the hosts file and configure startup tasks. |

## License

rest. is licensed under the [MIT License](https://opensource.org/licenses/MIT).

Feel free to fork, modify, experiment, and contribute.
