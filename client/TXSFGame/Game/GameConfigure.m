                                                                                                                                                                                                            //
//  GameConfigure.m
//  TXSFGame
//
//  Created by chao chen on 12-10-12.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "GameConfigure.h"
#import "cocos2d.h"
#import "NSData+Base64.h"
#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"
#import "GameDB.h"
#import "GameConnection.h"
#import "StageManager.h"
#import "TaskManager.h"

static GameConfigure * s_GameConfigure=nil;

//暂时保存玩家的等级和当前等级的经验
static int s_PlayerLevel = -1 ;
static int s_PlayerExp = -1 ;

@implementation GameConfigure

@synthesize time;
@synthesize isCanSendMove;

//取配置文件对象指针
+(GameConfigure*)shared
{
    if (nil == s_GameConfigure)
    {
        s_GameConfigure = [[GameConfigure alloc] init];
		s_GameConfigure.isCanSendMove = YES;
    }
    return s_GameConfigure;
}

+(void)stopAll{
	if(s_GameConfigure){
		[s_GameConfigure release];
		s_GameConfigure = nil;
	}
}

-(void)dealloc{
	time = 0;
	[super dealloc];
	
	CCLOG(@"GameConfigure dealloc");
}

/*
 * 通过表明加载基础表数据
 */
-(NSArray*)getDataByTableName:(NSString*)_table
{
	//arm, arm_exp, arm_level, eq_level, eq_set, equip, fate, fate_level, fusion, item, map, kposition, pos_level, role, role_exp, role_level, stage, str_eq
	//暂时存在内存
	//	if (!game_db) {
	//		NSString *path = [[NSBundle mainBundle] pathForResource:@"game_db" ofType:@""];
	//		NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
	//		CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
	//		NSError *error = nil;
	//		game_db = [deserializer deserializeAsDictionary:data error:&error];
	//		if (error) {
	//			CCLOG(@"getDataByTableName faild! erro:%@",[error description]);
	//			return nil;
	//		}
	//	}
	//	NSArray *dictArray = [game_db valueForKey:_table];
	//	return dictArray;
	return nil;
}

-(int)getLastLoginPlayerId{
	
	if([self getPlayerCount]==0) return -1;
	
	NSArray * ps = [self.userInfo objectForKey:@"players"];
	int lt = 0;
	int pid = 0;
	for(NSDictionary * p in ps){
		int tLogout = [[p objectForKey:@"tLogout"] intValue];
		if(tLogout>lt){
			lt = tLogout;
			pid = [[p objectForKey:@"id"] intValue];
		}
	}
	//默认选第一个
	if ((pid == 0) && ps && (ps.count > 0)) {
		NSDictionary* p = [ps objectAtIndex:0];
		pid = [[p objectForKey:@"id"] intValue];
	}
	return pid;
}
-(int)getPlayerCount{
	NSArray * ps = [self.userInfo objectForKey:@"players"];
	return [ps count];
}

-(void)loadData{
	
	//	NSDictionary * palyer = [self getDataBykey:@"player"];
	//	NSArray * roles = [self getDataBykey:@"roles"];
	
	
	//----------------
	//加载JSON
	//----------------
	//	NSString *path = [[NSBundle mainBundle] pathForResource:@"game_db/game_db" ofType:nil];
	//	NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
	//	CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
	//	NSError *error = nil;
	//	game_db = [deserializer deserializeAsDictionary:data error:&error];
	//	if (error) {
	//		CCLOG(@"getDataByTableName faild! erro:%@",[error description]);
	//		return ;
	//	}
	//	if (game_db) {
	//		[game_db retain];
	//	}
	//----------------
	
}

#pragma mark-

-(NSString*)createMapInfo{
	return nil;
}
/*
-(NSDictionary*)getPlayerChapterMap{
	NSString* _info = [self getPlayerCliAttr:@"World--map"];
	if (_info == nil) {
		_info = [self getDefaultChapterMap];
	}
	
	NSMutableDictionary* maps = [NSMutableDictionary dictionary];
	NSArray* array = [_info componentsSeparatedByString:@"|"];
	//-------写入字典
	
	for (NSString* str in array) {
		NSArray* _kv = [str componentsSeparatedByString:@":"];
		if (_kv.count == 2) {
			int _cid = [[_kv objectAtIndex:0] intValue];
			int _mid = [[_kv objectAtIndex:1] intValue];
			NSString* key_ = [NSString stringWithFormat:@"%d",_cid];
			[maps setObject:[NSNumber numberWithInt:_mid] forKey:key_];
		}
	}
	
	return maps;
}


-(NSDictionary*)getPlayerExternalMap{
	
	NSString* _info = [self getPlayerCliAttr:@"External--map"];
	
	if (_info == nil) {
		return nil;
	}
	
	NSMutableDictionary* maps = [NSMutableDictionary dictionary];
	NSArray* array = [_info componentsSeparatedByString:@"|"];
	
	for (NSString* str in array) {
		NSArray* _kv = [str componentsSeparatedByString:@":"];
		if (_kv.count == 2) {
			int _cid = [[_kv objectAtIndex:0] intValue];
			int _mid = [[_kv objectAtIndex:1] intValue];
			NSString* key_ = [NSString stringWithFormat:@"%d",_cid];
			[maps setObject:[NSNumber numberWithInt:_mid] forKey:key_];
		}
	}
	
	return maps;
}


-(void)updateExternalMap:(NSString*)_data{
	if (_data == nil || _data.length <= 0) return ;
	NSArray* kvs = [_data componentsSeparatedByString:@":"];
	
	if (kvs.count == 2){
		
		NSString* _info = [self getPlayerCliAttr:@"External--map"];
		if (_info == nil) {
			_info = [NSString stringWithFormat:@"%@",kvs];
		}else{
			_info = [_info stringByAppendingFormat:@"|%@",kvs];
		}
		
		[self setPlayerCliAttr:@"External--map" value:_info];
		
	}
	
	CCLOG(@"updateExternalMap->%@",_data);
	
}

-(void)updateChapterMap:(NSString*)_data{
	
	if (_data == nil || _data.length <= 0) return ;
	
	NSArray* kvs = [_data componentsSeparatedByString:@":"];
	
	if (kvs.count == 2){
		int _cid = [[kvs objectAtIndex:0] intValue];//章节ID
		int _mid = [[kvs objectAtIndex:1] intValue];//地图ID
		
		NSString* _info = [self getPlayerCliAttr:@"World--map"];
		if (_info == nil) {
			_info = [self getDefaultChapterMap];
		}
		
		CCLOG(@"updateChapterMap:%@",_info);
		
		
		NSString* replaces = nil ;
		NSMutableArray* array= [NSMutableArray arrayWithArray:[_info componentsSeparatedByString:@"|"]];
		for (NSString* string in array) {
			NSArray* __values = [string componentsSeparatedByString:@":"];
			int _cid2 = [[__values objectAtIndex:0] intValue];
			int _mid2 = [[__values objectAtIndex:1] intValue];
			//章节ID相等 地图ID不相等
			if (_cid2 == _cid && _mid2 != _mid) {
				replaces = [NSString stringWithFormat:string];
				break ;
			}
		}

		if (replaces != nil) {
			_info = [_info stringByReplacingOccurrencesOfString:replaces withString:_data];
			//跟新地图数据
			[self setPlayerCliAttr:@"World--map" value:_info];
		}
	}
}

-(NSString*)getDefaultChapterMap{
	
	NSDictionary* db = [[GameDB shared] readDB:@"chapter"];
	NSArray* temp = [db allValues];
	
	NSString* _info = [NSString stringWithFormat:@""];
	for (NSDictionary* dict in temp) {
		int _mid = [[dict objectForKey:@"mid"] intValue];
		int _id = [[dict objectForKey:@"id"] intValue];
		_info = [_info stringByAppendingFormat:@"%d:%d|",_id,_mid];
	}
	
	int len = _info.length;
	_info = [_info substringToIndex:len-1];
	
	[self setPlayerCliAttr:@"World_Map" value:_info];
	
	return _info ;
}
*/

//外传地图 101:7
//++++++++++++++++++++++++++++++++++++++++++++++

-(void)addUserWorldMap:(int)_cid map:(int)_mid{
	NSString* _info = [NSString stringWithFormat:@"%d:%d",_cid,_mid];
	[self addUserWorldMapWith:_info];
}

-(void)updateUserWorldMap:(int)_tag map:(int)_mid{
	
	NSString* _info = [self getPlayerCliAttr:@"World--map"];
	
	if (_info == nil) {
		CCLOG(@"updateUserWorldMap");
		return ;
	}
	
	NSString* replaces = nil ;
	NSMutableArray* array= [NSMutableArray arrayWithArray:[_info componentsSeparatedByString:@"|"]];
	for (NSString* string in array) {
		NSArray* __values = [string componentsSeparatedByString:@":"];
		int _cid2 = [[__values objectAtIndex:0] intValue];
		int _mid2 = [[__values objectAtIndex:1] intValue];
		//ID相等 地图ID不相等
		if (_cid2 == _tag && _mid2 != _mid) {
			replaces = [NSString stringWithFormat:string];
			break ;
		}
	}
	
	if (replaces != nil) {
		NSString* _data = [NSString stringWithFormat:@"%d:%d",_tag,_mid];
		_info = [_info stringByReplacingOccurrencesOfString:replaces withString:_data];
		[self setPlayerCliAttr:@"World--map" value:_info];
	}
	
}

-(void)setUserWorldMap:(NSString *)_info{
	if (_info == nil )		return ;
	if (_info.length <= 0)	return ;
	
	NSDictionary *dict = [self getPlayerInfo];
	
	NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
	
	[_target setObject:_info forKey:@"wMap"];
	
	[self addData:_target key:@"player"];
	
}

-(NSString*)getUserWorldMapForString:(int)_tag map:(int)_mid{
	
	NSDictionary* _player = [self getPlayerInfo];
	NSString* _info = [_player objectForKey:@"wMap"];
	NSString* _data = [NSString stringWithFormat:@"%d:%d",_tag,_mid];
	
	if (_info == nil || _info.length == 0) {
		_info = [NSString stringWithFormat:_data];
	}else{
		NSString* replaces = nil ;
		NSMutableArray* array= [NSMutableArray arrayWithArray:[_info componentsSeparatedByString:@"|"]];
		for (NSString* string in array) {
			
			NSArray* __values = [string componentsSeparatedByString:@":"];
			int _cid2 = [[__values objectAtIndex:0] intValue];
			if (_cid2 == _tag) {
				replaces = [NSString stringWithFormat:string];
				break ;
			}
		}
		
		if (replaces != nil) {
			_info = [_info stringByReplacingOccurrencesOfString:replaces withString:_data];
		}else{
			_info = [_info stringByAppendingFormat:@"|%@",_data];
		}
	}
	return _info ;
}

-(void)addUserWorldMapWith:(NSString *)_data{
	if (_data == nil) {
		CCLOG(@"Fuck  ! data is error!!");
		return ;
	}
	
	NSString* _info = [self getPlayerCliAttr:@"World--map"];
	
	if (_info == nil) {
		_info = [NSString stringWithFormat:_data];
	}else{
		_info = [_info stringByAppendingFormat:@"|%@",_data];
	}
	
	[self setPlayerCliAttr:@"World--map" value:_info];
}

-(void)addUserWorldMap:(int)_cid{
	
	NSString* _mapInfo = [self getDefaultChapterMapInfo:_cid];
	
	[self addUserWorldMapWith:_mapInfo];
	
}

-(NSString*)getDefaultChapterMapInfo:(int)_cid{
	if (_cid <= 0) return nil;
	NSDictionary* cDict = [[GameDB shared] getChapterInfo:_cid];
	
	if (cDict != nil) {
		int _mid = [[cDict objectForKey:@"mid"] intValue];
		NSString* _info = [NSString stringWithFormat:@"%d:%d",_cid,_mid];
		return _info;
	}
	
	return nil;
}

-(NSDictionary*)getUserWorldMap{
	
	//NSString* _info = [self getPlayerCliAttr:@"World--map"];
	
	NSDictionary* _player = [self getPlayerInfo];
	
	NSString* _info = [_player objectForKey:@"wMap"];
	
	/*
	if (_info == nil || _info.length == 0) {
		_info = [NSString stringWithFormat:@"3:2|1:0|4:5|2:1|5:7"];
	}
	*/
	
	NSMutableDictionary* maps = [NSMutableDictionary dictionary];
	NSArray* array = [_info componentsSeparatedByString:@"|"];
	for (NSString* str in array) {
		NSArray* _kv = [str componentsSeparatedByString:@":"];
		if (_kv.count == 2) {
			int _cid = [[_kv objectAtIndex:0] intValue];
			int _mid = [[_kv objectAtIndex:1] intValue];
			NSString* key_ = [NSString stringWithFormat:@"%d",_cid];
			[maps setObject:[NSNumber numberWithInt:_mid] forKey:key_];
		}
	}
	return maps;
}
//++++++++++++++++++++++++++++++++++++++++++++++

-(NSDictionary*)getChooseChapter{
	NSDictionary * data = [self getDataBykey:@"player"];
	if(data){
		int cid = [[data objectForKey:@"chapter"] intValue];
		NSDictionary * chapter = [[GameDB shared] getChapterInfo:cid];
		return chapter;
	}
	return nil;
}
-(BOOL)isPlayerOnOneOrChapter{
	NSDictionary * data = [[GameConfigure shared] getPlayerInfo];
	if ( [[data objectForKey:@"chapter"] intValue] < 3 ) {
		return YES;
	}
	return NO;
}
-(BOOL)isPlayerOnChapter{
	NSDictionary * chapter = [self getChooseChapter];
	if(chapter){
		if([chapter objectForKey:@"id"]){
			CCLOG(@"isPlayerOnChapter->%d",[[chapter objectForKey:@"id"] intValue]);
			if([[chapter objectForKey:@"start"] boolValue]){
				return YES;
			}
		}
	}
	return NO;
}

-(void)checkStopChapter:(int)tid{
	NSDictionary * chapter = [self getChooseChapter];
	if(chapter){
		int endTid = [[chapter objectForKey:@"endTid"] intValue];
		if(endTid==tid){
			[GameConnection request:@"chapterComplete" format:nil target:self call:@selector(didChapterComplete:)];
			//[[GameConfigure shared] updatePlayerChapter];
		}
	}
}
-(BOOL)checkStopChapterTask:(int)_tid{
	NSDictionary * chapter = [self getChooseChapter];
	if(chapter){
		int endTid = [[chapter objectForKey:@"endTid"] intValue];
		if(endTid==_tid){
			return YES;
		}
	}
	return NO;
}
-(void)didChapterComplete:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		//nothing
		//-------
		//todo 后台章节数据
	}
	[self reloadPlayerAllData];
}

-(void)forSkipChapterReload{
	CCLOG(@"forSkipChapterReload->start");
	[GameConnection request:@"init" format:nil target:self call:@selector(didForSkipChapterReload:)];
}

-(void)didForSkipChapterReload:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		[self resetPlayerData:getResponseData(response)];
		[GameConnection post:ConnPost_getPlayerInfo object:nil];
		[GameConnection post:ConnPost_updatePlayerInfo object:nil];
		[GameConnection post:ConnPost_finishChapter object:nil];
		[GameConnection post:ConnPost_skipChapterReload object:nil];
	}
}


-(void)reloadPlayerAllData{
	CCLOG(@"reloadPlayerAllData->start");
	[GameConnection request:@"init" format:nil target:self call:@selector(didReloadPlayerAllData:)];
}

-(void)didReloadPlayerAllData:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		[self resetPlayerData:getResponseData(response)];
		[GameConnection post:ConnPost_getPlayerInfo object:nil];
		//------------------
		[GameConnection post:ConnPost_updatePlayerInfo object:nil];
		[GameConnection post:ConnPost_finishChapter object:nil];
	}
}

-(NSString*)getPlayerCliAttr:(NSString*)key{
	NSDictionary * data = [self getDataBykey:@"cliAttr"];
	return [data objectForKey:key];
}

-(void)setPlayerCliAttr:(NSString*)key value:(id)_value{
	if (key == nil || _value == nil) return ;
	
	CCLOG(@"setPlayerCliAttr:%@|%@",key,_value);
	
	NSDictionary * data = [self getDataBykey:@"cliAttr"];
	if (data == nil) {
		data = [NSDictionary dictionary];
	}
	
	NSMutableDictionary* temp = [NSMutableDictionary dictionaryWithDictionary:data];
	[temp setObject:_value forKey:key];
	
	//先跟新本地数据
	[self addData:temp key:@"cliAttr"];
	
	//发送数据
	NSMutableDictionary* _send = [NSMutableDictionary dictionary];
	[_send setObject:key forKey:@"key"];
	[_send setObject:_value forKey:@"value"];
	
	[GameConnection request:@"cliAttrSet" data:_send target:nil call:nil];
	
}

-(int)getPlayerLevel{
	//if([self isPlayerOnChapter]) return 99;
	NSDictionary * data = [self getDataBykey:@"player"];
	if(data){
		int level = [[data objectForKey:@"level"] intValue];
		return level;
	}
	return 1;
}
-(NSDictionary*)getPlayerById:(int)_id{
	NSArray *player_list = [self getPlayerList];
	if([player_list count]>0){
		for(NSDictionary*dict in player_list){
			if([[dict objectForKey:@"id"] intValue]==_id){
				return dict;
			}
		}
		
	}
	return nil;
}
-(int)getRoleQualityWithRid:(int)_rid{
	int quality = IQ_GREEN;
	NSDictionary *role = [self getPlayerRoleFromListById:_rid];
	if (role) {
		//int _q1 = [[role objectForKey:@"quality"] intValue];
        int _q1 = [[role objectForKey:@"q"] intValue];
		if (_q1 == 0) {
			NSDictionary* db = [[GameDB shared] getRoleInfo:_rid];
			 _q1 = [[db objectForKey:@"quality"] intValue];
			if (_q1!=0) {
				quality = _q1;
			}else{
				CCLOG(@"get role quality error");
			}
		}else{
            quality = _q1;
        }
	}
	return quality;
}
-(int)getPlayerLastMapId{
	NSDictionary * data = [self getDataBykey:@"player"];
	return [[data objectForKey:@"preMId"] intValue];
}
-(void)setPlayerLocation:(CGPoint)point mapId:(int)mid{
	
	NSDictionary * data = [self getDataBykey:@"player"];
	if(data){
		NSMutableDictionary * player = [NSMutableDictionary dictionaryWithDictionary:data];
		int mapId = [[player objectForKey:@"mapId"] intValue];
		if(mapId==mid){
			
			if(isCanSendMove){
				//移动 move
				NSString * fm = [NSString stringWithFormat:@"pos:%@",NSStringFromCGPoint(point)];
				[GameConnection request:@"move" format:fm target:nil call:nil];
			}
			
		}else{
			//进入地图 enterMap
			//
			//todo 跳地图的时候先处理网络数据
			//
//			NSString * fm = [NSString stringWithFormat:@"mid::%d",mid];
//			[GameConnection request:@"enterMap" format:fm target:nil call:nil];
		}
		
		[player setObject:[NSNumber numberWithInt:mid] forKey:@"mapId"];
		[player setObject:NSStringFromCGPoint(point) forKey:@"pos"];
		[self addData:player key:@"player"];
	}
}

-(NSDictionary*)getUserMapInfo{
	NSDictionary * player = [self getDataBykey:@"player"];
	int mapId = [[player objectForKey:@"mapId"] intValue];
	return [[GameDB shared] getMapInfo:mapId];
}

-(NSDictionary*)getUserMapByMapId:(int)mapId{
	NSMutableArray * userMap = [self getDataBykey:@"map"];
	NSMutableDictionary * targetMap = nil;
	for(NSMutableDictionary * map in userMap){
		int mid = [[map objectForKey:@"mid"] intValue];
		if(mapId==mid){
			targetMap = map;
		}
	}
	if(targetMap==nil){
		targetMap = [NSMutableDictionary dictionary];
		[targetMap setObject:[NSNumber numberWithInt:mapId] forKey:@"mid"];
		[targetMap setObject:@"" forKey:@"data"];
		//[targetMap setObject:@"" forKey:@"dels"];//删除的列表
	}
	return targetMap;
}

-(NSArray*)getUserMapNPCByMapId:(int)mapId{
	NSDictionary * userMap = [self getUserMapByMapId:mapId];
	//data = @"1:{55,47}|2:{43,69}";
	NSString * data = [userMap objectForKey:@"data"];
	return getNPCListByData(data);
}


//-(void)updateMapNPCData:(NSString *)data map:(int)mapId handle:(MapNpc_handle)_handle{
//	
//	NSArray * userMapData = [self getDataBykey:@"map"];
//	
//	if(userMapData){
//		
//		NSMutableArray * userMap = [NSMutableArray arrayWithArray:userMapData];
//		
//		int index = -1;
//		for(int i=0;i<[userMap count];i++){
//			NSDictionary * map = [userMap objectAtIndex:i];
//			int mid = [[map objectForKey:@"mid"] intValue];
//			if(mapId==mid){
//				index = i;
//			}
//		}
//		
//		NSString *d1 = nil;
//		NSString *d2 = nil;
//		
//		if(index>=0){
//			NSMutableDictionary * tmpMap = [NSMutableDictionary dictionaryWithDictionary:[userMap objectAtIndex:index]];
//			[userMap removeObjectAtIndex:index];
//			if (MapNpc_data  == _handle) {
//				[tmpMap setObject:data forKey:@"data"];
//			}else{
//				[tmpMap setObject:data forKey:@"dels"];
//			}
//			d1 = [tmpMap objectForKey:@"data"];
//			d2 = [tmpMap objectForKey:@"dels"];
//			
//			[userMap addObject:tmpMap];
//		}else{
//			NSMutableDictionary * tmpMap = [NSMutableDictionary dictionary];
//			[tmpMap setObject:[NSNumber numberWithInt:mapId] forKey:@"mid"];
//			if (MapNpc_data  == _handle) {
//				[tmpMap setObject:data forKey:@"data"];
//			}else{
//				[tmpMap setObject:data forKey:@"dels"];
//			}
//			
//			d1 = [tmpMap objectForKey:@"data"];
//			d2 = [tmpMap objectForKey:@"dels"];
//			
//			[userMap addObject:tmpMap];
//		}
//		
//		[self addData:userMap key:@"map"];
//		
//		NSMutableDictionary * dict = [NSMutableDictionary dictionary];
//		[dict setObject:[NSNumber numberWithInt:mapId] forKey:@"mid"];
//		
//		[dict setObject:d1 forKey:@"data"];
//		[dict setObject:d2 forKey:@"dels"];
//		
//		[GameConnection request:@"mapUpdate" data:dict target:nil call:nil];
//		
//	}
//
//}
-(void)updateMapNPCData:(NSString *)data map:(int)mapId target:(id)_t call:(SEL)_c{
	NSArray * userMapData = [self getDataBykey:@"map"];
	if(userMapData){
		
		NSMutableArray * userMap = [NSMutableArray arrayWithArray:userMapData];
		
		int index = -1;
		for(int i=0;i<[userMap count];i++){
			NSDictionary * map = [userMap objectAtIndex:i];
			int mid = [[map objectForKey:@"mid"] intValue];
			if(mapId==mid){
				index = i;
			}
		}
		
		if(index>=0){
			NSMutableDictionary * tmpMap = [NSMutableDictionary dictionaryWithDictionary:[userMap objectAtIndex:index]];
			[userMap removeObjectAtIndex:index];
			[tmpMap setObject:data forKey:@"data"];
			[userMap addObject:tmpMap];
		}else{
			NSMutableDictionary * tmpMap = [NSMutableDictionary dictionary];
			[tmpMap setObject:[NSNumber numberWithInt:mapId] forKey:@"mid"];
			[tmpMap setObject:data forKey:@"data"];
			[userMap addObject:tmpMap];
		}
		[self addData:userMap key:@"map"];
		
		NSMutableDictionary * dict = [NSMutableDictionary dictionary];
		[dict setObject:[NSNumber numberWithInt:mapId] forKey:@"mid"];
		[dict setObject:data forKey:@"data"];
		
		[GameConnection request:@"mapUpdate" data:dict target:_t call:_c];
	}
	
}

-(BOOL)addUserMapNPC:(int)npcId map:(int)mapId
			   point:(CGPoint)point direction:(int)direction target:(id)_t call:(SEL)_c{
	
	NSMutableDictionary * npc = [NSMutableDictionary dictionary];
	[npc setObject:[NSNumber numberWithInt:npcId] forKey:@"nid"];
	[npc setObject:NSStringFromCGPoint(point) forKey:@"point"];
	[npc setObject:[NSNumber numberWithInt:direction] forKey:@"direction"];
	
	
	NSDictionary * userMap = [self getUserMapByMapId:mapId];
	NSString * data = [userMap objectForKey:@"data"];
	
	NSMutableArray * npcs = [NSMutableArray arrayWithArray:getNPCListByData(data)];
	
	int	count = 0;
	
	for(NSDictionary * tmpNPC in npcs){
		
		int nid = [[tmpNPC objectForKey:@"nid"] intValue];
		
		if(nid==npcId){
			NSArray* keys = [tmpNPC allKeys];
			if ([keys containsObject:@"count"]) {
				count = [[tmpNPC objectForKey:@"count"] intValue];
			}else{
				count = 1 ;
			}
			[npcs removeObject:tmpNPC];
			break;
		}
		
	}
	
	count += 1 ;
	
	[npc setObject:[NSNumber numberWithInt:count] forKey:@"count"];
	[npcs addObject:npc];
	
	
	NSString * NPCData = getNPCDataByList(npcs);
	[self updateMapNPCData:NPCData map:mapId target:_t call:_c];
	
	return YES;
}

-(void)removeUserMapNPCWith:(int)mapId{
	//删除指定地图的全部数据
	[self updateMapNPCData:@"" map:mapId target:nil call:nil];
}

-(void)removeUserMapNPC:(int)npcId map:(int)mapId target:(id)_t call:(SEL)_c{
	NSDictionary * userMap = [self getUserMapByMapId:mapId];
	NSString * data = [userMap objectForKey:@"data"];
	NSMutableArray * npcs = [NSMutableArray arrayWithArray:getNPCListByData(data)];
	
	NSMutableDictionary* _dict = nil;
	for(NSDictionary * tmpNPC in npcs){
		int nid = [[tmpNPC objectForKey:@"nid"] intValue];
		if(nid==npcId){
			_dict = [NSMutableDictionary dictionaryWithDictionary:tmpNPC];
			[npcs removeObject:tmpNPC];
			break;
		}
	}
	
	if (_dict != nil) {
		
		NSArray* keys = [_dict allKeys];
		int count = 0 ;
		if ([keys containsObject:@"count"]) {
			count = [[_dict objectForKey:@"count"] intValue];
		}
		count -= 1;
		//还有的时候 就继续加回去
		if (count > 0) {
			[_dict setObject:[NSNumber numberWithInt:count] forKey:@"count"];
			[npcs addObject:_dict];
		}
		
	}
	
	NSString * NPCData = getNPCDataByList(npcs);
	[self updateMapNPCData:NPCData map:mapId target:_t call:_c];
}


/*
-(void)updateMapNPCData:(NSString*)data map:(int)mapId{
	NSArray * userMapData = [self getDataBykey:@"map"];
	if(userMapData){
		
		NSMutableArray * userMap = [NSMutableArray arrayWithArray:userMapData];
		
		int index = -1;
		for(int i=0;i<[userMap count];i++){
			NSDictionary * map = [userMap objectAtIndex:i];
			int mid = [[map objectForKey:@"mid"] intValue];
			if(mapId==mid){
				index = i;
			}
		}
		
		if(index>=0){
			NSMutableDictionary * tmpMap = [NSMutableDictionary dictionaryWithDictionary:[userMap objectAtIndex:index]];
			[userMap removeObjectAtIndex:index];
			[tmpMap setObject:data forKey:@"data"];
			[userMap addObject:tmpMap];
		}else{
			NSMutableDictionary * tmpMap = [NSMutableDictionary dictionary];
			[tmpMap setObject:[NSNumber numberWithInt:mapId] forKey:@"mid"];
			[tmpMap setObject:data forKey:@"data"];
			[userMap addObject:tmpMap];
		}
		[self addData:userMap key:@"map"];
		
		NSMutableDictionary * dict = [NSMutableDictionary dictionary];
		[dict setObject:[NSNumber numberWithInt:mapId] forKey:@"mid"];
		[dict setObject:data forKey:@"data"];
		
		[GameConnection request:@"mapUpdate" data:dict target:nil call:nil];
		
	}
}

-(BOOL)addUserMapNPC:(int)npcId map:(int)mapId point:(CGPoint)point direction:(int)direction{
	//TODO ?????
	
	NSMutableDictionary * npc = [NSMutableDictionary dictionary];
	[npc setObject:[NSNumber numberWithInt:npcId] forKey:@"nid"];
	[npc setObject:NSStringFromCGPoint(point) forKey:@"point"];
	[npc setObject:[NSNumber numberWithInt:direction] forKey:@"direction"];
	
	NSDictionary * userMap = [self getUserMapByMapId:mapId];
	NSString * data = [userMap objectForKey:@"data"];
	
	NSMutableArray * npcs = [NSMutableArray arrayWithArray:getNPCListByData(data)];
	
	for(NSDictionary * tmpNPC in npcs){
		int nid = [[tmpNPC objectForKey:@"nid"] intValue];
		if(nid==npcId){
			[npcs removeObject:tmpNPC];
			break;
		}
	}
	
	[npcs addObject:npc];
	
	NSString * NPCData = getNPCDataByList(npcs);
	[self updateMapNPCData:NPCData map:mapId];
	
	return YES;
}
-(void)removeUserMapNPC:(int)npcId map:(int)mapId{
	
	NSDictionary * userMap = [self getUserMapByMapId:mapId];
	NSString * data = [userMap objectForKey:@"data"];
	NSMutableArray * npcs = [NSMutableArray arrayWithArray:getNPCListByData(data)];
	
	for(NSDictionary * tmpNPC in npcs){
		int nid = [[tmpNPC objectForKey:@"nid"] intValue];
		if(nid==npcId){
			[npcs removeObject:tmpNPC];
			break;
		}
	}
	NSString * NPCData = getNPCDataByList(npcs);
	[self updateMapNPCData:NPCData map:mapId];
}
*/
//==============================================================================
//==============================================================================

