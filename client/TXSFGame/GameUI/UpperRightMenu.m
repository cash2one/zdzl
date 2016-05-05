//
//  UpperRightMenu.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-16.
//  Copyright 2012 eGame. All rights reserved.
//

#import "UpperRightMenu.h"
#import "StageManager.h"
#import "Window.h"
#import "TaskManager.h"
#import "GameDB.h"
#import "GameConfigure.h"
#import "WorldMap.h"
#import "TaskManager.h"
#import "Task.h"
#import "AbyssManager.h"
#import "TaskPattern.h"
#import "CCSimpleButton.h"
#import "UnionManager.h"
#import "MiningManager.h"
#import "FightManager.h"
#import "GameUI.h"
#import "GameMail.h"
#import "GameSoundManager.h"
#import "GameStart.h"
#import "CashCowManager.h"

@implementation UpperRightMenu

@synthesize tracePt;

+(id)create
{
	return [UpperRightMenu node];
}
-(void) onEnter
{
	[super onEnter];
	//fix chao
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	mapNameRect = CGSizeMake(0,0);
	CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage:@"images/ui/button/bt_jumpmap.png"];
	mapNameRect = [tex contentSizeInPixels];
	mapNameRect.width = cFixedScale(mapNameRect.width);
	mapNameRect.height = cFixedScale(mapNameRect.height);
	
	//add menu
	m_Menu = [CCMenu node];
	[m_Menu setContentSize:winSize];
	[m_Menu setIgnoreAnchorPointForPosition:true];
	[m_Menu setPosition:ccp(0, 0)];
	[self addChild:m_Menu];
	//end
	
//	tracePt = ccp(winSize.width - ADJUST_GAP , winSize.height - mapNameRect.height - ADJUST_GAP);
//	taskPt = ccp(winSize.width - RES_WIDTH/2 - ADJUST_GAP ,winSize.height - mapNameRect.height - ADJUST_GAP-TASK_TRACE_HEIGHT - RES_HEIGHT/2 - ADJUST_GAP*2);
//	
//	dailyPt = ccp(winSize.width - mapNameRect.width , winSize.height);
//	actPt = ccp(dailyPt.x - RES_WIDTH , dailyPt.y);
//	rewardPt = ccp(actPt.x - RES_WIDTH , actPt.y);
	
}
-(void) onExit
{
	[super onExit];
}



