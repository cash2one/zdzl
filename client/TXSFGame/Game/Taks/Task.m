//
//  Task.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-15.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "Task.h"
#import "Game.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "CJSONDeserializer.h"
#import "MapManager.h"
#import "RoleManager.h"
#import "NPCManager.h"
#import "Game.h"
#import "TaskManager.h"
#import "TaskTalk.h"
#import "GameEffects.h"
#import "GameUI.h"
#import "Game.h"
#import "GameLayer.h"
#import "StageManager.h"
#import "FightManager.h"
#import "Window.h"
#import "RolePlayer.h"
#import "MovingAlert.h"
#import "UnlockAlert.h"
#import "GameNPC.h"
#import "Window.h"
#import "Config.h"
#import "WorldMap.h"
#import "intro.h"
#import "TimeBox.h"
//#import "PlayerSit.h"

#define DEFAULT_DISTANCE 80

@implementation Task

@synthesize icon;

@synthesize exp;
@synthesize userTaskId;
@synthesize taskId;
@synthesize step;
@synthesize stepCount;
@synthesize isRun;
//@synthesize isLock;
@synthesize type;
@synthesize status;
@synthesize bWaitFinish;

@synthesize taskInfo;
@synthesize execute;
@synthesize isDoingStep;

@synthesize currentAction;
@synthesize parentAction;

@synthesize pauseCall;
@synthesize pauseTarget;
@synthesize isPause;

@synthesize runingStepData;


+(Task*)TaskWithData:(NSDictionary*)data{
	Task * task = [[[Task alloc] init] autorelease];
	task.bWaitFinish = NO;
	[task setData:data];
	return task;
}

-(void)dealloc{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	if(taskInfo){
		[taskInfo release];
		taskInfo = nil;
	}
	if(runingStepData){
		[runingStepData release];
		runingStepData = nil;
	}
	[super dealloc];
	CCLOG(@"Task dealloc");
}

-(NSDictionary*)loadSteps{
	//NSDictionary * info = [[GameConfigure shared] getTaskInfoById:taskId];
	NSString * jsonString = [taskInfo objectForKey:@"step"];
	NSData * jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	
	NSError * error = nil;
	NSDictionary * steps = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&error];
	
	return steps;
}

-(void)setData:(NSDictionary*)data{
	
	userTaskId = [[data objectForKey:@"id"] intValue];
	taskId = [[data objectForKey:@"tid"] intValue];
	step = [[data objectForKey:@"step"] intValue];
	isRun = [[data objectForKey:@"isRun"] boolValue];
	status = [[data objectForKey:@"status"] intValue];
	
	
	//NSDictionary * info = [[GameConfigure shared] getTaskInfoById:taskId];
	taskInfo = [[GameConfigure shared] getTaskInfoById:taskId];
	[taskInfo retain];
	type = [[taskInfo objectForKey:@"type"] intValue];
	icon = [[taskInfo objectForKey:@"icon"] intValue];
	
	//TODO 或者任务自己的经验奖励
	exp = 0 ;
	/*
	int rewardId = [[taskInfo objectForKey:@"rid"] intValue];
	if (rewardId > 0) {
		NSDictionary *dict = [[GameDB shared] getRewardInfo:rewardId];
		if(dict){
			CCLOG([dict description]);
			NSError * error = nil;
			NSData * data = getDataFromString([dict objectForKey:@"reward"]);
			NSDictionary * rewards = [[CJSONDeserializer deserializer] deserializeAsArray:data error:&error];
			if(!error){
				for(NSDictionary * reward in rewards){
					NSString * t = [reward objectForKey:@"t"];
					int i = [[reward objectForKey:@"i"] intValue];
					int c = [[reward objectForKey:@"c"] intValue];
					if(t != nil && [t isEqualToString:@"i"] && i<=6){
						//经验
						if (i == 4) {
							exp = c ;
						}
					}
				}
			}
		}
	}
	 */
	
	NSDictionary * stepData = [self loadSteps];
	stepCount = [[stepData objectForKey:@"count"] intValue];
	
}

-(NSDictionary*)getStepDataByIndex:(int)index{
	if(index<0) index=0;
	NSDictionary * stepData = [self loadSteps];
	NSArray * steps = [stepData objectForKey:@"step"];
	//[steps objectAtIndex:step];
	if (index >= steps.count) {
		return nil;
	}
	return [steps objectAtIndex:index];
}