//-(NSDictionary*)getMapInfoById:(int)mid{
//	
//	//TODO test data
//	if(mid==1){
//		NSMutableDictionary * info = [NSMutableDictionary dictionary];
//		[info setObject:[NSNumber numberWithInt:mid] forKey:@"id"];
//		[info setObject:[NSNumber numberWithInt:1] forKey:@"type"];
//		[info setObject:[NSNumber numberWithInt:0] forKey:@"pmid"];
//		[info setObject:@"test map" forKey:@"name"];
//		[info setObject:@"test map" forKey:@"info"];
//		[info setObject:@"start.tmx" forKey:@"tiledFile"];
//		[info setObject:[NSNumber numberWithBool:YES] forKey:@"multi"];
//		return info;
//	}
//	if(mid==2){
//		NSMutableDictionary * info = [NSMutableDictionary dictionary];
//		[info setObject:[NSNumber numberWithInt:mid] forKey:@"id"];
//		[info setObject:[NSNumber numberWithInt:2] forKey:@"type"];
//		[info setObject:[NSNumber numberWithInt:1] forKey:@"pmid"];
//		[info setObject:@"test map" forKey:@"name"];
//		[info setObject:@"test map" forKey:@"info"];
//		[info setObject:@"stage1.tmx" forKey:@"tiledFile"];
//		[info setObject:[NSNumber numberWithBool:NO] forKey:@"multi"];
//		return info;
//	}
//	if(mid==3){
//		NSMutableDictionary * info = [NSMutableDictionary dictionary];
//		[info setObject:[NSNumber numberWithInt:mid] forKey:@"id"];
//		[info setObject:[NSNumber numberWithInt:2] forKey:@"type"];
//		[info setObject:[NSNumber numberWithInt:1] forKey:@"pmid"];
//		[info setObject:@"test map" forKey:@"name"];
//		[info setObject:@"test map" forKey:@"info"];
//		[info setObject:@"stage1.tmx" forKey:@"tiledFile"];
//		[info setObject:[NSNumber numberWithBool:NO] forKey:@"multi"];
//		return info;
//	}
//	
//	NSMutableDictionary * info = [NSMutableDictionary dictionary];
//	[info setObject:[NSNumber numberWithInt:mid] forKey:@"id"];
//	[info setObject:[NSNumber numberWithInt:1] forKey:@"type"];
//	[info setObject:@"test map" forKey:@"name"];
//	[info setObject:@"test map" forKey:@"info"];
//	[info setObject:@"start.tmx" forKey:@"tiledFile"];
//	[info setObject:[NSNumber numberWithBool:YES] forKey:@"multi"];
//	
//	return info;
//}

//-(NSDictionary*)getNPCInfoById:(int)nid{
//	
//	//TODO test data
//	
//	NSMutableDictionary * info = [NSMutableDictionary dictionary];
//	[info setObject:[NSNumber numberWithInt:nid] forKey:@"id"];
//	[info setObject:[NSString stringWithFormat:@"npc_%d",nid] forKey:@"name"];
//	
//	//TODO test
//	[info setObject:@"fuck!|fuck 2!|fuck 3!" forKey:@"msg"];
//	[info setObject:@"" forKey:@"func"];
//	[info setObject:[NSNumber numberWithBool:YES] forKey:@"isShowName"];
//	
//	if(nid==1){
//		[info setObject:@"1:2" forKey:@"func"];//NPC_FUNC_MAP to map id : 2
//	}
//	if(nid==2){
//		[info setObject:@"3:1" forKey:@"func"];//NPC_FUNC_STAGE to stage id : 1
//		[info setObject:[NSNumber numberWithBool:NO] forKey:@"isShowName"];
//	}
//	if(nid==3){
//		[info setObject:@"4:2" forKey:@"func"];//NPC_FUNC_FIGHT to fight id : 2
//	}
//	
//	return info;
//	
//}

//==============================================================================
//任务数据=======================================================================
//==============================================================================

//取用户当前已接受的多个任务
-(NSArray*)getUserTaskList{
	//------TODO
	//2012 12 15 任务数据改动
	//fix by soul
	NSDictionary *dict = [self getDataBykey:@"task"];
	NSAssert(dict != nil, @"TasList from sever is null.");
	if (dict) {
		NSArray * userTasks = [dict objectForKey:@"tasks"];
		return userTasks;
	}
	return nil;
}

-(void)removeUserTaskList{
	NSDictionary * dict = [self getDataBykey:@"task"];
	if(dict){
		NSMutableArray * userTasks = [NSMutableArray array];
		
		NSMutableDictionary * userData = [NSMutableDictionary dictionaryWithDictionary:dict];
		
		[userData setObject:userTasks forKey:@"tasks"];
		
		[self addData:userData key:@"task"];
	}	
}

-(void)startUserTask:(int)userTaskId{
	
	//更新UserTask isRun , 停止用户正在执行的UserTask
	NSDictionary * dict = [self getDataBykey:@"task"];
	if(dict){
		NSArray * tasks = [dict objectForKey:@"tasks"];
		NSMutableArray * userTasks = [NSMutableArray array];
		for(NSDictionary * task in tasks){
			if([[task objectForKey:@"id"] intValue]==userTaskId){
				NSMutableDictionary * tTask = [NSMutableDictionary dictionaryWithDictionary:task];
				[tTask setObject:[NSNumber numberWithBool:YES] forKey:@"isRun"];
				[userTasks addObject:tTask];
			}else{
				[userTasks addObject:task];
			}
		}
		NSMutableDictionary * userData = [NSMutableDictionary dictionaryWithDictionary:dict];
		[userData setObject:userTasks forKey:@"tasks"];
		[self addData:userData key:@"task"];
	}
	
	NSString * format = [NSString stringWithFormat:@"id::%d",userTaskId];
	[GameConnection request:@"taskActive" format:format target:nil call:nil];
	
}

-(void)updateUserTask:(int)userTaskId step:(int)step{
	
	NSDictionary * dict = [self getDataBykey:@"task"];
	if(dict){
		NSArray * tasks = [dict objectForKey:@"tasks"];
		NSMutableArray * userTasks = [NSMutableArray array];
		for(NSDictionary * task in tasks){
			if([[task objectForKey:@"id"] intValue]==userTaskId){
				NSMutableDictionary * tTask = [NSMutableDictionary dictionaryWithDictionary:task];
				[tTask setObject:[NSNumber numberWithInt:step] forKey:@"step"];
				[userTasks addObject:tTask];
			}else{
				[userTasks addObject:task];
			}
		}
		NSMutableDictionary * userData = [NSMutableDictionary dictionaryWithDictionary:dict];
		[userData setObject:userTasks forKey:@"tasks"];
		[self addData:userData key:@"task"];
	}
	
	//call update user task 
	NSString * format = [NSString stringWithFormat:@"id::%d|step::%d",userTaskId,step];
	[GameConnection request:@"taskUpdate" format:format target:nil call:nil];
	
}

-(void)completeUserTask:(int)userTaskId target:(id)target call:(SEL)call{
	
	//更新UserTask状态->完成 , 返回更新的UserTask列表，与返回任务的奖励
	
	NSDictionary * dict = [self getDataBykey:@"task"];
	if(dict){
		
		//int tid = 0;
		
		NSArray * tasks = [dict objectForKey:@"tasks"];
		NSMutableArray * userTasks = [NSMutableArray array];
		for(NSDictionary * task in tasks){
			if([[task objectForKey:@"id"] intValue]==userTaskId){
				NSMutableDictionary * tTask = [NSMutableDictionary dictionaryWithDictionary:task];
				
				[tTask setObject:[NSNumber numberWithInt:Task_Status_complete] forKey:@"status"];
				[tTask setObject:[NSNumber numberWithBool:NO] forKey:@"isRun"];
				
				[userTasks addObject:tTask];
				//2013-3-24
				//tid = [[task objectForKey:@"tid"] intValue];
			}else{
				[userTasks addObject:task];
			}
		}
		NSMutableDictionary * userData = [NSMutableDictionary dictionaryWithDictionary:dict];
		[userData setObject:userTasks forKey:@"tasks"];
		[self addData:userData key:@"task"];
		
		
		//if(tid>0) [self checkStopChapter:tid];
		
	}
	CCLOG(@"completeUserTask->%d",userTaskId);
	//call update user task
	NSString * format = [NSString stringWithFormat:@"id::%d",userTaskId];
	[GameConnection request:@"taskComplete" format:format target:target call:call];
	
}
-(NSArray*)getCompleteUserTaskList{
	NSDictionary * dict = [self getDataBykey:@"task"];
	if (dict) {
		NSString *list = [dict objectForKey:@"taskIds"];
		if (list && list.length > 0) {
			NSData *data = [NSData dataFromBase64String:list];
			int length = [data length];
			NSMutableArray *result = [NSMutableArray array];
			for (int pointr = 0; pointr < length;) {
				unsigned int temp ;
				[data getBytes:&temp range:NSMakeRange(pointr, sizeof(temp))];
				pointr +=  sizeof(temp);
				CCLOG(@"%u",temp);
				[result addObject:[NSNumber numberWithUnsignedInt:temp]];
			}
			return result;
		}
	}
	return nil;
}
-(void)addNewUserTasks:(NSArray*)tasks{
	if (tasks == nil) return ;
	NSDictionary * dict = [self getDataBykey:@"task"];
	if(dict){
		/*
		NSMutableArray * userTasks = [NSMutableArray arrayWithArray:[dict objectForKey:@"tasks"]];
		
		CCLOG(@"addNewUserTasks %@", userTasks);
		
		NSMutableArray* addTemp = [NSMutableArray array];
		for (NSDictionary *dict in tasks) {
			BOOL isHas = NO ;
			int tid = [[dict objectForKey:@"tid"] intValue];
			for (NSDictionary *uTask in userTasks) {
				int otid = [[uTask objectForKey:@"tid"] intValue];
				if (otid == tid && tid != 0) {
					isHas = YES ;
					break ;
				}
			}
			if (!isHas) {
				[addTemp addObject:dict];
			}
		}
		
		[userTasks addObjectsFromArray:addTemp];
		
		CCLOG(@"addNewUserTasks end %@", userTasks);
		
		NSMutableDictionary * userData = [NSMutableDictionary dictionaryWithDictionary:dict];
		[userData setObject:userTasks forKey:@"tasks"];
		[self addData:userData key:@"task"];
		 */
		NSMutableArray * userTasks = [NSMutableArray arrayWithArray:[dict objectForKey:@"tasks"]];
		
		//addNewUserTasks
		CCLOG(@"addNewUserTasks %@", userTasks);
		
		[userTasks addObjectsFromArray:tasks];
		
		// test addNewUserTasks
		CCLOG(@"addNewUserTasks after %@", userTasks);
		
		NSMutableDictionary * userData = [NSMutableDictionary dictionaryWithDictionary:dict];
		[userData setObject:userTasks forKey:@"tasks"];
		[self addData:userData key:@"task"];
	}
}

-(void)removeUserTasksById:(int)tid
{
	NSDictionary * dict = [self getDataBykey:@"task"];
	if(dict){
		NSMutableArray * userTasks = [NSMutableArray arrayWithArray:[dict objectForKey:@"tasks"]];
		
		for (NSDictionary *dict in userTasks) {
			int _tid = [[dict objectForKey:@"tid"] intValue];
			if (_tid == tid) {
				[userTasks removeObject:dict];
				break;
			}
		}
		
		NSMutableDictionary * userData = [NSMutableDictionary dictionaryWithDictionary:dict];
		[userData setObject:userTasks forKey:@"tasks"];
		[self addData:userData key:@"task"];
	}
}

-(NSDictionary*)getTaskInfoById:(int)tid{
	/*
	 //TODO get task info
	 if(!testTaskList) return nil;
	 return [testTaskList objectForKey:[NSString stringWithFormat:@"%d",tid]];
	 */
	
	NSDictionary * task = nil;
	
	task = [[GameDB shared] getTaskInfo:Task_Type_main taskId:tid];
	if(task) return task;
	task = [[GameDB shared] getTaskInfo:Task_Type_vice taskId:tid];
	if(task) return task;
	task = [[GameDB shared] getTaskInfo:Task_Type_offer taskId:tid];
	if(task) return task;
	task = [[GameDB shared] getTaskInfo:Task_Type_hide taskId:tid];
	if(task) return task;
	
	return nil;
}

/*
 -(void)initTestTsakList{
 
 //TODO init test data
 if(testTaskList) return;
 testTaskList = [NSMutableDictionary dictionary];
 [testTaskList retain];
 
 //主线任务
 [testTaskList setObject:[self getTestTaskInfoById:1 type:1] forKey:@"1"];
 [testTaskList setObject:[self getTestTaskInfoById:2 type:1] forKey:@"2"];
 [testTaskList setObject:[self getTestTaskInfoById:3 type:1] forKey:@"3"];
 [testTaskList setObject:[self getTestTaskInfoById:4 type:1] forKey:@"4"];
 [testTaskList setObject:[self getTestTaskInfoById:5 type:1] forKey:@"5"];
 [testTaskList setObject:[self getTestTaskInfoById:6 type:1] forKey:@"6"];
 [testTaskList setObject:[self getTestTaskInfoById:7 type:1] forKey:@"7"];
 [testTaskList setObject:[self getTestTaskInfoById:8 type:1] forKey:@"8"];
 [testTaskList setObject:[self getTestTaskInfoById:9 type:1] forKey:@"9"];
 [testTaskList setObject:[self getTestTaskInfoById:10 type:1] forKey:@"10"];
 [testTaskList setObject:[self getTestTaskInfoById:11 type:1] forKey:@"11"];
 [testTaskList setObject:[self getTestTaskInfoById:12 type:1] forKey:@"12"];
 [testTaskList setObject:[self getTestTaskInfoById:13 type:1] forKey:@"13"];
 [testTaskList setObject:[self getTestTaskInfoById:14 type:1] forKey:@"14"];
 [testTaskList setObject:[self getTestTaskInfoById:15 type:1] forKey:@"15"];
 [testTaskList setObject:[self getTestTaskInfoById:16 type:1] forKey:@"16"];
 [testTaskList setObject:[self getTestTaskInfoById:17 type:1] forKey:@"17"];
 [testTaskList setObject:[self getTestTaskInfoById:18 type:1] forKey:@"18"];
 [testTaskList setObject:[self getTestTaskInfoById:19 type:1] forKey:@"19"];
 [testTaskList setObject:[self getTestTaskInfoById:20 type:1] forKey:@"20"];
 
 //支线任务
 [testTaskList setObject:[self getTestTaskInfoById:101 type:2] forKey:@"101"];
 [testTaskList setObject:[self getTestTaskInfoById:102 type:2] forKey:@"102"];
 [testTaskList setObject:[self getTestTaskInfoById:103 type:2] forKey:@"103"];
 [testTaskList setObject:[self getTestTaskInfoById:104 type:2] forKey:@"104"];
 [testTaskList setObject:[self getTestTaskInfoById:105 type:2] forKey:@"105"];
 [testTaskList setObject:[self getTestTaskInfoById:106 type:2] forKey:@"106"];
 
 //悬赏任务
 [testTaskList setObject:[self getTestTaskInfoById:1001 type:3] forKey:@"1001"];
 [testTaskList setObject:[self getTestTaskInfoById:1002 type:3] forKey:@"1002"];
 [testTaskList setObject:[self getTestTaskInfoById:1003 type:3] forKey:@"1003"];
 [testTaskList setObject:[self getTestTaskInfoById:1004 type:3] forKey:@"1004"];
 [testTaskList setObject:[self getTestTaskInfoById:1005 type:3] forKey:@"1005"];
 
 //隐藏任务
 [testTaskList setObject:[self getTestTaskInfoById:10001 type:4] forKey:@"10001"];
 [testTaskList setObject:[self getTestTaskInfoById:10002 type:4] forKey:@"10002"];
 
 }
 */

/*
 -(NSDictionary*)getTestTaskInfoById:(int)tid{
 
 //TODO test data
 
 NSMutableDictionary * info = [NSMutableDictionary dictionary];
 
 [info setObject:[NSNumber numberWithInt:tid] forKey:@"id"];
 [info setObject:[NSNumber numberWithInt:1] forKey:@"type"];//主线任务
 
 [info setObject:[NSString stringWithFormat:@"task_%d",tid] forKey:@"name"];
 [info setObject:[NSString stringWithFormat:@"icon_task_%d",tid] forKey:@"icon"];
 [info setObject:[NSString stringWithFormat:@"info task %d",tid] forKey:@"info"];
 
 //TODO 结构 task:1|level:1|role:7|obj:1:3|equ:5
 //一般主线任务是没有unlock
 //task:1 任务id为1已完成 可以多个 task:1|task:2|task:3 用于多完成多个支线任务才达到条件
 //level:1 玩家级数到达1
 //role:1 玩家角色里有的角色id 可以多个->role:1|role:2|role:3
 //obj:1:3 玩家背包里有的物品obj id为1的数量是3  可以多个->obj:1:3|obj:2:2|obj:3:1
 //equ:5 玩家有装备equ id为5的装备 可以多个->equ:5|equ:6|equ:7|equ:8 多个装备可以用于收藏整个套装后激活技定的任务
 [info setObject:@"" forKey:@"unlock"];
 
 [info setObject:[NSNumber numberWithInt:(tid+1)] forKey:@"nextId"];//用于多个任务关连
 [info setObject:[NSNumber numberWithInt:1] forKey:@"rid"];//奖励ID，调用奖励接口
 
 [info setObject:@"" forKey:@"step"];//非常复杂
 
 return info;
 }
 */

/*
 //TODO test load task data;
 -(NSDictionary*)getTestTaskInfoById:(int)tid type:(int)type{
 NSMutableDictionary * info = [NSMutableDictionary dictionaryWithDictionary:[self getTestTaskInfoById:tid]];
 
 [info setObject:[NSNumber numberWithInt:type] forKey:@"type"];
 
 if(type==1){
 
 //完成上一级任务
 [info setObject:[NSString stringWithFormat:@"task:%d",(tid-1)] forKey:@"unlock"];
 
 [info setObject:[NSNumber numberWithInt:(tid+1)] forKey:@"nextId"];
 //TODO add task step data
 
 
 NSMutableArray * processList = [NSMutableArray array];
 
 NSMutableDictionary * process;
 NSMutableDictionary * data;
 
 
 //		//move
 //		process = [self getProcess:Task_Action_move];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 //		[data setObject:NSStringFromCGPoint(ccp(53,68)) forKey:@"point"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//move
 //		process = [self getProcess:Task_Action_move];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:2] forKey:@"mapId"];
 //		[data setObject:NSStringFromCGPoint(ccp(53,68)) forKey:@"point"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 
 //move to npc 1
 process = [self getProcess:Task_Action_moveToNPC];
 data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 [data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 [data setObject:[NSNumber numberWithInt:1] forKey:@"npcId"];
 [process setObject:data forKey:@"data"];
 [processList addObject:process];
 
 //fight 1
 
 process = [self getProcess:Task_Action_fight];
 data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 [data setObject:[NSNumber numberWithInt:1] forKey:@"fid"];
 [process setObject:data forKey:@"data"];
 [processList addObject:process];
 
 //talk 1
 process = [self getProcess:Task_Action_talk];
 [processList addObject:process];
 
 //move to npc 2
 process = [self getProcess:Task_Action_moveToNPC];
 data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 [data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 [data setObject:[NSNumber numberWithInt:2] forKey:@"npcId"];
 [process setObject:data forKey:@"data"];
 [processList addObject:process];
 
 // stage 1
 process = [self getProcess:Task_Action_stage];
 data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 [data setObject:[NSNumber numberWithInt:100] forKey:@"sid"];
 
 NSMutableArray * p = [NSMutableArray array];
 NSMutableArray * a1 = [NSMutableArray array];
 
 NSMutableDictionary * e1 = [self getProcess:Task_Action_addNpc];
 NSMutableDictionary * d1 = [NSMutableDictionary dictionaryWithDictionary:[e1 objectForKey:@"data"]];
 [d1 setObject:[NSNumber numberWithInt:3] forKey:@"npcId"];
 [d1 setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
 [d1 setObject:NSStringFromCGPoint(ccp(50,70)) forKey:@"point"];
 [e1 setObject:d1 forKey:@"data"];
 [a1 addObject:e1];
 
 e1 = [self getProcess:Task_Action_talk];
 [a1 addObject:e1];
 
 e1 = [self getProcess:Task_Action_effects];
 d1 = [NSMutableDictionary dictionaryWithDictionary:[e1 objectForKey:@"data"]];
 [d1 setObject:[NSNumber numberWithInt:EffectsAction_loshing] forKey:@"eid"];
 [e1 setObject:d1 forKey:@"data"];
 [a1 addObject:e1];
 
 e1 = [self getProcess:Task_Action_removeNpc];
 d1 = [NSMutableDictionary dictionaryWithDictionary:[e1 objectForKey:@"data"]];
 [d1 setObject:[NSNumber numberWithInt:3] forKey:@"npcId"];
 [d1 setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
 [e1 setObject:d1 forKey:@"data"];
 [a1 addObject:e1];
 
 NSMutableDictionary * p1 = [NSMutableDictionary dictionary];
 [p1 setObject:a1 forKey:@"before"];
 [p1 setObject:a1 forKey:@"behind"];
 
 p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
 [p1 setObject:[NSNumber numberWithInt:0] forKey:@"index"];
 [p addObject:p1];
 
 p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
 [p1 setObject:[NSNumber numberWithInt:1] forKey:@"index"];
 [p addObject:p1];
 
 p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
 [p1 setObject:[NSNumber numberWithInt:2] forKey:@"index"];
 [p addObject:p1];
 
 p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
 [p1 setObject:[NSNumber numberWithInt:3] forKey:@"index"];
 [p addObject:p1];
 
 p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
 [p1 setObject:[NSNumber numberWithInt:4] forKey:@"index"];
 [p addObject:p1];
 
 p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
 [p1 setObject:[NSNumber numberWithInt:5] forKey:@"index"];
 [p addObject:p1];
 
 [data setObject:p forKey:@"process"];
 
 [process setObject:data forKey:@"data"];
 [processList addObject:process];
 
 //move to npc 1
 process = [self getProcess:Task_Action_moveToNPC];
 data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 [data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 [data setObject:[NSNumber numberWithInt:1] forKey:@"npcId"];
 [process setObject:data forKey:@"data"];
 [processList addObject:process];
 
 //talk 1
 process = [self getProcess:Task_Action_talk];
 [processList addObject:process];
 
 
 
 
 //		//show effects EffectsAction_loshing
 //		process = [self getProcess:Task_Action_effects];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:EffectsAction_loshing] forKey:@"eid"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//show unlock BT_HAMMER_TAG
 //		process = [self getProcess:Task_Action_unlock];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:BT_HAMMER_TAG] forKey:@"unlockID"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//add NPC 3
 //		process = [self getProcess:Task_Action_addNpc];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:3] forKey:@"npcId"];
 //		[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 //		[data setObject:NSStringFromCGPoint(ccp(65,87)) forKey:@"point"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//move to npc 3
 //		process = [self getProcess:Task_Action_moveToNPC];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 //		[data setObject:[NSNumber numberWithInt:3] forKey:@"npcId"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//talk 1
 //		process = [self getProcess:Task_Action_talk];
 //		[processList addObject:process];
 //		
 //		//show unlock BT_HAMMER_TAG
 //		process = [self getProcess:Task_Action_unlock];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:BT_RECRUIT_TAG] forKey:@"unlockID"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//move npc 3
 //		process = [self getProcess:Task_Action_moveNpc];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:3] forKey:@"npcId"];
 //		[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 //		[data setObject:NSStringFromCGPoint(ccp(57,72)) forKey:@"point"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//move to npc 3
 //		process = [self getProcess:Task_Action_moveToNPC];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 //		[data setObject:[NSNumber numberWithInt:3] forKey:@"npcId"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//talk 1
 //		process = [self getProcess:Task_Action_talk];
 //		[processList addObject:process];
 //		
 //		//show unlock BT_HAMMER_TAG
 //		process = [self getProcess:Task_Action_unlock];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:BT_UNION_TAG] forKey:@"unlockID"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//remove npc 3
 //		process = [self getProcess:Task_Action_removeNpc];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:3] forKey:@"npcId"];
 //		[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//talk 1
 //		process = [self getProcess:Task_Action_talk];
 //		[processList addObject:process];
 //		
 //		//show unlock BT_HAMMER_TAG
 //		process = [self getProcess:Task_Action_unlock];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:BT_ZAZEN_TAG] forKey:@"unlockID"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//======================================================================
 //		
 //		//move to npc 1
 //		process = [self getProcess:Task_Action_moveToNPC];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 //		[data setObject:[NSNumber numberWithInt:1] forKey:@"npcId"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//talk 1
 //		process = [self getProcess:Task_Action_talk];
 //		[processList addObject:process];
 //		
 //		//move to npc 2
 //		process = [self getProcess:Task_Action_moveToNPC];
 //		data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
 //		[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
 //		[data setObject:[NSNumber numberWithInt:2] forKey:@"npcId"];
 //		[process setObject:data forKey:@"data"];
 //		[processList addObject:process];
 //		
 //		//talk 2
 //		process = [self getProcess:Task_Action_talk];
 //		[processList addObject:process];
 
 NSMutableDictionary * stepData = [NSMutableDictionary dictionary];
 [stepData setObject:[NSNumber numberWithInt:[processList count]] forKey:@"count"];
 [stepData setObject:processList forKey:@"step"];
 
 // turn data to json string
 NSData * jsonData = [[CJSONSerializer serializer] serializeObject:stepData error:nil];
 NSString * step = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
 
 step = @"{\"count\":3,\"step\":[{\"action\":\"3\",\"data\":{\"mapId\":\"1\",\"npcId\":\"1\"}},{\"action\":\"9\",\"data\":{\"sid\":\"1\",\"process\":[{\"index\":\"0\",\"before\":[{\"action\":\"1\",\"data\":[{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"1111\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"2222\"},{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"11111\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"22222\"}]}]}]}},{\"action\":\"1\",\"data\":[{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"1\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"2\"},{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"3\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"4\"},{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"5\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"6\"}]}]}";
 
 [info setObject:step forKey:@"step"];//非常复杂
 
 }
 if(type==2){
 
 [info setObject:[NSString stringWithFormat:@"task:%d",(tid-100)] forKey:@"unlock"];
 
 [info setObject:[NSNumber numberWithInt:(tid+1)] forKey:@"nextId"];
 //TODO add task step data
 NSString * step = @"";
 [info setObject:step forKey:@"step"];//非常复杂
 
 }
 if(type==3){
 
 //TODO add task step data
 NSString * step = @"";
 [info setObject:step forKey:@"step"];//非常复杂
 
 }
 if(type==3){
 
 [info setObject:@"task:100000|level:20" forKey:@"unlock"];
 
 //TODO add task step data
 NSString * step = @"";
 [info setObject:step forKey:@"step"];//非常复杂
 
 }
 
 return info;
 }
 */

