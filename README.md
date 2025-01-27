# FlushHotkeys
Some useful hotkeys for [Balatro](https://store.steampowered.com/app/2379780/Balatro). Requires [Balamod](https://github.com/balamod/balamod) or [Steamodded](https://github.com/Steamopollys/Steamodded).

## Hotkeys
| Key | Use                              |
| :-: | -------------------------------- |
| `F`, `Scroll Down` | Select cards with the same suit. |
| `D`, `Scroll Up` | Select full houses, four of a kinds etc. |
| `S`, `Middle Mouse Button` | Invert selected cards. Tries to select "most discardable" cards. |

Pressing the hotkeys multiple times cycles through the options. There are also `Play Hand` and `Discard Hand` hotkeys which are unbound. Follow [configuration](#configuration) to set them.
## Installation
1. Download [this zip file.](https://github.com/Agoraaa/FlushHotkeys/archive/refs/heads/main.zip)
2. Drag the folder in the zip file to your mods folder.
3. Enjoy!

If you are using balamod, use the `balamod` folder instead.

## Configuration
If you want to, for example add additional hotkey `Q` for the flushes, open the `FlushHotkeys.lua` file with notepad and change the
```lua
local flush_hotkeys = {"f", "scrollup"}
```
line into:
```lua
local flush_hotkeys = {"f", "q"}
```

For mouse buttons, instead change `none` into `mouse3` which sets the hotkey into Middle Mouse Button. Custom 4th, 5th etc. mouse buttons are also supported. Use `none` to unbind hotkeys.

## Contributing
Pull requests are welcome. Also feel free to submit bug reports and feature requests.

## License

[MIT](https://choosealicense.com/licenses/mit/)