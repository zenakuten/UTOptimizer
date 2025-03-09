class MutUTOptimizer extends Mutator;

enum EMasterServer
{
	MS_333networks,
	MS_Errorist,
	MS_333networksAndErrorist,
	MS_OpenSpy
};

enum EPropType
{
	PT_bool,
	PT_string,
	PT_int,
	PT_float
};

var config bool bCollectGarbage;
var config bool bSaveCache;
var config bool bFixCacheSizeMegs;
var config bool bFixReduceMouseLag;
var config bool bFixNetSettings;
var config bool bFixRenderer;
var config bool bFix90FPS;
var config bool bFixMasterServer;
var config EMasterServer SelectedMasterServer;
var config bool bDebugClient;

var bool bModified;

replication
{
	reliable if (ROLE == ROLE_Authority)
		bCollectGarbage, bSaveCache, bFixCacheSizeMegs, bFixReduceMouseLag, bFixNetSettings, bFixRenderer, bFix90FPS, bFixMasterServer, SelectedMasterServer, bDebugClient;
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
	Super.FillPlayInfo(PlayInfo);

	PlayInfo.AddSetting("UTOptimizer", "bCollectGarbage", "Collect garbage", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bSaveCache", "Never clear cache", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixCacheSizeMegs", "Fix CacheSizeMegs", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixReduceMouseLag", "Fix ReduceMouseLag", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixNetSettings", "Fix net settings", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixRenderer", "Fix renderer settings", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFix90FPS", "Fix 90FPS limit", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "bFixMasterServer", "Fix player's master server", 0, 1, "Check");
	PlayInfo.AddSetting("UTOptimizer", "SelectedMasterServer", "Master server(s) to use:", 0, 1, "Select", "MS_333networks;333networks;MS_Errorist;Errorist;MS_333networksAndErrorist;333networks+Errorist;MS_OpenSpy;OpenSpy");
	PlayInfo.AddSetting("UTOptimizer", "bDebugClient", "Message the client if config has been modified", 0, 1, "Check");
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "bCollectGarbage":	return "obj garbage; may help free some memory";
		case "bSaveCache": return "PurgeCacheDays=0; prevent redownloading every 30 days";
		case "bFixCacheSizeMegs": return "CacheSizeMegs=1; reduce OOM crashes";
		case "bFixReduceMouseLag": return "ReduceMouseLag=False; reduces input latency at same FPS while also increasing FPS";
		case "bFixNetSettings": return "KeepAliveTime=0.2, Max(Internet)ClientRate=1000000, bDynamicNetSpeed=False, Netspeed 1000000, MaxSimultaneousPings=200, bStandardServersOnly=False";
		case "bFixRenderer": return "DesiredRefreshRate=0, OverrideDesktopRefreshRate=False, UseVSync=False, UseBVO=True for >30% higher CPU FPS in OpenGL";
		case "bFix90FPS": return "If MaxClientFrameRate<120 or is 200, set to 240";
		case "bFixMasterServer": return "If a player has at least one Epic master server, replace with the following from the list.";
		case "SelectedMasterServer": return "333networks/Errorist lower ping to EU, OpenSpy lower ping to NA";
		case "bDebugClient": return "Message the client if config has been modified";
	}

	return Super.GetDescriptionText(PropName);
}

simulated function bool SetProperty(PlayerController PC, string PackageProp, string Prop, EPropType PropType, string value)
{
	local string cmdArgs;
	local string existingValue;

	cmdArgs = PackageProp$" "$Prop;
	existingValue = PC.ConsoleCommand("get "$cmdArgs);
	switch(PropType)
	{
		case PT_bool:
			if(bool(existingValue) != bool(value))
				bModified = true;
			break;
		case PT_string:
			if(existingValue != value)
				bModified = true;
			break;
		case PT_int:
			if(int(existingValue) != int(value))
				bModified = true;
			break;
		case PT_bool:
			if(bool(existingValue) != bool(value))
				bModified = true;
			break;
	}

	if(bModified)
	{
        log("UTOptimizer: Modifying "$PackageProp$" "$Prop$" old value="$existingValue$" new value ="$value);
		PC.ConsoleCommand("set "$cmdArgs$" "$value);
	}

	return bModified;
}