/*
 -(NSMutableDictionary*)getProcess:(int)action{
 NSMutableDictionary * process = [NSMutableDictionary dictionary];
 [process setObject:[NSNumber numberWithInt:action] forKey:@"action"];
 
 if(action==Task_Action_talk){
 NSMutableArray * data = [NSMutableArray array];
 [data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck1",@"msg",@"1",@"rid",@"1",@"dir",nil]];
 [data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck2",@"msg",@"2",@"rid",@"2",@"dir",nil]];
 [data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck3",@"msg",@"1",@"rid",@"1",@"dir",nil]];
 [data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck4",@"msg",@"2",@"rid",@"2",@"dir",nil]];
 [data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck5",@"msg",@"1",@"rid",@"1",@"dir",nil]];
 [data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck6",@"msg",@"2",@"rid",@"2",@"dir",nil]];
 [process setObject:data forKey:@"data"];
 }
 if(action==Task_Action_move){
 NSMutableDictionary * data = [NSMutableDictionary dictionary];
 [data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
 [data setObject:NSStringFromCGPoint(ccp(50,60)) forKey:@"point"];
 
 [process setObject:data forKey:@"data"];
 }
 if(action==Task_Action_moveToNPC){
 NSMutableDictionary * data = [NSMutableDictionary dictionary];
 [data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
 [data setObject:[NSNumber numberWithInt:0] forKey:@"npcId"];
 
 [process setObject:data forKey:@"data"];
 }
 
 ////////////////////////////////////////////////////////////////////////////
 
 if(action==Task_Action_addNpc){
 NSMutableDictionary * data = [NSMutableDictionary dictionary];
 
 [data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
 [data setObject:[NSNumber numberWithInt:0] forKey:@"npcId"];
 [data setObject:NSStringFromCGPoint(ccp(50,60)) forKey:@"point"];
 
 [process setObject:data forKey:@"data"];
 }
 if(action==Task_Action_moveNpc){
 NSMutableDictionary * data = [NSMutableDictionary dictionary];
 
 [data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
 [data setObject:[NSNumber numberWithInt:0] forKey:@"npcId"];
 [data setObject:NSStringFromCGPoint(ccp(50,60)) forKey:@"point"];
 
 [process setObject:data forKey:@"data"];
 }
 if(action==Task_Action_removeNpc){
 NSMutableDictionary * data = [NSMutableDictionary dictionary];
 
 [data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
 [data setObject:[NSNumber numberWithInt:0] forKey:@"npcId"];
 
 [process setObject:data forKey:@"data"];
 }
 
 ////////////////////////////////////////////////////////////////////////////
 
 if(action==Task_Action_effects){
 NSMutableDictionary * data = [NSMutableDictionary dictionary];
 [data setObject:[NSNumber numberWithInt:0] forKey:@"eid"];
 [data setObject:@"" forKey:@"other"];
 [process setObject:data forKey:@"data"];
 }
 
 if(action==Task_Action_unlock){
 NSMutableDictionary * data = [NSMutableDictionary dictionary];
 [data setObject:[NSNumber numberWithInt:0] forKey:@"unlockID"];
 [process setObject:data forKey:@"data"];
 }
 
 ////////////////////////////////////////////////////////////////////////////
 
 if(action==Task_Action_stage){
 NSMutableDictionary * data = [NSMutableDictionary dictionary];
 [data setObject:[NSNumber numberWithInt:0] forKey:@"sid"];
 [data setObject:@"" forKey:@"process"];
 [process setObject:data forKey:@"data"];
 }
 
 if(action==Task_Action_fight){
 NSMutableDictionary * data = [NSMutableDictionary dictionary];
 [data setObject:[NSNumber numberWithInt:1] forKey:@"fid"];
 [process setObject:data forKey:@"data"];
 }
 
 return process;
 }
 */

-(void)saveUserStage:(NSString*)stage{
	NSMutableDictionary * player = [NSMutableDictionary dictionaryWithDictionary:[self getPlayerInfo]];
	[player setObject:stage forKey:@"stage"];
	[self addData:player key:@"player"];
	
	//call update user stage
	NSMutableDictionary * data = [NSMutableDictionary dictionary];
	[data setObject:stage forKey:@"stage"];
	[GameConnection request:@"stageUpdate" data:data target:nil call:nil];
	
}

-(void)setUserStage:(int)sid kill:(int)count{
	
	NSMutableArray * result = [NSMutableArray array];
	NSMutableArray * stages = [NSMutableArray arrayWithArray:[self removeUserStage:sid]];
	for(NSString * str in stages){
		NSArray * ary = [str componentsSeparatedByString:@":"];
		int _sid = [[ary objectAtIndex:0] intValue];
		int _len = [[ary objectAtIndex:1] intValue];
		[result addObject:[NSString stringWithFormat:@"%d:%d:%d",_sid,_len,0]];
	}
	
	NSString * userStage = [NSString stringWithFormat:@"%d:%d:%d",sid,count,1];
	[result addObject:userStage];
	[self saveUserStage:[result componentsJoinedByString:@"|"]];
	
}

-(NSString*)getUserStage{
	
	NSDictionary * player = [self getPlayerInfo];
	NSString * userStage = [player objectForKey:@"stage"];
	NSArray * stages = [userStage componentsSeparatedByString:@"|"];
	
	if([stages count]==1){
		return [stages objectAtIndex:0];
	}
	
	if([stages count]>1){
		for(NSString * str in stages){
			NSArray * stage = [str componentsSeparatedByString:@":"];
			if([stage count]>=2){
				if([[stage objectAtIndex:2] intValue]==1){
					return str;
				}
			}
		}
	}
	return nil;
}
-(NSString*)getUserStageByStageId:(int)sid{
	NSDictionary * player = [self getPlayerInfo];
	NSString * userStage = [player objectForKey:@"stage"];
	NSArray * stages = [userStage componentsSeparatedByString:@"|"];
	if([stages count]>0){
		for(NSString * str in stages){
			NSArray * stage = [str componentsSeparatedByString:@":"];
			if([stage count]>1){
				if([[stage objectAtIndex:0] intValue]==sid){
					return str;
				}
			}
		}
	}
	return nil;
}

-(NSArray*)removeUserStage:(int)sid{
	
	NSMutableArray * result = [NSMutableArray array];
	
	NSDictionary * player = [self getPlayerInfo];
	NSString * userStage = [player objectForKey:@"stage"];
	NSArray * stages = [userStage componentsSeparatedByString:@"|"];
	if([stages count]>0){
		for(NSString * str in stages){
			NSArray * stage = [str componentsSeparatedByString:@":"];
			if([stage count]>1){
				int _sid = [[stage objectAtIndex:0] intValue];
				if(_sid>0 && _sid!=sid){
					[result addObject:str];
				}
			}
		}
	}
	
	[self saveUserStage:[result componentsJoinedByString:@"|"]];
	return result;
}

//-(NSDictionary*)getMonsterInfoById:(int)mid{
//	
//	NSMutableDictionary * info = [NSMutableDictionary dictionary];
//	[info setObject:[NSNumber numberWithInt:mid] forKey:@"id"];
//	
//	[info setObject:[NSNumber numberWithInt:MONSTER_TYPE_MONSTER] forKey:@"type"];
//	
//	if(mid==3){
//		[info setObject:[NSNumber numberWithInt:MONSTER_TYPE_BOSS] forKey:@"type"];
//	}
//	
//	[info setObject:@"monster" forKey:@"name"];
//	[info setObject:@"monster info" forKey:@"info"];
//	[info setObject:@"monster_1" forKey:@"act"];
//    
//    [info setObject:[NSNumber numberWithInt:2] forKey:@"sex"];
//	
//	//TODO skill ???
//	[info setObject:[NSNumber numberWithInt:1] forKey:@"sk1"];
//	[info setObject:[NSNumber numberWithInt:2] forKey:@"sk2"];
//	
//	return info;
//}

//-(NSDictionary*)getSkillInfoById:(int)sid{
//	
//	NSMutableDictionary * info = [NSMutableDictionary dictionary];
//	[info setObject:[NSNumber numberWithInt:sid] forKey:@"id"];
//	
//	[info setObject:@"skill" forKey:@"name"];
//	[info setObject:@"skill" forKey:@"info"];
//	[info setObject:@"skill" forKey:@"act"];
//	
//	[info setObject:[NSNumber numberWithInt:Attack_mode_target_single] forKey:@"range"];
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"rHurt1"];
//	[info setObject:[NSNumber numberWithInt:80] forKey:@"rHurt2"];
//	[info setObject:[NSNumber numberWithInt:0] forKey:@"far"];
//	
//	if(sid==1){
//		[info setObject:[NSNumber numberWithInt:Attack_mode_target_single] forKey:@"range"];
//	}
//	if(sid==2){
//		[info setObject:[NSNumber numberWithInt:Attack_mode_target_upright] forKey:@"range"];
//	}
//	
//	if(sid==3){
//		[info setObject:[NSNumber numberWithInt:Attack_mode_target_single] forKey:@"range"];
//	}
//	if(sid==4){
//		[info setObject:[NSNumber numberWithInt:Attack_mode_target_upright] forKey:@"range"];
//	}
//	
//	return info;
//	
//}
//-(NSArray*)getSkillStautsIds:(int)sid{
//	
//	//TODO load sk_state
//	NSMutableArray * result = [NSMutableArray array];
//	
//	NSMutableDictionary * skillStatus = nil;
//	
//	skillStatus = [NSMutableDictionary dictionary];
//	[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//	[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"skid"];
//	[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"stid"];
//	
//	[result addObject:skillStatus];
//	
//	skillStatus = [NSMutableDictionary dictionary];
//	[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//	[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"skid"];
//	[skillStatus setObject:[NSNumber numberWithInt:2] forKey:@"stid"];
//	
//	[result addObject:skillStatus];
//	
//	return result;
//}

//-(NSDictionary*)getStatusInfoById:(int)sid{
//	
//	//TODO test data
//	
//	NSMutableDictionary * info = [NSMutableDictionary dictionary];
//	[info setObject:[NSNumber numberWithInt:sid] forKey:@"id"];
//	[info setObject:@"fight" forKey:@"name"];
//	[info setObject:@"" forKey:@"info"];
//	
//	//1:普通加成 2:中毒 3:队友或自己HP 4:直加HP(盾牌作用)
//	[info setObject:[NSNumber numberWithInt:Fight_Status_Type_general] forKey:@"type"];
//	
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"rate"];
//	
//	//1=敌方目标; 2=自己; 3自己全体;  (4-5要搜索sort与num)
//	[info setObject:[NSNumber numberWithInt:2] forKey:@"target"];
//	
//	//target==3时起作用
//	[info setObject:[NSNumber numberWithInt:3] forKey:@"num"];
//	
//	//1:攻击时 2:受伤时 3:回合结束时
//	[info setObject:[NSNumber numberWithInt:Fight_Action_Type_attack] forKey:@"action"];
//	//作用的次数
//	[info setObject:[NSNumber numberWithInt:2] forKey:@"count"];
//	
//	//--------------------------------------------------------------------------
//	
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"ahp"];
//	[info setObject:[NSNumber numberWithInt:80] forKey:@"bhp"];
//	
//	[info setObject:[NSNumber numberWithBool:NO] forKey:@"noatk"];
//	[info setObject:[NSNumber numberWithBool:NO] forKey:@"nomis"];
//	[info setObject:[NSNumber numberWithBool:NO] forKey:@"nobok"];
//	[info setObject:[NSNumber numberWithBool:NO] forKey:@"nocot"];
//	
//	/*
//	//数值加成 -> HIT:100|CRI:100
//	[info setObject:@"HIT:100|CRI:100" forKey:@"value_r"];
//	//数值成分比加成 -> HIT:100|CRI:100
//	[info setObject:@"HIT:50|CRI:30|DEX:100" forKey:@"value_p"];
//	*/
//	
//	[info setObject:@"HIT_P:50|CRI_P:30|DEX_P:100|HIT:100|CRI:100" forKey:@"value"];
//	
//	//添加实数
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"mp"];
//	[info setObject:[NSNumber numberWithInt:1000] forKey:@"hp"];
//	
//	//添加百分比
//	[info setObject:[NSNumber numberWithInt:50] forKey:@"mp_p"];
//	[info setObject:[NSNumber numberWithInt:50] forKey:@"hp_p"];
//	
//	return info;
//}


//-(NSDictionary*)getFightInfoById:(int)fid{
//	
//	//TODO test data
//	
//	NSMutableDictionary * info = [NSMutableDictionary dictionary];
//	[info setObject:[NSNumber numberWithInt:fid] forKey:@"id"];
//	[info setObject:@"fight" forKey:@"name"];
//	[info setObject:@"fbg1" forKey:@"BG"];
//	
//	//TODO 怪物站位与数据->1:1 (怪物ID:怪物Level)
//	[info setObject:@"1:0" forKey:@"s1"];
//	[info setObject:@"1:1" forKey:@"s2"];
//	[info setObject:@"1:0" forKey:@"s3"];
//	
//	[info setObject:@"0:0" forKey:@""];
//	[info setObject:@"0:0" forKey:@"s5"];
//	[info setObject:@"0:0" forKey:@"s6"];
//	
//	[info setObject:@"0:0" forKey:@"s7"];
//	[info setObject:@"0:0" forKey:@"s8"];
//	[info setObject:@"0:0" forKey:@"s9"];
//	
//	[info setObject:@"0:0" forKey:@"s10"];
//	[info setObject:@"0:0" forKey:@"s11"];
//	[info setObject:@"0:0" forKey:@"s12"];
//	
//	[info setObject:@"0:0" forKey:@"s13"];
//	[info setObject:@"0:0" forKey:@"s14"];
//	[info setObject:@"0:0" forKey:@"s15"];
//	
//	return info;
//}

//-(NSDictionary*)getMonster:(int)mid level:(int)level{
//	
//	//TODO test data
//	
//	NSMutableDictionary * info = [NSMutableDictionary dictionary];
//	[info setObject:[NSNumber numberWithInt:mid] forKey:@"id"];
//	[info setObject:[NSNumber numberWithInt:mid] forKey:@"mid"];
//	[info setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//	
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"DEX"];
//	
//	[info setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"MP"];
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"ATK"];
//	[info setObject:[NSNumber numberWithInt:100] forKey:@"STK"];
//	
//	[info setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
//	[info setObject:[NSNumber numberWithInt:10] forKey:@"SPD"];
//	
//	[info setObject:[NSNumber numberWithInt:50] forKey:@"MPS"];
//	[info setObject:[NSNumber numberWithInt:10] forKey:@"MPT"];    // @"MPR" ?
//	
//	[info setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
//	[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
//	[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
//	[info setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
//	[info setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
//	[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
//	[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
//	[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
//	[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
//	
//	return info;
//	
//}

-(NSArray*)getUserChoosePositionMember{
	NSMutableArray* array = [NSMutableArray array];
	NSDictionary* position = [self getUserChoosePosition];
	for(int i=0;i<15;i++){
		NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
		int rid = [[position objectForKey:key] intValue];
		if (rid > 0) {
			NSString* _kid = [NSString stringWithFormat:@"%d",rid];
			[array addObject:_kid];
		}
	}
	return array;
}

-(NSDictionary*)getUserChoosePosition{
	
	NSDictionary * player = [self getPlayerInfo];
	int upid = [[player objectForKey:@"posId"] intValue];
	
	
	NSMutableDictionary * currentPos = nil;
	
	NSArray * position = [NSArray arrayWithArray:[self getDataBykey:@"position"]];
	for(NSDictionary * pos in position){
		if([[pos objectForKey:@"id"] intValue]==upid){
			currentPos = [NSMutableDictionary dictionaryWithDictionary:pos];
			break;
		}
	}
	
	if(currentPos){
		BOOL isEmpty = YES;
		for(int i=1;i<=15;i++){
			if([[currentPos objectForKey:[NSString stringWithFormat:@"s%d",i]] intValue]>0){
				isEmpty = NO;
			}
		}
		
		if(isEmpty){
			int pid = [[currentPos objectForKey:@"posId"] intValue];
			NSDictionary * info = [[GameDB shared] getPositionInfo:pid];
			if(info){
				int eye = [[info objectForKey:@"eye"] intValue];
				[currentPos setObject:[player objectForKey:@"rid"] forKey:[NSString stringWithFormat:@"s%d",eye]];
			}
		}
		
	}
	
	return currentPos;
}

//-(NSDictionary*)getPosition:(int)posId level:(int)posLevel{
//	
//	NSMutableDictionary * levelInfo = [NSMutableDictionary dictionary];
//	[levelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//	
//	[levelInfo setObject:[NSNumber numberWithInt:posId] forKey:@"posId"];   // @"pid" ?
//	[levelInfo setObject:[NSNumber numberWithInt:posLevel] forKey:@"level"];
//	
//	[levelInfo setObject:[NSNumber numberWithInt:10] forKey:@"unlock"];
//	[levelInfo setObject:[NSNumber numberWithInt:100] forKey:@"coin1"];
//	
//	//阵型增加 ：(特别)自身50%机率回复自身伤害值的10% ADD_HURT_HP_P:10:50
//	[levelInfo setObject:@"ATK:1|DEF:1|ADD_HURT_HP_P:10:50" forKey:@"s1"];
//	[levelInfo setObject:@"ATK:1|DEF:1" forKey:@"s2"];
//	[levelInfo setObject:@"ATK:1|DEF:1" forKey:@"s3"];
//	[levelInfo setObject:@"" forKey:@"s4"];
//	[levelInfo setObject:@"CENTER_SPD_P:25" forKey:@"s5"];
//	[levelInfo setObject:@"" forKey:@"s6"];
//	[levelInfo setObject:@"" forKey:@"s7"];
//	[levelInfo setObject:@"" forKey:@"s8"];
//	[levelInfo setObject:@"" forKey:@"s9"];
//	[levelInfo setObject:@"" forKey:@"s10"];
//	[levelInfo setObject:@"" forKey:@"s11"];
//	[levelInfo setObject:@"" forKey:@"s12"];
//	[levelInfo setObject:@"" forKey:@"s13"];
//	[levelInfo setObject:@"" forKey:@"s14"];
//	[levelInfo setObject:@"" forKey:@"s15"];
//	
//	return levelInfo;
//}

-(NSDictionary*)getUserRoleById:(int)rid{
	
	if (rid == 0) {
		CCLOG(@"rid == 0");
		return nil;
	}
	return [self getPlayerRoleFromListById:rid];
	//	//从角色列表返回一个ID匹配的角色
	//	//TODO test data
	//	if (rid == 0) {
	//		
	//		NSMutableDictionary * userRole = [NSMutableDictionary dictionary];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"id"];
	//		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"pid"];
	//		[userRole setObject:[NSNumber numberWithInt:rid] forKey:@"rid"];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:RoleStatus_in] forKey:@"status"];
	//		
	//		//add soul
	//		[userRole setObject:[NSNumber numberWithInt:2] forKey:@"armLevel"];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:0] forKey:@"sk"];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:0] forKey:@"eq1"];
	//		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"eq2"];
	//		[userRole setObject:[NSNumber numberWithInt:2] forKey:@"eq3"];
	//		[userRole setObject:[NSNumber numberWithInt:3] forKey:@"eq4"];
	//		[userRole setObject:[NSNumber numberWithInt:4] forKey:@"eq5"];
	//		[userRole setObject:[NSNumber numberWithInt:5] forKey:@"eq6"];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:0] forKey:@"fate1"];
	//		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"fate2"];
	//		[userRole setObject:[NSNumber numberWithInt:2] forKey:@"fate3"];
	//		[userRole setObject:[NSNumber numberWithInt:3] forKey:@"fate4"];
	//		[userRole setObject:[NSNumber numberWithInt:4] forKey:@"fate5"];
	//		[userRole setObject:[NSNumber numberWithInt:5] forKey:@"fate6"];
	//		return userRole;
	//	}else{
	//		NSMutableDictionary * userRole = [NSMutableDictionary dictionary];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"id"];
	//		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"pid"];
	//		[userRole setObject:[NSNumber numberWithInt:rid] forKey:@"rid"];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:RoleStatus_in] forKey:@"status"];
	//		
	//		//add soul
	//		[userRole setObject:[NSNumber numberWithInt:2] forKey:@"armLevel"];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:0] forKey:@"sk"];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:0] forKey:@"eq1"];
	//		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"eq2"];
	//		[userRole setObject:[NSNumber numberWithInt:2] forKey:@"eq3"];
	//		[userRole setObject:[NSNumber numberWithInt:3] forKey:@"eq4"];
	//		[userRole setObject:[NSNumber numberWithInt:4] forKey:@"eq5"];
	//		[userRole setObject:[NSNumber numberWithInt:5] forKey:@"eq6"];
	//		
	//		[userRole setObject:[NSNumber numberWithInt:0] forKey:@"fate1"];
	//		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"fate2"];
	//		[userRole setObject:[NSNumber numberWithInt:2] forKey:@"fate3"];
	//		[userRole setObject:[NSNumber numberWithInt:3] forKey:@"fate4"];
	//		[userRole setObject:[NSNumber numberWithInt:4] forKey:@"fate5"];
	//		[userRole setObject:[NSNumber numberWithInt:5] forKey:@"fate6"];
	//		return userRole;
	//	}
	
}

//-(NSDictionary*)getRoleInfoById:(int)rid{
//	
//	//TODO test data
//	
//	NSMutableDictionary * userRole = [NSMutableDictionary dictionary];
//	
//	[userRole setObject:[NSNumber numberWithInt:rid] forKey:@"id"];
//	
//	[userRole setObject:@"name" forKey:@"name"];
//	[userRole setObject:@"info" forKey:@"info"];
//	[userRole setObject:@"动画一" forKey:@"act"];
//	
//	[userRole setObject:@"职业一" forKey:@"job"];
//	[userRole setObject:@"位阶一" forKey:@"office"]; //位阶
//	
//	[userRole setObject:[NSNumber numberWithInt:1] forKey:@"sex"];
//	[userRole setObject:[NSNumber numberWithInt:rid] forKey:@"armId"];
//    
//	[userRole setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
//	
//	[userRole setObject:[NSNumber numberWithInt:3] forKey:@"sk1"];//普通攻击
//	[userRole setObject:[NSNumber numberWithInt:4] forKey:@"sk2"];//绝杀攻击
//    
//    [userRole setObject:[NSNumber numberWithInt:rid] forKey:@"index"];
//    [userRole setObject:[NSNumber numberWithInt:1] forKey:@"disLV"];
//    [userRole setObject:[NSNumber numberWithInt:1] forKey:@"invLV"];
//    [userRole setObject:@"" forKey:@"invs"];
//    [userRole setObject:[NSNumber numberWithInt:1] forKey:@"useId"];
//    [userRole setObject:[NSNumber numberWithInt:5] forKey:@"useNum"];
//    
//    // test
//    if (rid == 7) {
//        [userRole setObject:[NSNumber numberWithInt:7] forKey:@"index"];
//        [userRole setObject:@"tid:1|rid:4|rid:5|max:10|vip:5" forKey:@"invs"];
//    }
//    else if (rid == 9) {
//        [userRole setObject:[NSNumber numberWithInt:30] forKey:@"invLV"];
//    }
//    else if (rid == 14) {
//        [userRole setObject:@"tid:1|rid:4|max:30|vip:20" forKey:@"invs"];
//    }
//	
//	return userRole;
//	
//}


//按角色id读取当前角色武器等级数据
-(NSDictionary*)getUserArmInfoByRoleId:(int)rid{
	
	NSDictionary * playerRole = [self getPlayerRoleFromListById:rid];
	NSDictionary * roleArmInfo  =[[GameDB shared] getRoleInfo:rid];
	int armId = [[roleArmInfo objectForKey:@"armId"] intValue];
	int level = [[playerRole objectForKey:@"armLevel"] intValue];
	
	NSDictionary * result = [[GameDB shared] getArmLevelInfo:armId level:level];
	return result;
}

//==============================================================================
//==============================================================================

//
//#pragma mark -
//#pragma mark - 基础数据表(补全上面)

//-(NSDictionary *)getRoleLevel:(int)rid level:(int)level
//{
//    //TODO test data
//	
//	NSMutableDictionary *roleLevelInfo = [NSMutableDictionary dictionary];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:rid] forKey:@"rid"];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//	
//	[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
//    [roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"DEX"];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
//	
//	[roleLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MP"];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"ATK"];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"STK"];
//	
//	[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"DEF"];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:50] forKey:@"SPD"];
//	
//	[roleLevelInfo setObject:[NSNumber numberWithInt:50] forKey:@"MPS"];
//	[roleLevelInfo setObject:[NSNumber numberWithInt:10] forKey:@"MPR"];
//	
//	[roleLevelInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
//	[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
//	[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
//	[roleLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
//	[roleLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
//	[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
//	[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
//	[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
//	[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
//	
//	return roleLevelInfo;
//}

//-(NSDictionary *)getRoleExpByLevel:(int)level
//{
//    //TODO test data
//	
//	NSMutableDictionary *roleExpInfo = [NSMutableDictionary dictionary];
//	[roleExpInfo setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//	[roleExpInfo setObject:[NSNumber numberWithInt:level*10000] forKey:@"exp"];
//    [roleExpInfo setObject:[NSNumber numberWithInt:1] forKey:@"siteExp"];
//    
//    return roleExpInfo;
//}

//-(NSDictionary *)getArmById:(int)aid
//{
//    //TODO test data
//	
////	NSArray *record = [self getDataByTableName:@"arm"];
////	if (record && record.count > 0) {
////		for (NSDictionary *dict in record) {
////			int _id = [[dict objectForKey:@"id"] intValue];
////			if (_id == aid) {
////				return dict;
////			}
////		}
////	}
////	CCLOG(@"can't find record in data,please use test data");
//	
//	NSMutableDictionary *armInfo = [NSMutableDictionary dictionary];
//	[armInfo setObject:[NSNumber numberWithInt:aid] forKey:@"id"];
//    [armInfo setObject:@"name" forKey:@"name"];
//    [armInfo setObject:@"info" forKey:@"info"];
//    [armInfo setObject:@"act" forKey:@"act"];
//	//test
//    [armInfo setObject:[NSNumber numberWithInt:aid*2+1] forKey:@"sk1"];
//	[armInfo setObject:[NSNumber numberWithInt:aid*2+2] forKey:@"sk2"];
//    
//    return armInfo;
//}

//-(NSDictionary *)getSkillById:(int)sid
//{
//    //TODO test data
//    
//    NSMutableDictionary *skillInfo = [NSMutableDictionary dictionary];
//    [skillInfo setObject:[NSNumber numberWithInt:sid] forKey:@"id"];
//    [skillInfo setObject:@"name" forKey:@"name"];
//    [skillInfo setObject:@"info" forKey:@"info"];
//    [skillInfo setObject:@"act" forKey:@"act"];
//    [skillInfo setObject:[NSNumber numberWithInt:1] forKey:@"range"];
//    [skillInfo setObject:[NSNumber numberWithInt:1] forKey:@"far"];
//    
//    return skillInfo;
//}


//-(NSDictionary *)getStateById:(int)sid
//{
//    //TODO test data
//    
//    NSMutableDictionary *stateInfo = [NSMutableDictionary dictionary];
//    [stateInfo setObject:[NSNumber numberWithInt:sid] forKey:@"id"];
//    [stateInfo setObject:@"name" forKey:@"name"];
//    [stateInfo setObject:@"act" forKey:@"act"];
//    [stateInfo setObject:[NSNumber numberWithInt:10] forKey:@"rate"];
//    [stateInfo setObject:[NSNumber numberWithInt:1] forKey:@"num"];
//    [stateInfo setObject:[NSNumber numberWithInt:1] forKey:@"round"];
//    [stateInfo setObject:[NSNumber numberWithInt:1] forKey:@"target"];
//    [stateInfo setObject:@"数值效果" forKey:@"values"];
//    [stateInfo setObject:@"比例效果" forKey:@"pers"];
//    [stateInfo setObject:[NSNumber numberWithInt:0] forKey:@"nomis"];
//    [stateInfo setObject:[NSNumber numberWithInt:0] forKey:@"nobok"];
//    [stateInfo setObject:[NSNumber numberWithInt:0] forKey:@"nocot"];
//    [stateInfo setObject:[NSNumber numberWithInt:1] forKey:@"hp"];
//    [stateInfo setObject:[NSNumber numberWithInt:1] forKey:@"sort"];
//    
//    return stateInfo;
//}

//-(NSArray *)getSkillStateListBySkillId:(int)sid
//{
//    //TODO test data
//    
//    NSMutableArray *skillStateList = [NSMutableArray array];
//    
//    NSMutableDictionary *skillStateInfo1 = [NSMutableDictionary dictionary];
//    [skillStateInfo1 setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//    [skillStateInfo1 setObject:[NSNumber numberWithInt:sid] forKey:@"skid"];
//    [skillStateInfo1 setObject:[NSNumber numberWithInt:1] forKey:@"stid"];
//    
//    NSMutableDictionary *skillStateInfo2 = [NSMutableDictionary dictionary];
//    [skillStateInfo2 setObject:[NSNumber numberWithInt:2] forKey:@"id"];
//    [skillStateInfo2 setObject:[NSNumber numberWithInt:sid] forKey:@"skid"];
//    [skillStateInfo2 setObject:[NSNumber numberWithInt:2] forKey:@"stid"];
//    
//    [skillStateList addObject:skillStateInfo1];
//    [skillStateList addObject:skillStateInfo2];
//    
//    return skillStateList;
//}

//-(NSDictionary *)getArmLevel:(int)aid level:(int)level
//{
//    //TODO test data
//    
////	NSArray *record = [self getDataByTableName:@"arm_level"];
////	if (record && record.count > 0) {
////		for (NSDictionary *dict in record) {
////			int _id = [[dict objectForKey:@"aid"] intValue];
////			int _level = [[dict objectForKey:@"level"] intValue];
////			if (_id == aid && _level == level) {
////				return dict;
////			}
////		}
////	}
////	CCLOG(@"can't find record in data,please use test data");
//	
//    NSMutableDictionary *armInfo = [NSMutableDictionary dictionary];
//	[armInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//	[armInfo setObject:[NSNumber numberWithInt:aid] forKey:@"aid"];
//	[armInfo setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//	
//	[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
//    [armInfo setObject:[NSNumber numberWithInt:30] forKey:@"DEX"];
//	[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
//	[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
//	
//	[armInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
//	[armInfo setObject:[NSNumber numberWithInt:1000] forKey:@"MP"];
//	[armInfo setObject:[NSNumber numberWithInt:60] forKey:@"ATK"];
//	[armInfo setObject:[NSNumber numberWithInt:60] forKey:@"STK"];
//	
//	[armInfo setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
//	[armInfo setObject:[NSNumber numberWithInt:5] forKey:@"SPD"];
//	
//	[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPS"];
//	[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPR"];
//	
//	[armInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
//	[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
//	[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
//	[armInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
//	[armInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
//	[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
//	[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
//	[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
//	[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
//    
//    return armInfo;
//}

