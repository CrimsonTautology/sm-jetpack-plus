# Jetpack Plus
[![Build Status](https://travis-ci.org/CrimsonTautology/sm_jetpack_plus.svg?branch=master)](https://travis-ci.org/CrimsonTautology/sm_jetpack_plus)

Rewrite of Knagg0 and naris's [jetpack plugin](https://forums.alliedmods.net/showthread.php?p=488779) for Sourcemod. Redesigned to make it easier to extend and modify.  Allows players to fly around while hold down their jump key.

##Installation
* Compile plugins with spcomp (e.g.)
> spcomp addons/sourcemod/scripting/jetpack_plus.sp
> spcomp addons/sourcemod/scripting/jetpack_bling.sp
* Move compiled .smx files into your `"<modname>/addons/sourcemod/plugins"` directory.

    

# Jetpack

* There is no longer a need for a player to bind a key to +sm_jetpack.  To use the jetpack just hold down the jump key.
* `sm_jetpack` - Set to 1 to enable this plugin, 0 to disable
* `sm_jetpack_force` - Strength at which the jetpack pushes the player.
* `sm_jetpack_jump_delay` - The time in seconds the jump key needs to be pressed before the jetpack starts.

# Jetpack Bling
* Separate plugin to handle the sounds and particle effects; gives jetpacks their "bling"
* You can add your own!  Just edit `addons/sourcemod/configs/jetpacks.<modname>.cfg`
* The plugin will dynamicly load the config file for the corresponding game so you don't have to worry about incompatible sounds or particles.
* Players can choose their jetpack's effects by typing `!bling` into chat.

# Notes
* This has only been tested with TF2 but should work in other games, except...
* I have only made a bling config for TF2, you will have to create your own `addons/sourcemod/configs/jetpacks.<modname>.cfg` file for other games.  If you want to add some for other mods send a pull request.

