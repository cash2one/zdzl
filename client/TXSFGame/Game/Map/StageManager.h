//
//  StageManager.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-19.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Task;
@class Monster;

@interface StageManager : NSObject{
	int stageId;
	int mapId;
	int totalCount;
	int killCount;
	NSArray * other;
	NSMutableArray * monsters;
	
	Task * task;
	int chooseFightId;
	
}
@property(nonatomic,assign) int stageId;
@property(nonatomic,assign) int mapId;

@property(nonatomic,assign) Task * task;
@property(nonatomic,assign) NSArray * other;

+(StageManager*)shared;
+(void)stopAll;
+(int)currentStageId;
+(BOOL)onTargetMap;
+(void)saveStopTask:(Task*)_task;

-(void)checkStageOnInit;
-(void)checkStageRunOnMap;

-(void)cleanStageMapData;
-(void)cleanStageData;

-(void)startStageById:(int)sid;
-(void)startFight:(int)fid;

-(CGPoint)getTracePoint;
-(BOOL)checkHasMonsters;

@end
