// ZEUS!
// Created 5/18/2003

/* CVARS - copy and paste to shconfig.cfg

//Zeus
zeus_level 9
zeus_cooldown 600				// # of seconds for zeus cooldown

*/

#include <amxmod>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Zeus"
new gBetweenRounds
new bool:gHasZeusPowers[SH_MAXSLOTS+1]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Zeus","1.18","{HOJ} Batman/JTP10181")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("zeus_level", "9" )
	register_cvar("zeus_cooldown", "600" ) // Just once!

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Raise Dead", "Will Automatically Raise One Fallen Teammate", false, "zeus_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_event("ResetHUD","zeus_newspawn","b")
	register_srvcmd("zeus_init", "zeus_init")
	shRegHeroInit(gHeroName, "zeus_init")

	// DEATH
	register_event("DeathMsg", "zeus_death", "a")

	// ROUND EVENTS
	register_logevent("round_start", 2, "1=Round_Start")
	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_end", 2, "1&Restart_Round_")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound("ambience/port_suckin1.wav")
}
//----------------------------------------------------------------------------------------------
public zeus_newspawn(id)
{
	if ( !hasRoundStarted() ) {
		gPlayerUltimateUsed[id] = false
	}
	else {
		gPlayerUltimateUsed[id] = true //dead zeus's loose their zeus...
	}
}
//----------------------------------------------------------------------------------------------
public zeus_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has wolverine skills
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	gHasZeusPowers[id] = (hasPowers != 0)

}
//----------------------------------------------------------------------------------------------
public zeus_death()
{
	new id = read_data(2)

	if ( gBetweenRounds || !shModActive() ) return
	if ( !is_user_connected(id) || is_user_alive(id) ) return

	new idteam = get_user_team(id)

	// Look for alive players with unused Zeus Powers on the same team
	for ( new player = 1; player <= SH_MAXSLOTS; player++ ) {
		if ( player != id && is_user_alive(player) && gHasZeusPowers[player] && !gPlayerUltimateUsed[player] && idteam == get_user_team(player) ) {
			// We got a Zeus character willing to raise the dead!
			new parm[2]
			parm[0] = id
			parm[1] = player
			set_task(0.2,"zeus_respawn", 0, parm, 2)
		}
	}
}
//----------------------------------------------------------------------------------------------
public zeus_respawn(parm[])
{
	new dead = parm[0]
	new zeus = parm[1]

	if (gPlayerUltimateUsed[zeus] || gBetweenRounds) return
	if ( !is_user_connected(dead) || !is_user_connected(zeus)) return
	if ( !is_user_alive(zeus) || is_user_alive(dead) ) return
	if ( get_user_team(dead) != get_user_team(zeus) ) return

	ultimateTimer(zeus, get_cvar_float("zeus_cooldown"))
	emit_sound(zeus, CHAN_STATIC, "ambience/port_suckin1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	new zeusName[32],deadName[32]
	get_user_name(zeus,zeusName,31)
	get_user_name(dead,deadName,31)
	client_print(0,print_chat,"%s used Zeus Powers to Raise Dead Team Member %s!", zeusName, deadName )

	//Double spawn prevents the no HUD glitch (hopefully)
	user_spawn(dead)
	user_spawn(dead)

	emit_sound(dead, CHAN_STATIC, "ambience/port_suckin1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	shGlow(dead,255,255,0)
	set_task(3.0, "zeus_unglow", dead)
	set_task(1.0, "zeus_teamcheck", 0, parm, 2)
}
//----------------------------------------------------------------------------------------------
public zeus_unglow(id)
{
	shUnglow(id)
}
//----------------------------------------------------------------------------------------------
public zeus_teamcheck(parm[])
{
	new dead = parm[0]
	new zeus = parm[1]

	if ( get_user_team(dead) != get_user_team(zeus) ) {
		client_print(dead,print_chat,"You changed teams and got Zeus respawned, now you shall die")
		user_kill(dead,1)
		gPlayerUltimateUsed[zeus] = false
	}
}
//----------------------------------------------------------------------------------------------
public round_start()
{
	gBetweenRounds = false
}
//----------------------------------------------------------------------------------------------
public round_end()
{
	gBetweenRounds = true
}
//----------------------------------------------------------------------------------------------