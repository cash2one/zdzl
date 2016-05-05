//
//  FightManager.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-20.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "FightManager.h"
#import "Game.h"
#import "GameLayer.h"
#import "FightAction.h"
#import "GameUI.h"
#import "Window.h"
#import "FightPlayer.h"
#import "GameLoading.h"

#import "NSData+Base64.h"
#import "CJSONSerializer.h"
#import "CJSONDeserializer.h"
#import "NSData+GZIP.h"
#import "NSDataAES256.h"
#import "NSString+MD5Addition.h"

#import "GameConnection.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "AlertManager.h"
#import "intro.h"
#import "MovingAlert.h"
#import "PlayerSit.h"
#import "ChatPanelBase.h"

#import "Window.h"
#import "TaskTalk.h"
#import "GameEffects.h"

#define ENCODE_PW @"Rnevr58d20gsT"
#define FIGHT_SYSTEM_TIMER 0.05f

@implementation FightManager
@synthesize fightId;
@synthesize isWin;
@synthesize dieLeftkindCount;
@synthesize type;
@synthesize isPlay;

@synthesize targetDamages;
@synthesize userDamages;

//@synthesize targetsdamages = _targetsdamages;

static FightManager * fightManager;

+(FightManager*)shared{
	if(!fightManager){
		fightManager = [[FightManager alloc] init];
	}
	return fightManager;
}

+(void)cleanMemory{
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	[[CCDirector sharedDirector] purgeCachedData];
}

+(void)removeAllUI{
	
	[[GameUI shared] removeUI];
	[[GameLayer shared] removeMap];
	[[Window shared] removeAllWindows];
	[GameLayer shared].touchEnabled = NO;
	[[AlertManager shared] closeAlert];
	[MovingAlert remove];
	[PlayerSit hide];
	[FightPlayer hide];
	
}

+(BOOL)isWinFight{
	
	if(fightManager){
		return fightManager.isWin;
	}
	return NO;
}

+(int)getFightType{
	if (fightManager) {
		return fightManager.type;
	}
	
	return 0;
}

+(int)currentFightId{
	if (fightManager) {
		return fightManager.fightId;
	}
	return 0;
}

+(FightManager*)isFighting{
	return fightManager;
}

+(void)stopAll{
	
	if(fightManager){
		[fightManager release];
		fightManager = nil;
	}
	
	[FightAction stopAll];
	[FightPlayer stopAll];
}

+(void)stopAllByError{
	//[GameLoading hide];
	[GameLoading urgentHide];//立马删除重新开
	[FightManager stopAll];
	/*
	[NSTimer scheduledTimerWithTimeInterval:0.1f
									 target:[FightManager class]
								   selector:@selector(repeatShowMapByError)
								   userInfo:nil
									repeats:NO];
	 */
	//显示回地图
	[GameLoading showMessage:@""
					  target:[FightManager class]
						call:@selector(repeatShowMapByError)
					 loading:NO];
}

+(void)repeatShowMapByError{
	[[GameLayer shared] showMap];
	[[GameUI shared] displayUI];
	[GameLayer shared].touchEnabled = YES;
}

+(void)checkEndFight{
	if(fightManager){
		[fightManager checkEndFight];
	}
	fightManager = nil;
}

+(BOOL)checkCanStartFight{
	if ([TaskTalk isTalking]) return NO;
	if ([[Window shared] isHasWindow]) return NO;
	if ([GameEffects checkIsEffects]) return NO;
	
	return YES;
}

-(id)init{
	if((self=[super init])!=nil){
		isPlay = YES;
	}
	return self;
}

