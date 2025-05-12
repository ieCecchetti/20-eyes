import tkinter as tk
from threading import Thread
from queue import Queue, Empty
import time
import sys  # Import sys to exit the script


INTERVAL_MINUTES = 20  
# Global variables to track the popup state
popup_open = False
current_popup = None  # Reference to the currently open popup
custom_snooze = None  # Custom snooze duration in minutes


def background_loop(queue, interval_minutes=20):
    global custom_snooze

    while True:
        snooze_interval = custom_snooze if custom_snooze is not None else interval_minutes
        custom_snooze = None 
        print(f"⏳ Waiting for {snooze_interval} minutes until the next break...")
        time.sleep(snooze_interval * 60)
        print("🔔 Time to show popup!")
        queue.put("SHOW_POPUP")


def show_popup():
    global popup_open, current_popup, custom_snooze

    # If a popup is already open, close it
    if popup_open and current_popup is not None:
        current_popup.destroy()
        popup_open = False

    popup_open = True  # Set the flag to indicate a popup is open
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
        global popup_open, current_popup, custom_snooze
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


def check_queue(root, queue):
    try:
        message = queue.get_nowait()
        if message == "SHOW_POPUP":
            show_popup()
    except Empty:
        pass
    root.after(1000, check_queue, root, queue)


def main():
    print("⏰ Break reminder started. You'll be prompted every few seconds.")
    queue = Queue()

    # Start the background thread
    Thread(target=background_loop, args=(queue, INTERVAL_MINUTES), daemon=True).start()

    # Create and run the hidden root window
    root = tk.Tk()
    root.withdraw()  # Keep root hidden

    # Show the first popup instantly
    show_popup()

    # Start checking the queue for subsequent popups
    root.after(1000, check_queue, root, queue)
    root.mainloop()  # 🔁 Keeps app alive


if __name__ == "__main__":
    main()
