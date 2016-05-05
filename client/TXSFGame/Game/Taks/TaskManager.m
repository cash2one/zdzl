//
//  TaskManager.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-15.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "TaskManager.h"
#import "GameConfigure.h"
#import "GameUI.h"
#import "Task.h"
#import "GameConnection.h"
#import "GameEffects.h"
#import "Game.h"
#import "AlertManager.h"
#import "MapManager.h"
#import "Window.h"
#import "TaskTalk.h"
#import "RolePlayer.h"
#import "RoleManager.h"
#import "Window.h"
#import "UnlockAlert.h"
#import "NPCManager.h"

#define SkipToMap	1

/*
 * version:1.0.6
 * 任务改变主动去执行
 * 开始任务 - 结束任务
 *
 */

static BOOL s_NewTaskManagerRobot = NO;
static BOOL s_TaskManagerRobot = NO;
static BOOL s_SkipChapter = NO;

static int s_TaskExp = 0 ; //任务经验奖励
static int s_NextTaskId = 0 ; //下一个任务的ID

int sortTask(Task *t1, Task*t2, void*context){
	
	if (t1.taskId < t2.taskId) return NSOrderedAscending;
	if (t1.taskId > t2.taskId) return NSOrderedDescending;
	
	return NSOrderedSame;
}

@implementation TaskManager
@synthesize runingTask;
@synthesize taskList;
@synthesize completeList;

static TaskManager *taskManager;

+(TaskManager*)shared{
	if(!taskManager){
		taskManager = [[TaskManager alloc] init];
	}
	return taskManager;
}
+(void)stopAll{
	if(taskManager){
		[GameConnection removePostTarget:taskManager];
		[taskManager release];
		taskManager = nil;
	}
	//isRunTask = YES;
}

+(BOOL)isCanRunTask{
	//优先检测窗口
	if(![[Window shared] checkCanRunTask]){
		return NO;
	}
	//其次检测地图
	if(![[MapManager shared] checkCanRunTask]){
		return NO;
	}
	//TODO 战斗中做任务？？？？？
	
	return YES;
}

+(BOOL)isTaskManagerRobot{
#if TaskManager_robot == 1
	return s_TaskManagerRobot;
#else
	return NO;
#endif
}

+(BOOL)isNewTaskManagerRobot{
#if TaskManager_robot == 1
	return s_NewTaskManagerRobot;
#else
	return NO;
#endif
}

+(void)updateNewTaskManagerRobot:(BOOL)b{
#if TaskManager_robot == 1
	s_NewTaskManagerRobot = b;
#endif
}

+(void)taskManagerRobot:(BOOL)b{
#if TaskManager_robot == 1
	s_TaskManagerRobot = b;
	[TaskManager updateNewTaskManagerRobot:b];
#endif
}

-(void)dealloc{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	[GameConnection removePostTarget:self];
	if(taskList){
		[taskList release];
		taskList = nil;
	}
	
	if(lockList){
		[lockList release];
		lockList = nil;
	}
	
	[TaskTalk remove];
	
	if (completeList) {
		[completeList release];
		completeList = nil;
	}
	
	if(runingTask){
		runingTask = nil;
	}
	if(currentCompleteTask){
		currentCompleteTask = nil;
	}
	//[GameConnection freeRequest:self];
	[super dealloc];
	
	CCLOG(@"TaskManager dealloc");
}

-(id)init{
	if ((self=[super init]) != nil) {
		
		taskList = [NSMutableArray array];
		[taskList retain];
		
		lockList = [NSMutableArray array];
		[lockList retain];
		
		completeList = [NSMutableDictionary dictionary];
		[completeList retain];
		
		_currentType = Task_Type_main;
		
		s_SkipChapter = NO ;
		
	}
	return self;
}

-(void)start{
	
	[GameConnection addPost:ConnPost_getPlayerInfo target:self call:@selector(didGetPlayerInfo:)];
	[GameConnection addPost:ConnPost_taskPush target:self call:@selector(didGetPushTask:)];
	[GameConnection addPost:ConnPost_skipChapterReload target:self call:@selector(reboorManager)];
	
	[taskList removeAllObjects];
	[lockList removeAllObjects];
	[completeList removeAllObjects];
	
	
	NSArray * tList = [[GameConfigure shared] getUserTaskList];
	for(NSDictionary * info in tList){
		Task * task = [Task TaskWithData:info];
		[taskList addObject:task];
	}
	
	for (Task * task in taskList) {
		if (!task.isUnlock) {
			[lockList addObject:task];
		}
	}
	[lockList sortUsingFunction:sortTask context:nil];
	
	
	NSArray * cArray = [[GameConfigure shared] getCompleteUserTaskList];
	if (cArray && cArray.count > 0) {
		int count = cArray.count ;
		count = count*32;
		for (int i = 0; i < count; i++) {
			int offset = i/32;
			int index = i%32;
			unsigned int _value = [[cArray objectAtIndex:offset] intValue];
			if (isOpenFunction(_value, index)) {
				NSString *key = [NSString stringWithFormat:@"%d",i];
				[completeList setObject:[NSString stringWithFormat:@""] forKey:key];
			}
		}
	}
	
	//延时开始做任务
	[NSTimer scheduledTimerWithTimeInterval:0.888f
									 target:self
								   selector:@selector(checkStartUserTask)
								   userInfo:nil
									repeats:NO];
	
}

-(void)updateLockTask{
	if (lockList != nil) {
		[lockList removeAllObjects];
		for (Task * task in taskList) {
			if (!task.isUnlock) {
				[lockList addObject:task];
			}
		}
		//任务排序
		[lockList sortUsingFunction:sortTask context:nil];
	}
}

-(void)didGetPlayerInfo:(NSNotification*)notification{
	
}

-(void)didGetPushTask:(NSNotification*)notification{
	NSArray * tasks = notification.object;
#if TaskManager_ver == 1
	for (NSDictionary *dict in tasks) {
		Task *task = [Task TaskWithData:dict];
		if (task.type == Task_Type_vice) {
			//todo 增加获得支线任务的提示
			[[GameUI shared] addTaskFunction];
		}
	}
	//++++++++++++++++++++++++++++++++++++++++
	if([tasks count]>0){
		if (![self checkShowReviceTask:tasks]) {
			[self endGetPushTask];
		}
	}
#else
	if ([tasks count] > 0) {
		[self endGetPushTask];
	}
#endif
	
}

-(int)updateUserUserTask:(NSArray*)_tasks{
	if (runingTask) return 0 ;
	if (_tasks == nil) return 0 ;
	
	return 0;
}

