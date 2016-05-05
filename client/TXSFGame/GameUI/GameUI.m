//
//  GameUI.m
//  TXSFGame
//
//  Created by chao chen on 12-11-13.
//  Copyright 2012 eGame. All rights reserved.
//

#import "GameUI.h"
#import "GameUIRoleHead.h"

#import "MapManager.h"
#import "GameConfigure.h"
#import "Game.h"
#import "Config.h"
#import "TaskManager.h"
#import "UpperRightMenu.h"
#import "LowerLeftChat.h"
#import "GameDB.h"
#import "Window.h"
#import "TimeBox.h"
#import "GameConnection.h"
#import "MailList.h"
#import "TaskPattern.h"
#import "MiningManager.h"
#import "Arena.h"
#import "ActivityEDLogin.h"

#define PART1 1000
#define PART2 1001
#define PART3 1002
#define PART4 1003
#define PART5 1004
#define PART6 754768 //跳过章节

#pragma mark -
#pragma mark - GameUI
@implementation GameUI

@synthesize isShowUI;
@synthesize isShowOtherUI;

static GameUI * gameUI;

+(GameUI*)shared{
	if(!gameUI){
		gameUI = [GameUI node];
	}
	return gameUI;
}

+(void)stopAll{
	if(gameUI){
		[TaskPattern close];
		[gameUI removeUI];
		[gameUI removeFromParentAndCleanup:YES];
		gameUI = nil;
	}
}

+(BOOL)checkGameUI{
	if (gameUI) {
		return gameUI.visible;
	}
	return NO;
}
+(BOOL)isHasGameUI{
	if (gameUI) {
		return YES;
	}
	return NO;
}

-(void)dealloc{
	[super dealloc];
	CCLOG(@"GameUI dealloc");
}

-(id)init
{
    self = [super init];
    if (self) {
        //TODO
    }
    return self;
}
-(void)setVisible:(BOOL)visible{
	[super setVisible:visible];
	if(visible){
		if(m_part3){
			[m_part3 showInputTextField];
		}
	}else{
		if(m_part3){
			[m_part3 hideInputTextField];
		}
		
		if (m_part1) {
			[m_part1 closeMenu];
		}
		
	}
}

-(void)displayUI{
	
	//CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	//右下角菜单
	m_part1 = [MainMenu getInstance];
	[m_part1 setTag:PART1];
	[self addChild:m_part1];
	
	//右上角菜单
	m_part2 = [UpperRightMenu create];
	[self addChild:m_part2];
	[m_part2 setTag:PART2];
	[m_part2 updateStatus:[MapManager shared].mapType];
	// 邮件数目
	[m_part2 updateMailCount];
	
	//左下角聊天层
	m_part3=[LowerLeftChat node];
	[m_part3 setTag:PART3];
	[self addChild:m_part3];
	if ([[GameConfigure shared] isPlayerOnChapter]) {
		[m_part3 EventOpenChat:nil];
	}
	
	m_part4 = [GameUIRoleHead node];
	[m_part4 setTag:PART4];
	[self addChild:m_part4];
	
	//邮件列表
	m_part5 = [MailList layerWithColor:ccc4(0,0,0,0) width:60*12 height:60];
	m_part5.anchorPoint = ccp(0.0,0.0);
	[m_part5 setTag:PART5];
	[self addChild:m_part5 z:-10];
	// 显示邮件
	[m_part5 showMailList];
	
	m_part1.position = [self getPartPosition:PART1];
	m_part2.position = [self getPartPosition:PART2];
	m_part3.position = [self getPartPosition:PART3];
	m_part4.position = [self getPartPosition:PART4];
	m_part5.position = [self getPartPosition:PART5];
	
	if(!isShowUI){
		[m_part1 closeMenu];
	}
	
	//[MailList moveTop];
	
	//fix chao
	if ([[GameConfigure shared] isPlayerOnChapter] ) {
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];//右下
	}else{
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
	}
	if ([[GameConfigure shared] isPlayerOnOneOrChapter]) {
		[[LowerLeftChat share] EventOpenChat:nil];
	}
	//end
	//todo 检查
	[[TaskPattern shared] checkStatus];//检查重新打开任务按钮
	
	if ([[TaskManager shared] checkCanSkipChapter]) {
		
		//TODO 按钮跳过许张
		[self removeChildByTag:PART6 cleanup:YES];
		//桃园走道不显示了
		//if ([MapManager shared].mapId != 10) {
		
		CCSimpleButton* bt_skip = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_skip_1.png"
														  select:@"images/ui/button/bts_skip_2.png"
														  target:self
															call:@selector(skipChapter:)
														priority:-50];
		
		[self addChild:bt_skip z:10 tag:PART6];
		
		if (iPhoneRuningOnGame()) {
			bt_skip.scale=1.3f;
		}
		
		bt_skip.delayTime = 1.0f;
		//CGSize size = [CCDirector sharedDirector].winSize;
		bt_skip.position = [self getPartPosition:PART6];//ccp(size.width/2, cFixedScale(70));
		//bt_skip.position = ccp(cFixedScale(340), size.height - cFixedScale(35));
		//}
		
	}
	
}

