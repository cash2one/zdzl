//
//  SuccessLog.m
//  TXSFGame
//
//  Created by Soul on 13-4-19.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "SuccessLog.h"
#import "Config.h"
#import "CCNode+AddHelper.h"
#import "ActivityPanel.h"
#import "Window.h"
#import "CCPanel.h"
#import "SuccessView.h"

static NSArray* logArray = nil;

static float  SuccessLog_close_width = 44;
static float  SuccessLog_close_height = 40;

static float  SuccessLog_frame_x = 26;
static float  SuccessLog_frame_y = 19;

static float  SuccessLog_frame_width = 820;
static float  SuccessLog_frame_height = 485;


@implementation SuccessLog

+(void)addSuccessLog:(NSArray *)_array{
	[SuccessLog freeSuccessLog];
	if (_array == nil) {
		return ;
	}
	logArray = [NSArray arrayWithArray:_array];
	[logArray retain];
}

+(void)freeSuccessLog{
	if (logArray != nil) {
		[logArray release];
		logArray = nil ;
	}
}

-(void)onEnter{
	[super onEnter];
	
	if (iPhoneRuningOnGame()) {
		SuccessLog_close_width = 44;
		SuccessLog_close_height = 40;
		
		SuccessLog_frame_x = 26/2.0f;
		SuccessLog_frame_y = 19/2.0f;

		SuccessLog_frame_width=820/2.0f;
		SuccessLog_frame_height=485/2.0f;
	}else{
		SuccessLog_close_width = 44;
		SuccessLog_close_height = 40;
		
		SuccessLog_frame_x = 26;
		SuccessLog_frame_y = 19;
		
		SuccessLog_frame_width=820;
		SuccessLog_frame_height=485;
	}
	
	CGSize winSize = [CCDirector sharedDirector].winSize;
	
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/p5.png"];;
	self.contentSize = bg.contentSize;
	self.position = ccp(winSize.width/2-self.contentSize.width/2,
						winSize.height/2-self.contentSize.height/2);
	[self Category_AddChildToCenter:bg z:-1];
	
	
    CCSprite *title = [CCSprite spriteWithFile:@"images/ui/success/log_5.png"];
	title.position = ccp(self.contentSize.width/2.0f, self.contentSize.height-cFixedScale(8));
	[self addChild:title z:1];
    
    NSArray *closeBtns = getBtnSpriteForScale(@"images/ui/button/bt_close.png",1.1f);
    CCMenuItemImage* closeMenuItem = [CCMenuItemImage itemWithNormalSprite:[closeBtns objectAtIndex:0]
															selectedSprite:[closeBtns objectAtIndex:1]
															disabledSprite:nil
																	target:self
																  selector:@selector(closeWindowTapped)];
	
	closeMenuItem.position = ccp(self.contentSize.width-cFixedScale(SuccessLog_close_width),
								 self.contentSize.height-cFixedScale(SuccessLog_close_height));
    CCMenu *closeMenu = [CCMenu menuWithItems:closeMenuItem, nil];
    closeMenu.position = CGPointZero;
	[self addChild:closeMenu z:1];
	
	Frame* frame = [Frame layerWithColor:ccc4(0, 0, 0, 180)
								   width:SuccessLog_frame_width height:SuccessLog_frame_height];
	frame.boundColor = ccc4(83, 57, 32, 255);
	frame.position = ccp(SuccessLog_frame_x,SuccessLog_frame_y);
	[self addChild:frame z:1];
	
	[self showLogs];
}

-(void)showLogs{
	[self removeChildByTag:8754 cleanup:YES];
	
	CCLayer *content=[CCLayer node];
	
	if (logArray != nil && logArray.count > 0) {
		for(NSString *str in logArray){
			CCLOG(@"%@",str);
			SuccessComponent *cmp = [SuccessComponent create:str type:SuccessComponentType_log];
			[content addChild:cmp];
		}
		
		[content successLinearLayout:10];
		
		float pWidth = content.contentSize.width;
		float pheight = SuccessLog_frame_height - cFixedScale(20);
		float px = SuccessLog_frame_x + cFixedScale(14);
		float py = SuccessLog_frame_y + cFixedScale(10);
		
		CCPanel* panel = [CCPanel panelWithContent:content
										  viewSize:CGSizeMake(pWidth,pheight)];
		
		[self addChild:panel z:5 tag:8754];
		[panel setPosition:ccp(px, py)];
		[panel showScrollBar:@"images/ui/common/scroll3.png"];
		[panel updateContentToTopAndSetAligning:AligningType_top];
	}
}


-(void)closeWindowTapped{
	[[Window shared] removeWindow:PANEL_SUCCESS_LOG];
}

-(void)onExit{
	[SuccessLog freeSuccessLog];
	[super onExit];
}

@end
