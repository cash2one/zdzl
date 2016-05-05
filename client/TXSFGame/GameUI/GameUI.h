//
//  GameUI.h
//  TXSFGame
//
//  Created by chao chen on 12-11-13.
//  Copyright 2012 eGame. All rights reserved.
//

#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "MainMenu.h"

typedef enum
{
	GAMEUI_PART_LD = 1,//左下
	GAMEUI_PART_LU,//左上
	GAMEUI_PART_RU,//右上
	GAMEUI_PART_RD,//右下
	GAMEUI_PART_MAIL,//邮件
}GAMEUI_PART;
////头像区类
/*
 * add by Soul
 * ver:1.0
 */
@class GameUIRoleHead;
@class UpperRightMenu;
@class LowerLeftChat;
@class MailList;

typedef enum {
	GameUI_none = 0 ,
	GameUI_standard,
	GameUI_timebox,
	GameUI_minig,
}GameUI_TAG;

@interface GameUI : CCLayer
{
	//NSMutableDictionary *gameUIDict;////ui分区字典
    MainMenu				*m_part1;//右下角按钮层
	UpperRightMenu			*m_part2;//右上角按钮层
	LowerLeftChat			*m_part3;//左下角聊天层
	GameUIRoleHead			*m_part4;//左上角角色
	MailList				*m_part5;//邮件列表
	
	BOOL isShowUI;
	BOOL isShowOtherUI;
}
@property(nonatomic,readonly) BOOL isShowUI;
@property(nonatomic,readonly) BOOL isShowOtherUI;

+(GameUI*)shared;
+(void)stopAll;
+(BOOL)checkGameUI;
+(BOOL)isHasGameUI;

-(BOOL)isOpenMainMenu;
-(void)showMenuAlert:(MENU_TAG)_tag;//设置提示
-(void)addMenuItem:(MENU_TAG) _tag;//增加菜单
-(void)updateMapName;
-(void)updateStatus;

-(void)unlockDaily;
-(void)addTaskFunction;
-(void)addDailyFunction;

//--------------------------------
//
-(void)updateTaskStatus:(int)_taskId taskStep:(int)_step type:(int)_type;
//
//--------------------------------

-(void)updateTaskInfo;
-(void)showTaskControlAlert;

#if TaskManager_ver == 1
-(void)offTaskInfo;
-(void)onTaskInfo;
#endif

-(void)updatePlayerInfo;

-(void)removeUI;
-(void)displayUI;

//fix 
-(void)closeMainMenu;
-(void)unfoldMainMenu;

-(CGPoint)getTaskExecutePosition;

//todo soul 请在NPC聊天时执行
-(void)closeLowerLeftChat;
-(void)openLowerLeftChat;
//end

-(void)removeFunctionManager;

//end
-(void)partialRenewal:(GAMEUI_PART)_part display:(BOOL)_b;

-(BOOL)checkPartVisible:(GAMEUI_PART)_part;

-(void)updateMailCount;

-(void)openUI;
-(void)closeUI;

-(void)openOtherUI;
-(void)closeOtherUI;

-(void)closeSpecialSystem;
-(void)openSpecialSystem;
//
-(void)showButtonFireEffectWithTag:(int)tag;
-(void)hideButtonFireEffectWithTag:(int)tag;
@end