-(BOOL)checkShowReviceTask:(NSArray*)_tasks{
#if TaskManager_ver == 1
	if (runingTask) return NO ;
	for (NSDictionary *dict in _tasks) {
		Task *task = [Task TaskWithData:dict];
		if (task.type == Task_Type_main) {//支线也显示
			//TODO 章节任务不显示接任务
			if (![self checkIsChapter:task]) {
				[NSTimer scheduledTimerWithTimeInterval:0.5 target:self
											   selector:@selector(showStartAlert:)
											   userInfo:task
												repeats:NO];
				return YES;
			}
		}
	}
#endif
	return NO;
}
-(void)showStartAlert:(NSTimer *)timer{
#if TaskManager_ver == 1
	Task *_task = timer.userInfo;
	[[AlertManager shared] showTaskAlert:_task target:self call:@selector(endGetPushTask)];
#endif
}

-(void)endGetPushTask{
	[self reloadNewTaskList];
	[self checkStartUserTask];
}

-(BOOL)checkIsChapter:(Task*)_task{
	if (_task) {
		NSDictionary * chapter = [[GameConfigure shared] getChooseChapter];
		int startTid = [[chapter objectForKey:@"startTid"] intValue];
		if (_task.taskId == startTid) {
			return YES;
		}
	}
	return NO;
}
-(void)checkShowChapter{
	
	BOOL isShow = NO;
	
	NSDictionary * chapter = [[GameConfigure shared] getChooseChapter];
	int startTid = [[chapter objectForKey:@"startTid"] intValue];
	
	for(Task * task in taskList){
		if(startTid==task.taskId){
			if(task.step==0 && task.status==Task_Status_runing){
				isShow = YES;
			}
		}
	}
	
	if(isShow){
		[[GameEffects share] showEffects:EffectsAction_chapter target:nil call:nil];
	}
	
}

-(void)completeTask:(Task *)_task{
	
	if (_task == nil) return ;
	
	if (runingTask != nil && runingTask == _task) {
		[self completeTask];
	}
	
}

-(void)completeTask{
	if (runingTask.type == Task_Type_offer) {
		[self didCompleteTask];
	}else{
		if (runingTask.type == Task_Type_main && [self checkIsChapter:runingTask]) {
			[self openChapterMap];
		}else{
			if ([[GameConfigure shared] checkStopChapterTask:runingTask.taskId]) {
				[GameConnection request:@"chapterComplete" format:nil target:self call:@selector(didChapterComplete:)];
			}else{
#if TaskManager_ver == 1
				if ([[GameConfigure shared] isPlayerOnChapter]) {
					[self didCompleteTask];
				}else{
					[[AlertManager shared] showTaskAlert:runingTask target:self call:@selector(didCompleteTask)];
				}
#else
				[self didCompleteTask];
#endif
			}
		}
	}
	
}

-(void)openChapterMap{
	NSDictionary * chapter = [[GameConfigure shared] getChooseChapter];
	int cid = [[chapter objectForKey:@"id"] intValue];
	
	if (cid > 1) {
		int mid = [[chapter objectForKey:@"mid"] intValue];
		
		NSString* _info = [[GameConfigure shared] getUserWorldMapForString:cid map:mid];
		
		NSMutableDictionary* _dict  = [NSMutableDictionary dictionary];
		[_dict setObject:_info forKey:@"data"];
		
		[GameConnection request:@"worldMap"
						   data:_dict
						 target:self
						   call:@selector(endOpenChapterMap::)
							arg:_dict];
		
	}else{
		[self didCompleteTask];
	}
}

-(void)endOpenChapterMap:(NSDictionary*)_sender :(NSDictionary*)_data{
	if (checkResponseStatus(_sender)) {
		NSString* _info = [_data objectForKey:@"data"];
		[[GameConfigure shared] setUserWorldMap:_info];
		[self didCompleteTask];
	}
}

-(void)didChapterCompleteForSkip:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		//暂时更新章节
		[[GameConfigure shared] forSkipChapterReload];
	}
	else{
		CCLOG(@"didChapterComplete->nil");
	}
}

-(void)didChapterComplete:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		[[GameConfigure shared] reloadPlayerAllData];
		[self didCompleteTask];
	}
	else{
		CCLOG(@"didChapterComplete->nil");
	}
}
-(void)didCompleteTask{
	CCLOG(@"didCompleteTask begin:%d",runingTask.taskId);
	Task* completeTask_ = runingTask ;
	runingTask = nil ;
	if(completeTask_){
		if(completeTask_.status==Task_Status_complete){
			
			s_TaskExp = completeTask_.exp;
			s_NextTaskId = [completeTask_ getNextTaskId];
			
			completeTaskType = completeTask_.type ;
			
			if (![self checkIsChapter:completeTask_]) {
				[[RoleManager shared].player showTaskStatus:NO];
			}
			
			[[GameConfigure shared] completeUserTask:completeTask_.userTaskId target:self call:@selector(didGetRewarded:)];
			
			if (completeTask_.type != Task_Type_offer) {
				[self addCompleteTask:completeTask_.taskId];
			}
			
		}
		CCLOG(@"didCompleteTask end:%d",completeTask_.taskId);
		[taskList removeObject:completeTask_];
		completeTask_ = nil;
		[[GameUI shared] updateTaskStatus:0 taskStep:0 type:0];
	}
	[[GameUI shared] updateTaskInfo];
}

-(BOOL)checkHaskNextTask{
	
	if (runingTask != nil) {
		//这里补充其他类型
		if (runingTask.type == Task_Type_vice || runingTask.type == Task_Type_hide) {
			return [[runingTask.taskInfo objectForKey:@"nextId"] intValue] != 0 ;
		}
	}
	
	return YES;
}

-(BOOL)checkTaskByTaskFinish{
	BOOL _ok = NO ;
	if (completeTaskType == Task_Type_offer && lockList) {
		int utid = 0 ;
		NSArray* completes = [completeList allKeys];
		for (Task * task in lockList) {
			if (task.type == Task_Type_main && task.isUnlock) {
				NSString* temp = [NSString stringWithFormat:@"%d",task.taskId];
				if (![completes containsObject:temp]) {
					utid = task.userTaskId;
					break ;
				}
			}
		}
		if (utid > 0) {
			Task *_task = [self getUserTaskById:utid];
			if (_task != nil) {
				[lockList removeObject:_task];
			}
			//开始任务
			[self restartUserTask:utid];
			_ok = YES ;
		}
	}
	return _ok;
}

-(void)restartUserTask:(int)userTaskId{
	
	if(runingTask){
		if(runingTask.userTaskId==userTaskId){
			return;
		}
	}
	
	[[GameConfigure shared] startUserTask:userTaskId];
	runingTask = nil;
	
	Task * task = [self getUserTaskById:userTaskId];
	if(task){
		if (task.type == Task_Type_main) {
#if TaskManager_ver == 1
			runingTask = task;
			runingTaskType = runingTask.type;
			_currentType = runingTask.type;
			[[AlertManager shared] showTaskAlert:task target:self call:@selector(endShowTaskAlert)];
#else
			[self setReadyTask:task];
#endif
		}
	}
}


