# fish-pdm

Fork of [fish-poetry](https://github.com/ryoppippi/fish-poetry) and modified for pdm.

Hooks into a change in PWD to automatically launch a [PDM](https://pdm-project.org) environment for your PDM project.

[![asciicast](https://asciinema.org/a/kO57JCdJTLte3A0457Sqf3yDP.svg)](https://asciinema.org/a/kO57JCdJTLte3A0457Sqf3yDP)

## Installation

| manager                                          | command                            |
| ------------------------------------------------ | ---------------------------------- |
| [fisher](https://github.com/jorgebucaran/fisher) | `fisher install 'Samoed/fish-pdm'` |

## Options
Optionally you can load environment variables from a `.env` file. To do so you must `set FISH_PDM_LOAD_ENV true`
