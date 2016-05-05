//
//  MapManager.m
//  TXSFGame
//
//  Created by chao chen on 12-10-24.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "MapManager.h"
#import "AStarPathFinder.h"
#import "Config.h"
#import "NPCManager.h"

#import "GameConfigure.h"
#import "GameDB.h"
#import "StageManager.h"
#import "GameConnection.h"
#import "TiledMap.h"
#import "TiledLayer.h"
#import "AStarMap.h"
#import "AStarLayer.h"
#import "RoleManager.h"
#import "RolePlayer.h"

#import "PlayerSit.h"
#import "GameFileUtils.h"
#import "GameResourceLoader.h"

MapManager *s_MapManager = nil;

@implementation MapManager
@synthesize size;
@synthesize startPoint;
@synthesize mapId;
@synthesize parentMapId;
@synthesize mapType;
@synthesize isBlock = _isBlock;
@synthesize isLoadMapOver;

+(MapManager*)shared{
	if(!s_MapManager){
		s_MapManager = [MapManager node];
		[s_MapManager retain];
	}
	return s_MapManager;
}
+(void)stopAll{
	if(s_MapManager){
		[s_MapManager removeFromParentAndCleanup:YES];
		[s_MapManager release];
		s_MapManager = nil;
	}
}

+(BOOL)checkDownloadMapSourceById:(int)mid target:(id)target call:(SEL)call{
	NSDictionary * mapInfo = [[GameDB shared] getMapInfo:mid];
	return [MapManager checkDownloadMapSource:mapInfo target:target call:call];
}

+(BOOL)checkDownloadMapSource:(NSDictionary*)info target:(id)target call:(SEL)call{
	
	NSString * name = [info objectForKey:@"tiledFile"];
	if (name == nil) {
		CCLOG(@"ERROR!->checkDownloadMapSource->map name is null");
		return NO;
	}
	
	NSString * tPath = [GameResourceLoader getFilePathByType:PathType_map target:name];
	NSString * tPath1 = [NSString stringWithFormat:@"%@-a.map",tPath];
	NSString * tPath2 = [NSString stringWithFormat:@"%@-m.map",tPath];
	
	NSMutableArray * helpers = [NSMutableArray array];
	
	GameLoaderHelper * helper = nil;
	
	if(![CCFileUtils hasFilePathByTarget:tPath]){
		helper = [GameLoaderHelper create:[NSString stringWithFormat:@"%@.%@",tPath,GAME_RESOURCE_DAT] 
								  isUnzip:YES];
		helper.isPostLoading = YES;
		[helpers addObject:helper];
	}
	if(![CCFileUtils hasFilePathByTarget:tPath1]){
		helper = [GameLoaderHelper create:tPath1];
		helper.isPostLoading = YES;
		[helpers addObject:helper];
	}
	if(![CCFileUtils hasFilePathByTarget:tPath2]){
		helper = [GameLoaderHelper create:tPath2];
		helper.isPostLoading = YES;
		[helpers addObject:helper];
	}
	
	for(GameLoaderHelper * helper in helpers){
		helper.target = target;
		helper.call = call;
		helper.type = PathType_map;
		[helper bondOthers:helpers];
	}
	
	[[GameResourceLoader shared] syncDownloadHelpers:helpers];
	
	return ([helpers count]>0);
}

-(void)dealloc{
	[super dealloc];
	CCLOG(@"MapManager dealloc");
}

-(void)onEnter{
	[super onEnter];
}

-(BOOL)isEqualMapId:(int)mid{
	return (self.mapId == mid);
}

-(void)setTargetMapId:(int)mid{
	targetMapId = mid;
	
	CCLOG(@"targetMapId->%d",targetMapId);
	NSDictionary * mapInfo = [[GameDB shared] getMapInfo:targetMapId];
	Map_Type type = [[mapInfo objectForKey:@"type"] intValue];
	
	if([self canSetLocation:mapType] && [self canSetLocation:type]){
		[[GameConfigure shared] setPlayerLocation:ccp(-1,-1) mapId:mid];
		[[PlayerSitManager shared] stopSit];
	}
	
	NSDictionary* playerInfo = [[GameConfigure shared] getPlayerInfo];
	int _mid= [[playerInfo objectForKey:@"mapId"] intValue];
	if (_mid != targetMapId && mapId != _mid && [self canSetLocation:type]) {
		[[GameConfigure shared] setPlayerLocation:ccp(-1,-1) mapId:mid];
	}
	
}

