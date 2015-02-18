import subprocess
import threading
import Tkinter as Tk
import ttk
from tkFileDialog import askopenfilename
from PIL import Image, ImageTk


class App:
    def __init__(self, master):
        frame = Tk.Frame(master)

        top_menu = Tk.Menu(master)
        file_menu = Tk.Menu(top_menu, tearoff=0)
        help_menu = Tk.Menu(top_menu, tearoff=0)

        logo_png = Image.open("winRATLoad_logo.png")
        logo_png = logo_png.resize((100, 100), Image.ANTIALIAS)
        logo = ImageTk.PhotoImage(logo_png)
        logo_label = ttk.Label(master, image=logo, text="winRATLoad",
                              compound=Tk.LEFT, font=("Helvetica", 24))

        file_label = ttk.Label(master, text="Selected File", font=("Helvetica", 13))
        self.file_entry = ttk.Entry(master, state=Tk.DISABLED)
        file_button = ttk.Button(master, text="Choose File...", command=self.select_file)

        device_label = ttk.Label(master, text="Selected Serial Device", font=("Helvetica", 13))
        device_entry_f = ttk.Frame(master)
        self.device_entry = ttk.Combobox(device_entry_f, height=1)

        program_button_f = ttk.Frame(master)
        program_button = ttk.Button(program_button_f, text="Program")

        seperator = ttk.Separator(master)
        
        results_var = Tk.StringVar()
        results_f = ttk.Frame(master)
        results = Tk.Message(results_f, textvariable=results_var, background="white")
        
        file_menu.add_command(label="Refresh Serial Devices",
                              command=self.refresh_serial_devices)
        file_menu.add_command(label="Exit", command=root.quit)
        top_menu.add_cascade(label="File", menu=file_menu)

        help_menu.add_command(label="About / License")
        top_menu.add_cascade(label="Help", menu=help_menu)
        
        master.config(menu=top_menu)

        logo_label.photo = logo

        self.refresh_serial_devices()
        
        logo_label.grid(row=0, columnspan=3)

        file_label.grid(row=1, column=0, sticky=Tk.E, pady="5")
        self.file_entry.grid(row=1, column=1, padx="10 0")
        file_button.grid(row=1, column=2, padx="10")

        device_label.grid(row=2, column=0, sticky=Tk.E, padx="10 0", pady="5")
        device_entry_f.grid(row=2, column=1, columnspan=2,
                            sticky=Tk.E+Tk.W, padx="10")
        self.device_entry.pack(fill=Tk.BOTH)

        program_button_f.grid(row=3, columnspan=3, rowspan=2,
                              sticky=Tk.E+Tk.W+Tk.N+Tk.S, padx="10", pady="5")
        program_button.pack(fill=Tk.BOTH)

        seperator.grid(row=5, columnspan=3)
        
        results_f.grid(row=6, columnspan=3, rowspan=5,
                       sticky=Tk.E+Tk.W+Tk.N+Tk.S, padx="10", pady="5")
        results.pack(fill=Tk.BOTH)


    def select_file(self):
        filename = askopenfilename().strip()
        
        self.file_entry.delete(0, Tk.END)
        self.file_entry.insert(0, filename)


    def refresh_serial_devices(self):
        def run():
            proc = subprocess.Popen(
                ["./winRATLoad", "-l"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT
            )
            proc.wait()
            self.device_entry.delete(0, Tk.END)
            for device in proc.stdout.readlines():
                self.device_entry.insert(Tk.END, device.strip())
            return

        thread = threading.Thread(target=run)
        thread.start()

        return thread


root = Tk.Tk()
app = App(root)

root.resizable(width=Tk.FALSE, height=Tk.FALSE)
root.geometry("{}x{}".format(415, 630))
root.wm_title("winRATLoad")

root.mainloop()