simulated function Tick(float dt)
{
	local PlayerController PC;
	local float MaxFPS;
	local bool bHasEpicMasterServer;
	local int i;
    local string RenderDevice;

	super.Tick(dt);
	if(level.NetMode != NM_DedicatedServer)
	{
		bModified = false;
		PC = Level.GetLocalPlayerController();
		if(PC != None)
		{
            RenderDevice = ConsoleCommand("get Engine.Engine RenderDevice");
			if(bCollectGarbage)
			{
				PC.ConsoleCommand("obj garbage");
			}
			if(bSaveCache)
			{
				SetProperty(PC, "Core.System", "PurgeCacheDays", PT_int, "0");
			}
			if(bFixCacheSizeMegs)
			{
				SetProperty(PC, "Engine.GameEngine", "CacheSizeMegs", PT_int, "1");
			}
			if(bFixReduceMouseLag)
			{
                if(RenderDevice ~= "D3DDrv.D3DRenderDevice")
                    SetProperty(PC, "D3DDrv.D3DRenderDevice", "ReduceMouseLag", PT_bool, "false");
                else if(RenderDevice ~= "D3D9Drv.D3D9RenderDevice")
                    SetProperty(PC, "D3D9Drv.D3D9RenderDevice", "ReduceMouseLag", PT_bool, "false");
                else if(RenderDevice ~= "OpenGLDrv.OpenGLRenderDevice")
                    SetProperty(PC, "OpenGLDrv.OpenGLRenderDevice", "ReduceMouseLag", PT_bool, "false");
			}
			if(bFixNetSettings)
			{
				SetProperty(PC, "IpDrv.TcpNetDriver", "KeepAliveTime", PT_float, "0.2");
				SetProperty(PC, "IpDrv.TcpNetDriver", "MaxClientRate", PT_int, "1000000");
				SetProperty(PC, "IpDrv.TcpNetDriver", "MaxInternetClientRate", PT_int, "1000000");
				if(class'Engine.PlayerController'.default.bDynamicNetSpeed)
				{
					class'Engine.PlayerController'.default.bDynamicNetSpeed = False;
					class'Engine.PlayerController'.static.StaticSaveConfig();
					bModified=true;
				}
				if(class'Engine.Player'.default.ConfiguredInternetSpeed != 1000000)
				{
					PC.ConsoleCommand("Netspeed 1000000");
					bModified=true;
				}
				SetProperty(PC, "Engine.Player", "ConfiguredInternetSpeed", PT_int, "1000000");
				SetProperty(PC, "Engine.Player", "ConfiguredLanSpeed", PT_int, "1000000");
				SetProperty(PC, "XInterface.GUIController", "MaxSimultaneousPings", PT_int, "200");
				SetProperty(PC, "GUI2K4.UT2k4ServerBrowser", "bStandardServersOnly", PT_bool, "False");
			}
			if(bFixRenderer)
			{
                if(RenderDevice ~= "D3DDrv.D3DRenderDevice")
                {
                    SetProperty(PC, "D3DDrv.D3DRenderDevice", "DesiredRefreshRate", PT_int, "0");
                    SetProperty(PC, "D3DDrv.D3DRenderDevice", "OverrideDesktopRefreshRate", PT_bool, "False");
                    SetProperty(PC, "D3DDrv.D3DRenderDevice", "UseHardwareTL", PT_bool, "True");
                    SetProperty(PC, "D3DDrv.D3DRenderDevice", "UseHardwareVS", PT_bool, "True");
                    SetProperty(PC, "D3DDrv.D3DRenderDevice", "UseVSync", PT_bool, "False");
                }
                else if(RenderDevice ~= "D3D9Drv.D3D9RenderDevice")
                {
                    SetProperty(PC, "D3D9Drv.D3D9RenderDevice", "DesiredRefreshRate", PT_int, "0");
                    SetProperty(PC, "D3D9Drv.D3D9RenderDevice", "OverrideDesktopRefreshRate", PT_bool, "False");
                    SetProperty(PC, "D3D9Drv.D3D9RenderDevice", "UseHardwareTL", PT_bool, "True");
                    SetProperty(PC, "D3D9Drv.D3D9RenderDevice", "UseHardwareVS", PT_bool, "True");
                    SetProperty(PC, "D3D9Drv.D3D9RenderDevice", "UseVSync", PT_bool, "False");
                }
                else if(RenderDevice ~= "OpenGLDrv.OpenGLRenderDevice")
                {
                    SetProperty(PC, "OpenGLDrv.OpenGLRenderDevice", "DesiredRefreshRate", PT_int, "0");
                    SetProperty(PC, "OpenGLDrv.OpenGLRenderDevice", "OverrideDesktopRefreshRate", PT_bool, "False");
                    SetProperty(PC, "OpenGLDrv.OpenGLRenderDevice", "UseVBO", PT_bool, "True");
                    SetProperty(PC, "OpenGLDrv.OpenGLRenderDevice", "UseVSync", PT_bool, "False");
                }
			}
			if(bFix90FPS)
			{
				MaxFPS = class'Engine.LevelInfo'.default.MaxClientFrameRate;

				// also check for 200 to fix previous setting from old version of utoptimizer
				// 60hz + 200 max fps = aids
				if (MaxFPS < 120 || MaxFPS == 200)
				{
					class'Engine.LevelInfo'.default.MaxClientFrameRate = 240;
					class'Engine.LevelInfo'.static.StaticSaveConfig();
					bModified=true;
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
						bModified=true;
					}
					else if (SelectedMasterServer == MS_Errorist)
					{
						class'IpDrv.MasterServerLink'.default.MasterServerList.Length = 1;
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Address = "ut2004master.errorist.eu";
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Port = 28902;
						class'IpDrv.MasterServerLink'.static.StaticSaveConfig();
						bModified=true;
					}
					else if (SelectedMasterServer == MS_333networksAndErrorist)
					{
						class'IpDrv.MasterServerLink'.default.MasterServerList.Length = 2;
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Address = "ut2004master.333networks.com";
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Port = 28902;
						class'IpDrv.MasterServerLink'.default.MasterServerList[1].Address = "ut2004master.errorist.eu";
						class'IpDrv.MasterServerLink'.default.MasterServerList[1].Port = 28902;
						class'IpDrv.MasterServerLink'.static.StaticSaveConfig();
						bModified=true;
					}
					else if (SelectedMasterServer == MS_OpenSpy)
					{
						class'IpDrv.MasterServerLink'.default.MasterServerList.Length = 1;
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Address = "utmaster.openspy.net";
						class'IpDrv.MasterServerLink'.default.MasterServerList[0].Port = 28902;
						class'IpDrv.MasterServerLink'.static.StaticSaveConfig();
						bModified=true;
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

				if(bModified)
					PC.ClientMessage("Settings have been optimized!");
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
	bFixRenderer=true
	bFix90FPS=true
	bFixMasterServer=true
	SelectedMasterServer=MS_OpenSpy

	bDebugClient=false
}
