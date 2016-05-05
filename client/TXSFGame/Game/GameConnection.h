//
//  GameConnection.h
//  TXSFGame
//
//  Created by TigerLeung on 12-12-5.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

struct BaseHead {
	int tag;
	long length;
};
typedef struct BaseHead BaseHead;

typedef enum{
	LOGIN_TYPE_LOCAL	= 0,
	LOGIN_TYPE_SNS		= 1,
}LOGIN_TYPE;

typedef enum{
	SOCKET_ACTION_TYPE_NONE				= 0,
	SOCKET_ACTION_TYPE_LOGIN			= 101,
	SOCKET_ACTION_TYPE_LOGIN_ED			= 102,
	SOCKET_ACTION_TYPE_ENTER_SERVER		= 201,
	SOCKET_ACTION_TYPE_ENTER_SERVER_ED	= 202,
	SOCKET_ACTION_TYPE_ENTER_GAME		= 301,
}SOCKET_ACTION_TYPE;
//
#define ConnPost_gameResignActive @"ConnPost_gameResignActive"
#define ConnPost_gameEnterBackground @"ConnPost_gameEnterBackground"
#define ConnPost_gameEnterForeground @"ConnPost_gameEnterForeground"
#define ConnPost_gameBecomeActive @"ConnPost_gameBecomeActive"
//
#define ConnPost_getServersInfo @"ConnPost_getServersInfo"
#define ConnPost_getServersInfoError @"ConnPost_getServersInfoError"

#define ConnPost_getUpdateDatabaseStart @"ConnPost_updateDB_start"
#define ConnPost_getUpdateProgress @"ConnPost_updateDB_progress"
#define ConnPost_getUpdateReload @"ConnPost_updateDB_reload"
#define ConnPost_getUpdateDatabaseOver @"ConnPost_updateDB_Over"

#define ConnPost_passStart @"ConnPost_passStart"
#define ConnPost_selectServerPlayer @"ConnPost_selectServerPlayer"

#define ConnPost_login @"ConnPost_login"
#define ConnPost_logout @"ConnPost_logout"
#define ConnPost_playerList @"ConnPost_playerList"
#define ConnPost_init @"ConnPost_init"
#define ConnPost_getPlayerInfo @"ConnPost_getPlayerInfo"
#define ConnPost_start @"ConnPost_start"
#define ConnPost_enter @"ConnPost_enter"
#define ConnPost_InGame_New @"ConnPost_InGame_New"
//#define ConnPost_InGame_Change @"ConnPost_InGame_Change"
#define ConnPost_disconnect @"ConnPost_disconnect"
#define ConnPost_connect_timeout @"ConnPost_connect_timeout"

#define ConnPost_taskPush @"ConnPost_taskPush"
#define ConnPost_MapPush @"ConnPost_MapPush"

#define ConnPost_MailPush @"ConnPost_MailPush"
#define ConnPost_ChatPush @"ConnPost_ChatPush"

#define ConnPost_updatePlayerUpLevel @"ConnPost_updatePlayerUpLevel"
#define ConnPost_updatePlayerInfo @"ConnPost_updatePlayerInfo"
#define ConnPost_updatePackage @"ConnPost_updatePackage"
#define ConnPost_updatePackageLuck @"ConnPost_updatePackageLuck"
#define ConnPost_finishChapter @"ConnPost_finishChapter"

#define ConnPost_skipChapterReload @"ConnPost_skipChapterReload"

#define ConnPost_loadMapStart @"ConnPost_loadMap_start"
#define ConnPost_loadMapInit @"ConnPost_loadMapInit"
#define ConnPost_loadMapProgress @"ConnPost_loadMap_progress"
#define ConnPost_loadMapOver @"ConnPost_loadMapOver"
#define ConnPost_loadMapOver @"ConnPost_loadMapOver"
//fix chao
#define ConnPost_updateRolelist @"ConnPost_updateRolelist"
//#define ConnPost_roleChangeEquip @"ConnPost_roleChangeEquip"
//#define ConnPost_repeatName @"ConnPost_repeatName"
#define ConnPost_CreateRoleError @"ConnPost_CreateRoleError"
#define ConnPost_playerSit @"ConnPost_playerSit"

