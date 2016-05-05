//
//  RoleManager.m
//  TXSFGame
//
//  Created by chao chen on 12-10-24.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "RoleManager.h"
#import "RolePlayer.h"

#import "GameLayer.h"
#import "MapManager.h"
#import "GameConnection.h"
#import "GameConfigure.h"
#import "TaskManager.h"
#import "MovingAlert.h"
#import "GameDB.h"
#import "Car.h"
#import "RoleOption.h"

//#define MAX_ONLINE_PLAYER_COUNT_KEY @"MAX_ONLINE_PLAYER_COUNT"
//#define MAX_ONLINE_PLAYER_COUNT 30

#define MAX_ONLINE_PLAYER_COUNT_KEY @"zl_people_count_value"

RoleManager *s_RoleManager;

@implementation RoleManager

@synthesize player;
@synthesize maxPlayerCount;

+(RoleManager*)shared{
	if(!s_RoleManager){
		s_RoleManager = [[RoleManager alloc] init];
	}
	return s_RoleManager;
}
+(void)stopAll{
	if(s_RoleManager){
		[s_RoleManager release];
		s_RoleManager = nil;
	}
}

+(void)reloadPlayers{
	if(s_RoleManager){
		[s_RoleManager doReloadPlayers];
	}
}

-(id)init{
	if ( (self = [super init]) ){
		players = [[NSMutableArray alloc] init];
		player = nil;
		
		otherVisible = YES;
		
		[GameConnection addPost:ConnPost_MapPush target:self call:@selector(pushPlayerInfo:)];
		[GameConnection addPost:ConnPost_updatePlayerUpLevel target:self call:@selector(showPlayerUplevel:)];
		[GameConnection addPost:ConnPost_finishChapter target:self call:@selector(showPlayerSuitWithFinishChapter:)];
		[GameConnection addPost:ConnPost_AllyApply_success target:self call:@selector(updatePlayerViewer)];
        [GameConnection addPost:ConnPost_KickApply_success target:self call:@selector(updatePlayerViewer)];
        
		NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
		/*
		NSNumber * max = [defaults objectForKey:MAX_ONLINE_PLAYER_COUNT_KEY];
		if(max){
			int configMax = [[GameDB shared] mapRolesMax];
			maxPlayerCount = [max intValue];
			if(maxPlayerCount>configMax){
				self.maxPlayerCount = configMax;
			}
		}else{
			self.maxPlayerCount = MAX_ONLINE_PLAYER_COUNT;
		}
		*/
		
		maxPlayerCount = [[defaults objectForKey:MAX_ONLINE_PLAYER_COUNT_KEY] intValue];
		
	}
	return self;
}
-(void)dealloc{
	
	[GameConnection removePostTarget:self];
	
	[player release];
	player = nil;
	
	[players release];
	players = nil;
    //[GameConnection freeRequest:self];
	[super dealloc];
	
	CCLOG(@"RoleManager dealloc");
	
}

-(void)setMaxPlayerCount:(int)_maxPlayerCount{
	maxPlayerCount = _maxPlayerCount;
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:maxPlayerCount forKey:MAX_ONLINE_PLAYER_COUNT_KEY];
	[defaults synchronize];
	
	[self checkOtherPlayers];
	
}

-(void)showPlayerSuitWithFinishChapter:(NSNotification*)notification{
	if (player) {
		int rid = [[GameConfigure shared] getPlayerRole];
		NSDictionary* d1 = [[GameConfigure shared] getPlayerRoleFromListById:rid];
		int eq2 = [[d1 objectForKey:@"eq2"] intValue];
		NSDictionary* d2 = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
		int eid = [[d2 objectForKey:@"eid"] intValue];
		[player updateSuit:eid];
	}
}
-(void)updatePlayerViewer{
    if (player) {
        NSDictionary *playerAlly=[[GameConfigure shared]getPlayerAlly];
        player.allyName=[playerAlly objectForKey:@"n"];
        [player updateViewer];
	}
}
-(void)showPlayerUplevel:(NSNotification*)notification{
	if (player) {
		[player showUplevel];
	}
}
-(void)pushPlayerInfo:(NSNotification*)notification{
	
	if(![[MapManager shared] isShowMap]) return;
	if(![[MapManager shared] checkMapCanManyPeople]) return;
	
	NSDictionary * data = notification.object;
	if(data){
		
		int mid = [[data objectForKey:@"mid"] intValue];
		if (![[MapManager shared] isEqualMapId:mid]) {
			CCLOG(@"\n");
			CCLOG(@"==========================================");
			CCLOG(@"[[MapManager shared] isEqualMapId:%d]",mid);
			CCLOG(@"==========================================");
			CCLOG(@"\n");
			return ;
		}
		
		NSArray * enters = [data objectForKey:@"enters"];
		[self loadOtherPlayers:enters];
		
		NSArray * leaves = [data objectForKey:@"leaves"];
		[self removeOtherPlayers:leaves];
		
		NSArray * moves = [data objectForKey:@"moves"];
		[self moveOtherPlayers:moves];
		
		NSArray * ups = [data objectForKey:@"up"];
		[self updateOtherPlayers:ups];
		
	}
}

