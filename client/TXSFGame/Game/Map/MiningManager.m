//
//  MiningManager.m
//  TXSFGame
//
//  Created by huang shoujun on 13-1-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "MiningManager.h"
#import "Config.h"
#import "Game.h"
#import "GameDB.h"
#import "RolePlayer.h"
#import "RoleManager.h"
#import "GameConfigure.h"
#import "MapManager.h"
#import "GameUI.h"
#import "GameMoney.h"
#import "GameEffects.h"

#import "GameConnection.h"
#import "GameLayer.h"
#import "AnimationViewer.h"
#import "AlertManager.h"
#import "InfoAlert.h"
#import "GameTouchPoint.h"
#import "Arena.h"

#define MiningScrollTouch_tag	20030

#define MiningClick_tag		20034
#define MiningCount_tag		20033
#define MiningScrollBg_tag	10089
#define MiningScrollWidth	cFixedScale(403.0f)
#define MiningScrollDuration	4.0f


static int sortArray(NSValue *_value1, NSValue *_value2, void*pt){
	
	CGPoint pt1 = getTiledRectCenterPoint([_value1 CGRectValue]);
	CGPoint pt2 = getTiledRectCenterPoint([_value2 CGRectValue]);
	CGPoint target = CGPointFromString(pt);
	
	if(ccpDistance(pt1, target) < ccpDistance(pt2, target)) return NSOrderedAscending;
	if(ccpDistance(pt1, target) > ccpDistance(pt2, target)) return NSOrderedDescending;
	
	return NSOrderedSame;
}

static MiningManager *s_MiningManager = nil;

static int s_Collect = 0 ;
static int s_StoneIndex = 0;

@interface MiningScrollTouch : CCLayerColor

@end

@implementation MiningScrollTouch

-(void)onEnter
{
	[super onEnter];

	// 设置极高的优先级
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-1000 swallowsTouches:YES];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	// 点击一次
	if (s_MiningManager) {
		[s_MiningManager tapOnce];
	}
	return YES;
}