//
-(void)didGetRewarded:(NSDictionary*)response{
	
	if (checkResponseStatus(response)) {
		NSDictionary *dict = getResponseData(response);
		
		/*
		NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict type:PackageItem_all_excluding_exp];//[[GameConfigure shared] getPackageAddData:dict];
		NSMutableArray* array__ = [NSMutableArray arrayWithArray:updateData];
		
		if (s_TaskExp > 0) {
			NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
			//[tempDict setObject:[NSString stringWithFormat:@"经验"] forKey:@"name"];
            [tempDict setObject:[NSString stringWithFormat:NSLocalizedString(@"task_manager_exp",nil)] forKey:@"name"];
			[tempDict setObject:[NSNumber numberWithInt:s_TaskExp] forKey:@"count"];
			[array__ addObject:tempDict];
		}
		*/
		NSArray* array = [dict objectForKey:@"rwitems"];
		if (array) {
			NSArray* _addArray = [[GameConfigure shared] getPackageAddDataWithServer:array];
			[[AlertManager shared] showReceiveItemWithArray:_addArray];
		}
		[[GameConfigure shared] updatePackage:dict];
		
		
		//--------------------------------------
		//开始检测那些被锁的主线任务是不是已经解锁
		//--------------------------------------
		
		if (completeTaskType == Task_Type_hide ||
			completeTaskType == Task_Type_vice) {
			if (s_NextTaskId <= 0) {
				_currentType = Task_Type_main;
				
				[self checkStartUserTask];
				
			}
		}
		
		if (completeTaskType == Task_Type_offer) {
			if (![self checkTaskByTaskFinish]) {
				[[Window shared] showWindow:PANEL_TASK];
			}
		}
		
		completeTaskType = 0 ;
		
	}else {
		CCLOG(@"didGetRewarded is error!");
	}
}

//添加新任务
-(void)reloadNewTaskList{
	
#if TaskManager_ver == 1
	[self reloadNewTaskList:YES];
#else
	NSArray * array = [[GameConfigure shared] getUserTaskList];
	int _icon = 0;
	for(NSDictionary * info in array){
		int status = [[info objectForKey:@"status"] intValue];
		if(status!=Task_Status_complete){
			int userTaskId = [[info objectForKey:@"id"] intValue];
			Task * task = [self getUserTaskById:userTaskId];
			if(task==nil){
				task = [Task TaskWithData:info];
				[taskList addObject:task];
				_icon = task.icon;
			}
		}
	}
	
	[[GameUI shared] updateTaskStatus:_icon taskStep:0 type:0];
	[self updateLockTask];
	//通知新任务到来
#endif
	
}

-(void)reloadNewTaskList:(BOOL)showTips
{
	//BOOL isHasNewTask = NO;
	
	NSArray * tList = [[GameConfigure shared] getUserTaskList];
	
	int iconValue = 0 ;
	for(NSDictionary * info in tList){
		int status = [[info objectForKey:@"status"] intValue];
		if(status!=Task_Status_complete){
			int userTaskId = [[info objectForKey:@"id"] intValue];
			Task * task = [self getUserTaskById:userTaskId];
			if(task==nil){
				task = [Task TaskWithData:info];
				[taskList addObject:task];
				iconValue = task.icon;
				//isHasNewTask = YES;
			}
		}
	}
	
	[[GameUI shared] updateTaskStatus:iconValue taskStep:0 type:0];
	//_________________________________________
	//更新被锁定的任务队列
	[self updateLockTask];
	//_________________________________________
	//if(isHasNewTask && showTips) [[GameUI shared] showNewTaskTips];
}

-(void)stopTaskAndRemove:(int)tid
{
	[[GameConfigure shared] removeUserTasksById:tid];
	Task *_temp = [self getUserTaskByTid:tid];
	if (_temp) {
		[taskList removeObject:_temp];
	}
	if (runingTask && runingTask.taskId == tid) {
		runingTask=nil;
	}
}

-(void)amendTheTaskIcon{
	if (runingTask) {
		[[GameUI shared] updateTaskStatus:runingTask.icon taskStep:0 type:runingTask.type];
	}
}

-(void)stopAllOfferTask
{
	NSMutableArray *needToDeletes = [NSMutableArray array];
	for (Task *task in taskList) {
		if (task.type == Task_Type_offer) {
			[[GameConfigure shared] removeUserTasksById:task.taskId];
			if (runingTask && runingTask.taskId == task.taskId) {
				runingTask = nil;
			}
			[needToDeletes addObject:task];
		}
	}
	for (Task *task in needToDeletes) {
		[taskList removeObject:task];
	}
	[needToDeletes removeAllObjects];
	needToDeletes = nil;
}

//找出用户当前正在执行的任务
-(void)checkStartUserTask{
	if(runingTask) return;
	
	if (_currentType == Task_Type_offer) {
		if ([[GameConfigure shared] checkPlayerFunction:Unlock_offer]) {
			[[GameUI shared] updateTaskStatus:1006 taskStep:0 type:0];
			return ;
		}
	}else{
		//
		//继续做之前的那条线 做不了 再往下走
		//
		for (Task * task in taskList) {
			if (task.type == _currentType) {
				if ([self isCompleteTask:task.taskId]) {
					continue ;
				}
				if (task.isUnlock) {
					[self startUserTask:task.userTaskId];
					return;
				}
			}
		}
		
		for (Task * task in taskList) {
			if (task.type == Task_Type_main) {
				if (task.isUnlock) {
					if ([self isCompleteTask:task.taskId]) {
						continue ;
					}
					[self startUserTask:task.userTaskId];
					return;
				}
			}
		}
		
		if ([[GameConfigure shared] checkPlayerFunction:Unlock_vice]) {
			for (Task * task in taskList) {
				if (task.type == Task_Type_vice) {
					if (task.isUnlock) {
						[self startUserTask:task.userTaskId];
						return;
					}
				}
			}
		}
		
		if ([[GameConfigure shared] checkPlayerFunction:Unlock_hide]) {
			for (Task * task in taskList) {
				if (task.type == Task_Type_hide) {
					if (task.isUnlock) {
						[self startUserTask:task.userTaskId];
						return;
					}
				}
			}
		}
		
		if ([[GameConfigure shared] checkPlayerFunction:Unlock_offer]) {
			[[GameUI shared] updateTaskStatus:1006 taskStep:0 type:0];
			return ;
		}
	}
}

-(void)startUserTaskFormUi:(int)userTaskId{
	if(runingTask){
		if(runingTask.userTaskId==userTaskId){
			return;
		}
	}
	
	[[GameConfigure shared] startUserTask:userTaskId];
	
	runingTask = nil;
	
	Task * task = [self getUserTaskById:userTaskId];
	
	if (task) {
		if (task.status == Task_Status_complete) {
			return ;
		}
		if (readyTask != nil) {
			CCLOG(@"startUserTaskFormUi->");
			readyTask = nil ;
		}
		[self didStartUserTask:task];
	}
}

