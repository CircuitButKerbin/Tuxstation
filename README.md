# TuxStation
Bash script to convert the Windows version of Stationeers to Linux by swapping out the Unity player files for the Linux editions.
Uses tuxceil.dll to patch two methods in GameManager that try to import user32.dll, that tuxharmony.dll prefixes just return without calling the user32 methods.
You must run the game with run_bepinex.sh otherwise the GameManager will crash without user32.dll on start making the game unplayable. When this happens, the main menu exit button won't work.
Configuration is mostly self-explainatory in the top lines of convert.sh.
Not heavily tested - expect bugs.
Feel free to open an issue or PR if you have suggestions/fixes/improvements.