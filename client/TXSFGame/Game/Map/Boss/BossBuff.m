//
//  BossBuff.m
//  TXSFGame
//
//  Created by Soul on 13-5-13.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "BossBuff.h"
#import "CCSimpleButton.h"
#import "CCNode+AddHelper.h"

@implementation BossBuff

@synthesize target;
@synthesize call;

-(void)onEnter{
	[super onEnter];
	
	CCSimpleButton* bnt = [CCSimpleButton spriteWithFile:@"images/ui/worldboss/bt_battle1.png"
												  select:@"images/ui/worldboss/bt_battle2.png"];
	self.contentSize = bnt.contentSize;
	bnt.priority = -80;
	bnt.target = self;
	bnt.call = @selector(doBossBuffEvent:);
	[self Category_AddChildToCenter:bnt z:1];
	
}

-(void)onExit{
	[super onExit];
}

-(void)doBossBuffEvent:(CCSimpleButton*)sender{
	CCLOG(@"----------");
	if (target != nil && call != nil) {
		[target performSelector:call];
	}
}

@end
