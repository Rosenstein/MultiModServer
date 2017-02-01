// MORPH! - from the Exiles, omnimorphic shapeshifter able to transform into any human or inhuman shape he can imagine.

/* CVARS - copy and paste to shconfig.cfg

//Morph
morph_level 1
morph_cooldown 0	//Cooldown time between shapeshifting, from when you unmorph til you morph
morph_maxtime 0	//Max time in seconds you can be morphed
morph_toggle 1		//1-toggle 0-turns on til max time is over (Default 1)

*/

/*
* v1.2 - vittu - 6/22/05
*      - Minor code clean up.
*      - Fixed issue with maxtime breaking cooldown until user
*          is respawned.
*
* v1.1 - vittu - 1/25/05
*      - Renamed Hero from Copycat to Morph due to copycat comic
*          charaters powers not able to morph into objects.
*      - Added the ability to Toggle power with use of a cvar.
*      - Added Maxtime option as a cvar.
*      - Added sounds to morphing and also added box damage sounds
*          when you take damage to make you sound like a crate.
*      - Removed p_weapon model for when you are morhed, since when
*          you looked like a crate your gun was above you in mid air.
*      - Cooldown cvar now works since before you never unmorphed
*          until you died.
*
*   Hero originally named Copycat created by BLU3 V1Z10N & Freecode.
*/

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

