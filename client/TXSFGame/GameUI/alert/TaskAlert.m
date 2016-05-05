//
//  TaskAlert.m
//  TXSFGame
//
//  Created by shoujun huang on 13-1-2.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "TaskAlert.h"
#import "TaskManager.h"
#import "Task.h"
#import "CCLabelFX.h"
#import "Config.h"
#import "GameLayer.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "TaskAlert.h"

#import "FightManager.h"
#import "Window.h"
#import "MapManager.h"
#import "TaskTalk.h"
#import "StageTask.h"
#import "GameStart.h"

@implementation TaskAlert

@synthesize task;
@synthesize bNeedInfo;

-(void)show{
	
	if (!self.parent) {
		
		BOOL isCanShow = YES;
		
		if([FightManager isFighting])			isCanShow = NO;
		if([[Window shared] isHasWindow])		isCanShow = NO;
		if([TaskTalk isTalking])				isCanShow = NO;
		if([StageTask isTalking])				isCanShow = NO;
		if([GameStart isOpen])					isCanShow = NO;
		if(![[MapManager shared] checkMapCanShowTaskAlert]) isCanShow = NO;
		
		if (isCanShow) {
			
			[[RoleManager shared].player stopMove];
			
			[[Game shared] addChild:self z:INT32_MAX-10];
			CGSize winSize = [[CCDirector sharedDirector] winSize];
			
			if(iPhoneRuningOnGame()){
				self.position = ccp(winSize.width/2, winSize.height/2-115/2);
			}else{
				self.position = ccp(winSize.width/2, winSize.height/2-115);
			}
		}
		
	}
	
}

-(id)init{
	if(self=[super init]){
		bNeedInfo = NO;
		bTouchDelay = YES;
	}
	return self;
}

-(void)setTask:(Task*)_task{
	task = _task;
	if(task){
		[task retain];
	}
}

