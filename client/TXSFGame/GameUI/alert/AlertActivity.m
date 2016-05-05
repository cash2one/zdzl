//
//  AlertActivity.m
//  TXSFGame
//
//  Created by TigerLeung on 13-4-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AlertActivity.h"
#import "Game.h"
#import "ActivityViewerContent.h"
#import "Config.h"
#import "TaskTalk.h"
#import "GameLayer.h"
#import "CCNode+AddHelper.h"
#import "StageTask.h"
#import "GameStart.h"
#import "FightManager.h"
#import "Window.h"
#import "Config.h"
#import "GameActivity.h"


@implementation AlertActivity
@synthesize activity;

-(void)setActivity:(NSDictionary *)_activity{
	if(activity) [activity release];
	activity = _activity;
	if(activity) [activity retain];
}

-(NSString*)getCaptionPath{
	return nil;
}

-(NSString*)getBackgroundPath{
	return @"images/ui/panel/activity-bg.png";
}

-(void)onEnter{
	[super onEnter];
	
	self.touchEnabled = YES ;
	self.touchPriority = -5 ;
	
	NSArray * lists = [[GameActivity shared] getActivityByType:Activity_Type_recharge];
	if([lists count]>0){
		NSDictionary * __activity = [lists objectAtIndex:0];
		if(__activity){
			[self setActivity:__activity];
			
			ActivityViewerContent * content = [ActivityViewerContent create:activity];
			content.target = self;
			content.call = @selector(handleCloseWindow);
			[self Category_AddChildToCenter:content];
			
			float ___x  = (self.contentSize.width - content.contentSize.width)/2 ;
			content.position = ccp(self.contentSize.width/2 + ___x,self.contentSize.height/2 + cFixedScale(25));
			
		}
	}
	
	[GameLayer shared].touchEnabled = NO;
}

-(void)onExit{
	[GameLayer shared].touchEnabled = YES;
	[super onExit];
}

-(CGPoint)getClosePosition
{
	if (iPhoneRuningOnGame()) {
		CGPoint pt = ccp(self.contentSize.width - _closeBnt.contentSize.width/2-ccpIphone4X(0)-2.0f,
						 self.contentSize.height-_closeBnt.contentSize.height/2-2.5f );
		
		CGSize size = [CCDirector sharedDirector].winSize;
		if (self.contentSize.width < size.width) {
			pt = ccp(self.contentSize.width - _closeBnt.contentSize.width/2-10.0f,
					 self.contentSize.height-_closeBnt.contentSize.height/2-6);
		}
		return pt;
	}else{
		return ccp(self.contentSize.width - cFixedScale(44),
				   self.contentSize.height - cFixedScale(42));
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	return YES;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	[self closeWindowAndOpenWindow];
}

-(void)closeWindowAndOpenWindow{
	[self closeWindow];
	[[Window shared] showWindow:PANEL_EXCHANGE];
}

-(void)handleCloseWindow{
	[self closeWindow];
	if (self.activity) {
		NSString * cmd = [ActivityViewerContent getFunctionType:activity];
		if (isEqualToKey(@"", cmd)) {
			[[Window shared] showWindow:PANEL_EXCHANGE];
		}
	}
}

-(void)dealloc{
	if(activity){
		[activity release];
		activity = nil;
	}
	[super dealloc];
}

@end
