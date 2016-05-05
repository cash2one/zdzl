//
//  JewelMine.m
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "JewelMine.h"
#import "ItemManager.h"
#import "Config.h"
#import "GameMoney.h"
#import "GameMoneyMini.h"
#import "GameConfigure.h"
#import "JewelHelper.h"
#import "AlertManager.h"
#import "ItemIconViewerContent.h"
#import "AnimationViewer.h"
#import "ItemDescribetion.h"

#define DELAY_move			0.8f
#define DELAY_fly			0.8f
#define DELAY_per			0.1f

#define POS_num_X			cFixedScale(15)
#define CGS__itemMgr		CGSizeMake(cFixedScale(276), cFixedScale(368))

#define POS_money			CGPointMake(cFixedScale(40), cFixedScale(490))
#define POS_button			CGPointMake(cFixedScale(263), cFixedScale(42))
#define OFFSET_button_x		cFixedScale(112)

#define POS_stone			CGPointMake(cFixedScale(257), cFixedScale(282))
#define POS_production		CGPointMake(cFixedScale(255), cFixedScale(278))

#define Tag_production		1000


@implementation JewelMine

-(id)init
{
	if (self = [super init]) {
		isRequesting = NO;
		
		stoneDict = [NSMutableDictionary dictionary];
		[stoneDict retain];
		
		totalGoldTimes = [[[[GameDB shared] getGlobalConfig] objectForKey:@"gemMineCoin3Num"] intValue];
		NSString *costString = [[[GameDB shared] getGlobalConfig] objectForKey:@"gemMineCoin3Cost2"];
		NSArray *costArray = [costString componentsSeparatedByString:@"|"];
		startGold = [[costArray objectAtIndex:0] intValue];
		perGold = [[costArray objectAtIndex:1] intValue];
		
		int batchVip = [[[[GameDB shared] getGlobalConfig] objectForKey:@"gemMineVipLevel"] intValue];
		int playerVip = [[GameConfigure shared] getPlayerVipLevel];
		if (playerVip >= batchVip) {
			isBatchActive = YES;
			isBatch = [self getBatchStatus];
		}
		
		batchTimes = 10;
		
		if (iPhoneRuningOnGame()) {
			_itemManagerPos = CGPointMake(358, 46);
			_packageAmountPos = CGPointMake(358, 272);
			_freeTimesPos = ccp(70, 240);
			_goldTimesPos = ccp(180, 240);
		} else {
			_itemManagerPos = CGPointMake(567, 60);
			_packageAmountPos = CGPointMake(567, 500);
			_freeTimesPos = ccp(126, 483);
			_goldTimesPos = ccp(284, 483);
		}
	}
	return self;
}

