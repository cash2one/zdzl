//
//  ActivityPanel.m
//  TXSFGame
//
//  Created by efun on 13-3-11.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "ActivityPanel.h"
#import "Config.h"
#import "CCPanelPage.h"
#import "ButtonGroup.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "CCNode+AddHelper.h"
#import "GameActivity.h"
#import "ActivityKey.h"
#import "ActivityTab.h"
#import "ActivityTabGroup.h"
#import "ActivityViewerContent.h"
#import "SuccessView.h"
#import "ActivityEDLogin.h"
#import "ActivityEDcheck.h"

//iphone for chenjunming

#define Win_close_bt_width	cFixedScale(44)
#define Win_close_bt_height	cFixedScale(40)

#define Activity_width	cFixedScale(565)
#define Activity_height	cFixedScale(474)

static float Activity_tab_background_x=	26;
static float Activity_tab_background_y=	19;

static float Activity_tab_background_width=	235;
static float Activity_tab_background_height	=490;

static float  Activity_background_x	=268;
static float  Activity_background_y=	19;

static float Activity_background_width	=580;
static float Activity_background_height	=490;


static inline NSArray* userdefinedActivity(){
	
	NSMutableDictionary* days = [NSMutableDictionary dictionary];
	[days setObject:[NSNumber numberWithInt:9999] forKey:@"id"];
	//[days setObject:[NSString stringWithFormat:@"每日成就"] forKey:@"name"];
    [days setObject:[NSString stringWithFormat:NSLocalizedString(@"activity_time_consummation",nil)] forKey:@"name"];
	[days setObject:[NSString stringWithFormat:@""] forKey:@"info"];
	
	NSMutableDictionary* ever = [NSMutableDictionary dictionary];
	[ever setObject:[NSNumber numberWithInt:10000] forKey:@"id"];
	//[ever setObject:[NSString stringWithFormat:@"永久成就"] forKey:@"name"];
    [ever setObject:[NSString stringWithFormat:NSLocalizedString(@"activity_forever_consummation",nil)] forKey:@"name"];
	[ever setObject:[NSString stringWithFormat:@""] forKey:@"info"];
	
	NSMutableDictionary* login = [NSMutableDictionary dictionary];
	[login setObject:[NSString stringWithFormat:NSLocalizedString(@"activity_perday_login",nil)] forKey:@"name"];
	[login setObject:[NSNumber numberWithInt:10001] forKey:@"id"];
	[login setObject:[NSString stringWithFormat:@""] forKey:@"info"];
	
	NSMutableDictionary* checkday = [NSMutableDictionary dictionary];
	[checkday setObject:[NSString stringWithFormat:NSLocalizedString(@"activity_perday_check",nil)] forKey:@"name"];
	[checkday setObject:[NSNumber numberWithInt:10002] forKey:@"id"];
	[checkday setObject:[NSString stringWithFormat:@""] forKey:@"info"];
	
	return [NSArray arrayWithObjects:login,checkday,days,ever,nil];
}

@implementation Frame

@synthesize boundColor;

-(void)draw{
	[super draw];
	glLineWidth(2.0f);
    ccDrawColor4B(boundColor.r, boundColor.g, boundColor.b, boundColor.a);
	ccDrawRect(CGPointZero, ccp(self.contentSize.width, self.contentSize.height));
}

@end

static ActivityPanel * activityPanel;

@implementation ActivityPanel

@synthesize tabsManager;

+(ActivityPanel*)shared{
	return activityPanel;
}

-(id)init{
	if ((self=[super init]) == nil) return nil;
	
	activityArray = [NSMutableArray array];
	[activityArray retain];
	
	selectRecord = -1 ;
	
	if (iPhoneRuningOnGame()) {
		Activity_tab_background_x=	9/2.0f+44;
		Activity_tab_background_y=	33/2.0f;
		
		Activity_tab_background_width=	270/2.0f;
		Activity_tab_background_height	=550/2.0f;
		
		Activity_background_x	=293/2.0f+44;
		Activity_background_y=	33/2.0f;
		
		Activity_background_width	=650/2.0f;
		Activity_background_height	=550/2.0f;
	}
	else{
		Activity_tab_background_x=	26;
		Activity_tab_background_y=	19;
		
		Activity_tab_background_width=	235;
		Activity_tab_background_height	=490;
		
		Activity_background_x	=268;
		Activity_background_y=	19;
		
		Activity_background_width	=580;
		Activity_background_height	=490;
	}
	return self;
}