-(int)getTargetMapId{
	return targetMapId;
}

-(NSString*)getMapName{
	NSDictionary *dictionary = [[GameDB shared] getMapInfo:self.mapId];
	if (dictionary) {
		NSString *name = [dictionary objectForKey:@"name"];
		return name;
	}
	return [NSString stringWithFormat:@""];
}

-(void)loadMap{
	[self removeMap];
	
	NSDictionary * mapInfo = nil;
	if(targetMapId>0){
		mapInfo = [[GameDB shared] getMapInfo:targetMapId];
	}else{
		mapInfo = [[GameConfigure shared] getUserMapInfo];
	}
	
	//get user postion location load target map info
	
	mapId = [[mapInfo objectForKey:@"id"] intValue];
	parentMapId = [[mapInfo objectForKey:@"pmid"] intValue];
	mapType = [[mapInfo objectForKey:@"type"] intValue];
	isMulti = [[mapInfo objectForKey:@"multi"] boolValue];
	
	[self loadMapByMapFile:[mapInfo objectForKey:@"tiledFile"]];
	
	//targetMapId = 0;
}

-(void)removeMap{
	if(finder){
		//[finder removeFromParentAndCleanup:YES];
		[finder delayRelease];
		finder = nil;
	}
	if(tiled){
		[tiled removeFromParentAndCleanup:YES];
		tiled = nil;
	}
	if(maper){
		[maper removeAllChildrenWithCleanup:YES];
		[maper removeFromParentAndCleanup:YES];
		maper = nil;
	}
	
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	[[CCDirector sharedDirector] purgeCachedData];
	
	isLoadMapOver = NO;
	
}

-(BOOL)isShowMap{
	if(isLoadMapOver){
		return YES;
	}
	/*
	if(maper){
		return YES;
	}
	*/
	return NO;
}

-(void)checkMapPoint:(CGPoint)pos{
	
	[TiledLayer checkMapPoint:pos];
	
}

-(void)loadMapByMapFile:(NSString*)file{
	
	if (!file) {
		CCLOG(@"file is null");
		return ;
	}
	
	if([file hasSuffix:@".tmx"]){
		NSArray * strs = [file componentsSeparatedByString:@".tmx"];
		file = [strs objectAtIndex:0];
	}
	
	//tiled = [AStartMap tiledMapWithTMXFile:[NSString stringWithFormat:@"maps/nmap/%@-a.tmx",file]];
	tiled = [AStartMap tiledMapWithTMXFile:[NSString stringWithFormat:@"gmaps/%@-a.map",file]];
	
	[self loadStartPoint];
	[self loadMapNPCData];
	[self loadUserMapNPCData];
	
	//maper = [TiledMap tiledMapWithTMXFile:[NSString stringWithFormat:@"maps/nmap/%@-m.tmx",file]];
	maper = [TiledMap tiledMapWithTMXFile:[NSString stringWithFormat:@"gmaps/%@-m.map",file]];
	
	finder = [[AStarPathFinder alloc] initWithTileMap:tiled groundLayer:TILED_COLLIDE];
	[finder addCollideLayer:TILED_COLLIDE tileMap:tiled];
	
	[self addChild:maper z:1];
	[self addChild:tiled z:2];
	
	//[self addChild:finder z:3];
	
	if(tiled.contentSize.height>maper.contentSize.height){
		if([Game iPhoneRuningOnGame]){
			tiled.position = ccp(0,(maper.contentSize.height-tiled.contentSize.height)/2);
		}else{
			tiled.position = ccp(0,maper.contentSize.height-tiled.contentSize.height);
		}
	}
	
}

-(void)loadStartPoint{
	
	CCTMXObjectGroup * group = [tiled objectGroupNamed:@"object"];
	NSDictionary * startDict = [group objectNamed:@"start"];
	
	startPoint.x = [[startDict objectForKey:@"x"] intValue];
	startPoint.y = [[startDict objectForKey:@"y"] intValue];
	
	if([Game iPhoneRuningOnGame]){
		startPoint.x /= 2;
		startPoint.y /= 2;
	}
	
	startPoint = [self getPositionToTile:startPoint];
	
	CCLOG(@"%f %f",startPoint.x,startPoint.y);
	
}