//-(NSDictionary *)getArmExpByLevel:(int)level
//{
//    //TODO test data
////	NSArray *record = [self getDataByTableName:@"arm_exp"];
////	if (record && record.count > 0) {
////		for (NSDictionary *dict in record) {
////			int _level = [[dict objectForKey:@"level"] intValue];
////			if (_level == level) {
////				return dict;
////			}
////		}
////	}
////	CCLOG(@"can't find record in data,please use test data");
//	
//    NSMutableDictionary *armExpInfo = [NSMutableDictionary dictionary];
//    [armExpInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//    [armExpInfo setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//    [armExpInfo setObject:[NSNumber numberWithInt:1] forKey:@"exp"];
//    
//    return armExpInfo;
//}

//-(NSDictionary *)getEquipById:(int)eid
//{
//    //TODO test data
////	NSArray *record = [self getDataByTableName:@"equip"];
////	if (record && record.count > 0) {
////		//来，二分查找
////		//----
////		int start = 0 ;
////		int end = record.count-1;
////		int mid = 0 ;
////		while (start <= end) {
////			mid = start + (end - start)/2;
////			NSDictionary *dict = [record objectAtIndex:mid];
////			int _value = [[dict objectForKey:@"id"] intValue];
////			if (eid == _value) {
////				return dict;
////			}
////			//转移区间
////			if (_value > eid) {
////				end = mid -1;
////			}
////			else {
////				start = mid + 1;
////			}
////		}
////	}
//	CCLOG(@"can't find record in data,please use test data");
//	
//    NSMutableDictionary *equipInfo = [NSMutableDictionary dictionary];
//    [equipInfo setObject:[NSNumber numberWithInt:eid] forKey:@"id"];
//    [equipInfo setObject:@"name" forKey:@"name"];
//    [equipInfo setObject:@"info" forKey:@"info"];
//    [equipInfo setObject:@"act" forKey:@"act"];
//    [equipInfo setObject:[NSNumber numberWithInt:eid] forKey:@"sid"];
//	int part = eid%6;
//	part += 1;
//    [equipInfo setObject:[NSNumber numberWithInt:part] forKey:@"part"];
//    [equipInfo setObject:[NSNumber numberWithInt:1] forKey:@"limit"];
//    [equipInfo setObject:[NSNumber numberWithInt:1] forKey:@"price"];
//	
//	//add
//	[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
//    [equipInfo setObject:[NSNumber numberWithInt:30] forKey:@"DEX"];
//	[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
//	[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
//	
//	[equipInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
//	[equipInfo setObject:[NSNumber numberWithInt:1000] forKey:@"MP"];
//	[equipInfo setObject:[NSNumber numberWithInt:60] forKey:@"ATK"];
//	[equipInfo setObject:[NSNumber numberWithInt:60] forKey:@"STK"];
//	
//	[equipInfo setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
//	[equipInfo setObject:[NSNumber numberWithInt:5] forKey:@"SPD"];
//	
//	[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPS"];
//	[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPR"];
//	
//	[equipInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
//	[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
//	[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
//	[equipInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
//	[equipInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
//	[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
//	[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
//	[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
//	[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
//    
//    return equipInfo;
//}

//-(NSDictionary *)getEquipLevel:(int)eid level:(int)level
//{
//    //TODO test data
////	NSArray *record = [self getDataByTableName:@"eq_level"];
////	if (record && record.count > 0) {
////		for (NSDictionary *dict in record) {
////			int _id = [[dict objectForKey:@"eid"] intValue];
////			int _level = [[dict objectForKey:@"level"] intValue];
////			if (_id == eid && _level == level) {
////				return dict;
////			}
////		}
////	}
////	CCLOG(@"can't find record in data,please use test data");
//	
//    NSMutableDictionary *equipLevelInfo = [NSMutableDictionary dictionary];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:eid] forKey:@"eid"];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//	
//	[equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
//    [equipLevelInfo setObject:[NSNumber numberWithInt:30] forKey:@"DEX"];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
//	
//	[equipLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"MP"];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:60] forKey:@"ATK"];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:60] forKey:@"STK"];
//	
//	[equipLevelInfo setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:5] forKey:@"SPD"];
//	
//	[equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPS"];
//	[equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPR"];
//	
//	[equipLevelInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
//	[equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
//	[equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
//	[equipLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
//	[equipLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
//	[equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
//	[equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
//	[equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
//	[equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
//    
//    return equipLevelInfo;
//}

//-(NSDictionary *)getEquipSetById:(int)eid
//{
//    //TODO test data
//    
////	NSArray *record = [self getDataByTableName:@"eq_set"];
////	if (record && record.count > 0) {
////		for (NSDictionary *dict in record) {
////			int _id = [[dict objectForKey:@"id"] intValue];
////			if (_id == eid) {
////				return dict;
////			}
////		}
////	}
////	CCLOG(@"can't find record in data,please use test data");
//	
//	
//    NSMutableDictionary *equipSetInfo = [NSMutableDictionary dictionary];
//    [equipSetInfo setObject:[NSNumber numberWithInt:eid] forKey:@"id"];
//    [equipSetInfo setObject:@"name" forKey:@"name"];
//    [equipSetInfo setObject:@"info" forKey:@"info"];
//    [equipSetInfo setObject:@"effect2" forKey:@"effect2"];
//    [equipSetInfo setObject:@"effect4" forKey:@"effect4"];
//    [equipSetInfo setObject:@"effect6" forKey:@"effect6"];
//	
//    [equipSetInfo setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
//	[equipSetInfo setObject:[NSNumber numberWithInt:eid*2] forKey:@"lv"];//装备本身等级
//    return equipSetInfo;
//}

//-(NSDictionary *)getStrEquipByLevel:(int)level
//{
//    //TODO test data
//    
//    NSMutableDictionary *strEquipInfo = [NSMutableDictionary dictionary];
//    [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//    [strEquipInfo setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//    [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"useId"];
//    [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"count"];
//    [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"mvCoin1"];
////    [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"coin2"];
////    [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"coin3"];
//    
//    return strEquipInfo;
//}

//-(NSDictionary *)getStrMoveByLevel:(int)level
//{
//    //TODO test data
//    
//    NSMutableDictionary *strMoveInfo = [NSMutableDictionary dictionary];
//    [strMoveInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//    [strMoveInfo setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//    [strMoveInfo setObject:[NSNumber numberWithInt:1] forKey:@"coin1"];
//    [strMoveInfo setObject:[NSNumber numberWithInt:1] forKey:@"coin2"];
//    [strMoveInfo setObject:[NSNumber numberWithInt:1] forKey:@"coin3"];
//    
//    return strMoveInfo;
//}

//-(NSDictionary *)getFateById:(int)fid
//{
//    //TODO test data
//    
//    NSMutableDictionary *fateInfo = [NSMutableDictionary dictionary];
//    [fateInfo setObject:[NSNumber numberWithInt:fid] forKey:@"id"];
//    [fateInfo setObject:@"name" forKey:@"name"];
//    [fateInfo setObject:@"info" forKey:@"info"];
//    [fateInfo setObject:@"act" forKey:@"act"];
//    [fateInfo setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
//    [fateInfo setObject:[NSNumber numberWithInt:0] forKey:@"beginExp"];
//    [fateInfo setObject:[NSNumber numberWithFloat:50.0f] forKey:@"rate"];
//    [fateInfo setObject:[NSNumber numberWithInt:1] forKey:@"price"];
//    
//    return fateInfo;
//}

//-(NSDictionary *)getFateLevel:(int)fid level:(int)level
//{
//    //TODO test data
//    
//    NSMutableDictionary *fateLevelInfo = [NSMutableDictionary dictionary];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:fid] forKey:@"fid"];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//    [fateLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"exp"];
//	
//	[fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
//    [fateLevelInfo setObject:[NSNumber numberWithInt:30] forKey:@"DEX"];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
//	
//	[fateLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"MP"];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:60] forKey:@"ATK"];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:60] forKey:@"STK"];
//	
//	[fateLevelInfo setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:5] forKey:@"SPD"];
//	
//	[fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPS"];
//	[fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPR"];
//	
//	[fateLevelInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
//	[fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
//	[fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
//	[fateLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
//	[fateLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
//	[fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
//	[fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
//	[fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
//	[fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
//    
//    return fateLevelInfo;
//}

//-(NSDictionary *)getFateRateById:(int)fid
//{
//    //TODO test data
//    
//    NSMutableDictionary *fateRateInfo = [NSMutableDictionary dictionary];
//    [fateRateInfo setObject:[NSNumber numberWithInt:fid] forKey:@"id"];
//    [fateRateInfo setObject:@"1" forKey:@"type"];
//    [fateRateInfo setObject:@"1" forKey:@"mid"];
//    [fateRateInfo setObject:[NSNumber numberWithFloat:50.0f] forKey:@"rate"];
//    [fateRateInfo setObject:[NSNumber numberWithInt:1] forKey:@"rid"];
//    
//    return fateRateInfo;
//}

//-(NSDictionary *)getItemById:(int)iid
//{
//    //TODO test data
//    
//    NSMutableDictionary *itemInfo = [NSMutableDictionary dictionary];
//    [itemInfo setObject:[NSNumber numberWithInt:iid] forKey:@"id"];
//    [itemInfo setObject:@"name" forKey:@"name"];
//    [itemInfo setObject:@"info" forKey:@"info"];
//    [itemInfo setObject:@"act" forKey:@"act"];
//    [itemInfo setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
//
//    [itemInfo setObject:[NSNumber numberWithInt:Item_material] forKey:@"type"];
//
//    [itemInfo setObject:[NSNumber numberWithInt:1] forKey:@"price"];
//    [itemInfo setObject:[NSNumber numberWithInt:99] forKey:@"stack"];
//    
//    return itemInfo;
//}

//-(NSDictionary *)getFusionBySrcId:(int)sid
//{
//    //TODO test data
//    
//    NSMutableDictionary *fusionInfo = [NSMutableDictionary dictionary];
//    [fusionInfo setObject:[NSNumber numberWithInt:sid] forKey:@"id"];
//    [fusionInfo setObject:@"name" forKey:@"name"];
//    [fusionInfo setObject:@"info" forKey:@"info"];
//    [fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"desId"];
//    [fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"srcId"];
//    [fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"count"];
//    [fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint1"];
//    [fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint2"];
//    [fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint3"];
//    
//    return fusionInfo;
//}

//-(NSDictionary *)getRewardById:(int)rid
//{
//    //TODO test data
//    
//    NSMutableDictionary *rewardInfo = [NSMutableDictionary dictionary];
//    [rewardInfo setObject:[NSNumber numberWithInt:rid] forKey:@"id"];
//    [rewardInfo setObject:@"name" forKey:@"name"];
//    [rewardInfo setObject:@"info" forKey:@"info"];
//    [rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint1"];
//    [rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint2"];
//    [rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint3"];
//    [rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"exp"];
//    [rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"train"];
//    [rewardInfo setObject:@"item" forKey:@"item"];
//    [rewardInfo setObject:@"equip" forKey:@"equip"];
//    [rewardInfo setObject:@"fate" forKey:@"fate"];
//    [rewardInfo setObject:@"reward" forKey:@"reward"];
//    
//    return rewardInfo;
//}

//-(NSDictionary *)getCarById:(int)cid
//{
//    //TODO test data
//    
//    NSMutableDictionary *carInfo = [NSMutableDictionary dictionary];
//    [carInfo setObject:[NSNumber numberWithInt:cid] forKey:@"id"];
//    [carInfo setObject:@"name" forKey:@"name"];
//    [carInfo setObject:@"info" forKey:@"info"];
//    [carInfo setObject:@"act" forKey:@"act"];
//    [carInfo setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
//    [carInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"speed"];
//    [carInfo setObject:[NSNumber numberWithInt:1] forKey:@"useId"];
//    [carInfo setObject:[NSNumber numberWithInt:1] forKey:@"count"];
//    [carInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint1"];
//    [carInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint2"];
//    [carInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint3"];
//    
//    return carInfo;
//}

//-(NSDictionary *)getGroupLevelByLevel:(int)level
//{
//    //TODO test data
//    
//    NSMutableDictionary *groupLevelInfo = [NSMutableDictionary dictionary];
//    [groupLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
//    [groupLevelInfo setObject:[NSNumber numberWithInt:level] forKey:@"level"];
//    [groupLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"contrib"];
//    
//    return groupLevelInfo;
//}

//-(NSDictionary *)getPositionById:(int)pid
//{
//    //TODO test data
//    
//    NSMutableDictionary *positionInfo = [NSMutableDictionary dictionary];
//    [positionInfo setObject:[NSNumber numberWithInt:pid] forKey:@"id"];
//    [positionInfo setObject:@"name" forKey:@"name"];
//    [positionInfo setObject:@"info" forKey:@"info"];
//    [positionInfo setObject:@"act" forKey:@"act"];
//    [positionInfo setObject:[NSNumber numberWithInt:2] forKey:@"eye"];
//    
//    return positionInfo;
//}

//基础数据 结束===================================================================
//==============================================================================

//*******************************************************
//
//
//*******************************************************
-(NSMutableArray*)getUserMenuList
{
    //TODO test data
    
	NSMutableArray *array = [NSMutableArray array];
	//default
	[array addObject:[NSNumber numberWithInt:BT_SETTING_TAG]];
	[array addObject:[NSNumber numberWithInt:BT_ROLE_TAG]];
	
	if ([self checkPlayerFunction:Unlock_phalanx]) {
		[array addObject:[NSNumber numberWithInt:BT_PHALANX_TAG]];
	}
	if ([self checkPlayerFunction:Unlock_recruit]) {
		[array addObject:[NSNumber numberWithInt:BT_RECRUIT_TAG]];
	}
	if ([self checkPlayerFunction:Unlock_hammer]) {
		[array addObject:[NSNumber numberWithInt:BT_HAMMER_TAG]];
	}
	if ([self checkPlayerFunction:Unlock_weapon]) {
		[array addObject:[NSNumber numberWithInt:BT_WEAPON_TAG]];
	}
	if ([self checkPlayerFunction:Unlock_star]) {
		[array addObject:[NSNumber numberWithInt:BT_GUANXING_TAG]];
	}
	if ([self checkPlayerFunction:Unlock_timebox]) {
		[array addObject:[NSNumber numberWithInt:BT_TIMEBOX_TAG]];
	}
	
	if (YES) {
		[array addObject:[NSNumber numberWithInt:BT_JEWEL_TAG]];
	}
	
	if ([self checkPlayerFunction:Unlock_union]) {
		[array addObject:[NSNumber numberWithInt:BT_UNION_TAG]];
	}
	if ([self checkPlayerFunction:Unlock_zazen]) {
		[array addObject:[NSNumber numberWithInt:BT_ZAZEN_TAG]];
	}
	if ([self checkPlayerFunction:Unlock_arena]) {
		[array addObject:[NSNumber numberWithInt:BT_ARENA_TAG]];
	}
	
	//避免重复添加
	
	NSMutableArray* _result = [NSMutableArray array];
	
	for (NSNumber* _number in array) {
		if (![_result containsObject:_number]) {
			[_result addObject:_number];
		}
	}
	
	return _result;

}
-(BOOL)checkPlayerFunction:(Unlock_object)_id{
	NSDictionary *player = [self getPlayerInfo];
	unsigned int _value = [[player objectForKey:@"funcs"] intValue];
	
	//TODO
	BOOL result = isOpenFunction(_value, _id) ;
	
	if (!result) {
		NSDictionary* setDict = [[GameDB shared] getfuncsInfo:_id];
		if (setDict != nil) {
			int tid = [[setDict objectForKey:@"tid"] intValue];
			result = ([[TaskManager shared] isCompleteTask:tid] && tid != 0);
		}
	}
	
	return result;
}
/*
 *约定_tag的取值范围是[1,10]
 *对应 MainMenu.h  MENU_TAG
 */
-(void)updateUserMenuList:(int)_tag
{
    if (_tag < BT_ZAZEN_TAG || _tag > BT_TRADE_TAG) {
        //updateUserMenuList
        CCLOG(@"updateUserMenuList failed!");
        return ;
    }
    NSMutableArray * userMenuItems = [self getDataBykey:@"userMenu"];
    if (userMenuItems) {
        for ( NSNumber *nbr in userMenuItems) {
            int _temp = [nbr intValue];
            if (_temp == _tag) {
				CCLOG(@"updateUserMenuList failed! _tag haved inited!");
                return ;
            }
        }
        [userMenuItems addObject:[NSNumber numberWithInt:_tag]];
        //to file
        [self addData:userMenuItems key:@"userMenu"];
    }
    else {
        CCLOG(@"updateUserMenuList failed! checked init!");
    }
}

#pragma mark - 
#pragma mark - 玩家数据2
//参战成员
-(NSArray*)getFightTeamMember{
	NSDictionary *pDict = [self getPlayerInfo];
	if (pDict) {
		NSDictionary *posDict=[self getPlayerPhalanxById:[[pDict objectForKey:@"posId"] intValue]];
		if (posDict) {
			NSMutableArray * members = [NSMutableArray array];
			NSNumber *ridNumber=nil;
			NSDictionary *roleDict;
			for (int i=1; i<=15; i++) {
				ridNumber = [posDict objectForKey:[NSString stringWithFormat:@"s%d",i ]];
				if (!ridNumber) {
					CCLOG(@"get fight team member is error");
					return nil;
				}				
				if ([ridNumber intValue]>0) {
					roleDict = [self getPlayerRoleFromListById:[ridNumber intValue]];
					if (roleDict) {
						if ([[roleDict objectForKey:@"status"] intValue]==1) {
							[members addObject:ridNumber];
						}						
					}else{
						CCLOG(@"get fight team member role is error");
					}
				}
			}			
			return members;
		}

	}
	CCLOG(@"get fight team member is error");
	return nil;
}
-(NSArray*)getTeamMember
{
	int _prid = [self getPlayerRole];
	NSArray *array = [self getPlayerRoleList];
	NSMutableArray * members = [NSMutableArray array];
	for (NSDictionary *_dict in array) {
		int _rid = [ [_dict objectForKey:@"rid"] intValue];//获得值
		int _in = [[_dict objectForKey:@"status"] intValue];
		if (_in == RoleStatus_in) {//在队伍
			if (_prid == _rid) {//和主角色角色ID相等。丢在数组的最签名
				[members insertObject:[_dict objectForKey:@"rid"] atIndex:0];
			}
			else {
				[members addObject:[_dict objectForKey:@"rid"]];
			}
		}
	}	
	return members;
}

//-(void)addTeamMember:(int)_rid
//{
//	//TODO
//	//添加一名角色进入队伍
//}
-(void)removeTeamMember:(int)_id
{
	NSArray *array = [self getPlayerRoleList];
	NSMutableArray *temp = [NSMutableArray arrayWithArray:array];
	
	for (NSDictionary *role in  temp) {
		//
		//int _target = [[role objectForKey:@"rid"] intValue];
		int _target = [[role objectForKey:@"id"] intValue];
		if (_target == _id) {
			int _status = [[role objectForKey:@"status"] intValue];
			if (_status == RoleStatus_in) {
				NSMutableDictionary *_target_role = [NSMutableDictionary dictionaryWithDictionary:role];
				[_target_role setObject:[NSNumber numberWithInt:RoleStatus_out] forKey:@"status"];
				[temp removeObject:role];
				[temp addObject:_target_role];
				break;
			}
			else {
				CCLOG(@"role is not in team!");
			}
		}
	}
	[self addData:temp key:@"roles"];
	//
	[GameConnection post:ConnPost_updateRolelist object:nil];
}
//-(BOOL)roleDequeue:(int)_rid
//{
//	//角色离开队伍
//	NSArray * members = [self getTeamMember];
//	for (NSNumber *member in members) {
//		int _value = [member intValue];
//		if (_value == _rid) {
//			[members removeObject:member];
//			return YES;
//		}
//	}
//	return NO;
//	
//}
-(int)getPlayerId
{
	NSDictionary *dict = [self getPlayerInfo];
	int _id = [[dict objectForKey:@"id"] intValue];
	return _id;
}
-(int)getPlayerRole
{
	NSDictionary *dict = [self getPlayerInfo];
	int _rid = [[dict objectForKey:@"rid"] intValue];
	return _rid;
}
-(int)getPlayerTrain
{
	NSDictionary *dict = [self getPlayerInfo];
	int _train = [[dict objectForKey:@"train"] intValue];
	return _train;
}
-(NSString*)getPlayerName{
	NSDictionary *dict = [self getPlayerInfo];
	return [dict objectForKey:@"name"];
}

/*
 -(int)getPlayerLevel
 {
 NSDictionary *dict = [self getPlayerInfo];
 int _level = [[dict objectForKey:@"level"] intValue];
 return _level;
 }
 */

-(int)getPlayerMoney
{
	NSDictionary *dict = [self getPlayerInfo];
	int _coin = [[dict objectForKey:@"coin1"] intValue];
	return _coin;
}
-(int)getPlayerCoin2
{
	NSDictionary *dict = [self getPlayerInfo];
	int _coin = [[dict objectForKey:@"coin2"] intValue];
	return _coin;
}
-(int)getPlayerCoin3
{
	NSDictionary *dict = [self getPlayerInfo];
	int _coin = [[dict objectForKey:@"coin3"] intValue];
	return _coin;
}
-(int)getPlayerIngot{
	NSDictionary *dict = [self getPlayerInfo];
	int _coin = [[dict objectForKey:@"coin3"] intValue];
	_coin += [[dict objectForKey:@"coin2"] intValue];
	return _coin;
}
-(int)getPlayerExp
{
	NSDictionary *dict = [self getPlayerInfo];
	int _coin = [[dict objectForKey:@"exp"] intValue];
	return _coin;
}
-(void)updatePlayerState:(int)state{
	NSDictionary *dict = [self getPlayerInfo];
	NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
	[_target setObject:[NSNumber numberWithInt:state] forKey:@"state"];//更新状态
	[self addData:_target key:@"player"];
}
-(void)updatePlayerMoney:(int)_num
{
	NSDictionary *dict = [self getPlayerInfo];
	NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
	[_target setObject:[NSNumber numberWithInt:_num] forKey:@"coin1"];//更新银币
	[self addData:_target key:@"player"];
	[GameConnection post:ConnPost_updatePlayerInfo object:nil];
}
-(void)updatePlayerLastMapId:(int)_id{
	//测试preMId == 0 的原因
	NSDictionary *dict = [self getPlayerInfo];
	NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
	[_target setObject:[NSNumber numberWithInt:_id] forKey:@"preMId"];//更新银币
	[self addData:_target key:@"player"];
}
-(void)updatePlayerIngot:(int)_value
{
	NSDictionary *dict = [self getPlayerInfo];
	NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
	[_target setObject:[NSNumber numberWithInt:_value] forKey:@"coin2"];//更新银币
	[self addData:_target key:@"player"];
	[GameConnection post:ConnPost_updatePlayerInfo object:nil];
}
-(void)updatePlayerIngotEx:(int)_value
{
	NSDictionary *dict = [self getPlayerInfo];
	NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
	[_target setObject:[NSNumber numberWithInt:_value] forKey:@"coin3"];//更新银币
	[self addData:_target key:@"player"];
	[GameConnection post:ConnPost_updatePlayerInfo object:nil];
}
-(void)updatePlayerTrain:(int)_train
{
	NSDictionary *dict = [self getPlayerInfo];
	NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
	[_target setObject:[NSNumber numberWithInt:_train] forKey:@"train"];//更新炼历
	[self addData:_target key:@"player"];
	[GameConnection post:ConnPost_updatePlayerInfo object:nil];
}

-(void)updatePlayerPosId:(int)_pid
{
    NSDictionary *dict = [self getPlayerInfo];
	NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
	[_target setObject:[NSNumber numberWithInt:_pid] forKey:@"posId"];//更新激活阵形
	[self addData:_target key:@"player"];
	//
	[GameConnection post:ConnPost_updateRolelist object:nil];
}

-(void)updatePlayerFuncs:(unsigned int)_func target:(id)_target call:(SEL)_call{
	if (_target != nil && _call != nil) {
		if (_func) {
			NSDictionary *dict = [self getPlayerInfo];
			NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
			[_target setObject:[NSNumber numberWithInt:_func] forKey:@"funcs"];//更新玩家功能
			[self addData:_target key:@"player"];
			//todo 发送网络
			/*
			NSString *str = [NSString stringWithFormat:@"funcs::%d",_func];
			[GameConnection request:@"funcsUpdate" format:str target:_target call:_call];
			 */
		}
	}
}

-(void)updatePlayerFuncs:(unsigned int)_func
{
	if (_func) {
		NSDictionary *dict = [self getPlayerInfo];
		NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
		[_target setObject:[NSNumber numberWithInt:_func] forKey:@"funcs"];//更新玩家功能
		[self addData:_target key:@"player"];
		//todo 发送网络
		NSString *str = [NSString stringWithFormat:@"funcs::%d",_func];
		[GameConnection request:@"funcsUpdate" format:str target:nil call:nil];
	}	
}

-(void)updatePlayerInfo:(NSDictionary*)info{
	if(!info) return;
	[self addData:info key:@"player"];
	// 写入玩家信息时，修改UI
	[GameConnection post:ConnPost_updatePlayerInfo object:nil];
}

-(void)updatePlayerChapter{
	NSDictionary *dict = [self getPlayerInfo];
	
	NSMutableDictionary *_target = [NSMutableDictionary dictionaryWithDictionary:dict];
	int _chapter = [[dict objectForKey:@"chapter"] intValue];
	_chapter += 1;
	CCLOG(@"isPlayerOnChapter->%d",_chapter);
	[_target setObject:[NSNumber numberWithInt:_chapter] forKey:@"chapter"];//更新
	[_target setObject:[NSNumber numberWithInt:1] forKey:@"level"];//更新等级
	
	[self addData:_target key:@"player"];
}
/*
 * 玩家属性里面的rid如果和角色列表里面的rid相等，那么这是玩家本人
 */
-(NSDictionary*)getPlayerInfo
{
	NSDictionary* player = [NSDictionary dictionaryWithDictionary:[self getDataBykey:@"player"]];
	return player;
	/*
	 NSMutableDictionary *_player = [self getDataBykey:@"_player_data"];
	 
	 if (!_player || YES) {
	 _player = [NSMutableDictionary dictionary];
	 //玩家的测试数据
	 [_player setObject:[NSNumber numberWithInt:0] forKey:@"id"];
	 [_player setObject:[NSNumber numberWithInt:1] forKey:@"uid"];
	 [_player setObject:@"Jay" forKey:@"name"];
	 [_player setObject:[NSNumber numberWithInt:1] forKey:@"sex"];
	 [_player setObject:[NSNumber numberWithInt:200] forKey:@"coin1"];
	 [_player setObject:[NSNumber numberWithInt:33000] forKey:@"coin2"];
	 [_player setObject:[NSNumber numberWithInt:99999] forKey:@"coin3"];
	 [_player setObject:[NSNumber numberWithInt:2] forKey:@"level"];
	 [_player setObject:[NSNumber numberWithInt:24234] forKey:@"exp"];
	 [_player setObject:[NSNumber numberWithInt:0] forKey:@"rid"];
	 [_player setObject:[NSNumber numberWithInt:6372] forKey:@"train"];
	 [_player setObject:[NSNumber numberWithInt:12] forKey:@"vip"];
	 [_player setObject:[NSNumber numberWithInt:0] forKey:@"cid"];
	 [_player setObject:[NSNumber numberWithInt:0] forKey:@"t_total"];
	 [_player setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
	 [_player setObject:@"" forKey:@"pos"];
	 
	 //TODO
	 //ADD
	 //在线时间 登陆时间 登出时间 退出时候的地图ID 退出时的位置
	 ////------------
	 [_player setObject:[NSNumber numberWithInt:2] forKey:@"posId"];
	 
	 [self addData:_player key:@"_player_data"];
	 }
	 
	 return _player;
	 */
}

-(void)setPlayerExp:(int)Exp{
	NSMutableDictionary *player=[NSMutableDictionary dictionaryWithDictionary:[self getPlayerInfo]];
	// 满级后经验控制
	int maxLevel = [[[[GameDB shared] getGlobalConfig] objectForKey:@"playerMaxLevel"] intValue];
	if ([self getPlayerLevel] >= maxLevel) {
		int maxExp = [[[[GameDB shared] getRoleExpInfo:maxLevel+1] objectForKey:@"exp"] intValue];
		maxExp -= 1;
		Exp = MIN(maxExp, Exp);
	}
	[player setValue:[NSNumber numberWithInt:Exp] forKey:@"exp"];
	[self addData:player key:@"player"];
}

-(void)setPlayerCar:(id)pcid{
	NSMutableDictionary *player=[NSMutableDictionary dictionaryWithDictionary:[self getPlayerInfo]];
	[player setValue:pcid forKey:@"car"];
	[self addData:player key:@"player"];
}

