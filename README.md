# sm-jetpack-plus

![Build Status](https://github.com/CrimsonTautology/sm-jetpack-plus/workflows/Build%20plugins/badge.svg?style=flat-square)
[![GitHub stars](https://img.shields.io/github/stars/CrimsonTautology/sm-jetpack-plus?style=flat-square)](https://github.com/CrimsonTautology/sm-jetpack-plus/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/CrimsonTautology/sm-jetpack-plus.svg?style=flat-square&logo=github&logoColor=white)](https://github.com/CrimsonTautology/sm-jetpack-plus/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/CrimsonTautology/sm-jetpack-plus.svg?style=flat-square&logo=github&logoColor=white)](https://github.com/CrimsonTautology/sm-jetpack-plus/pulls)
[![GitHub All Releases](https://img.shields.io/github/downloads/CrimsonTautology/sm-jetpack-plus/total.svg?style=flat-square&logo=github&logoColor=white)](https://github.com/CrimsonTautology/sm-jetpack-plus/releases)

Rewrite of Knagg0 and naris's [jetpack plugin](https://forums.alliedmods.net/showthread.php?p=488779) for Sourcemod. Redesigned to make it easier to extend and modify.  Allows players to fly around while hold down their jump key.


## Requirements
* [SourceMod](https://www.sourcemod.net/) 1.10 or later


## Installation
Make sure your server has SourceMod installed.  See [Installing SourceMod](https://wiki.alliedmods.net/Installing_SourceMod).  If you are new to managing SourceMod on a server be sure to read the '[Installing Plugins](https://wiki.alliedmods.net/Managing_your_sourcemod_installation#Installing_Plugins)' section from the official SourceMod Wiki.

Download the latest [release](https://github.com/CrimsonTautology/sm-jetpack-plus/releases/latest) and copy the contents of `addons` to your server's `addons` directory.  It is recommended to restart your server after installing.

To confirm the plugin is installed correctly, on your server's console type:
```
sm plugins list
```

## Usage
There is no longer a need for a player to bind a key to +sm_jetpack.  To use the jetpack just hold down the jump key.


### Console Variables
| Command | Accepts | Values | Description |
| --- | --- | --- | --- |
| sm_jetpack | boolean | 0-1 | Set to 1 to enable this plugin, 0 to disable |
| sm_jetpack_force | float | any | Strength at which the jetpack pushes the player. |
| sm_jetpack_jump_delay | float | any | The time in seconds the jump key needs to be pressed before the jetpack starts. |


## Jetpack Bling
* Separate plugin to handle the sounds and particle effects; gives jetpacks their "bling"
* You can add your own!  Just edit `addons/sourcemod/configs/jetpacks.<modname>.cfg`
* The plugin will dynamicly load the config file for the corresponding game so you don't have to worry about incompatible sounds or particles.
* Players can choose their jetpack's effects by typing `!bling` into chat.


### Commands
NOTE: All commands can be run from the in-game chat by replacing `sm_` with `!` or `/`.  For example `sm_rtv` can be called with `!rtv`.

| Command | Accepts | Values | SM Admin Flag | Description |
| --- | --- | --- | --- | --- |
| sm_bling | None | None | None | Change jetpack's particle effects |


## Notes
* This has only been tested with TF2 but should work in other games, except...
* I have only made a bling config for TF2, you will have to create your own `addons/sourcemod/configs/jetpacks.<modname>.cfg` file for other games.  If you want to add some for other mods send a pull request.


## Compiling
If you are new to SourceMod development be sure to read the '[Compiling SourceMod Plugins](https://wiki.alliedmods.net/Compiling_SourceMod_Plugins)' page from the official SourceMod Wiki.

You will need the `spcomp` compiler from the latest stable release of SourceMod.  Download it from [here](https://www.sourcemod.net/downloads.php?branch=stable) and uncompress it to a folder.  The compiler `spcomp` is located in `addons/sourcemod/scripting/`;  you may wish to add this folder to your path.

Once you have SourceMod downloaded you can then compile using the included [Makefile](Makefile).

```sh
cd sm-jetpack-plus
make SPCOMP=/path/to/addons/sourcemod/scripting/spcomp
```

Other included Makefile targets that you may find useful for development:

```sh
# compile plugin with DEBUG enabled
make DEBUG=1

# pass additonal flags to spcomp
make SPFLAGS="-E -w207"

# install plugins and required files to local srcds install
make install SRCDS=/path/to/srcds

# uninstall plugins and required files from local srcds install
make uninstall SRCDS=/path/to/srcds
```


## Contributing
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


## License
[GNU General Public License v3.0](https://choosealicense.com/licenses/gpl-3.0/)


## Acknowledgements
* [Knagg0 and naris's original plugin](https://forums.alliedmods.net/showthread.php?p=488779)
* L. Duke's particle.inc
* [smlib](https://github.com/bcserv/smlib)
* [Flyflo's GoombaStomp plugin (majority of tags.inc)](https://github.com/Flyflo/SM-Goomba-Stomp)
