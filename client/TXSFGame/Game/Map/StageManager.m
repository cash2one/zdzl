//
//  StageManager.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-19.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "StageManager.h"
#import "Task.h"
#import "Game.h"
#import "GameConfigure.h"
#import "MapManager.h"
#import "Monster.h"
#import "MapManager.h"
#import "FightManager.h"
#import "RoleManager.h"
#import "StageTask.h"
#import "GameDB.h"
#import "RolePlayer.h"
#import "NPCManager.h"
#import "TaskManager.h"

@implementation StageManager
@synthesize stageId;
@synthesize mapId;
@synthesize task;
@synthesize other;

static StageManager * stageManager;
+(StageManager*)shared{
	if(!stageManager){
		stageManager = [[StageManager alloc] init];
	}
	return stageManager;
}

+(void)stopAll{
	if(stageManager){
		[stageManager release];
		stageManager = nil;
	}
	[StageTask remove];
}

+(int)currentStageId{
	if (stageManager) {
		return stageManager.stageId;
	}
	return 0;
}

+(BOOL)onTargetMap{
	if(stageManager){
		if(stageManager.mapId==[MapManager shared].mapId){
			return YES;
		}
	}
	return NO;
}

+(void)saveStopTask:(Task *)_task{
	if (stageManager != nil) {
		if (stageManager.task == _task) {
			stageManager.task = nil;
		}
	}
}

-(void)dealloc{
	
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	[self cleanStageData];
	[super dealloc];
	
	CCLOG(@"StageManager dealloc");
}

-(void)setOther:(NSArray*)o{
	if(other) [other release];
	other = [NSArray arrayWithArray:o];
	[other retain];
	
	CCLOG(@"set other");
}

-(void)setTask:(Task *)_task{
	task = _task;
	//清除全部NPC
	//[[NPCManager shared] clearAllNPC];
	
	if(task){
		[self checkStageRunOnMap];
	}else{
		[self cleanStageData];
	}
	
}

-(void)cleanStageMapData{
	[self removeAllMonster];
}

-(void)cleanStageData{
	
	CCLOG(@"cleanStageData");
	
	[self cleanStageMapData];
	
	if(other) [other release];
	other = nil;
	
	task = nil;
	
	mapId = 0;
	stageId = 0;
	totalCount = 0;
	killCount = 0;
	chooseFightId = 0;
	
}

-(void)checkStageOnInit{
	
	NSString * userStage = [[GameConfigure shared] getUserStage];
	if(userStage){
		NSArray * a = [userStage componentsSeparatedByString:@":"];
		if([a count]>=2){
			int sid = [[a objectAtIndex:0] intValue];
			if (sid > 0) {
				stageId = sid;
				killCount = [[a objectAtIndex:1] intValue];
				
				NSDictionary * info = [[GameDB shared] getStageInfo:stageId];
				if(info){
					mapId = [[info objectForKey:@"mapId"] intValue];
				}
				
			}
		}
	}
	
}

-(void)checkStageRunOnMap{
	
	//判断是不是需要初始化任务怪物
	if (![[TaskManager shared] checkStageMonsterInit]) {
		CCLOG(@"TaskManager checkStageMonsterInit");
		return;
	}
	
	//[self checkStageOnInit];
	if(stageId>0 && [StageManager onTargetMap]){
		[self loadStageData];
	}
	
	CCLOG(@"checkStageRunOnMap");
	
}

-(void)startStageById:(int)sid{
	
	[self cleanStageData];
	
	stageId = sid;
	NSString * stage = [[GameConfigure shared] getUserStageByStageId:stageId];
	if(stage){
		NSArray * a = [stage componentsSeparatedByString:@":"];
		if([a count]>=2){
			killCount = [[a objectAtIndex:1] intValue];
			chooseFightId = 0;
		}
	}else{
		totalCount = 0;
		killCount = 0;
		chooseFightId = 0;
	}
	[[GameConfigure shared] setUserStage:stageId kill:killCount];
	
	NSDictionary * info = [[GameDB shared] getStageInfo:stageId];
	if(info){
		mapId = [[info objectForKey:@"mapId"] intValue];
	}
	
	[[Game shared] trunToMap:mapId target:nil call:nil];
	
}