-(void)onExit
{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

@end

@implementation MiningManager

+(MiningManager*)shared{
	if (!s_MiningManager) {
		s_MiningManager = [MiningManager node];
		[s_MiningManager retain];
	}
	return s_MiningManager;
}

+(void)stopAll{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	if (s_MiningManager) {
		
		[[[GameLayer shared] content] removeChildByTag:10099 cleanup:YES];//
		[GameEffectsBlockTouck unlockScreen];//
		
		[s_MiningManager removeFromParentAndCleanup:YES];
		[s_MiningManager release];
		s_MiningManager=nil;
		
		[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
		[CCLabelBMFont purgeCachedData];
		[[CCTextureCache sharedTextureCache] removeUnusedTextures];
		[[CCFileUtils sharedFileUtils] purgeCachedEntries];
		
	}
}

+(BOOL)isMining{
	if (s_MiningManager) {
		return [s_MiningManager checkMining];
	}
	return NO;
}

+(void)enterMining{
	if ([MiningManager checkCanEnter]) {
		//发协议
		[[Game shared] trunToMap:1001];
	}else{
//		[[AlertManager shared] showMessage:@"无法进入采矿，你等级太低..."
//									target:[MiningManager class]
//								   confirm:@selector(stopAll)
//									 canel:nil];
        [[AlertManager shared] showMessage:NSLocalizedString(@"mining_input",nil)
									target:[MiningManager class]
								   confirm:@selector(stopAll)
									 canel:nil];
	}
}

+(void)quitMining{
	[MiningManager stopAll];//
	[[Game shared] backToMap:nil call:nil];//
	[[Intro share]removeInCurrenTipsAndNextStep:INTRO_Mining_Step_2];
}

+(void)checkStatus{
	if([MapManager shared].mapType==Map_Type_Mining){
		[[MiningManager shared] start];
	}else{
		[MiningManager stopAll];
	}
}

+(BOOL)checkCanEnter{
	NSDictionary *dict = [[GameDB shared] getGlobalConfig];
	if (dict) {
		int enterLevel = [[dict objectForKey:@"mineEnterLevel"] intValue];
		int playerLevel = [[GameConfigure shared] getPlayerLevel];
		if (playerLevel >= enterLevel){
			return YES;
		}
	}
	return NO;
}

-(BOOL)checkMining{
	//return (m_Step != Collect_wait);
	return bStartCollect ;
}

-(void)start{
	if(!self.parent){
		s_Collect = 0 ;
		[self loadSetting];
		[self setCostting];
		isCanExit = YES;
		
		//[[GameUI shared] addChild:self z:INT_MAX];
        //[[GameUI shared] addChild:self z:-1];
		self.visible = YES ;
		[[GameUI shared] addChild:self z:-1 tag:GameUi_SpecialSystem_mining];
	}
	
}

-(void)onEnter{
	[super onEnter];
	
	bStartCollect = NO;
	[self removeObtain];
	
	CGSize winSize = [CCDirector sharedDirector].winSize;
	
	if (!stones) {
		stones = [NSMutableArray array];
		[stones retain];
	}
	
	[GameConnection addPost:ConnPost_updatePackage target:self call:@selector(showPlayerInfo)];
	
	//CCSimpleButton *back = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_back.png"];
	//fix chao
	[self removeChildByTag:10032 cleanup:YES];
	NSArray *btns = getBtnSpriteForScale(@"images/ui/button/bt_backmap.png",1.1f);
	CCSprite *spr1 = [btns objectAtIndex:0];
	CCSprite *spr2 = [btns objectAtIndex:1];
	NSString *name = [[MapManager shared] getMapName];
	CCLabelFX *name1 = [CCLabelFX labelWithString:name
									   dimensions:CGSizeMake(0,0)
										alignment:kCCTextAlignmentCenter
										 fontName:getCommonFontName(FONT_1)
										 fontSize:21
									 shadowOffset:CGSizeMake(-1.5, -1.5)
									   shadowBlur:1.0f
									  shadowColor:ccc4(160,100,20, 128)
										fillColor:ccc4(230, 180, 60, 255)];
	
//    if (iPhoneRuningOnGame()) {
//        name1.scale=FONT_SIZE_SCALE;
//    }
	CCLabelFX *name2 = [CCLabelFX labelWithString:name
									   dimensions:CGSizeMake(0,0)
										alignment:kCCTextAlignmentCenter
										 fontName:getCommonFontName(FONT_1)
										 fontSize:21
									 shadowOffset:CGSizeMake(-1.5, -1.5)
									   shadowBlur:1.0f
									  shadowColor:ccc4(160,100,20, 128)
										fillColor:ccc4(230, 180, 60, 255)];
//    if (iPhoneRuningOnGame()) {
//        name2.scale=FONT_SIZE_SCALE;
//    }
	[spr1 addChild:name1];
	name1.position = ccp(spr1.contentSize.width/2 - cFixedScale(10), (spr1.contentSize.height)*1.2/2);
	[spr2 addChild:name2];
	name2.position = ccp(spr2.contentSize.width/2 - cFixedScale(10), (spr2.contentSize.height)*1.2/2);
	back = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_backmap.png"];
	[back setNormalSprite:spr1];
	[back setSelectSprite:spr2];
	//end
	back.target=self;
	back.call=@selector(doExit:);
	back.tag = 10032;
	[self addChild:back];
	back.anchorPoint=ccp(1, 1);
	
	if (iPhoneRuningOnGame()) {
		back.scale=1.13f;
		back.position=ccp(winSize.width, winSize.height);
	}else{
		back.position=ccp(winSize.width, winSize.height);
	}
	
	[self removeChildByTag:5678 cleanup:YES];
	CCMenu *menu = [CCMenu node];
	menu.ignoreAnchorPointForPosition = YES;
	[self addChild:menu z:0 tag:5678];
	menu.position = ccp(0, 0);
	
	[self showFunction];
	[self showPlayerInfo];
    
    // 规则
    //fix chao
	[self removeChildByTag:10033 cleanup:YES];
	RuleButton *ruleButton = [RuleButton node];
	if (iPhoneRuningOnGame()) {
		ruleButton.position = ccp(winSize.width-cFixedScale(FULL_WINDOW_RULE_OFF_X), winSize.height-cFixedScale(FULL_WINDOW_RULE_OFF_Y)+5);
	}else{
		ruleButton.position = ccp(winSize.width-cFixedScale(FULL_WINDOW_RULE_OFF_X), winSize.height-cFixedScale(FULL_WINDOW_RULE_OFF_Y));
	}
	ruleButton.type = RuleType_mining;
	ruleButton.tag = 10033;
	ruleButton.priority = -129;
	[self addChild:ruleButton];
    //end
	
	// 消耗
	float offsetX = cFixedScale(105);
	float offsetY = cFixedScale(100);
	[self removeChildByTag:10034 cleanup:YES];
	CCSprite *costBg = [CCSprite spriteWithFile:@"images/ui/panel/p36.png"];
	costBg.position = ccp(winSize.width-offsetX,
						  winSize.height-offsetY);
	costBg.tag = 10034;
	[self addChild:costBg];
	if (iPhoneRuningOnGame()) {
		costBg.scale = 1.25;
		costBg.position = ccpSub(costBg.position, ccp(10, 5));
	}
	
	[self removeChildByTag:10035 cleanup:YES];
	//NSString *costString = [NSString stringWithFormat:@"|【采集玄铁】#7dff0a|%d银币/次*|【元宝采集】#7dff0a|%d元宝/次", cost, ingot];
    NSString *costString = [NSString stringWithFormat:NSLocalizedString(@"mining_pick",nil), cost, ingot];
	int fontSize = 14;
	int lineHeight = 18;
	float costWidth = 192;
	if (iPhoneRuningOnGame()) {
		fontSize = 18;
		lineHeight = 24;
		costWidth = 240;
	}
	CCSprite *costSprite = drawString(costString, CGSizeMake(costWidth, 0), getCommonFontName(FONT_1), fontSize, lineHeight, getHexColorByQuality(IQ_WHITE));
	costSprite.position = costBg.position;
	costSprite.tag = 10035;
	[self addChild:costSprite];
	
	// 点击提示相关
	NSString *ratioString = [[[GameDB shared] getGlobalConfig] objectForKey:@"miningRatio"];
	NSString *rangeString = [[[GameDB shared] getGlobalConfig] objectForKey:@"miningRange"];
	NSString *lengthString = [[[GameDB shared] getGlobalConfig] objectForKey:@"miningLength"];
	
	tapRatio = [NSMutableArray array];
	NSArray *ratios = [ratioString componentsSeparatedByString:@"|"];
	float totalRatio = 0;
	for (NSString *str in ratios) {
		totalRatio += [str floatValue];
	}
	float curTotalRatio = 0;
	for (int i = 0; i < ratios.count; i++) {
		if (i != ratios.count-1) {
			float ratio = ([[ratios objectAtIndex:i] floatValue])/totalRatio;
			[tapRatio addObject:[NSNumber numberWithFloat:ratio]];
			curTotalRatio += ratio;
		} else {
			[tapRatio addObject:[NSNumber numberWithFloat:(1.0f-curTotalRatio)]];
		}
	}
	[tapRatio retain];
	
	
	tapRange = [rangeString componentsSeparatedByString:@"|"];
	[tapRange retain];
	tapLength = [lengthString componentsSeparatedByString:@"|"];
	[tapLength retain];
	
	NSString *cooling = [[[GameDB shared] getGlobalConfig] objectForKey:@"miningCooling"];
	tapCooling = [cooling floatValue];
	
	isCanExit = YES;
}

-(void)onExit{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	if (tapRatio) {
		[tapRatio release];
		tapRatio = nil;
	}
	if (tapRange) {
		[tapRange release];
		tapRange = nil;
	}
	if (tapLength) {
		[tapLength release];
		tapLength = nil;
	}
	if (stones) {
		[stones release];
		stones = nil;
	}
	CCNode *node = [self getChildByTag:MiningScrollTouch_tag];
	if (node) {
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	[GameConnection removePostTarget:self];
    [GameConnection freeRequest:self];
	[super onExit];
}

-(void)doExit:(id)sender{
    if((iPhoneRuningOnGame() && [[Window shared] isHasWindow]) || [Arena arenaIsOpen] ){
        return;
    }
	if (!isCanExit) {
		return;
	}
	//退出的时候需要停止移动
	[[RoleManager shared].player stopMoveAndTask];
	[self stopMiningAction];
	[MiningManager quitMining];
	//[[Intro share]removeCurrenTipsAndNextStep:INTRO_CLOSE_Mining];
}

-(BOOL)checkOpenBatch{
	NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
	if (player) {
		NSDictionary *setting = [[GameDB shared] getGlobalConfig];
		int vipMax = [[setting objectForKey:@"mineBatchVip"] intValue];
		int vip = [[player objectForKey:@"vip"] intValue];
		return vip>=vipMax;
	}
	return NO;
}

-(void)loadSetting{
	isBatch = [[[GameConfigure shared] getPlayerRecord:@"client.collect.roles.batch"] boolValue];
	isShieid = [[[GameConfigure shared] getPlayerRecord:@"client.collect.roles.shieid"] boolValue];
	isRecordBatchIngot = [[[GameConfigure shared] getPlayerRecord:@"client.collect.roles.batchingot"] boolValue];
	isRecordIngot = [[[GameConfigure shared] getPlayerRecord:@"client.collect.roles.ingot"] boolValue];
}

-(void)setCostting{
	//todo read data
	ingot = 20 ;
	cost = 3500;
	
	NSString *costString = [[[GameDB shared] getGlobalConfig] objectForKey:@"miningCost"];
	NSArray *costArray = [costString componentsSeparatedByString:@"|"];
	if (costArray) {
		cost = [[costArray objectAtIndex:0] intValue];
		ingot = [[costArray objectAtIndex:1] intValue];
	}
}
-(void)showButton:(BOOL)__isBatch
{
	if (![self checkOpenBatch]) return;
	
	CGSize winSize = [CCDirector sharedDirector].winSize;
	float _x = winSize.width/2;
	float _y = winSize.height;
	
	CCMenu *menu = (CCMenu*)[self getChildByTag:5678];
	[menu removeChildByTag:130];
	
	NSArray* array = getToggleSprites(@"images/ui/button/bt_toggle01.png",
									  @"images/ui/button/bt_toggle02.png",
									  NSLocalizedString(@"mining_batch",nil),
									  cFixedScale(15),
									  ccc4(237,228,205,255),
									  ccc4(237,228,205,255) );
	
	CCMenuItemSprite *item1 =  [CCMenuItemSprite itemWithNormalSprite:[array objectAtIndex:0] selectedSprite:nil];
	CCMenuItemSprite *item2 =  [CCMenuItemSprite itemWithNormalSprite:[array objectAtIndex:1] selectedSprite:nil];
	CCMenuItemToggle *button = [CCMenuItemToggle itemWithTarget:self selector:@selector(setBatchType:) items:item1,item2, nil];
	[menu addChild:button z:0 tag:130];
	
	if(iPhoneRuningOnGame()){
		button.position=ccp(_x, _y - 140/2);
	}else{
		button.position=ccp(_x, _y - 140);
	}
	
	if (__isBatch) {
		[button setSelectedIndex:1];
	} else {
		[button setSelectedIndex:0];
	}
}
-(void)showFunction{
	
	if ([self checkOpenBatch]) {
		 
		[self showButton:isBatch];
		if (isBatch) {
			[self updateFunction:10];
		} else {
			[self updateFunction:1];
		}
		 
	}else{
		[self updateFunction:1];
	}
}
-(void)setBatchType:(id)sender{
    if (![Window checkPlayerCanRun]) {
		BOOL __isBatch = [[[GameConfigure shared] getPlayerRecord:@"client.collect.roles.batch"] boolValue];
		[self showButton:__isBatch];
		return ;
	}
	CCMenuItemToggle *_obj = (CCMenuItemToggle*)sender;
	if (_obj.selectedIndex == 1) {
		[[GameConfigure shared] recordPlayerSetting:@"client.collect.roles.batch" value:[NSNumber numberWithBool:YES]];
		[self showButton:YES];
		[self updateFunction:10];
	}else if (_obj.selectedIndex == 0) {
		[[GameConfigure shared] recordPlayerSetting:@"client.collect.roles.batch" value:[NSNumber numberWithBool:NO]];
		[self showButton:NO];
		[self updateFunction:1];
	}
}

-(void)showTips:(NSTimer*)obj{
	CCSimpleButton *b=(CCSimpleButton*)obj.userInfo;
	CCNode *node=[CCNode node];
	
	if(iPhoneRuningOnGame()){
		[node setPosition:ccp(40/2, 50/2)];
	}else{
		[node setPosition:ccp(40, 50)];
	}
	
	[b addChild:node];
	[[Intro share]runIntroInTager:node step:INTRO_Mining_Step_2];
}


-(void)updateFunction:(int)_value{
	
	if (_value == 1 || _value == 10) {
		
		[self removeChildByTag:1001 cleanup:YES];
		[self removeChildByTag:1002 cleanup:YES];
		[self removeChildByTag:1003 cleanup:YES];
		[self removeChildByTag:1004 cleanup:YES];
		
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		float _x = winSize.width/2;
		float _y = winSize.height - 20 ;
		
		if (_value == 1) {
			//todo 采集玄铁 按钮
			CCSimpleButton *collect1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_gether1_1.png"
															   select:@"images/ui/button/bt_gether1_2.png"];
			collect1.target=self;
			collect1.call=@selector(doCollectWithCoin:);
			
			[self addChild:collect1 z:2 tag:1001];
			
			collect1.anchorPoint=ccp(1, 0.5);
			
			if(iPhoneRuningOnGame()){
				collect1.position=ccp(_x - 10/2, _y-55/2+10);
			}else{
				collect1.position=ccp(_x - 10, _y-55);
			}
			
			[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(showTips:) userInfo:collect1 repeats:NO];
			
            //元宝采集按钮
			CCSimpleButton *collect2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_gether2_1.png"
															   select:@"images/ui/button/bt_gether2_2.png"];
			collect2.target=self;
			collect2.call=@selector(doCollectWithIngot:);
			[self addChild:collect2 z:2 tag:1002];
			collect2.anchorPoint=ccp(0, 0.5);
			
			if(iPhoneRuningOnGame()){
				collect2.position=ccp(_x + 10/2, _y-55/2+10);
			}else{
				collect2.position=ccp(_x + 10, _y-55);
			}
			
		}
		else {
			CCSimpleButton *collect1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_gether10_1.png"
															   select:@"images/ui/button/bt_gether10_2.png"];
			collect1.target=self;
			collect1.call=@selector(doBatchCollectWithCoin:);
			[self addChild:collect1 z:2 tag:1003];
			collect1.anchorPoint=ccp(1, 0.5);
			
			CCNode *node=[CCNode node];
			
			if(iPhoneRuningOnGame()){
				collect1.position=ccp(_x - 10/2, _y-55/2+10);
				[node setPosition:ccp(40/2, 50/2)];
			}else{
				collect1.position=ccp(_x - 10, _y-55);
				[node setPosition:ccp(40, 50)];
			}
			
			[collect1 addChild:node];
			
			[[Intro share]runIntroInTager:node step:INTRO_Mining_Step_2];
			
			CCSimpleButton *collect2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_gether20_1.png"
															   select:@"images/ui/button/bt_gether20_2.png"];
			collect2.target=self;
			collect2.call=@selector(doBatchCollectWithIngot:);
			[self addChild:collect2 z:2 tag:1004];
			collect2.anchorPoint=ccp(0, 0.5);
			
			if(iPhoneRuningOnGame()){
				collect2.position=ccp(_x + 10/2, _y-55/2+10);
			}else{
				collect2.position=ccp(_x + 10, _y-55);
			}
			
		}
	}
}
-(void)showPlayerInfo{
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	CCSprite *_object = (CCSprite*)[self getChildByTag:8111];
	if (!_object) {
		_object = [CCSprite spriteWithFile:@"images/ui/panel/pMining.png"];
		_object.anchorPoint=ccp(0, 1);
		[self addChild:_object z:0 tag:8111];
		_object.position = ccp(0, winSize.height);
	}
	NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
	if (player) {
		int coin1 = [[player objectForKey:@"coin1"] intValue];
		int coin2 = [[player objectForKey:@"coin2"] intValue];
		int coin3 = [[player objectForKey:@"coin3"] intValue];
		
		GameMoney *m1 = (GameMoney*)[self getChildByTag:8000];
		GameMoney *m2 = (GameMoney*)[self getChildByTag:8001];
		GameMoney *m3 = (GameMoney*)[self getChildByTag:8002];
		
		if (!m1) {
			m1=[GameMoney gameMoneyWithType:GAMEMONEY_YIBI value:coin1];
			[self addChild:m1 z:1 tag:8000];
			m1.anchorPoint=ccp(0, 0);
		}
		else {
			[m1 setMoneyValue:coin1];
		}
		if (!m2) {
			m2=[GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_ONE value:coin2];
			[self addChild:m2 z:1 tag:8001];
			m2.anchorPoint=ccp(0, 0);
		}
		else {
			[m2 setMoneyValue:coin2];
		}
		if (!m3) {
			m3=[GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_TWO value:coin3];
			[self addChild:m3 z:1 tag:8002];
			m3.anchorPoint=ccp(0, 0);
		}
		else {
			[m3 setMoneyValue:coin3];
		}
		
		if(iPhoneRuningOnGame()){
			m2.position = ccp(20/2, winSize.height - 30/2);
			m3.position = ccp(20/2 + m2.contentSize.width + 4/2, winSize.height - 30/2);
			m1.position = ccp(20/2, winSize.height - 60/2);
		}else{
			m2.position = ccp(20, winSize.height - 30);
			m3.position = ccp(20 + m2.contentSize.width + 4, winSize.height - 30);
			m1.position = ccp(20, winSize.height - 60);
		}
		
	}
}
-(void)doCollectWithCoin:(id)sender{
	CCLOG(@"doCollectWithCoin");
	//	if (m_Step != Collect_wait) {
	//		return ;
	//	}
	if (bStartCollect) {return;}
	
	if (![Window checkPlayerCanRun]) {
		return ;
	}
	[self updateCanExit];
	
	[[RoleManager shared].player stopMove];
	
	m_Step = Collect_doing ;
	s_Collect = 10;
	[[Intro share]removeInCurrenTipsAndNextStep:INTRO_Mining_Step_2];
	int _value = [[GameConfigure shared] getPlayerMoney];
	if (_value >= cost) {
		[self startCollect];
	}else{
		//[[AlertManager shared] showUrgentMessage:@"对不起，你银币不足" target:nil confirm:nil canel:nil];
        //[[AlertManager shared] showUrgentMessage:NSLocalizedString(@"mining_no_money",nil) target:nil confirm:nil canel:nil];
        [ShowItem showItemAct:NSLocalizedString(@"mining_no_money",nil)];
		m_Step = Collect_wait ;
	}
}

