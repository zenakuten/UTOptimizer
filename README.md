# CSGarbageFix
UT2004 mutator which fixes some issues for clients.

Options:


### bCollectGarbage
Collect garbage each map load.

### bSaveCache
Sets PurgeCacheDays=0, preventing the need to constantly redownload server files every 30 days. Takes effect after a game restart.

### bFixCacheSizeMegs
Sets CacheSizeMegs=1. Some players like to set this higher than the default of 32 which results in the game running into the virtual memory limit sooner and crashing if enough content is loaded. CacheSizeMegs=1 has been tested to work fine, so it will save a small amount of memory over the default 32.

### bFixReduceMouseLag
Disables ReduceMouseLag, which counterintuitively increases input lag on modern systems. This will help level the playing field and create a better experience for those that have ReduceMouseLag enabled.

### bFixNetSettings
KeepAliveTime=0.2, Max(Internet)ClientRate=1000000, bDynamicNetSpeed=False, ConfiguredInternetSpeed=1000000, ConfiguredLanSpeed=1000000, Netspeed 1000000, MaxSimultaneousPings=200, bStandardServersOnly=False

Sets network settings to optimal values. Also fixes the server browser when netspeed is changed.

### bFixRenderer
DesiredRefreshRate=0, OverrideDesktopRefreshRate=False, UseVSync=False, UseBVO=True for >30% higher CPU FPS in OpenGL

If someone were to have enabled the override, and DesiredRefreshRate is anything but zero (80 by default), the game will override the desktop resolution and force a refresh rate much lower than what the monitor is capable of, in the case of high refresh rate displays. While most people would easily notice if this were the case, some people are oblivious, hence this being an option. Also enables UseVBO for OpenGL which is off by default. This will increase CPU FPS by at least 30% depending on the binary/OS used. Takes effect after a game restart.

### bFix90FPS
If MaxClientFrameRate=90, set to 200

Checks if a player is using the default 90FPS limit and sets it to 200 instead. Even on 60Hz displays, higher FPS results in lower latency and higher smoothness because of the higher likelihood of more recent frames being sent to the display. This will create a better experience for those that have not adjusted their FPS limit. Takes effect after a game restart or returning to the main menu and reconnecting.

### bFixMasterServer
Sets the master server for the players. Options are:

    333networks
    Errorist
    333networks + Errorist
    OpenSpy

If a player has at least one Epic master server in their ini (two by default), this setting will replace their master server with the above. 333networks/Errorist are based in the Netherlands, while OpenSpy is based in New Jersey. As such, pick whichever most of the players would have the lowest ping to. Most players might already be using OpenSpy due to its higher publicity, so it may be the safer choice.