-(void)removeUI{
	
	//[TaskPattern close];
	[TaskPattern display];
	
	[[Intro share]hideCurrenTips];
	
	[self removeChildByTag:PART6 cleanup:YES];
	
	if ([MapManager shared].mapType!=Map_Type_TimeBox) {
		[self removeAllChildrenWithCleanup:YES];
		m_part1 = nil;
		m_part2 = nil;
		m_part3 = nil;
		m_part4 = nil;
		m_part5 = nil;
	}else{
		for(int i=0;i<5;i++){
			[self removeChildByTag:PART1+i cleanup:true];
		}
		m_part1 = nil;
		m_part2 = nil;
		m_part3 = nil;
		m_part4 = nil;
		m_part5 = nil;
	}
	
	/*
	 if (m_part1) {
	 [m_part1 removeFromParentAndCleanup:true];
	 m_part1 = nil;
	 }
	 if (m_part2) {
	 [m_part2 removeFromParentAndCleanup:true];
	 m_part2 = nil;
	 }
	 if (m_part4) {
	 [m_part4 removeFromParentAndCleanup:true];
	 m_part4 = nil;
	 }
	 */
	
}

-(void)showButtonFireEffectWithTag:(int)tag{
    if (m_part1 && m_part1.visible==YES) {
        [m_part1 showFireEffectWithTag:tag];
    }
    if (m_part2 && m_part2.visible==YES) {
        [m_part2 showFireEffectWithTag:tag];
    }
}
-(void)hideButtonFireEffectWithTag:(int)tag{
    if (m_part1 && m_part1.visible==YES) {
        [m_part1 hideFireEffectWithTag:tag];
    }
    if (m_part2 && m_part2.visible==YES) {
        [m_part2 hideFireEffectWithTag:tag];
    }
}

//fix

-(CGPoint)getTaskExecutePosition{
	if (m_part2) {
		return m_part2.tracePt;
	}
	return ccp(0, 0);
}
-(void)closeMainMenu{
	if (m_part1) {
		[m_part1 closeMenu];
	}
}
-(void)unfoldMainMenu{
	if (m_part1) {
		[m_part1 unfoldMenu];
	}
}
-(void)openLowerLeftChat{
	if (m_part3) {
		[m_part3 EventOpenChat:nil];
	}
}
-(void)closeLowerLeftChat{
	if (m_part3) {
		[m_part3 EventCloseChat:nil];
	}
}
//end
-(void)onEnter
{
	[super onEnter];
	
	isShowUI = YES;
	isShowOtherUI = YES;
	
	//[self displayUI];
	////
	//gameUIDict = [[NSMutableDictionary alloc] init];
	
	[GameConnection addPost:ConnPost_updatePlayerInfo target:self call:@selector(updatePlayerInfo)];
	
}
-(void)onExit
{
	//	[gameUIDict release];
	//	gameUIDict = nil;
	[GameConnection removePostTarget:self];
	////
	[super onExit];
}
//==============================================================================
//fix chao
//更新UI的钱
-(void)updateMoneyWithYuanBao01:(NSInteger)value01 yuanBao02:(NSInteger)value02 yinBi:(NSInteger)value03{
	if (m_part4) {
		[m_part4 updateMoneyWithYuanBao01:value01 yuanBao02:value02 yinBi:value03];
	}
}