//获得角色最大背包数
-(int)getPlayerPackageMaxCapacity{
	int max = 0;
	//GX_FATE_POS01_TAG:GX_FATE_POS06_TAG
	NSDictionary *setDict = [[GameDB shared] getGlobalConfig];
	NSString *vipLvBagsStr = [setDict objectForKey:@"vipLvBags"];
	NSArray *bagsStrArr =[vipLvBagsStr componentsSeparatedByString:@"|"];
	NSArray *capacityArr=nil;
	int vip = [[[self getPlayerInfo] objectForKey:@"vip"] intValue];
	for (NSString *str in bagsStrArr) {
		if (str) {
			capacityArr = [str componentsSeparatedByString:@":"];
			if ([capacityArr count]>1) {
				max = [[capacityArr objectAtIndex:1] intValue];
				if (vip <= [[capacityArr objectAtIndex:0] intValue]) {
					break;
				}
			}
		}		
	}	
	return max;
}
//获得角色背包物品数
-(int)getPlayerPackageItemCount{
	int packageCapacity=0;
	NSArray *equipArray = [[GameConfigure shared] getPlayerEquipmentList];
	NSArray *itemArray = [[GameConfigure shared] getPlayerItemList];
	NSArray *fateArray = [[GameConfigure shared] getPlayerFateList];
	////
	NSNumber *itemUsed;
//	NSNumber *itemIID;
//	NSNumber *itemCount;
//	NSNumber *itemStack;
//	NSDictionary *t_dict;
	NSDictionary *dict;
	////
	for (dict in equipArray ) {
		itemUsed = [dict objectForKey:@"used"];
		if (itemUsed && EquipmentStatus_unused ==[itemUsed intValue]) {
			packageCapacity++;
		}
	}
	/*
	for (dict in itemArray ) {
		//itemUsed = [dict objectForKey:@"used"];
		//if (EquipmentStatus_unused ==[itemUsed intValue]) {
			itemCount = [dict objectForKey:@"count"];
			itemIID = [dict objectForKey:@"iid"];
			//soul				
			t_dict = [[GameDB shared] getItemInfo:[itemIID intValue]];
			itemStack = [t_dict objectForKey:@"stack"];
		if (itemStack.intValue>0) {		
			for (int i=0; i< (itemCount.integerValue/itemStack.integerValue) ; i++) {
				packageCapacity++;
			}
			if (itemCount.integerValue%itemStack.integerValue>0) {
				packageCapacity++;
			}
		}
		//}
	}
	 */
	for (dict in fateArray ) {
		itemUsed = [dict objectForKey:@"used"];
		if (itemUsed && FateStatus_unused ==[itemUsed intValue]) {
			packageCapacity++;
		}
	}
	
	packageCapacity += itemArray.count ;
	
	return packageCapacity;
}
-(BaseAttribute)getNpcAttribute:(int)_rid level:(int)_level{
	
	NSDictionary *role = [[GameDB shared] getRoleInfo:_rid];
	int armId = [[role objectForKey:@"armId"] intValue];
	//int armLevel = 2;
	
	//玩家角色等级
	NSDictionary * roleLevel = [[GameDB shared] getRoleLevelInfo:_rid level:_level];
	//武器等级
	NSDictionary * roleArmLevel = [[GameDB shared] getArmLevelInfo:armId level:2];
	
	//角色
	BaseAttribute ba_role = BaseAttributeFromDict(roleLevel);
	//武器
	BaseAttribute ba_arm = BaseAttributeFromDict(roleArmLevel);

	////////////////////////////////////////////////////////////////////////////
	
	ba_role = BaseAttributeAddBase(ba_role, ba_arm);
	ba_role = BaseAttributeConvert(ba_role);
	ba_role = BaseAttributeAddOther(ba_role, ba_arm);
	
	return BaseAttributeCheck(ba_role);
}
/*
 * 角色面板属性数据源
 */
-(BaseAttribute)getRoleAttribute:(int)_rid isLoadOtherBuff:(BOOL)isLoad{
	
	//通过角色ID获得角色的attribute
	//用于 面板的显示 武器 装备 基础 各种相加
	
	NSDictionary * userRole = [self getPlayerRoleFromListById:_rid];
	NSDictionary * position = [self getUserChoosePosition];
	
	NSArray * equips = [self getPlayerEquipmentList];
	NSArray * fates = [self getPlayerFateList];
	
	NSDictionary * footBuff = [self getPlayerBuffByType:Buff_Type_foot];
	
	NSMutableDictionary * data = [NSMutableDictionary dictionary];
	[data setObject:userRole forKey:@"userRole"];
	[data setObject:position forKey:@"position"];
	[data setObject:equips forKey:@"equips"];
	[data setObject:fates forKey:@"fates"];
	[data setObject:[NSNumber numberWithInt:[self getPlayerLevel]] forKey:@"level"];
	
	if(footBuff) [data setObject:footBuff forKey:@"footBuff"];
	
	return [self getRoleAttributeByData:data isLoadOtherBuff:isLoad];
	
}

-(BaseAttribute)getSingleRoleAttributeById:(int)rid level:(int)level{
	
	NSDictionary * role = [[GameDB shared] getRoleInfo:rid];
	
	int armId = [[role objectForKey:@"armId"] intValue];
	int armLevel = 0;
	
	//玩家角色等级
	NSDictionary * roleLevel = [[GameDB shared] getRoleLevelInfo:rid level:level];
	//武器等级
	NSDictionary * roleArmLevel = [[GameDB shared] getArmLevelInfo:armId level:armLevel];
	
	//角色
	BaseAttribute ba_role = BaseAttributeFromDict(roleLevel);
	//武器
	BaseAttribute ba_arm = BaseAttributeFromDict(roleArmLevel);
	
	////////////////////////////////////////////////////////////////////////////
	ba_role = BaseAttributeAddBase(ba_role, ba_arm);
	ba_role = BaseAttributeConvert(ba_role);
	ba_role = BaseAttributeAddOther(ba_role, ba_arm);
	////////////////////////////////////////////////////////////////////////////
	
	return BaseAttributeCheck(ba_role);
}

-(BaseAttribute)getRoleAttributeByData:(NSDictionary*)data isLoadOtherBuff:(BOOL)isLoad{
	
	int playerLevel = [[data objectForKey:@"level"] intValue];
	
	NSDictionary * userRole = [data objectForKey:@"userRole"];
	NSDictionary * position = [data objectForKey:@"position"];
	NSArray * equips = [data objectForKey:@"equips"];
	NSArray * fates = [data objectForKey:@"fates"];
	
	NSDictionary * footBuff = [data objectForKey:@"footBuff"];
	
	int _rid = [[userRole objectForKey:@"rid"] intValue];
	NSDictionary * role = [[GameDB shared] getRoleInfo:_rid];
	
	////////////////////////////////////////////////////////////////////////////
	
	int armId = [[role objectForKey:@"armId"] intValue];
	int armLevel = [[userRole objectForKey:@"armLevel"] intValue];
	
	//玩家角色等级
	NSDictionary * roleLevel = [[GameDB shared] getRoleLevelInfo:_rid level:playerLevel];

	//武器等级
	NSDictionary * roleArmLevel = [[GameDB shared] getArmLevelInfo:armId level:armLevel];
	
	//阵型等级
	NSString * positionLevelBuff = @"";
	if(position!=nil){
		int posId = [[position objectForKey:@"posId"] intValue];
		int posLevel = [[position objectForKey:@"level"] intValue];
		int posIndex = 0;
		for(int i=1;i<15;i++){
			int posRoleId = [[position objectForKey:[NSString stringWithFormat:@"s%d",i]] intValue];
			if(posRoleId==_rid){
				posIndex = i;
			}
		}
		NSDictionary * positionLevel = [[GameDB shared] getPositionLevelInfo:posId level:posLevel];
		positionLevelBuff = [positionLevel objectForKey:[NSString stringWithFormat:@"s%d",posIndex]];
	}
	//阵型等级
	
	////////////////////////////////////////////////////////////////////////////
	
	//角色
	BaseAttribute ba_role = BaseAttributeFromDict(roleLevel);
	//武器
	BaseAttribute ba_arm = BaseAttributeFromDict(roleArmLevel);
	//装备 TODO 套装加成???
	BaseAttribute ba_equip = [self getPlayerEquipTotalBAFrom:userRole byEquips:equips];
	//命格
	BaseAttribute ba_fate = [self getPlayerFateTotalBAFrom:userRole byFates:fates];
	
	//阵型
	BaseAttribute ba_pos = BaseAttributeFromKV(positionLevelBuff);
	//阵型 百分比
	BaseAttribute ba_pos_p = BaseAttributePercentFromKV(positionLevelBuff);
	ba_pos_p.SPD += valueFromFormat(positionLevelBuff,@"CENTER_SPD_P",1); //阵眼速度加成
	
	
	//食馆BUFF
	BaseAttribute ba_foot = BaseAttributeZero();
	//食馆BUFF 百份比
	BaseAttribute ba_foot_p = BaseAttributeZero();
	
	if(isLoad){
		//NSDictionary * footBuff = [self getPlayerBuffByType:Buff_Type_foot];
		if(footBuff){
			ba_foot = BaseAttributeFromKV([footBuff objectForKey:@"buff"]);
			ba_foot_p = BaseAttributePercentFromKV([footBuff objectForKey:@"buff"]);
		}
	}
	
	////////////////////////////////////////////////////////////////////////////
    //
    NSDictionary *role_info = [[GameConfigure shared] getPlayerRoleFromListById:_rid];;
    NSDictionary* d1 = [role_info objectForKey:@"tr"];
    BaseAttribute r2 = BaseAttributeFromDict(d1);
    ba_role = BaseAttributeAddBase(ba_role, r2);
    //
    NSDictionary *role_up_dict = [[GameDB shared] getRoleupTypeInfo:_rid];
    if (role_up_dict && [role_up_dict objectForKey:@"type"]) {
        
        int type_ = [[role_up_dict objectForKey:@"type"] intValue];
		NSDictionary *role_up_info_dict = [[GameDB shared] getRoleupInfo:type_ quality:[[role_info objectForKey:@"q"] intValue] grade:[[role_info objectForKey:@"g"] intValue] check:[[role_info objectForKey:@"c"] intValue]];
        if(role_up_info_dict && [role_up_info_dict objectForKey:@"attr"]){
            BaseAttribute r_up = BaseAttributeFromDict([role_up_info_dict objectForKey:@"attr"]);
            ba_role = BaseAttributeAddBase(ba_role, r_up);
        }
    }
    //
	ba_role = BaseAttributeAddBase(ba_role, ba_arm);
	ba_role = BaseAttributeAddBase(ba_role, ba_equip);
	ba_role = BaseAttributeAddBase(ba_role, ba_fate);
	ba_role = BaseAttributeAddBase(ba_role, ba_pos);
	ba_role = BaseAttributeAddBase(ba_role, ba_foot);
	
	ba_role = BaseAttributeConvert(ba_role);
	
	ba_role = BaseAttributeAddOther(ba_role, ba_arm);
	ba_role = BaseAttributeAddOther(ba_role, ba_equip);
	ba_role = BaseAttributeAddOther(ba_role, ba_fate);
	ba_role = BaseAttributeAddOther(ba_role, ba_pos);
	ba_role = BaseAttributeAddOther(ba_role, ba_foot);
	
	ba_role = BaseAttributeAdd(ba_role, BaseAttributeFromPercent(ba_role, ba_pos_p));
	ba_role = BaseAttributeAdd(ba_role, BaseAttributeFromPercent(ba_role, ba_foot_p));
	
	////////////////////////////////////////////////////////////////////////////
	
	return BaseAttributeCheck(ba_role);
	
}

-(BaseAttribute)getPlayerEquipTotalBAFrom:(NSDictionary*)role byEquips:(NSArray*)equips{
	
	BaseAttribute ba = BaseAttributeZero();
	if([equips count]==0) return ba;
	
	for(int i=1;i<=6;i++){
		NSString * key = [NSString stringWithFormat:@"eq%d",i];
		int ueid = [[role objectForKey:key] intValue];
		
		for(NSDictionary * equip in equips){
			
			if([[equip objectForKey:@"id"] intValue]==ueid){
				
				int eid = [[equip objectForKey:@"eid"] intValue];
				NSDictionary * equipBase = [[GameDB shared] getEquipmentInfo:eid];
				if(equipBase){
					ba = BaseAttributeAdd(ba, BaseAttributeFromDict(equipBase));
				}
				
				int level = [[equip objectForKey:@"level"] intValue];
				if(level>0){
					
					NSDictionary* dict = [[GameDB shared] getEquipmentInfo:eid];
					int _part = [[dict objectForKey:@"part"] intValue];
					NSDictionary * equipLevel = [[GameDB shared] getEquipmentLevelInfo:_part level:level];
					
					if(equipLevel){
						ba = BaseAttributeAdd(ba, BaseAttributeFromDict(equipLevel));
					}
					
				}
				
				// 珠宝
				NSDictionary *gem = [equip objectForKey:@"gem"];
				if (gem) {
					BaseAttribute attribute = BaseAttributeZero();
					NSArray* jewelIds = [gem allValues];
					for (NSNumber* number in jewelIds){
						NSDictionary* jewel = [self getPlayerJewelInfoById:[number intValue]];
						if (jewel) {
							int gid = [[jewel objectForKey:@"gid"] intValue];
							int level = [[jewel objectForKey:@"level"] intValue];
							NSDictionary* dict = [[GameDB shared] getJewelLevelInfoWithLevel:gid level:level];
							BaseAttribute r1 = BaseAttributeFromDict(dict);
							BaseAttribute r2 = BaseAttributePercentFromDict(dict);
							r2 = BaseAttributeFromPercent(attribute, r2);
							r2 = BaseAttributeAdd(r1, r2);
							attribute = BaseAttributeAdd(attribute, r2);
						}
					}
					
					ba = BaseAttributeAdd(ba, attribute);
				}
				
			}
			
		}
		
		//ba = BaseAttributeAdd(ba, [self getPlayerEquipBA:ueid]);
	}
	
	
	//----
	//套装加成
	//----
	NSMutableDictionary *ESet = [NSMutableDictionary dictionary];
	for (int i = 1; i <= 6; i++) {
		NSString *_key = [NSString stringWithFormat:@"eq%d",i];
		int reid = [[role objectForKey:_key] intValue];
		if (reid <= 0) { //没穿装备
			continue ;
		}
		
		//NSDictionary *req = [self getPlayerEquipInfoById:reid];
		NSDictionary * req = nil;
		for (NSDictionary * dict in equips) {
			int new_id = [[dict objectForKey:@"id"] intValue ];
			if (new_id == reid) {
				req = dict;
				break;
			}
		}
		
		int eid = [[req objectForKey:@"eid"] intValue];
		if (eid <= 0) { //装备出错
			continue ;
		}
		NSDictionary *eq = [[GameDB shared] getEquipmentInfo:eid];
		int sid = [[eq objectForKey:@"sid"] intValue];
		if (sid <= 0) { //套装出错
			continue ;
		}
		
		NSNumber *number = [ESet objectForKey:[NSString stringWithFormat:@"%d",sid]];
		if (!number) {
			[ESet setObject:[NSNumber numberWithInt:1] forKey:[NSString stringWithFormat:@"%d",sid]];
		}
		else {
			int num = [number intValue];
			num += 1;
			[ESet setObject:[NSNumber numberWithInt:num] forKey:[NSString stringWithFormat:@"%d",sid]];
		}
	}
	//----------------------
	NSArray *keys = [ESet allKeys];//全部套装的Key
	for (NSString *_key in keys) {
		int _id = [_key intValue];
		int _num = [[ESet objectForKey:_key] intValue];
		_num = _num/2;
		_num = _num*2;
		NSDictionary *dict = [[GameDB shared] getEquipmentSetInfo:_id];
		if (_num > 0) {
			//-----
			NSString *_eft = [NSString stringWithFormat:@"effect%d",_num];
			NSString *effects = [dict objectForKey:_eft];
			if (effects) {
				BaseAttribute temp = BaseAttributeFromKV(effects);
				ba =  BaseAttributeAdd(ba, temp);
			}
		}
	}
	return ba;
}

/*
-(BaseAttribute)getPlayerEquipBA:(int)ueid{
	BaseAttribute ba = BaseAttributeZero();
	if(ueid<=0) return ba;
	NSDictionary * equip = [self getPlayerEquipInfoById:ueid];
	if(equip){
		int eid = [[equip objectForKey:@"eid"] intValue];
		int level = [[equip objectForKey:@"level"] intValue];
		NSDictionary * equipLevel = nil;
		if(level==0){
			equipLevel = [[GameDB shared] getEquipmentInfo:eid];
		}else{
			equipLevel = [[GameDB shared] getEquipmentLevelInfo:eid level:level];
		}
		if(equipLevel){
			ba = BaseAttributeFromDict(equipLevel);
		}
	}
	return ba;
}
*/

-(BaseAttribute)getPlayerFateTotalBAFrom:(NSDictionary*)role byFates:(NSArray*)fates{
	BaseAttribute ba = BaseAttributeZero();
	for(int i=1;i<=6;i++){
		NSString * key = [NSString stringWithFormat:@"fate%d",i];
		int ufid = [[role objectForKey:key] intValue];
		
		if(ufid>0){
			
			NSDictionary * fate = nil;
			for (NSDictionary * dict in fates) {
				int new_id = [[dict objectForKey:@"id"] intValue];
				if (new_id == ufid) {
					fate = dict;
					break;
				}
			}
			
			if(fate){
				int fid = [[fate objectForKey:@"fid"] intValue];
				int level = [[fate objectForKey:@"level"] intValue];
				if(level<=0) level = 1;
				NSDictionary * fateLevel = [[GameDB shared] getFateLevelInfo:fid level:level];
				if(fateLevel){
					//ba = BaseAttributeFromDict(fateLevel);
					ba = BaseAttributeAdd(ba, BaseAttributeFromDict(fateLevel));
				}
			}
			
		}
		
		//ba = BaseAttributeAdd(ba, [self getPlayerFateBA:ufid]);
	}
	return ba;
}

/*
-(BaseAttribute)getPlayerFateBA:(int)ufid{
	BaseAttribute ba = BaseAttributeZero();
	if(ufid<=0) return ba;
	NSDictionary * fate = [self getPlayerFateInfoById:ufid];
	if(fate){
		int fid = [[fate objectForKey:@"fid"] intValue];
		int level = [[fate objectForKey:@"level"] intValue];
		if(level<=0) level = 1;
		NSDictionary * fateLevel = [[GameDB shared] getFateLevelInfo:fid level:level];
		if(fateLevel){
			ba = BaseAttributeFromDict(fateLevel);
		}
	}
	return ba;
}
*/

#pragma mark - 
#pragma mark - 阵型

-(NSArray *)getPlayerPhalanxList
{
	//return [self getDataBykey:@"position"];
	return [NSArray arrayWithArray:[self getDataBykey:@"position"]];
}
-(NSArray *)addPlayerPhalanx:(NSDictionary *)_dict
{
    NSArray* pList = [self getPlayerPhalanxList];
    NSMutableArray *temp = [NSMutableArray arrayWithArray:pList];
    if (_dict) {
        [temp addObject:_dict];
        [self addData:temp key:@"position"];
		//
		[GameConnection post:ConnPost_updateRolelist object:nil];
    } else {
        CCLOG(@"add player phalanx is nil");
    }
    return temp;
}
//升级
-(void)updatePlayerPhalanxWithId:(int)_pid level:(int)_level
{
    NSArray *array = (NSMutableArray *)[self getPlayerPhalanxList];
    NSMutableArray *list = [NSMutableArray arrayWithArray:array];
    if (list) {
        for (NSDictionary *dict in list) {
            int _value = [[dict objectForKey:@"posId"] intValue];
            if (_value == _pid) {
                NSMutableDictionary *t_dict = [NSMutableDictionary dictionaryWithDictionary:dict];
                [t_dict setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
                [list removeObject:dict];
                [list addObject:t_dict];
                break;
            }
        }
        [self addData:list key:@"position"];
		//
		//[GameConnection post:ConnPost_updateRolelist object:nil];
    }
}

-(void)updatePlayerPhalanx:(NSDictionary *)dict
{
    if (dict) {
        NSArray *array = (NSMutableArray *)[self getPlayerPhalanxList];
        NSMutableArray *list = [NSMutableArray arrayWithArray:array];
        if (list) {
            int _id = [[dict objectForKey:@"id"] intValue];
            for (NSDictionary *_dict in list) {
                int _value = [[_dict objectForKey:@"id"] intValue];
                if (_value == _id) {
                    [list removeObject:_dict];
                    [list addObject:dict];
                    break;
                }
            }
            [self addData:list key:@"position"];
			//
			[GameConnection post:ConnPost_updateRolelist object:nil];
        }
    } else {
        CCLOG(@"updatePlayerPhalanx dict is nil");
    }

}

-(NSDictionary *)getPlayerPhalanxByPhalanxId:(int)pid
{
    for (NSMutableDictionary *playerPhalanx in [self getPlayerPhalanxList]) {
        if ([[playerPhalanx objectForKey:@"posId"] intValue] == pid) {
            return playerPhalanx;
        }
    }
    return  nil;
}

-(NSDictionary *)getPlayerPhalanxById:(int)_id
{
    for (NSMutableDictionary *playerPhalanx in [self getPlayerPhalanxList]) {
        if ([[playerPhalanx objectForKey:@"id"] intValue] == _id) {
            return playerPhalanx;
        }
    }
    return  nil;
}
-(NSArray*)getFateArrayWithRoldID:(NSInteger)roleID{
	//TODO
	//NSMutableArray *itemArray = [self getDataBykey:@"fateArray"];
	static NSMutableArray *itemArray;
	//六个部位 -1 为空
	[itemArray addObject:[NSNumber numberWithInt:-1]];
	[itemArray addObject:[NSNumber numberWithInt:1023]];
	[itemArray addObject:[NSNumber numberWithInt:-1]];
	[itemArray addObject:[NSNumber numberWithInt:1026]];
	[itemArray addObject:[NSNumber numberWithInt:-1]];
	[itemArray addObject:[NSNumber numberWithInt:-1]];
	return itemArray;
}
#pragma mark - 
#pragma mark - Player


/*
 * 玩家装备表拿数据
 */
-(NSDictionary*)getPlayerEquipInfoById:(int)_id
{
	NSArray *array = [self getPlayerEquipmentList];
	for (NSDictionary *dict in array) {
		int new_id = [[dict objectForKey:@"id"] intValue ];
		if (new_id == _id) {
			return dict;
		}
	}
	return nil;
}
-(NSDictionary*)getPlayerEquipInfoWithBaseId:(int)_id
{
	NSArray *array = [self getPlayerEquipmentList];
	for (NSDictionary *dict in array) {
		int new_id = [[dict objectForKey:@"eid"] intValue ];
		if (new_id == _id) {
			return dict;
		}
	}
	return nil;
}

-(NSDictionary*)initErrorMessage
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    /*
	// 通用错误编码
	[dict setObject:@"数值错误" forKey:@"1"];
	[dict setObject:@"时间未到" forKey:@"2"];
	[dict setObject:@"超时" forKey:@"3"];
	[dict setObject:@"未达到所需主将等级" forKey:@"4"];
	[dict setObject:@"未到达所需vip等级" forKey:@"5"];
	[dict setObject:@"扣费失败" forKey:@"6"];
	[dict setObject:@"该用户无此操作权限" forKey:@"7"];
	[dict setObject:@"操作已处理" forKey:@"8"];
	[dict setObject:@"不存在该名玩家" forKey:@"9"];
	[dict setObject:@"重名" forKey:@"10"];
	[dict setObject:@"找不到" forKey:@"11"];
	[dict setObject:@"支付失败" forKey:@"12"];
	[dict setObject:@"达到最大玩家数" forKey:@"13"];
	[dict setObject:@"无资源" forKey:@"14"];
	// 背包
	[dict setObject:@"行囊已满，请先清理" forKey:@"21"];
	// 物品
	[dict setObject:@"EC_EQUIP_NOFOUND" forKey:@"31"];
	[dict setObject:@"EC_EQUIP_NOUSE" forKey:@"32"];
	[dict setObject:@"EC_EQUIP_NOPART" forKey:@"33"];
	[dict setObject:@"EC_FATE_NOFOUND" forKey:@"36"];
	[dict setObject:@"EC_FATE_MAX" forKey:@"37"];
	[dict setObject:@"EC_FATE_NOMERGE" forKey:@"38"];
	// 配将
	[dict setObject:@"EC_ROLE_NOFOUND" forKey:@"51"];
	[dict setObject:@"EC_ROLE_MAIN_REP " forKey:@"52"];
	[dict setObject:@"EC_ROLE_WEAR_REP" forKey:@"53"];
	[dict setObject:@"EC_ROLE_PART_USED" forKey:@"54"];
	// 阵形
	[dict setObject:@"EC_POS_NOFOUND" forKey:@"61"];
	// 深渊错误编码
	[dict setObject:@"EC_DEEP_HAVE_GUARD" forKey:@"62"];
	// 同盟
	[dict setObject:@"没有这个同盟" forKey:@"80"];
	[dict setObject:@"玩家已经有同盟" forKey:@"81"];
	[dict setObject:@"玩家没有同盟" forKey:@"82"];
	[dict setObject:@"该职位已满" forKey:@"83"];
	[dict setObject:@"盟主不能退出同盟，除非解散" forKey:@"84"];
	// 兵符
	[dict setObject:@"还有剩余的免费刷新次数，无法进行元宝刷新" forKey:@"101"];
	[dict setObject:@"悬赏任务免费刷新次数已经用完" forKey:@"102"];
	[dict setObject:@"当前等级暂无悬赏任务" forKey:@"103"];
	[dict setObject:@"积分不够，无法开启悬赏宝箱" forKey:@"104"];
	[dict setObject:@"悬赏任务已经接受" forKey:@"105"];
	[dict setObject:@"无当前悬赏任务" forKey:@"106"];
	[dict setObject:@"该悬赏任务已完成" forKey:@"107"];
	// 时光盒
	[dict setObject:@"有待收奖励或物品未收取" forKey:@"120"];
	[dict setObject:@"重置次数已经用完了" forKey:@"121"];
	[dict setObject:@"该章节还没有开通" forKey:@"122"];
	[dict setObject:@"未达到秒杀条件" forKey:@"123"];
	[dict setObject:@"无法使用秒杀" forKey:@"124"];
	[dict setObject:@"无排名" forKey:@"125"];
    */
	// 通用错误编码
	[dict setObject:NSLocalizedString(@"configure_error_1",nil) forKey:@"1"];
	[dict setObject:NSLocalizedString(@"configure_error_2",nil) forKey:@"2"];
	[dict setObject:NSLocalizedString(@"configure_error_3",nil) forKey:@"3"];
	[dict setObject:NSLocalizedString(@"configure_error_4",nil) forKey:@"4"];
	[dict setObject:NSLocalizedString(@"configure_error_5",nil) forKey:@"5"];
	[dict setObject:NSLocalizedString(@"configure_error_6",nil) forKey:@"6"];
	[dict setObject:NSLocalizedString(@"configure_error_7",nil) forKey:@"7"];
	[dict setObject:NSLocalizedString(@"configure_error_8",nil) forKey:@"8"];
	[dict setObject:NSLocalizedString(@"configure_error_9",nil) forKey:@"9"];
	[dict setObject:NSLocalizedString(@"configure_error_10",nil) forKey:@"10"];
	[dict setObject:NSLocalizedString(@"configure_error_11",nil) forKey:@"11"];
	[dict setObject:NSLocalizedString(@"configure_error_12",nil) forKey:@"12"];
	[dict setObject:NSLocalizedString(@"configure_error_13",nil) forKey:@"13"];
	[dict setObject:NSLocalizedString(@"configure_error_14",nil) forKey:@"14"];
	// 背包
	[dict setObject:NSLocalizedString(@"configure_error_21",nil) forKey:@"21"];
	// 物品
	[dict setObject:NSLocalizedString(@"configure_error_31",nil) forKey:@"31"];
	[dict setObject:NSLocalizedString(@"configure_error_32",nil) forKey:@"32"];
	[dict setObject:NSLocalizedString(@"configure_error_33",nil) forKey:@"33"];
	[dict setObject:NSLocalizedString(@"configure_error_36",nil) forKey:@"36"];
	[dict setObject:NSLocalizedString(@"configure_error_37",nil) forKey:@"37"];
	[dict setObject:NSLocalizedString(@"configure_error_38",nil) forKey:@"38"];
	// 配将
	[dict setObject:NSLocalizedString(@"configure_error_51",nil) forKey:@"51"];
	[dict setObject:NSLocalizedString(@"configure_error_52",nil) forKey:@"52"];
	[dict setObject:NSLocalizedString(@"configure_error_53",nil) forKey:@"53"];
	[dict setObject:NSLocalizedString(@"configure_error_54",nil) forKey:@"54"];
	// 阵形
	[dict setObject:NSLocalizedString(@"configure_error_61",nil) forKey:@"61"];
	// 深渊错误编码
	[dict setObject:NSLocalizedString(@"configure_error_62",nil) forKey:@"62"];
	// 同盟
	[dict setObject:NSLocalizedString(@"configure_error_80",nil) forKey:@"80"];
	[dict setObject:NSLocalizedString(@"configure_error_81",nil) forKey:@"81"];
	[dict setObject:NSLocalizedString(@"configure_error_82",nil) forKey:@"82"];
	[dict setObject:NSLocalizedString(@"configure_error_83",nil) forKey:@"83"];
	[dict setObject:NSLocalizedString(@"configure_error_84",nil) forKey:@"84"];
	// 兵符
	[dict setObject:NSLocalizedString(@"configure_error_101",nil) forKey:@"101"];
	[dict setObject:NSLocalizedString(@"configure_error_102",nil) forKey:@"102"];
	[dict setObject:NSLocalizedString(@"configure_error_103",nil) forKey:@"103"];
	[dict setObject:NSLocalizedString(@"configure_error_104",nil) forKey:@"104"];
	[dict setObject:NSLocalizedString(@"configure_error_105",nil) forKey:@"105"];
	[dict setObject:NSLocalizedString(@"configure_error_106",nil) forKey:@"106"];
	[dict setObject:NSLocalizedString(@"configure_error_107",nil) forKey:@"107"];
	// 时光盒
	[dict setObject:NSLocalizedString(@"configure_error_120",nil) forKey:@"120"];
	[dict setObject:NSLocalizedString(@"configure_error_121",nil) forKey:@"121"];
	[dict setObject:NSLocalizedString(@"configure_error_122",nil) forKey:@"122"];
	[dict setObject:NSLocalizedString(@"configure_error_123",nil) forKey:@"123"];
	[dict setObject:NSLocalizedString(@"configure_error_124",nil) forKey:@"124"];
	[dict setObject:NSLocalizedString(@"configure_error_125",nil) forKey:@"125"];
    
	//[self recordPlayerSetting:@"error" value:dict];
	
	return [dict retain];
}