-(void)dealloc{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	if(resource){
		[resource release];
		resource = nil;
	}
	if(fightData){
		[fightData release];
		fightData = nil;
	}
	//FightManager = nil;
	
//	if (_targetsdamages) {
//		[_targetsdamages release];
//		_targetsdamages = nil;
//	}
	
	if(temp_data){
		[temp_data release];
		temp_data = nil;
	}
	
	
	if (targetDamages) {
		[targetDamages release];
		targetDamages = nil;
	}
	
	if (userDamages) {
		[userDamages release];
		userDamages = nil;
	}
	
	target = nil;
	call = nil;
	sele = nil;
	
	fightId = 0;
	isWin = NO;
	//[GameConnection freeRequest:self];
	[super dealloc];
	CCLOG(@"FightManager dealloc");
}

-(void)updateTempData:(id)data{
	if(temp_data) [temp_data release];
	temp_data = data;
	if(temp_data) [temp_data retain];
}

-(void)startFightById:(int)fid target:(id)t call:(SEL)c{
	
	CCLOG(@"   \n\n ===Start Fight=== \n\n  ");
	if (fid == fightId) {
		CCLOG(@"   \n\n ===double Fight=== %d \n\n  ",fightId);
		return ;
	}
	
	fightId = fid;
	target = t;
	call = c;
	
	type = Fight_Type_normal;
	
	[self updateTempData:nil];
	[GameLoading showFight:@"" target:self call:@selector(startFight) loading:NO];
	
	/*
	[GameLoading showFight:@"" loading:NO];
	[FightManager removeAllUI];
	[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER 
									 target:self 
								   selector:@selector(startFight)
								   userInfo:nil 
									repeats:NO];
	*/
	
}

-(void)startFightAbyss:(NSDictionary*)data target:(id)t call:(SEL)c{
	
	fightId = 0;
	target = t;
	call = c;
	
	resource = data;
	[resource retain];
	
	type = Fight_Type_abyss;
	
	[self updateTempData:data];
	[GameLoading showFight:@"" target:self call:@selector(startFightAbyss) loading:NO];
	
	/*
	[GameLoading showFight:@"" loading:NO];
	[FightManager removeAllUI];
	[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER 
									 target:self selector:@selector(startFightAbyss:)
								   userInfo:data repeats:NO];
	*/
	
}

-(void)startCustomizeFight:(NSDictionary *)data target:(id)_target call:(SEL)_call{
	
	fightId = 0;//first
	target = _target;
	call = _call;
	
	resource = data;
	[resource retain];
	
	type = Fight_Type_custom;
	
	[self updateTempData:data];
	[GameLoading showFight:@"" target:self call:@selector(startCustomizeFight) loading:NO];
	
	/*
	[GameLoading showFight:@"" loading:NO];
	[FightManager removeAllUI];
	[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER 
									 target:self selector:@selector(startCustomizeFight:)
								   userInfo:data repeats:NO];
	*/
	
}

-(void)startFightBoss:(NSDictionary *)_data target:(id)_target call:(SEL)_call{
	[self startFightBoss:_data target:_target call:_call sele:nil];
}
-(void)startFightBoss:(NSDictionary*)_data target:(id)_target call:(SEL)_call sele:(SEL)_sele{
	
	fightId = 0;
	target = _target;
	call = _call;
	sele = _sele;
	
	type = Fight_Type_bossFight;
	
	[self updateTempData:_data];
	[GameLoading showFight:@"" target:self call:@selector(startFightWorldboss) loading:NO];
	/*
	[GameLoading showFight:@"" loading:NO];
	[FightManager removeAllUI];
	[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER
									 target:self
								   selector:@selector(startFightWorldboss:)
								   userInfo:_data
									repeats:NO];
	*/
	
}

-(void)startFightPlayerBySociality:(int)pid target:(id)_target call:(SEL)_call{
	
	fightId = 0;
	target = _target;
	call = _call;
	
	type = Fight_Type_pve;
	
	NSString * fm = [NSString stringWithFormat:@"pid::%d",pid];
	[self updateTempData:fm];
	[GameLoading showFight:@"" target:self call:@selector(startFightPlayerBySociality) loading:NO];
	
	/*
	[GameLoading showFight:@"" loading:NO];
	[FightManager removeAllUI];
	NSString * fm = [NSString stringWithFormat:@"pid::%d",pid];
	[GameConnection request:@"socialFight" format:fm target:self call:@selector(didPveStart:)];
	*/
	
}

