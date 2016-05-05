//
//  MessageAlert.m
//  TXSFGame
//
//  Created by huang shoujun on 13-1-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "MessageAlert.h"
#import "AlertManager.h"
#import "StretchingImg.h"
#import "CCSimpleButton.h"
#import "Config.h"
#import "GameLayer.h"

//iphone for chenjunming

@implementation MessageAlert

@synthesize isUrgent = _isUrgent;
@synthesize canel = canel_;
@synthesize message;
@synthesize delay=delay_;
@synthesize type;
@synthesize recordKey;
@synthesize recordTips;

-(void)onExit{
	if (self.type !=MessageAlert_none) {
		CCDirector *director = [CCDirector sharedDirector];
		[[director touchDispatcher] removeDelegate:self];
		
		if([Game checkIsInGameing]){
			[GameLayer shared].touchEnabled = YES;
		}
		
	}
	[super onExit];
}
-(void)onEnter{
	[super onEnter];
	
	if (self.type == MessageAlert_none) {
		//-------------------------------------------
		CCSprite *background = nil;
		if(iPhoneRuningOnGame()){
			background = [StretchingImg stretchingImg:@"images/ui/bound.png" width:244 height:57 capx:4 capy:4];
		}else{
			background = [StretchingImg stretchingImg:@"images/ui/bound.png" width:488 height:114 capx:8 capy:8];
		}
		self.contentSize=background.contentSize;
		background.position=ccp(background.contentSize.width/2, background.contentSize.height/2);
		[self addChild:background];
		
        
		if (self.message) {
			
			CCSprite *msg = nil;
			msg = drawString(self.message, CGSizeMake(400, 100), getCommonFontName(FONT_1), 22, 30,getHexStringWithColor3B(ccc3(255, 241, 207)));
			
			msg.anchorPoint=ccp(0.5, 0.5);
			[background addChild:msg];
			msg.position=ccp(background.contentSize.width/2, background.contentSize.height/2);
		}
		//---------------------------------------------
		id act1 = [CCScaleTo actionWithDuration:0.1 scale:1.2];
		id act2 = [CCScaleTo actionWithDuration:0.05 scale:1.0];
		id act3 = [CCDelayTime actionWithDuration:self.delay];
		id act4 = [CCScaleTo actionWithDuration:0.05 scale:0.3];
		id act5 = [CCCallFunc actionWithTarget:self selector:@selector(endShowMessageAlert)];
		[self runAction:[CCSequence actions:act1,act2,act3,act4,act5,nil]];

	}else{
		
		CCDirector *director =  [CCDirector sharedDirector];
		[[director touchDispatcher] addTargetedDelegate:self priority:INT32_MIN+1 swallowsTouches:YES];
		
		CCSprite *background = nil;
		if(iPhoneRuningOnGame()){
			background = [StretchingImg stretchingImg:@"images/ui/bound.png" width:558/2 height:274/2 capx:4 capy:4];
		}else{
			background = [StretchingImg stretchingImg:@"images/ui/bound.png" width:558 height:274 capx:8 capy:8];
		}
		self.contentSize=background.contentSize;
		background.position=ccp(background.contentSize.width/2, background.contentSize.height/2);
		[self addChild:background];
		
		if (self.message) {
			
			CCSprite *msg = nil;

			msg = drawString(self.message, CGSizeMake(488, 114), getCommonFontName(FONT_1), 22, 30,getHexStringWithColor3B(ccc3(255, 241, 207)));
			
            msg.anchorPoint=ccp(0.5, 1);
			[background addChild:msg];
			msg.position=ccp(background.contentSize.width/2, background.contentSize.height-cFixedScale(35.0/2));
		}

        CCSprite *line = [CCSprite spriteWithFile:@"images/ui/alert/line.png"];
		
		if(iPhoneRuningOnGame()){
			line.scale = (558.0f/2/2)/line.contentSize.width;
			[background addChild:line];
			line.position=ccp(background.contentSize.width/2, background.contentSize.height-180/2);
		}else{
			line.scale = 558.0f/line.contentSize.width;
			[background addChild:line];
			line.position=ccp(background.contentSize.width/2, background.contentSize.height-180);
		}
		
		CCSimpleButton *btOk = nil;
		CCSimpleButton *btNo = nil;
//		if (self.call)
		{
			btOk = [CCSimpleButton spriteWithFile:@"images/ui/alert/bt_ok_1.png" select:@"images/ui/alert/bt_ok_2.png" target:self call:@selector(selectOK:)];
			btOk.priority=INT32_MIN;
			[self addChild:btOk];
			btOk.anchorPoint=ccp(0.5, 0);
			
			if(iPhoneRuningOnGame()){
				btOk.scale=1.3f;
				btOk.position=ccp(self.contentSize.width/2, 20/2);
			}else{
				btOk.position=ccp(self.contentSize.width/2, 20);
			}
			
		}
		
//		if (self.canel)
		if(self.type != MessageAlert_error)
		{
			btNo = [CCSimpleButton spriteWithFile:@"images/ui/alert/bt_cancel_1.png" select:@"images/ui/alert/bt_cancel_2.png" target:self call:@selector(selectN0:)];
			btNo.priority=INT32_MIN;
			[self addChild:btNo];
			btNo.anchorPoint=ccp(0.5, 0);
			if (btOk) {
				if(iPhoneRuningOnGame()){
					btNo.scale=btOk.scale;
					btOk.position=ccp(self.contentSize.width/2-btOk.contentSize.width*btOk.scale/2.0f-10/2.0f, 20/2.0f);
					btNo.position=ccp(self.contentSize.width/2+btNo.contentSize.width/2+10/2.0f, 20/2.0f);
				}else{
					btOk.position=ccp(self.contentSize.width/2-btOk.contentSize.width/2-10, 20);
					btNo.position=ccp(self.contentSize.width/2+btNo.contentSize.width/2+10, 20);
				}
				
			}else{
				
				if(iPhoneRuningOnGame()){
					btNo.scale=btOk.scale;
					btNo.position=ccp(self.contentSize.width/2, 20/2);
				}else{
					btNo.position=ccp(self.contentSize.width/2, 20);
				}
				
			}
		}
		
		//[[GameLayer shared] setIsTouchEnabled:NO];
		if([GameLayer isShowing]){
			[GameLayer shared].touchEnabled = NO;
		}
		
		if (self.type == MessageAlert_setting) {
			
			if (recordTips && recordKey) {
				//带确认
				CCMenu *menu = [CCMenu node];
				menu.ignoreAnchorPointForPosition=YES;
				[self addChild:menu z:10 tag:888];
				menu.anchorPoint=ccp(0, 0);
				menu.position=ccp(0, 0);
				
				NSArray* array = getToggleSprites(@"images/ui/button/bt_toggle01.png",
												  @"images/ui/button/bt_toggle02.png",
												  recordTips,
												  iPhoneRuningOnGame()?8:15,
												  ccc4(237,228,205,255),
												  ccc4(237,228,205,255) );
				if ([array count] >= 2) {
					CCMenuItemSprite *item1 =  [CCMenuItemSprite itemWithNormalSprite:[array objectAtIndex:0] selectedSprite:nil];
					CCMenuItemSprite *item2 =  [CCMenuItemSprite itemWithNormalSprite:[array objectAtIndex:1] selectedSprite:nil];
					CCMenuItemToggle *button = [CCMenuItemToggle itemWithTarget:self selector:@selector(updateRecord:) items:item1,item2, nil];
					[menu addChild:button z:0 tag:130];
					
					if(iPhoneRuningOnGame()){
						button.scale=1.3f;
						button.position=ccp(background.contentSize.width/2, background.contentSize.height-160/2);
					}else{
						button.position=ccp(background.contentSize.width/2, background.contentSize.height-160);
					}
					
					bRecord = [[[GameConfigure shared] getPlayerRecord:recordKey] boolValue];
					if (bRecord) {
						[button setSelectedIndex:1];
					}
				}
				
			}
		}
	}
}
-(void)updateRecord:(id)sender{
	CCMenuItemToggle *_obj = (CCMenuItemToggle*)sender;
	if (_obj.selectedIndex == 1) {
		bRecord = YES;
		//[[GameConfigure shared] recordPlayerSetting:recordKey value:[NSNumber numberWithBool:YES]];
	}else if (_obj.selectedIndex == 0) {
		bRecord=NO;
		//[[GameConfigure shared] recordPlayerSetting:recordKey value:[NSNumber numberWithBool:NO]];
	}
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
}
-(void)selectOK:(id)sender{
	if(target!=nil && call!=nil){
		[target performSelector:call];
	}
	if (self.type == MessageAlert_setting){
		if (recordTips && recordKey){
			[[GameConfigure shared] recordPlayerSetting:recordKey value:[NSNumber numberWithBool:bRecord]];
		}
	}
	[self endShowMessageAlert];
}
-(void)selectN0:(id)sender{
	if(target!=nil && canel_!=nil){
		[target performSelector:canel_];
	}
	[self endShowMessageAlert];
}
-(void)endShowMessageAlert{
	if (message) {
		[message release];
		message = nil;
	}
	if (recordKey) {
		[recordKey release];
		recordKey=nil;
	}
	if (recordTips) {
		[recordTips release];
		recordTips=nil;
	}
	if (_isUrgent) {
		//这里不交给AlertManager的列表
		//所以可以直接自己删除自己
		[self removeFromParentAndCleanup:YES];
		
	}else{
		[[AlertManager shared] remove];
	}
}
@end