-(void)loadStepData{
	
	parentAction = Task_Action_none;
	execute = MANUAL;
	
	if(runingStepData) [runingStepData release];
	runingStepData = [NSDictionary dictionaryWithDictionary:[self getStepDataByIndex:step]];
	
	if(runingStepData){
		[runingStepData retain];
		
		currentAction = [[runingStepData objectForKey:@"action"] intValue];
		execute=[[runingStepData objectForKey:@"auto"] intValue];
		
		if(step>0){
			NSDictionary * data = [self getStepDataByIndex:(step-1)];
			parentAction = [[data objectForKey:@"action"] intValue];
		}
	}
	
}
//任务解锁判断
-(BOOL)isUnlock{
	BOOL unlock = YES;
	if (taskInfo) {
		NSString *condition = [taskInfo objectForKey:@"unlock"];
		if (condition && condition.length > 0){
			NSArray *array = [condition componentsSeparatedByString:@"|"];
			for (NSString *iterate in array) {
				if (iterate.length > 0) {
					NSRange rang = [iterate rangeOfString:@":"];
					NSString *conditionType = [iterate substringToIndex:rang.location];
					NSString *conditionContent = [iterate substringFromIndex:rang.location+1];
					if ([conditionType isEqualToString:@"task"]) {
						unlock = [self checkTaskCondition:conditionContent];
					}else if ([conditionType isEqualToString:@"level"]) {
						unlock = [self checkLevelCondition:conditionContent];
					}else if ([conditionType isEqualToString:@"role"]) {
						unlock = [self checkRoleCondition:conditionContent];
					}else if ([conditionType isEqualToString:@"obj"]) {
						unlock = [self checkObjectCondition:conditionContent];
					}else if ([conditionType isEqualToString:@"equ"]) {
						unlock = [self checkEquipmentCondition:conditionContent];
					}
				}
			}
		}
	}
	return unlock;
}
-(BOOL)checkTaskCondition:(NSString*)_content{
	if (_content) {
		NSArray *array = [_content componentsSeparatedByString:@":"];
		NSArray *completeList = [[TaskManager shared].completeList allKeys];
		for (NSString *cmp in array) {
			if (![completeList containsObject:cmp]) {
				return NO;
			}
		}
	}
	return YES;
}
/*
 * 等级判断
 */
-(BOOL)checkLevelCondition:(NSString*)_content{
	if (_content) {
		NSArray *array = [_content componentsSeparatedByString:@":"];
		int startLevel = [[array objectAtIndex:0] intValue];
		int endLevel = [[array objectAtIndex:1] intValue];
		NSDictionary *player= [[GameConfigure shared] getPlayerInfo];
		int level = [[player objectForKey:@"level"] intValue];
		if (level >= startLevel && level < endLevel) {
			return YES;
		}
	}
	return NO;
}
/*
 *角色判断
 */
-(BOOL)checkRoleCondition:(NSString*)_content{
	if (_content) {
		NSArray *array = [_content componentsSeparatedByString:@":"];
		for (NSString *cmp in array) {
			int _rid = [cmp intValue];
			if (nil == [[GameConfigure shared] getPlayerRoleFromListById:_rid]) {//只要一个角色没有 就不能解锁
				return NO;
			}
		}
	}
	return YES;
}
/*
 *物品判断
 */
-(BOOL)checkObjectCondition:(NSString*)_content{
	if (_content) {
		NSArray *array = [_content componentsSeparatedByString:@":"];
		for (int i = 0 ; i < (array.count-1); i+=2) {
			int _iid = [[array objectAtIndex:i] intValue];
			int count = [[array objectAtIndex:i+1]intValue];
			int num = [[GameConfigure shared] getPlayerItemCountByIid:_iid];
			if (num < count) {
				return NO;
			}
		}
	}
	return YES;
}
/*
 * 判断装备
 */
-(BOOL)checkEquipmentCondition:(NSString*)_content{
	if (_content) {
		NSArray *array = [_content componentsSeparatedByString:@":"];
		for (NSString *cmp in array) {
			int eid = [cmp intValue];
			if (nil == [[GameConfigure shared] getPlayerEquipInfoWithBaseId:eid]) {
				return NO;
			}
		}
	}
	return YES;
}
//------------------------------------------------
//add soul
-(Task_Action)getNextAction{
	Task_Action _value = Task_Action_none ;
	int next = step+1;
	if (next < stepCount) {
		NSDictionary *tData = [self getStepDataByIndex:next];
		if (tData) {
			_value = [[tData objectForKey:@"action"] intValue];
		}
	}
	return _value;
}
//------------------------------------------------