-(void)dealloc
{
	if (stoneDict) {
		[stoneDict release];
		stoneDict = nil;
	}
	if (updateData) {
		[updateData release];
		updateData = nil;
	}
	
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	freeTimes = 0;
	goldTimes = 0;
	
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/jewel_panel/bg_mine.jpg"];
	mainBg = getSideLayer(bg, cFixedScale(1.5f));
	mainBg.anchorPoint = CGPointZero;
	if (iPhoneRuningOnGame()) {
		mainBg.scale = cFixedScale(550)/mainBg.contentSize.height;
		mainBg.position = ccp(62, 18);
	} else {
		mainBg.position = ccp(27, 19);
	}
	[self addChild:mainBg z:-1];
	
	CCSprite *qualityBg = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
	qualityBg.position = POS_production;
	[mainBg addChild:qualityBg];
	
	[self showPackageBackground];
	[self updatePackageAmount];
	[self showSelectedButton];
		
	CCLabelTTF *_label = nil;
	float fontSize = 16;
	if (iPhoneRuningOnGame()) {
		fontSize = 9;
	}
	
	_label = [CCLabelTTF labelWithString:NSLocalizedString(@"jewel_mine_free_times",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	_label.anchorPoint = ccp(1, 0.5);
	_label.position = _freeTimesPos;
	_label.color = ccc3(237, 228, 205);
	[mainBg addChild:_label];
	
	_label = [CCLabelTTF labelWithString:NSLocalizedString(@"jewel_mine_gold_times",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	_label.anchorPoint = ccp(1, 0.5);
	_label.position = _goldTimesPos;
	_label.color = ccc3(237, 228, 205);
	[mainBg addChild:_label];
	
	freeTimesLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	freeTimesLabel.anchorPoint = ccp(0, 0.5);
	freeTimesLabel.position = _freeTimesPos;
	freeTimesLabel.color = ccc3(254, 234, 131);
	[mainBg addChild:freeTimesLabel];
	
	goldTimesLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	goldTimesLabel.anchorPoint = ccp(0, 0.5);
	goldTimesLabel.position = _goldTimesPos;
	goldTimesLabel.color = ccc3(254, 234, 131);
	[mainBg addChild:goldTimesLabel];
	
	// 显示背包
	itemManager = [ItemManager initWithDimension:CGS__itemMgr];
	itemManager.dataType = DataHelper_jewel;
	itemManager.shiftType = ItemTray_item_stone;
	itemManager.position = _itemManagerPos;
	[self addChild:itemManager z:10];
	
	[itemManager updateContainerWithType:ItemManager_show_type_stone];
	
	[self updateButton];
	
	[self showNormalScene];
	
	[GameConnection request:@"gemMineEnter" data:[NSDictionary dictionary] target:self call:@selector(didGemMineEnter:)];
	
	[GameConnection addPost:ConnPost_request_showInfo target:self call:@selector(requestShowItemTrayDescribe:)];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-180 swallowsTouches:NO];
	
	isCanExit = YES;
	isExiting = NO;
}

-(void)onExit
{
	[JewelHelper stop];
	[GameConnection freeRequest:self];
	[GameConnection removePostTarget:self];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	
	_panelPos = [self convertTouchToNodeSpace:touch];
	
	[self removeChildByTag:2098 cleanup:YES];
	
	return NO ;
}

-(void)requestShowItemTrayDescribe:(NSNotification*)arg{
	NSDictionary * dict = arg.object;
	if (dict) {
		int nid = [[dict objectForKey:@"id"] intValue];
		int typ = [[dict objectForKey:@"type"] intValue];
		[self requestShowItemTrayDescribe:nid type:typ];
	}
}

-(void)requestShowItemTrayDescribe:(int)_nid type:(ItemTray_type)_typ{
	ItemDescribetion* _info = [ItemDescribetion showDescribetion:_nid type:_typ dataType:DataHelper_jewel];
	
	if (_info != nil) {
		
		[self addChild:_info z:INT32_MAX tag:2098];
		
		float __x = _panelPos.x - _itemManagerPos.x ;
		float __y = _panelPos.y - _itemManagerPos.y ;
		
		float __w = ITEMTRAY_SIZE.width;
		float __h = ITEMTRAY_SIZE.height;
		
		int _row = (int)(__y/__h);
		int _col = (int)(__x/__w);
		
		__x = _itemManagerPos.x + __w*_col;
		__y = _itemManagerPos.y + __h*_row;
		
		CGPoint pt = ccp(__x - _info.contentSize.width, __y - _info.contentSize.height/2);
		_info.position = pt ;
		_info.position = getFinalPosition(_info);
	}
}

-(BOOL)getBatchStatus
{
	if (!isBatchActive) return NO;
	
	return [[[GameConfigure shared] getPlayerRecord:@"JewelMineBatch"] boolValue];
}

-(void)setBatchStatus:(BOOL)_isBatch
{
	if (!isBatchActive) return;
	
	isBatch = _isBatch;
	[[GameConfigure shared] recordPlayerSetting:@"JewelMineBatch" value:[NSNumber numberWithBool:_isBatch]];
}

// 右边背包背景
-(void)showPackageBackground{
	CCSprite *packageBg = [CCSprite spriteWithFile:@"images/ui/panel/character_panel/bg-package.png"];
	if (iPhoneRuningOnGame()) {
		packageBg.scale = cFixedScale(550)/packageBg.contentSize.height;
	}
	packageBg.anchorPoint = CGPointZero;
	packageBg.position = ccp(mainBg.position.x+mainBg.contentSize.width*mainBg.scaleX+cFixedScale(6),
							 mainBg.position.y);
	[self addChild:packageBg z:-1];
}

// 包裹容量
-(void)updatePackageAmount
{
	CCLabelTTF *label = (CCLabelTTF*)[self getChildByTag:200];
	if (label == nil) {
		float fontSize=16;
		if (iPhoneRuningOnGame()) {
			fontSize=9;
		}
		label = [CCLabelTTF labelWithString:@"" fontName:@"Verdana-Bold" fontSize:fontSize];
		label.tag = 200;
		label.anchorPoint = ccp(0, 0.5f);
		label.position = _packageAmountPos;
		label.color = ccc3(237, 228, 205);
		[self addChild:label];
	}
	
	int count = [[JewelHelper shared] getPackageAmount:ItemManager_show_type_stone];
	int total = [[JewelHelper shared] getTotalPackageAmount];
	label.string = [NSString stringWithFormat:NSLocalizedString(@"player_capacity",nil),count,total];
}

-(void)updateMineTimes
{
	freeTimesLabel.string = [NSString stringWithFormat:@"%d", freeTimes];
	goldTimesLabel.string = [NSString stringWithFormat:@"%d", goldTimes];
}

-(int)getGoldMineCost
{
	return startGold + perGold * (totalGoldTimes - goldTimes);
}

-(int)getGoldBatchMineCost
{
	int total = 0;
	int first = [self getGoldMineCost];
	for (int i = 0; i < batchTimes; i++) {
		total += first + perGold * i;
	}
	return total;
}

-(void)doBack
{
	if (!isCanExit) return;
	isExiting = YES;
	
	[[Window shared] showWindow:PANEL_JEWEL];
}

-(void)closeWindow
{
	if (!isCanExit) return;
	isExiting = YES;
	
	[super closeWindow];
}

-(void)doSelected
{
	CCNode *node = [mainBg getChildByTag:1998];
	if (node) {
		CCNode *selected = [node getChildByTag:1997];
		if (selected) {
			isBatch = !isBatch;
			selected.visible = isBatch;
			[self setBatchStatus:isBatch];
			
			[self updateButton];
		}
	}
}

-(void)updateSelectedButton:(BOOL)isShow
{
	CCNode *node = [mainBg getChildByTag:1998];
	if (node) {
		node.visible = isShow;
	}
}

-(void)showSelectedButton
{
	if (!isBatchActive) return;
	
	CCSimpleButton *selectedButton = [CCSimpleButton node];
	selectedButton.touchScale = 1.0f;
	selectedButton.contentSize = CGSizeMake(cFixedScale(115), cFixedScale(30));
	selectedButton.position = ccp(mainBg.contentSize.width/2, cFixedScale(90));
	selectedButton.target = self;
	selectedButton.call = @selector(doSelected);
	[mainBg addChild:selectedButton z:1000 tag:1998];
	
	CCSprite *s1 = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle01.png"];
	s1.position = ccp(cFixedScale(8)+s1.contentSize.width/2, selectedButton.contentSize.height/2);
	[selectedButton addChild:s1];
	
	CCSprite *s2 = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle02.png"];
	s2.position = s1.position;
	s2.visible = [self getBatchStatus];
	s2.tag = 1997;
	[selectedButton addChild:s2];
	
	float fontSize = 16;
	if (iPhoneRuningOnGame()) {
		fontSize = 9;
	}
	CCLabelTTF *label = [CCLabelTTF labelWithString:NSLocalizedString(@"jewel_batch_ten",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	label.anchorPoint = ccp(0, 0.5);
	label.position = ccp(s1.position.x+s1.contentSize.width/2+cFixedScale(5), selectedButton.contentSize.height/2);
	label.color = ccc3(237, 228, 205);
	[selectedButton addChild:label];
}

-(CCSimpleButton*)getButton:(BOOL)_isFree :(BOOL)_isBatch
{
	int tag;
	NSString *normal = nil;
	NSString *selected = nil;
	if (_isFree) {
		if (_isBatch) {
			tag = 2002;
			normal = @"images/ui/button/bt_batch_ten_1.png";
			selected = @"images/ui/button/bt_batch_ten_2.png";
		} else {
			tag = 2001;
			normal = @"images/ui/button/bt_mine_free_1.png";
			selected = @"images/ui/button/bt_mine_free_2.png";
		}
	} else {
		if (_isBatch) {
			tag = 2004;
			normal = @"images/ui/button/bt_goldbatch_ten_1.png";
			selected = @"images/ui/button/bt_goldbatch_ten_2.png";
		} else {
			tag = 2003;
			normal = @"images/ui/button/bt_mine_gold_1.png";
			selected = @"images/ui/button/bt_mine_gold_2.png";
		}
	}
	
	CCSimpleButton *simpleButton = [CCSimpleButton spriteWithFile:normal
														   select:selected
														   target:self
															 call:@selector(doGemMine:)];
	simpleButton.tag = tag;
	return simpleButton;
}

-(void)updateButton
{
	[mainBg removeChildByTag:2001];
	[mainBg removeChildByTag:2002];
	[mainBg removeChildByTag:2003];
	[mainBg removeChildByTag:2004];
	
	CCSimpleButton *simpleButton = nil;
	if (freeTimes > 0) {
		simpleButton = [self getButton:YES :isBatch];
	} else if (goldTimes > 0) {
		simpleButton = [self getButton:NO :isBatch];
	}
	if (simpleButton) {
		simpleButton.position = ccp(POS_button.x-OFFSET_button_x, POS_button.y);
		[mainBg addChild:simpleButton];
	}
	
	if (freeTimes <= 0 && goldTimes <= 0) {
		[self updateSelectedButton:NO];
	} else {
		[self updateSelectedButton:YES];
	}
		
	CCNode *node = [mainBg getChildByTag:2000];
	if (node == nil) {
		CCSimpleButton *backButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_return_1.png"
															 select:@"images/ui/button/bt_return_2.png"
															 target:self
															   call:@selector(doBack)];
		backButton.tag = 2000;
		[mainBg addChild:backButton];
	}
	node = [mainBg getChildByTag:2000];
	if (simpleButton) {
		node.position = ccp(POS_button.x+OFFSET_button_x, POS_button.y);
	} else {
		node.position = POS_button;
	}
}

-(void)didGemMineEnter:(id)sender
{
	if (checkResponseStatus(sender)) {
		
		NSDictionary *dict = getResponseData(sender);
		freeTimes = [[dict objectForKey:@"num1"] intValue];
		goldTimes = [[dict objectForKey:@"num2"] intValue];
		
		[self updateMineTimes];
		[self updateButton];
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

-(void)doGemMine:(id)sender
{
	if (isRequesting)	return;
	if (isExiting)		return;
	
	CCNode *node = sender;
	int tag = node.tag;
	
	// 免费开采
	if (tag == 2001) {
		
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:[NSNumber numberWithInt:1] forKey:@"t"];
		[dict setObject:[NSNumber numberWithInt:1] forKey:@"n"];
		[GameConnection request:@"gemMine" data:dict target:self call:@selector(didGemMine:)];
	
		freeTimes--;
		isRequesting = YES;
	}
	// 免费批量开采
	else if	(tag == 2002) {
		if (freeTimes < batchTimes) {
			[ShowItem showItemAct:NSLocalizedString(@"jewel_batch_no_enough",nil)];
			return;
		}
		
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:[NSNumber numberWithInt:1] forKey:@"t"];
		[dict setObject:[NSNumber numberWithInt:batchTimes] forKey:@"n"];
		[GameConnection request:@"gemMine" data:dict target:self call:@selector(didGemMine:)];
		
		freeTimes = freeTimes - batchTimes;
		isRequesting = YES;
	}
	// 元宝开采
	else if (tag == 2003) {
		int cost = [self getGoldMineCost];
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"jewel_mine_tips",nil), cost];
		isCanExit = NO;
		[[AlertManager shared] showMessage:message target:self confirm:@selector(doGemMineConfirm) canel:@selector(doGemMineCancel)];
	}
	// 元宝批量开采
	else if (tag == 2004) {
		if (goldTimes < batchTimes) {
			[ShowItem showItemAct:NSLocalizedString(@"jewel_batch_no_enough",nil)];
			return;
		}
		
		int cost = [self getGoldBatchMineCost];
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"jewel_batch_mine_tips",nil), cost];
		isCanExit = NO;
		[[AlertManager shared] showMessage:message target:self confirm:@selector(doGemBatchMineConfirm) canel:@selector(doGemMineCancel)];
	}
}

