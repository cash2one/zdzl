//
//  MapManager.h
//  TXSFGame
//
//  Created by chao chen on 12-10-24.
//  Copyright (c) 2012 eGame. All rights reserved.
//

typedef enum {
	Map_Type_Standard = 1,//标准地图
	Map_Type_Stage = 2,//副本地图
	Map_Type_Fish = 3,//钓鱼地图
	Map_Type_Mining = 4,//采矿地图
	Map_Type_TimeBox = 5,//时光盒
	Map_Type_Abyss = 6,//深渊
	Map_Type_Union = 7,//同盟
	Map_Type_WorldBoss = 8,//世界Boss
	Map_Type_UnionBoss = 9,//同盟Boss
	Map_Type_SysPvp=10,//竞技场
	Map_Type_dragonReady=11,//狩龙准备界面
	Map_Type_dragonFight=12,//狩龙战斗界面
}Map_Type;

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

@class AStarPathFinder;

@interface MapManager : CCLayer{
	//CGSize size;
	//CCSprite * backgroud;
	
	CCTMXTiledMap * tiled;
	CCTMXTiledMap * maper;
	AStarPathFinder * finder;
	
	CGPoint startPoint;
	
	int mapId;
	int targetMapId;
	int parentMapId;
	Map_Type mapType;
	BOOL isMulti;
	
	BOOL	_isBlock;
	BOOL isLoadMapOver;
}
@property(nonatomic,assign,readonly)CGSize size;
@property(nonatomic,assign) CGPoint startPoint;
@property(nonatomic,assign) int mapId;
@property(nonatomic,assign) int parentMapId;
@property(nonatomic,assign) Map_Type mapType;
@property(nonatomic,assign) BOOL isBlock;
@property(nonatomic,assign) BOOL isLoadMapOver;

+(MapManager*)shared;
+(void)stopAll;

+(BOOL)checkDownloadMapSourceById:(int)mid target:(id)target call:(SEL)call;
+(BOOL)checkDownloadMapSource:(NSDictionary*)info target:(id)target call:(SEL)call;


-(BOOL)isEqualMapId:(int)mid;
-(void)setTargetMapId:(int)mid;
-(int)getTargetMapId;

-(void)loadMap;
-(void)removeMap;
-(BOOL)isShowMap;

-(void)checkMapPoint:(CGPoint)pos;

-(NSArray*)startRun:(CGPoint)po1 moveTo:(CGPoint)po2;
-(NSArray*)startRun:(CGPoint)po1 moveTo:(CGPoint)po2 block:(BOOL)_b;

-(BOOL)targetPointIsOpen:(CGPoint)point;
-(BOOL)tiledPointIsOpen:(CGPoint)point;
-(BOOL)tiledPointIsOpen:(CGPoint)point block:(BOOL)_b;

-(CGPoint)getPositionToTile:(CGPoint)point;
-(CGPoint)getTileToPosition:(CGPoint)point;
-(CGPoint)getNearOpenTiledPoint:(CGPoint)point start:(int)start length:(int)length;

-(BOOL)canSetLocation:(Map_Type)type;
-(void)setPlayerLocation:(CGPoint)point;

-(void)logParentMap;

//add Soul for minig and fish
//在指定的TMX中增加制定的图层，用于制作指定地图的功能 
/* _layer 指定的层 _key 寻找的值
 */
-(NSArray*)getFunctionRect:(NSString*)_layer key:(NSString*)_key;
-(NSArray*)getFunctionData:(NSString*)_layer key:(NSString*)_key;

-(NSString*)getMapName;

-(BOOL)checkMapCanShowTaskAlert;
-(BOOL)checkMapCanManyPeople;
-(BOOL)checkCanRunTask;



//-(void)setBlockName:(NSString*)_name;
//-(void)removeBlockName;

-(CGSize)maxSize;
-(CGSize)tileSize;

@end
