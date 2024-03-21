# FlushHotkeys
Some useful hotkeys for [Balatro](https://store.steampowered.com/app/2379780/Balatro). Requires [Steamodded](https://github.com/Steamopollys/Steamodded).

## Hotkeys
| Key | Use                              |
| :-: | -------------------------------- |
| `F` | Select cards with the same suit. |
| `D` | Select full houses, four of a kinds etc. |
| `S` | Invert selected cards.           |

Pressing the hotkeys multiple times cycles through the options.
## Installation
Follow instructions from [here](https://github.com/Steamopollys/Steamodded?tab=readme-ov-file#how-to-install-a-mod).

## Configuration
If you want to, for example change flush hotkey to `Q`, open the `FlushHotkeys.lua` file with notepad and change the
```lua
local flush_hotkey = "f"
```
line into:
```lua
local flush_hotkey = "q"
```

For mouse buttons, change `local mouse_flush_hotkey = 400` into `local mouse_flush_hotkey = 3` which sets the hotkey into Middle Mouse Button. If you have a custom 4th button change it to `4` etc. This does not unbind the corresponding keyboard hotkey.
## Contributing
Feature and pull requests are welcome.

## License

[MIT](https://choosealicense.com/licenses/mit/)