-(void)doGemMineCancel
{
	isCanExit = YES;
}

-(void)doGemMineConfirm
{
	int gold = [[GameConfigure shared] getPlayerIngot];
	int cost = [self getGoldMineCost];
	if (gold < cost) {
		[ShowItem showItemAct:NSLocalizedString(@"jewel_gold_no_enough",nil)];
		return;
	}
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:2] forKey:@"t"];
	[dict setObject:[NSNumber numberWithInt:1] forKey:@"n"];
	[GameConnection request:@"gemMine" data:dict target:self call:@selector(didGemMine:)];
	
	goldTimes--;
	isRequesting = YES;
	isCanExit = YES;
}

-(void)doGemBatchMineConfirm
{
	int gold = [[GameConfigure shared] getPlayerIngot];
	int cost = [self getGoldBatchMineCost];
	if (gold < cost) {
		[ShowItem showItemAct:NSLocalizedString(@"jewel_gold_no_enough",nil)];
		return;
	}
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:2] forKey:@"t"];
	[dict setObject:[NSNumber numberWithInt:batchTimes] forKey:@"n"];
	[GameConnection request:@"gemMine" data:dict target:self call:@selector(didGemMine:)];
	
	goldTimes = goldTimes - batchTimes;
	isRequesting = YES;
	isCanExit = YES;
}