-(void) menuCallbackBack: (id) sender
{
	
	[[GameSoundManager shared] click];
	
	if(!self.visible || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] || [GameStart isOpen] ){
		return;
	}
	CCNode *node = (CCNode*)sender;
	if ([node tag] == BT_SHOW_MAP_TAG) {
		if([[GameConfigure shared] isPlayerOnChapter]) return;
		int mid = [MapManager shared].mapId;
		if ([WorldMap checkShowWorldMap:mid now:mid]) {//在章节地图的时候才能打开世界地图
			[[RoleManager shared].player stopMoveAndTask];
			[WorldMap show];
		}else{
			CCLOG(@"not in chapter map");
		}
		CCLOG(@"handle BT_SHOW_MAP_TAG");
	}else if ([node tag] == BT_TASK_TRACE_TAG) {
		CCLOG(@"handle BT_TASK_TRACE_TAG");
		[[TaskManager shared] executeTask];
	}else if ([node tag] == BT_TASK_TAG) {
		[[Window shared] showWindow:PANEL_TASK];
		CCLOG(@"handle BT_TASK_TAG");
	}else if ([node tag] == BT_DAILY_TAG) {
		CCLOG(@"handle BT_DAILY_TAG");
		[[Window shared] showWindow:PANEL_DAILY];
	}else if ([node tag] == BT_ACT_TAG) {
		CCLOG(@"handle BT_ACT_TAG");
	}else if ([node tag] == BT_REWARD_TAG) {
		CCLOG(@"handle BT_REWARD_TAG");
		[[Window shared] showWindow:PANEL_REWARD];
	}else if ([node tag] == BT_BACK_WORLD_TAG) {
		CCLOG(@"handle BT_BACK_WORLD_TAG");
		if([MapManager shared].mapType==Map_Type_Abyss){
			[AbyssManager quitAbyss];
			return;
		}
		if([MapManager shared].mapType==Map_Type_Union){
			[UnionManager quitUnion];
			return;
		}
		if([MiningManager isMining]){
			return;
		}
		if([FightManager isFighting]){
			return;
		}
		if([MapManager shared].mapType==Map_Type_SysPvp){
			[[Game shared] backToMap:nil call:nil];
			return;
		}
		//soul
		NSDictionary* dict = [TaskManager shared].completeList;
		if (dict != nil) {
			NSArray *tl = [dict allKeys];
			NSString* key = [NSString stringWithFormat:@"13"];
			if (![tl containsObject:key]) {
				return ;
			}
		}
		
		if ([[RoleManager shared].player isPrepareMoveEnd]) {
			CCLOG(@"Back map->[RoleManager shared].player isPrepareMoveEnd]");	
			return ;
		}
		
		[[TaskManager shared] freeTaskStep];
		
		[[Game shared] backToMap:nil call:nil];
		
//		NSDictionary * info = [[GameDB shared] getMapInfo:[MapManager shared].mapId];
//		int pmid = [[info objectForKey:@"pmid"] intValue];
//		[[Game shared] trunToMap:pmid];
	}
}
-(void) updateStatus:(Map_Type)_type
{
	if([MapManager shared].mapType==Map_Type_Standard){
		[self showTaskBtn:true];
		[self showDailyBtn:true];
		[self showBackBtn:false];
		[self showActBtn:true];
		[self showShowMapBtn:true];
		[self showRewardBtn:true];
        [self showRankBtn:true];
		[self showCashBtn:true];
	}
	else if([MapManager shared].mapType==Map_Type_Stage){
		[self showMapName:false];
		[self showTaskBtn:false];
		[self showDailyBtn:false];
		[self showBackBtn:true];
		[self showActBtn:false];
		[self showShowMapBtn:false];
		[self showRewardBtn:false];
        [self showRankBtn:false];
		[self showCashBtn:false];
	}
	else if([MapManager shared].mapType==Map_Type_Abyss){
		[self showMapName:false];
		[self showTaskBtn:false];
		[self showDailyBtn:false];
		[self showActBtn:false];
		[self showRewardBtn:false];
        [self showRankBtn:false];
		[self showShowMapBtn:false];
		[self showBackBtn:false];
		[self showCashBtn:false];
	}
	else if([MapManager shared].mapType==Map_Type_Union){
		[self showMapName:false];
		[self showTaskBtn:false];
		[self showDailyBtn:false];
		[self showActBtn:false];
		[self showRewardBtn:false];
        [self showRankBtn:false];
		[self showShowMapBtn:false];
		[self showBackBtn:false];
		[self showCashBtn:false];
	}else if([MapManager shared].mapType==Map_Type_Fish){
		[self showMapName:NO];
		[self showTaskBtn:YES];
		[self showDailyBtn:NO];
		[self showActBtn:NO];
		[self showRewardBtn:NO];
        [self showRankBtn:false];
		[self showShowMapBtn:NO];
		[self showBackBtn:NO];
		[self showCashBtn:false];
	}else if([MapManager shared].mapType==Map_Type_TimeBox){
		[self showMapName:NO];
		[self showTaskBtn:NO];
		[self showDailyBtn:NO];
		[self showActBtn:NO];
		[self showRewardBtn:NO];
        [self showRankBtn:false];
		[self showShowMapBtn:NO];
		[self showBackBtn:NO];
		[self showCashBtn:false];
	}else if([MapManager shared].mapType==Map_Type_Mining){
		[self showMapName:NO];
		[self showTaskBtn:NO];
		[self showDailyBtn:NO];
		[self showActBtn:NO];
		[self showRewardBtn:NO];
        [self showRankBtn:false];
		[self showShowMapBtn:NO];
		[self showBackBtn:NO];
		[self showCashBtn:false];
	}else if ([MapManager shared].mapType==Map_Type_WorldBoss){
		[self showMapName:NO];
		[self showTaskBtn:NO];
		[self showDailyBtn:NO];
		[self showActBtn:NO];
		[self showRewardBtn:NO];
        [self showRankBtn:false];
		[self showShowMapBtn:NO];
		[self showBackBtn:NO];
		[self showCashBtn:false];
	}else if ([MapManager shared].mapType==Map_Type_UnionBoss){
		[self showMapName:NO];
		[self showTaskBtn:NO];
		[self showDailyBtn:NO];
		[self showActBtn:NO];
		[self showRewardBtn:NO];
        [self showRankBtn:false];
		[self showShowMapBtn:NO];
		[self showBackBtn:NO];
		[self showCashBtn:false];
	}else if([MapManager shared].mapType==Map_Type_SysPvp){
		[self showTaskBtn:NO];
		[self showDailyBtn:NO];
		[self showBackBtn:true];
		[self showActBtn:NO];
		[self showShowMapBtn:NO];
		[self showRewardBtn:NO];
        [self showRankBtn:false];
		[self showCashBtn:false];
	}else if([MapManager shared].mapType==Map_Type_dragonReady){
		[self showTaskBtn:NO];
		[self showDailyBtn:NO];
		[self showBackBtn:NO];
		[self showActBtn:NO];
		[self showShowMapBtn:NO];
		[self showRewardBtn:NO];
        [self showRankBtn:NO];
		[self showCashBtn:NO];
	}else if([MapManager shared].mapType==Map_Type_dragonFight){
		[self showTaskBtn:NO];
		[self showDailyBtn:NO];
		[self showBackBtn:NO];
		[self showActBtn:NO];
		[self showShowMapBtn:NO];
		[self showRewardBtn:NO];
        [self showRankBtn:NO];
		[self showCashBtn:NO];
	}
	//soul
	//chapter need to hiden all buttons
	if ([[GameConfigure shared] isPlayerOnChapter]) {
		[self showMapName:YES];
		[self showShowMapBtn:YES];
		
		[self showTaskBtn:false];
		[self showDailyBtn:false];
		[self showBackBtn:false];
		[self showActBtn:false];
		[self showRewardBtn:false];
        [self showRankBtn:false];
		[self showCashBtn:false];
		
		//TODO test for Tiger Leung
		//fix chao
		//[self showTaskBtn:YES];
		[self showTaskBtn:NO];
		//end
	}
	
}
//
-(void)showFireEffectWithTag:(int)tag{
    CCSimpleButton *item = (CCSimpleButton *)[self getChildByTag:tag];
    if (item) {
        NSArray *frame=[AnimationViewer loadFileByFileFullPath:@"images/ui/intro/fire/" name:@"%d.png"];
        AnimationViewer *fire_logo=[AnimationViewer node];
        [fire_logo playAnimation:frame];
        [fire_logo setPosition:ccp(item.contentSize.width/2,item.contentSize.height/2)];
        fire_logo.tag = tag;
        [item addChild:fire_logo];
        return;
    }
    //
    CCLOG(@"no menu item.....");
}
//
-(void)hideFireEffectWithTag:(int)tag{
    CCSimpleButton *item = (CCSimpleButton *)[self getChildByTag:tag];
    [item removeChildByTag:tag cleanup:YES];
}