-(void)updateCBE:(NSDictionary *)powers{
	int total = [self getPowerResult:powers];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	NSDictionary* pDict = [NSDictionary dictionaryWithDictionary:powers];
	
	[dict setObject:[NSNumber numberWithInt:total] forKey:@"CBE"];
	[dict setObject:pDict forKey:@"cbes"];
	
	[GameConnection request:@"CBEUpdate" data:dict target:nil call:nil];
	
	//[GameConnection request:@"CBEUpdate" format:str target:nil call:nil];
	
}

-(int)getTotalPowerResult{
	NSDictionary* position = [self getUserChoosePosition];
	int _total = 0 ;
	for(int i=0;i<15;i++){
		NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
		int rid = [[position objectForKey:key] intValue];
		if (rid > 0) {
			BaseAttribute att = [[GameConfigure shared] getRoleAttribute:rid isLoadOtherBuff:YES];
			int __value = getBattlePower(att);
			_total += __value ;
		}
	}
	return _total ;
}

-(int)getPowerResult:(NSDictionary *)powers{
	if (powers == nil )  return 0 ;
	
	int _total = 0 ;
	
	NSDictionary* position = [self getUserChoosePosition];
	for(int i=0;i<15;i++){
		NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
		int rid = [[position objectForKey:key] intValue];
		if (rid > 0) {
			NSString* _kid = [NSString stringWithFormat:@"%d",rid];
			int _value = [[powers objectForKey:_kid] intValue];
			_total += _value ;
		}
	}
	
	return _total;
}
/*
-(void)sendRolePower{
	int _rid = [self getPlayerRole];
	if (_rid > 0) {
		BaseAttribute att = [[GameConfigure shared] getRoleAttribute:_rid isLoadOtherBuff:NO];
		int power = getBattlePower(att);
		if (power > 0) {
			
			NSString *str = [NSString stringWithFormat:@"key:CBE|value::%d",power];
			[GameConnection request:@"pAttrSet" format:str target:nil call:nil];
		}else{
			CCLOG(@"sendRolePower->power <= 0");
		}
	}else{
		CCLOG(@"sendRolePower->_rid <= 0");
	}
}*/

-(NSDictionary*)getErrorMessage
{
	NSDictionary *dict = [self getPlayerRecord:@"error"];
	if (!dict) {
		dict = [[self initErrorMessage] autorelease];
	}
	return dict;
}

-(NSString*)getErrorMessage:(NSString*)key
{
	NSDictionary *dict = [self getPlayerRecord:@"error"];
	NSString *_key=[NSString stringWithFormat:@"%@",key];
	if (!dict) {
		dict = [[self initErrorMessage] autorelease];
	}
	return [dict objectForKey:_key];
}

/*
 * 玩家身上的装备列表
 */
-(NSArray*)getPlayerEquipmentList
{	
	NSDictionary *ilist = [self getDataBykey:@"ilist"];
	NSArray *elist = [ilist objectForKey:@"equip"];
	if (elist) {
		return elist;
	}
	else {
		CCLOG(@"getPlayerEquipmentList return nil");
		return [NSArray array];
	}
	return [NSArray array];
}
-(void)moveLevelPlayerEquipmentEid1:(int)eid1 eid2:(int)eid2
{	
	int level_1 = 0;
	int level_2 = 0;

	NSDictionary *old_data_1=nil;
	NSDictionary *old_data_2=nil;
	NSMutableDictionary *_data_1=nil;
	NSMutableDictionary *_data_2=nil;
	
	NSArray *array = [self getPlayerEquipmentList];
	NSMutableArray *elist = [NSMutableArray arrayWithArray:array];
	if (!elist) {
		CCLOG(@"get equip list error");
		return;
	}
	//
	for (NSDictionary *dict in elist) {
		int _id1 = [[dict objectForKey:@"id"] intValue];
		if (_id1 == eid1) {
			old_data_1 = dict;
			_data_1 = [NSMutableDictionary dictionaryWithDictionary:dict];
			level_1 = [[_data_1 objectForKey:@"level"] intValue];
			break;
		}
	}
	//
	for (NSDictionary *dict in elist) {
		int _id2 = [[dict objectForKey:@"id"] intValue];
		if (_id2 == eid2) {
			old_data_2 = dict;
			_data_2 = [NSMutableDictionary dictionaryWithDictionary:dict];
			level_2 = [[_data_2 objectForKey:@"level"] intValue];
			break;
		}
	}
	//
	if (old_data_1 && old_data_2 && _data_1 && _data_2) {
		//----------------------
		int part_1 = 0;
		int part_2 = 0;
		NSDictionary *b_itemDict_1 = [[GameDB shared] getEquipmentInfo:[[old_data_1 objectForKey:@"eid"] intValue]];
		if(b_itemDict_1){
			part_1 = [[b_itemDict_1 objectForKey:@"part"] intValue];
			if (part_1<1||part_1>6) {
				CCLOG(@"part_1 get part for base item dict error");
				return;
			}
		}
		NSDictionary *b_itemDict_2 = [[GameDB shared] getEquipmentInfo:[[old_data_2 objectForKey:@"eid"] intValue]];
		if(b_itemDict_2){
			part_2 = [[b_itemDict_2 objectForKey:@"part"] intValue];
			if (part_2<1||part_2>6) {
				CCLOG(@"part_2 get part for base item dict error");
				return;
			}
		}
		if (part_1!=part_2) {
			CCLOG(@"part_1 != part_2 error");
			return;
		}
		//-----------------------		
		[_data_1 setObject:[NSNumber numberWithInt:level_2] forKey:@"level"];
		[_data_2 setObject:[NSNumber numberWithInt:level_1] forKey:@"level"];
		[elist removeObject:old_data_1];//删除一个
		[elist removeObject:old_data_2];//删除一个
		[elist addObject:_data_1];//添加一个
		[elist addObject:_data_2];//添加一个
		
		NSDictionary *ilist = [self getDataBykey:@"ilist"];
		NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
		[temp_data setObject:elist forKey:@"equip"];//重新写入合格列表
		[self addData:temp_data key:@"ilist"];//重新写入所有列表
		
		//fix chao
		//[GameConnection post:ConnPost_roleChangeEquip object:nil];
		//end
	}else{
		CCLOG(@"move equip level error ");
	}
}
-(void)movePlayerEquipment:(int)eid1 :(int)eid2 :(int)upid :(int)_part
{
	NSArray *array = [self getPlayerEquipmentList];
	NSMutableArray *elist = [NSMutableArray arrayWithArray:array];
	for (NSDictionary *dict in elist) {
		int _id1 = [[dict objectForKey:@"id"] intValue];
		if (_id1 == eid1) {
			NSMutableDictionary *_data = [NSMutableDictionary dictionaryWithDictionary:dict];
			int _use = [[_data objectForKey:@"used"] intValue];
			if (_use == EquipmentStatus_used) {
				_use = EquipmentStatus_unused;
			}
			else {
				_use = EquipmentStatus_used;
			}
			[_data setObject:[NSNumber numberWithInt:_use] forKey:@"used"];
			[elist removeObject:dict];//删除一个
			[elist addObject:_data];//添加一个
			break;
		}
	}
	BOOL isEid2 = YES;
	for (NSDictionary *dict in elist) {
		int _id1 = [[dict objectForKey:@"id"] intValue];
		if (_id1 == eid2) {
			NSMutableDictionary *_data = [NSMutableDictionary dictionaryWithDictionary:dict];
			int _use = [[_data objectForKey:@"used"] intValue];
			if (_use == EquipmentStatus_used) {
				_use = EquipmentStatus_unused;
				isEid2 = NO;
			}
			else {
				_use = EquipmentStatus_used;
			}
			[_data setObject:[NSNumber numberWithInt:_use] forKey:@"used"];
			[elist removeObject:dict];//删除一个
			[elist addObject:_data];//添加一个
			break;
		}
	}
	NSDictionary *ilist = [self getDataBykey:@"ilist"];
	NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
	[temp_data setObject:elist forKey:@"equip"];
	[self addData:temp_data key:@"ilist"];
	
	//重新穿上
	if (isEid2) {
		[self wearEquipment:upid part:_part target:eid2];
	}
	else {
		CCLOG(@"equipment ?");
	}
	//fix chao
	//[GameConnection post:ConnPost_roleChangeEquip object:nil];
	//end
}
-(void)wearEquipment:(int)_id target:(int)_ueid
{
	if (_id == 0 || _ueid == 0) {
		CCLOG(@"can't  = 0 ");
		return ;
	}
	NSDictionary *eq = [self getPlayerEquipInfoById:_ueid];
	if (eq) {
		int eid = [[eq objectForKey:@"eid"] intValue];
		if (eid != 0) {
			NSDictionary *db_eq = [[GameDB shared] getEquipmentInfo:eid];
			if (db_eq) {
				int _part = [[db_eq objectForKey:@"part"] intValue];
				[self wearEquipment:_id part:_part target:_ueid];
			}
			else {
				CCLOG(@"wearEquipment db_eq is null");
			}
		}
		else {
			CCLOG(@"wearEquipment eid == 0");
		}
	}
}
-(void)updateArmLevel:(int)_urid level:(int)_level
{
	NSArray *rlist = [self getPlayerRoleList];
	NSMutableArray *mlist = [NSMutableArray arrayWithArray:rlist];
	for (NSDictionary *dict in mlist) {
		int _value = [[dict objectForKey:@"id"] intValue];
		if (_value == _urid) {//-----
			NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dict];
			[temp setObject:[NSNumber numberWithInt:_level] forKey:@"armLevel"];
			[mlist removeObject:dict];//删除一个
			[mlist addObject:temp];//添加一个
			break;
		}
	}
	[self addData:mlist key:@"roles"];//刷新列表
}
-(void)activePlayerRoleSkillWithType:(int)_urid type:(int)_type
{
	NSArray *rlist = [self getPlayerRoleList];
	int active = 0 ;
	for (NSDictionary *dict in rlist) {
		int _value = [[dict objectForKey:@"id"] intValue];
		if (_value == _urid) {
			int _rid = [[dict objectForKey:@"rid"] intValue];
			NSDictionary *role = [[GameDB shared] getRoleInfo:_rid];
			if (role) {
				if (_type == 0) {
					active = [[role objectForKey:@"sk2"] intValue];
				}
				else if (_type == 1) {
					int aid = [[role objectForKey:@"armId"] intValue];
					NSDictionary *arm = [[GameDB shared] getArmInfo:aid];
					if (arm) {
						active = [[arm objectForKey:@"sk1"] intValue];
					}
				}
				else if (_type == 2) {
					int aid = [[role objectForKey:@"armId"] intValue];
					NSDictionary *arm = [[GameDB shared] getArmInfo:aid];
					if (arm) {
						active = [[arm objectForKey:@"sk2"] intValue];
					}
				}
			}
			break;
		}
	}
	if (active == 0) {
		CCLOG(@"active failed!");
		return ;
	}
	[self activePlayerRoleSkillWithId:_urid sid:active];
}
-(void)activePlayerRoleSkillWithId:(int)_urid sid:(int)_sid
{
	if (_urid == 0 || _sid == 0) {
		CCLOG(@"_urid == 0 || _sid == 0");
		return ;
	}
	
	NSArray *rlist = [self getPlayerRoleList];
	NSMutableArray *mlist = [NSMutableArray arrayWithArray:rlist];
	for (NSDictionary *dict in mlist) {
		int _value = [[dict objectForKey:@"id"] intValue];
		if (_value == _urid) {//-----
			NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dict];
			[temp setObject:[NSNumber numberWithInt:_sid] forKey:@"sk"];
			[mlist removeObject:dict];//删除一个
			[mlist addObject:temp];//添加一个
			break;
		}
	}
	[self addData:mlist key:@"roles"];//刷新列表
}
-(NSArray *)addPlayerRole:(NSDictionary *)_dict
{
    NSArray* pList = [self getPlayerRoleList];
    NSMutableArray *temp = [NSMutableArray arrayWithArray:pList];
    if (_dict) {
		
		NSDictionary * target = nil;
		int rid = [[_dict objectForKey:@"rid"] intValue];
		for(NSDictionary * role in temp){
			int rid_ = [[role objectForKey:@"rid"] intValue];
			if(rid==rid_){
				target = role;
			}
		}
		if(target){
			[temp removeObject:target];
		}
		
        [temp addObject:_dict];
        [self addData:temp key:@"roles"];
    } else {
        CCLOG(@"add player role is nil");
    }
    return temp;
}
-(void)updatePlayerRoleWithId:(int)_id status:(int)_status
{
    NSArray *array = (NSMutableArray *)[self getPlayerRoleList];
    NSMutableArray *list = [NSMutableArray arrayWithArray:array];
    if (list) {
        for (NSDictionary *dict in list) {
            int _value = [[dict objectForKey:@"id"] intValue];
            if (_value == _id) {
                NSMutableDictionary *t_dict = [NSMutableDictionary dictionaryWithDictionary:dict];
                [t_dict setObject:[NSNumber numberWithInt:_status] forKey:@"status"];
                [list removeObject:dict];
                [list addObject:t_dict];
                break;
            }
        }
        [self addData:list key:@"roles"];
		//
		[GameConnection post:ConnPost_updateRolelist object:nil];
    }
}
/*
 *角色穿戴装备
 */
-(void)wearEquipment:(int)upid part:(int)_part target:(int)ueid
{
	if (_part == 0 || _part > 6) {
		CCLOG(@"can't get part in role! _part=%d",_part);
		return ;
	}
	NSArray *rlist = [self getPlayerRoleList];
	NSMutableArray *mlist = [NSMutableArray arrayWithArray:rlist];
	for (NSDictionary *dict in mlist) {
		int _value = [[dict objectForKey:@"id"] intValue];
		if (_value == upid) {//-----
			NSString *key = [NSString stringWithFormat:@"eq%d",_part];
			NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dict];
			[temp setObject:[NSNumber numberWithInt:ueid] forKey:key];
			[mlist removeObject:dict];//删除一个
			[mlist addObject:temp];//添加一个
			//fix chao
			[self updateEquipment:ueid type:EquipmentStatus_used];
			//end

			break;
		}
	}
	[self addData:mlist key:@"roles"];//刷新列表
	//fix chao
	//[GameConnection post:ConnPost_roleChangeEquip object:nil];
	//end
}

//dict 
-(NSDictionary*)compareEqiutForShift:(NSDictionary *)_dict
{
	if (!_dict) {
		return nil;
	}
	int _src_eid = [[_dict objectForKey:@"eid"] intValue];
	
	//soul
	NSDictionary *equipment = [[GameDB shared] getEquipmentInfo:_src_eid];
	
	int _src_part = [[equipment objectForKey:@"part"] intValue];
	int _src_sid = [[equipment objectForKey:@"sid"] intValue];
	
	//soul
	NSDictionary *equipmentSet = [[GameDB shared] getEquipmentSetInfo:_src_sid];
	
	int _src_lv = [[equipmentSet objectForKey:@"lv"] intValue];
	int _src_quality = [[equipmentSet objectForKey:@"quality"] intValue];
	
	
	NSMutableArray *shift_array = [NSMutableArray array];
	
	NSArray *arr = [self getPlayerEquipmentList];
	
	int _top_lv = 0 ;
	for (NSMutableDictionary *_equip in arr) {
		int _des_eid = [[_equip objectForKey:@"eid"] intValue];
		int _des_use = [[_equip objectForKey:@"used"] intValue];
		if (_des_use == EquipmentStatus_unused) {
			//soul
			NSDictionary *equipment2 = [[GameDB shared] getEquipmentInfo:_des_eid];
			
			int _des_part = [[equipment2 objectForKey:@"part"] intValue];
			int _des_sid = [[equipment2 objectForKey:@"sid"] intValue];
			int _des_limit = [[equipment2 objectForKey:@"limit"] intValue];
			
			if (_des_part == _src_part && [self getPlayerLevel] >= _des_limit) {//部位相等比较//并且玩家的等级已经达到要求
				//soul
				//NSDictionary *des_equipmentSet = [self getEquipSetById:_des_sid];//目标套装
				NSDictionary *des_equipmentSet = [[GameDB shared] getEquipmentSetInfo:_des_sid];
				int _des_lv = [[des_equipmentSet objectForKey:@"lv"] intValue];//目标套装自身等级
				int _des_quality = [[des_equipmentSet objectForKey:@"quality"] intValue];//目标要装品质
				if ((_des_quality >= _src_quality)&&(_des_lv >= _src_lv)) {//品质 和 物品等级都OK
					if (_des_lv > _top_lv) {
						_top_lv = _des_lv;//目前最好的等级
					}
					[shift_array addObject:_equip];//加入可以换的队列
				}
			}
			
		}
	}
	if (shift_array.count > 0) {
		//在可以换的队列当中选择最合适的
		NSMutableArray *shift_array_quality = [NSMutableArray array];
		int _top_quality = 0;
		
		for (NSDictionary *best_lv in shift_array) {
			int _eid = [[best_lv objectForKey:@"eid"] intValue];
			//soul
			//NSDictionary *equipInfo = [self getEquipById:_eid];
			NSDictionary *equipInfo = [[GameDB shared] getEquipmentInfo:_eid];
			
			int _sid = [[equipInfo objectForKey:@"sid"] intValue];
			//NSDictionary *equipSet = [self getEquipSetById:_sid];
			//soul
			NSDictionary *equipSet = [[GameDB shared] getEquipmentSetInfo:_sid ];
			
			int _lv = [[equipSet objectForKey:@"lv"] intValue];
			int _quality = [[equipSet objectForKey:@"quality"] intValue];
			if (_top_lv == _lv) {
				if (_quality > _top_quality) {
					_top_quality = _quality;
				}
				[shift_array_quality addObject:best_lv];//加入可以换的队列,最高等级的那个数组,最少一个
			}
		}
		
		for (NSDictionary *best in shift_array_quality) {
			int _eid = [[best objectForKey:@"eid"] intValue];
			//soul
			//NSDictionary *equipInfo = [self getEquipById:_eid];
			NSDictionary *equipInfo = [[GameDB shared] getEquipmentInfo:_eid];
			
			int _sid = [[equipInfo objectForKey:@"sid"] intValue];
			//NSDictionary *equipSet = [self getEquipSetById:_sid];
			//soul
			NSDictionary *equipSet = [[GameDB shared] getEquipmentSetInfo:_sid];
			int _quality = [[equipSet objectForKey:@"quality"] intValue];
			if (_quality == _top_quality) {
				return best;//就是这个
			}
		}
	}
	return nil;
}
/*
 * 玩家物品数据
 */
-(NSDictionary*)getPlayerItemInfoById:(int)_id
{
	NSArray *array = [self getPlayerItemList];
	for (NSDictionary *dict in array) {
		int new_id = [[dict objectForKey:@"id"] intValue];
		if (new_id == _id) {
			return dict;
		}
	}
	return nil;
}
/*
 *玩家身上的物品列表
 */
-(NSArray*)getPlayerItemList
{
	NSDictionary *ilist = [self getDataBykey:@"ilist"];
	NSArray *elist = [ilist objectForKey:@"item"];
	if (elist) {
		return elist;
	}
	else {
		CCLOG(@"getPlayerEquipmentList return nil");
		return [NSArray array];
	}
}
/*
 * 玩家命格表拿数据
 */
-(NSDictionary*)getPlayerFateInfoById:(int)_id
{
	NSArray *array = [self getPlayerFateList];
	for (NSDictionary *dict in array) {
		int new_id = [[dict objectForKey:@"id"] intValue];
		if (new_id == _id) {
			return dict;
		}
	}
	return nil;
}

/*
 *玩家身上的物品列表
 */
-(NSArray*)getPlayerFateList
{
	NSDictionary *ilist = [self getDataBykey:@"ilist"];
	NSArray *elist = [ilist objectForKey:@"fate"];
	if (elist) {
		return elist;
	}
	else {
		CCLOG(@"getPlayerEquipmentList return nil");
		return [NSArray array];
	}
	return [NSArray array];
}

-(void)recordPlayerSetting:(NSString *)_key value:(id)_value
{
	int _pid = [[[[GameConfigure shared] getPlayerInfo] objectForKey:@"id"] intValue];
	
	_key = [_key stringByAppendingFormat:@"+%d",_pid];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:_value forKey:_key];
	[defaults synchronize];
	
	
	//[self addLocalData:_value key:_key];
}
-(NSDictionary*)getPlayerRecord
{
	return [self getLocalData];
}
-(id)getPlayerRecord:(NSString *)_key
{
	int _pid = [[[[GameConfigure shared] getPlayerInfo] objectForKey:@"id"] intValue];
	
	_key = [_key stringByAppendingFormat:@"+%d",_pid];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:_key];
	
	//return [[self getPlayerRecord] objectForKey:_key];
}

#pragma mark package

-(NSArray*)handlingItems:(NSArray*)_array{
	NSMutableArray *array = [NSMutableArray array];
	for (NSDictionary *dict in  _array) {
		int _uiid = [[dict objectForKey:@"id"] intValue];
		NSDictionary *info = [self getPlayerItemInfoById:_uiid];
		if (info) {
			
		}else{
			
		}
	}
	return array;
}
/*
 *key -> id
 *value -> count
 */
-(NSDictionary*)handleItemsInfo:(NSArray*)items{
	
	if (!items) {
		return nil;
	}
	//key ->iid value ->count
	NSMutableDictionary *infos = [NSMutableDictionary dictionary];
	
	for (NSDictionary *dict in items) {
		int _uid = [[dict objectForKey:@"id"] intValue];
		int iid = [[dict objectForKey:@"iid"] intValue];
		int count = [[dict objectForKey:@"count"] intValue];
		
		NSDictionary *src = [self getPlayerItemInfoById:_uid];
		
		if (src) {
			int count1 = [[src objectForKey:@"count"] intValue];
			int result = count - count1 ;
			//---------------------------------------------------
			NSArray *iKeys = [infos allKeys];
			NSString *nKey = [NSString stringWithFormat:@"%d",iid];
			if ([iKeys containsObject:nKey]) {
				int temp = [[infos objectForKey:nKey] intValue];
				temp += result;
				[infos setObject:[NSNumber numberWithInt:temp] forKey:nKey];
			}else{
				[infos setObject:[NSNumber numberWithInt:result] forKey:nKey];
			}
			//---------------------------------------------------
		}else{
			//---------------------------------------------------
			NSArray *iKeys = [infos allKeys];
			NSString *nKey = [NSString stringWithFormat:@"%d",iid];
			if ([iKeys containsObject:nKey]) {
				int temp = [[infos objectForKey:nKey] intValue];
				temp += count;
				[infos setObject:[NSNumber numberWithInt:temp] forKey:nKey];
			}else{
				[infos setObject:[NSNumber numberWithInt:count] forKey:nKey];
			}
			//---------------------------------------------------
		}
	}
	return infos;
}
/*
 *key -> id
 *value -> count
 */
-(NSDictionary*)handleEquipsInfo:(NSArray*)equips{
	
	if (!equips) {
		return nil;
	}
	//key ->eid value ->count
	NSMutableDictionary *infos = [NSMutableDictionary dictionary];
	
	for (NSDictionary *dict in equips) {
		int _uid = [[dict objectForKey:@"id"] intValue];
		int eid = [[dict objectForKey:@"eid"] intValue];
		
		NSDictionary *src = [self getPlayerEquipInfoById:_uid];
		
		if (!src) {
			// 装备堆叠为1
			int count = 1;
			//---------------------------------------------------
			NSArray *iKeys = [infos allKeys];
			NSString *nKey = [NSString stringWithFormat:@"%d",eid];
			if ([iKeys containsObject:nKey]) {
				int temp = [[infos objectForKey:nKey] intValue];
				temp += count;
				[infos setObject:[NSNumber numberWithInt:temp] forKey:nKey];
			}else{
				[infos setObject:[NSNumber numberWithInt:count] forKey:nKey];
			}
			//---------------------------------------------------
		}
	}
	return infos;
}


-(NSDictionary*)handleRolesInfo:(NSArray*)role{
	if (!role) {
		return nil;
	}
	int rid=0;
	NSMutableDictionary *rerole=[NSMutableDictionary dictionary];
	for(NSDictionary *dict in role){
		 rid=[[dict objectForKey:@"rid"]intValue];
	}
	/*
	NSDictionary *roledict=[[GameDB shared]getRoleInfo:rid];
	[rerole setValue:@"1" forKey:@"count"];
	[rerole setValue:[roledict objectForKey:@"name"]  forKey:@"count"];
	[rerole setValue:[roledict objectForKey:@"quality"]  forKey:@"quality"];
	 */
	[rerole setValue:@"1" forKey:[NSString stringWithFormat:@"%i",rid]];
	return  rerole;
}
/*
 *key -> id
 *value -> count
 */
-(NSDictionary*)handleFatesInfo:(NSArray*)fates{
	
	if (!fates) {
		return nil;
	}
	//key ->fid value ->count
	NSMutableDictionary *infos = [NSMutableDictionary dictionary];
	
	for (NSDictionary *dict in fates) {
		int _uid = [[dict objectForKey:@"id"] intValue];
		int fid = [[dict objectForKey:@"fid"] intValue];
		
		NSDictionary *src = [self getPlayerFateInfoById:_uid];
		
		if (!src) {
			// 命格堆叠为1
			int count = 1;
			//---------------------------------------------------
			NSArray *iKeys = [infos allKeys];
			NSString *nKey = [NSString stringWithFormat:@"%d",fid];
			if ([iKeys containsObject:nKey]) {
				int temp = [[infos objectForKey:nKey] intValue];
				temp += count;
				[infos setObject:[NSNumber numberWithInt:temp] forKey:nKey];
			}else{
				[infos setObject:[NSNumber numberWithInt:count] forKey:nKey];
			}
			//---------------------------------------------------
		}
	}
	return infos;
}
/*
 *key -> id
 *value -> count
 */
-(NSDictionary*)handleCarsInfo:(NSArray*)cars{
	
	if (!cars) {
		return nil;
	}
	//key ->cid value ->count
	NSMutableDictionary *infos = [NSMutableDictionary dictionary];
	
	for (NSDictionary *dict in cars) {
		int _uid = [[dict objectForKey:@"id"] intValue];
		int cid = [[dict objectForKey:@"cid"] intValue];
		
		NSDictionary *src = [self getPlayerCarInfoById:_uid];
		
		if (!src) {
			// 坐骑堆叠为1
			int count = 1;
			//---------------------------------------------------
			NSArray *iKeys = [infos allKeys];
			NSString *nKey = [NSString stringWithFormat:@"%d",cid];
			if ([iKeys containsObject:nKey]) {
				int temp = [[infos objectForKey:nKey] intValue];
				temp += count;
				[infos setObject:[NSNumber numberWithInt:temp] forKey:nKey];
			}else{
				[infos setObject:[NSNumber numberWithInt:count] forKey:nKey];
			}
			//---------------------------------------------------
		}
	}
	return infos;
}

-(NSDictionary*)handleGemsInfo:(NSArray*)gems{
	
	if (!gems) {
		return nil;
	}
	
	NSMutableDictionary *infos = [NSMutableDictionary dictionary];
	
	for (NSDictionary *dict in gems) {
		int _uid = [[dict objectForKey:@"id"] intValue];
		int gid = [[dict objectForKey:@"gid"] intValue];
		
		NSDictionary *src = [self getPlayerJewelInfoById:_uid];
		
		if (!src) {
			// 珠宝堆叠为1
			int count = 1;
			//---------------------------------------------------
			NSArray *iKeys = [infos allKeys];
			NSString *nKey = [NSString stringWithFormat:@"%d",gid];
			if ([iKeys containsObject:nKey]) {
				int temp = [[infos objectForKey:nKey] intValue];
				temp += count;
				[infos setObject:[NSNumber numberWithInt:temp] forKey:nKey];
			}else{
				[infos setObject:[NSNumber numberWithInt:count] forKey:nKey];
			}
			//---------------------------------------------------
		}
	}
	return infos;
}
/*

-(NSDictionary*)handleRolesInfo:(NSArray*)roles{
	
	if (!roles) {
		return nil;
	}
	
	NSMutableDictionary *infos = [NSMutableDictionary dictionary];
	
	for (NSDictionary *dict in roles) {
		int _uid = [[dict objectForKey:@"id"] intValue];
		int rid = [[dict objectForKey:@"rid"] intValue];
		
		NSDictionary *src = [self getRoleById:_uid];
		
		if (!src) {
			// 角色堆叠为1
			int count = 1;
			//---------------------------------------------------
			NSArray *iKeys = [infos allKeys];
			NSString *nKey = [NSString stringWithFormat:@"%d",rid];
			if ([iKeys containsObject:nKey]) {
				int temp = [[infos objectForKey:nKey] intValue];
				temp += count;
				[infos setObject:[NSNumber numberWithInt:temp] forKey:nKey];
			}else{
				[infos setObject:[NSNumber numberWithInt:count] forKey:nKey];
			}
			//---------------------------------------------------
		}
		
	}
	return infos;
}

*/
/*
 * 返回dictionary数组
 * dictionary allkeys-> @"name" @"count" @"quality"(可选) 
 */
