/**
 * vim: set ts=4 :
 * =============================================================================
 * Jetpack Plus
 *
 * Copyright 2014 CrimsonTautology
 * =============================================================================
 *
 */

#if defined _jetpack_plus_included_
    #endinput
#endif
#define _jetpack_plus_included_

public SharedPlugin __pl_jetpack_plus =
{
    name = "jetpack_plus",
    file = "jetpack_plus.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

/**
 * @brief Called right before a jetpack starts for a client
 *
 * @param client        The client for which this jetpack started for
 * @return              Plugin_Handled to stop the event, Plugin_Continue to modify.
 */
forward Action OnStartJetpack(int client);

/**
 * @brief Called right after a jetpack starts for a client
 *
 * @param client        The client for which this jetpack started for
 * @noreturn
 */
forward Action OnStartJetpackPost(int client);

/**
 * @brief Called right before a jetpack stops for a client
 *
 * @param client        The client for which this jetpack stopped for
 * @return              Plugin_Handled to stop the event, Plugin_Continue to modify.
 */
forward Action OnStopJetpack(int client);

/**
 * @brief Called right after a jetpack stops for a client
 *
 * @param client        The client for which this jetpack stopped for
 * @return              Plugin_Handled to stop the event, Plugin_Continue to modify.
 */
forward Action OnStopJetpackPost(int client);

/**
 * @brief Called each frame for which a jetpack is active for a client
 *
 * @param client        The client for which this jetpack is active for
 * @param force         (byref) push force applied to user by jetpack
 * @param force_stop    (byref) set to true to force the jetpack to stop
 * @noreturn
 */
forward Action OnJetpackStep(int client, float &force, bool &force_stop);

/**
 * @brief Check if the jetpack plugin is enabled
 *
 * @return      True if enabled, False otherwise
 */
native bool AreJetpacksEnabled();

/**
 * @brief Check if a client is currently using a jetpack
 *
 * @param client            Client to check
 * @return      True if using, else false
 */
native bool IsClientUsingJetpack(int client);