-(void)startFightPlayerBySociality{
	[FightManager removeAllUI];
	[GameConnection request:@"socialFight" format:temp_data target:self call:@selector(didPveStart:)];
	[self updateTempData:nil];
}

-(void)didPveStart:(NSDictionary*)response{
	[FightManager cleanMemory];
	
	if (resource != nil) {
		[resource release];
		resource = nil ;
	}
	
	if (![FightManager checkCanStartFight]) {
		CCLOG(@"didPveStart->error!");
//		[[AlertManager shared] showMessage:@"角色太忙..."
//									target:[FightManager class]
//								   confirm:@selector(stopAllByError)
//									 canel:@selector(stopAllByError)];
		
		[NSTimer scheduledTimerWithTimeInterval:0.2
										 target:[FightManager class]
									   selector:@selector(stopAllByError)
									   userInfo:nil repeats:NO];
		/*
        [[AlertManager shared] showMessage:NSLocalizedString(@"fight_role_busy",nil)
									target:[FightManager class]
								   confirm:@selector(stopAllByError)
									 canel:@selector(stopAllByError)];
		 */
		
		return ;
	}
	
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		if (data != nil) {
			CCLOG([data description]);
			resource = data;
			[resource retain];
			[FightAction startByPlayer:data];
		}
	}else{
		CCLOG(@"error");
//		[[AlertManager shared] showMessage:@"下载数据出错！"
//									target:[FightManager class]
//								   confirm:@selector(stopAllByError)
//									 canel:@selector(stopAllByError)];
		
		/*
        [[AlertManager shared] showMessage:NSLocalizedString(@"fight_data_error",nil)
									target:[FightManager class]
								   confirm:@selector(stopAllByError)
									 canel:@selector(stopAllByError)];
		 */
		[NSTimer scheduledTimerWithTimeInterval:0.2
										 target:[FightManager class]
									   selector:@selector(stopAllByError)
									   userInfo:nil repeats:NO];
	}
	
}

//chao TODO
//狩龙战NPC战
-(void)startFightDragonByNPCId:(int)ancid target:(id)_target call:(SEL)_call{
    fightId = ancid;
    
	target = _target;
	call = _call;
	
	type = Fight_Type_dragon_npc;
	
	NSString * fm = [NSString stringWithFormat:@"ancid::%d",ancid];
	[self updateTempData:fm];
	[GameLoading showFight:@"" target:self call:@selector(startFightDragonByNPC) loading:NO];
}
//chao TODO
//狩龙战NPC战
-(void)startFightDragonByNPC{
    [FightManager removeAllUI];
	[GameConnection request:@"awarMosterStart" format:temp_data target:self call:@selector(didDragonNPCStart:)];
	[self updateTempData:nil];
}
//chao TODO
//狩龙战NPC战回调
-(void)didDragonNPCStart:(NSDictionary*)response{
    [FightManager cleanMemory];
	
	if (resource != nil) {
		[resource release];
		resource = nil ;
	}
	
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
//		resource = data;
//		[resource retain];
        
		[FightAction startFightDragonByNPC:data fight:fightId];
	}else{
		CCLOG(@"error");
        [ShowItem showErrorAct:getResponseMessage(response)];
		[NSTimer scheduledTimerWithTimeInterval:0.2
										 target:[FightManager class]
									   selector:@selector(stopAllByError)
									   userInfo:nil repeats:NO];
	}
}
//---------------------
//chao TODO
//狩龙战影分身
-(void)startFightDragonByPlayerId:(int)ancid target:(id)_target call:(SEL)_call{
    fightId = 0;
	target = _target;
	call = _call;
	
	type = Fight_Type_dragon_player;
    
	NSString * fm = [NSString stringWithFormat:@"ancid::%d",ancid];
	[self updateTempData:fm];
	[GameLoading showFight:@"" target:self call:@selector(startFightPlayerByPlayer) loading:NO];
}
//chao TODO
//狩龙战影分身战发送
-(void)startFightPlayerByPlayer{
    [FightManager removeAllUI];
	[GameConnection request:@"awarCopyStart" format:temp_data target:self call:@selector(didDragonPlayerStart:)];
	[self updateTempData:nil];
}
//chao TODO
//狩龙战影分身回调
-(void)didDragonPlayerStart:(NSDictionary*)response{
    [FightManager cleanMemory];
	
	if (resource != nil) {
		[resource release];
		resource = nil ;
	}
	
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
//		resource = data;
//		[resource retain];
    
		[FightAction startFightDragonByPlayer:data];
	}else{
		CCLOG(@"error");
        [ShowItem showErrorAct:getResponseMessage(response)];
		[NSTimer scheduledTimerWithTimeInterval:0.2
										 target:[FightManager class]
									   selector:@selector(stopAllByError)
									   userInfo:nil repeats:NO];
	}
}

