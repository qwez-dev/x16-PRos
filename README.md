# <center>x16-PRos</center>

![screenshot](https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/1.png)


**x16-PRos**
 is a minimalistic 16-bit operating system written in NASM for x86 architecture. It supports a text interface, loading programs from disk, and basic system functions such as displaying CPU information, time, and date.

---

## Supported commands in x16 PRos terminal
- **help** display list of commands
- **info** brief system information
- **cls** clear screen
- **shut** shut down the system
- **reboot** restart the system
- **date** display date
- **time** show time (UTC)
- **CPU** CPU information
- **load** load program from disk sector (0000x800h)
- **writer** start writer program
- **brainf** start brainf interpreter
- **barchart** start barchart program
- **snake** start Snake game
- **calc** start calculator program

---

## x16 PRos Software Package

Basic x16 PRos software package includes:

- **Notepad** for writing and saving texts to disk sectors
![screenshot](https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/3.png)

- **Brainf** IDE for working with Brainf*ck language
![screenshot](https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/4.png)

- **Barchart** program for creating simple diagrams
![screenshot](https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/5.png)

- **Snake** classic Snake game

![screenshot](https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/6.png)

- **Calc** help with simple mathematical calculations
![screenshot](https://github.com/PRoX2011/x16-PRos/raw/main/screenshots/7.png)


---
  
## Adding programs
x16 PRos includes a small set of built-in programs. You can add your own program to the system image and then run it using the load command, specifying the disk sector number where you wrote the program as an argument.

Here's how you can add a program:
```bash
dd if=YourProgram.bin of=disk_img/x16pros.img bs=512 seek=DiskSector conv=notrunc
```

You can read more about the software development process for x16-PRos on the project website:
[Web site](https://google.com)

---

## Launchng

To launch x16 PRos, use emulators such as **QEMU**,**Bochs** or online emulator like [v86](https://copy.sh/v86/). 
Example command for **QEMU**:
```bash
qemu-system-x86_64 -fda x16-PRos-disk-image.img
```
You can also try running x16-PRos on a **real PC** (preferably with BIOS, not UEFI)

If you still want to run x16-PRos on a UEFI PC, you will need to enable "CSM support" in your BIOS. It may be called slightly differently.

---

## x16-PRos Developers

- **PRoX (Faddey Kabanov)** lead developer. Creator of the kernel, command interpreter, writer, brainf, snake programs.
- **Loxsete** developer of the barchart program.
- **Saeta** developer of the calculation logic in the program "Calculator".

---

## Contribute to the Project

If you want to contribute to the development of x16 PRos, you can:

- Report bugs via GitHub Issues.
- Suggest improvements or new features on GitHub.
- Help with documentation by emailing us at prox.dev.code@gmail.com.
- Develop new programs for the system.

The project is distributed under the **MIT** license. You are free to use, modify and distribute the code.

---

