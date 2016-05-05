//
//  TaskTalk.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-15.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "TaskTalk.h"
#import "Game.h"
#import "GameEffects.h"
#import "GameUI.h"
#import "GameLayer.h"
#import "TaskManager.h"
#import "Task.h"
#import "CCLabelFX.h"
#import "GameConfigure.h"
#import "RoleManager.h"
#import "GameDB.h"
#import "Window.h"
#import "RoleManager.h"
#import "ClickAnimation.h"
#import "GameNPC.h"
#import "NPCManager.h"
#import "RolePlayer.h"
#import "AlertManager.h"
#import "WorldMap.h"
#import "MessageAlert.h"
#import "RoleOption.h"

#import "TalkNpcViewerContent.h"
#import "TalkRoleViewerContent.h"

static NSDictionary * playerInfo;
static NSDictionary * roleInfo;
static void freePlayerInfo(){
	if(playerInfo){
		[playerInfo release];
		playerInfo = nil;
	}
	if(roleInfo){
		[roleInfo release];
		roleInfo = nil;
	}
}
static void loadPlayerInfo(){
	freePlayerInfo();
	
	playerInfo = [[GameConfigure shared] getPlayerInfo];
	[playerInfo retain];
	
	roleInfo = [[GameDB shared] getRoleInfo:[[playerInfo objectForKey:@"rid"] intValue]];
	[roleInfo retain];
	
}

static NSString * getStringFromPlayer(NSString*string){
	
	if(isEqualToKey(string,@":sex")) return [roleInfo objectForKey:@"sex"];
	if(isEqualToKey(string,@":name")) return [playerInfo objectForKey:@"name"];
	
	return @"";
}

static NSString * getStringFromCondition(NSString*string){
	
	NSArray * ary1 = [string componentsSeparatedByString:@"?"];
	if([ary1 count]>1){
		NSArray * ary2 = [[ary1 objectAtIndex:1] componentsSeparatedByString:@":"];
		NSString * str1 = [ary1 objectAtIndex:0];
		NSString * str2 = getStringFromPlayer(str1);
		if(isEqualToKey(str1,@":sex")){
			if([str2 intValue]==1) return [ary2 objectAtIndex:0];
			if([str2 intValue]==2) return [ary2 objectAtIndex:1];
		}
	}else{
		return getStringFromPlayer(string);
	}
	return @"";
}

static NSString * getFormatString(NSString*msg){
	NSString * result = @"";
	NSArray * msgs = [msg componentsSeparatedByString:@"}"];
	for(NSString * str in msgs){
		NSArray * ary = [str componentsSeparatedByString:@"{"];
		if([ary count]==2){
			NSString * str1 = [ary objectAtIndex:0];
			NSString * str2 = [ary objectAtIndex:1];
			result = [NSString stringWithFormat:@"%@%@%@",result,str1,getStringFromCondition(str2)];
		}else{
			result = [NSString stringWithFormat:@"%@%@",result,str];
		}
	}
	return result;
}


@implementation TaskTalk
@synthesize messages;
//@synthesize task;
@synthesize target;
@synthesize call;
@synthesize taskId;
@synthesize taskStep;

static TaskTalk * taskTalk;
static BOOL GameUIStatus;

+(BOOL)isShowTalking:(int)_tid taskStep:(int)_step{
	if (taskTalk != nil) {
		if (taskTalk.taskId == _tid && taskTalk.taskStep == _step) {
			return YES;
		}else{
			//todo delete talk????
		}
	}
	return NO;
}

+(void)removeAllUi{
	
	GameUIStatus = [GameUI shared].isShowUI;
	if(GameUIStatus){
		[[GameUI shared] closeUI];
	}
	[[GameUI shared] closeOtherUI];
	
	//[GameUI shared].visible = NO;
	
	[[Window shared] removeAllWindows];
	[Window destroy];
	[[AlertManager shared] closeAlert];
	[[RoleManager shared] stopMovePlayer];
	[WorldMap stopAll];
	
	[[RoleOption shared] binding:Nil];
	
}

+(void)show:(NSArray*)msgs target:(id)target call:(SEL)call{
	
	if (taskTalk != nil){
		CCLOG(@"TaskTalk error: have taskTalk no release!!!");
		return ;
	}
	//清楚全部UI
	[TaskTalk removeAllUi];
	//屏蔽玩家
	[[RoleManager shared] otherPlayerVisible:NO];
	//------
	
	loadPlayerInfo();
	
	taskTalk = [TaskTalk node];
	taskTalk.messages = msgs;
	taskTalk.target = target;
	taskTalk.call = call;
	
	[[Game shared] addChild:taskTalk z:INT16_MAX tag:98765];
	
	//关闭可能打开的聊天框
	//[[GameUI shared] closeLowerLeftChat];
	
}


+(void)remove{
	
	if(taskTalk){
		[taskTalk removeFromParentAndCleanup:YES];
		taskTalk = nil;
	}
	
	freePlayerInfo();
	
	[[RoleManager shared] otherPlayerVisible:YES];
	
}
+(BOOL)isTalking{
	if(taskTalk){
		return YES;
	}
	return NO;
}