-(void) showMapName:(bool)bShow
{
	[self showShowMapBtn:bShow];
}

-(void) showShowMapBtn:(bool)bShow
{
	//fix chao
	[m_Menu removeChildByTag:BT_SHOW_MAP_TAG cleanup:YES];
	if (bShow){
		NSArray * btns = getBtnSpriteForScale(@"images/ui/button/bt_jumpmap.png",1.1f);
		CCSprite *spr1 = [btns objectAtIndex:0];
		CCSprite *spr2 = [btns objectAtIndex:1];
		//int mapID = [[MapManager shared] getTargetMapId];
		//int mapID = [[MapManager shared] mapId];
		//NSDictionary *dictionary = [[GameDB shared] getMapInfo:mapID];
		if (YES) {
			NSString *name = [[MapManager shared] getMapName];//[dictionary objectForKey:@"name"];
			
			/*
			CCLabelFX *name1 = [CCLabelFX labelWithString:name
											   dimensions:mapNameRect
												alignment:kCCTextAlignmentCenter
												 fontName:getCommonFontName(FONT_1)
												 fontSize:21
											 shadowOffset:CGSizeMake(-1.5, -1.5)
											   shadowBlur:1.0f
											  shadowColor:ccc4(160,100,20, 128)
												fillColor:ccc4(230, 180, 60, 255)];

			CCLabelFX *name2 = [CCLabelFX labelWithString:name
											   dimensions:mapNameRect
												alignment:kCCTextAlignmentCenter
												 fontName:getCommonFontName(FONT_1)
												 fontSize:21
											 shadowOffset:CGSizeMake(-1.5, -1.5)
											   shadowBlur:1.0f
											  shadowColor:ccc4(160,100,20, 128)
												fillColor:ccc4(230, 180, 60, 255)];
			 */
			float fontSize=18;
			if(iPhoneRuningOnGame())
			{
				fontSize=19;
			}
			
			
			CCLabelFX *name1 = [CCLabelFX labelWithString:name
												 fontName:getCommonFontName(FONT_1)
												 fontSize:fontSize
											 shadowOffset:CGSizeMake(-1.5, -1.5)
											   shadowBlur:1.0f
											  shadowColor:ccc4(160,100,20, 128)
												fillColor:ccc4(230, 180, 60, 255)];
			
			CCLabelFX *name2 = [CCLabelFX labelWithString:name
												 fontName:getCommonFontName(FONT_1)
												 fontSize:fontSize
											 shadowOffset:CGSizeMake(-1.5, -1.5)
											   shadowBlur:1.0f
											  shadowColor:ccc4(160,100,20, 128)
												fillColor:ccc4(230, 180, 60, 255)];
			if(iPhoneRuningOnGame())
			{
				name1.position = ccp(spr1.contentSize.width/2.0f - cFixedScale(15.5), (spr1.contentSize.height)/2.0f+cFixedScale(5));
				name2.position = ccp(spr2.contentSize.width/2.0f - cFixedScale(15.5), (spr2.contentSize.height)/2.0f+cFixedScale(5));
			}else{
				name1.position = ccp(spr1.contentSize.width/2 - cFixedScale(13), (spr1.contentSize.height)/2+cFixedScale(5));
				name2.position = ccp(spr2.contentSize.width/2 - cFixedScale(13), (spr2.contentSize.height)/2+cFixedScale(5));
			}
			
			[spr1 addChild:name1];
			[spr2 addChild:name2];
		}
		
		CCMenuItemImage * bShowMap = [CCMenuItemImage itemWithNormalSprite:spr1
															selectedSprite:spr2
															disabledSprite:nil
																	target:self
																  selector:@selector(menuCallbackBack:)];
		if (iPhoneRuningOnGame()) {
			bShowMap.scale=1.13f;
			CGPoint pt=[self getBtnPosition:BT_SHOW_MAP_TAG];
			bShowMap.position =ccpAdd(pt, ccp(-6.5,-2.0f));
		}else{
			bShowMap.position = [self getBtnPosition:BT_SHOW_MAP_TAG];
		}
		[m_Menu addChild:bShowMap z:1 tag:BT_SHOW_MAP_TAG];
	}
	//end
}
-(void) showBackBtn:(bool)bShow
{

	CCMenuItemImage *bt = (CCMenuItemImage*)[m_Menu getChildByTag:BT_BACK_WORLD_TAG];
	if (bShow) {
		if (bt != nil) {
			[bt removeFromParentAndCleanup:YES];
			bt = nil ;
		}
		if (bt == nil) {
			//NSArray * btns2 = getBtnSpriteForScale(@"images/ui/button/bt_back.png",1.1f);
			NSArray * btns2 = getBtnSpriteForScale(@"images/ui/button/bt_backmap.png",1.1f);
			CCSprite *spr1 = [btns2 objectAtIndex:0];
			CCSprite *spr2 = [btns2 objectAtIndex:1];			
			//int mapID = [[MapManager shared] getTargetMapId];//[[MapManager shared] mapId];
			//NSDictionary *dictionary = [[GameDB shared] getMapInfo:mapID];
			if (YES) {
				NSString *name = [[MapManager shared] getMapName];//NSString *name = [dictionary objectForKey:@"name"];
				
				/*
				CCLabelFX *name1 = [CCLabelFX labelWithString:name
												   dimensions:mapNameRect
													alignment:kCCTextAlignmentCenter
													 fontName:getCommonFontName(FONT_1)
													 fontSize:21
												 shadowOffset:CGSizeMake(-1.5, -1.5)
												   shadowBlur:1.0f
												  shadowColor:ccc4(160,100,20, 128)
													fillColor:ccc4(230, 180, 60, 255)];
				
				CCLabelFX *name2 = [CCLabelFX labelWithString:name
												   dimensions:mapNameRect
													alignment:kCCTextAlignmentCenter
													 fontName:getCommonFontName(FONT_1)
													 fontSize:21
												 shadowOffset:CGSizeMake(-1.5, -1.5)
												   shadowBlur:1.0f
												  shadowColor:ccc4(160,100,20, 128)
													fillColor:ccc4(230, 180, 60, 255)];
				
				*/
				float fontSize=21;
				if(iPhoneRuningOnGame())
				{
					fontSize=19;
				}
				CCLabelFX *name1 = [CCLabelFX labelWithString:name
													 fontName:getCommonFontName(FONT_1)
													 fontSize:fontSize
												 shadowOffset:CGSizeMake(-1.5, -1.5)
												   shadowBlur:1.0f
												  shadowColor:ccc4(160,100,20, 128)
													fillColor:ccc4(230, 180, 60, 255)];
				
				CCLabelFX *name2 = [CCLabelFX labelWithString:name
													 fontName:getCommonFontName(FONT_1)
													 fontSize:fontSize
												 shadowOffset:CGSizeMake(-1.5, -1.5)
												   shadowBlur:1.0f
												  shadowColor:ccc4(160,100,20, 128)
													fillColor:ccc4(230, 180, 60, 255)];
				
				
				[spr1 addChild:name1];
				name1.position = ccp(spr1.contentSize.width/2 - cFixedScale(5), (spr1.contentSize.height)/2+cFixedScale(5));
				[spr2 addChild:name2];
				name2.position = ccp(spr2.contentSize.width/2 - cFixedScale(5), (spr2.contentSize.height)/2+cFixedScale(5));
				
			}
			
			bt = [CCMenuItemImage itemWithNormalSprite:[btns2 objectAtIndex:0]
										selectedSprite:[btns2 objectAtIndex:1]
										disabledSprite:nil
												target:self
											  selector:@selector(menuCallbackBack:)];
			//CGSize winSize = [[CCDirector sharedDirector] winSize];
			//bt.position = ccp(winSize.width/2 , winSize.height /2);
			if (iPhoneRuningOnGame()) {
				bt.scale=1.13f;
			}
			bt.position = [self getBtnPosition:BT_BACK_WORLD_TAG];
			[m_Menu addChild:bt z:3 tag:BT_BACK_WORLD_TAG];
			bt.position =ccpAdd(bt.position, ccp(-6.5,-2.0f));
			
		}
		else {
			bt.visible = true;
		}
	}
	else {
		if (bt) {
			bt.visible = false;
		}
	}

}