-(void)updateDelay{
	bTouchDelay = NO ;
}
-(void)onEnter{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-255 swallowsTouches:YES];
	
	CCSprite *background = [CCSprite spriteWithFile:@"images/ui/alert/task_bg.png"];
	self.contentSize=background.contentSize;
	[self addChild:background];
	background.position=ccp(background.contentSize.width/2, background.contentSize.height/2);
	
	if (self.task) {
		int value = 2 ;
		if (self.task.status == Task_Status_complete ) {
			value = 1 ;
		}
		if (!task.isUnlock) {
			value=5;
		}
		NSString *title_path = [NSString stringWithFormat:@"images/ui/alert/taskAlert_%d.png",value];
		CCSprite *title = [CCSprite spriteWithFile:title_path];
		title.anchorPoint=ccp(0.5, 1);
		[background addChild:title z:INT16_MAX];
		title.position=ccp(background.contentSize.width/2, background.contentSize.height);
		
		NSString *icon_path = [NSString stringWithFormat:@"images/ui/alert/task_%d.png",self.task.type];
		CCSprite *icon = [CCSprite spriteWithFile:icon_path];
		icon.anchorPoint=ccp(0.5, 1);
		[background addChild:icon z:INT16_MAX];
		if(iPhoneRuningOnGame()){
			icon.position=ccp(background.contentSize.width/2 + 50, background.contentSize.height-10);
		}else{
			icon.position=ccp(background.contentSize.width/2 + 100, background.contentSize.height-20);
		}
		
		NSDictionary *dict = self.task.taskInfo;
		NSString *name = [dict objectForKey:@"name"];
		ccColor4B label_color = ccc4(236, 180, 70, 255);
		if (self.task.status == Task_Status_complete) {
			//name = [name stringByAppendingFormat:@"（完成）"];
            name = [name stringByAppendingFormat:NSLocalizedString(@"task_alert_complete",nil)];
			label_color = ccc4(5, 169, 87, 255);
		}else{
			//name = [name stringByAppendingFormat:@"（可接）"];
            name = [name stringByAppendingFormat:NSLocalizedString(@"task_alert_can_do",nil)];
		}
		
		//===========================
		//===========================
		if (value == 5 && self.task.type == Task_Type_main) {//如果系未能开启的任务
			NSDictionary* dict = self.task.taskInfo;
			NSString* lockStr = [dict objectForKey:@"unlock"];
			NSArray* args = [lockStr componentsSeparatedByString:@":"];
			if (args != nil && args.count > 2) {
				int level = [[args objectAtIndex:1] intValue];
				int plevel = [[GameConfigure shared] getPlayerLevel];
				if (plevel < level) {
					//name = [NSString stringWithFormat:@"主将 %d 级可解锁",level];
                    name = [NSString stringWithFormat:NSLocalizedString(@"task_alert_can_open",nil),level];
					label_color = ccc4(255, 0, 0, 255);
				}
			}
		}
		//===========================
		//===========================
		CCLabelFX *label_name = [CCLabelFX labelWithString:name
												  fontName:GAME_DEF_CHINESE_FONT
												  fontSize:26
											  shadowOffset:CGSizeMake(2, 2)
												shadowBlur:0.2
											   shadowColor:ccc4(0, 0, 0, 0)
												 fillColor:label_color];
		[self addChild:label_name z:10];
		if(iPhoneRuningOnGame()){
			label_name.position=ccp(self.contentSize.width/2+10, self.contentSize.height/2-5);
		}else{
			label_name.position=ccp(self.contentSize.width/2+20, self.contentSize.height/2-20);
		}
		
		CCMenu *menu = [CCMenu node];		
		[self addChild:menu];
		//fix chao
		menu.tag = 555;
		///end
		menu.ignoreAnchorPointForPosition=YES;
		menu.position=menu.anchorPoint=CGPointZero;
		
		NSString *text = nil ;
		if (value == 5) {
			//text = [NSString stringWithFormat:@"点击确定"];
            text = [NSString stringWithFormat:NSLocalizedString(@"task_alert_is_sure",nil)];
		}else{
			//text = [NSString stringWithFormat:@"点击接取"];
            text = [NSString stringWithFormat:NSLocalizedString(@"task_alert_is_get",nil)];
		}
		
		if (self.task.status == Task_Status_complete) {
			CCSprite *face = [CCSprite spriteWithFile:@"images/ui/npc_alert/4.png"];
			//face.scale = 0.75;
			face.anchorPoint=ccp(1, 0.5);
			float _x = self.contentSize.width/2 - label_name.contentSize.width/2 ;
			_x -= 2;
			[self addChild:face z:10];
			
			if(iPhoneRuningOnGame()){
				face.position=ccp(_x, self.contentSize.height/2-10);
			}else{
				face.position=ccp(_x, self.contentSize.height/2-20);
			}
			
			//text = [NSString stringWithFormat:@"点击完成"];
            text = [NSString stringWithFormat:NSLocalizedString(@"task_alert_is_finish",nil)];
		}else {
			CCSprite *face = [CCSprite spriteWithFile:@"images/ui/npc_alert/1.png"];
			//face.scale = 0.75;
			face.anchorPoint=ccp(1, 0.5);
			float _x = self.contentSize.width/2 - label_name.contentSize.width/2 ;
			_x -= 2;
			[self addChild:face z:10];
			
			if(iPhoneRuningOnGame()){
				face.position=ccp(_x, self.contentSize.height/2-10);
			}else{
				face.position=ccp(_x, self.contentSize.height/2-20);
			}
		}
		
		CCLabelTTF *label = [CCLabelTTF labelWithString:text
											   fontName:GAME_DEF_CHINESE_FONT
											   fontSize:20
											 dimensions:CGSizeMake(90, 30)
											 hAlignment:kCCTextAlignmentCenter
											 vAlignment:kCCVerticalTextAlignmentCenter];
		label.color = ccc3(238, 228, 207);
		
		CCMenuItemLabel *bt_label = [CCMenuItemLabel itemWithLabel:label target:self selector:@selector(doOk:)];
		if(iPhoneRuningOnGame()){
			bt_label.scale = 0.5;
			bt_label.position=ccp(self.contentSize.width/2, self.contentSize.height/2-30);
		}else{
			bt_label.position=ccp(self.contentSize.width/2, self.contentSize.height/2-60);
		}
		
		[menu addChild:bt_label];
		
		[GameLayer shared].touchEnabled = NO;
	}
	
	[self scheduleOnce:@selector(updateDelay) delay:0.5];//推迟0.5秒
}
-(void)onExit{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	//[[GameLayer shared] setIsTouchEnabled:YES];
	[GameLayer shared].touchEnabled = YES;
	
	if(task){
		[task release];
		task = nil;
	}
	
	[super onExit];
}
- (CGRect)rect{
	CGSize s = self.contentSize;
	return CGRectMake(-s.width / 2, -s.height / 2, s.width, s.height);
}
- (BOOL)containsTouchLocation:(UITouch *)touch{
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	CGRect r = [self rect];
	return CGRectContainsPoint(r, p);
}
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{

	if (bTouchDelay) {
		return YES;
	}
	//fix chao
	isMenuTouch = NO;

	CCMenu *menu = (CCMenu *)[self getChildByTag:555];
	if ([menu ccTouchBegan:touch withEvent:event]) {
		isMenuTouch = YES;
	}
	return YES;
}
- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	if (bTouchDelay) {
		return ;
	}
	//fix chao
	if (isMenuTouch) {
		CCMenu *menu = (CCMenu *)[self getChildByTag:555];
		[menu ccTouchMoved:touch withEvent:event];
	}
	//end
}
- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if (bTouchDelay) {
		return ;
	}
	//fix chao
	if (isMenuTouch) {
		CCMenu *menu = (CCMenu *)[self getChildByTag:555];
		[menu ccTouchEnded:touch withEvent:event];
	}else{
		[self endAlert];
	}
	//end
}
-(void)doOk:(id)_sender{
	[self endAlert];
}
-(void)endAlert{
	
	if (bNeedInfo) {
		if (target!=nil && call!=nil) {
			[target performSelector:call withObject:task];
		}
	}else{
		if (target!=nil && call!=nil) {
			[target performSelector:call];
		}
	}
	if (task) {
		[task release];
		task=nil;
	}
	[super remove];
}
@end
