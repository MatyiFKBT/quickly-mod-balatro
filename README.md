# How to mod Balatro quickly and easily?

> [!WARNING]
> This guide is a work in progress and may contain errors. Please report any issues you find.

This repository meant to be a simple guide on how to mod Balatro. This guide will be updated as the game and modding tools evolve.

```sh
iwr -useb https://raw.githubusercontent.com/matyifkbt/quickly-mod-balatro/master/setup.ps1 | iex
```

![image](https://github.com/user-attachments/assets/dea0b65e-6a03-4285-9600-0580ab43b944)


## Background

I wanted to create a simple script that would allow me to easily install Lovely and Steamodded in order to mod the game, but I ended up creating a full-fledged tool that can be used to install some of my used mods too. I hope other modders will find it useful.

## Mods included

These mods can be installed/upgraded using the script:

| Mod                           | Description                             |
| ----------------------------- | --------------------------------------- |
| DorkDad141/keyboard-shortcuts | Many useful keyboard shortcuts          |
| nh6574/JokerDisplay           | Display useful information about Jokers |
| Balatro-Multiplayer/BalatroMultiplayer | Enable multiplayer functionality |

## Unmodding

If you want to remove installed mods and injector files, you can run the provided unmod script:

```sh
iwr -useb https://raw.githubusercontent.com/matyifkbt/quickly-mod-balatro/master/unmod.ps1 | iex
```

Flags:
- `-Force` Skip confirmation prompt.
- `-NoBackup` Do not create a timestamped backup of `%APPDATA%/Balatro/Mods`.
- `-Debug` Verbose internal logging.

After running, optionally verify integrity of game files in Steam for a fully clean install.

## Contributing

If you have any suggestions or improvements, feel free to open an issue.
