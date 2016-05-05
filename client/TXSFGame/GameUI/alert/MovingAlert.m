//
//  MovingAlert.m
//  TXSFGame
//
//  Created by shoujun huang on 13-1-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "MovingAlert.h"
#import "Config.h"
#import "Game.h"

//iphone for chenjunming

static MovingAlert *s_MovingAlert = nil;

@implementation MovingAlert
+(void)show{
	if (!s_MovingAlert) {
		s_MovingAlert = [MovingAlert node];
		[[Game shared] addChild:s_MovingAlert z:INT32_MAX-20 tag:-9876];
		CGSize size = [[CCDirector sharedDirector] winSize];
		
		if(iPhoneRuningOnGame()){
			s_MovingAlert.position= ccp(size.width/2, size.height/2+90);
		}else{
			s_MovingAlert.position= ccp(size.width/2, size.height/2+180);
		}
		
		s_MovingAlert.opacity = 0;
		id act1 = [CCDelayTime actionWithDuration:0.168];
		id act2 = [CCFadeTo actionWithDuration:0.888 opacity:255];
		[s_MovingAlert runAction:[CCSequence actions:act1,act2,nil]];
		
	}
}
+(void)remove{
	if (s_MovingAlert) {
		[[Game shared] removeChildByTag:-9876 cleanup:YES];
		s_MovingAlert = nil;
	}
}
-(void)onExit{
	[super onExit];
}
-(void)onEnter{
	[super onEnter];
	
	CCSprite *background = [CCSprite spriteWithFile:@"images/ui/alert/system_alert.png"];
	self.contentSize=background.contentSize;
	[self addChild:background z:0 tag:1001];
    
	if(iPhoneRuningOnGame()){
		background.position=ccp(background.contentSize.width/2, background.contentSize.height/2-25);
	}else{
		background.position=ccp(background.contentSize.width/2, background.contentSize.height/2-50);
	}
	
	//CCLabelTTF *label = [CCLabelTTF labelWithString:@"自动寻路中..." fontName:getCommonFontName(FONT_1) fontSize:iPhoneRuningOnGame()?15:30];
    CCLabelTTF *label = [CCLabelTTF labelWithString:NSLocalizedString(@"moving_alert_find",nil) fontName:getCommonFontName(FONT_1) fontSize:iPhoneRuningOnGame()?15:30];
	[background addChild:label z:1 tag:1002];
	label.color=ccc3(239, 192, 29);
	label.position=ccp(background.contentSize.width/2, background.contentSize.height/2);
	if(iPhoneRuningOnGame()){
		label.scale = 0.9;
	}
	
}
-(void)setOpacity:(GLubyte)opacity{
	[super setOpacity:opacity];
	CCSprite* n1 = (CCSprite*)[self getChildByTag:1001];
	if (n1) {
		n1.opacity = self.opacity;
		
		CCLabelTTF* n2 = (CCLabelTTF*)[n1 getChildByTag:1002];
		if (n2) {
			n2.opacity = self.opacity;
		}
		
	}
	
}
@end

