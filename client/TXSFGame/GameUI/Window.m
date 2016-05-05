//
//  Window.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-15.
//  Copyright 2012 Soul. All rights reserved.
//

#import "Window.h"
#import "Game.h"
#import "TaskPanel.h"
#import "PhalanxPanel.h"
#import "WeaponPanel.h"
#import "RecruitPanel.h"
#import "GameLayer.h"
#import "GuanXing.h"
#import "GuanXingRoom.h"
#import "HammerPanel.h"
#import "SacrificePanel.h"
#import "UnionPanel.h"
#import "ItemSynthesize.h"
#import "SettingPanel.h"
#import "TimeBox.h"
#import "MapManager.h"
#import "RewardPanel.h"
#import "MailViewer.h"
#import "DailyPanel.h"
#import "Businessman.h"
#import "RankPanel.h"
#import "TaskManager.h"
#import "UnionEngrave.h"
#import "FishReward.h"
#import "GameStart.h"
#import "TaskTalk.h"
#import "FightManager.h"
#import "GameStart.h"
#import "PlayerPanel.h"
#import "Car.h"
#import "ExchangePanel.h"
#import "ActivityPanel.h"
#import "SocialityPanel.h"
#import "ChatPanel.h"
#import "UnionCat.h"
#import "SuccessLog.h"
#import "JewelPanel.h"
#import "JewelSet.h"
#import "JewelMine.h"
#import "JewelPolish.h"
#import "JewelRefine.h"
#import "CashCowManager.h"
#import "ArenaTeamPanel.h"
#import "AlertActivity.h"
#import "UnionPracticeConfigTeam.h"
#import "RoleCultivate.h"
#import "RoleUp.h"
#import "WindowComponent.h"
#import "Notice.h"
#import "DragonDonate.h"
#import "DragonExchange.h"
#import "DragonRank.h"
#import "DragonWorldMap.h"


@implementation Window

static Window *m_instance;


//------------------------------------------------------------------------------
// 控制两个windows 不能过快去打开
//------------------------------------------------------------------------------
static bool isEndOpenWindow = YES ;

+(BOOL)check_Operation_too_fast{
	return isEndOpenWindow ;
}

+(void)endOpenWindow{
	isEndOpenWindow = YES ;
}

+(void)beginOpenWindow{
	isEndOpenWindow = NO ;
	[NSTimer scheduledTimerWithTimeInterval:0.5f
									 target:[Window class]
								   selector:@selector(endOpenWindow)
								   userInfo:nil
									repeats:NO];
}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
+(void)startShowWindow{
	[[Intro share] hideCurrenTips];
	[[RoleManager shared].player stopMoveAndTask];
	[[TaskManager shared] stopTask];
	[[AlertManager shared] closeAlert];
}
//------------------------------------------------------------------------------

/*
 *检查
 * Window 能不能打开
 *
 */
+(BOOL)check_Open_condition{
	if ([TaskTalk isTalking])						return NO;
	if ([FightManager isFighting])					return NO;
	if ([[GameConfigure shared] isPlayerOnChapter])	return NO;
	return YES ;
}

//------------------------------------------------------------------------------

+(void)stopAll{
	if(m_instance){
		[m_instance removeFromParentAndCleanup:YES];
		m_instance = nil;
	}
	[NSTimer cancelPreviousPerformRequestsWithTarget:[Window class]];
}

-(void)dealloc{
	[super dealloc];
	CCLOG(@"Window dealloc");//TODO not dealloc...
}

+(void)cleanMemory{
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
	[CCLabelBMFont purgeCachedData];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	[[CCFileUtils sharedFileUtils] purgeCachedEntries];
}

+(BOOL)checkPlayerCanRun{
	if (m_instance != nil) {
		if (![m_instance checkCanTouchNpc]) {
			return NO;
		}
	}
	return YES ;
}

+(Window*)shared
{
	if (m_instance == nil) {
		m_instance = [Window node];
		isEndOpenWindow = YES ;
		[[Game shared] addChild:m_instance z:INT32_MAX - 10 tag:787878];
 	}
	return m_instance;
}
+(void)destroy
{
	if (m_instance) {
		[m_instance removeFromParentAndCleanup:true];
		m_instance = nil;
	}
	[Window cleanMemory];
}