-(void)doCollectWithIngot:(id)sender{
	CCLOG(@"doCollectWithIngot");
	//	if (m_Step != Collect_wait) {
	//		CCLOG(@"doCollectWithIngot:m_Step != Collect_wait");
	//		return ;
	//	}
	if (bStartCollect) {return;}
	
	if (![Window checkPlayerCanRun]) {
		return ;
	}
	[self updateCanExit];
	
	[[RoleManager shared].player stopMove];
	
	m_Step = Collect_doing ;
	[self loadSetting];
	s_Collect = 20;
	int _value = [[GameConfigure shared] getPlayerIngot];
	if (_value >= ingot) {
		if (isRecordIngot) {
			[self startCollect];
		}else{
			//NSString *message = [NSString stringWithFormat:@"是否花费|%d#ff0000|元宝进行采集",ingot];
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"mining_spend_yuanbao",nil),ingot];
			[[AlertManager shared] showUrgentMessageWithSetting:message
														 target:self
														confirm:@selector(startCollect)
															key:@"client.collect.roles.ingot"];
		}
	}else{
		//[[AlertManager shared] showUrgentMessage:@"对不起，你元宝不足" target:nil confirm:nil canel:nil];
        //[[AlertManager shared] showUrgentMessage:NSLocalizedString(@"mining_no_yuanbao",nil) target:nil confirm:nil canel:nil];
        [ShowItem showItemAct:NSLocalizedString(@"mining_no_yuanbao",nil)];
		m_Step = Collect_wait ;
	}
}
-(void)doBatchCollectWithCoin:(id)sender{
	CCLOG(@"doBatchCollectWithCoin");
	//	if (m_Step != Collect_wait) {
	//		return ;
	//	}
	if (bStartCollect) {return;}
	
	if (![Window checkPlayerCanRun]) {
		return ;
	}
	[self updateCanExit];
	
	[[RoleManager shared].player stopMove];
	
	m_Step = Collect_doing ;
	s_Collect = 11;
	int _value = [[GameConfigure shared] getPlayerMoney];
	if (_value >= cost*10) {
		[self startCollect];
	}else{
		//[[AlertManager shared] showUrgentMessage:@"对不起，你银币不足" target:nil confirm:nil canel:nil];
        //[[AlertManager shared] showUrgentMessage:NSLocalizedString(@"mining_no_money",nil) target:nil confirm:nil canel:nil];
        [ShowItem showItemAct:NSLocalizedString(@"mining_no_money",nil)];
		m_Step = Collect_wait ;
	}
}
-(void)doBatchCollectWithIngot:(id)sender{
	CCLOG(@"doBatchCollectWithIngot");
	//	if (m_Step != Collect_wait) {
	//		return ;
	//	}
	if (bStartCollect) {return;}
	
	if (![Window checkPlayerCanRun]) {
		return ;
	}
	[self updateCanExit];
	
	[[RoleManager shared].player stopMove];
	
	m_Step = Collect_doing ;
	[self loadSetting];
	s_Collect = 21;
	int _value = [[GameConfigure shared] getPlayerIngot];
	if (_value >= ingot*10) {
		if (isRecordBatchIngot) {
			[self startCollect];
		}else{
			//NSString *message = [NSString stringWithFormat:@"是否花费|%d#ff0000|元宝进行采集",ingot*10];
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"mining_spend_yuanbao",nil),ingot*10];
			[[AlertManager shared] showUrgentMessageWithSetting:message
														 target:self
														confirm:@selector(startCollect)
															key:@"client.collect.roles.batchingot"];
		}
	}else{
		//[[AlertManager shared] showMessage:@"对不起，你元宝不足" target:nil confirm:nil canel:nil];
        //[[AlertManager shared] showMessage:NSLocalizedString(@"mining_no_yuanbao",nil) target:nil confirm:nil canel:nil];
        [ShowItem showItemAct:NSLocalizedString(@"mining_no_yuanbao",nil)];
		m_Step = Collect_wait ;
	}
}
-(void)startCollect{
	CGPoint pt = [self getCollectPoint];
	if (pt.x != 0 && pt.y != 0) {
		[[RoleManager shared] movePlayerTo:ccp(pt.x,pt.y) target:self call:@selector(showLoading)];
	}else{
		CCLOG(@"can't find collect point!");
		m_Step = Collect_wait ;
	}
	
}
-(CGPoint)getCollectPoint{
	NSMutableArray *array = [NSMutableArray arrayWithArray:[[MapManager shared] getFunctionRect:@"animation" key:@"minig"]];
	if ([array count] > 0) {
		[array sortUsingFunction:sortArray context:NSStringFromCGPoint([RoleManager shared].player.position)];
		NSMutableArray *points = [NSMutableArray array];
		for (NSValue *value in array) {
			CGPoint pt = getTiledRectCenterPoint([value CGRectValue]);
			[points addObject:[NSValue valueWithCGPoint:pt]];
		}
		CGPoint target = [[RoleManager shared] getFreePoint:points];
		if (target.x == -1 && target.y == -1) {
			int index = getRandomInt(0, points.count - 1);
			target = [[points objectAtIndex:index] CGPointValue];
		}
		return (target);
	}
	return ccp(0, 0);
}

