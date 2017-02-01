/** AMX Mod script
* 
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or ( at
*  your option ) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
*  General Public License for more details.
*  
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*/

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <hamsandwich>

#define PLUGIN            "Golden Weapons"
#define VERSION         "1.0-alpha1"
#define AUTHOR          "Addons zz"

#define BUY_WEAPON_MENU_NAME        "Golden Weapons"

#define IS_VALID_PLAYER(%1) ( 1 <= %1 <= 32 )

new AK47_V_MODEL[64] = "models/golden/v_ak47.mdl"
new AK47_P_MODEL[64] = "models/golden/p_ak47.mdl"

new M4A1_V_MODEL[64] = "models/golden/v_m4a1.mdl"
new M4A1_P_MODEL[64] = "models/golden/p_m4a1.mdl"

new MP5_V_MODEL[64] = "models/golden/v_mp5.mdl"
new MP5_P_MODEL[64] = "models/golden/p_mp5.mdl"

new ZOOM_WEAPON_SOUND[64] = "weapons/zoom.wav"

new const primaryWeapons[][] = 
{
	"weapon_shield",
	"weapon_scout",
	"weapon_xm1014",
	"weapon_mac10",
	"weapon_aug",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_p90"
}

new gp_cvar_dmg

new g_buy_menu_id
new g_weapon_damage
new g_weapon_cost = 16000
new g_whichSpecialWeapon[33] = {0, ...}

public plugin_init()
{
	register_plugin( PLUGIN, VERSION, AUTHOR ) 

	gp_cvar_dmg = register_cvar( "amx_gold_damage", "5" )

	g_buy_menu_id = register_menuid( BUY_WEAPON_MENU_NAME )
	register_menucmd( g_buy_menu_id, 1023, "buy_weaponMenu" )

	register_clcmd( "say /goldmenu", "showmenu" )
	register_clcmd( "say goldmenu", "showmenu" )

	register_clcmd( "say /silvermenu", "showmenu" )
	register_clcmd( "say silvermenu", "showmenu" )

	register_clcmd( "say /akdemonio", "showmenu" )
	register_clcmd( "say akdemonio", "showmenu" )
	
	register_event( "DeathMsg", "death_event", "a" )
	register_event( "CurWeapon","current_weaponEvent","be","1=1" )
	register_event( "TextMsg", "event_game_commencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in" );

	RegisterHam( Ham_TakeDamage, "player", "fw_takedamage", 0 )
}

public plugin_cfg()
{
	g_weapon_damage = get_pcvar_num( gp_cvar_dmg )
}

/**
 * Does not affect cs built-in bots. Only players and PODBots.
 */
public fw_takedamage( victim, inflictor, attacker, Float:damage )
{
	if( IS_VALID_PLAYER( attacker ) )
	{
		if( g_whichSpecialWeapon[attacker] == get_user_weapon( attacker ) )
		{
			SetHamParamFloat( 4, damage * g_weapon_damage )
			return HAM_HANDLED 
		}
	}
	return HAM_IGNORED 
}

public showmenu( id ) 
{
	new menu[512]

	format( menu, 511, "\rGolden Licenses Store\
			\w^n^n1. Buy a Golden AK47 License	  \
			\y( $%i )\w^n2. Buy a Golden M4A1 License	  \
			\y( $%i )\w^n3. Buy a Golden MP5 License		\
			\y( $%i )\w^n^n0. Exit^n", g_weapon_cost, g_weapon_cost, g_weapon_cost )

	new keys = ( 1<<0|1<<1|1<<2|1<<9 );
	show_menu( id, keys, menu, -1, BUY_WEAPON_MENU_NAME )
}

