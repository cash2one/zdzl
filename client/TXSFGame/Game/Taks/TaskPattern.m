//
//  TaskPattern.m
//  TXSFGame
//
//  Created by huang shoujun on 13-1-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "TaskPattern.h"
#import "AnimationViewer.h"
#import "Task.h"
#import "TaskManager.h"
#import "GameUI.h"
#import "MapManager.h"
#import "intro.h"
#import "Window.h"
#import "Config.h"
#import "TaskTalk.h"
#import "FightManager.h"
#import "WorldMap.h"
#import "AlertManager.h"
#import "RolePlayer.h"
#import "RoleManager.h"

#import "TaskIconViewerContent.h"
#import "GameSoundManager.h"

#define TASKPATTERN_DEBUG__________ YES
#define TASK_TIME_COUNT	5

#define Background_tag	400
#define TaskType_tag	401
#define TaskIcon_tag	402
#define Effect_tag		403
#define PointOut_tag	404

#define OfferIcon	1006

static TaskPattern* s_TaskPattern = nil;

#if TaskManager_ver == 1

@implementation TaskPattern

+(CGPoint)getPosition{
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	CGPoint point = ccp(winSize.width-cFixedScale(60),winSize.height-cFixedScale(140));
	if(![GameUI shared].isShowOtherUI){
		point = ccpAdd(point,ccp(cFixedScale(150),0));
	}
	return point;
}

+(TaskPattern*)shared{
	if (!s_TaskPattern) {
		s_TaskPattern = [TaskPattern node];
		[s_TaskPattern show];
		[s_TaskPattern retain];
	}
	
	return s_TaskPattern;
}

+(void)close{
	if (s_TaskPattern) {
		[s_TaskPattern removeFromParentAndCleanup:YES];
		[s_TaskPattern release];
		s_TaskPattern=nil;
	}
}

+(BOOL)isHasTaskPattern{
	if(s_TaskPattern){
		return YES;
	}
	return NO;
}

-(void)show{
	if (!s_TaskPattern.parent) {
		[[GameUI shared] addChild:s_TaskPattern z:INT16_MAX];
		s_TaskPattern.position=[TaskPattern getPosition];
	}
}

-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	isLock = NO ;
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-57 swallowsTouches:YES];
}

-(void)checkStatus{
	if ([TaskManager shared].runingTask == nil) {
		[[TaskManager shared] checkStartUserTask];
	}else{
		[self checkTaskStep];
	}
}

-(void)showOfferTaskIcon{
	if ([MapManager shared].mapType == Map_Type_Stage ||
		[MapManager shared].mapType == Map_Type_Standard) {
		
		[self endEffect];
		[self showBackground];
		
		[self removeChildByTag:103 cleanup:YES];
		[self removeChildByTag:109 cleanup:YES];
		
		[self removeChildByTag:110 cleanup:YES];
		[self removeChildByTag:111 cleanup:YES];
		
		CCSprite * iconSpr = [TaskIconViewerContent create:@"1006"];
		iconSpr.anchorPoint=ccp(0.5, 0);
		iconSpr.position=ccp(self.contentSize.width/2, 0);
		[self addChild:iconSpr z:4 tag:103];
		
		[self showEffect];
		
		if (background) {
			background.visible=YES;
		}
		m_func = TaskPattern_doOffer;
		
	}else{
		[TaskPattern close];
	}
}

-(void)showBackground{
	if (background == nil) {
		background = [CCSprite spriteWithFile:@"images/ui/characterIcon/big.png"];
		self.contentSize=background.contentSize;
		background.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
		[self addChild:background z:1 tag:-3389];
	}
}