-(void)addChild:(CCNode *)node z:(NSInteger)z tag:(NSInteger)tag{
	if(node.parent){
		
		return;
	}
	[super addChild:node z:z tag:tag];
}

-(void)onEnter
{
	[super onEnter];
}
-(void)onExit
{
	[super onExit];
}
-(int)showWindowByUnlock:(Unlock_object)_unlock{
	int tag = filterWindowTag(_unlock);
	if (tag > 0) {
		switch (tag) {
			case PANEL_RECRUIT:
				[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_Recruit];
				break;
			case PANEL_PHALANX:
				[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_Phalanx];
				break;
			case PANEL_HAMMER:
				[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_Hammer];
				break;
			case PANEL_WEAPON:
				[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_Weapon];
				break;
			case PANEL_FATE:
				[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_GuangXing];
				break;
			default:
				break;
		}
		
		return [self showWindow:tag];
	}
	return -1;
}

-(BOOL)isHasWindow{
	if (_children.count > 0) {
		CCNode * ____node;
		CCARRAY_FOREACH(_children, ____node) {
			if(____node!=NO){
				//TODO
				//CCLOG(@"have window:%d",____node.tag);
				return YES ;
			}
		}
	}
	//GMAE 嘎时候也当时WINDOW 在
	if ([GameStart isOpen]) return YES ;
	
	return NO;
}
//
//有窗口打开的时候就不做任务了，但是任务窗口除外
//
-(BOOL)checkCanRunTask{
	for (int i = PANEL_CHARACTER ; i < WINDOW_type_end; i++) {
		CCNode* ______node = [self getChildByTag:i];
		if (______node) {
			if (i == PANEL_TASK) {
				CCLOG(@"i == PANEL_TASK can!!!");
			}else{
				return NO;
			}
		}
	}
	if ([GameStart isOpen]) {
		return NO;
	}
	return YES;
}

-(BOOL)checkCanTouchNpc{
	
	if([Arena arenaIsOpen]){
		return NO;
	}
	
	if ([UnionPracticeConfigTeam isOpen]) {
		return NO;
	}
	
	if ([FightManager isFighting]) {
		return NO;
	}
	
	if (_children.count == 0) {
		return YES ;
	}
	
	for (int i = PANEL_CHARACTER ; i < WINDOW_type_end; i++) {
		CCNode* ______node = [self getChildByTag:i];
		if (______node) {
			return NO;
		}
	}
	
	
	return YES;
}

-(BOOL)isHasWindowByType:(WINDOW_TYPE)type{
	if([self getChildByTag:type]){
		return YES;
	}
	return NO;
}

#pragma mark
#pragma mark how to show window

-(int)showWindow:(WINDOW_TYPE)_type only:(BOOL)_only
{
	return [self try_to_show:_type monopolize:YES only:_only dictionary:nil];
}

-(int)showWindow:(WINDOW_TYPE)_type dictionary:(NSDictionary *)_dict
{	
	return [self try_to_show:_type monopolize:YES only:YES dictionary:_dict];
}

-(int)showWindow:(WINDOW_TYPE)_type
{
	return [self try_to_show:_type monopolize:YES only:YES dictionary:nil];
}

#pragma mark
#pragma mark how to remove

-(void)removeWindow:(WINDOW_TYPE)_type
{
	isEndOpenWindow = YES ;
	
	//[[TaskManager shared] resumeTask];
	[[TaskManager shared] checkStepStatusByCloseWindow];
	//
	//	[Window cleanMemory];
	[[Intro share] hideCurrenTips];
	
	[self removeWindowAndEffectWithType:_type];
	//end
	[ShowItem removeAllTips];
	
}

-(void)removeAllWindows{
	
	isEndOpenWindow = YES ;
	
	CCLOG(@"Window->removeAllWindows!!");
	[self removeAllChildrenWithCleanup:YES];
	
	if (![GameLayer shared].touchEnabled) {
		[GameLayer shared].touchEnabled = YES;
	}
	
	[Window cleanMemory];
	[ShowItem removeAllTips];
	
}

#pragma mark