#define ConnPost_goodsGive @"ConnPost_goodsGive"

#define ConnPost_WorldBoss_Start @"ConnPost_WorldBoss_Start"
#define ConnPost_WorldBoss_Hurts @"ConnPost_WorldBoss_Hurts"
#define ConnPost_WorldBoss_Rank @"ConnPost_WorldBoss_Rank"


#define ConnPost_BossInfo_time_setting_worldboss @"ConnPost_BossInfo_time_setting_worldboss"
#define ConnPost_BossInfo_time_setting_unionboss @"ConnPost_BossInfo_time_setting_unionboss"

#define ConnPost_BossInfo_time_setting @"ConnPost_BossInfo_time_setting"
#define ConnPost_WorldBoss_timeOut @"ConnPost_WorldBoss_timeOut"
#define ConnPost_allyBoss_timeOut @"ConnPost_allyBoss_timeOut"
#define ConnPost_WorldBoss_coolOff_timeOut @"ConnPost_WorldBoss_coolOff_timeOut"
#define ConnPost_allyBossRank_Start @"ConnPost_allyBossRank_Start"
#define ConnPost_allyBossRank_Hurts @"ConnPost_allyBossRank_Hurts"
#define ConnPost_allyBossRank_Rank @"ConnPost_allyBossRank_Rank"

//end

// 狩龙
#define ConnPost_Dragon_enterRoom			@"ConnPost_Dragon_enterRoom"
#define ConnPost_Dragon_exitRoom			@"ConnPost_Dragon_exitRoom"
#define ConnPost_Dragon_startFight			@"ConnPost_Dragon_startFight"	// 开战广播
#define ConnPost_Dragon_killMonsterStart	@"ConnPost_Dragon_killMonsterStart"
#define ConnPost_Dragon_killMonsterEnd		@"ConnPost_Dragon_killMonsterEnd"
#define ConnPost_Dragon_fire				@"ConnPost_Dragon_fire"		// 打炮
#define ConnPost_Dragon_bossHp				@"ConnPost_Dragon_bossHp"	// boss血量
#define ConnPost_Dragon_hard				@"ConnPost_Dragon_hard"		// 耐久度
#define ConnPost_Dragon_worldMap			@"ConnPost_Dragon_worldMap"
#define ConnPost_Dragon_warChoose			@"ConnPost_Dragon_warChoose"
#define ConnPost_Dragon_result				@"ConnPost_Dragon_result"
// end

#define ConnPost_wearEquipment @"ConnPost_wearEquipment"

#define ConnPost_achiUpdate @"ConnPost_achiUpdate"

#define ConnPost_writeDataSecurity @"ConnPost_writeDataSecurity"


#define ConnPost_AllyApply_success @"ConnPost_AllyApply_success"
#define ConnPost_KickApply_success @"ConnPost_KickApply_success"

#define ConnPost_AllyParTeamInfo @"ConnPost_AllyParTeamInfo"
#define ConnPost_AllyParTeamDisband @"ConnPost_AllyParTeamDisband"
#define ConnPost_AllyParTeamFigthInfo @"ConnPost_AllyParTeamFigthInfo"


#define ConnPost_request_showInfo   @"ConnPost_request_showInfo"

#define ConnPost_slot_move_start	@"ConnPost_slot_move_start"
#define ConnPost_slot_move_end		@"ConnPost_slot_move_end"

#define ConnPost_window_close		@"ConnPost_window_close"
#define ConnPost_updatecbe			@"ConnPost_updatecbe"
#define ConnPost_updateChannel		@"ConnPost_updateChannel"
#define ConnPost_response_error @"ConnPost_response_error"

#define ConnPost_ally_map_crystal_enter @"ConnPost_ally_map_crystal_enter"

static inline BOOL checkResponseStatus(NSDictionary*response){
	int status = [[response objectForKey:@"s"] intValue];
	if(status==1) return YES;
	return NO;
}
static inline NSString * getResponseFunc(NSDictionary*response){
	return [response objectForKey:@"f"];
}
static inline NSString * getResponseMessage(NSDictionary*response){
	return [[response objectForKey:@"m"] stringValue];
}
static inline id getResponseData(NSDictionary*response){
	return [response objectForKey:@"d"];
}

