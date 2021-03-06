import subprocess
import threading
import tkinter as Tk
import tkinter.scrolledtext 
import tkinter.ttk as ttk
from tkinter.filedialog import askopenfilename
from PIL import Image, ImageTk


class App:
    def __init__(self, master):
        frame = Tk.Frame(master)

        top_menu = Tk.Menu(master)
        actions_menu = Tk.Menu(top_menu, tearoff=0)

        logo_png = Image.open("ratload_logo.png")
        logo_png = logo_png.resize((100, 100), Image.ANTIALIAS)
        logo = ImageTk.PhotoImage(logo_png)
        logo_label = ttk.Label(master, image=logo, text="ratload",
                               compound=Tk.LEFT, font=("Helvetica", 24))

        file_label = ttk.Label(master, text="Selected File",
                               font=("Helvetica", 13))
        self.file_var = Tk.StringVar()
        self.file_entry = ttk.Entry(master, state=Tk.DISABLED,
                                    textvariable=self.file_var)
        file_button = ttk.Button(master, text="Choose File...",
                                 command=self.select_file)

        device_label = ttk.Label(master, text="Selected Serial Device",
                                 font=("Helvetica", 12))
        device_entry_f = ttk.Frame(master)
        self.device_var = Tk.StringVar()
        self.device_entry = ttk.Combobox(device_entry_f, height=1,
                                         textvariable=self.device_var)

        program_button_f = ttk.Frame(master)
        program_button = ttk.Button(program_button_f, text="Program\n  Board",
                                    command=self.program_board)
        
        results_f = ttk.Frame(master)
        self.results = Tk.scrolledtext.ScrolledText(
            master=results_f,
            wrap=Tk.WORD,
            width=40
        )
        
        actions_menu.add_command(label="Refresh Serial Devices",
                              command=self.refresh_serial_devices)
        actions_menu.add_command(label="Run Serial Test",
                              command=self.run_serial_test)
        actions_menu.add_command(label="Clear Results Area",
                              command=self.clear_results)
        actions_menu.add_command(label="About / License",
                                 command=self.show_help)
        actions_menu.add_command(label="Exit", command=root.quit)
        top_menu.add_cascade(label="Menu", menu=actions_menu)
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

        results_f.grid(row=5, columnspan=3, rowspan=10,
                       sticky=Tk.E+Tk.W+Tk.N+Tk.S, padx="10", pady="5")
        results_f.grid_propagate(False)
        self.results.pack(fill=Tk.X)
        self.results.config(state=Tk.DISABLED)

        # self.results.config(state=NORMAL)
        # self.results.delete(1.0, END)
        # self.results.insert(END, text)
        # self.results.config(state=Tk.DISABLED)


    def show_help(self):
        pass


    def select_file(self):
        filename = askopenfilename().strip()

        self.file_var.set(filename)


    def _do_ratload(self, args):
        def run():
            proc = subprocess.Popen(
                ["./ratload_Windows_x86.exe"] + args,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT
            )
            while proc.poll() is None:
                byte = proc.stdout.read(1)
                self.append(byte)
            proc.wait()
            self.append(proc.stdout.read())

        thread = threading.Thread(target=run)
        thread.start()
        return thread


    def run_serial_test(self):
        self.append("Running Serial Test...\n")
        self._do_ratload(["-d", self.device_var.get(), "-t"])



    def program_board(self):
        self.append("Programming Board...\n")
        self._do_ratload(["-d", self.device_var.get(),
                          "-f", self.file_var.get()])


    def append(self, s):
        self.results.config(state=Tk.NORMAL)
        self.results.insert(Tk.END, s)
        self.results.config(state=Tk.DISABLED)

    def clear_results(self):
        self.results.config(state=Tk.NORMAL)
        self.results.delete(1.0, Tk.END)
        self.results.config(state=Tk.DISABLED)

    def refresh_serial_devices(self):
        def run():
            proc = subprocess.Popen(
                ["./ratload_Windows_x86", "-l"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT
            )
            proc.wait()
            self.device_entry.delete(0, Tk.END)
            devices = [i.strip().decode("utf-8") for i in
                       proc.stdout.readlines()]
            self.device_entry['values'] = devices
            if len(devices):
                self.device_entry.current(0)
            else:
                self.device_entry.insert(0, "__NO_DEVICES_FOUND__")
            return

        thread = threading.Thread(target=run)
        thread.start()

        return thread


root = Tk.Tk()
app = App(root)

version = open(".version", "r")

root.resizable(width=Tk.FALSE, height=Tk.FALSE)
root.geometry("{}x{}".format(410, 620))
root.wm_title("ratload_v" + version.read().strip())

root.mainloop()