//end


//更新UI布局
-(void)updateStatus{
	/*
	 *
	 */
	
	[self removeChildByTag:PART6 cleanup:YES];
	int _type = [MapManager shared].mapType;
	
#if TaskManager_ver == 1
	[[GameUI shared]closeLowerLeftChat];
	if(_type==Map_Type_TimeBox){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[m_part2 updateStatus:[MapManager shared].mapType];
		[TaskPattern close];
	}
	if (_type == Map_Type_Fish) {
		if (m_part2) {
			[m_part2 updateStatus:[MapManager shared].mapType];
			[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
			[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];//右上
			[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
		}
		//????
		return ;
	}
	else if (_type == Map_Type_Mining) {
		[m_part2 updateStatus:[MapManager shared].mapType];
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[TaskPattern close];
	}
	else if (_type == Map_Type_Standard) {
		if (m_part2) {
			[m_part2 updateStatus:[MapManager shared].mapType];
		}
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
		
		[[TaskPattern shared] checkStatus];
	}
	else if (_type == Map_Type_Stage) {
		if (m_part2) {
			[m_part2 updateStatus:[MapManager shared].mapType];
			[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
			[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];//右上
		}
	}else if (_type == Map_Type_Abyss) {
		//TODO
		//fix chao
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
		[m_part2 updateStatus:[MapManager shared].mapType];
		[TaskPattern close];
		
	}else if(_type == Map_Type_Union){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
		[m_part2 updateStatus:[MapManager shared].mapType];
		[TaskPattern close];
	}else if(_type == Map_Type_WorldBoss){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];//右下
		
		[m_part2 updateStatus:[MapManager shared].mapType];
		
		[TaskPattern close];
		
		return ;
	}else if(_type == Map_Type_UnionBoss){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];//右下
		
		[m_part2 updateStatus:[MapManager shared].mapType];
		
		[TaskPattern close];
		
		return ;
	}else if(_type==Map_Type_SysPvp){
		//[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//左上
		//return;
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];
		[m_part2 updateStatus:[MapManager shared].mapType];
		return;
	}else if(_type == Map_Type_dragonReady){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_LD display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];
		return;
	}
	else if(_type == Map_Type_dragonFight){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_LD display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];
		return;
	}
#else
	[[GameUI shared]closeLowerLeftChat];
	
	[[TaskPattern shared] checkStatus];
	
	if(_type==Map_Type_TimeBox){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[m_part2 updateStatus:[MapManager shared].mapType];
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
	}else if (_type == Map_Type_Fish) {
		if (m_part2) {
			[m_part2 updateStatus:[MapManager shared].mapType];
			[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
			[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];//右上
			[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
		}
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
		return ;
	}else if (_type == Map_Type_Mining) {
		[m_part2 updateStatus:[MapManager shared].mapType];
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
	}else if (_type == Map_Type_Standard) {
		if (m_part2) {
			[m_part2 updateStatus:[MapManager shared].mapType];
		}
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
	}else if (_type == Map_Type_Stage) {
		if (m_part2) {
			[m_part2 updateStatus:[MapManager shared].mapType];
			[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
			[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];//右上
		}
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
	}else if (_type == Map_Type_Abyss) {
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
		[m_part2 updateStatus:[MapManager shared].mapType];
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
	}else if(_type == Map_Type_Union){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
		[m_part2 updateStatus:[MapManager shared].mapType];
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
	}else if(_type == Map_Type_WorldBoss){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];//右下
		[m_part2 updateStatus:[MapManager shared].mapType];
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
		return ;
	}else if(_type == Map_Type_UnionBoss){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];//右下
		[m_part2 updateStatus:[MapManager shared].mapType];
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
		return ;
	}else if(_type==Map_Type_SysPvp){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];
		[m_part2 updateStatus:[MapManager shared].mapType];
		if (m_part4) {
			[m_part4 updateStatus:[MapManager shared].mapType];
		}
		return;
	}else if(_type == Map_Type_dragonReady){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_LD display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];
		return;
	}
	else if(_type == Map_Type_dragonFight){
		[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_LD display:YES];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];
		return;
	}
