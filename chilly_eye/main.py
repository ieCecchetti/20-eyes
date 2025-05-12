import tkinter as tk
from threading import Thread
import time
import os
import sys
from pygame import mixer


INTERVAL_MINUTES = 20
# Global variables to track the popup state
popup_open = False
current_popup = None  # Reference to the currently open popup
custom_snooze = None  # Custom snooze duration in minutes


def play_notification_sound():
    # Get the path to the notification.mp3 file
    if getattr(sys, "frozen", False):  # If running as a PyInstaller bundle
        base_path = sys._MEIPASS
    else:
        # Use the root directory of the project during development
        base_path = os.path.dirname(
            os.path.dirname(os.path.abspath(__file__))
        )  # Root directory
    sound_path = os.path.join(base_path, "notification.mp3")

    # Check if the file exists
    if not os.path.exists(sound_path):
        print(f"Error: Sound file not found at {sound_path}")
        return

    # Play the sound
    mixer.init()
    mixer.music.load(sound_path)
    mixer.music.play()


def reminder_loop(interval_minutes=20):
    global popup_open, current_popup, custom_snooze

    while True:
        # Wait for the interval
        print(f"⏳ Waiting for {interval_minutes} minutes...")
        time.sleep(interval_minutes * 60)

        # Show the popup and wait for user interaction
        popup_open = True
        custom_snooze = None  # Reset custom snooze
        show_popup()

        # Wait until the popup is closed
        while popup_open:
            time.sleep(1)

        # Use the custom snooze interval if set, otherwise use the default interval
        interval_minutes = (
            custom_snooze if custom_snooze is not None else INTERVAL_MINUTES
        )


def show_popup():
    global popup_open, current_popup, custom_snooze

    # Play the notification sound
    play_notification_sound()

    popup = tk.Toplevel()
    current_popup = popup  # Store the reference to the current popup
    popup.title("Break Time!")
    popup.geometry("300x200")
    popup.attributes("-topmost", True)  # Ensure the popup is always on top
    popup.wm_attributes("-topmost", True)  # Additional topmost setting
    popup.focus_force()  # Force focus on the popup
    popup.lift()  # Bring the popup to the front

    label = tk.Label(popup, text="Time for a quick break!", font=("Arial", 14))
    label.pack(pady=10)

    def close_popup():
        global popup_open, current_popup
        popup_open = False  # Reset the flag when the popup is closed
        current_popup = None  # Clear the reference to the popup
        popup.destroy()

    def snooze_popup():
        global custom_snooze
        try:
            snooze_minutes = int(snooze_entry.get())
            custom_snooze = snooze_minutes
            print(f"Snoozed for {snooze_minutes} minutes.")
        except ValueError:
            print("Invalid snooze value. Please enter a valid number.")
        close_popup()

    def exit_script():
        print("Exiting the script...")
        sys.exit()  # Exit the script

    btn_got_it = tk.Button(popup, text="Got it!", command=close_popup)
    btn_got_it.pack(pady=5)

    snooze_frame = tk.Frame(popup)
    snooze_frame.pack(pady=5)
    snooze_label = tk.Label(snooze_frame, text="Snooze in:")
    snooze_label.pack(side=tk.LEFT, padx=5)
    snooze_entry = tk.Entry(snooze_frame, width=5)
    snooze_entry.pack(side=tk.LEFT, padx=5)
    btn_snooze = tk.Button(snooze_frame, text="Snooze", command=snooze_popup)
    btn_snooze.pack(side=tk.LEFT, padx=5)

    btn_exit = tk.Button(popup, text="Exit", command=exit_script)
    btn_exit.pack(pady=5)


def main():
    print("⏰ Break reminder started. You'll be prompted every 20 minutes.")

    # Start the reminder loop in a separate thread
    Thread(target=reminder_loop, args=(INTERVAL_MINUTES,), daemon=True).start()

    # Create and run the hidden root window
    root = tk.Tk()
    root.withdraw()  # Keep root hidden
    root.mainloop()  # 🔁 Keeps app alive


if __name__ == "__main__":
    main()