-(NSArray*)getPackageItemTips:(NSDictionary*)dict :(PackageItemType)type
{
	if (!dict) {
		return nil;
	}
	NSMutableArray *_array = [NSMutableArray array];
	NSArray *keys = [dict allKeys];
	for (NSString *key in keys) {
		int _id = [key intValue];
		int _count = [[dict objectForKey:key] intValue];
		NSString *name = nil;
		int quality = -1;
		int rid=-1;
		switch (type) {
			//case PackageItem_coin1:{name = @"银币";}
            case PackageItem_coin1:{name = NSLocalizedString(@"configure_coin1",nil);}
				break;
			//case PackageItem_coin2:{name = @"元宝";}
            case PackageItem_coin2:{name = NSLocalizedString(@"configure_coin2",nil);}
				break;
			//case PackageItem_coin3:{name = @"绑元宝";}
            case PackageItem_coin3:{name = NSLocalizedString(@"configure_coin3",nil);}
				break;
			//case PackageItem_exp:{name = @"经验";}
            case PackageItem_exp:{name = NSLocalizedString(@"configure_exp",nil);}
				break;
			//case PackageItem_train:{name = @"炼历";}
            case PackageItem_train:{name = NSLocalizedString(@"configure_train",nil);}
				break;
			case PackageItem_equip:
			{
				NSDictionary *equipDict = [[GameDB shared] getEquipmentInfo:_id];
				if (equipDict) {
					name = [equipDict objectForKey:@"name"];
					int sid = [[equipDict objectForKey:@"sid"] intValue];
					NSDictionary *equipSetDict = [[GameDB shared] getEquipmentSetInfo:sid];
					if (equipSetDict) {
						quality = [[equipSetDict objectForKey:@"quality"] intValue];
					}
				}
			}
				break;
			case PackageItem_item:
			{
				NSDictionary *itemDict = [[GameDB shared] getItemInfo:_id];
				if (itemDict) {
					name = [itemDict objectForKey:@"name"];
					quality = [[itemDict objectForKey:@"quality"] intValue];
				}
			}
				break;
			case PackageItem_fate:
			{
				NSDictionary *fateDict = [[GameDB shared] getFateInfo:_id];
				if (fateDict) {
					name = [fateDict objectForKey:@"name"];
					quality = [[fateDict objectForKey:@"quality"] intValue];
				}
			}
				break;
			case PackageItem_car:
			{
				NSDictionary *carDict = [[GameDB shared] getCarInfo:_id];
				if (carDict) {
					name = [carDict objectForKey:@"name"];
					quality = [[carDict objectForKey:@"quality"] intValue];
				}
			}
				break;
			case PackageItem_gem:
			{
				NSDictionary *gemDict = [[GameDB shared] getJewelInfo:_id];
				if (gemDict) {
					name = [gemDict objectForKey:@"name"];
					quality = [[gemDict objectForKey:@"quality"] intValue];
				}
			}
				break;
			case PackageItem_role:
			{
				NSDictionary *roleDict = [[GameDB shared] getRoleInfo:_id];
				if (roleDict) {
					name = [roleDict objectForKey:@"name"];
					quality = [[roleDict objectForKey:@"quality"] intValue];
					rid=_id;
				}
			}
				break;
				
			default:
				break;
		}
		NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
		[tempDict setObject:name forKey:@"name"];
		[tempDict setObject:[NSNumber numberWithInt:_count] forKey:@"count"];
		if (quality != -1) {
			[tempDict setObject:[NSNumber numberWithInt:quality] forKey:@"quality"];
		}
		if(rid!=-1){
			[tempDict setObject:[NSNumber numberWithInt:rid] forKey:@"rid"];
		}
		[_array addObject:tempDict];
	}
	return _array;
}

//
//标记玩家的属性
//暂时用于记录玩家的经验
//
-(void)markPlayerProperty{
	NSDictionary* player = [self getPlayerInfo];
	if (player) {
		s_PlayerLevel = [[player objectForKey:@"level"] intValue];
		s_PlayerExp = [[player objectForKey:@"exp"] intValue];
	}
}

-(NSArray*)getPackageAddDataWithServer:(NSArray*)array
{
	NSMutableArray* result = [NSMutableArray array];
	if (array == nil) {
		CCLOG(@"getPackageAddDataWithServer->array->is nil!");
		return result ;
	}
	
	for (NSDictionary *item in array) {
		
		int iid = [[item objectForKey:@"i"] intValue];
		int count = [[item objectForKey:@"c"] intValue];
		int quality = -1 ;
		NSString *type = [item objectForKey:@"t"];		
		NSDictionary *itemInfo = nil;
		
		// 物品
		if ([@"i" isEqualToString:type]) {
			//7 是 物品表中开启时光盒怪物的物品ID，这里不给显示，直接写死
			if (iid != 7) {
				
				int _iid = iid;
				// 打坐经验转为经验显示
				if (iid == 5) {
					_iid = 4;
					
					int level = [[GameConfigure shared] getPlayerLevel];
					NSDictionary* levelInfo = [[GameDB shared] getRoleExpInfo:level];
					int siteExp = [[levelInfo objectForKey:@"siteExp"] intValue];
					count *= siteExp;
				}
				
				itemInfo = [[GameDB shared] getItemInfo:_iid];
				if (itemInfo) {
					quality = [[itemInfo objectForKey:@"quality"] intValue];
					if (quality <= 0) {
						quality = -1 ;
					}
				}
			}
		}
		
		// 装备
		else if ([@"e" isEqualToString:type]) {
			itemInfo = [[GameDB shared] getEquipmentInfo:iid];
			if (itemInfo) {
				int sid = [[itemInfo objectForKey:@"sid"] intValue];
				NSDictionary *equipSetDict = [[GameDB shared] getEquipmentSetInfo:sid];
				if (equipSetDict) {
					quality = [[equipSetDict objectForKey:@"quality"] intValue];
				}
			}
		}
		
		// 命格
		else if ([@"f" isEqualToString:type]) {
			itemInfo = [[GameDB shared] getFateInfo:iid];
			if (itemInfo) {
				quality = [[itemInfo objectForKey:@"quality"] intValue];
			}
		}
		// 坐骑
		else if ([@"c" isEqualToString:type]) {
			itemInfo = [[GameDB shared] getCarInfo:iid];
			if (itemInfo) {
				quality = [[itemInfo objectForKey:@"quality"] intValue];
			}
		}
		// 配将
		else if ([@"r" isEqualToString:type]) {
			itemInfo = [[GameDB shared] getRoleInfo:iid];
			if (itemInfo) {
				quality = [[itemInfo objectForKey:@"quality"] intValue];
			}
		}
		
		if (itemInfo != nil) {
			NSString* _name = [itemInfo objectForKey:@"name"];
			if (_name != nil) {
				NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
				[tempDict setObject:_name forKey:@"name"];
				[tempDict setObject:[NSNumber numberWithInt:count] forKey:@"count"];
				if (quality > 0) {
					[tempDict setObject:[NSNumber numberWithInt:quality] forKey:@"quality"];
				}
				[result addObject:tempDict];
			}
		}
		
	}
	
	return result;
}

-(NSArray*)getPackageAddData:(NSDictionary *)dict
{
	return [self getPackageAddData:dict type:PackageItem_all isAdd:NO];
}
-(NSArray*)getPackageAddData:(NSDictionary *)dict type:(PackageItemType)type
{
	return [self getPackageAddData:dict type:type isAdd:NO];
}
-(NSArray*)getPackageAddData:(NSDictionary *)dict isAdd:(BOOL)isAdd
{
	return [self getPackageAddData:dict type:PackageItem_all isAdd:isAdd];
}
/* 
 * 添加的物品信息
 * 包含银币、元宝、绑定元宝、经验历练、装备、物品、命格、坐骑、珠宝、角色
 *
 * 返回dictionary数组
 * dictionary allkeys-> @"name" @"count" @"quality"(可选)
 */
-(NSArray*)getPackageAddData:(NSDictionary *)dict type:(PackageItemType)type isAdd:(BOOL)isAdd
{
	//先存起来
	PackageItemType ____temp_type = type ;
	
	if (type == PackageItem_all_excluding_exp) {
		type = PackageItem_all;
	}
	
	if (dict) {
		NSMutableArray *addDataArray = [NSMutableArray array];
		
		NSArray *keys = [dict allKeys];
		if ([keys containsObject:@"coin1"] && (type == PackageItem_coin1 || type == PackageItem_all)) {
			int t_num = [[dict objectForKey:@"coin1"] intValue] - [self getPlayerMoney];
			if ((isAdd && t_num > 0) || (!isAdd && t_num != 0)) {
				NSDictionary *t_dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:t_num] forKey:@"coin1"];
				[addDataArray addObjectsFromArray:[self getPackageItemTips:t_dict :PackageItem_coin1]];
			}
		}
		if ([keys containsObject:@"coin2"] && (type == PackageItem_coin2 || type == PackageItem_all)) {//更新元宝
			int t_num = [[dict objectForKey:@"coin2"] intValue] - [self getPlayerCoin2];
			if ((isAdd && t_num > 0) || (!isAdd && t_num != 0)) {
				NSDictionary *t_dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:t_num] forKey:@"coin2"];
				[addDataArray addObjectsFromArray:[self getPackageItemTips:t_dict :PackageItem_coin2]];
			}
		}
		if ([keys containsObject:@"coin3"] && (type == PackageItem_coin3 || type == PackageItem_all)) {//更新绑定元宝
			int t_num = [[dict objectForKey:@"coin3"] intValue] - [self getPlayerCoin3];
			if ((isAdd && t_num > 0) || (!isAdd && t_num != 0)) {
				NSDictionary *t_dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:t_num] forKey:@"coin3"];
				[addDataArray addObjectsFromArray:[self getPackageItemTips:t_dict :PackageItem_coin3]];
			}
		}
		if ([keys containsObject:@"exp"] && (type == PackageItem_exp || type == PackageItem_all)) {//更新经验
			int t_num = [[dict objectForKey:@"exp"] intValue] - [self getPlayerExp];
			//todo 这里先屏蔽经验为0的情况
			if (____temp_type == PackageItem_all_excluding_exp) {
				//not thing to do !!
			}else{
				
				if (s_PlayerExp != -1 && s_PlayerLevel != -1 && [self getPlayerLevel] > s_PlayerLevel) {
					NSDictionary *next_expLevel = [[GameDB shared] getRoleExpInfo:s_PlayerLevel+1];
					int nextLevelExp = [[next_expLevel objectForKey:@"exp"] intValue];
					int _Exp = nextLevelExp - s_PlayerExp ;
					_Exp = _Exp + [[dict objectForKey:@"exp"] intValue];
					
					NSDictionary *t_dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:_Exp] forKey:@"exp"];
					[addDataArray addObjectsFromArray:[self getPackageItemTips:t_dict :PackageItem_exp]];
					
					s_PlayerExp = -1 ;
					s_PlayerLevel = -1 ;
					
				}else{
					NSDictionary *t_dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:t_num] forKey:@"exp"];
					[addDataArray addObjectsFromArray:[self getPackageItemTips:t_dict :PackageItem_exp]];
				}
				
			}
		}
		if ([keys containsObject:@"train"] && (type == PackageItem_train || type == PackageItem_all)) {//更新历练
			int t_num = [[dict objectForKey:@"train"] intValue] - [self getPlayerTrain];
			NSDictionary *t_dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:t_num] forKey:@"train"];
			[addDataArray addObjectsFromArray:[self getPackageItemTips:t_dict :PackageItem_train]];
		}
		if ([keys containsObject:@"equip"] && (type == PackageItem_equip || type == PackageItem_all)) {//装备
			NSArray *array = [dict objectForKey:@"equip"];
			NSDictionary *equip=[self handleEquipsInfo:array];
			[addDataArray addObjectsFromArray:[self getPackageItemTips:equip :PackageItem_equip]];
		}
		if ([keys containsObject:@"item"] && (type == PackageItem_item || type == PackageItem_all)) {//物品
			NSArray *array = [dict objectForKey:@"item"];
			NSDictionary *item=[self handleItemsInfo:array];
			[addDataArray addObjectsFromArray:[self getPackageItemTips:item :PackageItem_item]];
		}
		if ([keys containsObject:@"fate"] && (type == PackageItem_fate || type == PackageItem_all)) {//命格
			NSArray *array = [dict objectForKey:@"fate"];
			NSDictionary *fate=[self handleFatesInfo:array];
			[addDataArray addObjectsFromArray:[self getPackageItemTips:fate :PackageItem_fate]];
		}
		if ([keys containsObject:@"car"] && (type == PackageItem_car || type == PackageItem_all)) {//坐骑
			NSArray *array = [dict objectForKey:@"car"];
			NSDictionary *car=[self handleCarsInfo:array];
			[addDataArray addObjectsFromArray:[self getPackageItemTips:car :PackageItem_car]];
		}

		if([keys containsObject:@"role"] && (type == PackageItem_role || type == PackageItem_all)){//配将
			NSArray *array = [dict objectForKey:@"role"];
			NSDictionary *role=[self handleRolesInfo:array];
			[addDataArray addObjectsFromArray:[self getPackageItemTips:role :PackageItem_role]];
		}

		if ([keys containsObject:@"gem"] && (type == PackageItem_gem || type == PackageItem_all)) {//珠宝
			NSArray *array = [dict objectForKey:@"gem"];
			NSDictionary *gem = [self handleGemsInfo:array];
			[addDataArray addObjectsFromArray:[self getPackageItemTips:gem :PackageItem_gem]];
		}
		
		s_PlayerLevel = -1 ;
		s_PlayerExp = -1 ;
		
		return addDataArray.count > 0 ? addDataArray : nil;
	}
	
	s_PlayerLevel = -1 ;
	s_PlayerExp = -1 ;
	return nil;
}

/*
 *根据服务器协议返回 修改本地的物品
 */