-(void)startFightPlayerByOrder:(int)order target:(id)_target call:(SEL)_call{
	
	fightId = 0;//first
	target = _target;
	call = _call;
	
	type = Fight_Type_pk;
	
	/*
	[GameLoading showFight:@"" loading:NO];
	[FightManager removeAllUI];
	NSString * fm = [NSString stringWithFormat:@"rk::%d",order];
	[GameConnection request:@"arenaStart" format:fm target:self call:@selector(didArenaStart:)];
	*/
	
	NSString * fm = [NSString stringWithFormat:@"rk::%d",order];
	[self updateTempData:fm];
	[GameLoading showFight:@"" target:self call:@selector(startFightPlayerByOrder) loading:NO];
	
}

-(void)startFightPlayerByOrder{
	[FightManager removeAllUI];
	[GameConnection request:@"arenaStart" format:temp_data target:self call:@selector(didArenaStart:)];
	[self updateTempData:nil];
}

-(void)didArenaStart:(NSDictionary*)response{
	
	[FightManager cleanMemory];
	
	if (resource != nil) {
		[resource release];
		resource = nil ;
	}
	
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		resource = data;
		[resource retain];
		[FightAction startByPlayer:data];
	}else{
		CCLOG(@"error");
		
//		[[AlertManager shared] showMessage:@"下载数据出错！"
//									target:[FightManager class]
//								   confirm:@selector(stopAllByError)
//									 canel:@selector(stopAllByError)];
		[NSTimer scheduledTimerWithTimeInterval:0.2
										 target:[FightManager class]
									   selector:@selector(stopAllByError)
									   userInfo:nil repeats:NO];
		/*
        [[AlertManager shared] showMessage:NSLocalizedString(@"fight_data_error",nil)
									target:[FightManager class]
								   confirm:@selector(stopAllByError)
									 canel:@selector(stopAllByError)];
		*/
	}
	
}

-(void)startFightById:(int)fid team:(int)teamId target:(id)_target call:(SEL)_call sele:(SEL)_sele{
	fightId = fid;
	target = _target;
	call = _call;
	sele = _sele;
	type = Fight_Type_team;
	
	NSString * fm = [NSString stringWithFormat:@"tid::%d",teamId];
	[self updateTempData:fm];
	
	[GameLoading showFight:@"" target:self call:@selector(startFightByTeam) loading:NO];
}

-(void)startFightByTeam{
	[FightManager removeAllUI];
	[GameConnection request:@"TeamFight" format:temp_data target:self call:@selector(didFightByTeam:)];
	[self updateTempData:nil];
}