-(void)checkTaskStep{
	
	if ([TaskManager shared].runingTask == nil) {
		return ;
	}
	
	if (taskId == [TaskManager shared].runingTask.taskId &&
		taskStep == [TaskManager shared].runingTask.step) {
		return ;
	}
	
	if ([TaskManager shared].runingTask == nil ||  ![[TaskManager shared].runingTask checkRuningData]) {
		return ;
	}
	
	if ([MapManager shared].mapType == Map_Type_Stage ||
		[MapManager shared].mapType == Map_Type_Standard ||
		[MapManager shared].mapType == Map_Type_Fish) {
		
		taskId = [TaskManager shared].runingTask.taskId;
		taskStep = [TaskManager shared].runingTask.step;
		
		[self showBackground];
		[self endEffect];
		
		[self removeChildByTag:103 cleanup:YES];
		NSString *icon = [[TaskManager shared].runingTask getPresentIcon];
		
		CCSprite * iconSpr = [TaskIconViewerContent create:icon];
		iconSpr.anchorPoint=ccp(0.5, 0);
		iconSpr.position=ccp(self.contentSize.width/2, 0);
		[self addChild:iconSpr z:4 tag:103];
		
		[self removeChildByTag:109 cleanup:YES];
		Task_Type type = [TaskManager shared].runingTask.type;
		NSString *type_icon_path = [NSString stringWithFormat:@"images/ui/alert/task_%d.png", type];
		CCSprite *type_icon = [CCSprite spriteWithFile:type_icon_path];
		//右上角任务头像上的主线任务图标还是悬赏任务图标
		if (type_icon) {
			if (iPhoneRuningOnGame()) {
				type_icon.position = ccp(100/2.0f, 25/2.0f);
			}else{
				type_icon.position = ccp(100, 25);
			}
			[self addChild:type_icon z:10 tag:109];
		}
		
		[[Intro share]runIntroTager:self step:1];
		[self showEffect];
		m_func = TaskPattern_doTask;
		
	}else{
		[TaskPattern close];
	}
	
	isLock = NO ;
}

-(void)showEffect{
	CCNode* _object = [self getChildByTag:-334];
	if (_object) {
		return ;
	}
	AnimationViewer *ani = [AnimationViewer node];
	[self addChild:ani z:2 tag:-334];
	ani.anchorPoint=ccp(0.5, 0.5);
	ani.position=ccp(self.contentSize.width/2,self.contentSize.height/2);
	NSString * path = [NSString stringWithFormat:@"images/animations/task/"];
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	[ani playAnimation:frames];
}

-(void)endEffect{
	CCNode* _object = [self getChildByTag:-334];
	if (_object) {
		[_object stopAllActions];
		[_object removeFromParentAndCleanup:YES];
		_object=nil;
	}
}

-(BOOL)isTouchInSite:(UITouch*)touch{
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	CGSize size = self.contentSize;
	if(p.x<-size.width*self.anchorPoint.x)		return NO;
	if(p.x>size.width*(1-self.anchorPoint.x))	return NO;
	if(p.y<-size.height*self.anchorPoint.y)		return NO;
	if(p.y>size.height*(1-self.anchorPoint.y))	return NO;
	
	if([[Window shared] isHasWindow]){
		return NO;
	}
	
	return YES;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	
	[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_MMission];
	if(self.visible && [self isTouchInSite:touch] && background && background.visible){
		CCLOG(@"TaskPattern ccTouchBegan");
		self.scale = 1.1;
		
		[[GameSoundManager shared] click];
		
		return YES;
	}
	self.scale = 1.0;
	return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	if([self isTouchInSite:touch]){
	}else{
		self.scale = 1.0;
	}
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	self.scale = 1.0;
	if (isLock) {
		return;
	}
	
	isLock = YES ;
	[self scheduleOnce:@selector(unLock) delay:0.5f];
	
	if(self.visible && [self isTouchInSite:touch] && background && background.visible){
		[self endEffect];
		[[Intro share]removeCurrenTipsAndNextStep:1];
		if (m_func == TaskPattern_doTask) {
			if ([TaskManager shared].runingTask != nil) {
				[[TaskManager shared] executeTask];
			}
		}else if (m_func == TaskPattern_doOffer){
			[[Window shared] showWindow:PANEL_TASK];
		}
	}
	
}

-(void)unLock{
	isLock = NO ;
}

/*
 -(BOOL)checkNewIcon{
 if ([TaskManager shared].runingTask != nil) {
 NSString *icon = [[TaskManager shared].runingTask getPresentIcon];
 if (icon && icon.length > 0){
 icon = [NSString stringWithFormat:@"images/ui/task_icon/task_icon_%@.png",icon];
 return checkHasFile(icon);
 }
 }
 return NO;
 }
 */


-(void)changeUI{
	[s_TaskPattern stopAllActions];
	id move = [CCMoveTo actionWithDuration:0.25f position:[TaskPattern getPosition]];
	[s_TaskPattern runAction:move];
}
@end

#else

@implementation TaskPattern

