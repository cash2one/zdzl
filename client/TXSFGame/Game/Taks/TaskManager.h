//
//  TaskManager.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-15.
//  Copyright (c) 2012 eGame. All rights reserved.
//


/*
 *Test
 */

#import <Foundation/Foundation.h>
#import "Config.h"

#define  TaskManager_ver 2

#define TaskManager_robot 1

typedef enum
{
	TaskException_error =  1 ,
	TaskException_no_npc = 2 ,
}TaskException;

@class Task;
@interface TaskManager : NSObject{
	
	NSMutableArray*			taskList;
	NSMutableArray*			lockList;//装载被锁住的任务
	NSMutableDictionary*	completeList;
	
	Task * readyTask;
	Task * runingTask;
	Task * currentCompleteTask;
	
	Task_Type runingTaskType;
	Task_Type completeTaskType;
	
	
	Task_Type		_currentType;
	int				_proxyTaskId;
	int				_proxyTaskStep;
	
}
@property(nonatomic,assign)NSMutableDictionary *completeList;
@property(nonatomic,assign)Task * runingTask;
@property(nonatomic,assign)NSMutableArray * taskList;

+(TaskManager*)shared;
+(void)stopAll;


+(BOOL)isNewTaskManagerRobot;
+(BOOL)isTaskManagerRobot;
+(void)taskManagerRobot:(BOOL)b;
+(void)updateNewTaskManagerRobot:(BOOL)b;

+(BOOL)isCanRunTask;
-(void)start;

-(void)startUserTask:(int)userTaskId;
-(void)checkStartUserTask;
-(void)completeTask:(Task*)_task;
-(void)reloadNewTaskList;
-(void)reloadNewTaskList:(BOOL)showTips;
-(BOOL)checkIsChapter:(Task*)_task;

-(void)stopTaskAndRemove:(int)tid;
-(void)stopAllOfferTask;
-(void)amendTheTaskIcon;

-(Task*)getUserTaskByTid:(int)tid;
-(Task*)getUserTaskById:(int)userTaskId;
-(NSArray*)getTaskListByType:(Task_Type)type;

//==============================================================================
-(void)checkTask:(int)userTaskId;
-(void)checkStepStatusByInit;
-(void)checkStepStatusByOver;
-(void)checkStepStatusByCloseWindow;
-(void)checkStepStatusByCloseTimeBox;
-(void)checkStepRuning;
-(void)executeTask;
//==============================================================================

-(BOOL)checkMoveToNpc:(CGPoint)_pt;
-(BOOL)checkStageMonsterInit;

-(void)resumeTask;
-(void)stopTask;

-(void)skipChapter;
-(void)pauseTask;


-(BOOL)checkCanSkipChapter;
-(BOOL)isCompleteTask:(int)tid;
-(void)addCompleteTask:(int)tid;


-(BOOL)checkReadyTask;
-(void)startUserReadyTask;

-(void)freeTaskStep;

-(void)throwTaskException:(NSString*)_msg exception:(int)_t;

//______________________________________________________________________________
//______________________________________________________________________________
//______________________________________________________________________________
// 回调 管理
//______________________________________________________________________________
//______________________________________________________________________________
//______________________________________________________________________________

-(void)proxy_TaskPlayerMove:(CGPoint)point Task:(Task*)_target;
-(void)proxy_TaskTurnToMap:(int)_mid Task:(Task*)_target;
-(void)proxy_TaskTalk:(Task*)_target;
-(void)proxy_TaskEffects:(Task*)_target;
-(void)proxy_TaskEnd:(Task*)_target;
-(void)proxy_TaskStartStep:(Task*)_target;
-(void)proxy_TaskStartCustomizeFight:(Task*)_target;
-(void)proxy_TaskStartFight:(Task*)_target;
-(void)proxy_TaskUnlock:(Task*)_target;
-(void)proxy_TaskUpdateMap:(Task *)_target;
-(void)proxy_TaskAddNPC:(Task*)_target;
-(void)proxy_TaskRemoveNPC:(Task*)_target;
-(void)proxy_TaskMoveNPC:(Task*)_target;

@end
