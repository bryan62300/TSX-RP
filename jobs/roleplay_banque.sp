/*
 * Cette oeuvre, création, site ou texte est sous licence Creative Commons Attribution
 * - Pas d’Utilisation Commerciale
 * - Partage dans les Mêmes Conditions 4.0 International. 
 * Pour accéder à une copie de cette licence, merci de vous rendre à l'adresse suivante
 * http://creativecommons.org/licenses/by-nc-sa/4.0/ .
 *
 * Merci de respecter le travail fourni par le ou les auteurs 
 * https://www.ts-x.eu/ - kossolax@ts-x.eu
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.2.1"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MODEL_CASH 			"models/DeadlyDesire/props/atm01.mdl"
#define MENU_TIME_DURATION	60

public Plugin myinfo = {
	name = "Jobs: Banquier", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Banquier",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	RegServerCmd("rp_bankcard",			Cmd_ItemBankCard,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_bankkey",			Cmd_ItemBankKey,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_bankswap",			Cmd_ItemBankSwap,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_assurance",	Cmd_ItemAssurance,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_forward",		Cmd_ItemForward,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_noAction",	Cmd_ItemNoAction,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cheque",		Cmd_ItemCheque,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_packdebutant",Cmd_ItemPackDebutant, 	"RP-ITEM", 	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_permi",		Cmd_ItemPermi,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_distrib",		Cmd_ItemDistrib,		"RP-ITEM", 	FCVAR_UNREGISTERED);
	
	RegServerCmd("rp_item_spawntag",	Cmd_SpawnTag,			"RP-ITEM",	FCVAR_UNREGISTERED);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	PrecacheModel(MODEL_CASH, true);
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerBuild,	fwdOnPlayerBuild);
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public Action fwdCommand(int client, char[] command, char[] arg) {	
	if( StrEqual(command, "search") || StrEqual(command, "lookup")) {
		if( rp_GetClientJobID(client) != 1 &&  rp_GetClientJobID(client) != 41 && rp_GetClientJobID(client) != 211 && rp_GetClientJobID(client) != 101 ) { // Police, mercenaire, banquier, tribunal
			ACCESS_DENIED(client);
		}
		int target = GetClientTarget(client);
		
		if( !IsValidClient(target) )
			return Plugin_Handled;

		if( !IsPlayerAlive(target) )
			return Plugin_Handled;

		int wepIdx;
		char classname[32], msg[128];
		Format(msg, 127, "Ce joueur possède: ");

		if( (wepIdx = GetPlayerWeaponSlot( target, 1 )) != -1 ){
			GetEdictClassname(wepIdx, classname, 31);
			ReplaceString(classname, 31, "weapon_", "", false);

			Format(msg, 127, "%s %s", msg, classname);
		}
		if( (wepIdx = GetPlayerWeaponSlot( target, 0 )) != -1 ){
			GetEdictClassname(wepIdx, classname, 31);
			ReplaceString(classname, 31, "weapon_", "", false);

			Format(msg, 127, "%s %s", msg, classname);
		}
			
		
		if( rp_GetClientBool(target, b_License1) || rp_GetClientBool(target, b_License2) || rp_GetClientBool(target, b_LicenseSell) ) {
			Format(msg, 127, "%s permis", msg);

			if( rp_GetClientBool(target, b_License1) ) {
				Format(msg, 127, "%s léger", msg);
			}
			if( rp_GetClientBool(target, b_License2) ) {
				Format(msg, 127, "%s lourd", msg);
			}
			if(  rp_GetClientBool(target, b_LicenseSell) ) {
				Format(msg, 127, "%s vente", msg);
			}
		}

		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %s.", msg);

		return Plugin_Handled;
	}
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPermi(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPermi");
	#endif
	
	char Arg1[12];
	GetCmdArg(1, Arg1, 11);
	
	int client = GetCmdArgInt(2);
	
	if( StrEqual(Arg1, "lege") ) {
		rp_SetClientBool(client, b_License1, true);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez maintenant le permis de port d'arme légère.");
	}
	else if( StrEqual(Arg1, "lourd") ) {
		rp_SetClientBool(client, b_License2, true);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez maintenant le permis de port d'arme lourde.");
	}
	else if( StrEqual(Arg1, "vente") ) {
		rp_SetClientBool(client, b_LicenseSell, true);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez maintenant le permis de vente.");
	}
	
	rp_ClientSave(client);
}
public Action Cmd_ItemBankCard(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemBankCard");
	#endif
	
	int client = GetCmdArgInt(1);
	rp_SetClientBool(client, b_HaveCard, true);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre carte bancaire est maintenant active.");
	rp_ClientSave(client);
}
public Action Cmd_ItemBankKey(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemBankKey");
	#endif
	
	int client = GetCmdArgInt(1);
	rp_SetClientBool(client, b_HaveAccount, true);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre compte bancaire est maintenant actif.");
	rp_ClientSave(client);
}
public Action Cmd_ItemBankSwap(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemBankSwap");
	#endif
	
	
	int client = GetCmdArgInt(1);
	rp_SetClientBool(client, b_PayToBank, true);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous recevrez maintenant votre paye en banque.");
	rp_ClientSave(client);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemAssurance(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemAssurance");
	#endif
	
	
	int client = GetCmdArgInt(1);
	
	if( !rp_GetClientBool(client, b_Assurance) ) {
		rp_IncrementSuccess(client, success_list_assurance);
	}
	
	rp_SetClientBool(client, b_Assurance, true);
	FakeClientCommand(client, "say /assu");
	
	rp_ClientSave(client);
	
	return Plugin_Handled;
}
public Action Cmd_ItemNoAction(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemNoAction");
	#endif
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	char name[64];
	
	rp_ClientGiveItem(client, item_id);
	rp_GetItemData(item_id, item_type_name, name, sizeof(name));
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ceci est un %s, vous en avez %d sur vous et %d en banque.", name, rp_GetClientItem(client, item_id), rp_GetClientItem(client, item_id, true));
	return;
}
// ----------------------------------------------------------------------------
int g_iChequeID = -1;
// ----------------------------------------------------------------------------
public Action Cmd_ItemCheque(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCheque");
	#endif
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( g_iChequeID == -1 )
		g_iChequeID = item_id;
	
	rp_ClientGiveItem(client, item_id);
	CreateTimer(0.25, task_cheque, client);
}
public Action task_cheque(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_cheque");
	#endif
	// Setup menu
	Handle menu = CreateMenu(MenuCheque);
	SetMenuTitle(menu, "Liste des jobs disponible:");
	char tmp[12], tmp2[64];
	
	bool bJob[MAX_JOBS];
	
	for(int i = 1; i <= MaxClients; i++) {
		
		if( !IsValidClient(i) )
			continue;
		if( !IsClientConnected(i) )
			continue;
		if( rp_GetClientInt(i, i_Job) == 0 )
			continue;
		if( i == client )
			continue;
		
		int job = rp_GetClientJobID(i);
		if( job == 1 || job == 91 || job == 101 || job == 181 ) // Police, mafia, tribunal, 18th
			continue;
		
		bJob[job] = true;
	}
	
	int amount = 0;
	
	for(int i=1; i<MAX_JOBS; i++) {
		if( bJob[i] == false )
			continue;
		
		amount++;
		Format(tmp, sizeof(tmp), "%d", i);
		rp_GetJobData(i, job_type_name, tmp2, sizeof(tmp2));
		
		AddMenuItem(menu, tmp, tmp2);
	}
	
	if( amount == 0 ) {
		CloseHandle(menu);
	}
	else {
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_DURATION);
	}
}
// ----------------------------------------------------------------------------
public int MenuCheque(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("MenuCheque");
	#endif
	
	if (p_oAction == MenuAction_Select) {
		
		char szMenuItem[64];
		if( GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem)) ) {
			
			char tmp[255], tmp2[255];
			int jobID = StringToInt(szMenuItem);
			
			// Setup menu
			Handle hGiveMenu = CreateMenu(MenuCheque2);
			SetMenuTitle(hGiveMenu, "Sélectionner un objet à acheter:");
			
			for(int i = 0; i < MAX_ITEMS; i++) {
				
				if( rp_GetItemInt(i, item_type_job_id) != jobID )
					continue;
				
				rp_GetItemData(i, item_type_extra_cmd, tmp, sizeof(tmp));
				
				// Chirurgie
				if( StrContains(tmp, "rp_chirurgie", false) == 0 )
					continue;
				if( StrContains(tmp, "rp_item_contrat", false) == 0 )
					continue;
				if( StrContains(tmp, "rp_item_conprotect", false) == 0 )
					continue;
				
				rp_GetItemData(i, item_type_name, tmp, sizeof(tmp));
				
				Format(tmp2, sizeof(tmp2), "%s [%d$]", tmp, rp_GetItemInt(i, item_type_prix) );
				Format(tmp, sizeof(tmp), "%d_0_0_%d_0", i, client);
				
				AddMenuItem(hGiveMenu, tmp, tmp2);
			}
			
			SetMenuExitButton(hGiveMenu, true);
			DisplayMenu(hGiveMenu, client, MENU_TIME_DURATION);
		}
	}
	else if ( p_oAction == MenuAction_End ) {
		CloseHandle(p_hItemMenu);
	}
}
public int MenuCheque2(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("MenuCheque2");
	#endif
	if (p_oAction == MenuAction_Select) {
		
		char szMenuItem[64];
		if( GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem)) ) {
			
			char data[5][32];
			ExplodeString(szMenuItem, "_", data, sizeof(data), sizeof(data[]));
			
			int item_id = StringToInt(data[0]);
			int price = rp_GetItemInt(item_id, item_type_prix);
			int auto = rp_GetItemInt(item_id, item_type_auto);
			
			char tmp[255], tmp2[255], tmp3[255];
			rp_GetItemData(item_id, item_type_name, tmp3, sizeof(tmp3));
			
			// Setup menu
			Handle hGiveMenu = rp_CreateSellingMenu();			
			
			SetMenuTitle(hGiveMenu, "Sélectionner combien en acheter:");
			int amount = 0;
			for(int i = 1; i <= 100; i++) {
				
				if( (rp_GetClientInt(client, i_Money)+rp_GetClientInt(client, i_Bank)) <= (price*i) )
					break;
				if( i > 1 && auto )
					continue;
				
				amount++;
				
				
				Format(tmp2, sizeof(tmp2), "%s - %d [%d$]", tmp3, i, price * i );
				Format(tmp, sizeof(tmp), "%d_%d_%s_%s_%s_%s", item_id, i, data[1], data[2], data[3], data[4]); // id,amount,itemTYPE=0,param,ClientFromMenu,reduction

				AddMenuItem(hGiveMenu, tmp, tmp2);
			}
			
			if( amount == 0 ) {
				CloseHandle(hGiveMenu);
				return;
			}
			
			SetMenuExitButton(hGiveMenu, true);
			DisplayMenu(hGiveMenu, client, MENU_TIME_DURATION);
		}
	}
	else if ( p_oAction == MenuAction_End ) {
		CloseHandle(p_hItemMenu);
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemForward(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemForward");
	#endif
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	char tmp[64];
	int mnt = rp_GetClientItem(client, item_id);
	rp_ClientGiveItem(client, item_id, -mnt, false);
	rp_ClientGiveItem(client, item_id, mnt+1, true);
	
	rp_GetItemData(item_id, item_type_name, tmp, sizeof(tmp));
	
	if( mnt+1 == 1 )
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %d %s a été transféré en banque.", mnt+1, tmp);
	else
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %d %s ont été transférés en banque.", mnt+1, tmp);
	
	return;
}
public Action Cmd_ItemPackDebutant(int args) { //Permet d'avoir la CB, le compte & le RIB
	#if defined DEBUG
	PrintToServer("Cmd_ItemPackDebutant");
	#endif
	
	int client = GetCmdArgInt(1);
	rp_SetClientBool(client, b_HaveCard, true);
	rp_SetClientBool(client, b_PayToBank, true);
	rp_SetClientBool(client, b_HaveAccount, true);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre carte banquaire, votre compte banquaire et votre RIB sont maintenant actifs.");

	rp_ClientSave(client);
}
// ----------------------------------------------------------------------------
public Action fwdOnPlayerBuild(int client, float& cooldown) {
	if( rp_GetClientJobID(client) != 211 )
		return Plugin_Continue;
	
	int ent = BuidlingATM(client);
	
	if( ent > 0 ) {
		rp_SetClientStat(client, i_TotalBuild, rp_GetClientStat(client, i_TotalBuild)+1);
		rp_ScheduleEntityInput(ent, 120.0, "Kill");
		cooldown = 120.0;
	}
	else 
		cooldown = 3.0;
	
	return Plugin_Stop;
}
public Action Cmd_ItemDistrib(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemDistrib");
	#endif
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( BuidlingATM(client) == 0 ) {
		ITEM_CANCEL(client, item_id);
	}
	
	return Plugin_Handled;
}


int BuidlingATM(int client) {
	#if defined DEBUG
	PrintToServer("BuildingATM");
	#endif
	
	if( !rp_IsBuildingAllowed(client) )
		return 0;	
	
	char classname[64], tmp[64];
	
	Format(classname, sizeof(classname), "rp_bank__%i", client);	
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	int count;
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		
		if( StrEqual(classname, tmp) ) {
			count++;
			if( count >= 2 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà deux banques de placées.");
				return 0;
			}
		}
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Construction en cours...");

	EmitSoundToAllAny("player/ammo_pack_use.wav", client);
	
	int ent = CreateEntityByName("prop_physics_override");
	
	DispatchKeyValue(ent, "classname", classname);
	DispatchKeyValue(ent, "model", MODEL_CASH);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntityModel(ent, MODEL_CASH);
	
	SetEntProp( ent, Prop_Data, "m_iHealth", 10000);
	SetEntProp( ent, Prop_Data, "m_takedamage", 0);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	float vecAngles[3]; GetClientEyeAngles(client, vecAngles); vecAngles[0] = vecAngles[2] = 0.0;
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	SetEntityRenderMode(ent, RENDER_NONE);
	ServerCommand("sm_effect_fading \"%i\" \"3.0\" \"0\"", ent);
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	CreateTimer(3.0, BuildingATM_post, ent);
	rp_SetBuildingData(ent, BD_owner, client);
	return ent;
}

public Action BuildingATM_post(Handle timer, any entity) {
	#if defined DEBUG
	PrintToServer("BuildingATM_post");
	#endif
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	rp_Effect_BeamBox(client, entity, NULL_VECTOR, 255, 255, 0);
	
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);
	SDKHook(entity, SDKHook_OnTakeDamage, DamageATM);
	HookSingleEntityOutput(entity, "OnBreak", BuildingATM_break);
	return Plugin_Handled;
}

public void BuildingATM_break(const char[] output, int caller, int activator, float delay) {
	#if defined DEBUG
	PrintToServer("BuildingATM_break");
	#endif
	
	int owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
	if( IsValidClient(owner) ) {
		CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Votre banque a été détruite.");
	}
}
public Action DamageATM(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	#if defined DEBUG
	PrintToServer("DamageATM");
	#endif
	
	if( rp_IsInPVP(victim) ) {
		damage *= 25.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}


public Action Cmd_SpawnTag(int args) {
	static iPrecached[MAX_ITEMS];
	#if defined DEBUG
	PrintToServer("Cmd_SpawnTag");
	#endif
	
	char gang[12], path[128];
	GetCmdArg(1, gang, sizeof(gang));
	
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	Format(path, sizeof(path), "deadlydesire/groups/princeton/%s_small.vmt", gang);
	
	if( !IsDecalPrecached(path) || iPrecached[item_id] < 0 ) {
		iPrecached[item_id] = PrecacheDecal(path);
	}
	
	float origin[3], origin2[3], angles[3];
	GetClientEyeAngles(client, angles);
	GetClientEyePosition(client, origin);
	
	Handle tr = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, FilterToOne, client);
	if( tr && TR_DidHit(tr) ) {
		TR_GetEndPosition(origin2, tr);
		if( GetVectorDistance(origin, origin2) <= 128.0 ) {
			
			TE_Start("World Decal");
			TE_WriteVector("m_vecOrigin",origin2);
			TE_WriteNum("m_nIndex", iPrecached[item_id]);
			TE_SendToAll();
			
			rp_IncrementSuccess(client, success_list_graffiti);
		}
		else {
			ITEM_CANCEL(client, item_id);
		}
	}
	else {
		ITEM_CANCEL(client, item_id);
	}
	CloseHandle(tr);
}