-(void) showTaskBtn:(bool)bShow
{
	CCSimpleButton* bt = (CCSimpleButton*)[self getChildByTag:BT_TASK_TAG];
	//CGSize win = [CCDirector sharedDirector].winSize;
	if (bShow) {
		if (bt == nil) {
			
			//fix chao
			bt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_task_1.png"
										 select:@"images/ui/button/bt_task_2.png"
										 target:self
										   call:@selector(doShowTask:)];
			if (iPhoneRuningOnGame()) {
				bt.scale=1.15f;
			}
			[self addChild:bt z:2 tag:BT_TASK_TAG];
			
			//bt.position=ccp(win.width-cFixedScale(60), win.height - cFixedScale(250));
			bt.position = [self getBtnPosition:BT_TASK_TAG];
			
		}else {
			bt.visible = true;
		}
	}else {
		if (bt) {
			bt.visible = false;
		}
	}
}
-(void)doShowTask:(id)sender{

	[[GameSoundManager shared] click];
	if((!self.visible) || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
		return;
	}
	[[Window shared] showWindow:PANEL_TASK];
}
-(void)unlockTask{
	CCSimpleButton* bt = (CCSimpleButton*)[self getChildByTag:BT_TASK_TAG];
	if (bt) {
		[bt showSuggest];
	}
}
-(void)unlockDailyFunction{
	CCSimpleButton* bt = (CCSimpleButton*)[self getChildByTag:BT_DAILY_TAG];
	if (bt) {
		[bt showSuggest];
	}
}

