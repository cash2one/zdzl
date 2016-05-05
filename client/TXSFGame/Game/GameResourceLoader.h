//
//  GameResourceLoader.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-18.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	PathType_map = 1,
	PathType_map_npc = 2,
	PathType_map_monster = 3,
	
	PathType_fight_bg = 11,
	PathType_fight_role = 12,
	PathType_fight_effects = 13,
	PathType_fight_sname = 14,
	
	PathType_car = 21,
	PathType_role = 22,
	PathType_role_image = 23,
	PathType_role_thumb = 24,
	
	PathType_icon_equip = 31,
	PathType_icon_fate = 32,
	PathType_icon_item = 33,
	PathType_icon_spirit = 34,
	PathType_icon_task = 35,
	PathType_icon_car = 36,
	
	PathType_icon_role = 60,
	PathType_icon_monster = 61,
	PathType_icon_member = 62,
	PathType_icon_team = 63,
	
	PathType_weapon = 50,
	
	PathType_talk_npc = 70,
	PathType_talk_role = 71,
	
	PathType_activity = 80,
	
	PathType_inbetweening = 81,//插画
	PathType_icon_jewel = 82,
	
}PathType;

@class ASINetworkQueue;
@class ASIHTTPRequest;
@interface GameLoaderHelper : NSObject{
	
	NSString * path;
	id target;
	SEL call;
	
	BOOL isUnzip;
	BOOL isFire;
	BOOL isError;
	
	ASIHTTPRequest * request;
	NSMutableArray * bondingOther;
	NSMutableArray * parallelHelpers;
	
	int type;
	int retryCount;
	
	BOOL isPostLoading;
}
@property(nonatomic,assign) NSString * path;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL call;
@property(nonatomic,assign) BOOL isUnzip;
@property(nonatomic,assign) int type;
@property(nonatomic,readonly) BOOL isFire;
@property(nonatomic,readonly) BOOL isError;
@property(nonatomic,assign) BOOL isPostLoading;

+(GameLoaderHelper*)createHelper;
+(GameLoaderHelper*)create:(NSString*)path;
+(GameLoaderHelper*)create:(NSString*)path isUnzip:(BOOL)upzip;
+(GameLoaderHelper*)create:(NSString*)path target:(id)target call:(SEL)call;

+(NSArray*)helpersFilter:(NSArray*)helpers;

-(NSString*)getDownloadUrl;
-(NSString*)getSavePath;
-(ASIHTTPRequest*)getHTTPRequest;
-(void)bondOthers:(NSArray*)helpers;
-(void)unbondHelper:(GameLoaderHelper*)helper;
-(void)unbondOthers:(NSArray*)helpers;

-(void)free;
-(void)fire;

-(BOOL)isIdenticalHelper:(GameLoaderHelper*)helper;
-(BOOL)isEqualUrlHelper:(GameLoaderHelper*)helper;
-(BOOL)isEqualCallHelper:(GameLoaderHelper*)helper;

-(void)addParallelHelper:(GameLoaderHelper*)helper;

@end

@interface GameResourceLoader : NSObject{
	NSString * resourcePath;
	NSString * downloadPath;
	
	ASINetworkQueue * networkQueue;
	NSMutableArray * downloading;
	
}
@property(nonatomic,readonly) NSString * resourcePath;
@property(nonatomic,assign) NSString * downloadPath;

+(void)cleanCache;
+(GameResourceLoader*)shared;
+(void)stopAll;
+(void)downloadPercentHandle:(id)handle;

+(NSString*)getFilePathByType:(PathType)type target:(NSString*)target;
+(void)createAllDirectory;
+(void)createDirectoryByType:(PathType)type;

-(void)syncDownloadHelpers:(NSArray*)helpers;
-(void)downloadHelper:(GameLoaderHelper*)helper;
-(void)delayDownloadHelper:(GameLoaderHelper*)helper time:(float)time;

-(BOOL)checkDownloadingTarget:(GameLoaderHelper*)target;

-(void)stop;



@end