@synthesize isEffect;
@synthesize taskId;
@synthesize taskStep;
@synthesize taskType;
@synthesize status;

@synthesize taskIcon;
@synthesize stepIcon;

@synthesize isTutorialing;

+(CGPoint)getPosition{
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	CGPoint point = ccp(winSize.width-cFixedScale(60),winSize.height-cFixedScale(140));
	if(![GameUI shared].isShowOtherUI){
		point = ccpAdd(point,ccp(cFixedScale(150*3),0));
	}
	return point;
}

+(TaskPattern*)shared{
	if (!s_TaskPattern) {
		s_TaskPattern = [TaskPattern node];
		[s_TaskPattern retain];
	}
	return s_TaskPattern;
}

+(void)display{
//	if (s_TaskPattern) {
//
//	}
	if ([TaskPattern isHasTaskPattern]) {
		[s_TaskPattern removeFromParentAndCleanup:YES];
		s_TaskPattern.parent = nil;
	}
}

+(void)redisplay{
	[[TaskPattern shared] show];
}

+(void)close{
	if (s_TaskPattern) {
		[s_TaskPattern removeFromParentAndCleanup:YES];
		[s_TaskPattern release];
		s_TaskPattern=nil;
	}
}

+(BOOL)isHasTaskPattern{
	if(s_TaskPattern && s_TaskPattern.parent != nil){
		return YES;
	}
	return NO;
}

-(void)show{
	if (!s_TaskPattern.parent) {
		CCLOG(@"TaskPattern->show->1");
		[[GameUI shared] addChild:s_TaskPattern z:INT16_MAX];
		s_TaskPattern.position=[TaskPattern getPosition];
	}
}

-(id)init{
	if ((self = [super init]) == nil) {
		return nil;
	}
	self.contentSize = CGSizeMake(cFixedScale(121), cFixedScale(121));
	
	checkTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
												  target:self
												selector:@selector(checkTimeCount)
												userInfo:nil
												 repeats:YES];
	
	return self;
}

-(void)dealloc{
	if(checkTimer){
		[checkTimer invalidate];
		checkTimer = nil;
	}
	[super dealloc];
}

-(BOOL)checkChapter{
	NSDictionary * chapter = [[GameConfigure shared] getChooseChapter];
	if(chapter){
		int cid = [[chapter objectForKey:@"id"] intValue];
		return (cid == 2 || cid == 1);
	}
	return NO;
}

-(BOOL)checkCanUpdateTime{
	
	BOOL isCan = YES;
	
	if ([self checkPointOut])							isCan = NO;
	if (self.parent == nil)								isCan = NO;
	if (![self checkChapter])							isCan = NO;
	if([TaskTalk isTalking])							isCan = NO;
	if([FightManager isFighting])						isCan = NO;
	if([AlertManager hasAlert])							isCan = NO;
	if([WorldMap isShow])								isCan = NO;
	if([[Window shared] isHasWindow])					isCan = NO;
	if([Intro isIntroOpen])								isCan = NO;
	
	if ([MapManager shared].mapType == Map_Type_TimeBox		||
		[MapManager shared].mapType == Map_Type_Mining		||
		[MapManager shared].mapType == Map_Type_Abyss		||
		[MapManager shared].mapType == Map_Type_Union		||
		[MapManager shared].mapType == Map_Type_WorldBoss	||
		[MapManager shared].mapType == Map_Type_UnionBoss	||
		[MapManager shared].mapType == Map_Type_SysPvp		||
		[MapManager shared].mapType == Map_Type_dragonReady	||
		[MapManager shared].mapType == Map_Type_dragonFight	||
		NO) {
		isCan = NO;
	}
	
	
	RolePlayer * player = [RoleManager shared].player;
	
	if(player==nil){
		isCan = NO;
	}else{
		if([player isRunning]) isCan = NO;
		if(player.state!=Player_state_normal) isCan = NO;
	}
	
	return isCan;
}

-(void)checkTimeCount{
	
	if (![self checkCanUpdateTime]) {
		timeCount = 0 ;
		return ;
	}
	
	if (timeCount > TASK_TIME_COUNT) {
		self.isTutorialing = YES ;
		[self startPointOut];
	}else{
		timeCount++;
	}
}

-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	isLock = NO ;
	self.scale = 1.0f;
	
	[self showInfo];
	
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-2 swallowsTouches:YES];
}