//==============================================================================
//对话
//==============================================================================
-(void)doStepTalk{
	
	CCLOG(@"doStepTalk");
	
	self.isDoingStep = YES;
	
	NSDictionary *npcDict = [runingStepData objectForKey:@"ret"];
	
	if (nil != npcDict) {
		
		int mid = [[npcDict objectForKey:@"mid"] intValue];
		int nid = [[npcDict objectForKey:@"nid"] intValue];
		
		if (mid > 0) {
			
			if (mid == [MapManager shared].mapId) {
				
				GameNPC * npc = [[NPCManager shared] getNPCById:nid];
				
				if (npc != nil) {
					
					CGPoint point = [npc getPlayerPoint];
					[RoleManager shared].player.targetPoint = npc.position;
					
					[[NPCManager shared] unSelectNPC];
					
					npc.isSelected = YES ;
					/*
					[[RoleManager shared] movePlayerTo:point
												target:self
												  call:@selector(endDoStepTalk)
					 ];*/
					
					[[TaskManager shared] proxy_TaskPlayerMove:point Task:self];
					
				}else{
					[self endDoStepTalk];
				}
				
			}else{
				//[[Game shared] trunToMap:mid target:self call:@selector(runStep)];
				[[TaskManager shared] proxy_TaskTurnToMap:mid Task:self];
			}
			
		}else{
			[self endDoStepTalk];
		}
		
	}else{
		[self endDoStepTalk];
	}
}
-(void)endDoStepTalk{
	if (currentAction == Task_Action_talk) {
		/*
		if (![TaskTalk isTalking]) {
			NSArray * data = [runingStepData objectForKey:@"data"];
			[TaskTalk show:data target:self call:@selector(endStep)];
		}*/
		
		[[TaskManager shared] proxy_TaskTalk:self];
		
	}else{
		CCLOG(@"endDoStepTalk -> currentAction != Task_Action_talk");
	}
}
//==============================================================================
//移动
//==============================================================================
-(void)doStepMove{
	self.isDoingStep = YES;
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int mapId = [[data objectForKey:@"mapId"] intValue];
	if(mapId==[MapManager shared].mapId){
		
		CGPoint point = CGPointFromString([data objectForKey:@"point"]);
		if(point.x==0&&point.y==0) point = [MapManager shared].startPoint;
		point = [[MapManager shared] getTileToPosition:point];
		
		//=======================================================
		if([[RoleManager shared] getPointDistanceWithPlayer:point] > DEFAULT_DISTANCE) {
			[MovingAlert show];
		}
		//=======================================================
		
		[RoleManager shared].player.targetPoint = point;
		
		/*
		[[RoleManager shared] movePlayerTo:point
									target:self
									  call:@selector(endStep)
		 ];
		*/
		[[TaskManager shared] proxy_TaskPlayerMove:point Task:self];
		
	}else{
		//[[Game shared] trunToMap:mapId target:self call:@selector(runStep)];
		[[TaskManager shared] proxy_TaskTurnToMap:mapId Task:self];
	}
}
//==============================================================================
//移动到NPC
//==============================================================================
-(void)doStepMoveToNPC{
	self.isDoingStep = YES;
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int mapId = [[data objectForKey:@"mapId"] intValue];
	if(mapId==[MapManager shared].mapId){
		
		int npcId = [[data objectForKey:@"npcId"] intValue];
		GameNPC * npc = [[NPCManager shared] getNPCById:npcId];
		
		//-----
		//test !
		if (npc == nil) {
			CCLOG(@"npc is null");
			
			//NSString* msg = [NSString stringWithFormat:@"Task:%d Step:%d Npc:%d Map:%d",self.taskId,self.step,npcId,mapId];
			//[[TaskManager shared] throwTaskException:msg exception:TaskException_no_npc];
			
			self.isDoingStep = NO;
			
			//todo 默认让他们完成吧.....
			[self endStep];
			
			return ;
		}
		//-----
		CGPoint point = [npc getPlayerPoint];
		
		//=======================================================
		if([[RoleManager shared] getPointDistanceWithPlayer:point] > DEFAULT_DISTANCE) {
			[MovingAlert show];
		}
		//=======================================================
		
		[[NPCManager shared] unSelectNPC];
		
		npc.isSelected = YES ;
		
		[RoleManager shared].player.targetPoint = npc.position;
		
		/*
		[[RoleManager shared] movePlayerTo:point
									target:self
									  call:@selector(endStep)
		 ];
		 */
		[[TaskManager shared] proxy_TaskPlayerMove:point Task:self];
		
	}else{
		//[[Game shared] trunToMap:mapId target:self call:@selector(runStep)];
		[[TaskManager shared] proxy_TaskTurnToMap:mapId Task:self];
	}
}
//==============================================================================
//添加NPC
//==============================================================================
-(void)doStepAddNPC{
	self.isDoingStep = YES;
	
	[[TaskManager shared] proxy_TaskAddNPC:self];
	
	/*
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int mapId = [[data objectForKey:@"mapId"] intValue];
	
	int npcId = [[data objectForKey:@"npcId"] intValue];
	CGPoint point = CGPointFromString([data objectForKey:@"point"]);
	int direction = [[data objectForKey:@"direction"] intValue];
	
	if([[GameConfigure shared] addUserMapNPC:npcId map:mapId point:point direction:direction]){
		
		if(mapId==[MapManager shared].mapId){
			[[NPCManager shared] addNPCById:npcId tilePoint:point direction:direction];
		}
		
	}
	
	[self endStep];
	*/
}
//==============================================================================
//转移NPC
//==============================================================================
-(void)doStepMoveNPC{
	self.isDoingStep = YES;
	
	[[TaskManager shared] proxy_TaskMoveNPC:self];
	
	/*
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int mapId = [[data objectForKey:@"mapId"] intValue];
	int npcId = [[data objectForKey:@"npcId"] intValue];
	CGPoint point = CGPointFromString([data objectForKey:@"point"]);
	int direction = [[data objectForKey:@"direction"] intValue];
	
	//remove npc
	[[GameConfigure shared] removeUserMapNPC:npcId map:mapId];
	if(mapId==[MapManager shared].mapId){
		[[NPCManager shared] removeNPCById:npcId];
	}
	
	//add npc
	[[GameConfigure shared] addUserMapNPC:npcId map:mapId point:point direction:direction];
	if(mapId==[MapManager shared].mapId){
		[[NPCManager shared] addNPCById:npcId tilePoint:point direction:direction];
	}
	
	[self endStep];
	 */
}
//==============================================================================
//
//==============================================================================
-(void)doStepRemoveNPC{
	self.isDoingStep = YES;
	[[TaskManager shared] proxy_TaskRemoveNPC:self];
	/*
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int mapId = [[data objectForKey:@"mapId"] intValue];
	int npcId = [[data objectForKey:@"npcId"] intValue];
	
	//remove npc
	[[GameConfigure shared] removeUserMapNPC:npcId map:mapId];
	
	if(mapId==[MapManager shared].mapId){
		[[NPCManager shared] removeNPCById:npcId];
	}
	[self endStep];
	*/
	
}
//==============================================================================
//
//==============================================================================
-(void)doStepEffects{
	self.isDoingStep = YES;
	/*
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	if (![GameEffects isShowEffect:taskId taskStep:step]) {
		[[GameEffects share] showEffectsWithDict:data
										  target:self
											call:@selector(endStep) taskId:taskId taskStep:step];
	}*/
	[[TaskManager shared] proxy_TaskEffects:self];
	/*
	[[GameEffects share] showEffectsWithDict:data
									  target:self
										call:@selector(endStep) taskId:taskId taskStep:step];
	*/
}
//==============================================================================
//
//==============================================================================
-(void)doStepUnlock{
	self.isDoingStep = YES;
	
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int _unlockID = [[data objectForKey:@"unlockID"] intValue];
	if ([[GameConfigure shared] checkPlayerFunction:_unlockID]) {
		if (checkTutorial(_unlockID)) {
			
			if (_unlockID == Unlock_timebox) {
				//进入时间盒
				[[Intro share]removeCurrenTipsAndNextStep:INTRO_OPEN_TimeBox];
				[TimeBox enterTimeBox];
				
			}else{
				//进入相应的窗口界面
				[[Window shared] showWindowByUnlock:_unlockID];
			}
			
		}else{
			[self endStep];
		}
	}else{
		/*
		//如果第一解锁的时候 在没正常回调之前就退出游戏
		//这里就补回那一步
		//玩家如果如果强制点
		//在doTask的时候双重检测
		[[Intro share] runIntroUnLockTask:_unlockID];
		
		if (checkTutorial(_unlockID)) {
			//有教程的情况
			[GameEffectsBlockTouck lockScreen:self call:@selector(runStep)];
			[UnlockAlert show:data target:nil call:nil];
		}else{
			//没教程的情况
			[UnlockAlert show:data target:self call:@selector(runStep)];
		}*/
		[[TaskManager shared] proxy_TaskUnlock:self];
	}
}
//==============================================================================
//开启外传地图
//==============================================================================
-(void)doStepOpenExternalMap{
	CCLOG(@"Task_Action_openExternalMap");
	if (currentAction != Task_Action_openExternalMap) return ;
	CCLOG(@"currentAction == Task_Action_openExternalMap");
	//self.isDoingStep = YES ;
	/*
	//修改章节地图数据
	//这里需要验证重复执行
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	
	int cid = [[data objectForKey:@"cid"] intValue];
	int mid = [[data objectForKey:@"mid"] intValue];
	
	[[GameConfigure shared] addUserWorldMap:cid map:mid];
	
	[self endStep];
	 */
	[[TaskManager shared] proxy_TaskUpdateMap:self];
	
}
//==============================================================================
//修改章节地图
//==============================================================================

