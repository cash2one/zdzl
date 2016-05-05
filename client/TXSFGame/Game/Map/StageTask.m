//
//  StageTask.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-21.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "StageTask.h"
#import "Config.h"
#import "NPCManager.h"
#import "TaskTalk.h"
#import "GameEffects.h"

@implementation StageTask
@synthesize target;
@synthesize call;
@synthesize data;

static StageTask * stageTask;

+(void)stopAll{
	if(stageTask){
		[StageTask remove];
	}
}

+(void)show:(NSArray*)data target:(id)target call:(SEL)call{
	if (stageTask != nil) {
		CCLOG(@"StageTask->double create!");
		return ;
	}
	stageTask = [[StageTask alloc] init];
	stageTask.data = data;
	stageTask.target = target;
	stageTask.call = call;
	[stageTask startTask];
}

+(void)remove{
	if(stageTask) [stageTask release];
	stageTask = nil;
}
+(BOOL)isTalking{
	if(stageTask) return YES;
	return NO;
}

-(void)dealloc{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	if(data) [data release];
	
	CCLOG(@"StageTask dealloc");
	
	[super dealloc];
	
}

-(void)setData:(NSArray*)d{
	data = [NSArray arrayWithArray:d];
	[data retain];
}

-(void)startTask{
	step = 0;
	[self runTask];
}

-(void)runTask{
	
	NSDictionary * p = [data objectAtIndex:step];
	
	int action = [[p objectForKey:@"action"] intValue];
	
	if(action==Task_Action_addNpc){
		NSDictionary * d = [p objectForKey:@"data"];
		int npcId = [[d objectForKey:@"npcId"] intValue];
		CGPoint point = CGPointFromString([d objectForKey:@"point"]);
		int direction = [[d objectForKey:@"direction"] intValue];
		
		[[NPCManager shared] addNPCById:npcId tilePoint:point direction:direction];
		
		[self endStep];
		return;
	}
	
	if(action==Task_Action_talk){
		NSArray * d = [p objectForKey:@"data"];
		[TaskTalk show:d target:self call:@selector(endStep)];
		return;
	}
	
	if(action==Task_Action_effects){
		NSDictionary * d = [p objectForKey:@"data"];
		[[GameEffects share] showEffectsWithDict:d 
										  target:self
											call:@selector(endStep)];
		return;
	}
	
	if(action==Task_Action_removeNpc){
		NSDictionary * d = [p objectForKey:@"data"];
		int npcId = [[d objectForKey:@"npcId"] intValue];
		[[NPCManager shared] removeNPCById:npcId];
		[self endStep];
		return;
	}
	
	//TODO if other action jump one
	[self endStep];
	
}

-(void)endStep{
	[NSTimer scheduledTimerWithTimeInterval:0.1f target:self 
								   selector:@selector(doEndStep) 
								   userInfo:nil 
									repeats:NO];
}

-(void)doEndStep{
	step++;
	if(step>=[data count]){
		
		if(target!=nil && call!=nil){
			[target performSelector:call withObject:nil afterDelay:0.001f];
			/*
			[NSTimer scheduledTimerWithTimeInterval:0.001f 
											 target:target selector:call 
										   userInfo:nil repeats:NO];
			*/
		}
		
		[StageTask remove];
		return;
	}
	[self runTask];
}

@end