-(void)didFightByTeam:(NSDictionary*)response{
	
	[FightManager cleanMemory];
	
	if(resource != nil){
		[resource release];
		resource = nil ;
	}
	
	if(checkResponseStatus(response)){
		
		NSDictionary * data = getResponseData(response);
		resource = data;
		[resource retain];
		
		[FightAction startByTeam:data fight:fightId];
		
	}else{
		[NSTimer scheduledTimerWithTimeInterval:0.2
										 target:[FightManager class]
									   selector:@selector(stopAllByError)
									   userInfo:nil repeats:NO];
		/*
		[[AlertManager shared] showMessage:NSLocalizedString(@"fight_data_error",nil)
									target:[FightManager class]
								   confirm:@selector(stopAllByError)
									 canel:@selector(stopAllByError)];
		*/
	}
	
}

-(void)startFightTeam:(int)selfTeamId byTeam:(int)targetTeamId 
			   target:(id)_target call:(SEL)_call sele:(SEL)_sele{
	
	target = _target;
	call = _call;
	sele = _sele;
	type = Fight_Type_teams;
	
	NSMutableDictionary * data = [NSMutableDictionary dictionary];
	[data setObject:[NSNumber numberWithInt:selfTeamId] forKey:@"selfTeamId"];
	[data setObject:[NSNumber numberWithInt:targetTeamId] forKey:@"targetTeamId"];
	[self updateTempData:data];
	
	[GameLoading showFight:@"" target:self call:@selector(startLoadSelfTeam) loading:NO];
}

-(void)startLoadSelfTeam{
	[FightManager removeAllUI];
	if(resource != nil){
		[resource release];
		resource = nil ;
	}
	NSString * fm = [NSString stringWithFormat:@"tid::%d",[[temp_data objectForKey:@"selfTeamId"] intValue]];
	[GameConnection request:@"TeamFight" format:fm target:self call:@selector(didLoadSelfTeam:)];
}
-(void)didLoadSelfTeam:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		NSMutableDictionary * team = [NSMutableDictionary dictionary];
		[team setObject:data forKey:@"team1"];
		resource = [NSDictionary dictionaryWithDictionary:team];
		[resource retain];
		[self startLoadTargetTeam];
	}else{
		/*
		[[AlertManager shared] showMessage:@"下载数据出错！"
									target:[FightManager class]
								   confirm:@selector(stopAllByError)
									 canel:@selector(stopAllByError)];
		 */
		[NSTimer scheduledTimerWithTimeInterval:0.2
										 target:[FightManager class]
									   selector:@selector(stopAllByError)
									   userInfo:nil repeats:NO];
		
	}
}

-(void)startLoadTargetTeam{
	NSString * fm = [NSString stringWithFormat:@"tid::%d",[[temp_data objectForKey:@"targetTeamId"] intValue]];
	[GameConnection request:@"TeamFight" format:fm target:self call:@selector(didLoadTargetTeam:)];
}
-(void)didLoadTargetTeam:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		NSMutableDictionary * team = [NSMutableDictionary dictionaryWithDictionary:resource];
		[team setObject:data forKey:@"team2"];
		
		[resource release];
		resource = [NSDictionary dictionaryWithDictionary:team];
		[resource retain];
		
		[self updateTempData:nil];
		
		[FightAction startByTeams:resource];
		
	}else{
		
		[NSTimer scheduledTimerWithTimeInterval:0.2
										 target:[FightManager class]
									   selector:@selector(stopAllByError)
									   userInfo:nil repeats:NO];
		
		/*
		[[AlertManager shared] showMessage:@"下载数据出错！"
									target:[FightManager class]
								   confirm:@selector(stopAllByError)
									 canel:@selector(stopAllByError)];
		*/
	}
}
#pragma mark-

-(void)startFight{
	[FightManager removeAllUI];
	[FightManager cleanMemory];
	[FightAction startFight:fightId];
}

