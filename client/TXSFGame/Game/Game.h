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
#import "SNSHelper.h"
#import "GameFilter.h"

@interface Game : CCScene<SNSHelperDelegate,UIAlertViewDelegate>{
	int map_count;
	int map_total;
	
	BOOL bStartGame;
	BOOL isTurnning;
	BOOL isInGameing;
	BOOL isCanBackToMap;
	BOOL isMustCheckLogin;
	
	//-----跳转回调
	id	trunTarget;
	SEL trunCall;
	//-----
	
}

@property(nonatomic,assign) BOOL bStartGame;
@property(nonatomic,assign) BOOL isTurnning;
@property(nonatomic,assign) BOOL isInGameing;
@property(nonatomic,assign) BOOL isCanBackToMap;

+(void)receiveMemoryWarning;
+(void)cleanMemory;
+(BOOL)checkDeviceTypeIsCanRun;
+(BOOL)checkUncompatibleDevice;

+(BOOL)iPhoneRuningOnGame;
+(void)isRetinaDisplay:(BOOL)isRD;
+(BOOL)supportRetinaDisplay;

////取game对象指针
+(Game*)shared;

+(void)resignActive;
+(void)enterBackground;
+(void)enterForeground;
+(void)becomeActive;
+(void)quitGame;
//+(void)restart;
+(void)reenterGame;

+(BOOL)checkIsInGameing;

+(void)setMapId:(int)_mid;

-(void)backToMap:(id)target call:(SEL)call;

-(void)trunToMap:(int)mid;
-(void)trunToMap:(int)mid target:(id)target call:(SEL)call;
-(void)doTrunToMap;

-(void)showAll;
-(void)hideOther:(CCNode*)node;

////控件触发
//-(void)widgetTapped:(WidgetID) widgetID;



@end