-(void)startUserTask:(int)userTaskId{
	
	if(runingTask){
		if(runingTask.userTaskId==userTaskId){
			return;
		}
	}
	
	//
	[[GameConfigure shared] startUserTask:userTaskId];
	
	runingTask = nil;
	
	Task * task = [self getUserTaskById:userTaskId];
	if(task){
		
		if (task.status == Task_Status_complete) {
			CCLOG(@"startUserTask->status->Task_Status_complete");
			return ;
		}
#if TaskManager_ver == 1
		//_____________________________________
		//非主线的时候，在任务开始的时候才现实接任务
		//主线任务是由接受到服务器推送任务的时候触发的
		//_____________________________________
		if (task.type != Task_Type_main) {
			runingTask = task;
			runingTaskType = runingTask.type;
			[NSTimer scheduledTimerWithTimeInterval:0.5
											 target:self
										   selector:@selector(showTaskAlert:)
										   userInfo:task
											repeats:NO];
			
		}else{
			[self didStartUserTask:task];
		}
#else
		[self setReadyTask:task];
#endif
		
	}
}


-(void)showTaskAlert:(NSTimer *)timer{
#if TaskManager_ver == 1
	Task *_task = timer.userInfo;
	[[AlertManager shared] showTaskAlert:_task target:self call:@selector(endShowTaskAlert)];
#endif
	
}

-(void)removeLockTask:(int)_tid{
	if (lockList != nil  && _tid > 0) {
		Task *_task = [self getUserTaskById:_tid];
		
		if (_task != nil &&
			_task.type == Task_Type_main &&
			_task.isUnlock) {
			[lockList removeObject:_task];
		}
		CCLOG(@"removeLockTask->lock count->%d",[lockList count]);
	}
}

-(void)endShowTaskAlert{
	if (runingTask != nil) {
		[[GameUI shared] updateTaskInfo];
		runingTaskType = runingTask.type;
		_currentType = runingTask.type;
		
		[self removeLockTask:runingTask.taskId];
		
		[runingTask start];
	}
}

-(void)didStartUserTask:(Task*)_task{
	if(_task){
		runingTask = nil;
		runingTask = _task;
		runingTaskType = runingTask.type;
		_currentType = runingTask.type;
		
		[self removeLockTask:runingTask.taskId];
		
		[runingTask start];
	}
}

-(Task *)getUserTaskByTid:(int)tid
{
	[self reloadNewTaskList];
	
	for(Task * task in taskList){
		if(task.taskId==tid){
			return task;
		}
	}
	return nil;
}

-(Task*)getUserTaskById:(int)userTaskId{
	for(Task * task in taskList){
		if(task.userTaskId==userTaskId){
			return task;
		}
	}
	return nil;
}

-(NSArray*)getTaskListByType:(Task_Type)type{
	NSMutableArray * result = [NSMutableArray array];
	NSArray* completes = [completeList allKeys];
	for(Task * task in taskList){
		if(task.type==type){
			if (type == Task_Type_main) {
				NSString* temp = [NSString stringWithFormat:@"%d",task.taskId];
				if (![completes containsObject:temp]) {
					[result addObject:task];
				}
			}else{
				[result addObject:task];
			}
		}
	}
	return result;
}

//==============================================================================

-(void)checkTask:(int)userTaskId{
	CCLOG(@"checkTask:%d",userTaskId);
	if (runingTask != nil &&
		runingTask.userTaskId == userTaskId) {
		CCLOG(@"checkTask:checkStepRuning(%d)",userTaskId);
		[NSTimer scheduledTimerWithTimeInterval:0.08 target:self
									   selector:@selector(checkStepRuning)
									   userInfo:nil
										repeats:NO];
	}else{
		CCLOG(@"checkTask:startUserTask(%d)",userTaskId);
		[self startUserTaskFormUi:userTaskId];
		/*
		[NSTimer scheduledTimerWithTimeInterval:0.18 target:self
									   selector:@selector(checkStepRuning)
									   userInfo:nil
										repeats:NO];
		 */
	}
	
}

//TODO map change to update task status for map objects...
-(void)checkStepStatusByInit{
	if(runingTask){
		
		if(runingTask.currentAction==Task_Action_stage ||
		   NO){
			[runingTask checkStatus];
		}
		
	}
	
}
-(void)checkStepStatusByOver{
	if(runingTask){
		
		if(runingTask.currentAction==Task_Action_talk ||
		   runingTask.currentAction==Task_Action_move ||
		   runingTask.currentAction==Task_Action_moveToNPC ||
		   
		   runingTask.currentAction==Task_Action_addNpc ||
		   runingTask.currentAction==Task_Action_moveNpc ||
		   runingTask.currentAction==Task_Action_removeNpc ||
		   
		   runingTask.currentAction==Task_Action_effects ||
		   runingTask.currentAction==Task_Action_unlock ||
		   
		   runingTask.currentAction==Task_Action_fight ||
		   
		   runingTask.currentAction==Task_Action_fightAction ||
		   
		   runingTask.currentAction==Task_Action_openMap ||
		   
		   NO){
			
			[runingTask checkStatus];
			
		}
	}
}

-(void)checkStepStatusByCloseWindow{
	if(runingTask != nil){
		if(runingTask.currentAction==Task_Action_unlock){
			[runingTask endStep];
		}
	}
}

-(void)checkStepStatusByCloseTimeBox{
	if(runingTask != nil){
		if(runingTask.currentAction==Task_Action_unlock){
			NSDictionary * data = [runingTask.runingStepData objectForKey:@"data"];
			int _unlockID = [[data objectForKey:@"unlockID"] intValue];
			if (_unlockID == Unlock_timebox) {
				[runingTask endStep];
			}
		}
	}
}

-(void)checkStepRuning{
	if(runingTask){
		[runingTask runStep];
	}else{
		//TODO show Task List UI and let user choose TaskList
		CCLOG(@"TODO show Task List UI and let user choose TaskList");
	}
}
/*
 * 外部执行任务
 */
-(void)executeTask{
	if (runingTask) {
		//[[GameUI shared] updateTaskStatus:runingTask.icon taskStep:runingTask.step type:runingTask.type];
		[runingTask doTask];
	}
}
/*
 *监测目标位置是不是当前任务的执行步骤的目标位置
 */
-(BOOL)checkMoveToNpc:(CGPoint)_pt{
	if (runingTask) {
		return [runingTask checkMoveToNpc:_pt];
	}
	return NO;
}
//_________________________________________________
//
//_________________________________________________
-(BOOL)checkStageMonsterInit{
	if (runingTask != nil && runingTask.currentAction == Task_Action_stage) {
		return YES;
	}
	return NO;
}