-(void)doStepUpdateMap{
	CCLOG(@"Task_Action_openMap");
	if (currentAction != Task_Action_openMap) return ;
	CCLOG(@"currentAction == Task_Action_openMap");
	//self.isDoingStep = YES ;
	//修改章节地图数据
	//这里需要验证重复执行
	/*
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int cid = [[data objectForKey:@"cid"] intValue];
	int mid = [[data objectForKey:@"mid"] intValue];
	[WorldMap updateChapterMap:cid map:mid];
	
	[self endStep];
	 */
	[[TaskManager shared] proxy_TaskUpdateMap:self];
}
//==============================================================================
//
//==============================================================================
-(void)doStepStage{
	
	CCLOG(@"doStepStage");
	
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int sid = [[data objectForKey:@"sid"] intValue];
	if([StageManager currentStageId] == sid && [StageManager onTargetMap]){
		CCLOG(@"YES !!! on target stage map");
		return;
	}
	
	if(parentAction==Task_Action_moveToNPC){
		NSDictionary * stepData = [self getStepDataByIndex:(step-1)];
		NSDictionary * data = [stepData objectForKey:@"data"];
		int mapId = [[data objectForKey:@"mapId"] intValue];
		
		if(mapId==[MapManager shared].mapId){
			
			int npcId = [[data objectForKey:@"npcId"] intValue];
			//CGPoint point = [[NPCManager shared] getNPCPointById:npcId];
			
			GameNPC * npc = [[NPCManager shared] getNPCById:npcId];
			CGPoint point = [npc getPlayerPoint];
			
			[[NPCManager shared] unSelectNPC];
			
			npc.isSelected = YES ;
			
			/*
			 
			[[RoleManager shared] movePlayerTo:point
										target:self
										  call:@selector(doStepStageEnd)
			 ];
			 */
			[[TaskManager shared] proxy_TaskPlayerMove:point Task:self];
			
		}else{
			//[[Game shared] trunToMap:mapId target:self call:@selector(runStep)];
			[[TaskManager shared] proxy_TaskTurnToMap:mapId Task:self];
			
		}
	}else{
		//direct enter stage
		[self doStepStageEnd];
	}
	
}
-(void)doStepStageEnd{
	CCLOG(@"doStepStageEnd");
	
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	
	int sid = [[data objectForKey:@"sid"] intValue];
	
	if([StageManager currentStageId] ==sid && [StageManager onTargetMap]){
		CCLOG(@"YES !!! on target stage map");
		return;
	}
	
	//TEST
	if ([TaskManager isTaskManagerRobot]) {
		[self endStep];
		return ;
	}
	
	[[StageManager shared] startStageById:sid];
	[StageManager shared].task = self;
	[StageManager shared].other = [data objectForKey:@"process"];
	
}