-(void)checkStatus{
	
	CCLOG(@"TaskPattern->checkStatus");
	
	if ([MapManager shared].mapType == Map_Type_TimeBox		||
		[MapManager shared].mapType == Map_Type_Mining		||
		[MapManager shared].mapType == Map_Type_Abyss		||
		[MapManager shared].mapType == Map_Type_Union		||
		[MapManager shared].mapType == Map_Type_WorldBoss	||
		[MapManager shared].mapType == Map_Type_UnionBoss	||
		[MapManager shared].mapType == Map_Type_SysPvp		||
		[MapManager shared].mapType == Map_Type_dragonReady	||
		[MapManager shared].mapType == Map_Type_dragonFight	||
		NO) {
		CCLOG(@"TaskPattern->checkStatus->1");

		[TaskPattern display];
	}
	
	if ([MapManager shared].mapType == Map_Type_Fish		||
		[MapManager shared].mapType == Map_Type_Standard	||
		[MapManager shared].mapType == Map_Type_Stage		||
		NO) {
		CCLOG(@"TaskPattern->checkStatus->2");
		[TaskPattern redisplay];
	}
}

-(void)endPointOut{
	self.isTutorialing = NO;
	[self removeChildByTag:PointOut_tag cleanup:YES];
}

-(BOOL)checkPointOut{
	CCNode* __node = [self getChildByTag:PointOut_tag];
	if (__node) {
		return YES;
	}
	return NO;
}

-(void)startPointOut{
	[self removeChildByTag:PointOut_tag cleanup:YES];
	
	if (self.taskIcon > 0 || self.stepIcon) {
		CCSprite* spr = [CCSprite spriteWithFile:@"images/ui/panel/task.png"];
		[self addChild:spr z:5 tag:PointOut_tag];
		
		spr.anchorPoint = ccp(1.0, 0.5);
		spr.position = ccp(0, self.contentSize.height/2);
		
		id _lp = nil;
		
		if(iPhoneRuningOnGame()){
			_lp = [CCMoveBy actionWithDuration:0.5 position:ccp(5, 0)];
		}else{
			_lp = [CCMoveBy actionWithDuration:0.5 position:ccp(10, 0)];
		}
		
		id _rp = [_lp reverse];
		id sequence = [CCSequence actions:_lp,_rp,nil];
		id forever = [CCRepeatForever actionWithAction:sequence];
		[spr runAction:forever];
	}
	
}

-(void)showEffect{
	
	AnimationViewer *ani = [AnimationViewer node];
	[self addChild:ani z:2 tag:Effect_tag];
	ani.anchorPoint=ccp(0.5, 0.5);
	ani.position=ccp(self.contentSize.width/2,self.contentSize.height/2);
	NSString * path = [NSString stringWithFormat:@"images/animations/task/"];
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	[ani playAnimation:frames];
	
}

-(void)endEffect{
	CCNode* _object = [self getChildByTag:Effect_tag];
	if (_object) {
		[_object stopAllActions];
		[_object removeFromParentAndCleanup:YES];
		_object=nil;
	}
}


-(BOOL)isTouchInSite:(UITouch*)touch{
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	CGSize size = self.contentSize;
	if(p.x<-size.width*self.anchorPoint.x)		return NO;
	if(p.x>size.width*(1-self.anchorPoint.x))	return NO;
	if(p.y<-size.height*self.anchorPoint.y)		return NO;
	if(p.y>size.height*(1-self.anchorPoint.y))	return NO;
	
	if([[Window shared] isHasWindow]){
		return NO;
	}
	
	return YES;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	
	[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_MMission];
	if(self.visible && [self isTouchInSite:touch] && self.parent != nil){
		CCLOG(@"TaskPattern ccTouchBegan");
		self.scale = 1.1;
		
		[[GameSoundManager shared] click];
		
		return YES;
	}
	self.scale = 1.0;
	return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	if([self isTouchInSite:touch]){
	}else{
		self.scale = 1.0;
	}
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	self.scale = 1.0;
	if (isLock) {
		return;
	}
	
	isLock = YES ;
	[self scheduleOnce:@selector(unLock) delay:0.5f];
	
	if(self.visible && [self isTouchInSite:touch] && self.parent != nil){
		[self endPointOut];
		
		if (m_func == TaskPattern_doTask) {
			
			
			[self endEffect];
			
			/* 只有 任务开始的时候才生效 */
			
#if TaskManager_robot == 1
			if ([TaskManager isTaskManagerRobot]) {
				if ([[TaskManager shared] checkReadyTask]) {
					[TaskManager updateNewTaskManagerRobot:NO];
					[[RoleManager shared].player showTaskStatus:YES];
					[[TaskManager shared] startUserReadyTask];
					return;
				}
				
				if ([TaskManager isNewTaskManagerRobot]) {
					[TaskManager updateNewTaskManagerRobot:NO];
					[[TaskManager shared] executeTask];
				}
				return ;
			}
#endif
			
			
			if ([[TaskManager shared] checkReadyTask]) {
				[[RoleManager shared].player showTaskStatus:YES];
				[[TaskManager shared] startUserReadyTask];
				return;
			}
			
			[[TaskManager shared] executeTask];
			
		}else if (m_func == TaskPattern_doOffer){
			[self endEffect];
			
			[[Window shared] showWindow:PANEL_TASK];
		}
		
		[[Intro share]removeCurrenTipsAndNextStep:1];
	}
	
}