-(void)didGemMine:(id)sender
{
	if (checkResponseStatus(sender)) {
		
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			
			if (updateData) {
				[updateData release];
				updateData = nil;
			}
			
			updateData = [NSArray arrayWithArray:[[GameConfigure shared] getPackageAddData:dict]];
			[updateData retain];
			
			[stoneDict removeAllObjects];
			NSArray *items = [dict objectForKey:@"item"];
			if (items) {
				[[JewelHelper shared] addItems:items];
				
				for (NSDictionary *item in items) {
					NSString *key = [[item objectForKey:@"id"] stringValue];
					[stoneDict setObject:item forKey:key];
				}
				
				[self showProductScene];
			} else {
				isRequesting = NO;
			}
		
			[self updateMineTimes];
			[self updateButton];
			
			[[GameConfigure shared] updatePackage:dict];
		}
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
		isRequesting = NO;
	}
}

-(void)showNormalScene
{
	[mainBg removeChildByTag:Tag_production];
	
	CCSprite *icon = [CCSprite spriteWithFile:@"images/animations/mine/0.png"];
	icon.tag = Tag_production;
	icon.position = POS_production;
	[mainBg addChild:icon];
	
	icon.opacity = 0;
}

-(void)showProductScene
{
	[mainBg removeChildByTag:Tag_production];
	
	AnimationViewer *productAnima = [AnimationViewer node];
	productAnima.tag = Tag_production;
	productAnima.position = POS_production;
	[mainBg addChild:productAnima];
	
	NSString *fullPath = [NSString stringWithFormat:@"images/animations/mine/"];
    NSArray *sealFrames = [AnimationViewer loadFileByFileFullPath:fullPath name:@"%d.png"];
	id call = [CCCallFunc actionWithTarget:self selector:@selector(showStoneFly)];
	[productAnima playAnimation:sealFrames delay:0.12 call:call];
}

