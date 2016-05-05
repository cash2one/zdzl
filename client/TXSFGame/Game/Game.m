//
//  Game.m
//  TXSFGame
//
//  Created by chao chen on 12-10-15.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "Game.h"
#import "GameLayer.h"
#import "GameUI.h"
#import "GameConfigure.h"
#import "RoleManager.h"
#import "NPCManager.h"
#import "TaskManager.h"
#import "StageManager.h"
#import "GameConnection.h"
#import "GameStart.h"
#import "GameDB.h"
#import "GameLoading.h"
#import "GameEffects.h"
#import "MapManager.h"
#import "Window.h"
#import "GameMail.h"
#import "AlertManager.h"
#import "AbyssManager.h"
#import "TimeBox.h"
#import "FightManager.h"
#import "MiningManager.h"
#import "FishingManager.h"
#import "WorldMap.h"
#import "UnionManager.h"
#import "GameSoundManager.h"
#import "GameTouchPoint.h"
#import "ShowItem.h"
#import "WorldBossManager.h"
#import "FightAnimation.h"
#import "PlayerDataHelper.h"
#import "RolePlayer.h"
#import "PlayerSit.h"
//#import "FightManager.h"
//#import "GameWidgetManager.h"
#import "GameReporter.h"
#import "SNSHelper.h"
#import "SocialHelper.h"
#import "RoleOption.h"

#import "GameResourceLoader.h"
#import "GameTipsHelper.h"
#import "intro.h"
#import "StageTask.h"

#import "UnionBossManager.h"
#import "GameActivity.h"
#import "InAppBrowser.h"
#import "AdServiceHelper.h"

#import "GameConnectionHelper.h"

#import "Reachability.h"
#import "ChatPanelBase.h"
#import "WorldBossTips.h"
#import "MessageManager.h"

#import "DragonReadyData.h"
#import "DragonFightData.h"
#import "DragonReadyManager.h"
#import "DragonFightManager.h"
#import "DragonTips.h"

static Game *s_Game=nil;
static int		map_id;
static SEL parentAction;
static BOOL isRetinaDisplay;
static BOOL isEnterGame;

static NSString * blockDevice[] = {
	//@"iPad1",
	//@"iPod4",
	//@"x86_64",
};

static NSString * UncompatibleDevice[] = {
	@"iPad1"
	//@"iPod4",
	//@"x86_64",
};


@implementation Game

@synthesize bStartGame;
@synthesize isInGameing;
@synthesize isCanBackToMap;
@synthesize isTurnning;

+(BOOL)iPhoneRuningOnGame{
	return iPhoneRuningOnGame();
}
+(void)isRetinaDisplay:(BOOL)isRD{
	isRetinaDisplay = isRD;
}
+(BOOL)supportRetinaDisplay{
	return isRetinaDisplay;
}

+(void)receiveMemoryWarning{
	[GameDB freeMemory];
	[Game cleanMemory];
}

+(void)cleanMemory{
	
	//[FightAnimation checkMemoryUnshowStand];
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	[[CCDirector sharedDirector] purgeCachedData];
	
}

+(BOOL)checkUncompatibleDevice{
	NSString * model = getDeviceName();
	int totalDevice = (sizeof(UncompatibleDevice)/sizeof(UncompatibleDevice[0]));
	for(int i=0;i<totalDevice;i++){
		if(isEqualToKey(model, UncompatibleDevice[i])) return NO;
	}
	return YES;
}

+(BOOL)checkDeviceTypeIsCanRun{
	
	if([Game iPhoneRuningOnGame] && !isRetinaDisplay){
		CCLOG(@"\n\n===Game run on iPhone[1,3G,3GS]===\n\n");
		return NO;
	}
	
	NSString * model = getDeviceName();
	
	CCLOG(@"\n\n===Game run on %@===\n\n",model);
	
	int totalDevice = (sizeof(blockDevice)/sizeof(blockDevice[0]));
	for(int i=0;i<totalDevice;i++){
		if(isEqualToKey(model, blockDevice[i])) return NO;
	}
	return YES;
}
+(Game*)shared{
    if (nil == s_Game){
        s_Game = [Game node] ;
    }
    return s_Game;
}
+(void)setMapId:(int)_mid{
	map_id = _mid;
}

