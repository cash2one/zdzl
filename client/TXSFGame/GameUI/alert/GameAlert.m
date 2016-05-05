//
//  GameAlert.m
//  TXSFGame
//
//  Created by shoujun huang on 13-1-2.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "GameAlert.h"
#import "GameLayer.h"
#import "Window.h"
#import "Game.h"
#import "AlertManager.h"
#import "TaskTalk.h"

//iphone for chenjunming

@implementation GameAlert
@synthesize target;
@synthesize call;
@synthesize argument;
@synthesize father=_father;

-(void)show{
	//WHT ？？避免在任务对话的时候出现对话框
	//保护一下 有些时候不给弹出来
	BOOL isCanShow = YES ;
	if (self.parent)			isCanShow = NO;
	if ([TaskTalk isTalking])	isCanShow = NO;
	
	if (isCanShow == NO) {
		return ;
	}
	
	if (_father) {
		@try {
			[_father addChild:self z:INT32_MAX];
			if(iPhoneRuningOnGame()){
				self.position = ccp(_father.contentSize.width/2,_father.contentSize.height/2);
			}else{
				self.position = ccp(_father.contentSize.width/2,_father.contentSize.height/2);
			}
		}
		@catch (NSException *exception) {
			[self remove];
		}
	}else{
		//todo ???
		[[Game shared] addChild:self z:INT32_MAX];
		//[[Game shared] addChild:self z:INT32_MAX-10];
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		
		if(iPhoneRuningOnGame()){
			self.position = ccp(winSize.width/2, winSize.height/2+50);
		}else{
			self.position = ccp(winSize.width/2, winSize.height/2+100);
		}
		//end
		
		//[[AlertManager shared] alertEnter:self];
	}
}
-(void)onEnter{
	[super onEnter];
}
-(void)remove{
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
