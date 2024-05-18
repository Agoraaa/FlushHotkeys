# FlushHotkeys
Some useful hotkeys for [Balatro](https://store.steampowered.com/app/2379780/Balatro). Requires [Balamod](https://github.com/balamod/balamod) or [Steamodded](https://github.com/Steamopollys/Steamodded).

## Hotkeys
| Key | Use                              |
| :-: | -------------------------------- |
| `F` | Select cards with the same suit. |
| `D` | Select full houses, four of a kinds etc. |
| `S` | Invert selected cards. Tries to select "most discardable" cards. |

Pressing the hotkeys multiple times cycles through the options. There are also `Play Hand` and `Discard Hand` hotkeys which are unbound. Follow [configuration](#configuration) to set them.
## Installation
Download the `FlushHotkeys.lua` file and then follow [balamod](https://github.com/balamod/balamod?tab=readme-ov-file#how-to-install-mods) or [steamodloader](https://github.com/Steamopollys/Steamodded?tab=readme-ov-file#how-to-install-a-mod) instructions.

## Scroll Wheel Mode
Use the `FlushHotkeys-scrollwheel.lua` file to enable using scroll wheel. This will **disable all other functionality** for the scroll wheel and isn't supported on balamod. It's fine for the base game but it will override any other scroll wheel feature added by other mods. 

| Key | Use                              |
| :-: | -------------------------------- |
| `Scroll Down` | Select cards with the same suit. |
| `Scroll Up` | Select full houses, four of a kinds etc. |
| `Middle Mouse Button` | Invert selected cards. Tries to select "most discardable" cards.|

## Configuration
If you want to, for example add additional hotkey `Q` for the flushes, open the `FlushHotkeys.lua` file with notepad and change the
```lua
local flush_hotkeys = {"f", "none"}
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