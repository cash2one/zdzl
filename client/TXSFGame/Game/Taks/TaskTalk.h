//
//  TaskTalk.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-15.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class Task;

@interface TaskTalk : CCLayer{
	NSArray * messages;
	int mid;
	//Task * task;
	
	id target;
	SEL call;
	BOOL bTouchDelay;
	BOOL isEndTalk;
	BOOL isGameUiShow;
	
	int taskId;
	int taskStep;
	
	//BOOL	_isWait;
}
@property(nonatomic,assign)int taskId;
@property(nonatomic,assign)int taskStep;

@property(nonatomic,retain) NSArray * messages;
//@property(nonatomic,assign) Task * task;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL call;

//+(void)show:(NSArray*)msgs task:(Task*)task;
+(void)show:(NSArray*)msgs target:(id)target call:(SEL)call;
+(void)remove;
+(BOOL)isTalking;
+(BOOL)isShowTalking:(int)_tid taskStep:(int)_step;

@end
