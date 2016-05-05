//
//  GameWidgetManager.m
//  TXSFGame
//
//  Created by chao chen on 12-10-24.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "GameWidgetManager.h"
#import "GamePackWidget.h"
#import "GameRoleWidget.h"


GameWidgetManager *s_GameWidgetManager;

@implementation GameWidgetManager

+(GameWidgetManager*)shared
{
    if (nil == s_GameWidgetManager)
    {
        s_GameWidgetManager = [GameWidgetManager node] ;
    }
    return s_GameWidgetManager;
}


-(void)onEnter
{
	[super onEnter];
	//widgetDictionary = [NSMutableDictionary dictionaryWithCapacity:5];
	packWidget_ = nil;
	roleWidget_ = nil;

}
-(void)onExit
{
	
	////
	[self removeChild:packWidget_ cleanup:YES];
	[self removeChild:roleWidget_ cleanup:YES];
	[roleWidget_ release];
	[packWidget_ release];
	roleWidget_ = nil;
	packWidget_ = nil;
	////
	[super onExit];
}

////控件触发
-(void)widgetTapped:(WidgetID) widgetID
{
	switch (widgetID) {
		case TXSF_GameRoleWidget:
		{
			[self roleWidgetTapped];
		}
			break;
		case TXSF_GamePackWidget:
		{
			[self packWidgetTapped];
		}
			break;
		default:
			break;
	}
}
////角色控件触发
-(void)roleWidgetTapped
{
	if ( roleWidget_ == nil)
	{
		CGSize size = [[CCDirector sharedDirector] winSize];
		CGPoint pos = ccp(size.width/2,size.height/2);
		roleWidget_ = [[GameRoleWidget alloc] init];
		roleWidget_.position = pos;
		
		[self addChild:roleWidget_ z:999];
		
		////
		if ( packWidget_ != nil) {
			[roleWidget_ moveToLeftStep];
			[packWidget_ moveToRightStep];
			//roleWidget_.anchorPoint = ccp(1,0.5);
			//packWidget_.anchorPoint = ccp(0,0.5);
		}
		
	}
	else
	{
		if (packWidget_ != nil)
		{
			[packWidget_ moveToLeftStep];		
			//packWidget_.anchorPoint = ccp(0.5,0.5);
		}
		[roleWidget_ removeFromParentAndCleanup:YES];
		[roleWidget_ release];
		roleWidget_ = nil;
	}	
}

////背包控件触发
-(void)packWidgetTapped
{
	if ( packWidget_ == nil)
	{
		CGSize size = [[CCDirector sharedDirector] winSize];
		CGPoint pos = ccp(size.width/2,size.height/2);
		
		packWidget_ = [[GamePackWidget alloc] init];
		packWidget_.position = pos;
		
		[self addChild:packWidget_ z:999];
		////
		if ( roleWidget_ != nil) {
			[roleWidget_ moveToLeftStep];
			[packWidget_ moveToRightStep];
			//roleWidget_.anchorPoint = ccp(1,0.5);
			//packWidget_.anchorPoint = ccp(0,0.5);
		}
		
	}
	else
	{
		if (roleWidget_ != nil)
		{
			[roleWidget_ moveToRightStep];			
			//roleWidget_.anchorPoint = ccp(0.5,0.5);
		}
		[packWidget_ removeFromParentAndCleanup:YES];
		[packWidget_ release];
		packWidget_ = nil;
	}
}
@end