-(void)loadStageData{
	
	CCLOG(@"loadStageData");
	
	if(monsters) return;
	
	//清除全部NPC
	[[NPCManager shared] clearAllNPC];
	
	if(chooseFightId>0 && [FightManager isWinFight]==NO){
		[[RoleManager shared] movePlayerToStartPoint];
	}
	
	monsters = [NSMutableArray array];
	[monsters retain];
	
	//soul
	//NSDictionary * info = [[GameConfigure shared] getStageInfoById:stageId];
	NSDictionary * info = [[GameDB shared] getStageInfo:stageId];
	NSString * string = [info objectForKey:@"monster"];
	
	NSArray * m1 = [string componentsSeparatedByString:@"|"];
	totalCount = [m1 count];
	for(int i=0;i<totalCount;i++){
		NSString * m2 = [m1 objectAtIndex:i];
		if([m2 length]>0){
			
			if(i>(killCount-1)){
				NSArray * m3 = [m2 componentsSeparatedByString:@":"];
				Monster * monster = [Monster getMonsterByStageData:m3];
				if(monster){
					monster.index = i;
					[monsters addObject:monster];
				}
			}
			
		}
	}
	
	[self startMonsterAction:YES];
	
	//1.28秒延时 还是会有重复战斗的可能
	//这里需要直接不开，胜利的情况
	if ([FightManager isWinFight]) {
		Monster * target_monster = [self getFightMonster];
		if(target_monster){
			[target_monster startMonsterAction:NO];
		}
	}
	
	[NSTimer scheduledTimerWithTimeInterval:0.38f 
									 target:self selector:@selector(checkStageOver) 
								   userInfo:nil repeats:NO];
	
}

-(void)startFight:(int)fid{
	
	CCLOG(@"startFight : %d",fid);
	chooseFightId = fid;
	
	Monster * target_monster = [self getFightMonster];
	if(target_monster){
		
		[target_monster startMonsterAction:NO];
		
		if(other){
			
			CCLOG(@"fight monster index : %d",target_monster.index);
			for(NSDictionary * p in other){
				int index = [[p objectForKey:@"index"] intValue];
				if(index==target_monster.index){
					NSArray * before = [p objectForKey:@"before"];
					if(before){
						CCLOG(@"show before task");
						
						[StageTask show:before target:self call:@selector(intoFight)];
						
						return;
					}
				}
			}
			
		}
	}
	
	//延时开始，让数据清除
	[NSTimer scheduledTimerWithTimeInterval:0.01f
									 target:self
								   selector:@selector(intoFight)
								   userInfo:nil
									repeats:NO];

	//[self intoFight];
}

-(void)intoFight{
	//clean all monster
	[self removeAllMonster];
	[[FightManager shared] startFightById:chooseFightId target:self call:@selector(endFight)];
}

-(void)endFight{
	
	CCLOG(@"doEndFight");
	
	if ([FightManager isWinFight]) {
		
		Monster * target_monster = [self getFightMonster];
		
		//正常打死怪物之后，更新副本怪物数据，移走
		killCount += 1;
		[[GameConfigure shared] setUserStage:stageId kill:killCount];
		
		if(target_monster){
			
			[target_monster startMonsterAction:NO];
			
			//TODO check show Task other
			CCLOG(@"fight monster index : %d",target_monster.index);
			for(NSDictionary * p in other){
				int index = [[p objectForKey:@"index"] intValue];
				if(index==target_monster.index){
					NSArray * behind = [p objectForKey:@"behind"];
					if(behind){
						CCLOG(@"show behind task");
						[StageTask show:behind target:self call:@selector(removeTargetMonster)];
						
						[RoleManager shared].player.followTarget = nil;
						
						return;
					}
				}
			}
			
		}
		
		[self removeTargetMonster];
		
	}else{
		
		[[RoleManager shared] movePlayerToStartPoint];
	}
}

-(Monster*)getFightMonster{
	for(Monster * monster in monsters){
		if(monster.fightId==chooseFightId){
			return monster;
		}
	}
	return nil;
}

#pragma mark -

-(void)startMonsterAction:(BOOL)isStart{
	for(Monster * monster in monsters){
		[monster startMonsterAction:isStart];
	}
}

-(void)removeTargetMonster{
	
	Monster * target_monster = [self getFightMonster];
	if(target_monster != nil){
		[target_monster removeFromParentAndCleanup:YES];
		[monsters removeObject:target_monster];
	}
	
	chooseFightId = 0;
	[self checkStageOver];
}

-(void)removeAllMonster{
	if(monsters){
		for(Monster * monster in monsters){
			if(monster.parent){
				[monster removeFromParentAndCleanup:YES];
			}
		}
	}
	if (monsters) {
		[monsters removeAllObjects];
		[monsters release];
		monsters = nil;
	}
}

#pragma mark -

-(void)checkStageOver{
	
	if(!monsters) return;
	if([monsters count]==0){
		CCLOG(@"stage clean all");
		if ([TaskManager shared].runingTask != nil) {
			if ([TaskManager shared].runingTask.currentAction == Task_Action_stage) {
				if ([[TaskManager shared].runingTask getStageId] == self.stageId) {
					[[TaskManager shared].runingTask endStep];
					[[GameConfigure shared] removeUserStage:stageId];
					[self cleanStageData];
				}
			}
		}
	}else{
		if(killCount<totalCount){
			[RoleManager shared].player.followTarget = [monsters objectAtIndex:0];
		}
	}
	
}

-(CGPoint)getTracePoint{
	if (monsters) {
		for(Monster * monster in monsters){
			return monster.point;
		}
	}
	return ccp(-1, -1);
}

-(BOOL)checkHasMonsters{
	return ((monsters != nil) && monsters.count > 0);
}

@end