+(BOOL)checkVersion:(NSString*)ver_server{
	
#ifdef GAME_SNS_TYPE
#if GAME_SNS_TYPE==1
	return NO;
#endif
#if GAME_SNS_TYPE==10
	return NO;
#endif
#endif
	
	BOOL isHasNewVersion = NO;
	
	NSString * ver_client = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	NSArray * ver_server_nums = [ver_server componentsSeparatedByString:@"."];
	NSArray * ver_client_nums = [ver_client componentsSeparatedByString:@"."];
	
	if([ver_server_nums count]==3 && [ver_client_nums count]==3){
		int v1 = [[ver_server_nums objectAtIndex:0] intValue] * 10000;
		int v2 = [[ver_client_nums objectAtIndex:0] intValue] * 10000;
		v1 += [[ver_server_nums objectAtIndex:1] intValue] * 100;
		v2 += [[ver_client_nums objectAtIndex:1] intValue] * 100;
		v1 += [[ver_server_nums objectAtIndex:2] intValue];
		v2 += [[ver_client_nums objectAtIndex:2] intValue];
		if(v1>v2){
			isHasNewVersion = YES;
		}
	}else{
		isHasNewVersion = YES;
	}
	
	return isHasNewVersion;
}


+(void)resignActive{
	CCLOG(@"GAME resignActive");
    [GameConnection post:ConnPost_gameResignActive object:nil];
}
+(void)enterBackground{
	CCLOG(@"GAME enterBackground");
    [GameConnection post:ConnPost_gameEnterBackground object:nil];
}

+(void)enterForeground{
	CCLOG(@"GAME enterForeground");
    [GameConnection post:ConnPost_gameEnterForeground object:nil];
}

+(void)becomeActive{
	
	CCLOG(@"GAME becomeActive");
    [GameConnection post:ConnPost_gameBecomeActive object:nil];
	
	if(isEnterGame){
		if(s_Game){
			if([[GameConnection share] isConnection]){
				[RoleManager reloadPlayers];
			}else{
				if(s_Game.isInGameing){
					[Game reenterGame];
				}
			}
		}
	}else{
		isEnterGame = YES;
	}
	
}

+(void)quitGame{
	
	[GameConnection stopAll];
	//[GameConfigure stopAll];
	//[GameDB stopAll];
	[s_Game endAll];
	
	[GameStart show];
	[GameLoading delayHide];
	
}

+(void)reenterGame{
	
	[GameConnection stopAll];
	//[GameConfigure stopAll];
	//[GameDB stopAll];
	[s_Game endAll];
	[NSTimer scheduledTimerWithTimeInterval:0.05f
									 target:self selector:@selector(doReenterGame)
								   userInfo:nil repeats:NO];
}
+(void)doReenterGame{
	[GameConnection post:ConnPost_passStart object:nil];
}

+(BOOL)checkIsInGameing{
	if(s_Game){
		return s_Game.isInGameing;
	}
	return NO;
}

-(void)dealloc{
	[GameConnection removePostTarget:self];
	[super dealloc];
}

-(void)addChild:(CCNode *)node z:(NSInteger)z{
	if(!node){
		return;
	}
	if(node.parent){
		return;
	}
	[super addChild:node z:z];
}