-(void)unlockCash{
	if ([CashCowManager checkOpenSystem]) {
		if ([MapManager shared].mapType==Map_Type_Standard) {
			[self showCashBtn:YES];
		}
	}
}

-(void)unlockDaily{
	CCSimpleButton *bt = (CCSimpleButton*)[self getChildByTag:BT_ACT_TAG];//判断是不是需要显示
	CGSize size = [CCDirector sharedDirector].winSize;
	if (bt && bt.visible) {
		[self removeChildByTag:BT_DAILY_TAG cleanup:YES];
		CCSimpleButton *d1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_daily_1.png"
													 select:@"images/ui/button/bt_daily_2.png"
													 target:self
													   call:@selector(doShowDaily:)];
		[self addChild:d1 z:2 tag:BT_DAILY_TAG];
		//刚解锁时日常图标的位置
		if (iPhoneRuningOnGame()) {
			d1.position=ccp(size.width - (mapNameRect.width + cFixedScale(40))-18, size.height - cFixedScale(50)-4);
		}else{
			d1.position=ccp(size.width - (mapNameRect.width + cFixedScale(40)), size.height - cFixedScale(50));		
		}
		//解锁时由小变大
		d1.scale=0;
		if (iPhoneRuningOnGame()) {
			[d1 runAction:[CCScaleTo actionWithDuration:0.4 scale:1.15f]];
		}
		else{
			[d1 runAction:[CCScaleTo actionWithDuration:0.4 scale:1]];
		}
		id act1 =[CCMoveTo actionWithDuration:0.2 position:ccpAdd(bt.position, ccp(cFixedScale(-90), 0))];
		[bt runAction:act1];
		
		
		CCSimpleButton *b2 = (CCSimpleButton*)[self getChildByTag:BT_REWARD_TAG];
		id act2 =[CCMoveTo actionWithDuration:0.2 position:ccpAdd(b2.position, ccp(cFixedScale(-90), 0))];
		[b2 runAction:act2];
	}
}
-(void)doShowDaily:(id)sender{
	CCLOG(@"doShowDaily");
	[[GameSoundManager shared] click];
	if((!self.visible) || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
		return;
	}
	[[Window shared] showWindow:PANEL_DAILY];
}
-(void)showDailyBtn:(bool)bShow
{
	if ([[GameConfigure shared] checkPlayerFunction:Unlock_daily]) {
		CCSimpleButton* bt = (CCSimpleButton*)[self getChildByTag:BT_DAILY_TAG];
		if (bShow) {
			
			//CGSize size = [CCDirector sharedDirector].winSize;
			if (bShow) {
				if (bt == nil) {
					bt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_daily_1.png"
												 select:@"images/ui/button/bt_daily_2.png"
												 target:self
												   call:@selector(doShowDaily:)];
					//bt.priority = -57;
					[self addChild:bt z:2 tag:BT_DAILY_TAG];
					if (iPhoneRuningOnGame()) {
						bt.scale=1.15f;
					}
					//bt.position=ccp(size.width - (mapNameRect.width + cFixedScale(40)), size.height - cFixedScale(50));
					bt.position = [self getBtnPosition:BT_DAILY_TAG];
					
				}else {
					bt.visible = true;
				}
			}else {
				if (bt) {
					bt.visible = false;
				}
			}
			
		}else{
			if (bt) {
				bt.visible = false;
			}
		}
			
	}
}
-(void)doShowAct:(id)sender{
	CCLOG(@"doShowAct");
	[[GameSoundManager shared] click];
		if ((![[GameUI shared] checkPartVisible:GAMEUI_PART_RU]) || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] ) {

		return;
	}
	[[Window shared] showWindow:PANEL_ACTIVITY];
}
-(void)showActBtn:(bool)bShow
{
	//CGSize size = [CCDirector sharedDirector].winSize;
	
	CCSimpleButton* bt = (CCSimpleButton*)[self getChildByTag:BT_ACT_TAG];
	if (bShow) {
		if (bt == nil) {
			bt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_act_1.png"
										 select:@"images/ui/button/bt_act_2.png"
										 target:self
										   call:@selector(doShowAct:)];
			//bt.priority = -57;
			[self addChild:bt z:2 tag:BT_ACT_TAG];
			if (iPhoneRuningOnGame()) {
				bt.scale=1.15f;
			}
			bt.position = [self getBtnPosition:BT_ACT_TAG];
			
		}else {
			bt.visible = true;
		}
	}else {
		if (bt) {
			bt.visible = false;
		}
	}
}