-(void)resumeTask{
	
}

-(void)stopTask{
	if(runingTask){
		[runingTask stopTask];
	}
}

-(void)skipChapter{
	
	if (s_SkipChapter) {
		return ;
	}
	
	s_SkipChapter = YES ;
	
	if (runingTask != nil) {
		//第一个任务不能跳过
		//最后一个不能跳过
		CCLOG(@"skipChapter->runingTask != nil");
		if (runingTask.taskId < 2 && runingTask.taskId > 6) {
			return ;
		}
		
	}else{
		CCLOG(@"skipChapter->runingTask == nil");
		if ([self isCompleteTask:6]) {
			return ;
		}
		if (![self isCompleteTask:1]) {
			return ;
		}
	}

	
	[self pauseTask];
	
	[[RoleManager shared].player stopMoveAndTask];
	
//	[[AlertManager shared] showMessage:@"序章是游戏世界观的概述，请问是否确认跳过？"
//								target:self
//							   confirm:@selector(doSkipChapter)
//								 canel:@selector(canelSkipChapter)];
    [[AlertManager shared] showMessage:NSLocalizedString(@"task_manager_jump",nil)
								target:self
							   confirm:@selector(doSkipChapter)
								 canel:@selector(canelSkipChapter)];
}

-(BOOL)checkCanSkipChapter{
	
	BOOL _result = [[GameConfigure shared] isPlayerOnChapter];
	
	_result = _result && ([MapManager shared].mapId != 10);
	
	return _result ;
	
}

-(void)pauseTask{
	runingTask = nil ;
	readyTask = nil ;
	_proxyTaskId = -1 ;
	_proxyTaskStep = -1 ;
	[[GameUI shared] updateTaskStatus:0 taskStep:0 type:0];
}

-(void)refreshSkipEvent{
	s_SkipChapter = NO ;
}

-(void)canelSkipChapter{
	[NSTimer scheduledTimerWithTimeInterval:1.68f
									 target:self
								   selector:@selector(refreshSkipEvent)
								   userInfo:nil
									repeats:NO];
	[self checkStartUserTask];
}

-(void)doSkipChapter{
	[self pauseTask];
	[taskList removeAllObjects];
	
	[[GameConfigure shared] removeUserMapNPCWith:[MapManager shared].mapId];
	[[GameConfigure shared] removeUserTaskList];
	[[GameConfigure shared] updatePlayerChapter];
	
	[[Game shared] trunToMap:SkipToMap target:self call:@selector(freeTaskAndChapterComplete)];
}

-(void)showChapterStartEffect{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:10] forKey:@"eid"];
	[[GameEffects share] showEffectsWithDict:dict target:nil call:nil];
}

-(void)freeTaskAndChapterComplete{
	
	[NSTimer scheduledTimerWithTimeInterval:1.88f
									 target:self
								   selector:@selector(showChapterStartEffect)
								   userInfo:nil
									repeats:NO];
	
	NSDictionary* db = [[GameDB shared] getChapterInfo:2];
	int _mid = [[db objectForKey:@"mid"] intValue];
	
	
	NSString* _info = [[GameConfigure shared] getUserWorldMapForString:2 map:_mid];
	NSMutableDictionary* _dict  = [NSMutableDictionary dictionary];
	[_dict setObject:_info forKey:@"data"];
	[GameConnection request:@"worldMap"
					   data:_dict
					 target:nil
					   call:nil
						arg:_dict];
	
	[self pauseTask];
	
	[GameConnection request:@"chapterComplete"
					 format:nil
					 target:self
					   call:@selector(didChapterCompleteForSkip:)];
	
}

-(BOOL)isCompleteTask:(int)tid{
	if(tid==0) return YES;
	NSString * key = [NSString stringWithFormat:@"%d",tid];
	if([completeList objectForKey:key]){
		return YES;
	}
	return NO;
}

-(void)addCompleteTask:(int)tid{
	if (tid > 0) {
		NSString *key = [NSString stringWithFormat:@"%d",tid];
		[completeList setObject:[NSString stringWithFormat:@""] forKey:key];
	}
}

//
//______________________________________________________________________________
//______________________________________________________________________________
//______________________________________________________________________________

-(void)stopManager{
	
}

-(void)reboorManager{
	
	[taskList removeAllObjects];
	[lockList removeAllObjects];
	[completeList removeAllObjects];
	
	readyTask = nil ;
	currentCompleteTask = nil;
	runingTask = nil ;
	
	runingTaskType = Task_Type_none;
	completeTaskType = Task_Type_none;
	_currentType = Task_Type_none;
	
	NSArray * userTasks = [[GameConfigure shared] getUserTaskList];
	for(NSDictionary * info in userTasks){
		Task * task = [Task TaskWithData:info];
		[taskList addObject:task];
	}
	
	for (Task * task in taskList) {
		if (!task.isUnlock) {
			[lockList addObject:task];
		}
	}
	[lockList sortUsingFunction:sortTask context:nil];
	
	
	NSArray * cArray = [[GameConfigure shared] getCompleteUserTaskList];
	if (cArray && cArray.count > 0) {
		int count = cArray.count ;
		count = count*32;
		for (int i = 0; i < count; i++) {
			int offset = i/32;
			int index = i%32;
			unsigned int _value = [[cArray objectAtIndex:offset] intValue];
			if (isOpenFunction(_value, index)) {
				NSString *key = [NSString stringWithFormat:@"%d",i];
				[completeList setObject:[NSString stringWithFormat:@""] forKey:key];
			}
		}
	}
	
	//延时开始做任务
	[NSTimer scheduledTimerWithTimeInterval:0.668f
									 target:self
								   selector:@selector(checkStartUserTask)
								   userInfo:nil
									repeats:NO];
	
}

-(void)setReadyTask:(Task*)task{
	if (task == nil) return ;
	
	if (task.type == Task_Type_main && [self checkIsChapter:task]) {
		readyTask = nil ;
		readyTask = task;
		if ([Game shared].bStartGame) {
			[Game shared].bStartGame = NO;
		}
		[NSTimer scheduledTimerWithTimeInterval:0.348
										 target:self
									   selector:@selector(startUserReadyTask)
									   userInfo:nil
										repeats:NO];
	}else{
		readyTask = nil ;
		readyTask = task;
		if (readyTask.step == 0) {
			if ([Game shared].bStartGame) {
				[Game shared].bStartGame = NO;
			}
			[[GameUI shared] updateTaskStatus:readyTask.icon taskStep:0 type:readyTask.type];
		}else{
			[NSTimer scheduledTimerWithTimeInterval:0.348
											 target:self
										   selector:@selector(startUserReadyTask)
										   userInfo:nil
											repeats:NO];
		}
	}
}

