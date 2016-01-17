#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <zombiereloaded>

new bool:g_bZombieMode = false;

#define DATA "1.0"

public Plugin:myinfo =
{
	name = "SM Franug Player Colors",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

// I think that I get these color codes from advcommands :D
new g_iTColors[26][4] = {{255, 255, 255, 255}, {0, 0, 0, 192}, {255, 0, 0, 192},    {0, 255, 0, 192}, {0, 0, 255, 192}, {255, 255, 0, 192}, {255, 0, 255, 192}, {0, 255, 255, 192}, {255, 128, 0, 192}, {255, 0, 128, 192}, {128, 255, 0, 192}, {0, 255, 128, 192}, {128, 0, 255, 192}, {0, 128, 255, 192}, {192, 192, 192}, {210, 105, 30}, {139, 69, 19}, {75, 0, 130}, {248, 248, 255}, {216, 191, 216}, {240, 248, 255}, {70, 130, 180}, {0, 128, 128},	{255, 215, 0}, {210, 180, 140}, {255, 99, 71}};
new String:g_sTColors[26][32];

new g_color[MAXPLAYERS + 1];

new Handle:c_color = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("franug_colors.phrases");
	SetupRGBA();
	
	CreateConVar("sm_fcolors_version", DATA, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_color = RegClientCookie("Colors", "Colors", CookieAccess_Private);
	RegAdminCmd("sm_colors", Colores, ADMFLAG_GENERIC);
	
	HookEvent("player_hurt", Playerh);
	HookEvent("player_spawn", Playerh2);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
			
		if(AreClientCookiesCached(client)) OnClientCookiesCached(client);
		else g_color[client]  = 0;
		
	}
	
	g_bZombieMode = (FindPluginByFile("zombiereloaded")==INVALID_HANDLE?false:true);
}

public OnLibraryAdded(const String:name[])
{
	if(strcmp(name, "zombiereloaded")==0)
		g_bZombieMode = true;
}

public Action:Playerh(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bZombieMode) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_color[client] != 0)
		CreateTimer(0.1, Colort, client);
}

public Action:Playerh2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_color[client] != 0)
		CreateTimer(2.0, Colort, client);
}

public Action:Colort(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && g_color[client] != 0) 
		SetEntityRenderColor(client, g_iTColors[g_color[client]][0], g_iTColors[g_color[client]][1], g_iTColors[g_color[client]][2], g_iTColors[g_color[client]][3]);
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if(g_color[client] != 0) 
		SetEntityRenderColor(client, g_iTColors[g_color[client]][0], g_iTColors[g_color[client]][1], g_iTColors[g_color[client]][2], g_iTColors[g_color[client]][3]);
}

public ZR_OnClientHumanPost(client, bool:respawn, bool:protect)
{
	if(g_color[client] != 0) 
		CreateTimer(1.0, Colort, client);
}

public OnClientCookiesCached(client)
{
	new String:SprayString[12];
	GetClientCookie(client, c_color, SprayString, sizeof(SprayString));
	
	if(StringToInt(SprayString) == 0)
	{
		g_color[client]  = 0;
		return;
	}
		
	g_color[client]  = StringToInt(SprayString);
}

public OnClientDisconnect(client)
{
	if(AreClientCookiesCached(client))
	{
		new String:SprayString[12];
		Format(SprayString, sizeof(SprayString), "%i", g_color[client]);
		
		SetClientCookie(client, c_color, SprayString);
	}
}


public Action:Colores(client, args)
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "Choose Player Color");
	decl String:temp[4];
	for(new i=0; i<26; i++)
	{
		Format(temp, 4, "%i", i);
		AddMenuItem(menu, temp, g_sTColors[i]);
	}
		
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);

}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		decl String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		new g = StringToInt(info);
		
		if(IsPlayerAlive(client)) SetEntityRenderColor(client, g_iTColors[g][0], g_iTColors[g][1], g_iTColors[g][2], g_iTColors[g][3]);
		
		g_color[client] = g;
		
		PrintToChat(client, " \x04[SM_COLORS]\x01 You have choosen\x03 %s \x01!",g_sTColors[g]);
		
		Colores(client, 0);
		
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


SetupRGBA()
{
	new String:colorTemp[32];
	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_normal");
	g_sTColors[0] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_black");
	g_sTColors[1] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_red");
	g_sTColors[2] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_green");
	g_sTColors[3] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_blue");
	g_sTColors[4] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_yellow");
	g_sTColors[5] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_purple");
	g_sTColors[6] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_cyan");
	g_sTColors[7] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_orange");
	g_sTColors[8] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_pink");
	g_sTColors[9] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_olive");
	g_sTColors[10] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_lime");
	g_sTColors[11] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_violet");
	g_sTColors[12] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%t", "color_lightblue");
	g_sTColors[13] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_silver");
	g_sTColors[14] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_chocolate");
	g_sTColors[15] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_saddlebrown");
	g_sTColors[16] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_indigo");
	g_sTColors[17] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_ghostwhite");
	g_sTColors[18] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_thistle");
	g_sTColors[19] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_aliceblue");
	g_sTColors[20] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_steelblue");
	g_sTColors[21] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_teal");
	g_sTColors[22] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_gold");
	g_sTColors[23] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_tan");
	g_sTColors[24] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%t", "color_tomato");
	g_sTColors[25] = colorTemp;
}