-(void)startFightWorldboss{
	[FightManager removeAllUI];
	[FightManager cleanMemory];
	[FightAction startFightWorldBoss:temp_data];
	[self updateTempData:nil];
}

-(void)startFightAbyss{
	[FightManager removeAllUI];
	[FightManager cleanMemory];
	[FightAction startFightAbyss:temp_data];
	[self updateTempData:nil];
}
-(void)startCustomizeFight{
	[FightManager removeAllUI];
	[FightManager cleanMemory];
	[FightAction startCustomizeFight:temp_data];
	[self updateTempData:nil];
}
-(void)startByPlayer{
	[FightManager removeAllUI];
	[FightAction startByPlayer:temp_data];
}

-(void)playFightRecord:(int)rid target:(id)_target call:(SEL)_call{
	target = _target;
	call = _call;
	[self playFightRecord:rid];
}
-(void)playFightRecord:(int)rid{
	
	type = Fight_Type_record;
	
	/*
	[GameLoading showFight:@"" loading:NO];
	[FightManager removeAllUI];
	NSString * fm = [NSString stringWithFormat:@"id::%d",rid];
	[GameConnection request:@"fightReport" format:fm target:self call:@selector(didLoadFightReport:)];
	*/
	NSString * fm = [NSString stringWithFormat:@"id::%d",rid];
	[self updateTempData:fm];
	[GameLoading showFight:@"" target:self call:@selector(loadFightReport) loading:NO];
}

-(void)loadFightReport{
	[FightManager removeAllUI];
	[GameConnection request:@"fightReport" format:temp_data target:self call:@selector(didLoadFightReport:)];
	[self updateTempData:nil];
}

-(void)didLoadFightReport:(NSDictionary*)response{
	
	[FightManager cleanMemory];
	
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		NSString * url  = [data objectForKey:@"url"];
		
		ASIHTTPRequest * http = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
		[http setDownloadCache:[ASIDownloadCache sharedCache]];
		[http setTimeOutSeconds:3*60];
		[http setCompletionBlock:^{
			
			NSString * responseString = [http responseString];
			NSData * fdata = [[NSData dataFromBase64String:responseString] gunzippedData];
			fdata = [fdata AES256DecryptWithKey:[ENCODE_PW stringFromMD5]];
			
			NSError * error = nil;
			NSDictionary * json = [[CJSONDeserializer deserializer] deserializeAsDictionary:fdata error:&error];
			if(!error){
				[self playFight:json];
				return ;
			}
			
			CCLOG(@"load fight report error!");
			[self endFight];
		}];
		[http setFailedBlock:^{
			CCLOG(@"load fight report error!");
			[self endFight];
		}];
		[http startAsynchronous];
	}else{
		CCLOG(@"load fight report error!");
		//[ShowItem showItemAct:@"读取失败"];
        [ShowItem showItemAct:NSLocalizedString(@"fight_read_fail",nil)];
		[self endFight];
	}

}

-(void)seleFightResult:(NSDictionary*)info isUserWin:(BOOL)isUserWin{
	
	if(fightData){
		[fightData release];
		fightData = nil;
	}
	fightData = [[NSDictionary alloc] initWithDictionary:info];
	if(target!=nil && sele!=nil){
		isWin = isUserWin;
		[target performSelector:sele];
	}
	
}

-(void)playFightResult{
	[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER 
									 target:self selector:@selector(doPlayFight) 
								   userInfo:nil repeats:NO];
}

-(void)playFight:(NSDictionary*)info{
	if(fightData){
		[fightData release];
		fightData = nil;
	}
	
	fightData = [[NSDictionary alloc] initWithDictionary:info];
	[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER 
									 target:self selector:@selector(doPlayFight) 
								   userInfo:nil repeats:NO];
}

-(void)doPlayFight{
	
	[FightManager cleanMemory];
	[FightAction cleanFight];
	[FightPlayer showByDict:fightData];
	
}

