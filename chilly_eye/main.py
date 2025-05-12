import tkinter as tk
from threading import Thread
import time
import os
import sys
from pygame import mixer

# Default fallback interval
INTERVAL_MINUTES = 20.0  # Used only if setup is skipped or fails
custom_snooze = None
interval_minutes = None
root = None


def play_notification_sound():
    base_path = (
        sys._MEIPASS
        if getattr(sys, "frozen", False)
        else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    )
    sound_path = os.path.join(base_path, "notification.mp3")

    if not os.path.exists(sound_path):
        print(f"🔊 Sound file not found: {sound_path}")
        return

    mixer.init()
    mixer.music.load(sound_path)
    mixer.music.play()


def reminder_loop():
    global custom_snooze, interval_minutes

    print(f"⏳ Initial wait for {interval_minutes} minutes...")
    time.sleep(interval_minutes * 60)

    while True:
        popup_window = popup()
        popup_window.wait_window()  # 🛑 BLOCKS until popup is closed

        delay = custom_snooze if custom_snooze is not None else interval_minutes
        custom_snooze = None

        print(f"⏳ Waiting {delay} minutes before next reminder...")
        time.sleep(delay * 60)


def popup():
    global custom_snooze

    play_notification_sound()
    popup_win = tk.Toplevel()
    popup_win.title("Break Time!")
    popup_win.geometry("300x200")
    popup_win.attributes("-topmost", True)
    popup_win.focus_force()
    popup_win.lift()

    tk.Label(popup_win, text="Time for a quick break!", font=("Arial", 14)).pack(
        pady=10
    )

    def close_popup():
        popup_win.destroy()

    def snooze_popup():
        global custom_snooze
        try:
            val = float(snooze_entry.get())
            if val <= 0:
                raise ValueError
            custom_snooze = val
            print(f"😴 Snoozed for {val} minutes.")
        except ValueError:
            print("⚠️ Invalid snooze value.")
        close_popup()

    def exit_script():
        print("👋 Exiting.")
        root.destroy()  # Exits mainloop
        sys.exit()

    tk.Button(popup_win, text="Got it!", command=close_popup).pack(pady=5)

    frame = tk.Frame(popup_win)
    frame.pack(pady=5)
    tk.Label(frame, text="Snooze (min):").pack(side=tk.LEFT, padx=5)
    snooze_entry = tk.Entry(frame, width=5)
    snooze_entry.pack(side=tk.LEFT, padx=5)
    tk.Button(frame, text="Snooze", command=snooze_popup).pack(side=tk.LEFT, padx=5)

    tk.Button(popup_win, text="Exit", command=exit_script).pack(pady=5)
    snooze_entry.focus_set()

    return popup_win


def show_setup_window(root):
    setup = tk.Toplevel()
    setup.title("Set Reminder Interval")
    setup.geometry("300x150")
    setup.attributes("-topmost", True)
    setup.focus_force()
    setup.lift()

    tk.Label(setup, text="Set interval (minutes):", font=("Arial", 12)).pack(pady=10)

    entry = tk.Entry(setup, width=10)
    entry.pack(pady=5)
    entry.insert(0, "20")
    entry.focus_set()

    def start_reminder():
        global interval_minutes
        try:
            val = float(entry.get())
            if val <= 0:
                raise ValueError
            interval_minutes = val
            print(f"✅ Starting with interval: {interval_minutes} minutes.")
            setup.destroy()
            Thread(target=reminder_loop, daemon=True).start()
        except ValueError:
            print("⚠️ Invalid interval. Please enter a positive number.")

    tk.Button(setup, text="Start", command=start_reminder).pack(pady=10)


def main():
    global root
    print("🚀 20-20-20 break reminder...")

    root = tk.Tk()
    root.withdraw()

    show_setup_window(root)
    root.mainloop()


if __name__ == "__main__":
    main()