#endif
	
	//fix chao
	//[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
	if ([[GameConfigure shared] isPlayerOnChapter] ) {
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];//右下
	}else{
		[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右下
	}
	if ([[GameConfigure shared] isPlayerOnOneOrChapter]) {
		[[LowerLeftChat share] EventOpenChat:nil];
	}
	//end
	if ([[TaskManager shared] checkCanSkipChapter]) {
		//TODO 按钮跳过许张
		CCSimpleButton* bt_skip = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_skip_1.png"
														  select:@"images/ui/button/bts_skip_2.png"
														  target:self
															call:@selector(skipChapter:)
														priority:-2];
		
		[self addChild:bt_skip z:10 tag:PART6];
		
		bt_skip.delayTime = 1.0f;
		bt_skip.position = [self getPartPosition:PART6];
		if (iPhoneRuningOnGame()) {
			bt_skip.scale=1.3f;
		}
		
	}else{
		[self removeChildByTag:PART6 cleanup:YES];
	}
}

-(void)skipChapter:(CCSimpleButton*)_sender{
	if (self.visible) {
		CCLOG(@"skip chapter");
		[[TaskManager shared] skipChapter];
	}
}

-(void)updatePlayerInfo
{
	NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
	int level = [[player objectForKey:@"level"] intValue];
	int coin1 = [[player objectForKey:@"coin1"] intValue];
	int coin2 = [[player objectForKey:@"coin2"] intValue];
	int coin3 = [[player objectForKey:@"coin3"] intValue];
	//updata info
	if (m_part4) {
		[m_part4 updateLevel:level];
		[m_part4 updateMoneyWithYuanBao01:coin2 yuanBao02:coin3 yinBi:coin1];
	}
	/*
	if (m_part2 != nil) {
		[m_part2 unlockCash];
	}
	 */
	//判断到初章经过后打开抽奖面板
	if(level==5){
        //TODO 闪烁
		//[ActivityEDLogin checkMaxhasLuckTime];
	}
}
-(BOOL)isOpenMainMenu{
    if (m_part1) {
        return [m_part1 OpenMenu];
    }
    return YES;
}

-(void)showMenuAlert:(MENU_TAG)_tag{
	//TODO 设置提示
	if (m_part1) {
		//		CCMenuItem *_object = [m_part1 getMenuItem:_tag];
		//		id action1 = [CCScaleTo actionWithDuration:0.05 scale:1.2];
		//		id action2 = [CCScaleTo actionWithDuration:0.05 scale:1.0];
		//		[_object runAction:[CCSequence actions:action1,action2,nil]];
    }
}
/*
 * _tag的取值范围是[1,10]
 * 对应 MainMenu 中的 MENU_TAG 定义
 */
-(void) addMenuItem:(MENU_TAG)__tag{
	if (m_part1) {
        [m_part1 addMenuItem:__tag Dir:0];
    }
}