-(void)onEnter{
	
	[super onEnter];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	BOOL isCleanCache = [defaults boolForKey:@"zl_clean_cache"];
	
	NSString * clientVersion = [defaults stringForKey:@"zdzl_version"];
	NSString * bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
	if(!isEqualToKey(clientVersion, bundleVersion)){
		isCleanCache = YES;
	}
	if(isCleanCache){
		[GameDB cleanCache];
		[GameResourceLoader cleanCache];
	}
	[defaults setBool:NO forKey:@"zl_clean_cache"];
	[defaults setObject:bundleVersion forKey:@"zdzl_version"];
	[defaults synchronize];
	
	BOOL isUse3G = [defaults boolForKey:@"zl_use3g"];
	BOOL isCanRunForNetwork = YES;
	Reachability * reachability = [Reachability reachabilityWithHostName:@"www.baidu.com"];
	switch([reachability currentReachabilityStatus]){
		case NotReachable:
			isCanRunForNetwork = NO;
			break;
		case ReachableViaWWAN:
			if(!isUse3G){
				isCanRunForNetwork = NO;
			}
			break;
		case ReachableViaWiFi:
			break;
	}
	
	if(!isCanRunForNetwork){
		[GameLoading isInGameing:NO];
		[GameLoading showMessage:@"" loading:NO];
		[GameLoading showError:NSLocalizedString(@"game_network_error", nil)];
		return;
	}
	
    if(![Game checkDeviceTypeIsCanRun]){
		NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
		NSString * appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
		
		NSString * error = [NSString stringWithFormat:NSLocalizedString(@"game_no_support", nil),appName,getDeviceName()];
		[GameLoading isInGameing:NO];
		[GameLoading showMessage:@"" loading:NO];
		[GameLoading showError:error];
		//[GameTouchPoint start];
		return;
	}
	
	[GameConnection addPost:ConnPost_getServersInfo target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_getServersInfoError target:self call:@selector(onConnection:)];
	
	[GameConnection addPost:ConnPost_getUpdateDatabaseStart target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_getUpdateProgress target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_getUpdateReload target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_getUpdateDatabaseOver target:self call:@selector(onConnection:)];
	
	[GameConnection addPost:ConnPost_passStart target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_selectServerPlayer target:self call:@selector(onConnection:)];
	
	[GameConnection addPost:ConnPost_login target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_playerList target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_init target:self call:@selector(onConnection:)];
	
	[GameConnection addPost:ConnPost_disconnect target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_connect_timeout target:self call:@selector(onConnection:)];
	
	[GameConnection addPost:ConnPost_start target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_enter target:self call:@selector(onConnection:)];
	[GameConnection addPost:ConnPost_InGame_New target:self call:@selector(onConnection:)];
	//[GameConnection addPost:ConnPost_InGame_Change target:self call:@selector(onConnection:)];
	
	[GameConnection addPost:ConnPost_loadMapStart target:self call:@selector(onLoadingMap:)];
	[GameConnection addPost:ConnPost_loadMapInit target:self call:@selector(onLoadingMap:)];
	[GameConnection addPost:ConnPost_loadMapProgress target:self call:@selector(onLoadingMap:)];
	[GameConnection addPost:ConnPost_loadMapOver target:self call:@selector(onLoadingMap:)];
	[GameConnection addPost:ConnPost_CreateRoleError target:self call:@selector(onCreateError:)];
	
	[GameConnection addPost:ConnPost_goodsGive target:self call:@selector(onGoodsGive:)];
	
	[GameLoading isInGameing:NO];
	[GameLoading showMessage:@"" loading:NO];
	[GameTouchPoint start];
	
	[GameResourceLoader downloadPercentHandle:[GameLoading class]];
	
	isCanBackToMap = YES;
	isMustCheckLogin = YES;
	
	[[GameConfigure shared] start];
	[[AdServiceHelper shared] sendTracking];
	
	//[SNSHelper initSNS];
	[[SNSHelper shared] start:self];
	[[SNSHelper shared] checkVersion];
	
}

-(void)startInitServerInfo{
	NSDictionary * info = [GameConnection share].serverInfo;
	if([GameConfigure shared].serverId>0){
		[GameConnection share].currentServerId = [GameConfigure shared].serverId;
	}else{
		[GameConfigure shared].serverId = [GameConnection share].currentServerId;
	}
	[GameResourceLoader shared].downloadPath = [info objectForKey:@"res_url"];
	
	int db_ver = [[info objectForKey:@"db_ver"] intValue];
	[[GameDB shared] checkOutVersion:db_ver];
}