-(BOOL)checkReadyTask{
	if (readyTask) {
		return YES;
	}
	return NO;
}

-(void)startUserReadyTask{
	if (readyTask) {
		[self didStartUserTask:readyTask];
		readyTask = nil;
	}
}

-(void)throwTaskException:(NSString *)_msg exception:(int)_t
{
	
}

//______________________________________________________________________________
//______________________________________________________________________________
//______________________________________________________________________________

-(void)freeTaskStep{
	_proxyTaskId = -1 ;
	_proxyTaskStep = -1 ;
}

-(void)proxy_TaskPlayerMove:(CGPoint)point Task:(Task *)_target{
	if (_target != nil) {
		
		_proxyTaskId = _target.taskId ;
		_proxyTaskStep = _target.step ;
		
		if ([TaskManager isTaskManagerRobot]) {
			[self proxy_endTaskPlayerMove];
			return ;
		}
		
		[[RoleManager shared] movePlayerTo:point
									target:self
									  call:@selector(proxy_endTaskPlayerMove)
		 ];
		
	}
}
-(void)proxy_endTaskPlayerMove{
	if (runingTask != nil) {
		
		if (_proxyTaskId == runingTask.taskId && _proxyTaskStep == runingTask.step) {
			
			_proxyTaskId	= -1 ;
			_proxyTaskStep	= -1 ;
			
			if (runingTask.currentAction == Task_Action_talk) {
				[runingTask endDoStepTalk];
			}else if (runingTask.currentAction == Task_Action_move || runingTask.currentAction == Task_Action_moveToNPC){
				[runingTask endStep];
			}else if (runingTask.currentAction == Task_Action_stage){
				[runingTask doStepStageEnd];
			}else if (runingTask.currentAction == Task_Action_fightAction){
				[runingTask doStepFightShowEnd];
			}else if (runingTask.currentAction == Task_Action_fight){
				[runingTask doStepFightEnd];
			}
			else{
				[runingTask endStep];
			}
			
		}
	}
}
-(void)proxy_TaskTurnToMap:(int)_mid Task:(Task *)_target{
	if (_target != nil) {
		
		_proxyTaskId = _target.taskId ;
		_proxyTaskStep = _target.step ;
		
		[[Game shared] trunToMap:_mid target:self call:@selector(proxy_endTaskTurnToMap)];
		
	}
}
-(void)proxy_endTaskTurnToMap{
	if (runingTask != nil) {
		
		if (_proxyTaskId == runingTask.taskId && _proxyTaskStep == runingTask.step) {
			
			_proxyTaskId	= -1 ;
			_proxyTaskStep	= -1 ;
			
			[NSTimer scheduledTimerWithTimeInterval:0.2f
											 target:runingTask
										   selector:@selector(runStep)
										   userInfo:nil repeats:NO];
			
			//[runingTask runStep];
			
		}
	}
}
-(void)proxy_TaskTalk:(Task *)_target{
	if (_target != nil) {
		
		if (_target.currentAction != Task_Action_talk) return ;
		
		if (![TaskTalk isTalking]) {
			
			if (_proxyTaskId == _target.taskId && _proxyTaskStep == _target.step) {
				return ;
			}
			
			_proxyTaskId = _target.taskId ;
			_proxyTaskStep = _target.step ;
			
			//test
			if ([TaskManager isTaskManagerRobot]) {
				[self proxy_endTaskTalk];
				return ;
			}
			
			NSArray * data = [_target.runingStepData objectForKey:@"data"];
			[TaskTalk show:data target:self call:@selector(proxy_endTaskTalk)];
			
		}
	}
}
-(void)proxy_endTaskTalk{
	if (runingTask != nil) {
		if (runingTask.currentAction != Task_Action_talk) return ;
		
		
		CCLOG(@"proxy_endTaskTalk");
		
		if (_proxyTaskId == runingTask.taskId && _proxyTaskStep == runingTask.step) {
			
			_proxyTaskId	= -1 ;
			_proxyTaskStep	= -1 ;
			
			[runingTask endStep];
			
			
		}
		
	}
	
	CCLOG(@"proxy_endTaskTalk-nil");
}
-(void)proxy_TaskEffects:(Task *)_target{
	if (_target != nil) {
		
		if (_target.currentAction != Task_Action_effects) return ;
		
		if (_proxyTaskId == _target.taskId && _proxyTaskStep == _target.step) {
			return ;
		}
		
		_proxyTaskId = _target.taskId ;
		_proxyTaskStep = _target.step ;
		
		
		//test
		if ([TaskManager isTaskManagerRobot]) {
			[self proxy_endTaskEffects];
			return ;
		}
		
		NSDictionary * data = [_target.runingStepData objectForKey:@"data"];
		
		if (![GameEffects isShowEffect:_target.taskId taskStep:_target.step]) {
			
			[[GameEffects share] showEffectsWithDict:data
											  target:self
												call:@selector(proxy_endTaskEffects)
											  taskId:_target.taskId
											taskStep:_target.step];
		}
		
	}
}
-(void)proxy_endTaskEffects{
	if (runingTask != nil) {
		
		if (runingTask.currentAction != Task_Action_effects) return ;
		
		if (_proxyTaskId == runingTask.taskId && _proxyTaskStep == runingTask.step) {
			_proxyTaskId	= -1 ;
			_proxyTaskStep	= -1 ;
			
			[runingTask endStep];
			
			CCLOG(@"proxy_endTaskEffects");
		}
		
	}
	
	CCLOG(@"proxy_endTaskEffects-nil");
}
-(void)proxy_TaskEnd:(Task *)_target{
	if (_target != nil) {
		NSNumber* number1 = [NSNumber numberWithInt:_target.taskId];
		NSNumber* number2 = [NSNumber numberWithInt:_target.step];
		
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		[dict setObject:number1 forKey:@"tid"];
		[dict setObject:number2 forKey:@"step"];
		
		
		CCLOG(@"proxy_TaskEnd:->>>>>>>>>>>>>>>>>>>>>>>>");
		
		[NSTimer scheduledTimerWithTimeInterval:0.338f
										 target:self
									   selector:@selector(proxy_endTaskEnd:)
									   userInfo:dict repeats:NO];
		
	}
}
-(void)proxy_endTaskEnd:(NSTimer*)_obj{
	if (runingTask != nil) {
		
		CCLOG(@"proxy_endTaskEnd");
		
		NSDictionary* dict = (NSDictionary*)[_obj userInfo];
		
		int  tid = [[dict objectForKey:@"tid"] intValue];
		int  step = [[dict objectForKey:@"step"] intValue];
		
		if (runingTask.taskId == tid && runingTask.step == step) {
			[runingTask doEndStep];
		}
		
	}
	
	CCLOG(@"proxy_endTaskEnd - nil");
}
-(void)proxy_TaskStartStep:(Task *)_target{
	if (_target != nil) {
		
		NSNumber* number1 = [NSNumber numberWithInt:_target.taskId];
		NSNumber* number2 = [NSNumber numberWithInt:_target.step];
		
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		
		[dict setObject:number1 forKey:@"tid"];
		[dict setObject:number2 forKey:@"step"];
		
		[NSTimer scheduledTimerWithTimeInterval:0.3f
										 target:self
									   selector:@selector(proxy_endTaskStartStep:)
									   userInfo:dict repeats:NO];
		
	}
}
-(void)proxy_endTaskStartStep:(NSTimer*)_obj{
	if (runingTask != nil) {
		
		CCLOG(@"proxy_endTaskStartStep");
		
		NSDictionary* dict = (NSDictionary*)[_obj userInfo];
		
		int  tid = [[dict objectForKey:@"tid"] intValue];
		int  step = [[dict objectForKey:@"step"] intValue];
		
		if (runingTask.taskId == tid && runingTask.step == step ) {
			if (runingTask.currentAction == Task_Action_waitStart) {
				[runingTask startStep];
			}
		}
		
	}
	
	CCLOG(@"proxy_endTaskStartStep-nil");
}
-(void)proxy_TaskStartCustomizeFight:(Task *)_target{
	if (_target != nil) {
		
		NSDictionary * data = [_target.runingStepData objectForKey:@"data"];
		int fid = [[data objectForKey:@"fid"] intValue];
		
		if (_proxyTaskId == _target.taskId && _proxyTaskStep == _target.step) {
			return ;
		}
		
		_proxyTaskId	= _target.taskId ;
		_proxyTaskStep	= _target.step ;
		
		//test
		if ([TaskManager isTaskManagerRobot]) {
			[self proxy_endTaskStartCustomizeFight];
			return ;
		}
		
		
		if ([FightManager currentFightId] != fid) {
			[[FightManager shared] startCustomizeFight:data target:self call:@selector(proxy_endTaskStartCustomizeFight)];
		}
		
	}
}
-(void)proxy_endTaskStartCustomizeFight{
	if (runingTask != nil) {
		CCLOG(@"proxy_endTaskStartCustomizeFight");
		if (runingTask.taskId == _proxyTaskId && runingTask.step == _proxyTaskStep ) {
			[runingTask doSetpFightResult];
		}
		_proxyTaskId	= -1 ;
		_proxyTaskStep	= -1 ;
	}
	CCLOG(@"proxy_endTaskStartCustomizeFight-nil");
}
-(void)proxy_TaskStartFight:(Task *)_target{
	if (_target != nil) {
		
		if (_proxyTaskId == _target.taskId && _proxyTaskStep == _target.step) {
			return ;
		}
		
		_proxyTaskId	= _target.taskId ;
		_proxyTaskStep	= _target.step ;
		
		
		//test
		if ([TaskManager isTaskManagerRobot]) {
			[self proxy_endTaskStartFight];
			return ;
		}
		
		
		NSDictionary * data = [_target.runingStepData objectForKey:@"data"];
		int fid = [[data objectForKey:@"fid"] intValue];
		
		if ([FightManager currentFightId] != fid) {
			[[FightManager shared] startFightById:fid target:self call:@selector(proxy_endTaskStartFight)];
		}
	}
}
-(void)proxy_endTaskStartFight{
	if (runingTask != nil) {
		CCLOG(@"proxy_endTaskStartFight");
		if (runingTask.taskId == _proxyTaskId && runingTask.step == _proxyTaskStep ) {
			[runingTask doSetpFightResult];
		}
		
		_proxyTaskId	= -1 ;
		_proxyTaskStep	= -1 ;
	}
	CCLOG(@"proxy_endTaskStartFight-nil");
}
-(void)proxy_TaskUnlock:(Task *)_target{
	if (_target == nil) return ;
	
	if(_target.currentAction==Task_Action_unlock){
		
		NSDictionary * data = [_target.runingStepData objectForKey:@"data"];
		
		
		_proxyTaskId	= _target.taskId ;
		_proxyTaskStep	= _target.step ;
		
		int _unlockID = [[data objectForKey:@"unlockID"] intValue];
		
		
		
		if ([TaskManager isTaskManagerRobot]) {
			
			NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
			unsigned int _value = [[player objectForKey:@"funcs"] intValue];
			_value = updateFunction(_value, _unlockID);
			[[GameConfigure shared] updatePlayerFuncs:_value];
			
			[self proxy_endTaskUnlock];
			
			return ;
		}
		
		[[Intro share] runIntroUnLockTask:_unlockID];
		
		if (checkTutorial(_unlockID)) {
			//有教程的情况
			[GameEffectsBlockTouck lockScreen:self call:@selector(proxy_endTaskUnlock)];
			[UnlockAlert show:data target:nil call:nil];
		}else{
			//没教程的情况
			[UnlockAlert show:data target:self call:@selector(proxy_endTaskUnlock)];
		}
		
		return;
	}
}
-(void)proxy_endTaskUnlock{
	
	if (runingTask != nil) {
		CCLOG(@"proxy_endTaskUnlock");
		
		if (runingTask.taskId == _proxyTaskId && runingTask.step == _proxyTaskStep ) {
			if (runingTask.currentAction == Task_Action_unlock) {
				
				if ([TaskManager isTaskManagerRobot]) {
					[runingTask endStep];
					_proxyTaskId	= -1 ;
					_proxyTaskStep	= -1 ;
					return;
				}
				
				[runingTask doStepUnlock];
			}
			
		}
		
		_proxyTaskId	= -1 ;
		_proxyTaskStep	= -1 ;
	}
	
	CCLOG(@"proxy_endTaskUnlock-nil");
}
-(void)proxy_TaskUpdateMap:(Task *)_target{
	
	if (_target == nil) return ;
	
	if (_target.taskId == _proxyTaskId && _target.step == _proxyTaskStep ) {
		return ;
	}
	
	_proxyTaskId	= _target.taskId ;
	_proxyTaskStep	= _target.step ;
	
	NSDictionary * data = [_target.runingStepData objectForKey:@"data"];
	
	int cid = [[data objectForKey:@"cid"] intValue];
	int mid = [[data objectForKey:@"mid"] intValue];
	
	NSString* _info = [[GameConfigure shared] getUserWorldMapForString:cid map:mid];
	
	NSMutableDictionary* _dict  = [NSMutableDictionary dictionary];
	[_dict setObject:_info forKey:@"data"];
	
	[GameConnection request:@"worldMap"
					   data:_dict
					 target:self
					   call:@selector(proxy_endTaskUpdateMap::)
						arg:_dict];
	
}
-(void)proxy_endTaskUpdateMap:(NSDictionary*)_sender :(NSDictionary*)_dict{
	
	if (checkResponseStatus(_sender)) {
		
		if (runingTask != nil) {
			if (runingTask.taskId == _proxyTaskId && runingTask.step == _proxyTaskStep ) {
				
				NSString* _info = [_dict objectForKey:@"data"];
				[[GameConfigure shared] setUserWorldMap:_info];
				
				[runingTask endStep];
				
			}
			_proxyTaskId	= -1 ;
			_proxyTaskStep	= -1 ;
		}
	}else{
		_proxyTaskId	= -1 ;
		_proxyTaskStep	= -1 ;
	}
	
}

