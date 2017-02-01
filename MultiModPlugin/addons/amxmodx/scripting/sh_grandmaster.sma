// GRANDMASTER! from marvel comics. One of the Elders of the Universe, has the power to to resurrect dead beings.
// Created 5/18/2003
// Hero Originally named Zeus, changed since powers did not fit.

/* CVARS - copy and paste to shconfig.cfg

//Grandmaster
gmaster_level 9
gmaster_cooldown 600		//# of seconds for Grandmaster cooldown

*/

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "Grandmaster"
new bool:gHasGrandmaster[SH_MAXSLOTS+1]
new const gSoundGmaster[] = "ambience/port_suckin1.wav"
new gPcvarCooldown
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Grandmaster", SH_VERSION_STR, "{HOJ} Batman/JTP10181")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("gmaster_level", "9")
	gPcvarCooldown = register_cvar("gmaster_cooldown", "600")

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "Revive Dead", "Utilize cosmic life force to Revive one Dead Teammate")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundGmaster)
}
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if ( gHeroID != heroID ) return

	gHasGrandmaster[id] = mode ? true : false

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED")
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	if ( sh_is_freezetime() ) {
		gPlayerInCooldown[id] = false
	}
	else {
		// dead Grandmaster's loose their revive power...
		gPlayerInCooldown[id] = true
	}
}
//----------------------------------------------------------------------------------------------
public sh_client_death(victim)
{
	if ( !sh_is_active() || !sh_is_inround() ) return
	if ( !is_user_connected(victim) || is_user_alive(victim) ) return

	new CsTeams:idTeam = cs_get_user_team(victim)

	new players[SH_MAXSLOTS], playerCount, player
	get_players(players, playerCount, "a")

	// Look for alive players with unused Grandmaster Powers on the same team
	for ( new i = 0; i < playerCount; i++ ) {
		player = players[i]
		if ( player != victim && gHasGrandmaster[player] && !gPlayerInCooldown[player] && idTeam == cs_get_user_team(player) ) {
			// We got a Grandmaster willing to raise the dead!
			new parm[2]
			parm[0] = victim
			parm[1] = player
			set_task(1.0, "gmaster_respawn", _, parm, 2)
		}
	}
}
//----------------------------------------------------------------------------------------------
public gmaster_respawn(parm[])
{
	if ( !sh_is_active() || !sh_is_inround() ) return

	new dead = parm[0]
	new gmaster = parm[1]

	if ( gPlayerInCooldown[gmaster] || !is_user_alive(gmaster) ) return
	if ( !is_user_connected(dead) || is_user_alive(dead) ) return
	if ( cs_get_user_team(dead) != cs_get_user_team(gmaster) ) return

	new Float:cooldown = get_pcvar_float(gPcvarCooldown)
	if ( cooldown > 0.0 ) sh_set_cooldown(gmaster, cooldown)

	emit_sound(gmaster, CHAN_STATIC, gSoundGmaster, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	new gmasterName[32], deadName[32]
	get_user_name(gmaster, gmasterName, charsmax(gmasterName))
	get_user_name(dead, deadName, charsmax(deadName))
	sh_chat_message(0, gHeroID, "%s used cosmic life force to Revive Dead Teammate %s!", gmasterName, deadName)

	//Respawns the player best available method
	ExecuteHamB(Ham_CS_RoundRespawn, dead)

	emit_sound(dead, CHAN_STATIC, gSoundGmaster, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	sh_set_rendering(dead, 255, 255, 0, 16, kRenderFxGlowShell)

	set_task(3.0, "gmaster_unglow", dead)
}
//----------------------------------------------------------------------------------------------
public gmaster_unglow(id)
{
	sh_set_rendering(id)
}
//----------------------------------------------------------------------------------------------