-(void)loadPlayer{
	
	if (player) return;
	
	//[RolePlayer reset];
	
	NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
	playerInfo = [NSDictionary dictionaryWithDictionary:playerInfo];
	NSDictionary *playerAlly=[[GameConfigure shared]getPlayerAlly];
	
	player = [RolePlayer node];
	[player retain];
	[[[GameLayer shared] content] addChild:player];
	
	player.player_id = [[playerInfo objectForKey:@"id"] intValue];
	player.role_id = [[playerInfo objectForKey:@"rid"] intValue];
	player.car_id = [[playerInfo objectForKey:@"car"] intValue];
	player.level = [[playerInfo objectForKey:@"level"] intValue];
	player.name = [playerInfo objectForKey:@"name"];
	player.state = [[playerInfo objectForKey:@"state"] intValue];
	player.allyName=[playerAlly objectForKey:@"n"];
	player.isShow = YES;
	CCLOG(@"name:%@ car:%i",player.name,player.car_id);
	CGPoint point = ccp(0,0);
	if([[MapManager shared] canSetLocation:[MapManager shared].mapType]){
		point = CGPointFromString([playerInfo objectForKey:@"pos"]);
	}
	if(point.x<=0 || point.y<=0){
		point = [MapManager shared].startPoint;
	}
	
	//重新进入到地图的时候需要到副本的开始位置
	if ([Game shared].bStartGame) {
		point = ([MapManager shared].mapType == Map_Type_Stage)?[MapManager shared].startPoint:point;
	}
	
	if(![[MapManager shared] tiledPointIsOpen:point]){
		point = [MapManager shared].startPoint;
	}
	
	point = [[MapManager shared] getTileToPosition:point];
	
	player.position = point;
	
	NSDictionary * roleInfo = [[GameConfigure shared] getPlayerRoleFromListById:player.role_id];
	int eq2 = [[roleInfo objectForKey:@"eq2"] intValue];
	if(eq2>0){
		NSDictionary * equip = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
		int eqid = [[equip objectForKey:@"eid"] intValue];
		player.suit_id = eqid;
	}
	
	/*
	NSDictionary *playEq=[[GameConfigure shared]getPlayerRoleFromListById:player.role_id];
	int playeqid=[[playEq objectForKey:@"eq2"]integerValue];
	int eqid=[[[[GameConfigure shared]getPlayerEquipInfoById:playeqid]objectForKey:@"eid"]integerValue];
	
	player.suit_id=eqid;
	*/
	
	[player start];
	

	
}

-(void)movePlayerToStartPoint{
	
	//[PlayerSit setSitTime:0];
	
	CGPoint point = [MapManager shared].startPoint;
	player.position = [[MapManager shared] getTileToPosition:point];
    
	/*
	if([[MapManager shared] canSetLocation]){
		[[GameConfigure shared] setPlayerLocation:point
											mapId:[MapManager shared].mapId];
	}
	*/
	[[MapManager shared] setPlayerLocation:point];
	[[GameLayer shared] updatePlayerView];
	
}


-(void)movePlayerTo:(CGPoint)point{
	
	[self movePlayerTo:point target:nil call:nil];
	
}

-(void)movePlayerTo:(CGPoint)point target:(id)target call:(SEL)call{
	
	//[PlayerSit setSitTime:0];
	//CGPoint tPoint = [[MapManager shared] getPositionToTile:point];
	
	if([self playerIsOnPoint:point]){
		if(target!=nil && call!=nil){
			[target performSelector:call];
		}
		return;
	}
	
	//CGPoint tp = [[MapManager shared] getTileToPosition:tPoint];
	[player moveTo:point target:target call:call];
	
    //todo ????????
    //????????
    //[player setState:Player_state_normal];
	
	/*
	if([player moveTo:point]){
		
		player.target = target;
		player.moveEndCall = call;
		
		[[MapManager shared] setPlayerLocation:tPoint];
		
		//=======================================================
		if (![[TaskManager shared] checkMoveToNpc:tPoint]) {
			CCLOG(@"movePlayerTo:关闭自动寻路");
			[MovingAlert remove];
		}
		//=======================================================
		
	}
	*/
	
}