-(void)onConnection:(NSNotification*)notification{
	
	if([notification.name isEqualToString:ConnPost_getServersInfo]){
		
		NSDictionary * info = [GameConnection share].serverInfo;
		
		NSString * server_version = [info objectForKey:@"client_ver"];
		if([Game checkVersion:server_version]){
			
			//[[GameLoading share] showMessage:@"请升级到最新游戏版本!"];
			
			NSString * game_name = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
			
			UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"game_up_tips",nil)
															 message:[NSString stringWithFormat:NSLocalizedString(@"game_up_new_version",nil),game_name,server_version]
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"cancel",nil)
												   otherButtonTitles:NSLocalizedString(@"update",nil),nil];
			[alert show];
			[alert release];
			
		}else{
			[self startInitServerInfo];
		}
		
		return;
		
	}else if([notification.name isEqualToString:ConnPost_getServersInfoError]){
		[[GameLoading share] showMessage:NSLocalizedString(@"game_network_error", nil)];
		return;
	}
	
	if([notification.name isEqualToString:ConnPost_getUpdateDatabaseStart]){
		[[GameLoading share] showMessage:NSLocalizedString(@"loading...", nil)];
		return;
	}else if([notification.name isEqualToString:ConnPost_getUpdateProgress]){
		
		float index = [[notification.object objectForKey:@"index"] floatValue];
		float total = [[notification.object objectForKey:@"total"] floatValue];
		float percent = (float)index/(total*2.0);
		NSString * msg = [NSString stringWithFormat:NSLocalizedString(@"loading_percent", nil),percent*100,@"%"];
		[[GameLoading share] showMessage:msg];
		[[GameLoading share] showPercent:percent];
		
		return;
		
	}else if([notification.name isEqualToString:ConnPost_getUpdateReload]){
		
		float index = [[notification.object objectForKey:@"index"] floatValue];
		float total = [[notification.object objectForKey:@"total"] floatValue];
		float percent = (float)(index+total)/(total*2.0);
		NSString * msg = [NSString stringWithFormat:NSLocalizedString(@"loading_percent", nil),percent*100,@"%"];
		[[GameLoading share] showMessage:msg];
		[[GameLoading share] showPercent:percent];
		
		return;
	}else if([notification.name isEqualToString:ConnPost_getUpdateDatabaseOver]){
		CCLOG(@" Connection update db finish");
		
		//[[AdServiceHelper shared] sendTracking];
		
		[GameLoading hide];
		[GameStart show];
		
		[[GameSoundManager shared] playWelcome];
		[GameFilter share];
		
		if(![[SNSHelper shared] isLogined] && isMustCheckLogin){
			[[SNSHelper shared] login];
		}
		isMustCheckLogin = NO;
		
		return;
	}
	
	if([notification.name isEqualToString:ConnPost_disconnect]){
		
		CCLOG(@"ConnPost_disconnect");
		
		if(isInGameing){
			if([FightManager isFighting]){
				[FightManager shared].isPlay = NO;
			}
			if([RoleManager shared].player){
				[[RoleManager shared].player stopMoveAndTask];
			}
		}
		
		[[AlertManager shared] showError:NSLocalizedString(@"game_netword_disconn", nil)
								  target:[Game class]
								 confirm:@selector(quitGame)
								  father:self];
		
		return;
	}
	
	if([notification.name isEqualToString:ConnPost_connect_timeout]){
		[[AlertManager shared] showError:NSLocalizedString(@"game_netword_timeout", nil)
								  target:[Game class]
								 confirm:@selector(quitGame)
								  father:self];
		return;
	}
	
	if([notification.name isEqualToString:ConnPost_passStart]){
		[self loginGame];
	}
	
	if([notification.name isEqualToString:ConnPost_selectServerPlayer]){
		
		int sid = [[notification.object objectForKey:@"sid"] intValue];
		int pid = [[notification.object objectForKey:@"pid"] intValue];
		
		if(isInGameing){
			
			if(sid==[GameConfigure shared].serverId){
				if(pid<0){
					[GameLoading hide];
					[GameStart create];
				}else{
					[self endAll];
					[[GameConnection share] enterPlayer:pid];
				}
			}else{
				
				[self endAll];
				[[GameConnection share] logout];
				
				[GameConfigure shared].serverId = sid;
				[GameConnection share].currentServerId = sid;
				[GameConnection share].currentPlayerId = pid;
				
				[self loginGame];
				
			}
		}else{
			
			[GameConfigure shared].serverId = sid;
			[GameConnection share].currentServerId = sid;
			[GameConnection share].currentPlayerId = pid;
			
			[self loginGame];
		}
		
	}
	
	if([notification.name isEqualToString:ConnPost_login]){
		CCLOG(@"Connection login");
		[[GameConnection share] getPlayers];
		
	}else if([notification.name isEqualToString:ConnPost_InGame_New]){
		
		[self endAll];
		[GameLoading showMessage:@"" loading:YES];
		
	}else if([notification.name isEqualToString:ConnPost_playerList]){
		
		CCLOG(@" Connection player list");
		
		if([[GameConfigure shared] getPlayerCount]==0){
			[GameConnection share].currentPlayerId = -1;
		}
		
		if([GameConnection share].currentPlayerId==0){
			[GameConnection share].currentPlayerId = [[GameConfigure shared] getLastLoginPlayerId];
		}
		
		if([GameConnection share].currentPlayerId<0){
			[GameLoading hide];
			[GameStart create];
		}else{
			[[GameConnection share] enterCurrentPlayer];
		}
		
	}else if([notification.name isEqualToString:ConnPost_init]){
		
		//TODO on load user data
		CCLOG(@" Connection init");
		
	}else if([notification.name isEqualToString:ConnPost_start]){
		
		CCLOG(@" Connection start");
		[GameStart hide];
		
		//[[GameLoading share] showMessage:@"进入中..."];
		[GameLoading showMessage:NSLocalizedString(@"starting",nil) loading:YES];
		[[GameLoading share] showPercent:0.0f];
		
	}
	
	if([notification.name isEqualToString:ConnPost_enter]){
		
		[NSTimer scheduledTimerWithTimeInterval:0.001f
										 target:self
									   selector:@selector(startAll)
									   userInfo:nil
										repeats:NO];
		
		//[[GameConnection share] logout];
		CCLOG(@" Connection enter ");
	}
	
}