-(int)try_to_show:(WINDOW_TYPE)_type monopolize:(BOOL)_lock only:(BOOL)_only dictionary:(NSDictionary *)_dict{
	CCLOG(@"Window->showWindow");
	//先停止玩家移动
	[[RoleManager shared].player stopMoveAndTask];
	[[TaskManager shared] stopTask];
	
	if (![Window check_Operation_too_fast]) {
		CCLOG(@"you are open too quick!");
		return -1;
	}
	
	//如果不可以打开窗口的话,不给显示
	if (![Window check_Open_condition]){
		return -1 ;
	}
	
	if ([self getChildByTag:_type]) {
		CCLOG(@"you can't open the same window!");
		return -1;
	}
	
	[Window beginOpenWindow];
	
	return [self showWindow:_type monopolize:_lock only:_only dictionary:_dict];
}

-(int)showWindow:(WINDOW_TYPE)_type monopolize:(BOOL)_lock only:(BOOL)_only dictionary:(NSDictionary *)_dict
{
	//
	//todo mark some handle for show window
	//
	[Window startShowWindow];
	
	//
	//lock player to move
	//
	if (_lock) {//锁定底下
		if ([GameLayer shared].touchEnabled) {
			[GameLayer shared].touchEnabled = NO ;
		}
	}
	else {//不锁定
		if (![GameLayer shared].touchEnabled) {
			[GameLayer shared].touchEnabled = YES ;
		}
	}
	
	//
	//clear up
	//
	if (_only) {
		[self removeAllChildrenWithCleanup:YES];
	}
	
	BOOL isShow = NO;
	switch (_type) {
			
		case PANEL_CHARACTER://显示人物属性
		{
			CCLOG(@"show character panel");
			
			PlayerPanel* _player = [PlayerPanel node];
			_player.windowType = PANEL_CHARACTER;
			[self addChild:_player z:11 tag:PANEL_CHARACTER];
			[[Intro share]hideCurrenTips];
			isShow= YES;
			
		}
			break;
			
		case PANEL_ITEMSYNTHESIZE://物品合成
		{
			ItemSynthesize *itemSynthesizePanel = [ItemSynthesize node];
			itemSynthesizePanel.windowType = _type;
			[self addChild:itemSynthesizePanel z:10 tag:_type];
			isShow= YES;
		}
			break;
			
		case PANEL_TASK://显示任务列表
        {
            TaskPanel *task = [TaskPanel node];
			task.windowType = _type;
            [self addChild:task z:10 tag:_type];
			isShow= YES;
        }
			break;
			
        case PANEL_PHALANX:// 显示阵型
        {
            PhalanxPanel *phalanx = [PhalanxPanel node];
			phalanx.windowType = _type;
            [self addChild:phalanx z:10 tag:_type];
			isShow= YES;
        }
            break;
			
		case PANEL_WEAPON:// 显示宝具(武器就是宝具)
        {			
			Weapon *weapon = [Weapon node];
			weapon.windowType = _type;
			[self addChild:weapon z:10 tag:_type];
			isShow = YES;
        }
            break;
			
		case PANEL_FATE:// 显示命格
        {
			GuanXing *guanxing = [GuanXing create];
			guanxing.windowType = _type;
			[self addChild:guanxing z:10 tag:_type];
			isShow= YES;
        }
            break;
			
		case PANEL_FATEROOM:// 显示命格殿
        {
			[GuanXingRoom create];
			isShow= YES;
        }
            break;
			
        case PANEL_RECRUIT:// 点将
        {
            RecruitPanel *recruit = [RecruitPanel node];
			recruit.windowType = _type;
            [self addChild:recruit z:10 tag:_type];
			isShow= YES;
        }
            break;
			
        case PANEL_SACRIFICE:// 祭天
        {
            SacrificePanel *sacrifice = [SacrificePanel node];
			sacrifice.windowType = _type;
            [self addChild:sacrifice z:10 tag:_type];
			isShow= YES;
        }
            break;
			
        case PANEL_UNION:
        {
			[UnionPanel start];
			isShow= YES;
        }
            break;
			
		case PANEL_HAMMER:
		{
			HammerPanel *hammer = [HammerPanel node];
			hammer.windowType = _type;
			[self addChild:hammer z:10 tag:_type];
			isShow= YES;
		}
			break;
			
		case PANEL_SETTING:
		{
			SettingPanel *setting = [SettingPanel node];
			setting.windowType = _type;
			[self addChild:setting z:10 tag:_type];
			isShow= YES;
		}
			break;
			
		case PANEL_DAILY:
		{
			DailyPanel *daily = [DailyPanel node];
			daily.windowType = _type;
			[self addChild:daily z:10 tag:_type];
			isShow= YES;
		}
			break;
			
		case PANEL_RANK:
		{
			RankPanel *rank = [RankPanel node];
			rank.windowType = _type;
			[self addChild:rank z:10 tag:_type];
			isShow= YES;
		}
			break;
			
		case PANEL_RANK_arena:
		{
			RankPanel *rank = [RankPanel node];
			rank.windowType = PANEL_RANK;
			rank.defaultType = RankType_arena;
			[self addChild:rank z:10 tag:PANEL_RANK];// 默认打开竞技场排行榜,tag一样
			isShow= YES;
		}
			break;
			
		case PANEL_BUSINESSMAN:
		{
			Businessman *businessman = [Businessman node];
			businessman.windowType = _type;
			[self addChild:businessman z:10 tag:_type];
			isShow= YES;
		}
			break;
			
        case PANEL_TIMEBOX://时光盒
        {
            TimeBox *timebox=[TimeBox node];
            [self addChild:timebox z:10 tag:PANEL_TIMEBOX];
			isShow= YES;
        }
			break;
			
		case PANEL_MAIL://邮件
        {
            MailViewer * mailViewer = [MailViewer node];
            [self addChild:mailViewer z:INT16_MAX tag:PANEL_MAIL];
			isShow= YES;
        }
			break;
			
		case PANEL_REWARD://奖励
        {
			RewardPanel * rewardPanel = [RewardPanel node];
			rewardPanel.windowType = _type;
            [self addChild:rewardPanel z:10 tag:_type];
			isShow= YES;
        }
			break;
			
		case PANEL_UNION_Engrave://同盟铭刻
        {
            UnionEngrave * unionEngrave = [UnionEngrave node];
			unionEngrave.windowType = _type;
            [self addChild:unionEngrave z:10 tag:_type];
			isShow= YES;
        }
			break;
			
		case PANEL_FISH_Box://南蛮宝箱
		{
			FishReward *reward = [FishReward node];
			reward.windowType = _type;
			[self addChild:reward z:10 tag:_type];
			isShow= YES;
		}
			break;
			
		case PANEL_CAR://打开坐骑
		{
			Car *car=[Car node];
			car.windowType = _type;
			[self addChild:car z:10 tag:_type];
			isShow= YES;
		}
			break;
			
		case PANEL_ARENA:
		{
			Arena *aren=[Arena node];
			[self addChild:aren z:1 tag:PANEL_ARENA];
			isShow=YES;
		}
			break;
			
		case PANEL_EXCHANGE:
		{
			ExchangePanel *exchange = [ExchangePanel node];
			exchange.windowType = _type;
            [self addChild:exchange z:10 tag:_type];
			isShow= YES;
		}
			break;
			
		case PANEL_ACTIVITY:
		{
			ActivityPanel *activity = [ActivityPanel node];
			activity.windowType = _type;
			[self addChild:activity z:10 tag:_type];
			isShow = YES;
		}
			break;
			
		case PANEL_FRIEND:
		{
			SocialityPanel *sociality = [SocialityPanel node];
			sociality.windowType = _type;
			[self addChild:sociality z:10 tag:_type];
			isShow = YES;
		}
			break;
			
		case PANEL_OTHER_PLAYER_INFO:
		{
			//其他角色面板
			CCLOG(@"PANEL_OTHER_PLAYER_INFO");
		}
			break;

		case PANEL_CHAT_BIG:{

			ChatPanel *chat=[ChatPanel node];
			[self addChild:chat z:10 tag:PANEL_CHAT_BIG];
			isShow=YES;
		}
			break;
			
		case PANEL_UNION_Cat:{
			UnionCat *cat=[UnionCat node];
			cat.windowType = _type;
			[self addChild:cat z:10 tag:_type];
			isShow=YES;
		}
			break;
			
		case PANEL_SUCCESS_LOG:{
			SuccessLog* _log = [SuccessLog node];
			[self addChild:_log z:10 tag:PANEL_SUCCESS_LOG];
			isShow=YES;
		}
			break;
			
		case PANEL_CASHCOW:{
			CashCowManager* cash = [CashCowManager node];
			cash.windowType = PANEL_CASHCOW;
			[self addChild:cash z:10 tag:PANEL_CASHCOW];
			isShow = YES;
		}
			break;
			
		case PANEL_EXCHANGE_ACTIVITY:{
			AlertActivity* alert = [AlertActivity node];
			alert.windowType = PANEL_EXCHANGE_ACTIVITY;
			[self addChild:alert z:10 tag:PANEL_EXCHANGE_ACTIVITY];
			isShow = YES;
		}
			break;
			
        case PANEL_ROLE_CULTIVATE:{
            /*
			 RoleCultivate *role_cultivate = [RoleCultivate node];
			 role_cultivate.windowType = PANEL_ROLE_CULTIVATE;
			 [self addChild:role_cultivate z:10  tag:PANEL_ROLE_CULTIVATE];
             */
		}
			break;
			
        case PANEL_ROLE_UP:{
			RoleUp *role_up = [RoleUp node];
            role_up.windowType = PANEL_ROLE_UP;
            [self addChild:role_up z:10  tag:PANEL_ROLE_UP];
		}
			break;
			
		case PANEL_TEAM_ARENA:{
			//ArenaTeamPanel *atp=[ArenaTeamPanel node];
			//[self addChild:atp z:10 tag:PANEL_TEAM_ARENA];
		}
			break;
			
		case PANEL_JEWEL:{
			JewelPanel* jewel = [JewelPanel node];
			jewel.windowType = _type;
			[self addChild:jewel z:10 tag:_type];
			isShow = YES;
		}
			break;
			
		case PANEL_JEWEL_set:{
			JewelSet* jewel = [JewelSet create:_dict];
			jewel.windowType = _type;
			[self addChild:jewel z:10 tag:_type];
			isShow = YES;
		}
			break;
			
		case PANEL_JEWEL_mine:{
			JewelMine* jewel = [JewelMine node];
			jewel.windowType = _type;
			[self addChild:jewel z:10 tag:_type];
			isShow = YES;
		}
			break;
			
		case PANEL_JEWEL_polish:{
			JewelPolish* jewel = [JewelPolish node];
			jewel.windowType = _type;
			[self addChild:jewel z:10 tag:_type];
			isShow = YES;
		}
			break;
			
		case PANEL_JEWEL_refine:{
			JewelRefine* jewel = [JewelRefine node];
			jewel.windowType = _type;
			[self addChild:jewel z:10 tag:_type];
			isShow = YES;
		}
			break;
		case PANEL_NOTICE:{
			Notice* notice = [Notice node];
			notice.windowType = _type;
			[self addChild:notice z:10 tag:_type];
			isShow = YES;
		}
			break;
        case PANEL_UNION_Dragon_Donate:{
			DragonDonate *donate=[DragonDonate node];
			donate.windowType = _type;
			[self addChild:donate z:10 tag:_type];
			isShow=YES;
		}
			break;
        case PANEL_UNION_Dragon_Exchange:{
			DragonExchange *exchange=[DragonExchange node];
			exchange.windowType = _type;
			[self addChild:exchange z:10 tag:_type];
			isShow=YES;
		}
			break;
        case PANEL_UNION_Dragon_Union_Rank:{
			DragonUnionRank *rank=[DragonUnionRank node];
			rank.windowType = _type;
			[self addChild:rank z:10 tag:_type];
			isShow=YES;
		}
			break;
        case PANEL_UNION_Dragon_World_Rank:{
			DragonWorldRank *rank=[DragonWorldRank node];
			rank.windowType = _type;
			[self addChild:rank z:10 tag:_type];
			isShow=YES;
		}
			break;
        case PANEL_UNION_Dragon_World_Map:{
			DragonWorldMap *dragonMap=[DragonWorldMap node];
			dragonMap.windowType = _type;
			[self addChild:dragonMap z:10 tag:_type];
			isShow=YES;
		}
			break;
		default:
			break;
	}
	
	if (isShow) {
		if (!iPhoneRuningOnGame()) {
			[self addWindowAndEffectWithType:_type];
		}
		return 1;
	}else{
		return -1;
	}
	
}