-(void)updatePackage:(NSDictionary *)dict
{
	//2012-12-24
	//TODO
	if (dict) {
		NSArray *keys = [dict allKeys];
		//---------------------------------------------
		//更新玩家数据
		//---------------------------------------------
		//[self handleItemsInfo:[dict objectForKey:@""]];
		NSMutableDictionary *player = [NSMutableDictionary dictionaryWithDictionary:[self getPlayerInfo]];
		if (player) {
			CCLOG([player description]);
			BOOL bUpdate = NO;
			
			if ([keys containsObject:@"coin1"]) {//更新银币
				CCLOG(@"update coin1");
				[player setObject:[dict objectForKey:@"coin1"] forKey:@"coin1"];
				bUpdate = YES;
			}
			if ([keys containsObject:@"coin2"]) {//更新元宝
				CCLOG(@"update coin2");
				[player setObject:[dict objectForKey:@"coin2"] forKey:@"coin2"];
				bUpdate = YES;
			}
			if ([keys containsObject:@"coin3"]) {//更新绑定元宝
				CCLOG(@"update coin3");
				[player setObject:[dict objectForKey:@"coin3"] forKey:@"coin3"];
				bUpdate = YES;
			}
			if ([keys containsObject:@"exp"]) {//更新经验
				CCLOG(@"update exp");
				[player setObject:[dict objectForKey:@"exp"] forKey:@"exp"];
				bUpdate = YES;
			}
			if ([keys containsObject:@"train"]) {//更新历练
				CCLOG(@"update train");
				[player setObject:[dict objectForKey:@"train"] forKey:@"train"];
				bUpdate = YES;
				
			}
			CCLOG([player description]);
			[self addData:player key:@"player"];
			//fix chao			
//			NSArray *array = [self getPlayerList];
//			if (array) {
//				NSMutableArray *m_playersArray = [NSMutableArray arrayWithArray:array];
//			}
//			[userInfo setObject:[NSArray array] forKey:@"players"];
			//end
			if (bUpdate) {
				[GameConnection post:ConnPost_updatePlayerInfo object:nil];
			}
		}
		//--------------------------------------------
		if ([keys containsObject:@"role"]) {
			//增加配将
			//待测试
			NSMutableArray *roles = [NSMutableArray arrayWithArray:[self getPlayerRoleList]];
			NSArray *array = [dict objectForKey:@"role"];
			for (NSDictionary *iterate in array) {
				[roles addObject:iterate];
			}
			[self addData:roles key:@"roles"];
		}
		//-----------------------------------
		
		//--------------------------------------------
		//待收取物品增删改查
		NSArray *waits = [self getPlayerWaitItemList];
		if (waits){
			//----------------------------------------------------------------
			NSMutableDictionary *wait_dict = [NSMutableDictionary dictionary];
			for (NSDictionary *iterate in waits) {
				int _id = [[iterate objectForKey:@"id"] intValue];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[wait_dict setObject:iterate forKey:_key];
			}
			//----------------------------------------------------------------
			if ([keys containsObject:@"wait"]) {//增加与修改
				NSArray *array = [dict objectForKey:@"wait"];
				for (NSDictionary *iterate in array) {
					int _id = [[iterate objectForKey:@"id"] intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[wait_dict setObject:iterate forKey:_key];
				}
			}
			if ([keys containsObject:@"delWids"]) {//删除
				NSArray *array = [dict objectForKey:@"delWids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[wait_dict removeObjectForKey:_key];
				}
			}
			NSArray *wait_array = [wait_dict allValues];
			[self addData:wait_array key:@"iwait"];
		}
		//-----------------------------------
		
		NSMutableDictionary *package = [NSMutableDictionary dictionaryWithDictionary: [self getDataBykey:@"ilist"]];
		if (package) {
			CCLOG([package description]);
			//---------------------------------------------
			//转换装备dict
			//---------------------------------------------
			NSArray *elist = [package objectForKey:@"equip"];
			NSMutableDictionary *equip_dict = [NSMutableDictionary dictionary];
			for (NSDictionary *iterate in elist) {
				int _id = [[iterate objectForKey:@"id"] intValue];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[equip_dict setObject:iterate forKey:_key];
			}
			//----------------------------------------------------
			
			//---------------------------------------------
			//转换物品dict
			//---------------------------------------------
			NSArray *ilist = [package objectForKey:@"item"];
			NSMutableDictionary *item_dict = [NSMutableDictionary dictionary];
			for (NSDictionary *iterate in ilist) {
				int _id = [[iterate objectForKey:@"id"] intValue];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[item_dict setObject:iterate forKey:_key];
			}
			//----------------------------------------------------
			
			//---------------------------------------------
			//转换命格dict
			//---------------------------------------------
			NSArray *flist = [package objectForKey:@"fate"];
			NSMutableDictionary *fate_dict = [NSMutableDictionary dictionary];
			for (NSDictionary *iterate in flist) {
				int _id = [[iterate objectForKey:@"id"] intValue];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[fate_dict setObject:iterate forKey:_key];
			}
			//----------------------------------------------------
			
			//---------------------------------------------
			//转换坐骑dict
			//---------------------------------------------
			NSArray *clist = [package objectForKey:@"car"];
			NSMutableDictionary *car_dict = [NSMutableDictionary dictionary];
			for (NSDictionary *iterate in clist) {
				int _id = [[iterate objectForKey:@"id"] intValue];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[car_dict setObject:iterate forKey:_key];
			}
			//----------------------------------------------------
			
			//---------------------------------------------
			//转换珠宝dict
			//---------------------------------------------
			NSArray *glist = [package objectForKey:@"gem"];
			NSMutableDictionary *gem_dict = [NSMutableDictionary dictionary];
			for (NSDictionary *iterate in glist) {
				int _id = [[iterate objectForKey:@"id"] intValue];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[gem_dict setObject:iterate forKey:_key];
			}
			//----------------------------------------------------
			
			if ([keys containsObject:@"equip"]) {
				CCLOG(@"update equip");
				NSArray *array = [dict objectForKey:@"equip"];
				for (NSDictionary *iterate in array) {
					int _id = [[iterate objectForKey:@"id"] intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[equip_dict setObject:iterate forKey:_key];
				}
			}
			if ([keys containsObject:@"item"]) {
				CCLOG(@"update item");
				NSArray *array = [dict objectForKey:@"item"];
				for (NSDictionary *iterate in array) {
					int _id = [[iterate objectForKey:@"id"] intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[item_dict setObject:iterate forKey:_key];
				}
				
			}
			if ([keys containsObject:@"fate"]) {
				CCLOG(@"update fate");
				NSArray *array = [dict objectForKey:@"fate"];
				for (NSDictionary *iterate in array) {
					int _id = [[iterate objectForKey:@"id"] intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[fate_dict setObject:iterate forKey:_key];
				}
			}
			if ([keys containsObject:@"car"]) {
				CCLOG(@"update car");
				NSArray *array = [dict objectForKey:@"car"];
				for (NSDictionary *iterate in array) {
					int _id = [[iterate objectForKey:@"id"] intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[car_dict setObject:iterate forKey:_key];
				}
			}
			if ([keys containsObject:@"gem"]) {
				CCLOG(@"update gem");
				NSArray *array = [dict objectForKey:@"gem"];
				for (NSDictionary *iterate in array) {
					int _id = [[iterate objectForKey:@"id"] intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[gem_dict setObject:iterate forKey:_key];
				}
			}

			//---------------------------------------------
			//删除物品
			//---------------------------------------------
			if ([keys containsObject:@"delIids"]) {
				CCLOG(@"update delIids");
				NSArray *array = [dict objectForKey:@"delIids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[item_dict removeObjectForKey:_key];
				}
			}
			if ([keys containsObject:@"delEids"]) {
				CCLOG(@"update delEids");
				NSArray *array = [dict objectForKey:@"delEids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[equip_dict removeObjectForKey:_key];
				}
			}
			if ([keys containsObject:@"delFids"]) {
				CCLOG(@"update delFids");
				NSArray *array = [dict objectForKey:@"delFids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[fate_dict removeObjectForKey:_key];
				}
			}
			if ([keys containsObject:@"delCids"]) {
				CCLOG(@"update delCids");
				NSArray *array = [dict objectForKey:@"delCids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[car_dict removeObjectForKey:_key];
				}
			}
			if ([keys containsObject:@"delGids"]) {
				CCLOG(@"update delGids");
				NSArray *array = [dict objectForKey:@"delGids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[gem_dict removeObjectForKey:_key];
				}
			}
			//--------------------------------------
			NSArray *equip_array = [equip_dict allValues];
			NSArray *item_array = [item_dict allValues];
			NSArray *fate_array = [fate_dict allValues];
			NSArray *car_array = [car_dict allValues];
			NSArray *gem_array = [gem_dict allValues];
			
			[package setObject:equip_array forKey:@"equip"];
			[package setObject:item_array forKey:@"item"];
			[package setObject:fate_array forKey:@"fate"];
			[package setObject:car_array forKey:@"car"];
			[package setObject:gem_array forKey:@"gem"];
			
//			CCLOG([package description]);
			
			[self addData:package key:@"ilist"];
		}
		[GameConnection post:ConnPost_updatePackage object:dict];
	}
	
}

-(NSDictionary*)getItemUpdateData:(NSDictionary *)dict
{
	if (dict) {
		NSMutableDictionary *changeDict = [NSMutableDictionary dictionary];
		
		// 减少物品
		NSArray *delIids = [dict objectForKey:@"delIids"];
		for (int i = 0; i < delIids.count; i++) {
			int _id = [[delIids objectAtIndex:i] intValue];
			NSDictionary *playerItemDict = [[GameConfigure shared] getPlayerItemInfoById:_id];
			if (playerItemDict) {
				int count = -[[playerItemDict objectForKey:@"count"] intValue];
				int iid = [[playerItemDict objectForKey:@"iid"] intValue];
				NSString *key = [NSString stringWithFormat:@"%d", iid];
				count += [[changeDict objectForKey:key] intValue];
				[changeDict setValue:[NSNumber numberWithInt:count] forKey:key];
			}
		}
		
		// 改变物品数目（可增可减）
		NSArray *items = [dict objectForKey:@"item"];
		for (NSDictionary *itemDict in items) {
			int _id = [[itemDict objectForKey:@"id"] intValue];
			int iid = [[itemDict objectForKey:@"iid"] intValue];
			int newCount = [[itemDict objectForKey:@"count"] intValue];
			NSDictionary *playerItemDict = [[GameConfigure shared] getPlayerItemInfoById:_id];
			if (playerItemDict) {
				newCount -= [[playerItemDict objectForKey:@"count"] intValue];
			}
			NSString *key = [NSString stringWithFormat:@"%d", iid];
			newCount += [[changeDict objectForKey:key] intValue];
			[changeDict setValue:[NSNumber numberWithInt:newCount] forKey:key];
		}
		return changeDict;
	}
	return [NSMutableDictionary dictionary];
}


#pragma mark - wait item
//玩家待收取物品表拿数据
-(NSDictionary*)getPlayerWaitItemInfoById:(int)_id
{
	NSMutableDictionary * info = [NSMutableDictionary dictionary];
	[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
	[info setObject:[NSNumber numberWithInt:1] forKey:@"pid"];
	[info setObject:[NSNumber numberWithInt:PlayerWaitItemType_1] forKey:@"type"];
	[info setObject:@"{t:<f>,i:<1>,c:<1>,tr:<0>}" forKey:@"items"];	
	return info;
	
}

//玩家待收取物品表
-(NSArray*)getPlayerWaitItemList{
	NSArray *array = [self getDataBykey:@"iwait"];
	//-----------------------------------
	if (!array) {
		array = [NSMutableArray array];
	}
	//-----------------------------------
#ifdef GAME_DEBUGGER
	if (array && (array.count == 0)) {
		NSMutableArray *waitItems = [NSMutableArray array];
		for (int i =1; i<4; i++) {
			NSMutableDictionary *infos_ = (NSMutableDictionary*)[self getPlayerWaitItemInfoById:i];
			[waitItems addObject:infos_];			
		}
		return waitItems;
	}
#endif
	//----
	return array;	
}

//玩家待收取物品表 by type
-(NSArray*)getPlayerWaitItemListByType:(int)_type
{
	if (_type < PlayerWaitItemType_1 || _type > PlayerWaitItemType_4) {
		CCLOG(@"_type < 1 || _type > 4");
		return nil;
	}
	NSArray *wArray = [self getPlayerWaitItemList] ;
	NSMutableArray *array = [NSMutableArray array];
	for (NSDictionary *dict in wArray) {		
		if (_type == [[dict objectForKey:@"type"] intValue]) {
			[array addObject:dict];
		}
	}
	return array;
}
//删玩家待收取猎命
-(void)removePlayerWaitItem:(NSArray*)_idArray{
	if ([_idArray count]>0) {
		NSMutableArray *WMutArray = [NSMutableArray arrayWithArray:[self getPlayerWaitItemList]];
		for (NSNumber *idNumber in _idArray) {
			for (NSDictionary *dict in WMutArray) {
				if ( [idNumber intValue] == [[dict objectForKey:@"id"] intValue] ) {
					[WMutArray removeObject:dict];
					break;
				}
			}
		}
		[self addData:WMutArray key:@"iwait"];
	}else{
		CCLOG(@"id array error");
	}
}
//加玩家待收取猎命
-(void)addPlayerWaitItem:(NSArray*)_idDictArray{
	if ([_idDictArray count]>0) {		
		NSMutableArray *WMutArray = [NSMutableArray arrayWithArray:[self getPlayerWaitItemList]];
		[WMutArray addObjectsFromArray:_idDictArray];
		[self addData:WMutArray key:@"iwait"];
	}else{
		CCLOG(@"id dict array error");
	}
}
/*
 * 玩家坐骑
 */
-(NSDictionary*)getPlayerCarInfoById:(int)_id
{
	NSArray *array = [self getPlayerCarList];
	for (NSDictionary *dict in array) {
		int new_id = [[dict objectForKey:@"id"] intValue];
		if (new_id == _id) {
			return dict;
		}
	}
	return nil;
}

// 同盟列表
/*
-(NSDictionary *)getGroupById:(int)_id
{
    NSMutableDictionary *group = [NSMutableDictionary dictionary];
    [group setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
    [group setObject:@"斧头帮" forKey:@"name"];
    [group setObject:[NSNumber numberWithInt:1] forKey:@"mainId"];
    [group setObject:[NSNumber numberWithInt:2] forKey:@"subid"];
    [group setObject:[NSNumber numberWithInt:1] forKey:@"level"];
    [group setObject:[NSNumber numberWithInt:300] forKey:@"contrib"];
    [group setObject:[NSNumber numberWithInt:1] forKey:@"createPid"];
    [group setObject:[NSDate date] forKey:@"createTime"];
    [group setObject:[NSNumber numberWithInt:1] forKey:@"postId"];
    
    return group;
}

-(NSMutableArray *)getGroupList
{
    NSMutableArray *groups = [self getDataBykey:@"_group_list"];
	if(!groups || YES){
        groups = [NSMutableArray array];
		//TEST
		for (int i = 0 ; i < 5; i++) {
			
			NSMutableDictionary *infos_ = (NSMutableDictionary*)[self getGroupById:i];
			
			if (i == 2) {
				[infos_ setObject:@"帅哥协会" forKey:@"name"];
			}
			
			[groups addObject:infos_];
		}
		[self addData:groups key:@"_group_list"];
	}
	return groups;
}

-(NSDictionary *)getGroupPlayerById:(int)_gid
{
    NSMutableDictionary *groupPlayer = [NSMutableDictionary dictionary];
    [groupPlayer setObject:[NSNumber numberWithInt:1] forKey:@"id"];
    [groupPlayer setObject:[NSNumber numberWithInt:_gid] forKey:@"gid"];
    [groupPlayer setObject:[NSNumber numberWithInt:1] forKey:@"pid"];
    [groupPlayer setObject:[NSDate date] forKey:@"joinTime"];
    [groupPlayer setObject:[NSNumber numberWithInt:1] forKey:@"contrib"];
    
    return groupPlayer;
}

-(NSMutableArray *)getGroupPlayerList
{
    NSMutableArray *groupPlayers = [self getDataBykey:@"_group_player_list"];
	if(!groupPlayers || YES){
        groupPlayers = [NSMutableArray array];
		//TEST
		for (int i = 0 ; i < 5; i++) {
			NSMutableDictionary *infos_ = (NSMutableDictionary*)[self getGroupPlayerById:i];
			
			[groupPlayers addObject:infos_];
		}
		[self addData:groupPlayers key:@"_group_player_list"];
	}
	return groupPlayers;
}

-(NSDictionary *)getGroupPostById:(int)_gid
{
    NSMutableDictionary *groupPost = [NSMutableDictionary dictionary];
    [groupPost setObject:[NSNumber numberWithInt:1] forKey:@"id"];
    [groupPost setObject:[NSNumber numberWithInt:_gid] forKey:@"gid"];
    [groupPost setObject:@"宇宙无敌第一帮派，竞技前100名私密。宇宙无敌第一帮派，竞技前100名私密。" forKey:@"msg"];
    [groupPost setObject:[NSDate date] forKey:@"postTime"];
    
    return groupPost;
}

-(NSMutableArray *)getGroupPostList
{
    NSMutableArray *groupPosts = [self getDataBykey:@"_group_post_list"];
	if(!groupPosts || YES){
        groupPosts = [NSMutableArray array];
		//TEST
		for (int i = 0 ; i < 3; i++) {
			NSMutableDictionary *infos_ = (NSMutableDictionary*)[self getGroupPostById:i];
			
			[groupPosts addObject:infos_];
		}
		[self addData:groupPosts key:@"_group_post_list"];
	}
	return groupPosts;
}
*/
#pragma mark
#pragma mark 常用方法
-(NSDictionary*)getPlayerRoleFromListById:(int)rid
{
    NSArray *playerRoleList = [self getPlayerRoleList];
    for (NSDictionary *playerRole in playerRoleList) {
        int playerRoleId = [[playerRole objectForKey:@"rid"] intValue];
        if (playerRoleId == rid) {
            return playerRole;
        }
    }
    return nil;
}

-(int)getPlayerItemCountByIid:(int)iid
{
    int count = 0;
    NSArray *playerItemList = [self getPlayerItemList];
    for (NSDictionary *playerItem in playerItemList) {
        if ([[playerItem objectForKey:@"iid"] intValue] == iid) {
            count += [[playerItem objectForKey:@"count"] intValue];
        }
    }
    return count;
}
-(void)upgradePlayerEquipment:(int)_id
{
	NSArray *array = [self getPlayerEquipmentList];
	NSMutableArray *list = [NSMutableArray arrayWithArray:array];
	for (NSDictionary *dict in list) {
		int _value = [[dict objectForKey:@"id"] intValue];
		if (_value == _id) {
			NSMutableDictionary *t_dict = [NSMutableDictionary dictionaryWithDictionary:dict];
			int level = [[t_dict objectForKey:@"level"] intValue];
			level += 1;
			if (level <= EQUIPMENT_MAX_LEVEL) {
				[t_dict setObject:[NSNumber numberWithInt:level] forKey:@"level"];
				[list removeObject:dict];//删除之前的
				[list addObject:t_dict];//添加新的
				break;
			}
		}
	}
	NSDictionary *ilist = [self getDataBykey:@"ilist"];
	NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
	[temp_data setObject:list forKey:@"equip"];//重新写入装备列表
	[self addData:temp_data key:@"ilist"];//重新写入所有列表
	
	//fix chao
	//[GameConnection post:ConnPost_roleChangeEquip object:nil];
	//end
}
/*
 * 更新装备
 * ueid 玩家装备列表ID
 * type 操作类型 穿 脱
 */
-(void)updateEquipment:(int)_ueid type:(int)_type
{
	NSArray *array = [self getPlayerEquipmentList];
	NSMutableArray *list = [NSMutableArray arrayWithArray:array];
	if (list) {
		for (NSDictionary *dict in list) {
			int _value = [[dict objectForKey:@"id"] intValue];
			if (_value == _ueid) {
				NSMutableDictionary *t_dict = [NSMutableDictionary dictionaryWithDictionary:dict];
				if (_type == 1) {
					[t_dict setObject:[NSNumber numberWithInt:EquipmentStatus_used] forKey:@"used"];
					//->player
				}
				else {
					[t_dict setObject:[NSNumber numberWithInt:EquipmentStatus_unused] forKey:@"used"];
					//->player
				}
				[list removeObject:dict];//删除之前的
				[list addObject:t_dict];//添加新的
				break;
			}
		}
		NSDictionary *ilist = [self getDataBykey:@"ilist"];
		NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
		[temp_data setObject:list forKey:@"equip"];//重新写入装备列表
		[self addData:temp_data key:@"ilist"];//重新写入所有列表
		//fix chao
		//[GameConnection post:ConnPost_roleChangeEquip object:nil];
		//end
	}
}
-(void)tackOffEquipmentWithID:(int)eid rid:(int)_rid{
	for (int _part = 1; _part < 7; _part++) {
		NSArray *rlist = [self getPlayerRoleList];
		NSMutableArray *mlist = [NSMutableArray arrayWithArray:rlist];
		for (NSDictionary *dict in mlist) {
			int _value = [[dict objectForKey:@"id"] intValue];
			if (_value == _rid) {//-----
				NSString *key = [NSString stringWithFormat:@"eq%d",_part];
				if ([[dict objectForKey:key] intValue] == eid) {
					NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dict];
					[temp setObject:[NSNumber numberWithInt:0] forKey:key];
					[mlist removeObject:dict];//删除一个
					[mlist addObject:temp];//添加一个
					[self addData:mlist key:@"roles"];//刷新列表
					
					////equip used
					//fix chao
					[self updateEquipment:eid type:EquipmentStatus_unused];
					//end
					//fix chao
					//[GameConnection post:ConnPost_roleChangeEquip object:nil];
					//end
					return;
				}
			}
		}
		
	}
	CCLOG(@"tack off equip error");
}
-(void)tackOffEquipment:(NSString*)_part rid:(int)_rid
{
	NSDictionary *role =[self getPlayerRoleFromListById:_rid];
	NSMutableDictionary *dict =[NSMutableDictionary dictionaryWithDictionary:role];
	//fix chao
	[self updateEquipment:[[dict objectForKey:_part] intValue] type:EquipmentStatus_unused];
	//end
	[dict setValue:0 forKey:_part];
	NSArray *playerRoleList = [self getPlayerRoleList];
	NSMutableArray *array = [NSMutableArray arrayWithArray:playerRoleList];
	[array removeObject:role];
	[array addObject:dict];
	[self addData:array key:@"roles"];
	//fix chao
	//[GameConnection post:ConnPost_roleChangeEquip object:nil];
	//end
}




-(void)removeEquipment:(int)_ueid
{
	NSArray *array = [self getPlayerEquipmentList];
	NSMutableArray *list = [NSMutableArray arrayWithArray:array];
	if (list) {
		for (NSDictionary *dict in list) {
			int _value = [[dict objectForKey:@"id"] intValue];
			if (_value == _ueid) {
				[list removeObject:dict];//删除
				break;
			}
		}
		NSDictionary *ilist = [self getDataBykey:@"ilist"];
		NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
		[temp_data setObject:list forKey:@"equip"];//重新写入装备列表
		[self addData:temp_data key:@"ilist"];//重新写入所有列表
	}
}
////删除物品
-(void)removeItem:(int)_uiid{
	NSArray *array = [self getPlayerItemList];
	NSMutableArray *list = [NSMutableArray arrayWithArray:array];
	if (list) {
		for (NSDictionary *dict in list) {
			int _value = [[dict objectForKey:@"id"] intValue];
			if (_value == _uiid) {
				[list removeObject:dict];//删除
				break;
			}
		}
		NSDictionary *ilist = [self getDataBykey:@"ilist"];
		NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
		[temp_data setObject:list forKey:@"item"];//重新写入装备列表
		[self addData:temp_data key:@"ilist"];//重新写入所有列表
	}
}
//删除命格
-(void)removeFate:(int)_ufid{
	NSArray *array = [self getPlayerFateList];
	NSMutableArray *list = [NSMutableArray arrayWithArray:array];
	if (list) {
		for (NSDictionary *dict in list) {
			int _value = [[dict objectForKey:@"id"] intValue];
			if (_value == _ufid) {
				[list removeObject:dict];//删除
				break;
			}
		}
		NSDictionary *ilist = [self getDataBykey:@"ilist"];
		NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
		[temp_data setObject:list forKey:@"fate"];//重新写入装备列表
		[self addData:temp_data key:@"ilist"];//重新写入所有列表
	}
}
//加一个命格
-(void)addFate:(NSDictionary*)dict{
	if (!dict) {
		CCLOG(@"add fate dict is null");
		return;
	}
	if (!(
		  [dict objectForKey:@"id"] &&
		  [dict objectForKey:@"pid"] &&
		  [dict objectForKey:@"fid"] &&
		  [dict objectForKey:@"level"] &&
		  [dict objectForKey:@"exp"] &&
		  [dict objectForKey:@"used"] &&
		  [dict objectForKey:@"isTrade"]
		  )) {
		CCLOG(@"add fate dict format is error");
		return;
	}
	NSArray *array = [self getPlayerFateList];
	NSMutableArray *list = [NSMutableArray arrayWithArray:array];
	if (list) {
		[list addObject:dict];
		NSDictionary *ilist = [self getDataBykey:@"ilist"];
		NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
		[temp_data setObject:list forKey:@"fate"];
		[self addData:temp_data key:@"ilist"];
	}
}
/*
 *角色穿戴命格
 */
-(void)wearFate:(int)_ufid part:(int)_part target:(int)_urid
{
	if (_part == 0 || _part > 6) {
		CCLOG(@"can't get part in role! _part=%d",_part);
		return ;
	}
	NSArray *rlist = [self getPlayerRoleList];
	NSMutableArray *mlist = [NSMutableArray arrayWithArray:rlist];
	for (NSDictionary *dict in mlist) {
		int _value = [[dict objectForKey:@"id"] intValue];
		if (_value == _urid) {//-----
			NSString *key;
			NSMutableDictionary *temp= [NSMutableDictionary dictionaryWithDictionary:dict];
			for (int i=1; i<7; i++) {
				key = [NSString stringWithFormat:@"fate%d",i];
				if (_ufid == [[temp objectForKey:key] intValue]) {
					[temp setObject:[NSNumber numberWithInt:0] forKey:key];
				}
			}
			key = [NSString stringWithFormat:@"fate%d",_part];
			//temp = [NSMutableDictionary dictionaryWithDictionary:dict];
			[temp setObject:[NSNumber numberWithInt:_ufid] forKey:key];
			[mlist removeObject:dict];//删除一个
			[mlist addObject:temp];//添加一个
			break;
		}
	}
	[self addData:mlist key:@"roles"];//刷新列表
	
	////fate used
	NSArray *flist = [self getPlayerFateList];
	mlist = [NSMutableArray arrayWithArray:flist];
	for (NSDictionary *dict in mlist) {
		int _value = [[dict objectForKey:@"id"] intValue];
		if (_value == _ufid) {
			NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dict];
			[temp setObject:[NSNumber numberWithInt:FateStatus_used] forKey:@"used"];
			[mlist removeObject:dict];//删除一个
			[mlist addObject:temp];//添加一个
			break;
		}
	}
	NSDictionary *ilist = [self getDataBykey:@"ilist"];
	NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
	[temp_data setObject:mlist forKey:@"fate"];//重新写入合格列表
	[self addData:temp_data key:@"ilist"];//重新写入所有列表
	
	//fix chao
	//[GameConnection post:ConnPost_roleChangeEquip object:nil];
	//end
}
/*
 *角色脱命格
 */
-(void)tackOffFate:(int)_ufid part:(int)_part target:(int)_urid{
	if (_part == 0 || _part > 6) {
		CCLOG(@"can't get part in role! _part=%d",_part);
		return ;
	}
	NSArray *rlist = [self getPlayerRoleList];
	NSMutableArray *mlist = [NSMutableArray arrayWithArray:rlist];
	for (NSDictionary *dict in mlist) {
		int _value = [[dict objectForKey:@"id"] intValue];
		if (_value == _urid) {//-----
			NSString *key = [NSString stringWithFormat:@"fate%d",_part];
			NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dict];
			[temp setObject:[NSNumber numberWithInt:0] forKey:key];
			[mlist removeObject:dict];//删除一个
			[mlist addObject:temp];//添加一个
			break;
		}
	}
	[self addData:mlist key:@"roles"];//刷新列表
	
	////fate used
	NSArray *flist = [self getPlayerFateList];
	mlist = [NSMutableArray arrayWithArray:flist];
	for (NSDictionary *dict in mlist) {
		int _value = [[dict objectForKey:@"id"] intValue];
		if (_value == _ufid) {
			NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dict];
			[temp setObject:[NSNumber numberWithInt:FateStatus_unused] forKey:@"used"];
			[mlist removeObject:dict];//删除一个
			[mlist addObject:temp];//添加一个
			break;
		}
	}
	NSDictionary *ilist = [self getDataBykey:@"ilist"];
	NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
	[temp_data setObject:mlist forKey:@"fate"];//重新写入合格列表
	[self addData:temp_data key:@"ilist"];//重新写入所有列表
	
	//fix chao
	//[GameConnection post:ConnPost_roleChangeEquip object:nil];
	//end
}
/*
 *角色脱命格
 */
-(void)tackOffFate:(int)_ufid target:(int)_urid{
	//	if (_part == 0 || _part > 6) {
	//		CCLOG(@"can't get part in role! _part=%d",_part);
	//		return ;
	//	}
	for (int _part = 1; _part < 7; _part++) {
		NSArray *rlist = [self getPlayerRoleList];
		NSMutableArray *mlist = [NSMutableArray arrayWithArray:rlist];
		for (NSDictionary *dict in mlist) {
			int _value = [[dict objectForKey:@"id"] intValue];
			if (_value == _urid) {//-----
				NSString *key = [NSString stringWithFormat:@"fate%d",_part];
				if ([[dict objectForKey:key] intValue] == _ufid) {					
					NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dict];
					[temp setObject:[NSNumber numberWithInt:0] forKey:key];
					[mlist removeObject:dict];//删除一个
					[mlist addObject:temp];//添加一个					
					[self addData:mlist key:@"roles"];//刷新列表
					
					////fate used
					NSArray *flist = [self getPlayerFateList];
					mlist = [NSMutableArray arrayWithArray:flist];
					for (NSDictionary *dict in mlist) {
						int _value = [[dict objectForKey:@"id"] intValue];
						if (_value == _ufid) {
							NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:dict];
							[temp setObject:[NSNumber numberWithInt:FateStatus_unused] forKey:@"used"];
							[mlist removeObject:dict];//删除一个
							[mlist addObject:temp];//添加一个
							break;
						}
					}
					NSDictionary *ilist = [self getDataBykey:@"ilist"];
					NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
					[temp_data setObject:mlist forKey:@"fate"];//重新写入合格列表
					[self addData:temp_data key:@"ilist"];//重新写入所有列表
					
					//fix chao
					//[GameConnection post:ConnPost_roleChangeEquip object:nil];
					//end
					return;
				}				
			}
		}
		
	}
	CCLOG(@"tack off fate error");
}
/*
 *获取物品Id
 */
-(int)getItemIdByName:(NSString *)name
{
	NSDictionary *itemDict = [[GameDB shared] readDB:@"item"];
    NSArray *keys = [itemDict allKeys];
    for (NSString *key in keys) {
        NSDictionary *dict = [itemDict objectForKey:key];
        if ([[dict objectForKey:@"name"] isEqualToString:name]) {
            return [[dict objectForKey:@"id"] intValue];
            break;
        }
    }
    return -1;
}

-(NSArray*)getPlayerItemListByIid:(int)_iid
{
	NSMutableArray *itemArray = [NSMutableArray array];
	
	NSArray *array = [self getPlayerItemList];
	for (NSDictionary *dict in array) {
		int new_id = [[dict objectForKey:@"iid"] intValue];
		if (new_id == _iid) {
			[itemArray addObject:dict];
		}
	}
	return itemArray;
}

-(NSArray*)getPlayerItemByType:(Item_type)_type
{
	NSMutableArray *itemArray = [NSMutableArray array];
	
	NSDictionary *itemDict = [[GameDB shared] readDB:@"item"];
	NSArray *array = [self getPlayerItemList];
	for (NSDictionary *dict in array) {
		int iid = [[dict objectForKey:@"iid"] intValue];
		NSDictionary *item = [itemDict objectForKey:[NSString stringWithFormat:@"%d", iid]];
		if (item) {
			Item_type type = [[item objectForKey:@"type"] intValue];
			if (type == _type) {
				[itemArray addObject:dict];
			}
		}
	}
	return itemArray;
}


-(void)updateRoleArray:(NSArray *)_array{
	if (_array ==  nil)  return ;
	CCLOG(@"GameConfigure->updateRoleArray");
	
	NSArray* _arr = [NSArray arrayWithArray:_array];
	//TODO 检测 是不是有角色增加
	[self addData:_arr key:@"roles"];
	
}

-(void)updateEquipmentArray:(NSArray *)_array{
	if (_array ==  nil)  return ;
	CCLOG(@"GameConfigure->updateEquipmentArray");
	
	//TODO 检测 是不是有数据增加
	NSMutableDictionary* iDict = [NSMutableDictionary dictionaryWithDictionary:[self getDataBykey:@"ilist"]];
	NSArray* _arr = [NSArray arrayWithArray:_array];
	
	[iDict setObject:_arr forKey:@"equip"];
	
	[self addData:iDict key:@"ilist"];
}

-(void)updateFateArray:(NSArray *)_array{
	if (_array ==  nil)  return ;
	CCLOG(@"GameConfigure->updateFateArray");
	
	//TODO 检测 是不是有数据增加
	
	NSMutableDictionary* iDict = [NSMutableDictionary dictionaryWithDictionary:[self getDataBykey:@"ilist"]];
	
	NSArray* _arr = [NSArray arrayWithArray:_array];
	[iDict setObject:_arr forKey:@"fate"];
	
	[self addData:iDict key:@"ilist"];
}

-(void)updateItemArray:(NSArray *)_array{
	if (_array ==  nil)  return ;
	CCLOG(@"GameConfigure->updateItemArray");
	
	//TODO 检测 是不是有数据增加
	NSMutableDictionary* iDict = [NSMutableDictionary dictionaryWithDictionary:[self getDataBykey:@"ilist"]];
	
	NSArray* _arr = [NSArray arrayWithArray:_array];
	
	[iDict setObject:_arr forKey:@"item"];
	[self addData:iDict key:@"ilist"];
	
}

-(void)updateJewelArray:(NSArray *)_array{
	
	if (_array == nil) return;
	CCLOG(@"GameConfigure->updateJewelArray");
	
	//TODO 检测 是不是有数据增加
	NSMutableDictionary* iDict = [NSMutableDictionary dictionaryWithDictionary:[self getDataBykey:@"ilist"]];
	
	NSArray* _arr = [NSArray arrayWithArray:_array];
	
	[iDict setObject:_arr forKey:@"gem"];
	[self addData:iDict key:@"ilist"];
}

-(NSArray*)getPlayerJewels{
	NSDictionary *ilist = [self getDataBykey:@"ilist"];
	NSArray *glist = [NSArray arrayWithArray:[ilist objectForKey:@"gem"]];
	if (glist) {
		return glist;
	}	
	CCLOG(@"getPlayerJewels return nil");
	return [NSArray array];
}

-(NSDictionary*)getPlayerJewelInfoById:(int)_id
{
	NSArray *array = [self getPlayerJewels];
	for (NSDictionary *dict in array) {
		int new_id = [[dict objectForKey:@"id"] intValue];
		if (new_id == _id) {
			return dict;
		}
	}
	return nil;
}

-(NSArray*)getPlayerRoleList
{
	//return [self getDataBykey:@"roles"];
	
	return [NSArray arrayWithArray:[self getDataBykey:@"roles"]];
}


-(NSArray*)getPlayerMails{
	return [self getDataBykey:@"mail"];
}

-(void)setPlayerBuff:(NSDictionary*)dict type:(Buff_Type)type{
	NSMutableArray * ary = [NSMutableArray arrayWithArray:[self getDataBykey:@"buff"]];
	int ti = -1;
	for(int i=0;i<[ary count];i++){
		NSDictionary * b = [ary objectAtIndex:i];
		if([[b objectForKey:@"t"] intValue]==type){
			ti = i;
		}
	}
	if(ti>=0){
		[ary removeObjectAtIndex:ti];
	}
	[ary addObject:dict];
	[self addData:ary key:@"buff"];
}

-(NSDictionary*)getPlayerBuffByType:(Buff_Type)type{
	NSArray * ary = [self getDataBykey:@"buff"];
	for(int i=0;i<[ary count];i++){
		NSDictionary * b = [ary objectAtIndex:i];
		Buff_Type t = [[b objectForKey:@"t"] intValue];
		if(t==type){
			int et = [[b objectForKey:@"et"] intValue];
			if((et-time)>0){
				return b;
			}
		}
	}
	return nil;
}

-(NSDictionary*)getPlayerAlly{
	return [self getDataBykey:@"ally"];
}

-(void)removePlayerAlly{
	[gameRecord removeObjectForKey:@"ally"];
}

-(void)setPlayerAlly:(NSDictionary*)info{
	
	if (info == nil) {
		return ;
	}
	
	NSDictionary * ally = [self getDataBykey:@"ally"];
	NSMutableDictionary * data = [NSMutableDictionary dictionary];
	if(ally){
		[data setValuesForKeysWithDictionary:ally];
	}
	[data setValuesForKeysWithDictionary:info];
	[data setObject:[info objectForKey:@"name"] forKey:@"n"];
	
	[self addData:data key:@"ally"];
}


-(NSArray*)getPlayerCarList{
	NSArray* car=[[self getDataBykey:@"ilist"]objectForKey:@"car"];
	if (car) {
		return car;
	}
	return [NSArray array];
}

//______________________________________________________________________________
//______________________________________________________________________________
//______________________________________________________________________________
-(NSDictionary*)getRoleById:(int)_id{
	NSArray* array = [self getPlayerRoleList];
	for (NSDictionary* role in array) {
		int ___id = [[role objectForKey:@"id"] intValue];
		if (___id == _id && _id > 0) {
			return role ;
		}
	}
	return nil;
}

-(void)doEquipmentMoveLevel:(int)_eid1 with:(int)_eid2{
	NSDictionary* d1 = [self getPlayerEquipInfoById:_eid1];
	NSDictionary* d2 = [self getPlayerEquipInfoById:_eid2];
	
	if (d1 == nil || d2 == nil) {
		return ;
	}
	
	NSMutableDictionary* e1 = [NSMutableDictionary dictionaryWithDictionary:d1];
	NSMutableDictionary* e2 = [NSMutableDictionary dictionaryWithDictionary:d2];
	
	int level1 = [[e1 objectForKey:@"level"] intValue];
	int level2 = [[e2 objectForKey:@"level"] intValue];
	
	//对调等级
	[e1 setObject:[NSNumber numberWithInt:level2] forKey:@"level"];
	[e2 setObject:[NSNumber numberWithInt:level1] forKey:@"level"];
	
	[self updateEquipmentByDict:e1];
	[self updateEquipmentByDict:e2];
	
}

-(void)doEquipmentAction:(int)_rid off:(int)_ueid input:(int)_ieid{
	
	if (_rid <= 0) return ;
	
	NSDictionary* rDict = [self getRoleById:_rid];
	if (rDict == nil) return;
	
	NSMutableDictionary* _role = [NSMutableDictionary dictionaryWithDictionary:rDict];
	
	BOOL isUpdate = NO;
	//处理脱下装备
	if (_ueid > 0) {
		isUpdate = YES ;
		NSDictionary* eDict = [self getPlayerEquipInfoById:_ueid];
		NSMutableDictionary* _equip = [NSMutableDictionary dictionaryWithDictionary:eDict];
		int ___eid  = [[_equip objectForKey:@"eid"] intValue];
		NSDictionary* dbEq = [[GameDB shared] getEquipmentInfo:___eid];
		int ___part = [[dbEq objectForKey:@"part"] intValue];
		NSString* _key = [NSString stringWithFormat:@"eq%d",___part];
		
		[_role setObject:[NSNumber numberWithInt:0] forKey:_key];
		[_equip setObject:[NSNumber numberWithInt:EquipmentStatus_unused] forKey:@"used"];
		[self updateEquipmentByDict:_equip];
	}
	
	//处理穿上装备
	if (_ieid > 0) {
		isUpdate = YES ;
		NSDictionary* eDict = [self getPlayerEquipInfoById:_ieid];
		NSMutableDictionary* _equip = [NSMutableDictionary dictionaryWithDictionary:eDict];
		int ___eid  = [[_equip objectForKey:@"eid"] intValue];
		NSDictionary* dbEq = [[GameDB shared] getEquipmentInfo:___eid];
		
		int ___part = [[dbEq objectForKey:@"part"] intValue];
		NSString* _key = [NSString stringWithFormat:@"eq%d",___part];
		
		[_role setObject:[NSNumber numberWithInt:_ieid] forKey:_key];
		[_equip setObject:[NSNumber numberWithInt:EquipmentStatus_used] forKey:@"used"];
		[self updateEquipmentByDict:_equip];
		
	}
	
	if (isUpdate) {
		[self updateRoleByDict:_role];
	}
	
}

-(void)updateRoleByDict:(NSDictionary *)_dict{
	if (_dict == nil) return ;
	CCLOG(@"updateRoleByDict:%@",[_dict description]);
	NSMutableArray* roles = [NSMutableArray arrayWithArray:[self getPlayerRoleList]];
	//
	BOOL isAdd = NO;
	for(NSDictionary * role in roles){
		int id1 = [[role objectForKey:@"id"] intValue];
		int id2 = [[_dict objectForKey:@"id"] intValue];
		if (id2 == id1 && id1 > 0) {
			isAdd = YES ;
			[roles removeObject:role];
			break ;
		}
	}
	if (isAdd) {
		[roles addObject:_dict];
		[self addData:roles key:@"roles"];
	}
}

-(void)updateEquipmentByDict:(NSDictionary *)_dict{
	if (_dict == nil) return ;
	CCLOG(@"updateEquipmentByDict:%@",[_dict description]);
	NSMutableArray* equips = [NSMutableArray arrayWithArray:[self getPlayerEquipmentList]];
	
	BOOL isAdd = NO;
	for(NSDictionary * equip in equips){
		int id1 = [[equip objectForKey:@"id"] intValue];
		int id2 = [[_dict objectForKey:@"id"] intValue];
		
		if (id1 == id2 && id2 > 0) {
			isAdd = YES ;
			[equips removeObject:equip];
			break ;
		}
	}
	
	if (isAdd) {
		[equips addObject:_dict];
		
		NSDictionary *ilist = [self getDataBykey:@"ilist"];
		NSMutableDictionary *temp_data = [NSMutableDictionary dictionaryWithDictionary:ilist];
		[temp_data setObject:equips forKey:@"equip"];
		[self addData:temp_data key:@"ilist"];
		
	}
}

//______________________________________________________________________________
//______________________________________________________________________________

-(NSDictionary*)getVipConfig{
    NSDictionary* dict = [NSDictionary dictionaryWithDictionary:[self getDataBykey:@"vip"]];
    return dict;
}

-(void)updateVipConfig:(NSDictionary *)dict{
    if (dict) {
        [self addData:dict key:@"vip"];
    }
}

-(int)getPlayerVipLevel{
	NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
	int vip= [[dict objectForKey:@"vip"] intValue];
	return vip;
}

-(NSArray*)getRoleWithStatus:(RoleStatus)_status{
	NSMutableArray* array = [NSMutableArray array];
	NSArray* roles = [self getPlayerRoleList];
	
	for (NSDictionary* role in roles) {
		NSNumber* number = [role objectForKey:@"status"];
		if ([number intValue] == _status) {
			[array addObject:[role objectForKey:@"rid"]];
		}
	}
	
	[array sortUsingSelector:@selector(compare:)];
	return array;
}

//______________________________________________________________________________
//______________________________________________________________________________

-(BOOL)checkPlayerIsFirstRecharge{
	NSDictionary* dict = [self getPlayerInfo];
	if (dict) {
		if([[dict objectForKey:@"Payed"] intValue] == 0){
			return YES;
		}
	}
	return NO;
}

-(void)closePlayerFirstRecharge{
	NSMutableDictionary *player=[NSMutableDictionary dictionaryWithDictionary:[self getPlayerInfo]];
	[player setValue:[NSNumber numberWithInt:1] forKey:@"Payed"];
	[self addData:player key:@"player"];
}

//______________________________________________________________________________


-(void)updatePlayerCBE:(NSDictionary *)dict{
	NSMutableDictionary *cbe=[NSMutableDictionary dictionaryWithDictionary:dict];
	[self addData:cbe key:@"CBE"];
}

-(NSDictionary*)getPlayerCBE{
	return [NSDictionary dictionaryWithDictionary:[self getDataBykey:@"CBE"]];
}

@end
