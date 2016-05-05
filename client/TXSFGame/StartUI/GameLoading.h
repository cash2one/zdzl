//
//  GameLoading.h
//  TXSFGame
//
//  Created by TigerLeung on 12-12-13.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#define GAMELOADING_SHOW_LOADING @"GL_show_loading"

@interface GameLoading : CCLayerColor{
	float t_percent;
	bool p5isMove;
	NSArray *last3Frame;
	
	CCSprite *runSpwRoot;
	CCSprite *runSpw1;
	CCSprite *runSpw2;
	CCSprite *strSpw;
	
	BOOL isShowFight;
}

+(GameLoading*)share;
+(void)stopAll;
+(BOOL)isShowing;
+(void)isInGameing:(BOOL)isInGame;

+(void)show;
+(void)urgentHide;
+(void)hide;
+(void)delayHide;
+(void)freeMemory;

+(void)showFight:(NSString*)msg loading:(BOOL)loading;
+(void)showFight:(NSString*)msg target:(id)target call:(SEL)call loading:(BOOL)loading;

+(void)showMessage:(NSString*)msg loading:(BOOL)loading;
+(void)showMessage:(NSString*)msg target:(id)target call:(SEL)call loading:(BOOL)loading;

+(void)showError:(NSString*)error;

+(void)downloadPercent:(NSNumber*)percent;

-(void)showMessage:(NSString*)msg;
-(void)showPercent:(float)percent;
-(void)isShowPercent:(BOOL)isShow;

-(void)showFightLoadingStep1Target:(id)target call:(SEL)call;
-(void)showFightLoadingStep2Target:(id)target call:(SEL)call;

//-(void)showEffect:(NSString*)path target:(id)target call:(SEL)call;

//fix chao 换loading 背景
//-(void)changeBGWithFile:(NSString*)bgFile;
//end
@end