//fix chao
-(void)addWindowAndEffectWithType:(WINDOW_TYPE)_type{
	//////
	CCNode *window = [self getChildByTag:_type];
	
	if (window) {
		
		CGSize size = [[CCDirector sharedDirector] winSize];
		CCLayerColor *layer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0)];
		CCRenderTexture *inTexture = [CCRenderTexture renderTextureWithWidth:size.width height:size.height];
		inTexture.sprite.anchorPoint = ccp(0.5f,0.5f);
		inTexture.position = ccp(size.width/2, size.height/2);
		inTexture.anchorPoint = ccp(0.5f,0.5f);
		
		[inTexture begin];
		[window visit];
		[inTexture end];
		
		ccBlendFunc blend1 = {GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA};
		[inTexture.sprite setBlendFunc:blend1];
		[inTexture.sprite setOpacity:0];
		
		id fade = [CCFadeTo actionWithDuration:0.25f opacity:255];
		id call = [CCCallBlock actionWithBlock:^(void){
			[self removeChildByTag:PANEL_NONE+998  cleanup:YES];
			[window setVisible:YES];
		}];
		[inTexture.sprite runAction:[CCSequence actions:fade, call, nil]];
		
		/*
		 [inTexture.sprite runAction:[CCFadeTo actionWithDuration:0.25f opacity:255] ];
		 [self performSelector:@selector(addWindowBackCall:)
		 withObject:[NSNumber numberWithInt:_type]
		 afterDelay:0.5];
		 */
		
		[layer addChild:inTexture];
		[self addChild:layer z:PANEL_NONE+998  tag:PANEL_NONE+998];
		
		[window setVisible:NO];
		
	}
}