-(void)doShowCash:(id)sender{
	if((!self.visible) || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
		return;
	}
	CCLOG(@"doShowCash");
	if (![CashCowManager checkOpenSystem]) {
		return ;
	}
	[[Window shared] showWindow:PANEL_CASHCOW];
}
-(void)doShowReward:(id)sender{
	[[GameSoundManager shared] click];
	if((!self.visible) || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
		return;
	}
	CCLOG(@"doShowReward");
	[[Window shared] showWindow:PANEL_REWARD];
}
-(void) showRewardBtn:(bool)bShow
{
	//CGSize size = [CCDirector sharedDirector].winSize;
	
	CCSimpleButton* bt = (CCSimpleButton*)[self getChildByTag:BT_REWARD_TAG];
	if (bShow) {
		if (bt == nil) {
			bt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_reward_1.png"
										 select:@"images/ui/button/bt_reward_2.png"
										 target:self
										   call:@selector(doShowReward:)];
			//bt.priority = -57;
			[self addChild:bt z:2 tag:BT_REWARD_TAG];
			if (iPhoneRuningOnGame()) {
				bt.scale=1.15f;
			}
			bt.position = [self getBtnPosition:BT_REWARD_TAG];
			
		}else {
			bt.visible = true;
		}
		
		// 显示时更新邮件个数
		[self updateMailCount];
	}else {
		if (bt) {
			bt.visible = false;
		}
	}
}
-(void)doShowRank:(id)sender{
	[[GameSoundManager shared] click];
	if((!self.visible) || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
		return;
	}
	CCLOG(@"doShowReward");
	[[Window shared] showWindow:PANEL_RANK_arena];
}
-(void) showRankBtn:(bool)bShow
{
	if (![CashCowManager checkOpenSystem]) {
		return ;
	}
	if ([[GameConfigure shared] isPlayerOnChapter]) {
		return ;
	}
	//todo 按钮图标移走了
	return ;
	
	CCSimpleButton* bt = (CCSimpleButton*)[self getChildByTag:BT_RANK_TAG];
	if (bShow) {
		if (bt == nil) {
			bt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_rank_1.png"
										 select:@"images/ui/button/bt_rank_2.png"
										 target:self
										   call:@selector(doShowRank:)];
			//bt.priority = -57;
			[self addChild:bt z:2 tag:BT_RANK_TAG];
			if (iPhoneRuningOnGame()) {
				bt.scale=1.15f;
			}
			bt.position = [self getBtnPosition:BT_RANK_TAG];
			
		}else {
			bt.visible = true;
		}
	}else {
		if (bt) {
			bt.visible = false;
		}
	}
}
-(void)showCashBtn:(bool)bShow{
	if (![CashCowManager checkOpenSystem]) {
		return ;
	}
	if ([[GameConfigure shared] isPlayerOnChapter]) {
		return ;
	}
	//todo 按钮图标移走了
	return ;
	
	CCSimpleButton* bt = (CCSimpleButton*)[self getChildByTag:BT_CASH_TAG];
	if (bShow) {
		if (bt == nil) {
			//todo 按钮图片
			bt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_cash_1.png"
										 select:@"images/ui/button/bt_cash_2.png"
										 target:self
										   call:@selector(doShowCash:)];
			//bt.priority = -57;
			[self addChild:bt z:2 tag:BT_CASH_TAG];
			
			if (iPhoneRuningOnGame()) {
				bt.scale=1.15f;
			}
			
			bt.position = [self getBtnPosition:BT_CASH_TAG];
			
		}else {
			bt.visible = true;
		}
	}else {
		if (bt) {
			bt.visible = false;
		}
	}
}

