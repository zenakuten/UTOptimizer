class MutUTOptimizer extends Mutator;

enum EMasterServer
{
	MS_333networks,
	MS_Errorist,
	MS_333networksAndErrorist,
	MS_OpenSpy
};

var config bool bCollectGarbage;
var config bool bSaveCache;
var config bool bFixCacheSizeMegs;
var config bool bFixReduceMouseLag;
var config bool bFixNetSettings;
var config bool bFixResolution;
var config bool bFix90FPS;
var config bool bFixMasterServer;
var config EMasterServer SelectedMasterServer;
//var LevelInfo levelInfo;

replication
{
	reliable if (ROLE == ROLE_Authority)
		bCollectGarbage, bSaveCache, bFixCacheSizeMegs, bFixReduceMouseLag, bFixNetSettings, bFixResolution, bFix90FPS, bFixMasterServer, SelectedMasterServer;
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
	Super.FillPlayInfo(PlayInfo);

	PlayInfo.AddSetting("UTOptimizer", "bCollectGarbage", "Collect garbage", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bSaveCache", "Never clear cache", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixCacheSizeMegs", "Fix CacheSizeMegs", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixReduceMouseLag", "Fix ReduceMouseLag", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixNetSettings", "Fix net settings", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixResolution", "Fix resolution override", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFix90FPS", "Fix 90FPS limit", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixMasterServer", "Fix player's master server", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "SelectedMasterServer", "Master server(s) to use:", 0, 1, "Select", "MS_333networks;333networks;MS_Errorist;Errorist;MS_333networksAndErrorist;333networks+Errorist;MS_OpenSpy;OpenSpy");
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "bCollectGarbage":	return "obj garbage; may help free some memory";
		case "bSaveCache": return "PurgeCacheDays=0; prevent redownloading every 30 days";
		case "bFixCacheSizeMegs": return "CacheSizeMegs=1; reduces OOM crashes";
		case "bFixReduceMouseLag": return "ReduceMouseLag=False; reduces input latency and increases FPS";
		case "bFixNetSettings": return "KeepAliveTime=0.2, Max(Internet)ClientRate=1000000, bDynamicNetSpeed=False, Netspeed 1000000, MaxSimultaneousPings=200, bStandardServersOnly=False";
		case "bFixResolution": return "DesiredRefreshRate=0, OverrideDesktopRefreshRate=False; prevents overriding desktop resolution which can force low refresh rate";
		case "bFix90FPS": return "If MaxClientFrameRate=90, set to 200";
		case "bFixMasterServer": return "If a player has at least one Epic master server, replace with the following from the list.";
		case "SelectedMasterServer": return "333networks/Errorist lower ping to EU, OpenSpy lower ping to NA";
	}

	return Super.GetDescriptionText(PropName);
}