-(void)setCanExit
{
	isCanExit = YES;
}

-(void)updateCanExit
{
	isCanExit = NO;
	[self unschedule:@selector(setCanExit)];
	[self scheduleOnce:@selector(setCanExit) delay:1.0f];
}

#pragma mark -读条，点击屏幕相关
// 显示点击提示
-(void)showLoadingTips{
	if (s_Collect == 0) {
		return;
	}
	
	CGSize winSize = [CCDirector sharedDirector].winSize;
	tapCorrect = 0;
	tapCorrect3 = 0;
	tapCorrect5 = 0;
	if (s_Collect % 10 == 0) {
		tapRemain = 1;
		tapTotal = 1;
		if (s_Collect / 10 == 1) {
			tapCurLength = [[tapLength objectAtIndex:0] floatValue];
		} else {
			tapCurLength = [[tapLength objectAtIndex:2] floatValue];
		}
	} else {
		tapRemain = 10;
		tapTotal = 10;
		if (s_Collect / 10 == 1) {
			tapCurLength = [[tapLength objectAtIndex:1] floatValue];
		} else {
			tapCurLength = [[tapLength objectAtIndex:3] floatValue];
		}
	}
	float start = [[tapRange objectAtIndex:0] floatValue];
	float end = [[tapRange objectAtIndex:1] floatValue] - tapCurLength;
	int range = end - start;
	tapCurStart = arc4random() % range + start;
	
	tapLastPer = -tapCooling;
	
	[self unschedule:@selector(hideDelay)];
	CCNode *node = [self getChildByTag:MiningCount_tag];
	if (!node) {
		CCLabelTTF *countLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
		countLabel.tag = MiningCount_tag;
		countLabel.color = ccc3(255, 255, 255);
		countLabel.anchorPoint = ccp(0, 0.5);
		
		CGPoint pt = [[GameLayer shared] getPlayerViewPosition];
		countLabel.position = ccpAdd(pt, ccp(cFixedScale(260), cFixedScale(180)));
		countLabel.string = [NSString stringWithFormat:@"%d/%d", tapCorrect+tapCorrect3+tapCorrect5, tapTotal];
		[self addChild:countLabel];
	} else {
		[node unscheduleAllSelectors];
		
		node.visible = YES;
		CGPoint pt = [[GameLayer shared] getPlayerViewPosition];
		node.position = ccpAdd(pt, ccp(cFixedScale(260), cFixedScale(180)));
		CCLabelTTF *countLabel = (CCLabelTTF *)node;
		countLabel.string = [NSString stringWithFormat:@"%d/%d", tapCorrect+tapCorrect3+tapCorrect5, tapTotal];
	}
	
	// 添加点击提示
	[self removeChildByTag:MiningClick_tag cleanup:YES];
	CCSprite *clickTips = [CCSprite spriteWithFile:@"images/ui/panel/p37.png"];
	clickTips.position = ccp(winSize.width/2,
							 winSize.height/2+cFixedScale(20));
	clickTips.tag = MiningClick_tag;
	[self addChild:clickTips];
	
	//NSString *clickString = @"|【操作说明】#7dff0a|当|进度条最前端#FF2424|到达加倍区时，点击屏幕收获加倍";
    NSString *clickString = NSLocalizedString(@"mining_info",nil);
	CCSprite *clickSprite = drawString(clickString, CGSizeMake(1000, 0), getCommonFontName(FONT_1), 20, 24, getHexColorByQuality(IQ_WHITE));
	clickSprite.position = ccp(clickTips.contentSize.width/2,
							   clickTips.contentSize.height/2);
	[clickTips addChild:clickSprite];
	
	MiningScrollTouch *touchLayer = [MiningScrollTouch node];
	touchLayer.tag = MiningScrollTouch_tag;
	[self addChild:touchLayer];
}
// 隐藏点击提示
-(void)hideLoadingTips{
	[self scheduleOnce:@selector(hideDelay) delay:2.0f];
	
	CCNode *node = [self getChildByTag:MiningScrollTouch_tag];
	if (node) {
		[node removeFromParentAndCleanup:YES];
		node = nil;
	}
	
	// 添加点击提示
	CCNode *clickTips = [self getChildByTag:MiningClick_tag];
	if (clickTips) {
		[clickTips removeFromParentAndCleanup:YES];
		clickTips = nil;
	}
}
// 延迟隐藏数字
-(void)hideDelay
{
	CCNode *node = [self getChildByTag:MiningCount_tag];
	if (node) {
		node.visible = NO;
	}
}
// 获得当前百分比
-(float)getCurrentPer
{
	CCNode * node = [self getChildByTag:MiningScrollBg_tag];
	if(node){
		CCNode * child = [node getChildByTag:102];
		if(child) {
			float scaleX = MiningScrollWidth/child.contentSize.width;
			float curScaleX = child.scaleX;
			float scalePer = curScaleX/scaleX*100.0f;
			return scalePer;
		}
	}
	
	return 0.0f;
}
// 正确点击一次
-(void)tapCorrectOnce
{
	float per = [self getCurrentPer];
	float curRatio = (per-tapCurStart)/tapCurLength;
	float ratio = [[tapRatio objectAtIndex:0] floatValue];
	float ratio3 = [[tapRatio objectAtIndex:1] floatValue];
	NSString *mulString = nil;
	if (curRatio <= ratio) {
		tapCorrect++;
		//mulString = @"多";
        mulString = NSLocalizedString(@"mining_much",nil);
	} else if (curRatio <= ratio+ratio3) {
		tapCorrect3++;
		//mulString = @"多";
        mulString = NSLocalizedString(@"mining_much",nil);
	} else {
		tapCorrect5++;
		//mulString = @"多";
        mulString = NSLocalizedString(@"mining_much",nil);
	}

	CCLabelTTF *countLabel = (CCLabelTTF *)[self getChildByTag:MiningCount_tag];
	countLabel.string = [NSString stringWithFormat:@"%d/%d", tapCorrect+tapCorrect3+tapCorrect5, tapTotal];
	
	CCNode *node = [self getChildByTag:MiningScrollBg_tag];
	if (node) {
		// 滚动条右边部分
		CCNode *child = [node getChildByTag:103];
		if (child) {
			CGPoint point = ccpAdd(child.position, ccp(child.contentSize.width, cFixedScale(30)));
			//NSString *correctString = [NSString stringWithFormat:@"暴击!%@倍奖励!", mulString];
            NSString *correctString = [NSString stringWithFormat:NSLocalizedString(@"mining_multiple",nil), mulString];
			CCLabelTTF *correctTips = [CCLabelTTF labelWithString:correctString fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(22)];
			correctTips.color = ccc3(255, 0, 0);
			correctTips.position = point;
			[node addChild:correctTips z:100];
			
			[correctTips runAction:[CCSequence actions:[CCMoveBy actionWithDuration:1.6 position:ccp(0, cFixedScale(40))], [CCCallFuncN actionWithTarget:self selector:@selector(removeTips:)], nil]];
		}
	}
}
-(void)removeTips:(CCNode *)node
{
	[node removeFromParentAndCleanup:YES];
	node = nil;
}
// 点击一次
-(void)tapOnce
{
	// 次数
	if (tapRemain <= 0) {
		CCLOG(@"点击次数已用完");
		return;
	}
	
	// 冷却
	float curPer = [self getCurrentPer];
	if (curPer - tapLastPer < tapCooling) {
		CCLOG(@"在冷却中");
		return;
	}
	tapLastPer = curPer;
	
	if (tapCorrect+tapCorrect3+tapCorrect5 >= tapTotal) {
		CCLOG(@"正确次数达上限");
		return;
	}
	
	tapRemain--;
	
	if ([self isTapCorrect]) {
		[self drawClickTrace:YES];
		
		[self tapCorrectOnce];
	} else {
		[self drawClickTrace:NO];
	}
}
// 正确范围点击
-(BOOL)isTapCorrect
{
	float per = [self getCurrentPer];
	if (per>=tapCurStart&&per<=tapCurStart+tapCurLength) {
		return YES;
	}
	return NO;
}
// 点击区域
-(void)drawClickRange
{
	CCNode *node = [self getChildByTag:MiningScrollBg_tag];
	if (node) {
		// 滚动条前面部分
		CCNode *child = [node getChildByTag:101];
		if (child) {
			float width = MiningScrollWidth*tapCurLength*0.01;
			
			float offsetWidth = 0;
			CCNode *right = [node getChildByTag:103];
			if (right) {
				offsetWidth = right.contentSize.width;
			}
			
			CCSprite *rangeSprite = [CCSprite spriteWithFile:@"images/effects/loading2/range.png"];
			rangeSprite.scaleX = width/rangeSprite.contentSize.width;
			rangeSprite.anchorPoint = CGPointZero;
			rangeSprite.position = ccpAdd(child.position, ccp(child.contentSize.width+MiningScrollWidth*tapCurStart*0.01+offsetWidth, -child.contentSize.height/2));
			[node addChild:rangeSprite];
		}
	}
}
// 痕迹
-(void)drawClickTrace:(BOOL)isRight
{
	CCNode *node = [self getChildByTag:MiningScrollBg_tag];
	if (node) {
		// 滚动条右边部分
		CCNode *child = [node getChildByTag:103];
		if (child) {
			CCSprite *lineSprite = [CCSprite spriteWithFile:@"images/effects/loading2/line.png"];
			lineSprite.anchorPoint = ccp(0.5, 0);
			CGPoint point = ccpAdd(child.position, ccp(child.contentSize.width, 0));
			lineSprite.position = ccpAdd(point, ccp(0, -child.contentSize.height/2));
			[node addChild:lineSprite];
			
			if (isRight) {
				AnimationViewer *ringAnima = [AnimationViewer node];
				ringAnima.position = point;
				[node addChild:ringAnima z:100];
				NSString *fullPath = @"images/animations/minig/strike/";
				NSArray *ringFrames = [AnimationViewer loadFileByFileFullPath:fullPath name:@"%d.png"];
				id call = [CCCallFuncN actionWithTarget:self selector:@selector(removeRing:)];
				[ringAnima playAnimation:ringFrames delay:0.08 call:call];
			}
			
			else {
				CCSprite *ring = [CCSprite spriteWithFile:@"images/effects/loading2/ring.png"];
				ring.position = point;
				float duration = 0.5;
				CCScaleTo *scale = [CCScaleTo actionWithDuration:duration scale:1.8];
				CCFadeOut *fadeOut = [CCFadeOut actionWithDuration:duration];
				CCSpawn *ringSpawn = [CCSpawn actions:scale, fadeOut, nil];
				[ring runAction:[CCSequence actions:ringSpawn, [CCCallFuncN actionWithTarget:self selector:@selector(removeRing:)], nil]];
				[node addChild:ring z:100];
			}
		}
	}
}
-(void)removeRing:(CCSprite *)sender
{
	[sender removeFromParentAndCleanup:YES];
	sender = nil;
}
+(BOOL)isShowLoading
{
	if (s_MiningManager) {
		CCNode *node = [s_MiningManager getChildByTag:MiningScrollBg_tag];
		if (node && node.visible) {
			return YES;
		}
	}
	return NO;
}
#pragma mark -读条，点击屏幕相关 end
-(void)showLoading{
	if (bStartCollect) {
		return ;
	}
	[GameEffectsBlockTouck lockScreen];
	// 显示tips
	[self showLoadingTips];
	
	[[GameUI shared] closeMainMenu];
	bStartCollect = YES ;
	[[RoleManager shared].player stopMove];
	NSArray *array = [[MapManager shared] getFunctionRect:@"animation" key:@"stone"];
	if ([array count] <= 0) {
		CCLOG(@"showLoading->array == 0");
		return ;
	}
	
	CGPoint pt_target = CGPointZero;
	if(iPhoneRuningOnGame()){
		pt_target = getTiledRectCenterPoint([[array objectAtIndex:0] CGRectValue]);
	}else{
		pt_target = getTiledRectCenterPoint([[array objectAtIndex:0] CGRectValue]);
	}
	
	[[RoleManager shared].player updateDir:pt_target];
	
	CCSprite * bg = [CCSprite spriteWithFile:@"images/effects/loading2/bg.png"];
	CGPoint pt = [[GameLayer shared] getPlayerViewPosition];
    //进度条的位置
	
	if(iPhoneRuningOnGame()){
		bg.position = ccpAdd(pt, ccp(0, 180/2));
	}else{
		bg.position = ccpAdd(pt, ccp(0, 180));
	}
	
	[self addChild:bg z:INT32_MAX-1 tag:MiningScrollBg_tag];
	CCSprite * p1 = [CCSprite spriteWithFile:@"images/effects/loading2/p-1.png"];
	CCSprite * p2 = [CCSprite spriteWithFile:@"images/effects/loading2/p-2.png"];
	CCSprite * p3 = [CCSprite spriteWithFile:@"images/effects/loading2/p-3.png"];
	p1.anchorPoint = ccp(0,0.5);
	p2.anchorPoint = ccp(0,0.5);
	p3.anchorPoint = ccp(0,0.5);
	[bg addChild:p1 z:1 tag:101];
	[bg addChild:p2 z:1 tag:102];
	[bg addChild:p3 z:1 tag:103];
	
	p1.position = ccp(cFixedScale(37), cFixedScale(47));
	p2.scaleX = 0;
	p2.position = ccp(p1.position.x+p1.contentSize.width,p1.position.y);
	p3.position = ccp(p2.position.x+p2.contentSize.width*p2.scaleX,p2.position.y);
	
	// 背景2
	CCSprite *bg2 = [CCSprite spriteWithFile:@"images/effects/loading2/bg2.png"];
	bg2.anchorPoint = ccp(0, 0.5);
	bg2.position = ccpAdd(p1.position, ccp(10, 0));
	bg2.opacity = 0;
	[bg addChild:bg2];
	[bg2 runAction:[CCSequence actions:[CCDelayTime actionWithDuration:MiningScrollDuration*0.5], [CCFadeIn actionWithDuration:MiningScrollDuration*0.2f], nil]];
	
	// 点击区域
	[self drawClickRange];
	
	[self schedule:@selector(updateLoading:) interval:1/30.0f ];
	float scaleX = MiningScrollWidth / p2.contentSize.width;
	id scale = [CCScaleTo actionWithDuration:MiningScrollDuration scaleX:scaleX scaleY:1];
	[p2 runAction:[CCSequence actions:scale, [CCCallFunc actionWithTarget:self selector:@selector(endLoading)], nil]];
	
//	CCLabelFX * label = [CCLabelFX labelWithString:@"采集玄铁中..."
//										dimensions:CGSizeMake(0,0)
//										 alignment:kCCTextAlignmentCenter
//										  fontName:GAME_DEF_CHINESE_FONT
//										  fontSize:16
//									  shadowOffset:CGSizeMake(0,0)
//										shadowBlur:2.0f];
    CCLabelFX * label = [CCLabelFX labelWithString:NSLocalizedString(@"mining_picking",nil)
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentCenter
										  fontName:GAME_DEF_CHINESE_FONT
										  fontSize:16
									  shadowOffset:CGSizeMake(0,0)
										shadowBlur:2.0f];
	label.anchorPoint = ccp(0.5,0.0);
	label.position = ccp(bg.contentSize.width/2,cFixedScale(66));
	
	[bg addChild:label z:10 tag:200];
	
	[self showCollectAnimation];
}
-(void)updateLoading:(ccTime)time{
	CCNode * node = [self getChildByTag:MiningScrollBg_tag];
	if(node){
		CCNode * p1 = [node getChildByTag:101];
		CCNode * p2 = [node getChildByTag:102];
		CCNode * p3 = [node getChildByTag:103];
		if(p2) p2.position = ccp(p1.position.x+p1.contentSize.width,p1.position.y);
		if(p3) p3.position = ccp(p2.position.x+p2.contentSize.width*p2.scaleX,p2.position.y);
	}
}
-(void)endLoading
{
	[self removeChildByTag:MiningScrollBg_tag cleanup:YES];
	[[[GameLayer shared] content] removeChildByTag:10099 cleanup:YES];
	
	[self unschedule:@selector(updateLoading:)];
	[GameEffectsBlockTouck unlockScreen];
	// 隐藏tips
	[self hideLoadingTips];
	
	if (s_Collect != 0) {
		[self askForCollect:s_Collect];
	}else{
		CCLOG(@"endLoading:s_Collect == 0");
		m_Step = Collect_wait ;
		bStartCollect = NO ;
	}
	CCNode *node=[CCNode node];
	
	if(iPhoneRuningOnGame()){
		[node setPosition:ccp(60/2, 0)];
	}else{
		[node setPosition:ccp(60, 0)];
	}
	
	[back addChild:node];
	//[[Intro share]runIntroTager:node step:INTRO_CLOSE_Mining];
}
-(void)showCollectAnimation{
	NSArray *array = [[MapManager shared] getFunctionRect:@"animation" key:@"stone"];
	if (array.count > 0) {
		CGPoint pt = getTiledRectCenterPoint([[array objectAtIndex:0] CGRectValue]);

		AnimationViewer *ani = [AnimationViewer node];
		ani.tag = 10099;
		ani.anchorPoint = ccp(0.5, 0.5);
		ani.position=pt;
		[[[GameLayer shared] content] addChild:ani z:4];
		
		NSString *fullPath = [NSString stringWithFormat:@"images/animations/minig/1/"];
		NSArray *frams = [AnimationViewer loadFileByFileFullPath:fullPath name:@"%d.png"];
		[ani playAnimation:frams delay:0.1];
	}
}
-(void)showFlyStone{
	if (stones && [stones count] > s_StoneIndex) {
		NSString *iid = [stones objectAtIndex:s_StoneIndex];
		int _id = [iid intValue];
		CCSprite *spr = getItemIcon(_id);
		[[[GameLayer shared] content] addChild:spr z:2];
		spr.scale = 0;
		NSArray *pts = [[MapManager shared] getFunctionRect:@"animation" key:@"stone"];
        if ([pts count]>0) {
            spr.position = getTiledRectCenterPoint([[pts objectAtIndex:0] CGRectValue]);
        }
		CGPoint endPt = [RoleManager shared].player.position;
		
		id acts = [CCSpawn actions:
				   [CCSequence actions:[CCScaleTo actionWithDuration:0.2 scale:1.2],
					[CCScaleTo actionWithDuration:0.2 scale:0],nil],
				   [CCJumpTo actionWithDuration:0.4 position:endPt height:160 jumps:1],
				   nil];
		
		id action = [CCSequence actions:
					 acts,
					 [CCCallFuncN actionWithTarget:self selector:@selector(clearStone:)],
					 nil];
		
		[spr runAction:action];
		s_StoneIndex++;
	}else{
		[self showObtain];
	}
	
}
-(CCSprite*)stoneSprite:(int)_iid count:(int)_count quality:(int)_quality{
	NSString *path = [NSString stringWithFormat:@"images/ui/common/quality%d.png",_quality];
	CCSprite *result = [CCSprite spriteWithFile:path];
	CCSprite *item = getItemIcon(_iid);
	NSString *string = [NSString stringWithFormat:@"%d",_count];
	CCLabelFX *label = [CCLabelFX labelWithString:string
										 fontName:getCommonFontName(FONT_1)
										 fontSize:20
									 shadowOffset:CGSizeMake(2, 2)
									   shadowBlur:0.2
									  shadowColor:ccc4(0, 0, 0, 128)
										fillColor:ccc4(255, 255, 0, 255)];
//    if (iPhoneRuningOnGame()) {
//        label.scale=FONT_SIZE_SCALE;
//    }
	label.anchorPoint=ccp(0.5, 0.5);
	[item addChild:label];
	label.position=ccp(item.contentSize.width,item.contentSize.height);
	[result addChild:item];
	item.position=ccp(result.contentSize.width/2, result.contentSize.height/2);
	NSDictionary *dict =[[GameDB shared] getItemInfo:_iid];
	if (dict) {
		NSString *name = [dict objectForKey:@"name"];
		ccColor3B cl = getColorByQuality(_quality);
		CCLabelFX *_name = [CCLabelFX labelWithString:name
											 fontName:getCommonFontName(FONT_1)
											 fontSize:20
										 shadowOffset:CGSizeMake(2, 2)
										   shadowBlur:0.2
										  shadowColor:ccc4(0, 0, 0, 128)
											fillColor:ccc4BFromccc4F(ccc4FFromccc3B(cl))];
//        if (iPhoneRuningOnGame()) {
//            _name.scale=FONT_SIZE_SCALE;
//        }
		[result addChild:_name];
		_name.position=ccp(result.contentSize.width/2, -16);
	}
	return result;
}