-(void)loadMapNPCData{
	CCTMXObjectGroup * group = [tiled objectGroupNamed:@"object"];
	for(NSDictionary * npc in group.objects){
		if([[npc objectForKey:@"name"] isEqualToString:@"npc"]){
			
			CGPoint point;
			point.x = [[npc objectForKey:@"x"] intValue];
			point.y = [[npc objectForKey:@"y"] intValue];
			
			if([Game iPhoneRuningOnGame]){
				point.x /= 2;
				point.y /= 2;
			}
			
			int npcId = [[npc objectForKey:@"id"] intValue];
			
			if ([npc objectForKey:@"userdata"]){
				[[NPCManager shared] addNPCById:npcId
									  tilePoint:[self getPositionToTile:point]
									  direction:[npc objectForKey:@"direction"]
										   with:[npc objectForKey:@"userdata"]];
			}
			else
			{
				[[NPCManager shared] addNPCById:npcId
									  tilePoint:[self getPositionToTile:point]
									  direction:[[npc objectForKey:@"direction"] intValue]
				 ];
			}

		}
	}
}
/*
 */
-(NSArray*)getFunctionRect:(NSString *)_layer key:(NSString *)_key
{
	NSMutableArray *array = [NSMutableArray array];
	if (_layer && _key) {
		CCTMXObjectGroup * group = [tiled objectGroupNamed:_layer];
		if (group) {
			for (NSDictionary *dict in group.objects) {
				if ([[dict objectForKey:@"name"] isEqualToString:_key]) {
					
					CGRect rect = CGRectMake([[dict objectForKey:@"x"] intValue],
											 [[dict objectForKey:@"y"] intValue],
											 [[dict objectForKey:@"width"] intValue],
											 [[dict objectForKey:@"height"] intValue]);
					[array addObject:[NSValue valueWithCGRect:rect]];
				}
			}
		}
		else {
			CCLOG(@"Can't find layer by %@",_layer);
		}
	}
	else {
		CCLOG(@"parameters is null");
	}
	return array;
}
-(NSArray*)getFunctionData:(NSString *)_layer key:(NSString *)_key
{
	NSMutableArray *array = [NSMutableArray array];
	if (_layer && _key) {
		CCTMXObjectGroup * group = [tiled objectGroupNamed:_layer];
		if (group) {
			for (NSDictionary *dict in group.objects) {
				if ([[dict objectForKey:@"name"] isEqualToString:_key]) {
					[array addObject:dict];
				}
			}
		}
		else {
			CCLOG(@"Can't find layer by %@",_layer);
		}
	}
	else {
		CCLOG(@"parameters is null");
	}
	return array;
}

-(void)loadUserMapNPCData{
	NSArray * npcs = [[GameConfigure shared] getUserMapNPCByMapId:mapId];
	for(NSDictionary * d in npcs){
		[[NPCManager shared] addNPCById:[[d objectForKey:@"nid"] intValue]
							  tilePoint:CGPointFromString([d objectForKey:@"point"])
							  direction:[[d objectForKey:@"direction"] intValue]
		 ];
	}
}

-(CGSize)size{
	int w = MIN(tiled.contentSize.width, maper.contentSize.width);
	int h = MIN(tiled.contentSize.height, maper.contentSize.height);
	
	if([Game iPhoneRuningOnGame]){
		w/=2;
		h/=2;
	}
	
	return CGSizeMake(w,h);
}
-(CGSize)maxSize{
	int w = MAX(tiled.contentSize.width, maper.contentSize.width);
	int h = MAX(tiled.contentSize.height, maper.contentSize.height);
	if([Game iPhoneRuningOnGame]){
		w/=2;
		h/=2;
	}
	
	return CGSizeMake(w,h);
}
-(CGSize)tileSize{
	return tiled.tileSize;
}

-(NSArray*)startRun:(CGPoint)po1 moveTo:(CGPoint)po2 block:(BOOL)_b
{
	NSMutableArray * result = [NSMutableArray array];
	
	if(!finder){
		return result;
	}
	
	CGPoint p1 = [ self getPositionToTile:po1];
	CGPoint p2 = [ self getPositionToTile:po2];
	
	if(![[MapManager shared] tiledPointIsOpen:p2 block:_b]){
		return result;
	}
	
	if(![[MapManager shared] tiledPointIsOpen:p1 block:_b]){
		CGPoint npos = [self getNearOpenTiledPoint:p1 start:1 length:30];
		if(p1.x==npos.x && p1.y==npos.y){
			[result addObject:NSStringFromCGPoint(po2)];
			return result;
		}
		p1 = npos;
	}
	
	NSArray * nodes = [finder getBasePathFrom:p1 to:p2];
	[result addObjectsFromArray:nodes];

	
	return result;
}

