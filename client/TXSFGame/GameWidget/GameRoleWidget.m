//
//  GameRoleWidget.m
//  TXSFGame
//
//  Created by chao chen on 12-10-19.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "GameRoleWidget.h"
#import "Game.h"

@implementation GameRoleWidget

@synthesize size;

-(void)onEnter
{
	[super onEnter];
	
	////

	CGPoint pos = ccp(0,0);
	////
	CCSprite *backgroud = [CCSprite spriteWithFile:@"TXSF_GameRoleWidgetBack.png"];
	backgroud.position = pos;
	[self addChild:backgroud];
	
	size = backgroud.texture.contentSize;
	
	CCMenuItemImage *close_button = [CCMenuItemImage itemWithNormalImage:@"TXSF_CloseButton01.png" selectedImage:@"TXSF_CloseButton02.png" target:self selector:@selector(closeButtonTapped:)];
	close_button.anchorPoint = ccp(1,1);
	close_button.position = ccp(size.width/2,size.height/2);
	
	CCMenu *enterInUIMenu = [CCMenu menuWithItems:close_button,nil];
	enterInUIMenu.position = pos;
	[self addChild:enterInUIMenu];	
	
}

////左移一步
-(void)moveToLeftStep
{
    CGPoint pos = self.position;
    pos.x -= size.width/2;
    
    self.position = pos;
}

////右移一步
-(void)moveToRightStep
{
    CGPoint pos = self.position;
    pos.x += size.width/2;
    
    self.position = pos;
	
}

////关闭按钮函数
-(void)closeButtonTapped:(id)sender
{
    [[Game shared] widgetTapped:TXSF_GameRoleWidget];
}

@end