-(void)proxy_TaskAddNPC:(Task *)_target{
	if (_target == nil) return ;
	
	if (_target.taskId == _proxyTaskId && _target.step == _proxyTaskStep ) {
		return ;
	}
	
	_proxyTaskId	= _target.taskId ;
	_proxyTaskStep	= _target.step ;
	
	NSDictionary * data = [_target.runingStepData objectForKey:@"data"];
	int mapId = [[data objectForKey:@"mapId"] intValue];
	
	int npcId = [[data objectForKey:@"npcId"] intValue];
	CGPoint point = CGPointFromString([data objectForKey:@"point"]);
	int direction = [[data objectForKey:@"direction"] intValue];
	
	[[GameConfigure shared] addUserMapNPC:npcId
									  map:mapId
									point:point
								direction:direction
								   target:self call:@selector(proxy_endTaskAddNPC:)];
}

-(void)proxy_endTaskAddNPC:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		if (runingTask != nil) {
			if (runingTask.taskId == _proxyTaskId && runingTask.step == _proxyTaskStep ) {
				
				NSDictionary * data = [runingTask.runingStepData objectForKey:@"data"];
				int mapId = [[data objectForKey:@"mapId"] intValue];
				
				int npcId = [[data objectForKey:@"npcId"] intValue];
				CGPoint point = CGPointFromString([data objectForKey:@"point"]);
				int direction = [[data objectForKey:@"direction"] intValue];
				
				if(mapId==[MapManager shared].mapId){
					[[NPCManager shared] addNPCById:npcId tilePoint:point direction:direction];
				}
				
				[runingTask endStep];
			}
			_proxyTaskId	= -1 ;
			_proxyTaskStep	= -1 ;
		}
	}else{
		_proxyTaskId	= -1 ;
		_proxyTaskStep	= -1 ;
	}
}