-(void)showStoneFly
{
	[self showNormalScene];
	[[AlertManager shared] showReceiveItemWithArray:updateData];
	
	int i = 0;
	
	NSDictionary *_stoneDict = [NSDictionary dictionaryWithDictionary:stoneDict];
	for (NSString *key in _stoneDict) {
		int _id = [key intValue];
		int _iconTag = 20000 + _id;
		
		NSDictionary *_item = [_stoneDict objectForKey:key];
		int _iid = [[_item objectForKey:@"iid"] intValue];
		
		CCSprite *icon = [ItemIconViewerContent create:_iid];
		icon.position = ccpAdd(mainBg.position,
							   ccp(POS_stone.x*mainBg.scaleX, POS_stone.y*mainBg.scaleY));
		icon.tag = _iconTag;
		[self addChild:icon z:INT16_MAX+10];
		
		CGPoint jumpPoint = ccp(itemManager.position.x + itemManager.contentSize.width/2,
								itemManager.position.y + itemManager.contentSize.width/2 + cFixedScale(80));
		
		id delayAction = [CCDelayTime actionWithDuration:(DELAY_per*i)];
		id moveAction = [CCMoveBy actionWithDuration:DELAY_move position:ccp(cFixedScale(0), cFixedScale(100))];
		id jumpAction = [CCJumpTo actionWithDuration:DELAY_fly position:jumpPoint height:cFixedScale(100) jumps:1];
		
		[icon runAction:[CCSequence actions:delayAction, moveAction, jumpAction, [CCCallFuncN actionWithTarget:self selector:@selector(endStoneFly:)], nil]];
		
		i++;
	}
}

-(void)endStoneFly:(id)sender
{
	CCNode *node = sender;
	int _uiid = node.tag - 20000;
	
	NSDictionary *item = [[JewelHelper shared] getItemBy:_uiid];
	if (item) {
		[itemManager eventForAddStone:item];
	}
	
	NSString *key = [NSString stringWithFormat:@"%d", _uiid];
	[stoneDict removeObjectForKey:key];
	
	NSArray *allKeys = [stoneDict allKeys];
	if (allKeys.count <= 0) {
		isRequesting = NO;
	}
	
	[self updatePackageAmount];

	[node removeFromParent];
	node = nil;
}

@end