-(int)getStageId{
	if (currentAction == Task_Action_stage) {
		NSDictionary * data = [runingStepData objectForKey:@"data"];
		int sid = [[data objectForKey:@"sid"] intValue];
		return sid ;
	}
	return 0 ;
}
//==============================================================================
//
//==============================================================================
-(void)doStepFightShow{
	CCLOG(@"doStepFightShow");
	if(parentAction==Task_Action_moveToNPC){
		NSDictionary * stepData = [self getStepDataByIndex:(step-1)];
		NSDictionary * data = [stepData objectForKey:@"data"];
		int mapId = [[data objectForKey:@"mapId"] intValue];
		
		if(mapId==[MapManager shared].mapId){
			
			int npcId = [[data objectForKey:@"npcId"] intValue];
			
			GameNPC* npc = [[NPCManager shared] getNPCById:npcId];
			if (npc != nil) {
				[[NPCManager shared] unSelectNPC];
				
				npc.isSelected = YES ;
			}
			
			CGPoint point = [[NPCManager shared] getNPCPointById:npcId];
			
			/*
			[[RoleManager shared] movePlayerTo:point
										target:self
										  call:@selector(doStepFightShowEnd)
			 ];
			*/
			
			[[TaskManager shared] proxy_TaskPlayerMove:point Task:self];
			
		}else{
			//[[Game shared] trunToMap:mapId target:self call:@selector(runStep)];
			
			[[TaskManager shared] proxy_TaskTurnToMap:mapId Task:self];
			
		}
	}else{
		[NSTimer scheduledTimerWithTimeInterval:0.5
													 target:self
												   selector:@selector(doStepFightShowEnd)
												   userInfo:nil
													repeats:NO];
	}

}
-(void)doStepFightShowEnd{
	
	self.isDoingStep = YES;
	/*
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int fid = [[data objectForKey:@"fid"] intValue];
	
	if ([FightManager currentFightId] != fid) {
		[[FightManager shared] startCustomizeFight:data target:self call:@selector(doSetpFightResult)];
	}*/
	[[TaskManager shared] proxy_TaskStartCustomizeFight:self];
	
}
//==============================================================================
//
//==============================================================================
-(void)doStepFight{
	CCLOG(@"doStepFight");
	
	//TODO ???
	if(parentAction==Task_Action_moveToNPC){
		NSDictionary * stepData = [self getStepDataByIndex:(step-1)];
		NSDictionary * data = [stepData objectForKey:@"data"];
		int mapId = [[data objectForKey:@"mapId"] intValue];
		
		if(mapId==[MapManager shared].mapId){
			
			int npcId = [[data objectForKey:@"npcId"] intValue];
			
			GameNPC* npc = [[NPCManager shared] getNPCById:npcId];
			if (npc != nil) {
				[[NPCManager shared] unSelectNPC];
				npc.isSelected = YES ;
			}
			
			CGPoint point = [[NPCManager shared] getNPCPointById:npcId];
			
			/*
			[[RoleManager shared] movePlayerTo:point
										target:self
										  call:@selector(doStepFightEnd)
			 ];
			*/
			[[TaskManager shared] proxy_TaskPlayerMove:point Task:self];
			
		}else{
			//[[Game shared] trunToMap:mapId target:self call:@selector(runStep)];
			
			[[TaskManager shared] proxy_TaskTurnToMap:mapId Task:self];
			
		}
	}else{
		[NSTimer scheduledTimerWithTimeInterval:0.5
													 target:self
												   selector:@selector(doStepFightEnd)
												   userInfo:nil
													repeats:NO];
	}
	
}
-(void)doStepFightEnd{
	CCLOG(@"doStepFightEnd");
	self.isDoingStep = YES;
	/*
	NSDictionary * data = [runingStepData objectForKey:@"data"];
	int fid = [[data objectForKey:@"fid"] intValue];
	if ([FightManager currentFightId] != fid) {
		[[FightManager shared] startFightById:fid target:self call:@selector(doSetpFightResult)];
	}
	*/
	[[TaskManager shared] proxy_TaskStartFight:self];
	
}
-(void)doSetpFightResult{
	CCLOG(@"doSetpFightResult");
	
	//test
	if ([TaskManager isTaskManagerRobot]) {
		[self endStep];
		return ;
	}
	
	if([FightManager isWinFight]){
		[self endStep];
	}else{
		self.isDoingStep = NO;
		//[[GameUI shared] showTaskTips];
		[[GameUI shared] updateTaskStatus:0 taskStep:[self getStepIcon] type:self.type];
	}
}
//==============================================================================
//结束步骤
//==============================================================================

-(void)start{
	
	if(status==Task_Status_complete) return;
	
	[self loadStepData];
	
	
	if(nil == runingStepData){
		[NSTimer scheduledTimerWithTimeInterval:0.5
										 target:self
									   selector:@selector(doEndStep)
									   userInfo:nil
										repeats:NO];
		return ;
	}
	
	[self checkStatus];
	
	if (self.type == Task_Type_offer) {
		
		[self runStep];
		return ;
		
	}else if (self.type == Task_Type_main ||
			  self.type == Task_Type_hide ||
			  self.type == Task_Type_vice ||
			  NO){
		if (execute == AUTOEXEC) {
			/*if ([Game shared].bStartGame) {
				[Game shared].bStartGame=NO;
				if ([[TaskManager shared] checkIsChapter:self]) {
					[self runStep];
				}
			}else{
				[self runStep];
			}*/
			if ([Game shared].bStartGame) {
				[Game shared].bStartGame=NO;
			}else{
				[self runStep];
			}
		}else{
			if(currentAction == Task_Action_addNpc  ||
			   currentAction == Task_Action_openMap ||
			   currentAction == Task_Action_openExternalMap ||
			   NO){
				
				[NSTimer scheduledTimerWithTimeInterval:0.008
												 target:self
											   selector:@selector(runStep)
											   userInfo:nil
												repeats:NO];
				return;
			}
		}
	}	
}