-(void)unLock{
	isLock = NO ;
}

-(void)changeUI{
	[s_TaskPattern stopAllActions];
	id move = [CCMoveTo actionWithDuration:0.25f position:[TaskPattern getPosition]];
	[s_TaskPattern runAction:move];
}

-(void)updateStatus:(int)_taskIcon taskStep:(int)_stepIcon type:(int)_type{
	CCLOG(@"\n --------------------- \n");
	CCLOG(@"TaskPattern->updateStatus: \n taskIcon:(%d) \n taskStep:(%d) \n type:(%d)",
		  _taskIcon,
		  _stepIcon,
		  _type);
	CCLOG(@"\n --------------------- \n");
	
	self.taskType = _type ;
	self.taskIcon = _taskIcon;
	self.stepIcon = _stepIcon;
	
	[self showInfo];
}

-(void)showInfo{
	
	[self removeChildByTag:Background_tag cleanup:YES];
	[self removeChildByTag:TaskType_tag cleanup:YES];
	[self removeChildByTag:TaskIcon_tag cleanup:YES];
	[self removeChildByTag:Effect_tag cleanup:YES];
	
	if (self.taskIcon > 0)
	{
		NSString *icon = [NSString stringWithFormat:@"%d",self.taskIcon];
		CCSprite * iconSpr = [TaskIconViewerContent create:icon];
		iconSpr.anchorPoint=ccp(0.5, 0);
		iconSpr.position=ccp(self.contentSize.width/2, 0);
		[self addChild:iconSpr z:4 tag:TaskIcon_tag];
	}
	
	if (self.stepIcon > 0)
	{
		NSString *icon = [NSString stringWithFormat:@"%d",self.stepIcon];
		CCSprite * iconSpr = [TaskIconViewerContent create:icon];
		iconSpr.anchorPoint=ccp(0.5, 0);
		iconSpr.position=ccp(self.contentSize.width/2, 0);
		[self addChild:iconSpr z:4 tag:TaskIcon_tag];
	}
	
	if (self.taskIcon > 0 || self.stepIcon > 0 ) {
		CCSprite* sprite = [CCSprite spriteWithFile:@"images/ui/characterIcon/big.png"];
		sprite.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
		[self addChild:sprite z:1 tag:Background_tag];
		
		if (self.taskType > 0){
			NSString *type_icon_path = [NSString stringWithFormat:@"images/ui/alert/task_%d.png", self.taskType];
			CCSprite *type_icon = [CCSprite spriteWithFile:type_icon_path];
			if (type_icon) {
				if (iPhoneRuningOnGame()) {
					type_icon.position = ccp(100/2.0f, 25/2.0f);
				}else{
					type_icon.position = ccp(100, 25);
				}
				[self addChild:type_icon z:10 tag:TaskType_tag];
			}
		}
		
		[self showEffect];
		
	}
	
	if (self.taskIcon == OfferIcon) {
		m_func = TaskPattern_doOffer ;
	}else if (self.taskIcon > 0 || self.stepIcon > 0){
		m_func = TaskPattern_doTask ;
	}else{
		m_func = TaskPatternStatus_none;
	}
}

@end

#endif

