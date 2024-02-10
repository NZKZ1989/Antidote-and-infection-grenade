/*

1) Граната заражение
а)В радиусе взрыва гранаты, заражать игроков (Настройк радиуса)
б)Покупка огранечение N кол-во за раунд (Для зомби)
в) стоимость гранаты за шоп кредиты

2) Граната антидот
а)Покупка только зомби (Превращать в человека)

Доп:
Скрывать в меню шопа от игроков за команду людей


Запретить покупку и поднятие гранаты если игрок не купил в меню шопа

Создать файл настроек ini

Граната смок

*/

#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[ZR] Grenade (Infects, Anti-Infects, +Antidote)",
	author = "KiKiEEKi | NZ)",
	version = "( PRIVATE 1.1 )"
};

int g_iCostCredit[3] = {
	100, //Стоимость гранаты Infect
	200, //Стоимость гранаты Anti-Infect
	300 //Стоимость Antidote
};

//Ограничение гранаты в раунде
int g_iGrenadeLimit[6] = {
	1, //Ограничение для Infect
	3, //Ограничение для Anti-Infect
	0, //Лимит для Infect (Не изменять)
	0, //Лимит для Anti-Infect (Не изменять)
	3, //Ограничение для Antidote
	0 //Лимит для Antidote (Не изменять)
};

float g_fRadius[3] = {
	0.0,
	300.0, //Радиус для Infect
	200.0 //Радиус для Anti-Infect
};

int g_iInfect[MAXPLAYERS+1]; //0 - antodote / 1 - infect / 2 - anti-infect

//============================
//		Звук
float g_fVolume = 1.0; //Громкость звука (0.1 - 1.0)
char g_sSound[128]; //Звук при использование

//============================
//		Настройк спрайта
int g_iBeamSprite; //Индекс спрайта
int g_iBeamColor[2][4] = {
	{255, 1, 1, 255}, //Цвет круга Infect
	{1, 255, 1, 255} //Цвет круга Anti-Infect
};
float g_fBeamLife = 1.0; //Время жизни луча
float g_fBeamWidth = 1.0; //Ширина луча
float g_fBeamAmplitude = 0.0; //Амплитуда луча

//============================
public void CVarChanged_1(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_iCostCredit[0] = cvar.IntValue;
}
public void CVarChanged_2(ConVar cvar, const char[] oldVal, const char[] newVal) {
	g_iCostCredit[1] = cvar.IntValue;
}
public void CVarChanged_3(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_iGrenadeLimit[0] = cvar.IntValue;
}
public void CVarChanged_4(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_iGrenadeLimit[1] = cvar.IntValue;
}
public void CVarChanged_5(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_fRadius[1] = cvar.FloatValue;
}
public void CVarChanged_6(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_fRadius[2] = cvar.FloatValue;
}
public void CVarChanged_7(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_iCostCredit[2] = cvar.IntValue;
}
public void CVarChanged_8(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_iGrenadeLimit[4] = cvar.IntValue;
}
public void CVarChanged_9(ConVar cvar, const char[] oldValue, const char[] newValue) {
	cvar.GetString(g_sSound, sizeof(g_sSound));
}
public void CVarChanged_10(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_fVolume = cvar.FloatValue;
}