-(void)proxy_TaskRemoveNPC:(Task *)_target{
	if (_target == nil) return ;
	
	if (_target.taskId == _proxyTaskId && _target.step == _proxyTaskStep ) {
		return ;
	}
	
	_proxyTaskId	= _target.taskId ;
	_proxyTaskStep	= _target.step ;
	
	NSDictionary * data = [_target.runingStepData objectForKey:@"data"];
	int mapId = [[data objectForKey:@"mapId"] intValue];
	int npcId = [[data objectForKey:@"npcId"] intValue];
	
	
	[[GameConfigure shared] removeUserMapNPC:npcId map:mapId target:self call:@selector(proxy_endRemoveNPC:)];
	
}
-(void)proxy_endRemoveNPC:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		if (runingTask != nil) {
			if (runingTask.taskId == _proxyTaskId && runingTask.step == _proxyTaskStep ) {
				NSDictionary * data = [runingTask.runingStepData objectForKey:@"data"];
				int mapId = [[data objectForKey:@"mapId"] intValue];
				int npcId = [[data objectForKey:@"npcId"] intValue];
				
				if(mapId==[MapManager shared].mapId){
					[[NPCManager shared] removeNPCById:npcId];
				}
				
				[runingTask endStep];
			}
			_proxyTaskId	= -1 ;
			_proxyTaskStep	= -1 ;
		}
	}else{
		_proxyTaskId	= -1 ;
		_proxyTaskStep	= -1 ;
	}
}

-(void)proxy_TaskMoveNPC:(Task *)_target{
	if (_target == nil) return ;
	
	if (_target.taskId == _proxyTaskId && _target.step == _proxyTaskStep ) {
		return ;
	}
	
	_proxyTaskId	= _target.taskId ;
	_proxyTaskStep	= _target.step ;
	
	NSDictionary * data = [_target.runingStepData objectForKey:@"data"];
	int mapId = [[data objectForKey:@"mapId"] intValue];
	int npcId = [[data objectForKey:@"npcId"] intValue];
	
	[[GameConfigure shared] removeUserMapNPC:npcId map:mapId
									  target:self
										call:@selector(proxy_endMoveNPCStepRemove:)];
	
}
-(void)proxy_endMoveNPCStepRemove:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		if (runingTask != nil) {
			
			if (runingTask.currentAction != Task_Action_moveNpc) {
				_proxyTaskId	= -1 ;
				_proxyTaskStep	= -1 ;
				return ;
			}
			
			if (runingTask.taskId == _proxyTaskId && runingTask.step == _proxyTaskStep ){
				
				NSDictionary * data = [runingTask.runingStepData objectForKey:@"data"];
				int mapId = [[data objectForKey:@"mapId"] intValue];
				int npcId = [[data objectForKey:@"npcId"] intValue];
				CGPoint point = CGPointFromString([data objectForKey:@"point"]);
				int direction = [[data objectForKey:@"direction"] intValue];
				
				if(mapId==[MapManager shared].mapId){
					[[NPCManager shared] removeNPCById:npcId];
				}
				
				
				[[GameConfigure shared] addUserMapNPC:npcId
												  map:mapId
												point:point
											direction:direction
											   target:self call:@selector(proxy_endMoveNPCStepAdd:)];
			}
		}
	}else{
		_proxyTaskId	= -1 ;
		_proxyTaskStep	= -1 ;
	}
}
-(void)proxy_endMoveNPCStepAdd:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		if (runingTask != nil) {
			
			if (runingTask.currentAction != Task_Action_moveNpc) {
				_proxyTaskId	= -1 ;
				_proxyTaskStep	= -1 ;
				return ;
			}
			
			if (runingTask.taskId == _proxyTaskId && runingTask.step == _proxyTaskStep ){
				
				NSDictionary * data = [runingTask.runingStepData objectForKey:@"data"];
				int mapId = [[data objectForKey:@"mapId"] intValue];
				int npcId = [[data objectForKey:@"npcId"] intValue];
				CGPoint point = CGPointFromString([data objectForKey:@"point"]);
				int direction = [[data objectForKey:@"direction"] intValue];
				
				if(mapId==[MapManager shared].mapId){
					[[NPCManager shared] addNPCById:npcId tilePoint:point direction:direction];
				}
				
				[runingTask endStep];
			}
			
			_proxyTaskId	= -1 ;
			_proxyTaskStep	= -1 ;
		}
		
	}else{
		_proxyTaskId	= -1 ;
		_proxyTaskStep	= -1 ;
	}
}

@end



