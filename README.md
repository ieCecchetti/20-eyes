# Chilly Eye - Break Reminder Application

Chilly Eye is a simple break reminder application built with Python and Tkinter. It helps you take regular breaks by showing a popup at specified intervals. The application supports snoozing and allows you to customize the snooze duration.

## The 20-20-20 Rule

Chilly Eye is designed to help you follow the 20-20-20 Rule, which is a simple guideline to reduce eye strain caused by prolonged screen time:

Every 20 minutes, take a 20-second break.
Look at something 20 feet away.
This rule helps relax the eye muscles and prevent digital eye strain, making it an essential practice for those who spend long hours in front of screens.

## Features

- Displays a popup to remind you to take a break.
- Follows the 20-20-20 Rule:
  - Every 20 minutes, take a 20-second break.
  - Look at something 20 feet away to reduce eye strain.
- Allows snoozing for a custom duration.
- Includes an "Exit" button to close the application.
- Configurable interval between reminders.

## Installation and Usage

## 1. Clone the Repository

Clone the repository to your local machine:

```bash
git clone <repository-url>
cd chilly_eye
```

## 2. Install Dependencies

Install the required dependencies using Poetry:

```bash
poetry install
```

## 3. Building the Executable

1. Prepare the Icon
Before building the executable, convert your icon image (alarm.png) to the required .icns format (for macOS) or .ico format (for Windows). Use the following command:

```bash
poetry run img-converter alarm.png alarm.icns
```

Then:
   - Replace `alarm.png` with the path to your source image;
   - The output file will be `alarm.icns`;

2. Build the Executable
Use PyInstaller to create the standalone executable:

```bash
poetry run pyinstaller --clean --onefile --windowed --icon=alarm.icns chilly_eye/main.py --noconfirm
```

- --clean: Clears PyInstaller's cache before building.
- --onefile: Packages everything into a single executable file.
- --windowed: Ensures the app runs without a terminal window.
- --icon=alarm.icns: Specifies the custom icon for the application.
- --noconfirm: Skips confirmation prompts during the build process.

The executable will be created in the dist folder.

## 4. Running the application

After executed the build..

### MacOS

Open the application using:

```bash
cd path/to/project
open dist/main.app
```

### Windows

Open the application using:

```bash
cd path/to/project
./dist/main
```

### Alternatively

Navigate to the `dist` folder and double-click the program to run it.

## Notes

Ensure you have the required Python version (^3.10) with tkinter installed.
The application icon must be in .icns format for macOS and .ico format for Windows.
If you encounter issues with the icon, ensure it is properly formatted and valid.