-(void) setTouchEnabled:(BOOL)enabled{
	if( __touchEnabled != enabled ) {
		__touchEnabled = enabled;
		
		CCDirector *director = [CCDirector sharedDirector];
		if( enabled ){
			[[director touchDispatcher] addTargetedDelegate:self
												   priority:__touchPriority
											swallowsTouches:NO];
		}else {
			[[director touchDispatcher] removeDelegate:self];
		}
	}
}

-(void)onEnter
{
	[super onEnter];
	
	activityPanel = self;
	
	self.touchEnabled = YES;
	self.touchPriority = -500;
		
	float fwidth = Activity_tab_background_width ;
	float fheight = Activity_tab_background_height ;
	CGPoint pos = ccp(Activity_tab_background_x, Activity_tab_background_y);
	//左边黑框
	Frame* frame1 = [Frame layerWithColor:ccc4(0, 0, 0, 180)
									width:fwidth height:fheight];
	frame1.boundColor = ccc4(83, 57, 32, 255);
	frame1.position = pos;
	[self addChild:frame1 z:0];
	
	fwidth = Activity_background_width;
	fheight = Activity_background_height;
	pos = ccp(Activity_background_x, Activity_background_y);
	//右边黑框
	Frame* frame2 = [Frame layerWithColor:ccc4(0, 0, 0, 180)
									width:fwidth height:fheight];
	frame2.boundColor = ccc4(83, 57, 32, 255);
	frame2.position=pos;
	[self addChild:frame2 z:0];
	
	
	//--------
	if (iPhoneRuningOnGame()) {
		fwidth = Activity_tab_background_width + 15;
		fheight = Activity_tab_background_height-3.5f;
		pos = ccp(Activity_tab_background_x +5, Activity_tab_background_y+3);
	}else{
		fwidth = Activity_tab_background_width + 10;
		fheight = Activity_tab_background_height-5.0f;
		pos = ccp(Activity_tab_background_x + 10, Activity_tab_background_y+3);
	}
	tabsManager = [ActivityTabGroup initActivityTabGroup:fwidth height:fheight];
	[self addChild:tabsManager z:40];
	tabsManager.position = pos;
	
	
	NSMutableArray* tabArray = [NSMutableArray arrayWithArray:userdefinedActivity()];
	NSArray* list = [[GameActivity shared] getActivityByType:Activity_Type_general];
	if (list != nil) {
		[tabArray addObjectsFromArray:list];
	}
	
	[tabsManager addTabs:tabArray target:self call:@selector(doSelectMenu:)];
	
}