-(void)showObtain{
	[self removeObtain];
	CCSprite *obtain = [CCSprite spriteWithFile:@"images/ui/panel/obtain.png"];
	[self addChild:obtain z:10 tag:8779];
	obtain.anchorPoint=ccp(0.5, 0.5);
	CGSize winSize = [CCDirector sharedDirector].winSize;
	
	//TODO 获得玄铁的框
	if(iPhoneRuningOnGame()){
		obtain.position=ccp(winSize.width/2, winSize.height/2 - 150/2);
	}else{
		obtain.position=ccp(winSize.width/2, winSize.height/2 - 150);
	}
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if (stones && stones.count > 0) {
		for (NSString *key in stones) {
			int _num = [[dict objectForKey:key] intValue];
			_num += 1;
			[dict setObject:[NSNumber numberWithInt:_num] forKey:key];
		}
		//-----------------------------------------------------------
		NSArray *keys = [dict allKeys];
		//
		float _w = 84 * keys.count + 10*(keys.count-1);
		float startX = (obtain.contentSize.width-_w)/2;
		float _y = obtain.contentSize.height/2+16;
		
		for (NSString *iid in keys) {
			int _iid = [iid intValue];
			int count = [[dict objectForKey:iid] intValue];
			NSDictionary *item = [[GameDB shared] getItemInfo:_iid];
			int quality = [[item objectForKey:@"quality"] intValue];
			CCSprite *sprite = [self stoneSprite:_iid count:count quality:quality];
			[obtain addChild:sprite];
			sprite.anchorPoint=ccp(0, 0.5);
			sprite.position=ccp(startX, _y);
			startX += 94 ;
		}
	}
	
	id act1 = [CCDelayTime actionWithDuration:2.5];
	id act2 = [CCCallFunc actionWithTarget:self selector:@selector(removeObtain)];
	id act3 = [CCCallFunc actionWithTarget:self selector:@selector(updateCollect)];
	
	[obtain runAction:[CCSequence actions:act1,act2,act3,nil]];
	
}

