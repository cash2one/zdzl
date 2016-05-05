//
//  Task.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-15.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"


typedef enum{
	MANUAL,
	AUTOEXEC,
}Execute_type;

typedef enum{
	TaskStep_init = 1 ,
	TaskStep_run = 2 ,
	TaskStep_end = 3 ,
}TaskStep_logic;

@interface Task : NSObject{
	
	int userTaskId;
	int taskId;
	int step;
	int stepCount;
	int exp;
	
	int icon;
	
	BOOL isRun;
	BOOL isDoingStep;
	
	Execute_type execute;
	
	Task_Type type;
	Task_Status status;
	
	Task_Action currentAction;
	Task_Action parentAction;
	TaskStep_logic _logic;
	
	BOOL bWaitEnd;
	BOOL bWaitFinish;
	
	NSDictionary * taskInfo;
	NSDictionary * runingStepData;
	
	id			_pauseTarget;
	SEL			_pauseCall;
	BOOL		_isPause;
	
	//用于控制任务是不是马上开始
}
@property(nonatomic,assign)int exp;
@property(nonatomic,assign)int userTaskId;
@property(nonatomic,assign)int taskId;
@property(nonatomic,assign)int step;
@property(nonatomic,assign)int stepCount;
@property(nonatomic,assign)BOOL isRun;
@property(nonatomic,assign)Task_Type type;
@property(nonatomic,assign)Task_Status status;
@property(nonatomic,assign)Execute_type execute;
@property(nonatomic,assign)BOOL isDoingStep;
@property(nonatomic,assign)NSDictionary * taskInfo;
@property(nonatomic,assign)BOOL bWaitFinish;
@property(nonatomic,readonly)NSDictionary * runingStepData;

@property(nonatomic,assign)int	icon;

@property(nonatomic,assign)id	pauseTarget;
@property(nonatomic,assign)SEL	pauseCall;
@property(nonatomic,assign)BOOL	isPause;



@property(nonatomic,readonly) Task_Action currentAction;
@property(nonatomic,readonly) Task_Action parentAction;

+(Task*)TaskWithData:(NSDictionary*)data;

-(void)setData:(NSDictionary*)data;

-(BOOL)checkMoveToNpc:(CGPoint)_point;
-(void)start;
-(void)checkStatus;
-(void)startStep;
-(void)runStep;
-(void)endStep;
-(Task_Action)getNextAction;
-(BOOL)isUnlock;

-(void)doTask;

-(BOOL)checkRuningData;
-(NSString*)getPresentIcon;
-(BOOL)doFindMonsterInStage;

-(void)endDoStepTalk;
-(void)doStepStageEnd;
-(void)doStepFightShowEnd;

-(void)stopTask;

-(void)doEndStep;
-(void)doSetpFightResult;
-(void)doStepFightEnd;

-(int)getStageId;
-(void)doStepUnlock;
-(int)getNextTaskId;

-(int)getStepIcon;

@end