-(void)dealloc{
	[super dealloc];
	CCLOG(@"TaskTalk dealloc");
}

-(void)onEnter{
	[super onEnter];
	[self setTouchEnabled:YES];
	
	bTouchDelay = YES ;
	isGameUiShow = GameUIStatus;
	
	[GameLayer shared].touchEnabled = NO;
	
	//-------------
	//延迟一秒才给操作
	[self scheduleOnce:@selector(updateDelay) delay:0.5f];
	//[[GameEffects share] showEffects:EffectsAction_zoomIn target:self call:@selector(startShowMesage)];
	//[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(startShowMesage) userInfo:nil repeats:NO];
	[self startShowMesage];
	[[Intro share]hideCurrenTips];
	
}

-(void)registerWithTouchDispatcher{
	CCDirector* director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-256 swallowsTouches:YES];
}

-(void)onExit{
	
	//[[Intro share]showCurrenTips];
	
	taskTalk = nil;
	[messages release];
	[super onExit];
	
	[[CCDirector sharedDirector] purgeCachedData];
	
}

-(void)startShowMesage{
	
	//self.touchEnabled = YES;
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	CCSprite * content = [CCSprite node];
	[self addChild:content z:0 tag:100];
	
	CCSprite * bg1 = [CCSprite spriteWithFile:@"images/talk/bg-talk.png"];
	CCSprite * bg2 = [CCSprite spriteWithFile:@"images/talk/bg-talk.png"];
	bg1.anchorPoint = ccp(0,0);
	bg2.anchorPoint = ccp(0,0);
	//bg2.scaleX = -1;
	bg2.position = ccp(winSize.width,0);
	
	bg1.scaleX = (winSize.width/2)/bg1.contentSize.width;
	bg2.scaleX = -bg1.scaleX;
	
	[content addChild:bg1 z:0];
	[content addChild:bg2 z:0];
	
	//fix chao 加入对话动画按钮
	ClickAnimation *click = (ClickAnimation *)[self getActionByTag:555];
	if (!click) {
		click = [ClickAnimation showInLayer:content 
									  point:ccp(winSize.width*0.75,25) 
									   path:@"images/talk/uidialog/" loop:YES];
		
		click.tag = 555;
		if(iPhoneRuningOnGame()){
			click.position = ccp(winSize.width*0.75,15); 
		}
	}
	//end
	//任务对话字体大小
	float fontSize=22;
	if (iPhoneRuningOnGame()) {
		fontSize=26;
	}
	CCLabelFX * label = [CCLabelFX labelWithString:@""
										dimensions:CGSizeMake(440,120)
										 alignment:kCCTextAlignmentLeft
										  fontName:getCommonFontName(FONT_1)
										  fontSize:fontSize
									  shadowOffset:CGSizeMake(0.5,0.5)
										shadowBlur:2.0f
									   shadowColor:ccc4(255,241,207, 255)
										 fillColor:ccc4(255,241,207, 255)
						 ];
	label.anchorPoint = ccp(0.5,0.0);
	[content addChild:label z:101 tag:101];
	fontSize=24;
	if (iPhoneRuningOnGame()) {
		fontSize=28;
	}
	CCLabelFX * name = [CCLabelFX labelWithString:@""
									   dimensions:CGSizeMake(440,30)
										alignment:kCCTextAlignmentLeft
										 fontName:getCommonFontName(FONT_1)
										 fontSize:fontSize
									 shadowOffset:CGSizeMake(0.5,0.5)
									   shadowBlur:2.0f
									  shadowColor:ccc4(255,241,207, 255)
										fillColor:ccc4(255,241,207, 255)
						];
	
	name.anchorPoint = ccp(0.5,0.0);
	[content addChild:name z:102 tag:102];
	
	if(iPhoneRuningOnGame()){
		name.position = ccp(winSize.width/2,123/2);
		label.position = ccp(winSize.width/2,123/2-60);
	}else{
		label.position = ccp(winSize.width/2,123-120);
		name.position = ccp(winSize.width/2,123);
	}
	
	bTouchDelay = YES;
	isEndTalk = NO;
	content.position = ccp(0,cFixedScale(-300));
	id time = [CCDelayTime actionWithDuration:0.25f];
	id move = [CCMoveTo actionWithDuration:0.35f position:ccp(0,0)];
	id action = [CCCallBlock actionWithBlock:^{
		mid = 0;
		//TODO 延迟再删除一次窗口，看看会不会有问题
		CCLOG(@"TaskTalk->TaskTalk removeAllUi");
		[TaskTalk removeAllUi];
		//再屏蔽一次玩家
		[[RoleManager shared] otherPlayerVisible:NO];
		
		[self showMesage];
	}];
	[content runAction:[CCSequence actions:time, move, action, nil]];
	
}
-(void)showMesage{
	
	if(isEndTalk) return;
	
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	if(mid<[messages count]){
		
		CCLOG(@"showMesage");
		
		NSDictionary * data = [messages objectAtIndex:mid];
		
		int rid = [[data objectForKey:@"rid"] intValue];
		int nid = [[data objectForKey:@"nid"] intValue];
		int dir = [[data objectForKey:@"dir"] intValue];
		
		NSString * msg = [data objectForKey:@"msg"];
		NSDictionary * info;
		
		CCNode * content = [self getChildByTag:100];
		CCLabelFX * label = (CCLabelFX*)[content getChildByTag:101];
		CCLabelFX * nameLabel = (CCLabelFX*)[content getChildByTag:102];
		
		[label setString:getFormatString(msg)];
		[nameLabel setString:@""];
		
		//??????
		//CCSprite * icon_ = (CCSprite*)[self getChildByTag:103];
		CCSprite * icon_ = (CCSprite*)[content getChildByTag:103];
		if(icon_){
			icon_.tag = 105;
			[icon_ removeFromParentAndCleanup:YES];
		}
		
		CCSprite * icon = nil;
		if(nid>0){
			
			//icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/talk/n/npc_big_%d.png",nid]];
			icon = [TalkNpcViewerContent create:nid];
			info = [[GameDB shared] getNpcInfo:nid];
			
			[nameLabel setString:[info objectForKey:@"name"]];
			
		}else{
			
			if(rid<=0){
				NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
				int t = [[player objectForKey:@"rid"] intValue];
				
				//icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/talk/r/player_big_%d.png",t]];
				icon = [TalkRoleViewerContent create:t];
				[nameLabel setString:[player objectForKey:@"name"]];
			}else{
				//icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/talk/r/player_big_%d.png",rid]];
				icon = [TalkRoleViewerContent create:rid];
				info = [[GameDB shared] getRoleInfo:rid];
				[nameLabel setString:[info objectForKey:@"name"]];
			}
		}
		if(!icon) icon = [CCSprite node];
		icon.anchorPoint = ccp(1,0);
		
		if(dir==1){
			icon.scaleX = -1.0f;
			icon.position = ccp(0,0);
		}else{
			icon.scaleX = 1.0f;
			icon.position = ccp(winSize.width,0);
		}
		[content addChild:icon z:10 tag:103];
		//[self addChild:icon z:10 tag:103];
		
		mid++;
		
	}else{
		
		CCLOG(@"showMesage end");
		
		isEndTalk = YES;
		
		CCNode * content = [self getChildByTag:100];
		CCLabelFX * label = (CCLabelFX*)[content getChildByTag:101];
		CCLabelFX * nameLabel = (CCLabelFX*)[content getChildByTag:102];
		[label setString:@""];
		[nameLabel setString:@""];
		
		id move = [CCMoveTo actionWithDuration:0.25f position:ccp(0,cFixedScale(-300))];
		id action = [CCCallBlock actionWithBlock:^{
			self.visible = NO;
			[self setTouchEnabled:NO];
			[self scheduleOnce:@selector(endTalk) delay:0.1f];
		}];
		[content runAction:[CCSequence actions:move, action, nil]];
		
		//CCSprite * icon = (CCSprite*)[self getChildByTag:103];
		CCSprite * icon = (CCSprite*)[content getChildByTag:103];
		if(icon){
			if(icon.scaleX==-1){
				[icon runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(cFixedScale(-350),0)]];
			}else{
				[icon runAction:[CCMoveTo actionWithDuration:0.2f position:ccp(winSize.width+cFixedScale(350),0)]];
			}
		}
		
	}
}