-(void)unlockDaily{
	if (m_part2) {
		[m_part2 unlockDaily];
	}
}
-(void)addDailyFunction{
	CCLOG(@"addDailyFunction");
	if (m_part2) {
		[m_part2 unlockDailyFunction];
	}
}
-(void)addTaskFunction{
	CCLOG(@"addTaskFunction");
	if (m_part2) {
		[m_part2 unlockTask];
	}
}
/*
 *更新地图名字
 */
-(void) updateMapName
{
	if (m_part2) {
		int mapID = [[MapManager shared] mapId];
		//soul
		//NSDictionary *dictionary = [[GameConfigure shared] getMapInfoById:mapID];
		NSDictionary *dictionary = [[GameDB shared] getMapInfo:mapID];
		
		if (dictionary) {
			NSString *name = [dictionary objectForKey:@"name"];
			[m_part2 showMapName:name];
		}
	}
}

//TODO test task button
-(void)showTaskTips{
	CCLOG(@"------>showTaskTips");
#if TaskManager_ver == 1
	[[TaskPattern shared] checkTaskStep];
#endif
	
}

-(void)updateTaskStatus:(int)_taskId taskStep:(int)_step type:(int)_type{
	[[TaskPattern shared] updateStatus:_taskId taskStep:_step type:_type];
	if (_taskId == 0 && _step == 0 && _type == 0) {
		CCLOG(@"[TaskPattern shared] endPointOut");
		[[TaskPattern shared] endPointOut];
	}
}
//
//--------------------------------


-(void)updateTaskInfo{
	//TODO update Task tips
	CCLOG(@"updateTaskInfo");
}
-(void)showTaskControlAlert{
	CCLOG(@"showTaskControlAlert");
}

#if TaskManager_ver == 1
-(void)offTaskInfo{
	[TaskPattern close];
}
-(void)onTaskInfo{
	[[TaskPattern shared] show];
}
#endif

-(void)doTask:(id)sender{
	[[TaskManager shared] checkStepRuning];
}

-(void)partialRenewal:(GAMEUI_PART)_part display :(BOOL)_b
{
	if (_part == GAMEUI_PART_LD) {
		if (m_part3) {
			m_part3.visible = _b;
		}
	}else if (_part == GAMEUI_PART_LU) {
		if (m_part4) {
			m_part4.visible=_b;
		}
	}else if (_part == GAMEUI_PART_RU) {
		if (m_part2) {
			m_part2.visible=_b;
		}
	}else if (_part == GAMEUI_PART_RD) {
		if (m_part1) {
			m_part1.visible=_b;
		}
	}else if(_part==GAMEUI_PART_MAIL){
		if(m_part5){
			m_part5.visible=_b;
		}
	}
}

-(BOOL)checkPartVisible:(GAMEUI_PART)_part
{
	BOOL isResult = NO;
	if (_part == GAMEUI_PART_LD) {
		if (m_part3) {
			isResult = m_part3.visible;
		}
	}else if (_part == GAMEUI_PART_LU) {
		if (m_part4) {
			isResult = m_part4.visible;
		}
	}else if (_part == GAMEUI_PART_RU) {
		if (m_part2) {
			isResult = m_part2.visible;
		}
	}else if (_part == GAMEUI_PART_RD) {
		if (m_part1) {
			isResult = m_part1.visible;
		}
	}
	return isResult;
}

-(void)removeFunctionManager{
	[MiningManager stopAll];
}


-(void)updateMailCount{
	if(m_part2){
		[m_part2 updateMailCount];
	}
}

-(void)openUI{
	if(isShowUI==NO){
		isShowUI = YES;
		[[Intro share] showCurrenTips];
		[self changeUI];
	}
}
-(void)closeUI{
	if(isShowUI==YES){
		isShowUI = NO;
		[[Intro share]hideCurrenTips];
		[self changeUI];
	}
}

-(void)openOtherUI{
	isShowOtherUI = YES;
	if(m_part2){
		[m_part2 changeMapBtn];
	}
	if([TaskPattern isHasTaskPattern]){
		[[TaskPattern shared] changeUI];
	}
}

