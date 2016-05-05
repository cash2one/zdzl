//
//  Game.h
//  TXSFGame
//
//  Created by chao chen on 12-10-15.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "LowerLeftChat.h"
//#import "GameWidgetManager.h"

#define GameLayer_Fish_Button_Begin		80031
#define GameLayer_Fish_Button_Convert	80032

@interface GameLayer: CCLayerColor{
	CCLayer * content;
	
	BOOL isAction;
	
	BOOL selfIsCanTouch;
	float checkOpenTouchTime;
	
	float touch_distance;
	float end_touch_distance;
	BOOL isMultiTouch;
	int touchCount;
}

@property(nonatomic,assign) CCLayer * content;
@property(nonatomic,assign) BOOL isAction;

////取对象指针
+(GameLayer*)shared;
+(void)stopAll;
+(BOOL)isShowing;

-(void)showMap;
-(void)removeMap;

-(void)updatePlayerView;


////控件触发
//-(void)widgetTapped:(WidgetID) widgetID;

////设置视图中心
//-(void) setViewpointCenter:(CGPoint)position;
-(CGPoint)getContentPoint;
-(CGPoint)getPlayerViewPosition;
-(CGPoint)getPlayerViewPosition:(CGPoint)pt;
@end