public buy_weaponMenu( id, key ) 
{
	if ( !is_user_alive( id ) )
	{
		client_print( id,print_chat, "[AMXX] To buy golden weapons, you need to be alive!" )
		return PLUGIN_HANDLED
	}
	new money = cs_get_user_money( id )

	if( money >= g_weapon_cost )
	{ 
		drop_prim( id )

		new licenteType[32]

		switch( key ) 
		{
			case 0: 
			{
				g_whichSpecialWeapon[id] = CSW_AK47
				copy( licenteType, charsmax( licenteType ), "AK47" )

				set_task( 0.3, "giveWeapon_AK47", id )
			}
			case 1: 
			{
				g_whichSpecialWeapon[id] = CSW_M4A1
				copy( licenteType, charsmax( licenteType ), "M4A1" )

				set_task( 0.3, "giveWeapon_M4A1", id )
			}
			case 2: 
			{
				g_whichSpecialWeapon[id] = CSW_MP5NAVY
				copy( licenteType, charsmax( licenteType ), "MP5" )

				set_task( 0.3, "giveWeapon_MP5", id )
			}
			default: return PLUGIN_HANDLED
		}
		cs_set_user_money( id, money - g_weapon_cost )

		client_print( id, print_chat, "[AMXX] You own now a %s Golden Weapon licence!", licenteType )

	} else 
	{
		client_print( id, print_chat, "[AMXX] You do not have enough money to buy Golden Weapons. Cost $%d ", g_weapon_cost )
	}
	return PLUGIN_HANDLED
}

public giveWeapon_AK47( id )
{
	give_item( id, "weapon_ak47" )

	set_pev( id, pev_viewmodel2, AK47_V_MODEL )
	set_pev( id, pev_weaponmodel2, AK47_P_MODEL )

	give_item( id,"ammo_762nato" );
	give_item( id,"ammo_762nato" );
	give_item( id,"ammo_762nato" );
}

public giveWeapon_M4A1( id )
{
	give_item( id, "weapon_m4a1" )

	set_pev( id, pev_viewmodel2, M4A1_V_MODEL )
	set_pev( id, pev_weaponmodel2, M4A1_P_MODEL )

	give_item( id,"ammo_556nato" );
	give_item( id,"ammo_556nato" );
	give_item( id,"ammo_556nato" );
}

public giveWeapon_MP5( id )
{
	give_item( id, "weapon_mp5navy" )

	set_pev( id, pev_viewmodel2, MP5_V_MODEL )
	set_pev( id, pev_weaponmodel2, MP5_P_MODEL )

	give_item( id,"ammo_9mm" );
	give_item( id,"ammo_9mm" );
	give_item( id,"ammo_9mm" );
	give_item( id,"ammo_9mm" );
}

public client_connect( id )
{
	g_whichSpecialWeapon[id] = 0
}

public event_game_commencing()
{
	arrayset( g_whichSpecialWeapon, 0, sizeof( g_whichSpecialWeapon ) )
}

public client_disconnect( id )
{
	g_whichSpecialWeapon[id] = 0
}

public death_event()
{
	new id = read_data( 2 )

	g_whichSpecialWeapon[id] = 0
}

public plugin_precache()
{
	precache_model( AK47_V_MODEL )
	precache_model( AK47_P_MODEL )

	precache_model( M4A1_V_MODEL )
	precache_model( M4A1_P_MODEL )

	precache_model( MP5_V_MODEL )
	precache_model( MP5_P_MODEL )

	precache_sound( ZOOM_WEAPON_SOUND )
}

/**
 * This message updates the numerical magazine ammo count and the corresponding ammo 
 *	type icon on the HUD.
 */
public current_weaponEvent( id )
{
	new szWeapID = read_data( 2 )

	if( g_whichSpecialWeapon[id] == szWeapID )
	{
		switch( szWeapID )
		{
			case CSW_AK47: 
			{
				set_pev( id, pev_viewmodel2, AK47_V_MODEL )
				set_pev( id, pev_weaponmodel2, AK47_P_MODEL )
			} 
			case CSW_M4A1: 
			{
				set_pev( id, pev_viewmodel2, M4A1_V_MODEL )
				set_pev( id, pev_weaponmodel2, M4A1_P_MODEL )
			} 
			case CSW_MP5NAVY: 
			{
				set_pev( id, pev_viewmodel2, MP5_V_MODEL )
				set_pev( id, pev_weaponmodel2, MP5_P_MODEL )
			}
		}
	}
	return PLUGIN_HANDLED
}

stock drop_prim( id ) 
{
	for ( new i = 0; i < sizeof( primaryWeapons ); i++ ) 
	{
		client_cmd( id, "drop %s", primaryWeapons[i] )
	}
}