-(void)updateCollect{
	bStartCollect = NO ;
}
-(void)removeObtain{
	//清除动作
	m_Step = Collect_wait;
	CCSprite *obtain = (CCSprite*)[self getChildByTag:8779];
	if (obtain) {
		[obtain removeFromParentAndCleanup:YES];
		obtain=nil;
	}
}

-(void)clearStone:(id)sender{
	CCNode *obj = (CCNode*)sender;
	[obj removeFromParentAndCleanup:YES];
}
#pragma mark connect
-(void)askForCollect:(int)_type{
	NSString *str = nil ;
	int itype = _type/10;
	int ibatch = _type%10;
	CCLOG(@"击中 %d %d %d", tapCorrect, tapCorrect3, tapCorrect5);
	str = [NSString stringWithFormat:@"type::%d|isbatch::%d|hit::%d|hit3::%d|hit5::%d",itype,ibatch,tapCorrect,tapCorrect3,tapCorrect5];
	if (str) {
		[GameConnection request:@"mine" format:str target:self call:@selector(doCollect:)];
	}
}

-(void)doCollect:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		
		s_StoneIndex = 0;
		[stones removeAllObjects];
		
		NSDictionary *dict = getResponseData(_sender);
		
		// 显示更新的物品
		NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
		[[AlertManager shared] showReceiveItemWithArray:updateData];
		
		NSArray *items =  [dict objectForKey:@"item"];
		if ([items count] > 0) {
			NSDictionary *gets = [[GameConfigure shared] handleItemsInfo:items];
			NSArray *keys =[gets allKeys];
			for (NSString *_key in keys) {
				int count = [[gets objectForKey:_key] intValue];
				for (int i = 0; i < count; i++) {
					[stones addObject:_key];
				}
			}
			if (stones && [stones count] > 0) {
				float ____time = 0.3f;
				if (s_Collect == 21 || s_Collect == 11) {
					____time = 0.12f;
				}
				[self schedule:@selector(showFlyStone) interval:____time repeat:(stones.count) delay:0.2];
			}
		}
		s_Collect = 0;
		
		NSArray *array = [[MapManager shared] getFunctionRect:@"animation" key:@"stone"];
        CGPoint pt_target = CGPointZero;
        if([array count]>0){
            pt_target = getTiledRectCenterPoint([[array objectAtIndex:0] CGRectValue]);
        }
		[[RoleManager shared].player updateDir:pt_target];
		
		[[GameConfigure shared] updatePackage:dict];
	}
	else {
		CCLOG(@"doCollect:error!");
		[ShowItem showErrorAct:getResponseMessage(_sender)];
		m_Step = Collect_wait;
		bStartCollect = NO ;
	}
}

-(void)stopMiningAction{
	[self unschedule:@selector(updateLoading:)];
	[self unschedule:@selector(endLoading)];
	[self unschedule:@selector(showFlyStone)];
}

@end