-(void)fireParentAction{
	[NSTimer scheduledTimerWithTimeInterval:0.001f
									 target:self
								   selector:parentAction
								   userInfo:nil
									repeats:NO];
	parentAction = nil;
}

-(void)loginGame{
	if([[SNSHelper shared] isLogined]){
		[GameStart hide];
		[GameLoading showMessage:NSLocalizedString(@"login",nil) loading:YES];
		[[GameLoading share] showPercent:0.0f];
		[[GameConnection share] loginSNSUser:[[SNSHelper shared] getUserInfo]];
	}else{
		parentAction = _cmd;
		[[SNSHelper shared] loginUser];
	}
}

-(void)onLoadingMap:(NSNotification*)notification{
	
	if([notification.name isEqualToString:ConnPost_loadMapStart]){
		
		map_count = 0;
		map_total = [notification.object intValue];
		
		CCLOG(@"ConnPost_loadMapStart %d / %d",map_count,map_total);
		
		[[GameLoading share] showPercent:0.0f];
		
		return;
	}
	if([notification.name isEqualToString:ConnPost_loadMapInit]){
		
		CCLOG(@"ConnPost_loadMapInit");
		
		[self checkSystemByMapInit];
		return;
	}
	if([notification.name isEqualToString:ConnPost_loadMapProgress]){
		map_count++;
		
		CCLOG(@"ConnPost_loadMapProgress %d / %d",map_count,map_total);
		
		if(map_count==map_total){
			[GameConnection post:ConnPost_loadMapOver object:nil];
		}else{
			[[GameLoading share] showPercent:(float)map_count/map_total];
		}
		return;
	}
	
	if([notification.name isEqualToString:ConnPost_loadMapOver]){
		
		CCLOG(@"ConnPost_loadMapOver");
		
		[GameLoading hide];
		
		//[self checkSystemByMapOver];
		[NSTimer scheduledTimerWithTimeInterval:0.05
										 target:self
									   selector:@selector(checkSystemByMapOver)
									   userInfo:nil
										repeats:NO];
		
	}
	
}

-(void)onCreateError:(NSNotification*)notification{
	
	[GameLoading hide];
	[GameStart create];
	
	NSDictionary * data = notification.object;
	id m = [data objectForKey:@"m"];
	if([m isKindOfClass:[NSNumber class]]){
		if ([m intValue] == 10) {
			[NSTimer scheduledTimerWithTimeInterval:1.0f
											 target:self
										   selector:@selector(showDoubleNameError)
										   userInfo:nil repeats:NO];
			//[ShowItem showItemAct:NSLocalizedString(@"game_has_palyer_name", nil)];
		}
	}
	if([m isKindOfClass:[NSString class]]){
		[ShowItem showItemAct:m];
	}
	
}

-(void)onGoodsGive:(NSNotification*)notification{
	// 如果首次充值，撤销首充状态
	BOOL isFirst = [[GameConfigure shared] checkPlayerIsFirstRecharge];
	if (isFirst) {
		[[GameConfigure shared] closePlayerFirstRecharge];
		[[GameUI shared] updateStatus];
	}
}

-(void)showDoubleNameError{
	[ShowItem showItemAct:NSLocalizedString(@"game_has_palyer_name", nil)];
}

