# Jetpack Plus
[![Build Status](https://travis-ci.org/CrimsonTautology/sm_jetpack_plus.svg?branch=master)](https://travis-ci.org/CrimsonTautology/sm_jetpack_plus)

Rewrite of the Sourcemod plugin to make it easier to extend and modify.  Allows players to fly around while hold down their jump key.

##Installation
* Compile plugins with spcomp (e.g.)
> spcomp addons/sourcemod/scripting/jetpack_plus.sp
> spcomp addons/sourcemod/scripting/jetpack_bling.sp
* Move compiled .smx files into your `"<modname>/addons/sourcemod/plugins"` directory.

    

##Requirements
* [Donator Interface](https://forums.alliedmods.net/showthread.php?t=145542)(Optional)

#CVARs

* `sm_jetpack` - Set to 1 to enable this plugin, 0 to disable
* `sm_jetpack_force` - Strength at which the jetpack pushes the player.
* `sm_jetpack_jump_delay` - The time in seconds the jump key needs to be pressed before the jetpack starts.

# Usage

* There is no longer a need for a player to bind a key to +sm_jetpack.  To use the jetpack just hold down the jump key.
* If the bling plugin is installed donators can change their jetpack effects via the donator menu.