@class AsyncSocket;
@class GCDAsyncSocket;
@class GameConnectionRequest;

@interface GameConnection : NSObject{
	
	int currentServerId;
	int currentPlayerId;
	int recommendServerId;
	
	NSDictionary * serverInfo;
	
	SOCKET_ACTION_TYPE action_type;
	LOGIN_TYPE login_type;
	
	NSDictionary * userInfo;
	NSDictionary * loginInfo;
	NSDictionary * newInfo;
	
	long long server_time;
	
	//GCDAsyncSocket * asyncSocket;
	AsyncSocket * asyncSocket;
	
	GameConnectionRequest * cRequest;
	NSMutableData * receiveData;
	
	int did_pid;
	
	//int new_rid;
	//NSString * new_username;
	
}

@property(nonatomic,assign) int recommendServerId;
@property(nonatomic,assign) int currentServerId;
@property(nonatomic,assign) int currentPlayerId;
@property(nonatomic,assign) NSDictionary * serverInfo;
@property(nonatomic,assign) long long server_time;

+(GameConnection*)share;
+(void)stopAll;

+(void)freeRequest:(id)target;

+(void)request:(NSString*)action data:(NSDictionary*)data target:(id)target call:(SEL)call;
+(void)request:(NSString*)action format:(NSString*)format target:(id)target call:(SEL)call;
//add soul
+(void)request:(NSString*)action data:(NSDictionary*)data target:(id)target call:(SEL)call arg:(NSDictionary*)_arg;
+(void)request:(NSString*)action format:(NSString*)format target:(id)target call:(SEL)call arg:(NSDictionary*)_arg;
//
+(void)post:(NSString*)post object:(id)object;
+(void)addPost:(NSString*)post target:(id)target call:(SEL)call;
+(void)removePostTarget:(id)target;

-(void)loadServersInfo;

-(BOOL)checkCurrentServerCanEnter;
-(BOOL)checkServerCanEnter:(int)sid;

-(NSDictionary*)getServerInfoById:(int)sid;

-(NSString*)getServerHost:(int)sid;
-(int)getServerPort:(int)sid;

-(NSArray*)getAllActivity;
-(NSArray*)getAllServer;
-(NSString*)getDBPath;
-(NSString*)getGameApiPath:(int)sid;
-(void)getServerPlayers:(NSDictionary*)data server:(int)ser target:(id)target call:(SEL)call;

//-(void)connection;
-(void)disconnect;

-(BOOL)isConnection;
-(BOOL)isDidEnterServer;

//-(void)login:(NSString*)name password:(NSString*)pass;
-(void)loginSNSUser:(NSDictionary*)data;
-(void)loginLocalUser;
-(void)logout;
-(void)getPlayers;

-(void)newPlayer:(NSString*)name rid:(int)rid;
-(void)enterCurrentPlayer;
-(void)enterPlayer:(int)pid;

@end

@interface GameConnectionRequest : NSObject{
	
	int tag;
	
	id target;
	SEL call;
	//add soul
	//参数操作
	NSDictionary *argument;
	
	NSMutableDictionary * requestDict;
	NSMutableData * requestData;
	
	long responseLength;
	NSMutableData * responseData;
	
}
@property(nonatomic,readonly) int tag;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL call;
//add soul
@property(nonatomic,retain)NSDictionary *args;

@property(nonatomic,readonly) NSMutableData * requestData;

+(NSData*)BlockPing;

+(GameConnectionRequest*)request;
+(void)addToMemory:(id)target;
+(void)removeMemory:(id)target;

+(void)didSendDataWithTag:(int)tag;
+(void)didReceiveData:(NSData*)data;

+(void)freeRequest:(id)target;

-(id)initWithTag:(int)_tag;

-(void)free;

-(void)action;

-(void)setRequestAction:(NSString*)action;
-(void)setRequestFromDict:(NSDictionary*)dict;
-(void)setRequestFromFormat:(NSString*)format;

//-(void)receiveData:(NSData*)data length:(long)length;
-(void)receiveData:(NSData*)data;

@end