//----------------------------------------------------------------------------

-(void)updateMailCount{
	CCSimpleButton * bt = (CCSimpleButton*)[self getChildByTag:BT_REWARD_TAG];
	if(bt){
		int count = [[GameMail shared] getCountByType:Mail_type_reward];
		[bt showCount:count];
	}
}

-(void)changeUI{
	
	float actionTime = 0.25f;
	id move = nil;
	
	CCNode * bt = [self getChildByTag:BT_TASK_TAG];
	if(bt){
		[bt stopAllActions];
		move = [CCMoveTo actionWithDuration:actionTime position:[self getBtnPosition:BT_TASK_TAG]];
		[bt runAction:move];
	}
	
	bt = [self getChildByTag:BT_DAILY_TAG];
	if(bt){
		[bt stopAllActions];
		move = [CCMoveTo actionWithDuration:actionTime position:[self getBtnPosition:BT_DAILY_TAG]];
		[bt runAction:move];
	}
	
	bt = [self getChildByTag:BT_ACT_TAG];
	if(bt){
		[bt stopAllActions];
		move = [CCMoveTo actionWithDuration:actionTime position:[self getBtnPosition:BT_ACT_TAG]];
		[bt runAction:move];
	}
	
	bt = [self getChildByTag:BT_REWARD_TAG];
	if(bt){
		[bt stopAllActions];
		move = [CCMoveTo actionWithDuration:actionTime position:[self getBtnPosition:BT_REWARD_TAG]];
		[bt runAction:move];
	}
	
	bt = [self getChildByTag:BT_CASH_TAG];
	if(bt){
		[bt stopAllActions];
		move = [CCMoveTo actionWithDuration:actionTime position:[self getBtnPosition:BT_CASH_TAG]];
		[bt runAction:move];
	}
	
}

-(void)changeMapBtn{
	float actionTime = 0.25f;
	id move = nil;
	CCNode * bt = [m_Menu getChildByTag:BT_SHOW_MAP_TAG];
	if(bt){
		[bt stopAllActions];
		move = [CCMoveTo actionWithDuration:actionTime position:[self getBtnPosition:BT_SHOW_MAP_TAG]];
		[bt runAction:move];
	}
	bt = [m_Menu getChildByTag:BT_BACK_WORLD_TAG];
	if(bt){
		[bt stopAllActions];
		move = [CCMoveTo actionWithDuration:actionTime position:[self getBtnPosition:BT_BACK_WORLD_TAG]];
		[bt runAction:move];
	}
}

