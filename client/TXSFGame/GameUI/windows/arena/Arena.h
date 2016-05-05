//
//  Arena.h
//  TXSFGame
//
//  Created by Max on 13-1-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameMoney.h"
#import "GameConfigure.h"
#import "GameUI.h"
#import "StretchingImg.h"
#import "GameConnection.h"
#import "FightManager.h"
#import "TaskPattern.h"
#import "LowerLeftChat.h"
#import "CCPanel.h"
#import "AlertManager.h"
#import "RankPanel.h"




@interface Arena : CCLayer {
	int currenRank;
	int getPracticeTime;
	int arenaYB;
	int todayCanGetmoney;
	int todayCanGetPractice;
	int todayCanPlayTime;
	
	int canGetmoney;
	int canPractice;
	
	bool isToFigth;
	CCSprite *playerListBg;
	CCLabelTTF *labelRank;
	CCLabelTTF *labelgetPractice;
	CCLabelTTF *labelmoney;
	CCLabelTTF *labelPractice;
	CCLabelTTF *labelPlayTime;
	CCPanel *subPanel;
	CCLayerColor *content;
	GameMoney *coin1spr;
	GameMoney *coin2spr;
	GameMoney *coin3spr;
	CCSprite *rewardBg;
	
	CCSprite *label3;
	CCSprite *label4;
	CCSprite *label5;
	
	CCSprite *label6;
	CCSprite *label7;
    //
    BOOL isSend;
}
+(void)enterArena;
/*
+(void)quitArena;
 */
+(Arena*)share;
+(void)didFigth;
+(BOOL)arenaIsOpen;

@end