-(NSArray*)startRun:(CGPoint)po1 moveTo:(CGPoint)po2{
	
	NSMutableArray * result = [NSMutableArray array];
	
	if(!finder){
		return result;
	}
	
	CGPoint p1 = [ self getPositionToTile:po1];
	CGPoint p2 = [ self getPositionToTile:po2];
	
	if(![[MapManager shared] tiledPointIsOpen:p2]){
		return result;
	}
	
	if(![[MapManager shared] tiledPointIsOpen:p1]){
		CGPoint npos = [self getNearOpenTiledPoint:p1 start:1 length:30];
		if(p1.x==npos.x && p1.y==npos.y){
			[result addObject:NSStringFromCGPoint(po2)];
			return result;
		}
		p1 = npos;
	}
	
	//[finder setPathRGBAFillColor:255 g:0 b:0 a:255];
	//[finder highlightPathFrom:p1 to:p2];
	//[finder highlightPathFrom:p2 to:p1];
	
	//NSMutableArray * points = [NSMutableArray array];
	
	//NSArray * nodes = [finder getPath:p1 to:p2];
	//NSArray * nodes = [finder getPath:p2 from:p1];
	NSArray * nodes = [finder getBasePathFrom:p1 to:p2];
	[result addObjectsFromArray:nodes];
	
	/*
	 if([nodes count]>0){
	 for(AStarNode * node in nodes){
	 CGPoint po = [self getTileToPosition:node->point];
	 [points addObject:NSStringFromCGPoint(po)];
	 }
	 }
	 */
	
	return result;
}

-(BOOL)targetPointIsOpen:(CGPoint)point{
	point = [self getPositionToTile:point];
	return [self tiledPointIsOpen:point];
}

-(BOOL)tiledPointIsOpen:(CGPoint)point block:(BOOL)_b
{
	if (_isBlock && _b) {
		TiledLayer * layer = (TiledLayer*)[tiled layerNamed:TILED_BLOCK];
		if(layer){
			if([layer tileGIDAt:point]){
				return YES;
			}
		}else{
			TiledLayer * layer = (TiledLayer*)[tiled layerNamed:TILED_COLLIDE];
			if(layer){
				if([layer tileGIDAt:point]){
					return YES;
				}
			}
		}
	}else{
		TiledLayer * layer = (TiledLayer*)[tiled layerNamed:TILED_COLLIDE];
		if(layer){
			if([layer tileGIDAt:point]){
				return YES;
			}
		}
	}
	
	return NO;
}

-(BOOL)tiledPointIsOpen:(CGPoint)point{
	
	if (_isBlock) {
		TiledLayer * layer = (TiledLayer*)[tiled layerNamed:TILED_BLOCK];
		if(layer){
			if([layer tileGIDAt:point]){
				return YES;
			}
		}else{
			TiledLayer * layer = (TiledLayer*)[tiled layerNamed:TILED_COLLIDE];
			if(layer){
				if([layer tileGIDAt:point]){
					return YES;
				}
			}
		}
	}else{
		TiledLayer * layer = (TiledLayer*)[tiled layerNamed:TILED_COLLIDE];
		if(layer){
			if([layer tileGIDAt:point]){
				return YES;
			}
		}
	}
	
	return NO;
}

//get tiled point for position
-(CGPoint)getPositionToTile:(CGPoint)point{
	
	CGSize tileSize = tiled.tileSize;
	CGSize tiledContent = tiled.contentSize;
	if([Game iPhoneRuningOnGame]){
		tileSize.width /= 2;
		tileSize.height /= 2;
		tiledContent.width /= 2;
		tiledContent.height /= 2;
	}
	
	point = ccpAdd(point, ccp(0,-tiled.position.y));
	point.x = (int)point.x/tileSize.width;
	point.y = (int)point.y/tileSize.height;
	point.y = tiledContent.height/tileSize.height-point.y;
	
	return ccp((int)point.x,(int)point.y);
}

-(CGPoint)getTileToPosition:(CGPoint)point{
	
	CGSize tileSize = tiled.tileSize;
	CGSize tiledContent = tiled.contentSize;
	if([Game iPhoneRuningOnGame]){
		tileSize.width /= 2;
		tileSize.height /= 2;
		tiledContent.width /= 2;
		tiledContent.height /= 2;
	}
	
	point.x = (int)point.x*tileSize.width;
	point.y = (int)point.y*tileSize.height;
	point.y = tiledContent.height-point.y;
	point.x += tileSize.width/2;
	point.y -= tileSize.height/2 - tiled.position.y;
	
	return ccp((int)point.x,(int)point.y);
}