// GLOBAL VARIABLES
new gHeroName[]="Morph"
new bool:gHasMorphPower[SH_MAXSLOTS+1]
new bool:gMorphed[SH_MAXSLOTS+1]
new gWoodSound[3][] = {
	"debris/wood1.wav",
	"debris/wood2.wav",
	"debris/wood3.wav"
}
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Morph", "1.2", "BLU3 V1Z10N / Freecode / vittu")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("morph_level", "1")
	register_cvar("morph_cooldown", "0")
	register_cvar("morph_maxtime", "0")
	register_cvar("morph_toggle", "1")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Shapeshift into a Crate", "Disguise yourself as a Crate and blend into the environment! Crate looks best when standing still.", true, "morph_level")

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("morph_init", "morph_init")
	shRegHeroInit(gHeroName, "morph_init")

	// KEY DOWN
	register_srvcmd("morph_kd", "morph_kd")
	shRegKeyDown(gHeroName, "morph_kd")

	// EVENTS
	register_event("ResetHUD", "newSpawn", "b")
	register_event("CurWeapon", "weaponChange", "be", "1=1")
	register_event("Damage", "morph_damage", "b", "2!0")
	register_event("DeathMsg", "morph_death", "a")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_model("models/player/box/box.mdl")
	precache_sound("debris/bustcrate1.wav")
	precache_sound("debris/bustcrate2.wav")
	// TBD - SOUNDS!
	for (new x = 0; x < 3; x++) {
		precache_sound(gWoodSound[x])
	}
}
//----------------------------------------------------------------------------------------------
public morph_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has the hero
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	// This gets run if they had the power but don't anymore
	if ( !hasPowers && gHasMorphPower[id] && gMorphed[id] && is_user_alive(id) ) {
		morph_unmorph(id)
	}

	// Sets this variable to the current status
	gHasMorphPower[id] = (hasPowers!=0)
}
//----------------------------------------------------------------------------------------------
public newSpawn(id)
{
	gPlayerUltimateUsed[id] = false
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public morph_kd()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	if ( !is_user_alive(id) ) return

	if ( get_cvar_num("morph_toggle") && gMorphed[id] && !gPlayerUltimateUsed[id] ) {
		morph_unmorph(id)
		return
	}

	// Let them know they already used their ultimate if they have
	if ( gPlayerUltimateUsed[id] || gMorphed[id] ) {
		playSoundDenySelect(id)
		return
	}

	morph_morph(id)

	new Float:morphMaxTime = get_cvar_float("morph_maxtime")
	if (morphMaxTime > 0.0) set_task(morphMaxTime, "forceUnmorph", id)
}
//----------------------------------------------------------------------------------------------
public morph_morph(id)
{
	if ( !is_user_alive(id) || gMorphed[id] ) return

	#if defined AMXX_VERSION
	cs_set_user_model(id, "box")
	#else
	CS_SetModel(id, "box")
	#endif

	switchmodel(id)

	emit_sound(id, CHAN_AUTO, "debris/bustcrate2.wav", 0.4, ATTN_NORM, 0, PITCH_NORM)

	gMorphed[id] = true

	// Message
	set_hudmessage(200, 200, 0, -1.0, 0.45, 2, 0.02, 3.0, 0.01, 0.1, 86)
	show_hudmessage(id, "Morph - YOU SHAPESHIFTED INTO A CRATE")
}
//----------------------------------------------------------------------------------------------
public morph_unmorph(id)
{
	if ( gMorphed[id] ) {

		#if defined AMXX_VERSION
		cs_reset_user_model(id)
		#else
		CS_ClearModel(id)
		#endif

		switchmodel(id)

		emit_sound(id, CHAN_AUTO, "debris/bustcrate1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)

		set_hudmessage(200, 200, 0, -1.0, 0.45, 2, 0.02, 3.0, 0.01, 0.1, 86)
		show_hudmessage(id, "Morph - RETURNED TO SELF")

		gMorphed[id] = false

		new Float:MorphCooldown = get_cvar_float("morph_cooldown")
		if ( MorphCooldown > 0.0 ) ultimateTimer(id, MorphCooldown)

		remove_task(id)
	}
}
//----------------------------------------------------------------------------------------------
public switchmodel(id)
{
	if ( !is_user_alive(id) || !gHasMorphPower[id] ) return

	if ( gMorphed[id] ) {
		//remove p_weapon model since you are a crate
		//if another hero sets a custom p_ model this may not remove it
		Entvars_Set_String(id, EV_SZ_weaponmodel, "")
	}
	else {
		//reset the p_weapon model, best way to change it bug free by checking weapon name
		//custom p_ models will replace default model after first shot fired
		new wpn[32], p_mdl[40], v_mdl[32]
		new clip, ammo, wpnid = get_user_weapon(id, clip, ammo)
		if (wpnid > 0) {
			if (wpnid == 19) {
				//set p_ model back if mp5
				Entvars_Set_String(id, EV_SZ_weaponmodel, "models/p_mp5.mdl")
			}
			else {
				//need to check for a shield
				Entvars_Get_String(id, EV_SZ_viewmodel, v_mdl, 31)
				if ( containi(v_mdl, "v_shield_") != -1 && wpnid != 10 ) {
					get_weaponname(wpnid, wpn, 31)
					replace(wpn, 31, "weapon", "p_shield")
					format(p_mdl, 39, "models/shield/%s.mdl", wpn)
				}
				else {
					get_weaponname(wpnid, wpn, 31)
					replace(wpn, 31, "weapon", "p")
					format(p_mdl, 39, "models/%s.mdl", wpn)
				}
				//set p_ model back
				Entvars_Set_String(id, EV_SZ_weaponmodel, p_mdl)
			}
		}
	}
}
//----------------------------------------------------------------------------------------------
public weaponChange(id)
{
	if ( !gHasMorphPower[id] || !shModActive() || !is_user_alive(id) || !gMorphed[id] ) return

	switchmodel(id)
}
//----------------------------------------------------------------------------------------------
public morph_death()
{
	new id = read_data(2)

	if( !gHasMorphPower[id] ) return

	morph_unmorph(id)
}
//----------------------------------------------------------------------------------------------
public forceUnmorph(id)
{
	if ( !is_user_connected(id) ) return

	client_print(id, print_chat, "[SH](Morph) Shapeshifting power has worn out")

	morph_unmorph(id)
}
//----------------------------------------------------------------------------------------------
public morph_damage(id)
{
	if (!shModActive() || !is_user_alive(id) || !gMorphed[id] ) return

	new attacker = get_user_attacker(id)

	if ( attacker <= 0 || attacker > SH_MAXSLOTS ) return

	if ( is_user_alive(id) && id != attacker &&  gMorphed[id] ) {
		new num = random_num(0, 2)
		playSound(id, num)
	}
}
//----------------------------------------------------------------------------------------------
public playSound(id, num)
{
	emit_sound(id, CHAN_STATIC, gWoodSound[num], 1.0, ATTN_NORM, 0, PITCH_HIGH)
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	gMorphed[id] = false
}
//----------------------------------------------------------------------------------------------