-(void)endFight{
	//show loading
	
	[FightPlayer hide];
	[FightManager cleanMemory];
	
	CCLOG(@"   \n\n ===End Fight=== \n\n  ");
	
	//[GameLoading showFight:@"" target:self call:@selector(doEndFight) loading:NO];
	[GameLoading showMessage:@"" target:self call:@selector(doEndFight) loading:NO];
	
	//[self doEndFight];
	
}
-(void)doEndFight{
	
	[[GameLayer shared] showMap];
	[[GameUI shared] displayUI];
	
}

-(void)checkEndFight{
	CCLOG(@"FightManager checkEndFight-----------------------------------------------------");
	if(target!=nil && call!=nil){
		[target performSelector:call];
		target = nil;
		call = nil;
		sele = nil;
	}
	
	[GameLayer shared].touchEnabled = YES;
	
	[self cleanResult];
	
}

-(void)cleanResult{
	
	fightId = -1;
	isWin = NO;
	dieLeftkindCount = 0;
	
	target =  nil;
	call = nil;
	sele = nil;
	
	if(fightData){
		[fightData release];
		fightData = nil;
	}
	//int rc = [self retainCount];
	//CCLOG(@"FightManager retain count:%d",rc);
	
	[self release];
}

-(NSString*)getFigthSub{
	
	//fightData
	if(fightData){
		NSError * error = nil;
		NSData * json = [[CJSONSerializer serializer] serializeObject:fightData error:&error];
		if(!error){
			NSData * data = [NSData gzipData:[json AES256EncryptWithKey:[ENCODE_PW stringFromMD5]]];
			NSString * result = [data base64EncodedString];
			return result;
		}
	}
	
	return @"";
	
}

-(void)fightAgain{
	
	if(fightId>0 || resource!=nil){
		
		//[GameLoading showFight:@"" loading:NO];
		
		if(type==Fight_Type_normal){
			
			
			/*
			[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER
											 target:self 
										   selector:@selector(startFight) 
										   userInfo:nil 
											repeats:NO];
			*/
			
			[self updateTempData:nil];
			[GameLoading showFight:@"" target:self call:@selector(startFight) loading:NO];
			
		}
		if(type==Fight_Type_abyss){
			/*
			[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER 
											 target:self 
										   selector:@selector(startFightAbyss:) 
										   userInfo:resource 
											repeats:NO];
			*/
			[self updateTempData:resource];
			[GameLoading showFight:@"" target:self call:@selector(startFightAbyss) loading:NO];
		}
		if(type==Fight_Type_custom){
			/*
			[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER 
											 target:self 
										   selector:@selector(startCustomizeFight:)
										   userInfo:resource 
											repeats:NO];
			*/
			[self updateTempData:resource];
			[GameLoading showFight:@"" target:self call:@selector(startCustomizeFight) loading:NO];
		}
		if(type==Fight_Type_pk || type == Fight_Type_pve){
			/*
			[NSTimer scheduledTimerWithTimeInterval:FIGHT_SYSTEM_TIMER 
											 target:self 
										   selector:@selector(startByPlayer:)
										   userInfo:resource 
											repeats:NO];
			*/
			[self updateTempData:resource];
			[GameLoading showFight:@"" target:self call:@selector(startByPlayer) loading:NO];
		}
		
	}else{
		[self endFight];
	}
}

-(int)getTargetDamage:(int)_tid{
	CCLOG(@"getTargetDamage:%d",_tid);
	if (targetDamages) {
		NSString* key = [NSString stringWithFormat:@"%d",_tid];
		return [[targetDamages objectForKey:key] intValue];
	}
	return 0;
}

-(int)getUserDamage:(int)_tid{
	if (userDamages) {
		NSString* key = [NSString stringWithFormat:@"%d",_tid];
		return [[userDamages objectForKey:key] intValue];
	}
	return 0;
}

@end