public void OnPluginStart()
{
	ConVar cvar;

	(cvar = CreateConVar("sm_gr_cost_infect", "100", "Стоимость гранаты Infect")).AddChangeHook(CVarChanged_1);
	CVarChanged_1(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gr_cost_anti_infect", "200", "Стоимость гранаты Anti-Infect")).AddChangeHook(CVarChanged_2);
	CVarChanged_2(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gr_infect_limit", "1", "Ограничение для Infect")).AddChangeHook(CVarChanged_3);
	CVarChanged_3(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gr_anti_infect_limit", "3", "Ограничение для Anti-Infect")).AddChangeHook(CVarChanged_4);
	CVarChanged_4(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gr_infect_radius", "300.0", "Радиус для Infect")).AddChangeHook(CVarChanged_5);
	CVarChanged_5(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gr_anti_infect_radius", "200.0", "Радиус для Anti-Infect")).AddChangeHook(CVarChanged_6);
	CVarChanged_6(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gr_cost_antidote", "200", "Стоимость Antidote")).AddChangeHook(CVarChanged_7);
	CVarChanged_7(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gr_antidote_limit", "1", "Ограничение для Antidote")).AddChangeHook(CVarChanged_8);
	CVarChanged_8(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gr_sound_path", "kikieeki/nmp/smallmedkit1.mp3", "Путь до звук без папки sound")).AddChangeHook(CVarChanged_9);
	CVarChanged_9(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("sm_gr_sound_volume", "1.0", "Громкость звука (0.1 - 1.0)")).AddChangeHook(CVarChanged_10);
	CVarChanged_10(cvar, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "[OS][ZR]GrenadeInfectAndAntiInfect");

	if(Shop_IsStarted()) Shop_Started(); //Чтобы быть уверенным, что магазин готов к регистрации

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void Event_RoundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	OSClear();
}

public void OnMapStart()
{
	PrecacheSound(g_sSound, true);
	char sBuf[128];
	FormatEx(sBuf, sizeof(sBuf), "sound/%s", g_sSound);
	AddFileToDownloadsTable(sBuf);
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	OSClear();
}

public void Event_RoundEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	OSClear();
}

void OSClear()
{
	for(int i = 1; i <= MaxClients; ++i) {
		g_iInfect[i] = 0;
	}

	g_iGrenadeLimit[2] = g_iGrenadeLimit[0];
	g_iGrenadeLimit[3] = g_iGrenadeLimit[1];
	g_iGrenadeLimit[5] = g_iGrenadeLimit[4];
}

public void OnEntityCreated(int iEnt, const char[] sClassname)
{
	if(strcmp(sClassname, "smokegrenade_projectile") == 0) {
		SDKHook(iEnt, SDKHook_SpawnPost, Hook_SpawnPost);
	}
	if(strcmp(sClassname, "env_particlesmokegrenade") == 0) {
		RemoveEdict(iEnt);
	}
}

public void Hook_SpawnPost(int iEnt)
{
	int iClient = GetEntPropEnt(iEnt, Prop_Data, "m_hOwnerEntity");
	if(0 < iClient <= MaxClients) {
		if(ZR_IsClientZombie(iClient) && g_iInfect[iClient] > 0) {
			CreateTimer(1.3, Timer_Explosion, EntIndexToEntRef(iEnt), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action Timer_Explosion(Handle timer, int iEntRef)
{
	int iEnt = EntRefToEntIndex(iEntRef);
	if(iEnt == INVALID_ENT_REFERENCE) return Plugin_Continue;

	int iClient = GetEntPropEnt(iEnt, Prop_Data, "m_hOwnerEntity");

	float fPos[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fPos);

	fPos[2] += 10.0;

	switch(g_iInfect[iClient])
	{
		case 1: {
			TE_SetupBeamRingPoint(fPos, g_fRadius[1] / 2.0, g_fRadius[1], g_iBeamSprite, g_iBeamSprite, 0, 30, g_fBeamLife, g_fBeamWidth + 5.0, g_fBeamAmplitude, g_iBeamColor[0], 1, 0);
			TE_SendToAll();
		}
		case 2: {
			TE_SetupBeamRingPoint(fPos, g_fRadius[2] / 2.0, g_fRadius[2], g_iBeamSprite, g_iBeamSprite, 0, 30, g_fBeamLife, g_fBeamWidth + 5.0, g_fBeamAmplitude, g_iBeamColor[1], 1, 0);
			TE_SendToAll();
		}
	}

	float fPosPlayer[3];

	for(int i = 1; i <= MaxClients; ++i)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, fPosPlayer);
			
			if(GetVectorDistance(fPos, fPosPlayer) <= g_fRadius[g_iInfect[iClient]])
			{
				if(!ZR_IsClientZombie(i) && g_iInfect[iClient] == 1)
				{
					ZR_InfectClient(i); //, int attacker = -1, bool motherInfect = false, bool respawnOverride = false, bool respawn = false);
					PrintToChat(i, "Вы заражены от гранаты!");
				}
				else if(ZR_IsClientZombie(i) && g_iInfect[iClient] == 2)
				{
					ZR_HumanClient(i, false, false); //ZR_HumanClient(int client, bool respawn = false, bool protect = false);
					PrintToChat(i, "Вы вылечились от гранаты!");
				}
			}
		}
	}

	g_iInfect[iClient] = 0;

	//PrintToChatAll("Граната взорвана!");
	//PrintToChatAll("[%f/%f/%f]", fPos[0], fPos[1], fPos[2]);

	return Plugin_Continue;
}

//============================
//Регистрация элементов
public void Shop_Started()
{
	CategoryId hCategoryId = Shop_RegisterCategory("OS_Grenade_Infect", "ZShop", "");

	if(Shop_StartItem(hCategoryId, "OS_Infect"))
	{
		Shop_SetInfo("Infect Grenade", "", g_iCostCredit[0], -1, Item_BuyOnly, _, 0, _);
		Shop_SetCallbacks(_, _, _, _, _, _, ItemBuyCallback);
		Shop_EndItem();
	}

	/*if(Shop_StartItem(hCategoryId, "OS_Anti_Infect"))
	{
		Shop_SetInfo("Anti-Infect Grenade", "", g_iCostCredit[1], -1, Item_BuyOnly, _, 0, _);
		Shop_SetCallbacks(_, _, _, _, _, _, ItemBuyCallback);
		Shop_EndItem();
	}*/

	if(Shop_StartItem(hCategoryId, "OS_Antidote"))
	{
		Shop_SetInfo("Antidote", "", g_iCostCredit[1], -1, Item_BuyOnly, _, 0, _);
		Shop_SetCallbacks(_, _, _, _, _, _, ItemBuyCallback);
		Shop_EndItem();
	}
}

public bool ItemBuyCallback(int iClient, CategoryId category_id, const char[] category, ItemId item_id, const char[] sItem, ItemType type, int price, int sell_price, int value, int gold_price, int gold_sell_price)
{
	if(!IsPlayerAlive(iClient) || !ZR_IsClientZombie(iClient)) {
		PrintToChat(iClient, "Доступно только живым зомби!");
		return false;
	}

	//PrintToChat(iClient, "sItem = [%s]", sItem);

	if(strcmp(sItem, "OS_Infect", false) == 0)
	{
		if(g_iGrenadeLimit[2] == 0) {
			PrintToChat(iClient, "Infect Grenade закончились!");
			return false;
		}

		g_iInfect[iClient] = 1;
		--g_iGrenadeLimit[2];
		PrintToChat(iClient, "Вы купили Infect Grenade!");
	}
	else if(strcmp(sItem, "OS_Anti_Infect", false) == 0)
	{
		if(g_iGrenadeLimit[3] == 0) {
			PrintToChat(iClient, "Anti-Infect Grenade закончились!");
			return false;
		}

		g_iInfect[iClient] = 2;
		--g_iGrenadeLimit[3];
		PrintToChat(iClient, "Вы купили Anti-Infect Grenade!");
	}
	else if(strcmp(sItem, "OS_Antidote", false) == 0)
	{
		if(g_iGrenadeLimit[5] == 0) {
			PrintToChat(iClient, "Antidote закончились!");
			return false;
		}

		if(OSGetZombieAlive() < 2) return false;

		--g_iGrenadeLimit[5];
		ZR_HumanClient(iClient, false, false); //ZR_HumanClient(int client, bool respawn = false, bool protect = false);
		EmitSoundToClient(iClient, g_sSound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, g_fVolume);
		PrintToChat(iClient, "Вы приняли Antidote!");
		return true;
	}

	EquipPlayerWeapon(iClient, GivePlayerItem(iClient, "weapon_smokegrenade"));

	return true;
}

int OSGetZombieAlive()
{
	int iTotal = 0;

	for(int i = 1; i <= MaxClients; ++i) {
		if(IsClientInGame(i) && IsPlayerAlive(i)) {
			if(ZR_IsClientZombie(i)) ++iTotal;
		}
	}
	return iTotal;
}