-(AnimationViewer*)getMyImages:(bool)ShowCar{
	AnimationViewer *roleAnima = [AnimationViewer node];
	int rid=[[[[GameConfigure shared]getPlayerInfo]objectForKey:@"rid"]integerValue];

	int eqid = 0;
	int eq2 = 0;
	NSArray *roleFrames = nil;
	NSDictionary* playerRole = [[GameConfigure shared] getPlayerRoleFromListById:rid];
	if (playerRole) {
		eq2 = [[playerRole objectForKey:@"eq2"] intValue];
		NSDictionary* playerEquip = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
		if (playerEquip) {
			eqid = [[playerEquip objectForKey:@"eid"] intValue];
		}
	}
	NSString *fullPath = nil;
	if (eqid == 0) {
		fullPath = [NSString stringWithFormat:@"images/animations/role/r%d/1/5/", rid];
	} else {
		fullPath = [NSString stringWithFormat:@"images/animations/role/r%d_%d/1/5/", rid, eqid];
	}
	roleFrames = [AnimationViewer loadFileByFileFullPath:fullPath name:@"%d.png"];
	[roleAnima playAnimation:roleFrames];
	[roleAnima setAnchorPoint:ccp(0.5, 0)];
	return roleAnima;
}

-(void)stopMovePlayer{
	
	CGPoint tPoint = [[MapManager shared] getPositionToTile:player.position];
	
	[player stopMove];
	
	/*
    if([MapManager shared].mapType!=5){
        [[GameConfigure shared] setPlayerLocation:tPoint
										mapId:[MapManager shared].mapId];
    }
	*/
	
	[[MapManager shared] setPlayerLocation:tPoint];
	
}

-(BOOL)playerIsOnPoint:(CGPoint)point{
	CGPoint tPoint = [[MapManager shared] getPositionToTile:point];
	CGPoint sPoint = [[MapManager shared] getPositionToTile:player.position];
	if(ccpFuzzyEqual(tPoint,sPoint,1)){
		return YES;
	}
	return NO;
}

-(BOOL)pointIsOnPoint:(CGPoint)point1 with:(CGPoint)point2{
	CGPoint tPoint = [[MapManager shared] getPositionToTile:point1];
	CGPoint sPoint = [[MapManager shared] getPositionToTile:point2];
	if(ccpFuzzyEqual(tPoint,sPoint,1)){
		return YES;
	}
	return NO;
}
//==============================================================================

-(void)clearAllPlayer{
	
	for(RolePlayer * p in players){
		[p removeFromParentAndCleanup:YES];
		
		//清除绑定
		if (p == [RoleOption shared].role) {
			[RoleOption shared].role = nil ;
		}
		
	}
	[players removeAllObjects];
	
	[player release];
	[player removeFromParentAndCleanup:YES];
	player = nil;
	
}

//==============================================================================
//OTHER PLAYERs
//==============================================================================
#pragma mark 处理除自己其他玩家表现
-(void)checkOtherPlayers{
	
	//TODO need test
	NSArray * showings = [self getOtherPlayerShow];
	if([showings count]>maxPlayerCount){
		int cut = [showings count]-maxPlayerCount;
		for(int i=0;i<cut;i++){
			RolePlayer * other = [players objectAtIndex:i];
			[other hidePlayer];
		}
	}
	
	if([players count]<maxPlayerCount){
		for(RolePlayer * other in players){
			[other showPlayer];
		}
	}
	
}

-(void)loadOtherPlayers{
	
	if(![[MapManager shared] isShowMap]) return;
	if(![[MapManager shared] checkMapCanManyPeople]) return;
	[GameConnection request:@"mapPlayers" format:@"" target:self call:@selector(didLoadPlayers:)];
}

-(void)doReloadPlayers{
	for(RolePlayer * p in players){
		[p removeFromParentAndCleanup:YES];
	}
	[players removeAllObjects];
	[self loadOtherPlayers];
}

-(void)didLoadPlayers:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSArray * ps = getResponseData(response);
		[self loadOtherPlayers:ps];
	}
}

-(void)loadOtherPlayers:(NSArray*)array{
	for(int i=0;i<[array count];i++){
		NSArray * p = [array objectAtIndex:i];
		[self loadPlayerByData:p index:i];
	}
}