-(void)checkTime:(ccTime)time{
	[GameConnection share].server_time++;
}

-(void)startAll{
	
	NSDictionary * mapInfo = [[GameConfigure shared] getUserMapInfo];
	if([MapManager checkDownloadMapSource:mapInfo target:self call:_cmd]){
		return;
	}
	
	////////////////////////////////////////////////////////////////////////////
	
	NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	NSDictionary * server = [[GameConnection share] getServerInfoById:[GameConnection share].currentServerId];
	
	NSMutableDictionary * other = [NSMutableDictionary dictionary];
	[other setObject:[player objectForKey:@"id"] forKey:@"playerId"];
	[other setObject:[player objectForKey:@"name"] forKey:@"playerName"];
	[other setObject:[NSString stringWithFormat:@"%d",[[server objectForKey:@"sid"] intValue]] forKey:@"serverId"];
	[other setObject:[server objectForKey:@"name"] forKey:@"serverName"];
	
	[[SNSHelper shared] enterUserInfo:other];
	
	////////////////////////////////////////////////////////////////////////////
	
	//[[ListenChatData share].chatSavingHistory removeAllObjects];
	[GameTouchPoint start];
	
	[GameFilter stopAll];
	
	self.bStartGame = YES;
	self.isInGameing = YES;
	
	[GameLoading isInGameing:YES];
	[[GameConfigure shared] loadData];
	
	[self addChild:[GameLayer shared] z:0];
	[self addChild:[GameUI shared] z:10];
	
	[[GameLayer shared] showMap];
	
	[[MessageManager share] start];
	
	//TODO 延时打开
	[[TaskManager shared] start];
	
	[[GameUI shared] displayUI];
	[[GameUI shared] updateStatus];
	
	[[PlayerSitManager shared] start];
	
	[WorldBossManager startAll];
	
	[UnionBossManager startAll];
	
	[DragonReadyData startAll];
	[DragonFightData startAll];
	[DragonReadyManager startAll];
	[DragonFightManager startAll];
	
	NSDictionary * serverInfo = [GameConnection share].serverInfo;
	[GameReporter shared].baseUri = [serverInfo objectForKey:@"bug_url"];
	[GameReporter shared].winSize = [[CCDirector sharedDirector] winSize];
	[GameReporter shared].reportData = [self getLoginUserInfo];
	[[GameReporter shared] start];
	
	[self schedule:@selector(checkTime:) interval:1.0f];
	
	[[GameMail shared] start];
	[GameTipsHelper start];
	
	[[StageManager shared] checkStageOnInit];
    
    [[GameActivity shared] checkStartActivity];
	
	[[GameConnectionHelper shared] start];
	
}

-(NSDictionary*)getLoginUserInfo{
	
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	int currentServerId = [GameConnection share].currentServerId;
	NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	NSDictionary * server = [[GameConnection share] getServerInfoById:currentServerId];
	NSDictionary * serverInfo = [GameConnection share].serverInfo;
	NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
	
	[result setObject:[server objectForKey:@"id"] forKey:@"serverId"];
	[result setObject:[server objectForKey:@"name"] forKey:@"serverName"];
	[result setObject:[server objectForKey:@"host"] forKey:@"serverHost"];
	[result setObject:[server objectForKey:@"port"] forKey:@"serverPort"];
	
	[result setObject:[NSNumber numberWithInt:[SNSHelper getHelperType]] forKey:@"snsType"];
	[result setObject:[[SNSHelper shared] getUserId] forKey:@"snsUserId"];
	
	[result setObject:[playerInfo objectForKey:@"uid"] forKey:@"uid"];
	[result setObject:[playerInfo objectForKey:@"id"] forKey:@"playerId"];
	[result setObject:[playerInfo objectForKey:@"name"] forKey:@"playerName"];
	
	[result setObject:version forKey:@"clientVersion"];
	[result setObject:[serverInfo objectForKey:@"db_ver"] forKey:@"dbVersion"];
	
	return result;
}

-(void)addChild:(CCNode *)node z:(NSInteger)z tag:(NSInteger)tag{
	if (node.parent) {
		CCLOG(@"Game addChild again!");
		return ;
	}
	[super addChild:node z:z tag:tag];
}

