//
//  TaskPattern.h
//  TXSFGame
//
//  Created by huang shoujun on 13-1-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "TaskManager.h"


typedef enum{
	TaskPattern_doTask = 1 ,//做任务
	TaskPattern_doOffer = 2 ,//打开悬赏UI
}TaskPattern_func;

typedef enum{
	TaskPatternStatus_none = 0,
	TaskPatternStatus_begin = 1 ,//做任务
	TaskPatternStatus_running = 2 ,//打开悬赏UI
}TaskPatternStatus;

#if TaskManager_ver == 1
@interface TaskPattern : CCSprite<CCTouchOneByOneDelegate> {
    CCSprite* background;
	CCLabelTTF *label;
	CCLabelTTF *labelStep;
	BOOL isLock;
	TaskPattern_func m_func;
	int taskId;
	int taskStep;
}

+(TaskPattern*)shared;
+(void)close;
+(BOOL)isHasTaskPattern;
+(CGPoint)getPosition;

-(void)showOfferTaskIcon;
-(void)checkTaskStep;
-(void)show;

-(void)checkStatus;

-(void)changeUI;

@end
#else

@interface TaskPattern : CCSprite<CCTouchOneByOneDelegate> {
	CCLabelTTF *label;
	CCLabelTTF *labelStep;
	BOOL isLock;
	TaskPattern_func m_func;
	int taskId;
	int taskStep;
	int taskType;
	TaskPatternStatus status;
	BOOL isEffect;
	NSTimer * checkTimer;
	int timeCount;
	
	BOOL isTutorialing;
	int taskIcon;
	int stepIcon;
}
@property(nonatomic,assign)BOOL isTutorialing;
@property(nonatomic,assign)BOOL isEffect;
@property(nonatomic,assign)int taskIcon;
@property(nonatomic,assign)int stepIcon;
@property(nonatomic,assign)int taskId;
@property(nonatomic,assign)int taskStep;
@property(nonatomic,assign)int taskType;
@property(nonatomic,assign)TaskPatternStatus status;

+(TaskPattern*)shared;
+(void)close;
+(BOOL)isHasTaskPattern;
+(CGPoint)getPosition;

+(void)display;
+(void)redisplay;

-(void)show;
-(void)checkStatus;

-(void)updateStatus:(int)_taskId taskStep:(int)_step type:(int)_type;

-(void)changeUI;
-(void)endPointOut;

@end

#endif