-(CGPoint)getBtnPosition:(MENU_TAG)tag{
	
	CGSize size = [CCDirector sharedDirector].winSize;
	CGPoint position = CGPointZero;
	
	float distanceX,distanceX2,distanceX3,distanceY;
	distanceX=distanceX2=distanceX3=distanceY=0;
	if (iPhoneRuningOnGame()) {
		distanceX=18;
		distanceX2=22;
		distanceX3=26;
		distanceY=4;
	}
	
	if([GameUI shared].isShowUI){
		if(tag==BT_TASK_TAG){
			position = ccp(size.width-cFixedScale(60), size.height-cFixedScale(250));
		}
		if(tag==BT_DAILY_TAG){
			position = ccp(size.width - (mapNameRect.width + cFixedScale(40))-distanceX, size.height - cFixedScale(50)-distanceY);
		}
		if(tag==BT_ACT_TAG){
			if([[GameConfigure shared] checkPlayerFunction:Unlock_daily]){
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(90)-distanceX2, size.height-cFixedScale(50)-distanceY);
			}else{
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-distanceX2, size.height-cFixedScale(50)-distanceY);
			}
		}
		if(tag==BT_REWARD_TAG){
			if ([[GameConfigure shared] checkPlayerFunction:Unlock_daily]) {
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(2*90)-distanceX3, size.height-cFixedScale(50)-distanceY);
			}else{
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(90)-distanceX3, size.height-cFixedScale(50)-distanceY);
			}
		}
        if(tag==BT_RANK_TAG){
			if ([[GameConfigure shared] checkPlayerFunction:Unlock_daily]) {
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(3*90)-distanceX3, size.height-cFixedScale(50)-distanceY);
			}else{
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(2*90)-distanceX3, size.height-cFixedScale(50)-distanceY);
			}
		}
		if(tag==BT_CASH_TAG){
			if ([[GameConfigure shared] checkPlayerFunction:Unlock_daily]) {
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(4*90)-distanceX3, size.height-cFixedScale(50)-distanceY);
			}else{
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(3*90)-distanceX3, size.height-cFixedScale(50)-distanceY);
			}
		}
		
	}else{
		if(tag==BT_TASK_TAG){
			position = ccp(size.width+cFixedScale(60), size.height-cFixedScale(250));
		}
		if(tag==BT_DAILY_TAG){
			position = ccp(size.width-(mapNameRect.width+cFixedScale(40))-distanceX, size.height+cFixedScale(60)-distanceY);
		}
		if(tag==BT_ACT_TAG){
			if([[GameConfigure shared] checkPlayerFunction:Unlock_daily]){
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(90)-distanceX2, size.height+cFixedScale(60)-distanceY);
			}else{
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-distanceX2, size.height+cFixedScale(60)-distanceY);
			}
		}
		if(tag==BT_REWARD_TAG){
			if ([[GameConfigure shared] checkPlayerFunction:Unlock_daily]) {
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(2*90)-distanceX3, size.height+cFixedScale(60)-distanceY);
			}else{
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(90)-distanceX3, size.height+cFixedScale(60)-distanceY);
			}
		}
        if(tag==BT_RANK_TAG){
			if ([[GameConfigure shared] checkPlayerFunction:Unlock_daily]) {
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(3*90)-distanceX3, size.height+cFixedScale(60)-distanceY);
			}else{
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(2*90)-distanceX3, size.height+cFixedScale(60)-distanceY);
			}
		}
		if(tag==BT_CASH_TAG){
			if ([[GameConfigure shared] checkPlayerFunction:Unlock_daily]) {
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(4*90)-distanceX3, size.height+cFixedScale(60)-distanceY);
			}else{
				position=ccp(size.width-(mapNameRect.width+cFixedScale(40))-cFixedScale(3*90)-distanceX3, size.height+cFixedScale(60)-distanceY);
			}
		}
	}
	
	if([GameUI shared].isShowOtherUI){
		if(tag==BT_SHOW_MAP_TAG){
			float _x = mapNameRect.width/2;
			float _y = mapNameRect.height/2;
			position = ccp(size.width-_x, size.height-_y);
		}
		if(tag==BT_BACK_WORLD_TAG){
			float _x = mapNameRect.width/2;
			float _y = mapNameRect.height/2;
			position = ccp(size.width-_x, size.height-_y);
		}
	}else{
		if(tag==BT_SHOW_MAP_TAG){
			float _x = mapNameRect.width/2;
			float _y = mapNameRect.height/2;
			position = ccp(size.width-_x, size.height-_y+cFixedScale(+60));
		}
		if(tag==BT_BACK_WORLD_TAG){
			float _x = mapNameRect.width/2;
			float _y = mapNameRect.height/2;
			position = ccp(size.width-_x, size.height-_y+cFixedScale(+60));
		}
	}
	
	return position;
}

@end
