//
//  intro.h
//  TXSFGame
//
//  Created by Max on 13-1-26.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameDB.h"
#import "GameConnection.h"
#import "Config.h"
#import "Game.h"
#import "GameConfigure.h"
#import "AnimationViewer.h"

typedef enum
{
	INTRO_NOTHING = 0,//点击开始寻路
	INTRO_START_Move = 1,//点击开始寻路
	INTRO_OPEN_Recruit=2,//打开点将界面
	INTRO_Recruit_Step_1=3,//点击招募关平
	INTRO_CLOSE_Recruit=4,//点击关闭
	
	INTRO_OPEN_Phalanx=5,//打开阵型界面
	INTRO_Phalanx_Step_1=6,//点击选择关平
	INTRO_Phalanx_Step_2=7,//拖动到这里
	INTRO_CLOSE_Phalanx=8,//点击关闭
	
	INTRO_OPEN_Hammer=9,//打开强化界面
	INTRO_Hammer_Step_1=10,//点击选择
	INTRO_Hammer_Step_2=11,//拖动到这里
	INTRO_Hammer_Step_3=12,//点击这里
	//INTRO_CLOSE_Hammer=13,//点击关闭
	
	INTRO_ENTER_Mining=13,//点击进入采矿
	INTRO_Mining_Step_1=14,//点击这里
	INTRO_Mining_Step_2=15,//点击这里
	//INTRO_CLOSE_Mining=17,//点击返回
	
	INTRO_OPEN_Weapon=16,//打开宝具界面
	INTRO_Weapon_Step_1=17,//点击这里
	//INTRO_CLOSE_Weapon=18,//点击关闭
	
	INTRO_OPEN_GuangXing=18,//打开观星界面
	INTRO_GuangXing_Step_1=19,//点击这里
	INTRO_GuangXing_Step_2=20,//拖动到这里
	
	INTRO_OPEN_GuangXingRoom=21,//点击前往观星
	INTRO_GuangXingRoom_Step_1=22,//点击这里
	INTRO_GuangXingRoom_Step_2=23,//点击这里
	//INTRO_CLOSE_GuangXingRoom=27,//点击关闭
	
	INTRO_OPEN_TimeBox=24,//打开时光盒
	INTRO_TimeBox_Step_1=25,//点击这里
	
	INTRO_OPEN_MMission=26,//进入悬赏任务
	INTRO_MMission_Step_1=27,//点击这里
	
}IntroStep;

@interface Intro : CCLayer {
	int postStep;
	//int currenStep;
	CCNode *currenTager;
	bool isInto;
	bool isForce;
	bool isIntoNode;
	int dir;
	int type;
	int isLogo;
	CGSize size;
	CGPoint point;
	CGPoint anpoint;
	NSValue *dropPos;
	NSString *content;
	NSTimer *checkTimer;
	CCSprite *tips;

}

+(Intro*)share;
+(void)stopAll;

+(void)resetCurrenStep;
+(IntroStep)getCurrenStep;

-(void)runIntroUnLockTask:(Unlock_object)uno;
-(void)runIntroTask:(IntroStep)_step;
-(void)runIntroTager:(CCNode*)node step:(int)_step;
-(void)runIntroInTager:(CCNode*)node step:(int)_step;

-(void)runBackIntro;

-(void)removeInCurrenTipsAndNextStep:(int)step;
-(void)removeCurrenTipsAndNextStep:(int)step;
//-(void)stopAll;
-(void)showCurrenTips;
-(void)hideCurrenTips;
+(BOOL)isIntroOpen;
@end
