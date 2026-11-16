<pre>
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
                                                 ......

</pre>

# rest.

A custom, reactive ASCII homepage for Firefox featuring animated backgrounds, time-based greetings, a digital clock, and a fully functional search bar with custom bookmarks.

![Demo of rest.](assets/examples.gif)

## Features

- **Dynamic ASCII Background**: Rotates through 20+ curated ASCII scenes from ascii.rest every time you restart your browser.
- **Time-based Greetings**: A dynamic ASCII banner that changes based on the time of day (morning, afternoon, evening, night).
- **Digital Clock**: A precise ASCII clock synchronized with your system time.
- **Smart Search Bar**: Search the web or enter a URL directly. Supports Brave, Google, and DuckDuckGo.
- **Custom Bookmarks**: Add, edit, and remove your favorite sites. Bookmarks are saved locally and displayed as beautiful ASCII circles with the site's favicon.
- **No Extensions Required**: Runs entirely on a local Python server. No browser extensions, no telemetry, no bloat.

## Credits & Acknowledgments

The vast majority of the visual resources in this project, including the ASCII art generation engine, the animated scenes, the digital clock, the banner text generator, and the core layout styles, were fetched from [ascii.rest](https://ascii.rest). Without their incredible work, this project would not exist.

Original programming for this project is limited to:
- The custom search bar logic and engine selector.
- The bookmark system (adding, editing, removing, and displaying icons via localStorage).
- The cross-platform installation and server management scripts.

## Quick Start

The easiest way to get `rest.` running is to use the automated installer for your operating system.

### Prerequisites

- **Python 3** installed on your system (Linux/macOS usually have it pre-installed; on Windows, download it from python.org and make sure to check "Add Python to PATH").
- **Firefox** (or any modern browser).

### Installation

1. Clone the repository (or download it as a ZIP and extract it):

```bash
git clone https://github.com/SadFighter/rest..git
cd rest.
```

2. Run the installer for your OS:

**Linux:**

```bash
chmod +x install-linux.sh
./install-linux.sh
```

**macOS:**

```bash
chmod +x install-macos.sh
./install-macos.sh
```

**Windows:**

Open PowerShell as Administrator (right-click the Start menu -> Terminal (Admin)), navigate to the folder, and run:

```powershell
.\install-windows.ps1
```

3. Follow the on-screen menu. Select `1) Install rest.`. The script will:
   - Set up a background server that starts automatically when you log in.
   - Map `rest.home` to your local machine in the `hosts` file.
   - Launch the server.

4. Open Firefox and go to:

```text
http://rest.home:8000
```

5. *(Optional)* Set `http://rest.home:8000` as your Firefox Homepage or New Tab page in Firefox Settings.

## The Installer Menu

The installers include a simple terminal UI to manage the server without touching the command line again:

- `1) Install`: Sets up the server and hosts file.
- `2) Start`: Starts the server if it's stopped.
- `3) Stop`: Stops the server (useful if you want to free up the port).
- `4) Status`: Checks if the server is currently running.
- `5) Uninstall`: Completely removes the server, the startup script, and the `rest.home` mapping from your system.

## Usage & Customization

- **Adding a Bookmark**: Click the `+` icon under the search bar. Enter the URL and the name. You can also upload a custom icon (or leave it blank to use the site's favicon).
- **Editing/Removing a Bookmark**: Hover over a bookmark and click the three dots icon. You'll see options to edit the URL, edit the name, edit the icon, or remove it.
- **Changing the Background Scene**: The background changes automatically every time you restart Firefox. If you want to add or remove scenes, edit the `SCENE` array inside `index.html`.

## Project Structure

```text
rest./
  index.html          # The main homepage (HTML, CSS, JS)
  install-linux.sh    # Interactive installer for Linux
  install-macos.sh    # Interactive installer for macOS
  install-windows.ps1 # Interactive installer for Windows
  assets/             # Folder for images and the demo GIF
  README.md           # This file
```

## Troubleshooting

- **"Python not found"**: Make sure Python 3 is installed and added to your system's PATH.
- **"Permission denied" (Linux/macOS)**: Run `chmod +x install-*.sh` before executing the scripts.
- **The page doesn't load**: Make sure the server is running by executing the installer and selecting `4) Status`. Also, verify that no other application is using port 8000.
- **Windows Admin Error**: The Windows script modifies system files (the hosts file and Task Scheduler), so it must be run in an Administrator PowerShell window.

## License

This project is licensed under the MIT License. Feel free to fork, modify, and build upon it.