-(void)endAll{
	
	self.isInGameing = NO;
	
	[GameConnectionHelper stopAll];
	
	[GameActivity stopAll];
	
	[GameStart hide];
	
	[GameLoading isInGameing:NO];
	
	[GameResourceLoader stopAll];
	
	[GameTipsHelper stopAll];
	[GameTouchPoint stopAll];
	
	
	[MessageManager stopAll];
	
	[RoleOption stopAll];
	[TaskManager stopAll];
	[GameMail stopAll];
	[WorldMap stopAll];
	[FishingManager stopAll];
	[MiningManager stopAll];
	[TimeBox stopAll];
	[WorldBossManager stopAll];
	
	[UnionBossManager stopAll];
	
	[DragonReadyData stopAll];
	[DragonFightData stopAll];
	[DragonReadyManager stopAll];
	[DragonFightManager stopAll];
	
	[AbyssManager stopAll];
	[UnionManager stopAll];
	[StageManager stopAll];
	[GameEffects stopAll];
	[AlertManager stopAll];
	[FightManager stopAll];
	[PlayerSitManager stopAll];
	[Intro stopAll];
	[StageTask stopAll];
	
	//[GameSoundManager stopAll];
	
	[GameUI stopAll];
	[Window stopAll];
	[GameLayer stopAll];
	
	[GameFilter stopAll];
	[PlayerDataHelper stopAll];
	[SocialHelper stopAll];
	[GameReporter stopAll];
	
	[self removeAllChildrenWithCleanup:YES];
	[GameLoading stopAll];
	
	[GameTouchPoint start];
	[GameLoading showMessage:@"" loading:NO];
	
	//other close
	[[GameReporter shared] hide];
	[InAppBrowser hide];
	
	
};

-(void)checkSystemByMapInit{
	
	[[TaskManager shared] checkStepStatusByInit];
    //update new map npc status
	
}
-(void)checkSystemByMapOver{
	
	isCanBackToMap = YES;
	
	[MapManager shared].isLoadMapOver = YES;
	[[RoleManager shared] loadOtherPlayers];
	
	//check on Abyss map
	[AbyssManager checkStatus];
	[WorldBossManager checkStatus];
	[UnionBossManager checkStatus];
	
	[UnionManager checkStatus];
	
	[TimeBox checkStatus];
	
	[MiningManager checkStatus];
	[FishingManager checkStatus];
	
	[[TaskManager shared] checkStepStatusByOver];
	[[AlertManager shared] checkStatus];
	
	[[GameUI shared] updateStatus];
	
	//add
	[WorldBossTips updateStatus];
	[DragonTips updateStatus];
	
	[[StageManager shared] checkStageRunOnMap];
	[FightManager checkEndFight];
	
	// 在战斗处理之后
	[DragonReadyManager checkStatus];
	[DragonFightManager checkStatus];
	
}

-(void)trunToMap:(int)mid{
	map_id = mid;
	[[Intro share] hideCurrenTips];
	if ([WorldMap checkShowWorldMap:map_id now:[MapManager shared].mapId]) {
		[WorldMap show:map_id target:nil call:nil];
		return ;
	}
	[self doTrunToMap];
}

-(void)doTrunToMap{
	
	isTurnning = YES;
	
	if([MapManager checkDownloadMapSourceById:map_id target:self call:_cmd]){
		[GameLoading showMessage:NSLocalizedString(@"load_map", nil) target:nil call:nil loading:NO];
		return;
	}
	
	//[[PlayerSit share]cancelSit];
	[[PlayerSitManager shared] stopSit];
	
	//show loading... 根据mid查看地图类型,显示不同的loading效果
	[GameLoading showMessage:@"" target:self call:@selector(showMap) loading:YES];
	[[GameLoading share] showPercent:0.0f];
	
	//[self showMap];
	
}

-(void)showMap{
	
	[[MapManager shared] logParentMap];
	[[AlertManager shared] closeAlert];
	[[Window shared] removeAllWindows];
	[[GameLayer shared] removeMap];
	
	[Game cleanMemory];
	//todo
	[self scheduleOnce:@selector(doJumpMaps) delay:0.01];
	//[self scheduleOnce:@selector(doShowMap) delay:0.01];
	
}

-(void)doJumpMaps{
	NSString * fm = [NSString stringWithFormat:@"mid::%d",map_id];
	[GameConnection request:@"enterMap" format:fm target:self call:@selector(endJumpMaps:)];
}

