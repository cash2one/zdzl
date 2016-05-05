//
//  UpperRightMenu.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-16.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameUI.h"
#import "Config.h"
#import "GameConfigure.h"
#import "CCLabelFX.h"
#import "MapManager.h"
#import "Game.h"
#import "TimeBox.h"
#import "DailyPanel.h"

#define ADJUST_GAP							10
#define TASK_TRACE_HEIGHT					120
#define RES_WIDTH							85
#define RES_HEIGHT							92
@class CCSimpleButton;

@interface UpperRightMenu : CCLayer {
	//end
	CGSize					mapNameRect;
	CCMenu					*m_Menu;
	CGPoint					tracePt; //任务追踪按钮位置
	CGPoint					taskPt; //任务按钮位置
	CGPoint					dailyPt;
	CGPoint					actPt;
	CGPoint					rewardPt;
}
+(id) create;
@property(nonatomic,assign)CGPoint tracePt;

-(void)showShowMapBtn:(bool)sShow;
-(void)showMapName:(bool)bShow;
-(void)menuCallbackBack: (id) sender;

-(void)showTaskBtn:(bool)bShow;//任务
-(void)showDailyBtn:(bool)bShow; //日常按钮
-(void)showActBtn:(bool)bShow; //活动按钮
-(void)showRewardBtn:(bool)bShow; //奖励按钮
-(void)showBackBtn:(bool)bShow;//返回世界的按钮
-(void)updateStatus:(Map_Type)_type;
-(void)showCashBtn:(bool)bShow; //显示摇钱树


-(void)unlockCash;
-(void)unlockDaily;
-(void)unlockDailyFunction;
-(void)unlockTask;

-(void)updateMailCount;

-(void)changeUI;
-(void)changeMapBtn;
//
-(void)showFireEffectWithTag:(int)tag;
-(void)hideFireEffectWithTag:(int)tag;

@end