-(void)endTalk{
	
	CCLOG(@"endTalk");
	
	[self removeChildByTag:555 cleanup:YES];
	[self removeChildByTag:754768 cleanup:YES];
	[self removeChildByTag:67676 cleanup:YES];
	
	//[GameUI shared].visible = YES;
	//[[GameUI shared] openUI];
	if(isGameUiShow){
		[[GameUI shared] openUI];
		if ([GameUI shared].isShowUI) {
			[[GameUI shared] openLowerLeftChat];
		}
	}
	
	[[GameUI shared] openOtherUI];
	
	[GameLayer shared].touchEnabled = YES;
	
	//打开可能关诸的聊天框 只限初章
	/*
	if ([[GameConfigure shared] isPlayerOnChapter]) {
		[[GameUI shared] openLowerLeftChat];
	}
	*/
	
	[TaskTalk remove];
	
	if(target!=nil && call!=nil){
		[target performSelector:call];
	}
	
	target = nil ;
	call = nil ;
	
	[[AlertManager shared] checkStatus];
}

//==============================================================================
//==============================================================================
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    return YES;
}
-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if (bTouchDelay) {
		CCLOG(@"you touch too much");
		return ;
	}
	bTouchDelay = YES ;
	[self unschedule:@selector(updateDelay)];
	[self scheduleOnce:@selector(updateDelay) delay:0.1f];
	
	//if (_isWait) return ;
	
	[self showMesage];
}
-(void)updateDelay{
	bTouchDelay = NO ;
}

@end