-(void)loadPlayerByData:(NSArray*)p index:(int)index{
	
	NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
	int self_pid = [[playerInfo objectForKey:@"id"] intValue];
	int pid = [[p objectAtIndex:0] intValue];
	
	if(self_pid==pid) return;
	//if(pid==player.player_id) return;
	
	RolePlayer * other = [self getOtherPlayerByPid:pid];
	if(other){
		other.visible = otherVisible;
		return;
	}
	
	other = [RolePlayer node];
	other.player_id = pid;
	other.name = [p objectAtIndex:1];
	other.level = [[p objectAtIndex:2] intValue];
	other.role_id = [[p objectAtIndex:3] intValue];
	other.suit_id = [[p objectAtIndex:4] intValue];
	other.car_id = [[p objectAtIndex:5] intValue];
	other.state = [[p objectAtIndex:7] intValue];
	other.allyName=[p objectAtIndex:8];

	other.visible = otherVisible;
	
	CGPoint point = CGPointFromString([p objectAtIndex:6]);
	if(point.x<=0 || point.y<=0) point = [MapManager shared].startPoint;
	other.position = [[MapManager shared] getTileToPosition:point];
	
	[players addObject:other];
	other.isShow = ([players count]<maxPlayerCount);
	
	[[[GameLayer shared] content] addChild:other];
	
	[other startDelay:(0.1+0.05*index)];
	
	CCLOG(@"%@ %i",other.name,other.car_id);
	[other updateCar:other.car_id];
    //
    if ([p count]>9 && [p objectAtIndex:9]!= NULL && [[p objectAtIndex:9] isKindOfClass:[NSNull class]] == NO /*&& [[p objectAtIndex:9] isEqualToString:@""] == NO*/ && [[p objectAtIndex:9] intValue] != -1) {
        [other setQuality:[[p objectAtIndex:9]integerValue]];
        [other updateViewer];
    }
    //
}

-(void)removeOtherPlayers:(NSArray*)array{
	if([array count]>0){
		for(NSNumber * p in array){
			RolePlayer * other = [self getOtherPlayerByPid:[p intValue]];
			if(other){
				[players removeObject:other];
				  
				if (other == [RoleOption shared].role) {
					[RoleOption shared].role = nil ;
				}
				
				[other removeFromParentAndCleanup:YES];
			}
		}
	}
}
-(void)moveOtherPlayers:(NSArray*)array{
	for(NSArray * p in array){
		int pid = [[p objectAtIndex:0] intValue];
		RolePlayer * other = [self getOtherPlayerByPid:pid];
		if(other){
			CGPoint point = CGPointFromString([p objectAtIndex:1]);
			point = [[MapManager shared] getTileToPosition:point];
			[other moveTo:point];
		}
	}
}
-(void)updateOtherPlayers:(NSArray*)array{
	if(!array) return;
	for(NSArray * p in array){
		int pid = [[p objectAtIndex:0] intValue];
		RolePlayer * other = [self getOtherPlayerByPid:pid];
		if(other){
			//TODO other 1-5
			
			[other updateSuit:[[p objectAtIndex:4]integerValue]];
			[other updateCar:[[p objectAtIndex:5]integerValue]];

			if ([p count]>9 && [p objectAtIndex:9]!= NULL && [[p objectAtIndex:9] isKindOfClass:[NSNull class]] == NO /*&& [[p objectAtIndex:9] isEqualToString:@""] == NO */&& [[p objectAtIndex:9] intValue] != -1) {
                [other setQuality:[[p objectAtIndex:9]integerValue]];
                [other updateViewer];
            }
            
			if(other.level != [[p objectAtIndex:2] intValue]){
				[other setLevel:[[p objectAtIndex:2] intValue]];
				[other showUplevel];
			}
			other.state = [[p objectAtIndex:7] intValue];
		}
	}
}

-(RolePlayer*)getOtherPlayerByPid:(int)pid{
	for(RolePlayer * other in players){
		if(other.player_id==pid){
			return other;
		}
	}
	return nil;
}

-(BOOL)isOtherPlayerVisible{
	return otherVisible;
}

-(void)otherPlayerVisible:(BOOL)visible{
	otherVisible = visible;
	for(RolePlayer * other in players){
		other.visible = otherVisible;
	}
}

-(int)getOtherPlayerShowCount{
	NSArray * showings = [self getOtherPlayerShow];
	return [showings count];
}

-(NSArray*)getOtherPlayerShow{
	NSMutableArray * result = [NSMutableArray array];
	for(RolePlayer * other in players){
		if(other.isShow){
			[result addObject:other];
		}
	}
	return result;
}

-(CGPoint)getFreePoint:(NSArray*)array{
	if (array) {
		if (players.count > 0) {
			for (NSValue *_value in array) {
				CGPoint temp = [_value CGPointValue];
				BOOL isFree = YES ;
				for(RolePlayer * other in players){
					if ([self pointIsOnPoint:temp with:other.position]) {
						isFree = NO ;
						break ;
					}
				}
				if (isFree) {
					return temp;
				} 
			}
		}
		else {
			CGPoint pt = [[array objectAtIndex:0] CGPointValue];
			return pt;
		}
	}
	return ccp(-1, -1);
}

-(float)getPointDistanceWithPlayer:(CGPoint)_pt{
	if (player) {
		return ccpDistance(_pt, player.position);
	}
	return 0;
}

-(void)playerSit{
	if(player){
		//TODO 运龟中 不能打坐 ... 
		if(player.state>=2) return;
		if(player.state==Player_state_normal){
			player.state = Player_state_sit;
		}else{
			player.state = Player_state_normal;
		}
	}
}



@end
