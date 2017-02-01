// Victim 15/21 - Joseph Schreiber
//Based on code from Phoenix and Kamikaze

/* CVARS copy and paste to shconfig.cfg

//Victim 15/21
vic15_level 10
vic15_revivetimer 5		//Time (in seconds) before Victim 15 is brought back
vic15_auradamage 15		//Damage dealt to an enemy in range of Victim15's
vic15_frequency 3		//How frequently aura damage is dealt (in seconds) to players in the aura's radius
vic15_auraradius 300		//Radius of Victim 15's ghostly aura

*/


#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

new g_heroName[]="Victim 15/21"
new bool:g_hasVic15[SH_MAXSLOTS+1]
new bool:g_vic15PowerUsed[SH_MAXSLOTS+1]
new bool:g_betweenRounds
new g_userTeam[SH_MAXSLOTS+1]
new g_savedOrigin[SH_MAXSLOTS+1][3]
new g_lastPosition[SH_MAXSLOTS+1][3]
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Victim15/21", "1", "World Crafter/[FTW]-S.W.A.T / vittu")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("vic15_level", "10")
	register_cvar("vic15_revivetimer", "5")
	register_cvar("vic15_auradamage", "15")
	register_cvar("vic15_aurafrequency", "3")
	register_cvar("vic15_auraradius", "300")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(g_heroName, "15th Sacrament", "Deal damage to enemies merely by standing near them and always come back to life. Be careful of triggered deaths!", false, "vic15_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("vic15_init", "vic15_init")
	shRegHeroInit(g_heroName, "vic15_init")

	// DEATH EVENT
	register_event("DeathMsg", "vic15_death", "a")

	// ROUND EVENTS
	register_logevent("round_start", 2, "1=Round_Start")
	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_end", 2, "1&Restart_Round_")

	set_task( get_cvar_float("vic15_aurafrequency"), "vic15_auraloop", 0, "", 0, "b")
	set_task( 1.0, "vic15_ringloop", 0, "", 0, "b")

}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound("misc/victim15_static.wav")
	precache_sound("misc/victim15_revive.wav")
}
//----------------------------------------------------------------------------------------------
public vic15_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has the hero
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	g_hasVic15[id] = (hasPowers != 0)
}
//----------------------------------------------------------------------------------------------
public vic15_death()
{
	if ( !shModActive() || g_betweenRounds ) return

	new id = read_data(2)

	if ( !is_user_connected(id) || !g_hasVic15[id] ) return

	g_userTeam[id] = get_user_team(id)

	// Save users origin on death
	get_user_origin(id, g_savedOrigin[id])
	g_savedOrigin[id][2] += 8

	// Look for self to raise from dead
	if ( !is_user_alive(id) && !g_vic15PowerUsed[id] ) {
		new parm[1]
		parm[0] = id
		// never set higher then 1.9 or lower then 0.5
		set_task(get_cvar_float("vic15_revivetimer"), "vic15_respawn", 0, parm, 1)
	}
}
//----------------------------------------------------------------------------------------------
public vic15_respawn(parm[])
{
	new id = parm[0]

	if ( !is_user_connected(id) || is_user_alive(id) ) return
	if ( g_vic15PowerUsed[id] || g_betweenRounds ) return
	if ( g_userTeam[id] != get_user_team(id) ) return //prevents respawning spectators

	// Double spawn prevents the no HUD glitch
	//user_spawn(id)
	//user_spawn(id)
	set_task(0.1, "revival", id)
	set_task(0.3, "revival", id)

	set_task(1.0, "vic15_teamcheck", 0, parm, 1)

	set_task(0.4, "vic15_teleport", id)
}
//----------------------------------------------------------------------------------------------
public vic15_teamcheck(parm[])
{
	new id = parm[0]

	if ( g_userTeam[id] != get_user_team(id) ) {
		client_print(id, print_chat, "[SH](Victim 15/21) You cannot respawn after switcing teams. Wait until the next round.")

		user_kill(id, 1)

		// StopVictim15 from respawning until round ends
		remove_task(id)
		g_vic15PowerUsed[id] = false
	}
}
//----------------------------------------------------------------------------------------------
public round_start()
{
	g_betweenRounds = false
}
//----------------------------------------------------------------------------------------------
public round_end()
{
	if ( !shModActive() ) return

	g_betweenRounds = true

	// Reset the cooldown on round end, to start fresh for a new round
	for (new id = 1; id <= SH_MAXSLOTS; id++) {
		if ( g_hasVic15[id] ) {
			// Reset the cooldown on round end, to start fresh for a new round
			remove_task(id)
			g_vic15PowerUsed[id] = false
		}
	}
}
//----------------------------------------------------------------------------------------------
public vic15_teleport(id)
{
	// Teleport the player
	set_user_origin(id, g_savedOrigin[id])
	//set_user_health(id, 100)
	if (get_user_team(id)==1){
		give_item(id,"weapon_knife")
		give_item(id,"weapon_glock18")
		give_item(id,"ammo_9mm")
		give_item(id,"ammo_9mm")
	}
	else{
		give_item(id,"weapon_knife")
		give_item(id,"weapon_usp")
		give_item(id,"ammo_45acp")
		give_item(id,"ammo_45acp")
	}
	emit_sound(id, CHAN_STATIC, "misc/victim15_revive.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)

	positionChangeTimer(id)

}
//----------------------------------------------------------------------------------------------
public positionChangeTimer(id)
{
	if ( !is_user_alive(id) ) return

	get_user_origin(id, g_lastPosition[id])

	new Float:velocity[3]
	Entvars_Get_Vector(id, EV_VEC_velocity, velocity)

	if ( velocity[0]==0.0 && velocity[1]==0.0 ) {
		// Force a Move (small jump)
		velocity[0] += 20.0
		velocity[2] += 100.0
		Entvars_Set_Vector(id, EV_VEC_velocity, velocity)
	}

	set_task(0.4, "positionChangeCheck", id+100)
}
//----------------------------------------------------------------------------------------------
public positionChangeCheck(id)
{
	id -= 100

	if ( !is_user_alive(id) ) return

	new origin[3]
	get_user_origin(id, origin)

	// Kill this player if Stuck in Wall!
	if ( g_lastPosition[id][0] == origin[0] && g_lastPosition[id][1] == origin[1] && g_lastPosition[id][2] == origin[2] && is_user_alive(id) ) {
		user_kill(id, 1)
		client_print(id, print_chat, "[SH](Victim 15/21) You respawned in a wall")
	}
}
//----------------------------------------------------------------------------------------------
public vic15_auraloop()
{
	if ( !shModActive() || !hasRoundStarted() ) return

	new Distance, Origin[3], eOrigin[3]
	new Radius = get_cvar_num("vic15_auraradius")
	new Pain = get_cvar_num("vic15_auradamage")
	new players[SH_MAXSLOTS], pnum, id, enemy
	get_players(players, pnum, "a")
	for (new i = 0; i < pnum; i++) {
		id = players[i]
		if ( g_hasVic15[id] && is_user_alive(id) ) {
			//gClosestDist[id] = 1182

			for (new e = 0; e < pnum; e++) {
				enemy = players[e]
				if( !is_user_alive(enemy) || get_user_team(id) == get_user_team(enemy) ) continue
				get_user_origin(id, Origin)
				get_user_origin(enemy, eOrigin)
				Distance = get_distance(Origin, eOrigin)
				if (Distance < Radius){
					shExtraDamage(enemy, id, Pain, "Victim 15/21 Aura")
				} //distance
			} //enemy loop
		} //power check
	} //self loop
} //function
//----------------------------------------------------------------------------------------------
public vic15_ringloop()
{
	if ( !shModActive() || !hasRoundStarted() ) return

	new Distance, Origin[3], eOrigin[3]
	new Radius = get_cvar_num("vic15_auraradius")
	new players[SH_MAXSLOTS], pnum, id, enemy
	get_players(players, pnum, "a")
	for (new i = 0; i < pnum; i++) {
		id = players[i]
		if ( g_hasVic15[id] && is_user_alive(id) ) {
			//gClosestDist[id] = 1182

			for (new e = 0; e < pnum; e++) {
				enemy = players[e]
				if( !is_user_alive(enemy) || get_user_team(id) == get_user_team(enemy) ) continue
				get_user_origin(id, Origin)
				get_user_origin(enemy, eOrigin)
				Distance = get_distance(Origin, eOrigin)
				if (Distance < Radius){
					setScreenFlash(enemy, 128, 0, 0, 13, 150 )  //Constant red fade to let the player know they are in Victim 15's aura radius
					setScreenFlash(id, 128, 0, 0, 13, 50 )  //Small red fade for Victim 15's screen to let him know that someone is near
					emit_sound(id, CHAN_STATIC, "misc/victim15_static.wav", 0.6, ATTN_NORM, 0, PITCH_NORM)
				} //distance
			} //enemy loop
		} //power check
	} //self loop
} //function
//----------------------------------------------------------------------------------------------
public revival(id)
{
	user_spawn(id)
	setScreenFlash(id, 0, 0, 0, 10, 255 )  //Black flash indicating revival
}
//----------------------------------------------------------------------------------------------