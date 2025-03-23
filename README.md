x16 PRos Kernel

x16 PRos is a simple 16-bit operating system written in NASM for x86 PCs. It includes a basic shell with commands for interaction, CPU info, file loading, and more.
Features:

    Shell with basic commands like help, info, cls, etc.

    CPU information display.

    Date and time functionality.

    Support for loading and executing programs from disk sectors.

    Simple programs like a clock, text editor, and Brainf IDE.

Commands:

    help - Get a list of available commands.

    info - Display information about the OS.

    cls - Clear the terminal.

    shut - Shut down the PC.

    reboot - Reboot the system.

    date - Display the current date.

    time - Display the current time.

    CPU - Display CPU information.

    load - Load a program from disk.

    clock - Start the clock program (disk sector 8).

    writer - Start a text editor (disk sector 9-10).

    brainf - Start a Brainf IDE (disk sector 12-13).


Compile:
    git clone https://github.com/PRoX2011/x16-PRos
    cd x16-PRos
    chmod +x build-linux.sh
    ./build-linux.sh