-(void)addWindowBackCall:(id)sender{
	CCLOG(@"Window->performSelector->addWindow");
	int addWindowTag = [sender intValue];
	CCNode *window = [self getChildByTag:addWindowTag];
	[window setVisible:YES];
	
	[self removeChildByTag:PANEL_NONE+998  cleanup:YES];
}

//fix chao
-(void)removeWindowAndEffectWithType:(WINDOW_TYPE)_type{
	
	if (iPhoneRuningOnGame()) {
		[self removeWindowBackCall:[NSNumber numberWithInt:_type]];
		return ;
	}
	
	CCNode *window = [self getChildByTag:_type];
	if (window) {
		
		CGSize size = [[CCDirector sharedDirector] winSize];
		CCLayerColor * layer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0)];
		
		// create the first render texture for inScene_
		CCRenderTexture *inTexture = [CCRenderTexture renderTextureWithWidth:size.width height:size.height];
		inTexture.sprite.anchorPoint= ccp(0.5f,0.5f);
		inTexture.position = ccp(size.width/2, size.height/2);
		inTexture.anchorPoint = ccp(0.5f,0.5f);
		// render inScene_ to its texturebuffer
		[inTexture begin];
		[window visit];
		[inTexture end];
		
		window.visible = NO;
		ccBlendFunc blend1 = {GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA}; // inScene_ will lay on background and will not be used with alpha
		// set blendfunctions
		[inTexture.sprite setBlendFunc:blend1];
		
		// initial opacity:
		[inTexture.sprite setOpacity:255];
		
		// run the blend action
		id fade = [CCFadeTo actionWithDuration:0.25f opacity:0];
		id call = [CCCallBlock actionWithBlock:^(void){
			[self removeChildByTag:PANEL_NONE+999  cleanup:YES];
		}];
		[inTexture.sprite runAction:[CCSequence actions:fade, call, nil]];
		
		// add render textures to the layer
		[layer addChild:inTexture];
		// add the layer (which contains our two rendertextures) to the scene
		[self addChild: layer z:PANEL_NONE+999 tag:PANEL_NONE+999];
		
		[self performSelector:@selector(removeWindowBackCall:)
				   withObject:[NSNumber numberWithInt:_type]
				   afterDelay:0.05f];
		
	}
}

-(void)removeWindowBackCall:(id)sender{
	
	int removeTag = [sender intValue];
	[self removeChildByTag:removeTag cleanup:YES];
	[self removeChildByTag:PANEL_NONE+999 cleanup:YES];
	
	
	if (![GameLayer shared].touchEnabled) {
		[GameLayer shared].touchEnabled = YES;
	}
	
	[[AlertManager shared] checkStatus];
	[Window cleanMemory];
	
}
//end


@end