simulated function Tick(float dt)
{
	local PlayerController PC;
	local float MaxFPS;
	local bool bHasEpicMasterServer;
	local int i;

	super.Tick(dt);
	if(level.NetMode != NM_DedicatedServer)
	{
		PC = Level.GetLocalPlayerController();
		if(PC != None)
		{
			if(bCollectGarbage)
			{
				PC.ConsoleCommand("obj garbage");
			}
			if(bSaveCache)
			{
				PC.ConsoleCommand("set Core.System PurgeCacheDays 0");
			}
			if(bFixCacheSizeMegs)
			{
				PC.ConsoleCommand("set Engine.GameEngine CacheSizeMegs 1");
			}
			if(bFixReduceMouseLag)
			{
				PC.ConsoleCommand("set D3DDrv.D3DRenderDevice ReduceMouseLag False");
				PC.ConsoleCommand("set D3D9Drv.D3D9RenderDevice ReduceMouseLag False");
				PC.ConsoleCommand("set OpenGLDrv.OpenGLRenderDevice ReduceMouseLag False");
				PC.ConsoleCommand("set PixoDrv.PixoRenderDevice ReduceMouseLag False");
			}
			if(bFixNetSettings)
			{
				PC.ConsoleCommand("set IpDrv.TcpNetDriver KeepAliveTime 0.2");
				PC.ConsoleCommand("set IpDrv.TcpNetDriver MaxClientRate 1000000");
				PC.ConsoleCommand("set IpDrv.TcpNetDriver MaxInternetClientRate 1000000");
				class'Engine.PlayerController'.default.bDynamicNetSpeed = False;
				class'Engine.PlayerController'.static.StaticSaveConfig();
				PC.ConsoleCommand("set Engine.Player ConfiguredInternetSpeed 1000000");
				PC.ConsoleCommand("set Engine.Player ConfiguredLanSpeed 1000000");
				PC.ConsoleCommand("Netspeed 1000000");
				PC.ConsoleCommand("set XInterface.GUIController MaxSimultaneousPings 200");
				PC.ConsoleCommand("set GUI2K4.UT2k4ServerBrowser bStandardServersOnly False");
			}
			if(bFixResolution)
			{
				PC.ConsoleCommand("set D3DDrv.D3DRenderDevice DesiredRefreshRate 0");
				PC.ConsoleCommand("set D3DDrv.D3DRenderDevice OverrideDesktopRefreshRate False");
				PC.ConsoleCommand("set D3D9Drv.D3D9RenderDevice DesiredRefreshRate 0");
				PC.ConsoleCommand("set D3D9Drv.D3D9RenderDevice OverrideDesktopRefreshRate False");
				PC.ConsoleCommand("set OpenGLDrv.OpenGLRenderDevice DesiredRefreshRate 0");
				PC.ConsoleCommand("set OpenGLDrv.OpenGLRenderDevice OverrideDesktopRefreshRate False");
				PC.ConsoleCommand("set PixoDrv.PixoRenderDevice DesiredRefreshRate 0");
			}
			if(bFix90FPS)
			{
				MaxFPS = class'Engine.LevelInfo'.default.MaxClientFrameRate;

				if (MaxFPS == 90)
				{
					class'Engine.LevelInfo'.default.MaxClientFrameRate = 200;
					class'Engine.LevelInfo'.static.StaticSaveConfig();
				}
			}
			if (bFixMasterServer)
			{
				bHasEpicMasterServer = false;

				for (i = 0; i < class'IpDrv.MasterServerLink'.default.MasterServerList.Length; i++)
				{
					if ((class'IpDrv.MasterServerLink'.default.MasterServerList[i].Address == "ut2004master1.epicgames.com" ||
						class'IpDrv.MasterServerLink'.default.MasterServerList[i].Address == "ut2004master2.epicgames.com") &&
						class'IpDrv.MasterServerLink'.default.MasterServerList[i].Port == 28902)
					{
						bHasEpicMasterServer = true;
						break;
					}
				}

				if (bHasEpicMasterServer)
				{
					if (SelectedMasterServer == MS_333networks)
					{
						class'IpDrv.MasterServerLink'.default.MasterServerList.Length = 1;
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Address = "ut2004master.333networks.com";
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Port = 28902;
						class'IpDrv.MasterServerLink'.static.StaticSaveConfig();
					}
					else if (SelectedMasterServer == MS_Errorist)
					{
						class'IpDrv.MasterServerLink'.default.MasterServerList.Length = 1;
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Address = "ut2004master.errorist.eu";
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Port = 28902;
						class'IpDrv.MasterServerLink'.static.StaticSaveConfig();
					}
					else if (SelectedMasterServer == MS_333networksAndErrorist)
					{
						class'IpDrv.MasterServerLink'.default.MasterServerList.Length = 2;
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Address = "ut2004master.333networks.com";
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Port = 28902;
						class'IpDrv.MasterServerLink'.default.MasterServerList[1].Address = "ut2004master.errorist.eu";
						class'IpDrv.MasterServerLink'.default.MasterServerList[1].Port = 28902;
						class'IpDrv.MasterServerLink'.static.StaticSaveConfig();
					}
					else if (SelectedMasterServer == MS_OpenSpy)
					{
						class'IpDrv.MasterServerLink'.default.MasterServerList.Length = 1;
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Address = "utmaster.openspy.net";
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Port = 28902;
						class'IpDrv.MasterServerLink'.static.StaticSaveConfig();
					}
					else
					{
						Log("Warning: could not determine which master server to use");
					}
				}
				else
				{
					Log("Warning: Default Epic master server not found. Skipping master server modification.");
				}
			}
			Disable('Tick');
		}
	}
}

defaultproperties
{
	bAddToServerPackages=true
	FriendlyName="UTOptimizer"
	Description="Runs console commands on behalf of clients to reduce crashes, keep cache, fix networking, and improve performance. By default everything is enabled."
	RemoteRole=ROLE_SimulatedProxy
	bSkipActorPropertyReplication=false
	bOnlyDirtyReplication=false
	bAlwaysRelevant=true

    bCollectGarbage=true
    bSaveCache=true
    bFixCacheSizeMegs=true
    bFixReduceMouseLag=true
    bFixNetSettings=true
    bFixResolution=true
    bFix90FPS=true
    bFixMasterServer=true
    SelectedMasterServer=MS_OpenSpy
}