//
//  Alert.m
//  TXSFGame
//
//  Created by shoujun huang on 13-1-2.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "Alert.h"
#import "GameLayer.h"
#import "Window.h"
#import "AlertManager.h"

@implementation Alert
@synthesize target;
@synthesize call;
@synthesize argument;

-(void)show{
	[[Window getWindow] addChild:self z:INT32_MAX];
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	self.position = ccp(winSize.width/2, winSize.height/2+100);
}
-(void)onEnter{
	[super onEnter];
	
}
/*
-(void)showAlert:(CCNode *)_father target:(id)_target call:(SEL)_call arg:(id)_arg{
	self.target=_target;
	self.argument=_arg;
	self.call=_call;
	[_father addChild:self z:INT16_MAX];
	self.scale=0;
	self.position=ccp(_father.contentSize.width/2, _father.contentSize.height/2 + 100);
	id act1 = [CCScaleTo actionWithDuration:0.05 scale:1.2];
	id act2 = [CCScaleTo actionWithDuration:0.02 scale:1.0];
	[self runAction:[CCSequence actions:act1,act2,nil]];
}
-(void)showAlert:(CCNode *)_father target:(id)_target call:(SEL)_call arg:(id)_arg delay:(float)_delay{
	self.target=_target;
	self.argument=_arg;
	self.call=_call;
	[_father addChild:self z:INT16_MAX];
	self.scale=0;
	self.position=ccp(_father.contentSize.width/2, _father.contentSize.height/2);
	id act1 = [CCScaleTo actionWithDuration:0.05 scale:1.2];
	id act2 = [CCScaleTo actionWithDuration:0.02 scale:1.0];
	id act3 = [CCDelayTime actionWithDuration:_delay];
	id act4 = [CCCallFunc actionWithTarget:self selector:@selector(remove)];
	[self runAction:[CCSequence actions:act1,act2,act3,act4,nil]];
}
*/

-(void)remove{
	if (target && call) {
		if (argument) {
			[target performSelector:call withObject:argument];
		}else {
			[target performSelector:call];
		}
	}
	[[AlertManager shared] remove];
}
-(void)onExit{
	[super onExit];
	if (argument) {
		[argument release];
		argument=nil;
	}
}
@end