-(void)doSelectMenu:(id)sender
{
	CCLOG(@"doSelectMenu:");
	
	if (sender) {

		NSNumber* number = (NSNumber*)sender;
		int _value = [number intValue];
		
		if (_value == selectRecord) {
			CCLOG(@"you are have do much!");
			return ;
		}
		
		selectRecord = _value ;
		
		[self removeChildByTag:7865 cleanup:YES];
		

		
		if(_value==10001){
			ActivityEDLogin *aedl=[ActivityEDLogin node];
			aedl.position = ccp(Activity_background_x,
								   Activity_background_y);
			[self addChild:aedl z:1 tag:7865];
			return;
		}
		if(_value==10002){
			ActivityEDcheck *aedc=[ActivityEDcheck node];
			aedc.position = ccp(Activity_background_x,
								Activity_background_y);
			[self addChild:aedc z:1 tag:7865];
			return;
		}

		
		
		if (_value == 9999 || _value == 10000) {
			//每日日常 9999
			//永久成就 10000
			
			SuccessView* content = nil ;
			SuccessType __type = SuccessType_none;
			
			if (_value == 9999) {
				__type = SuccessType_day;
			}
			
			if (_value == 10000) {
				__type = SuccessType_ever;
			}
			
			for (CCNode* cnt in activityArray) {
				if ([cnt isKindOfClass:[SuccessView class]]) {
					content = (SuccessView*)cnt;
					break ;
				}
			}
			
			if (content != nil) {
				content.type = __type;
				[self addChild:content z:10 tag:7865];
			}else{
				content = [SuccessView viewWithDimension:Activity_background_width
												  height:Activity_tab_background_height];
				content.position = ccp(Activity_background_x,
									   Activity_background_y);
				content.type = __type;
				[self addChild:content z:10 tag:7865];
				[activityArray addObject:content];
			}
			
			return;
		}
		
		
		NSDictionary* activity = [[GameActivity shared] getActivity:Activity_Type_general activityId:_value];
		if (activity != nil) {
			
			int ___id = [[activity objectForKey:@"id"] intValue];
			
			ActivityViewerContent* content = nil ;
			for (CCNode* cnt in activityArray) {
				if ([cnt isKindOfClass:[ActivityViewerContent class]]) {
					ActivityViewerContent* activityTemp = (ActivityViewerContent*)cnt;
					if ( [activityTemp getActivityId] == ___id) {
						content = activityTemp ;
						break ;
					}
				}
			}
			
			if (content != nil) {
				[self addChild:content z:10 tag:7865];
			}else{
				content = [ActivityViewerContent create:activity];
				content.position = ccp(Activity_background_x + Activity_background_width/2,
									   Activity_background_y + Activity_background_height/2);
				//content.target = self;
				if (iPhoneRuningOnGame()) {
					content.scale=1.1f;
				}
				//content.call = @selector(closeWindow);
				[self addChild:content z:10 tag:7865];
				[activityArray addObject:content];
			}
			
			/*
			 NSString* aType = getFunctionType(activity);
			 int ___id = [[activity objectForKey:@"id"] intValue];
			 
			 if (aType != nil && [aType isEqualToString:FUNC_input]) {
			 
			 //输入框
			 ActivityKey* content = nil ;
			 for (CCNode* cnt in activityArray) {
			 if ([cnt isKindOfClass:[ActivityKey class]]) {
			 ActivityKey* activityTemp = (ActivityKey*)cnt;
			 if (activityTemp.aid == ___id) {
			 content = activityTemp ;
			 break ;
			 }
			 }
			 }
			 
			 if (content != nil) {
			 [self addChild:content z:10 tag:7865];
			 }else{
			 
			 content = [ActivityKey node];
			 [content loadData:activity];
			 
			 float __x = (Activity_background_width - 565)/2;
			 float __y = (Activity_background_height - 474)/2;
			 
			 content.position = ccp(Activity_background_x + __x,
			 Activity_background_y + __y);
			 [self addChild:content z:10 tag:7865];
			 [activityArray addObject:content];
			 }
			 
			 }else{
			 
			 ActivityViewerContent* content = nil ;
			 for (CCNode* cnt in activityArray) {
			 if ([cnt isKindOfClass:[ActivityViewerContent class]]) {
			 ActivityViewerContent* activityTemp = (ActivityViewerContent*)cnt;
			 if ( [activityTemp getActivityId] == ___id) {
			 content = activityTemp ;
			 break ;
			 }
			 }
			 }
			 
			 if (content != nil) {
			 [self addChild:content z:10 tag:7865];
			 }else{
			 content = [ActivityViewerContent create:activity];
			 content.position = ccp(Activity_background_x + Activity_background_width/2,
			 Activity_background_y+Activity_background_height/2);
			 content.target = self;
			 content.call = @selector(closeWindowTapped);
			 [self addChild:content z:10 tag:7865];
			 [activityArray addObject:content];
			 }
			 }
			 */
			
		}
		
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	ActivityViewerContent* content=(ActivityViewerContent*)[self getChildByTag:7865];
	if (content) {
		[ActivityViewerContent hideKeyboard:content];
	}
	return YES;
}

-(void)onExit
{
	activityPanel = nil;
	if (activityArray) {
		[activityArray removeAllObjects];
		[activityArray release];
		activityArray = nil;
	}
	
	[super onExit];
}

-(void)moveTop:(BOOL)isTop{
	
	if(isTop){
		id move = [CCMoveTo actionWithDuration:0.15 position:ccpAdd(self.position, ccp(0,50))];
		[self runAction:move];
	}else{
		id move = [CCMoveTo actionWithDuration:0.15 position:ccpAdd(self.position, ccp(0,-50))];
		[self runAction:move];
	}
	
}

@end