//
//  MessageNPCAlert.m
//  TXSFGame
//
//  Created by TigerLeung on 13-2-1.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "MessageNPCAlert.h"
#import "AlertManager.h"
#import "StretchingImg.h"
#import "CCSimpleButton.h"
#import "Config.h"
#import "GameLayer.h"
#import "NPCManager.h"
#import "GameNPC.h"
#import "TaskIconViewerContent.h"

//iphone for chenjunming

@implementation MessageNPCAlert

@synthesize message;
@synthesize canel;
@synthesize npcId;

-(void)onExit{
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	[GameLayer shared].touchEnabled = YES;
	
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-255 swallowsTouches:YES];
	
	CCSprite * bg = [CCSprite spriteWithFile:@"images/ui/alert/bg-npc.png"];
	[self addChild:bg];
	
	//NSString * npcIcon = [NSString stringWithFormat:@"images/ui/task_icon/task_icon_%d.png",npcId];
	//CCSprite * icon = [CCSprite spriteWithFile:npcIcon];
	CCSprite * icon = [TaskIconViewerContent create:[NSString stringWithFormat:@"%d",npcId]];
	if (icon != nil ) {
		icon.anchorPoint = ccp(0.5,0);
		icon.position = iPhoneRuningOnGame()? ccp(60/2,0):ccp(60,0);
		if(iPhoneRuningOnGame()){
			icon.position = ccp(30,0);
		}
		[bg addChild:icon];
	}else{
		CCLOG(@"can't find images!");
	}

	
	if(message){
		
		CCSprite * msg = nil;
		
		msg = drawString(self.message, CGSizeMake(400, 50), getCommonFontName(FONT_1), 22, 30,getHexStringWithColor3B(ccc3(255, 241, 207)));
		if(iPhoneRuningOnGame()){
//			msg = drawString(self.message, CGSizeMake(400/2, 50/2), getCommonFontName(FONT_1), 22/2, 30/2,getHexStringWithColor3B(ccc3(255, 241, 207)));
			msg.position=ccp(130/2, 85/2);
		}else{
			msg.position=ccp(130, 85);
		}
		
		msg.anchorPoint=ccp(0,1);
		[bg addChild:msg];
	}
	
	GameNPC * targetNpc = [[NPCManager shared] getNPCById:npcId];
	if(targetNpc && targetNpc.isHasFunc){
		isHasNpcFunc = YES;
	}
	
	if(isHasNpcFunc){
		CCSimpleButton *btOk = nil;
		CCSimpleButton *btNo = nil;
		btOk = [CCSimpleButton spriteWithFile:@"images/ui/alert/bt_ok_1.png" select:@"images/ui/alert/bt_ok_2.png" target:self call:@selector(selectOK:)];
		btOk.priority=-256;
		[self addChild:btOk];
		btOk.anchorPoint=ccp(0.5, 0);
		btOk.position=ccp(self.contentSize.width/2, cFixedScale(-88));
		
		btNo = [CCSimpleButton spriteWithFile:@"images/ui/alert/bt_cancel_1.png" select:@"images/ui/alert/bt_cancel_2.png" target:self call:@selector(selectN0:)];
		btNo.priority=-256;
		[self addChild:btNo];
		btNo.anchorPoint=ccp(0.5, 0);
		if (btOk) {
			btOk.position=ccp(self.contentSize.width/2-btOk.contentSize.width/2-cFixedScale(10), cFixedScale(-88));
			btNo.position=ccp(self.contentSize.width/2+btNo.contentSize.width/2+cFixedScale(10), cFixedScale(-88));
		}else{
			btNo.position=ccp(self.contentSize.width/2, cFixedScale(-88));
		}
	}
	
	//[[GameLayer shared] setIsTouchEnabled:NO];
	[GameLayer shared].touchEnabled = NO;
	
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
	return YES;
}
- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
}
- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	CCMenu* menu = (CCMenu*)[self getChildByTag:888];
	if (menu) {
		if ([menu ccTouchBegan:touch withEvent:event]) {
			[menu ccTouchEnded:touch withEvent:event];
		}
	}
	if(!isHasNpcFunc){
		[self selectN0:nil];
	}
}
-(void)selectOK:(id)sender{
	if(target!=nil && call!=nil){
		[target performSelector:call];
	}
	
	[self endShowMessageAlert];
}
-(void)selectN0:(id)sender{
	if(target!=nil && canel!=nil){
		[target performSelector:canel];
	}
	[self endShowMessageAlert];
}

-(void)endShowMessageAlert{
	if (message) {
		[message release];
		message = nil;
	}
	[[AlertManager shared] remove];
}
@end
