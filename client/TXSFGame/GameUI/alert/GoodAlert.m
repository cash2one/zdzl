//
//  GoodAlert.m
//  TXSFGame
//
//  Created by Soul on 13-7-30.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "GoodAlert.h"
#import "StretchingImg.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "FateIconViewerContent.h"
#import "AlertManager.h"

@implementation GoodAlert

@synthesize goodType;
@synthesize goodId;
@synthesize message;
@synthesize canel;
@synthesize recordKey;
@synthesize recordTips;

-(void)onExit{
	if (message != nil) {
		[message release];
		message = nil ;
	}
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	
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
	
	
	float cut_off_rule = self.contentSize.width / 3;
	CCSprite *goodsBg = [CCSprite spriteWithFile:@"images/ui/panel/itemNull.png"];
	goodsBg.anchorPoint = ccp(1.0f, 1.0f);
	goodsBg.position =ccp(cut_off_rule,self.contentSize.height - cFixedScale(50));
	[self addChild:goodsBg];
	
	CGPoint pt = goodsBg.position ;
	CGPoint gPt = ccpAdd(pt, ccp(-goodsBg.contentSize.width/2, -goodsBg.contentSize.height/2));
	
	
	if (goodType == GoodType_item) {
		CCSprite* sprite = getItemIcon(goodId);
		if (sprite) {
			sprite.position = gPt;
			[self addChild:sprite];
		}
	}else if (goodType == GoodType_fate){
		NSDictionary* dict = [[GameDB shared] getFateInfo:goodId];
		FateIconViewerContent * icon = [FateIconViewerContent create:goodId];
		icon.quality = [[dict objectForKey:@"quality"] intValue];
		if (icon) {
			icon.position = gPt;
			[self addChild:icon];
		}
	}
	
	
	if (self.message) {
		
		CCSprite *msg = nil;
		msg = drawString(self.message, CGSizeMake(400, 100), getCommonFontName(FONT_1), 22, 30,getHexStringWithColor3B(ccc3(255, 241, 207)));
		
		msg.anchorPoint=ccp(0, 1.0);
		[background addChild:msg];
		msg.position= ccpAdd(pt, ccp(cFixedScale(20), 0)) ;
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
	if (call != nil) {
		btOk = [CCSimpleButton spriteWithFile:@"images/ui/alert/bt_ok_1.png" select:@"images/ui/alert/bt_ok_2.png" target:self call:@selector(selectOK:)];
		btOk.priority=INT32_MIN;
		[self addChild:btOk];
		btOk.anchorPoint=ccp(0.5, 0);
	}
	
	if (canel != nil) {
		btNo = [CCSimpleButton spriteWithFile:@"images/ui/alert/bt_cancel_1.png" select:@"images/ui/alert/bt_cancel_2.png" target:self call:@selector(selectN0:)];
		btNo.priority=INT32_MIN;
		[self addChild:btNo];
		btNo.anchorPoint=ccp(0.5, 0);
	}
	
	if (btOk != nil && btNo != nil) {
		if(iPhoneRuningOnGame()){
			btNo.scale=btOk.scale;
			btOk.position=ccp(self.contentSize.width/2-btOk.contentSize.width*btOk.scale/2.0f-10/2.0f, 20/2.0f);
			btNo.position=ccp(self.contentSize.width/2+btNo.contentSize.width/2+10/2.0f, 20/2.0f);
		}else{
			btOk.position=ccp(self.contentSize.width/2-btOk.contentSize.width/2-10, 20);
			btNo.position=ccp(self.contentSize.width/2+btNo.contentSize.width/2+10, 20);
		}
	}else if (btNo != nil){
		if(iPhoneRuningOnGame()){
			btNo.scale=btOk.scale;
			btNo.position=ccp(self.contentSize.width/2, 20/2);
		}else{
			btNo.position=ccp(self.contentSize.width/2, 20);
		}
		
	}else if (btOk != nil){
		if(iPhoneRuningOnGame()){
			btOk.scale=1.3f;
			btOk.position=ccp(self.contentSize.width/2, 20/2);
		}else{
			btOk.position=ccp(self.contentSize.width/2, 20);
		}
	}
	
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

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	return YES;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	CCMenu* menu = (CCMenu*)[self getChildByTag:888];
	if (menu) {
		if ([menu ccTouchBegan:touch withEvent:event]) {
			[menu ccTouchEnded:touch withEvent:event];
		}
	}
}

-(void)updateRecord:(id)sender{
	CCMenuItemToggle *_obj = (CCMenuItemToggle*)sender;
	if (_obj.selectedIndex == 1) {
		bRecord = YES;
	}else if (_obj.selectedIndex == 0) {
		bRecord=NO;
	}
}

-(void)selectOK:(id)sender{
	if (recordTips && recordKey){
		[[GameConfigure shared] recordPlayerSetting:recordKey value:[NSNumber numberWithBool:bRecord]];
	}
	if(target!=nil && call!=nil){
		[target performSelector:call];
	}
	[self freeAlert];
}

-(void)selectN0:(id)sender{
	if(target!=nil && canel!=nil){
		[target performSelector:canel];
	}
	[self freeAlert];
}

-(void)freeAlert{
	[[AlertManager shared] remove];
}

@end