//TODO check tips
-(void)checkStatus{
	
	//TODO show task to NPC tips
	if(status==Task_Status_complete) return;
	//int action = [[runingStepData objectForKey:@"action"] intValue];
	
	int mapId = -1;
	int npcId = -1;
	
	if(currentAction==Task_Action_moveToNPC){
		//TODO show NPC TIPS
		NSDictionary * data = [runingStepData objectForKey:@"data"];
		mapId = [[data objectForKey:@"mapId"] intValue];
		npcId = [[data objectForKey:@"npcId"] intValue];
		
	}
	
	if (currentAction != Task_Action_stage) {
		[StageManager shared].task = nil;
	}
	
	if(currentAction==Task_Action_stage ||
	   currentAction==Task_Action_fight ){
		
		//TODO show NPC TIPS
		if(parentAction==Task_Action_moveToNPC){
			
			NSDictionary * stepData = [self getStepDataByIndex:(step-1)];
			NSDictionary * data = [stepData objectForKey:@"data"];
			mapId = [[data objectForKey:@"mapId"] intValue];
			npcId = [[data objectForKey:@"npcId"] intValue];
			
			CCLOG(@"auto show stage tips");
			
		}
		
		if(currentAction==Task_Action_stage){
			NSDictionary * data = [runingStepData objectForKey:@"data"];
			int sid = [[data objectForKey:@"sid"] intValue];
			
			if([StageManager shared].stageId==sid){
				CCLOG(@"YES !!! on target stage map");
				NSDictionary * data = [runingStepData objectForKey:@"data"];
				[StageManager shared].task = self;
				[StageManager shared].other = [data objectForKey:@"process"];
			}
		}
		
	}
	
	if(mapId==[MapManager shared].mapId && npcId>0){
		[[NPCManager shared] bondTask:self toNpc:npcId];
	}
	
	//--------------------------------------------------------------------------
	[[GameUI shared] updateTaskStatus:0 taskStep:[self getStepIcon] type:self.type];
	
}

-(void)startStep{
	
	if(status==Task_Status_complete) return;
	
	[self loadStepData];
	
	[self checkStatus];
	
	//初始化完成
	_logic = TaskStep_init;
	//等待结束
	bWaitEnd = NO;
	
	CCLOG(@"startStep->%@",[self actionString:currentAction]);
	
	[[RoleManager shared].player stopMove];
	
	
	if ([TaskManager isTaskManagerRobot]) {
		CCLOG(@"TaskManager isTaskManagerRobot");
		[self runStep];
		return;
	}
	
	
	//==========================================================================
	//todo 这里可以移走
	//在解锁的步骤里面有检测
	if(currentAction==Task_Action_unlock){
		/*
		NSDictionary * data = [runingStepData objectForKey:@"data"];
		int _unlockID = [[data objectForKey:@"unlockID"] intValue];

		[[Intro share] runIntroUnLockTask:_unlockID];
		
		if (checkTutorial(_unlockID)) {
			//有教程的情况
			[GameEffectsBlockTouck lockScreen:self call:@selector(runStep)];
			[UnlockAlert show:data target:nil call:nil];
		}else{
			//没教程的情况
			[UnlockAlert show:data target:self call:@selector(runStep)];
		}*/
		[[TaskManager shared] proxy_TaskUnlock:self];
		
		return;
	}
	//==========================================================================
	
	
	if (execute == AUTOEXEC) {
		[self runStep];
		//[[GameUI shared] showTaskTips];
		return ;
	}
	
	//TODO auto run action by multi-condition
	if(parentAction==Task_Action_effects && currentAction==Task_Action_move){
		[NSTimer scheduledTimerWithTimeInterval:0.1
											target:self
									   selector:@selector(runStep)
									   userInfo:nil
										repeats:NO];
		return;
	}
	
	//TODO auto run action by single-condition
	//int action = [[runingStepData objectForKey:@"action"] intValue];
	if(currentAction==Task_Action_openMap){
		self.isDoingStep = YES ;
		[self runStep];
		return;
	}
	
	if(currentAction==Task_Action_talk){
		[self runStep];
		return;
	}
	if(currentAction==Task_Action_move){
		//[[GameUI shared] showTaskTips];
		return;
	}
	if(currentAction==Task_Action_moveToNPC){
		if(parentAction==Task_Action_stage ||
		   parentAction==Task_Action_fight ){
			[self runStep];
		}else{
			//[[GameUI shared] showTaskTips];
		}
		return;
	}
	
	//NPC
	if(currentAction==Task_Action_addNpc ||
	   currentAction==Task_Action_moveNpc ||
	   currentAction==Task_Action_removeNpc ||
	   NO){
		[self runStep];
		return;
	}
	
	if(currentAction==Task_Action_effects ||
	   NO){
		[self runStep];
		return;
	}
	
	//???? 这是什么
	if(currentAction==Task_Action_stage){
		if(parentAction==Task_Action_moveToNPC){
			CCLOG(@"auto in stage");
			[self doStepStageEnd];
		}else{
			//[[GameUI shared] showTaskTips];
		}
		return;
	}
	
	//???? 这是什么
	if(currentAction==Task_Action_fight){
		if(parentAction==Task_Action_moveToNPC){
			CCLOG(@"auto in fight");
			[self doStepFightEnd];
		}else{
			//[[GameUI shared] showTaskTips];
		}
		return;
	}
}