-(void)closeOtherUI{
	isShowOtherUI = NO;
	if(m_part2){
		[m_part2 changeMapBtn];
	}
	if([TaskPattern isHasTaskPattern]){
		[[TaskPattern shared] changeUI];
	}
}

-(void)changeUI{
	float actionTime = 0.25f;
	if(m_part1){
		[m_part1 stopAllActions];
		if([m_part1 OpenMenu]){
			[m_part1 closeMenu];
			id time = [CCDelayTime actionWithDuration:0.25f];
			id move = [CCMoveTo actionWithDuration:actionTime position:[self getPartPosition:PART1]];
			[m_part1 runAction:[CCSequence actions:time, move, nil]];
		}else{
			id move = [CCMoveTo actionWithDuration:actionTime position:[self getPartPosition:PART1]];
			[m_part1 runAction:[CCSequence actions:move, nil]];
		}
	}
	if(m_part2){
		[m_part2 changeUI];
	}
	if(m_part3){
		[m_part3 EventCloseChat:nil];
		[m_part3 stopAllActions];
		id move = [CCMoveTo actionWithDuration:actionTime position:[self getPartPosition:PART3]];
		[m_part3 runAction:[CCSequence actions:move, nil]];
	}
	if(m_part4){
		[m_part4 stopAllActions];
		id move = [CCMoveTo actionWithDuration:actionTime position:[self getPartPosition:PART4]];
		[m_part4 runAction:[CCSequence actions:move, nil]];
	}
	if(m_part5){
		[m_part5 stopAllActions];
		[m_part5 runAction:[CCMoveTo actionWithDuration:actionTime position:[self getPartPosition:PART5]]];
	}
	CCNode* ___node = [self getChildByTag:PART6];
	if (___node) {
		[___node stopAllActions];
		[___node runAction:[CCMoveTo actionWithDuration:actionTime position:[self getPartPosition:PART6]]];
	}
	
}

-(CGPoint)getPartPosition:(int)tag{
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	CGPoint position = CGPointZero;
	if(isShowUI){
		if(tag==PART4){
			position = ccp(0, winSize.height-cFixedScale(120));
		}
		if(tag==PART5){
			position = ccp(winSize.width/2, cFixedScale(160));
		}
		if (tag==PART6) {
			position = ccp(winSize.width/2, cFixedScale(70));
		}
	}else{
		if(tag==PART1){
			if (iPhoneRuningOnGame()) {
				position = ccp(cFixedScale(120),cFixedScale(-120));
			}else{
				position = ccp(cFixedScale(100),cFixedScale(-100));
			}
		}
		if(tag==PART2){
			//position = ccp(cFixedScale(100),cFixedScale(100));
		}
		if(tag==PART3){
			position = ccp(cFixedScale(-420),0);
		}
		if(tag==PART4){
			position = ccp(cFixedScale(-150), winSize.height+cFixedScale(50));
		}
		if(tag==PART5){
			position = ccp(winSize.width/2, cFixedScale(-60));
		}
		if (tag==PART6) {
			position = ccp(winSize.width/2, cFixedScale(-100));
		}
	}
	return position;
}

-(void)closeSpecialSystem{
	for (int i = GameUi_SpecialSystem_start_enum ; i < GameUi_SpecialSystem_end_enum ; i++) {
		CCNode* node_1 = [self getChildByTag:i];
		if (node_1 != nil) {
			node_1.visible = NO;
		}
	}
	[TimeBox visibleTimeBox:NO];
}

-(void)openSpecialSystem{
	for (int i = GameUi_SpecialSystem_start_enum ; i < GameUi_SpecialSystem_end_enum ; i++) {
		CCNode* node_1 = [self getChildByTag:i];
		if (node_1 != nil) {
			node_1.visible = YES;
		}
	}
	[TimeBox visibleTimeBox:YES];
}

@end