-(void)endJumpMaps:(NSDictionary*)sender{
	if (checkResponseStatus(sender)) {
		[self doShowMap];
	}else{
		CCLOG(@"error! endJumpMaps error!");
	}
}

-(void)doShowMap{
	
	[[MapManager shared] setTargetMapId:map_id];
	[[GameLayer shared] showMap];
	[[GameUI shared] updateStatus];
	
	[WorldMap stopAll];
	
	isTurnning = NO ;
	
	if ( trunCall != nil  && trunTarget != nil) {
		[trunTarget performSelector:trunCall];
	}
	trunCall = nil;
	trunTarget = nil;
	
}

-(void)trunToMap:(int)mid target:(id)target call:(SEL)call{
	if(target!=nil && call!=nil){
		trunTarget=target;
		trunCall=call;
	}else{
		trunTarget=nil;
		trunCall=nil;
	}
	[self trunToMap:mid];
}

-(void)backToMap:(id)target call:(SEL)call{
	
	if(!isCanBackToMap) return;
	
	isTurnning = YES ;
	
	if(target!=nil && call!=nil){
		[target performSelector:call];
	}
	
	int _id = [[GameConfigure shared] getPlayerLastMapId];//获得上一次地图
	
	if (_id > 0) {
		[self trunToMap:_id];//跳转地图
	}else{
		CCLOG(@"trunToMap->0 is error");
		NSDictionary* dict = [[GameConfigure shared] getChooseChapter];
		int mid = [[dict objectForKey:@"mid"] intValue];
		[self trunToMap:mid];
	}
}

-(void)showAll{
	CCSprite * sprite;
	CCARRAY_FOREACH(_children, sprite) {
		sprite.visible = YES;
	}
}
-(void)hideOther:(CCNode*)node{
	CCSprite * sprite;
	CCARRAY_FOREACH(_children, sprite) {
		if(node!=sprite){
			sprite.visible = NO;
		}
	}
}

#pragma mark SNSHelperDelegate

-(void)didLogin:(SNSHelper*)helper{
	[self checkUserState];
}

-(void)didLogout:(SNSHelper*)helper{
	[self checkUserState];
}

-(void)checkUserState{
	
	if(isInGameing){
		if([[SNSHelper shared] isLogined]){
			//TODO nothing
			
		}else{
			[Game quitGame];

#if (GAME_SNS_TYPE==7 || GAME_SNS_TYPE==9)
		[[SNSHelper shared] loginUser];
#endif
		}
	}else{
		[GameStart updateUserInfo];
		if(parentAction!=nil){
			[self fireParentAction];
		}
	}
}

-(void)didCheckVersion:(SNSHelper*)helper action:(SNSHELPER_VERSION)action{
	
	if(action==VERSION_UPDATE_FORCE_CANCELED){
		//TODO alert error [nothing]
		return;
	}
	
	//[[GameConnection share] loadServersInfo];
	[NSTimer scheduledTimerWithTimeInterval:0.005f
									 target:[GameConnection share]
								   selector:@selector(loadServersInfo)
								   userInfo:nil
									repeats:NO];
}

-(void)pauseExit{
	//[[CCDirector sharedDirector] startAnimation];
	//[Game enterForeground];
}

-(BOOL)isEnforced{
	NSString* setting = [[GameConnection share].serverInfo objectForKey:@"client_minver"];
	if (setting != nil && setting.length > 0) {
		return [Game checkVersion:setting];
	}
	return NO;
}

#pragma mark UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
	
	NSString * _plistUrl = [[GameConnection share].serverInfo objectForKey:@"PlistUrl"];
	NSString * _url = [NSString stringWithFormat:@"%@?plf=%d", _plistUrl, GAME_SNS_TYPE];
	
	if(buttonIndex==0){
		if ([self isEnforced]) {
		    [[GameLoading share] showMessage:NSLocalizedString(@"updateGame",nil)];
			
			NSString * ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
			NSString * url = [NSString stringWithFormat:@"%@&ver=%@", _url, ver];
			
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
		}else{
			[self startInitServerInfo];
		}
	}
	if(buttonIndex==1){
		
		[[GameLoading share] showMessage:NSLocalizedString(@"updateGame",nil)];
		
		NSString * ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
		NSString * url = [NSString stringWithFormat:@"%@&ver=%@", _url, ver];
		
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
		
	}
	
}

@end