-(void)runStep{
	
	if(![TaskManager isCanRunTask]){
		CCLOG(@"TaskManager can not run task");
		return;
	}
	
	if(status==Task_Status_complete){
		return;
	}
	
	SEL call = nil;
	
	if(currentAction==Task_Action_talk)				call = @selector(doStepTalk);
	if(currentAction==Task_Action_move)				call = @selector(doStepMove);
	if(currentAction==Task_Action_moveToNPC)		call = @selector(doStepMoveToNPC);
	
	if(currentAction==Task_Action_addNpc)			call = @selector(doStepAddNPC);
	if(currentAction==Task_Action_moveNpc)			call = @selector(doStepMoveNPC);
	if(currentAction==Task_Action_removeNpc)		call = @selector(doStepRemoveNPC);
	
	if(currentAction==Task_Action_effects)			call = @selector(doStepEffects);
	if(currentAction==Task_Action_unlock)			call = @selector(doStepUnlock);
	
	if(currentAction==Task_Action_stage)			call = @selector(doStepStage);
	if(currentAction==Task_Action_fight)			call = @selector(doStepFight);
	
	if(currentAction==Task_Action_fightAction)		call = @selector(doStepFightShow);
	if(currentAction==Task_Action_openMap)			call = @selector(doStepUpdateMap);
	
	if(currentAction==Task_Action_openExternalMap)	call = @selector(doStepOpenExternalMap);
	
	self.isDoingStep=NO;
	_logic = TaskStep_run;
	
	if(call!=nil){
		[NSTimer scheduledTimerWithTimeInterval:0.05f
										 target:self
									   selector:call
									   userInfo:nil repeats:NO];
	}
	
}

-(void)endStep{
	
	//检查停止自动寻路提示
	[self checkStopMoveAlert];
	
	if(status == Task_Status_complete) return;
	if (currentAction == Task_Action_none) return ;
	if(currentAction == Task_Action_waitStart) return;
	
	
	CCLOG(@"doEndStep->%@",[self actionString:currentAction]);
	CCLOG(@"Task %d end step : %d/%d",taskId,step,(stepCount-1));
	
	currentAction = Task_Action_none;
	
	[[TaskManager shared] proxy_TaskEnd:self];
	
}

-(void)doEndStep{
	
	[[NPCManager shared] unbondTask:self];
	
	step++;
	_logic = TaskStep_end ;
	
	if(step>=stepCount){
		
		currentAction = Task_Action_end;
		status = Task_Status_complete;
		//[[TaskManager shared] completeTask];
		[[TaskManager shared] completeTask:self];
	}else{
		
		currentAction = Task_Action_waitStart ;
		
		[[GameConfigure shared] updateUserTask:userTaskId step:step];
		[[TaskManager shared] proxy_TaskStartStep:self];
		
	}

	isDoingStep=NO;
	
}

#pragma mark

-(BOOL)checkMoveToNpc:(CGPoint)_point{
	if (currentAction == Task_Action_moveToNPC) {
		NSDictionary * data = [runingStepData objectForKey:@"data"];
		int mapId = [[data objectForKey:@"mapId"] intValue];
		if(mapId==[MapManager shared].mapId){
			
			int npcId = [[data objectForKey:@"npcId"] intValue];
			CGPoint point = [[NPCManager shared] getNPCPointById:npcId];
			
			CGPoint tPoint = [[MapManager shared] getPositionToTile:point];
			
			return (_point.x == tPoint.x && _point.y == tPoint.y);
		}
	}else if (currentAction == Task_Action_move){
		NSDictionary * data = [runingStepData objectForKey:@"data"];
		int mapId = [[data objectForKey:@"mapId"] intValue];
		if(mapId==[MapManager shared].mapId){
			
			CGPoint point = CGPointFromString([data objectForKey:@"point"]);
			if(point.x==0&&point.y==0) point = [MapManager shared].startPoint;
			return (_point.x == point.x && _point.y == point.y);
			
		}
	}
	return NO;
}

-(NSDictionary*)getLatelyMoveStepData{
	int _per = step - 1;
	while (_per >= 0) {
		NSDictionary *dict = [NSDictionary dictionaryWithDictionary:[self getStepDataByIndex:_per]];
		Task_Action _action = [[dict objectForKey:@"action"] intValue];
		if (_action == Task_Action_move || _action == Task_Action_moveToNPC) {
			return dict;
		}
		_per--;
	}
	return nil;
}

-(BOOL)checkRuningData{
	return (runingStepData != nil);
}


-(int)getStepIcon{
	if (runingStepData) {
		NSString* str = [runingStepData objectForKey:@"icon"] ;
		if (str) {
			return [str intValue];
		}
	}
	return 0;
}

-(NSString*)getPresentIcon{
	if (runingStepData) {
		NSString* str = [runingStepData objectForKey:@"icon"] ;
		return str;
	}
	return nil;
}

-(BOOL)doFindMonsterInStage{
	if (currentAction==Task_Action_stage){
		//副本的问题
		NSDictionary * data = [runingStepData objectForKey:@"data"];
		int sid = [[data objectForKey:@"sid"] intValue];
		if([StageManager currentStageId] == sid){
			CGPoint pt = [[StageManager shared] getTracePoint];
			if (pt.x != -1 && pt.y != -1) {
				[RoleManager shared].player.targetPoint = pt;
				[[RoleManager shared] movePlayerTo:[[MapManager shared] getTileToPosition:pt]];
				return YES;
			}
		}
	}
	return NO;
}