-(CGPoint)getNearOpenTiledPoint:(CGPoint)point start:(int)start length:(int)length{
	
	CGPoint check = CGPointZero;
	
	if(start<=0) start = 1;
	length += start;
	length -= 1;
	if(length<=start) length = start;
	
	for(int i=start;i<length;i++){
		
		check = ccpAdd(point, ccp(0,-i));
		if([[MapManager shared] tiledPointIsOpen:check]){
			return check;
		}
		check = ccpAdd(point, ccp(0,i));
		if([[MapManager shared] tiledPointIsOpen:check]){
			return check;
		}
		check = ccpAdd(point, ccp(i,0));
		if([[MapManager shared] tiledPointIsOpen:check]){
			return check;
		}
		check = ccpAdd(point, ccp(-i,0));
		if([[MapManager shared] tiledPointIsOpen:check]){
			return check;
		}
		
		check = ccpAdd(point, ccp(i,i));
		if([[MapManager shared] tiledPointIsOpen:check]){
			return check;
		}
		check = ccpAdd(point, ccp(-i,-i));
		if([[MapManager shared] tiledPointIsOpen:check]){
			return check;
		}
		check = ccpAdd(point, ccp(-i,i));
		if([[MapManager shared] tiledPointIsOpen:check]){
			return check;
		}
		check = ccpAdd(point, ccp(i,-i));
		if([[MapManager shared] tiledPointIsOpen:check]){
			return check;
		}
		
	}
	return point;
}

-(BOOL)canSetLocation:(Map_Type)type{
	if(type==Map_Type_TimeBox){
		[[PlayerSitManager shared] stopSit];
		return NO;
	};
	//if(type==Map_Type_Stage) return NO;
	return YES;
}

-(void)setPlayerLocation:(CGPoint)point{
	if(![self canSetLocation:mapType]) return;
	[[GameConfigure shared] setPlayerLocation:point mapId:mapId];
	[[PlayerSitManager shared] stopSit];
}

-(void)logParentMap{
	
	if(mapType==Map_Type_Abyss ||
	   mapType==Map_Type_WorldBoss ||
	   mapType==Map_Type_UnionBoss ||
	   mapType==Map_Type_Mining ||
	   mapType==Map_Type_Fish ||
	   mapType==Map_Type_TimeBox ||
	   mapType==Map_Type_Stage ||
       mapType==Map_Type_Union ||
	   mapType==Map_Type_SysPvp ||
	   mapType==Map_Type_dragonReady ||
	   mapType==Map_Type_dragonFight){
		return;
	}
	//----副本不记录当前地图
	CCLOG(@"preMapUpdate->%d",mapId);
	//---------------------
	NSString *str = [NSString stringWithFormat:@"pmid::%d",mapId];
	[GameConnection request:@"preMapUpdate" format:str target:nil call:nil];
	[[GameConfigure shared] updatePlayerLastMapId:[MapManager shared].mapId];//本地更新
	//---------------------
	
}

-(BOOL)checkCanRunTask{
	if(mapType==Map_Type_Abyss		||
	   mapType==Map_Type_Mining		||
	   mapType==Map_Type_WorldBoss	||
	   mapType==Map_Type_UnionBoss	||
	   mapType==Map_Type_TimeBox	||
	   mapType==Map_Type_dragonReady ||
	   mapType==Map_Type_dragonFight){
		return NO;
	}
	return YES;
}
-(BOOL)checkMapCanShowTaskAlert{
	if(mapType==Map_Type_Abyss		||
	   mapType==Map_Type_Mining		||
	   mapType==Map_Type_WorldBoss	||
	   mapType==Map_Type_UnionBoss	||
	   mapType==Map_Type_TimeBox	||
	   mapType==Map_Type_Union		||
	   mapType==Map_Type_dragonReady ||
	   mapType==Map_Type_dragonFight){
		return NO;
	}
	return YES;
}
-(BOOL)checkMapCanManyPeople{
	if(mapType==Map_Type_Standard	||
	   mapType==Map_Type_Fish		||
	   mapType==Map_Type_Mining		||
	   mapType==Map_Type_Abyss		||
	   mapType==Map_Type_WorldBoss	||
	   mapType==Map_Type_UnionBoss	||
	   mapType==Map_Type_Union		||
	   mapType==Map_Type_dragonReady ||
	   mapType==Map_Type_dragonFight){
		return YES;
	}
	return NO;
}

@end
