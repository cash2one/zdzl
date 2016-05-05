//
//  GameTouchPoint.m
//  TXSFGame
//
//  Created by Max on 13-2-21.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "GameTouchPoint.h"
#import "Game.h"
#import "AnimationViewer.h"
#import "MapManager.h"
#import "Window.h"
#import "FightManager.h"
#import "TaskTalk.h"
#import "GameStart.h"
#import "Arena.h"
#import "MiningManager.h"

@implementation GameTouchPoint

static GameTouchPoint* touch;


+(GameTouchPoint *)instance{
	return touch;
}

+(void)start{
	if(!touch){
		touch=[GameTouchPoint node];
		[[Game shared]addChild:touch z:INT32_MAX];
	}
}

+(void)stopAll{
	if(touch){
		[touch removeFromParentAndCleanup:YES];
		touch = nil;
	}
}

-(void)onEnter{
	[super onEnter];
	[[[CCDirector sharedDirector]touchDispatcher]addTargetedDelegate:self priority:INT32_MIN swallowsTouches:NO];
	//self.touchEnabled = YES;
	//self.touchMode = kCCTouchesAllAtOnce;
	//self.touchPriority = INT32_MIN;
	pointActAr=[[NSArray alloc]initWithArray:[AnimationViewer loadFileByFileFullPath:@"images/animations/uicursorwait/" name:@"%d.png"]];
	
}
-(void)onExit{
	[[[CCDirector sharedDirector]touchDispatcher ]removeDelegate:self];
	[pointActAr release];
	pointActAr=nil;
	touch=nil;
	[super onExit];
}
-(void)dealloc{
	[super dealloc];
}

/*
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	
    bool isDisplay=false;
    if([MapManager shared].mapId==0){
        isDisplay=true;
    }
    if([[Window shared]isHasWindow]){
        isDisplay=true;
    }
    if([FightManager isFighting]){
        isDisplay=true;
    }
	
	if([Arena arenaIsOpen]){
		isDisplay=true;
	}
	
	if([TaskTalk isTalking]){
		isDisplay=true;
	}
	if ([GameStart isOpen]) {
		isDisplay=true;
	}
	
    if(!isDisplay){
        return NO;
    }
    CGPoint touchLocation = [touch locationInView:touch.view];
	CGPoint gltouch=[[CCDirector sharedDirector]convertToGL:touchLocation];
	
	AnimationViewer *mact=[AnimationViewer node];
	[mact showAnimationByPathOne:@"images/animations/uicursorwait/%d.png"];
	[mact setPosition:ccp(gltouch.x, gltouch.y)];
	if(iPhoneRuningOnGame()){
		mact.scale = 1.5f;
	}
	[[Game shared] addChild:mact z:INT32_MAX];
	
	return NO;
}
*/

-(void)checkShowPoint:(UITouch*)touch{
	bool isDisplay=false;
    if([MapManager shared].mapId==0){
        isDisplay=true;
    }
    if([[Window shared]isHasWindow]){
        isDisplay=true;
    }
    if([FightManager isFighting]){
        isDisplay=true;
    }
	
	if([Arena arenaIsOpen]){
		isDisplay=true;
	}
	
	if([TaskTalk isTalking]){
		isDisplay=true;
	}
	if ([GameStart isOpen]) {
		isDisplay=true;
	}
	
	// 采矿读条，有点击效果
	if ([MiningManager isShowLoading]) {
		isDisplay=true;
	}
	
    if(!isDisplay){
        return;
    }
	
    CGPoint touchLocation = [touch locationInView:touch.view];
	CGPoint gltouch=[[CCDirector sharedDirector]convertToGL:touchLocation];
	
	AnimationViewer *mact=[AnimationViewer node];
	//[mact playAnimation:pointActAr delay:0.1 call:nil];
	[mact playAnimationAndClean:pointActAr];
	[mact setPosition:ccp(gltouch.x, gltouch.y)];
	if(iPhoneRuningOnGame()){
		mact.scale = 1.5f;
	}
	[[Game shared] addChild:mact z:INT32_MAX];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	[self checkShowPoint:touch];
	return NO;
}




#pragma mark -
/*
-(void)ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
	
}
-(void)ccTouchesMoved:(NSSet*)touches withEvent:(UIEvent*)event{
	
}
-(void)ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent*)event{
	if([touches count]==1){
		[self checkShowPoint:[touches anyObject]];
	}else{
		
	}
}
*/
@end