//_________________________________________________________________________
//
//_________________________________________________________________________
-(NSString*)actionString:(int)_action{
	NSString* str = [NSString stringWithFormat:@""];
	if (_action == Task_Action_none) {
		str = [str stringByAppendingFormat:@"Task_Action_none"];
	}else if(_action == Task_Action_talk) {
		str = [str stringByAppendingFormat:@"Task_Action_talk"];
	}else if(_action == Task_Action_move) {
		str = [str stringByAppendingFormat:@"Task_Action_move"];
	}else if(_action == Task_Action_moveToNPC) {
		str = [str stringByAppendingFormat:@"Task_Action_moveToNPC"];
	}else if(_action == Task_Action_addNpc) {
		str = [str stringByAppendingFormat:@"Task_Action_addNpc"];
	}else if(_action == Task_Action_moveNpc) {
		str = [str stringByAppendingFormat:@"Task_Action_moveNpc"];
	}else if(_action == Task_Action_removeNpc) {
		str = [str stringByAppendingFormat:@"Task_Action_removeNpc"];
	}else if(_action == Task_Action_unlock) {
		str = [str stringByAppendingFormat:@"Task_Action_unlock"];
	}else if(_action == Task_Action_stage) {
		str = [str stringByAppendingFormat:@"Task_Action_stage"];
	}else if(_action == Task_Action_fight) {
		str = [str stringByAppendingFormat:@"Task_Action_fight"];
	}else if(_action == Task_Action_effects) {
		str = [str stringByAppendingFormat:@"Task_Action_effects"];
	}else if(_action == Task_Action_fightAction) {
		str = [str stringByAppendingFormat:@"Task_Action_fightAction"];
	}else if(_action == Task_Action_openMap) {
		str = [str stringByAppendingFormat:@"Task_Action_openMap"];
	}else if(_action == Task_Action_waitStart) {
		str = [str stringByAppendingFormat:@"Task_Action_waitStart"];
	}else if(_action == Task_Action_openExternalMap) {
		str = [str stringByAppendingFormat:@"Task_Action_openExternalMap"];
	}
	return str;
}

-(void)checkStopMoveAlert{
	if (currentAction == Task_Action_move || currentAction == Task_Action_moveToNPC) {
		[MovingAlert remove];
	}
}

-(void)doTask{
	
	if (currentAction == Task_Action_end){
		CCLOG(@"doTask:currentAction == Task_Action_end");
		return ;
	}
	
	if (currentAction == Task_Action_waitStart){
		CCLOG(@"doTask:currentAction == Task_Action_waitStart");
		return ;
	}
	
	if (currentAction == Task_Action_none){
		CCLOG(@"doTask:currentAction == Task_Action_none");
		CCLOG(@"doTask:_logic-%d",_logic);
		return ;
	}
	
	if (currentAction == Task_Action_addNpc ||
		currentAction == Task_Action_removeNpc ||
		currentAction == Task_Action_effects ||
		currentAction == Task_Action_moveNpc ||
		currentAction == Task_Action_openMap ||
		currentAction == Task_Action_openExternalMap) {
		if (isDoingStep) return ;
	}
	
	if (currentAction == Task_Action_talk) {
		if ([TaskTalk isTalking]) return ;
	}
	
	if (currentAction == Task_Action_unlock) {
		if (isDoingStep) return ;
		if ([self checkUnlockAction]) return ;
	}

	if (currentAction==Task_Action_move ||
		currentAction==Task_Action_moveToNPC) {
		//todo check move
	}
	
	if (currentAction==Task_Action_stage){
		if ([self checkStage]) return ;
	}
	
	if (currentAction == Task_Action_fight ||
		currentAction == Task_Action_fightAction){
		if ([self checkFight]) return ;
	}
	
	[self runStep];
}

-(BOOL)checkUnlockAction{ 
	if ([UnlockAlert isUnlocking]) {
		if (currentAction == Task_Action_unlock) {
			NSDictionary * data = [runingStepData objectForKey:@"data"];
			int _unlockID = [[data objectForKey:@"unlockID"] intValue];
			if ([UnlockAlert shared].unlockId == _unlockID) {
				return YES ;
			}
		}
	}
	return NO;
}

-(BOOL)checkFight{
	if (currentAction == Task_Action_fight){
		NSDictionary * data = [runingStepData objectForKey:@"data"];
		int fid = [[data objectForKey:@"fid"] intValue];
		if ([FightManager currentFightId] == fid) return YES ;
	}
	if (currentAction == Task_Action_fightAction){
		NSDictionary * data = [runingStepData objectForKey:@"data"];
		int fid = [[data objectForKey:@"fid"] intValue];
		if ([FightManager currentFightId] == fid) return YES ;
	}
	return NO;
}

-(BOOL)checkStage{
	if ([self doFindMonsterInStage]) {
		return YES ;
	}
	return NO ;
}

-(void)stopTask{
	if(currentAction == Task_Action_move || currentAction == Task_Action_moveToNPC){
		[[RoleManager shared].player stopMoveAndTask];
	}
}

-(int)getNextTaskId{
	if (self.type == Task_Type_vice ||
		self.type == Task_Type_hide) {
		int next = [[self.taskInfo objectForKey:@"nextId"] intValue];
		return  next ;
	}
	return 0;
}

@end


