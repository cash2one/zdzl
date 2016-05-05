//
//  JewelRefine.m
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "JewelRefine.h"
#import "ItemManager.h"
#import "JewelHelper.h"
#import "ModuleTray.h"
#import "CCSimpleButton.h"
#import "ShowItem.h"
#import "AlertManager.h"
#import "ItemDescribetion.h"
#import "ClickAnimation.h"

#define Tag_Tray_main			1999
#define	Tag_Tray_start			2000
#define Tag_back				1998
#define Tag_Tray_Mask_start		2500

#define CGS__itemMgr			CGSizeMake(cFixedScale(276), cFixedScale(368))

#define POS_Jewel				CGPointMake(cFixedScale(278), cFixedScale(307))
#define POS_button				CGPointMake(cFixedScale(263), cFixedScale(38))
#define OFFSET_button_x			cFixedScale(112)

#define POS_Package_Amount_startX		cFixedScale(570)
#define POS_Package_Amount_startY		cFixedScale(500)
#define UI_OFFSET_HEIGHT				cFixedScale(63)

@implementation JewelRefine

-(id)init
{
	if (self = [super init]) {
		isRequesting = NO;
		successRate = 0;
		trayCount = 5;
		
		jewelIdArray = [NSMutableArray array];
		[jewelIdArray retain];
		
		upgradeRateDict = [NSMutableDictionary dictionary];
		[upgradeRateDict retain];
		
		maxLevel = [[[[GameDB shared] getGlobalConfig] objectForKey:@"gemMaxLevel"] intValue];
		
		NSString *_upgradeString = [[[GameDB shared] getGlobalConfig] objectForKey:@"gemUpgradeRate"];
		NSArray *_upgradeArray = [_upgradeString componentsSeparatedByString:@"|"];
		for (NSString *_string in _upgradeArray) {
			NSArray *_array = [_string componentsSeparatedByString:@":"];
			
			NSString *_key = [_array objectAtIndex:0];
			NSMutableArray *_finalArray = [NSMutableArray arrayWithArray:_array];
			[_finalArray removeObjectAtIndex:0];
			
			[upgradeRateDict setObject:_finalArray forKey:_key];
		}
		
		if (iPhoneRuningOnGame()) {
			_itemManagerPos = CGPointMake(358, 46);
			_packageAmountPos = CGPointMake(358, 272);
		} else {
			_itemManagerPos = CGPointMake(567, 60);
			_packageAmountPos = CGPointMake(567, 500);
		}
	}
	return self;
}

-(void)dealloc
{
	if (jewelIdArray) {
		[jewelIdArray release];
		jewelIdArray = nil;
	}
	
	if (upgradeRateDict) {
		[upgradeRateDict release];
		upgradeRateDict = nil;
	}
	
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/jewel_panel/bg_refine.jpg"];
	CCLayer *_mainBg = getSideLayer(bg, cFixedScale(1.5f));
	_mainBg.anchorPoint = CGPointZero;
	if (iPhoneRuningOnGame()) {
		_mainBg.scale = cFixedScale(550)/_mainBg.contentSize.height;
		_mainBg.position = ccp(62, 18);
	} else {
		_mainBg.position = ccp(27, 19);
	}
	[self addChild:_mainBg z:-1];
	
	mainBg = [CCLayer node];
	mainBg.anchorPoint = _mainBg.anchorPoint;
	mainBg.position = _mainBg.position;
	mainBg.contentSize = _mainBg.contentSize;
	mainBg.scale = _mainBg.scale;
	[self addChild:mainBg z:INT16_MAX-5];
	
	float tipsSize = 14;
	if (iPhoneRuningOnGame()) {
		tipsSize = 8;
	}
	CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"jewel_refine_tips",nil) fontName:getCommonFontName(FONT_1) fontSize:tipsSize];
	tipsLabel.anchorPoint = ccp(1, 1);
	tipsLabel.position = ccp(mainBg.contentSize.width-cFixedScale(15), mainBg.contentSize.height-cFixedScale(8));
	tipsLabel.color = ccc3(238, 228, 207);
	[mainBg addChild:tipsLabel];
	
	[self showPackageBackground];
	[self updatePackageAmount];
	
	// 成功率
	CCSprite *successBg = [CCSprite spriteWithFile:@"images/effects/loading/bg.png"];
	successBg.tag = 500;
	successBg.anchorPoint = CGPointZero;
	successBg.position = ccp(mainBg.contentSize.width/2-successBg.contentSize.width/2, cFixedScale(70));
	[mainBg addChild:successBg z:10];
	
	// 中间珠宝托盘
	ModuleTray *mainTray = [ModuleTray create:ItemTray_item_jewel];
	mainTray.position = POS_Jewel;
	mainTray.tag = Tag_Tray_main;
	mainTray.takeOffTarget = self;
	mainTray.takeOffCall = @selector(doTakeOff:);
	[mainBg addChild:mainTray];
	
	// 托盘
	for (int i = 0; i < trayCount; i++) {
		
		ModuleTray *tray = [ModuleTray create:ItemTray_item_jewel];
		tray.position = [self getTrayPositionWithIndex:i+1];
		tray.tag = Tag_Tray_start+i;
		tray.takeOffTarget = self;
		tray.takeOffCall = @selector(doTakeOff:);
		[mainBg addChild:tray];
		
	}
	
	if (![self isExistJewel]) {
		[self addMask];
	}
	
	itemManager = [ItemManager initWithDimension:CGS__itemMgr];
	itemManager.dataType = DataHelper_jewel;
	itemManager.shiftType = ItemTray_item_jewel;
	itemManager.shiftTarget = self;
	itemManager.shiftCall = @selector(requestShiftWithDictionary:);
	itemManager.position = _itemManagerPos;
	[self addChild:itemManager z:10];
	
	[itemManager updateContainerWithType:ItemManager_show_type_jewel];
	
	[self updateAll];
	
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
	
	int count = [[JewelHelper shared] getPackageAmount:ItemManager_show_type_jewel];
	int total = [[JewelHelper shared] getTotalPackageAmount];
	label.string = [NSString stringWithFormat:NSLocalizedString(@"player_capacity",nil),count,total];
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

-(void)updateButton
{
	BOOL isCanUse = (BOOL)(successRate > 0);
	
	[mainBg removeChildByTag:10001];
	[mainBg removeChildByTag:10002];
	
	CCSimpleButton *simpleButton = nil;
	if (isCanUse) {
		simpleButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_refine_1.png"
											   select:@"images/ui/button/bt_refine_2.png"
											   target:self
												 call:@selector(doRefine:)];
		simpleButton.tag = 10001;
	} else {
		simpleButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_refine_3.png"
											   select:@"images/ui/button/bt_refine_3.png"
											   target:self
												 call:@selector(doRefine:)];
		simpleButton.tag = 10002;
	}
	if (simpleButton) {
		simpleButton.position = ccp(POS_button.x-OFFSET_button_x, POS_button.y);
		[mainBg addChild:simpleButton];
	}
	
	CCNode *node = [mainBg getChildByTag:Tag_back];
	if (node == nil) {
		CCSimpleButton *backButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_return_1.png"
															 select:@"images/ui/button/bt_return_2.png"
															 target:self
															   call:@selector(doBack)];
		backButton.tag = Tag_back;
		backButton.position = ccp(POS_button.x+OFFSET_button_x, POS_button.y);
		[mainBg addChild:backButton];
	}
}

// _index从0开始
-(int)getSuccessRate:(int)_rate index:(int)_index
{
	NSString *key = [NSString stringWithFormat:@"%d", _rate];
	NSArray *array = [upgradeRateDict objectForKey:key];
	if (array) {
		return [[array objectAtIndex:_index] intValue];
	}
	
	return 0;
}

-(int)getSuccessRate
{
	ModuleTray *mainTray = (ModuleTray*)[mainBg getChildByTag:Tag_Tray_main];
	if (mainTray.uxid <= 0) {
		return 0;
	}
	
	NSDictionary *jewel = [[JewelHelper shared] getJewelBy:mainTray.uxid];
	if (jewel == nil) {
		return 0;
	}
	
	float totalRate = [[jewel objectForKey:@"upSucc"] floatValue];
	
	int level = [[jewel objectForKey:@"level"] intValue];
	int gid = [[jewel objectForKey:@"gid"] intValue];
	NSDictionary *dict = [[JewelHelper shared] getJewelInfoBy:gid];
	int quality = [[dict objectForKey:@"quality"] intValue];
	
	NSMutableArray *rateArray = [NSMutableArray array];
	
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		if (tray.uxid <= 0) {
			continue;
		}
		
		NSDictionary *_jewel = [[JewelHelper shared] getJewelBy:tray.uxid];
		NSDictionary *_dict = [[JewelHelper shared] getJewelInfoBy:tray.xid];
		
		int _level = [[_jewel objectForKey:@"level"] intValue];
		int _quality = [[_dict objectForKey:@"quality"] intValue];
		
		NSDictionary *_upDict = [[GameDB shared] getGemUpRate:_quality startLevel:_level to:quality toLevel:level];
		if (_upDict) {
			int _rate = [[_upDict objectForKey:@"succ"] intValue];
			
			BOOL isAdd = NO;
			for (int i = 0; i < rateArray.count; i++) {
				int __rate = [[rateArray objectAtIndex:i] intValue];
				if (_rate >= __rate) {
					[rateArray insertObject:[NSNumber numberWithInt:_rate] atIndex:i];
					isAdd = YES;
					break;
				}
			}
			if (!isAdd) {
				[rateArray addObject:[NSNumber numberWithInt:_rate]];
			}
		}
	}
	
	if (rateArray.count > 0) {
		int _rate = [[rateArray objectAtIndex:0] intValue];
		if (_rate >= 100) {
			return 100;
		}
	}
	
	for (int i = 0; i < rateArray.count; i++) {
		int _rate = [[rateArray objectAtIndex:i] intValue];
		totalRate += [self getSuccessRate:_rate index:i];
	}
	
	return MIN(MAX(0, totalRate), 100);
}

-(void)updateSuccessRate
{
	successRate = [self getSuccessRate];
	
	CCNode *node = [mainBg getChildByTag:500];
	if (node) {
		[node removeAllChildren];
		
		if (successRate > 0) {
			node.visible = YES;
			
			float totalWidth = cFixedScale(382.0f);
			float currentWidth = totalWidth * successRate / 100.0f;
			
			CCSprite *s1 = [CCSprite spriteWithFile:@"images/effects/loading/p-1-m.png"];
			s1.anchorPoint = ccp(0, 0);
			s1.position = ccp(cFixedScale(29), cFixedScale(19));
			[node addChild:s1];
			
			CCSprite *s2 = [CCSprite spriteWithFile:@"images/effects/loading/p-2-m.png"];
			s2.anchorPoint = ccp(0, 0);
			s2.position = ccp(s1.position.x+s1.contentSize.width, s1.position.y);
			s2.scaleX = currentWidth / s2.contentSize.width;
			[node addChild:s2];
			
			CCSprite *s3 = [CCSprite spriteWithFile:@"images/effects/loading/p-3-m.png"];
			s3.anchorPoint = ccp(0, 0);
			s3.position = ccp(s1.position.x+s1.contentSize.width+currentWidth, s1.position.y);
			[node addChild:s3];
			
			float fontSize = 14;
			if (iPhoneRuningOnGame()) {
				fontSize = 9;
			}
			
			CCLabelTTF *label = [CCLabelTTF labelWithString:NSLocalizedString(@"jewel_success_rate",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
			label.anchorPoint = ccp(1, 0.5);
			label.position = ccp(node.contentSize.width/2, cFixedScale(5));
			[node addChild:label];
			
			CCLabelTTF *rateLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d%%", successRate] fontName:getCommonFontName(FONT_1) fontSize:fontSize];
			rateLabel.anchorPoint = ccp(0, 0.5);
			rateLabel.position = ccp(node.contentSize.width/2, cFixedScale(5));
			rateLabel.color = ccc3(254, 235, 127);
			[node addChild:rateLabel];
		} else {
			node.visible = NO;
		}
	}
}

-(void)updateAll
{
	[self updateSuccessRate];
	[self updateButton];
	[self updatePackageAmount];
}

-(CGPoint)getTrayPositionWithIndex:(int)_index
{
	CGPoint point;
	switch (_index) {
		case 1:
			point = ccp(cFixedScale(192), cFixedScale(409));
			break;
		case 2:
			point = ccp(cFixedScale(364), cFixedScale(409));
			break;
		case 3:
			point = ccp(cFixedScale(410), cFixedScale(247));
			break;
		case 4:
			point = ccp(cFixedScale(278), cFixedScale(177));
			break;
		case 5:
			point = ccp(cFixedScale(150), cFixedScale(247));
			break;
			
		default:
			point = ccp(0, 0);
			break;
	}
	return point;
}

-(id)addJewelWithUjid:(int)__ujid tag:(int)__tag
{
	ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:__tag];
	if (tray) {
		
		if (tray.uxid > 0) {
			[ShowItem showItemAct:NSLocalizedString(@"jewel_had_other",nil)];
			return [NSNumber numberWithBool:NO];
		}
		
		if (__tag == Tag_Tray_main) {
			
			if (![self isExistJewel]) {
				[self removeMask];
			}
			
			NSDictionary *_data = [[JewelHelper shared] getJewelBy:__ujid];
			[tray updateWithDictionary:_data];
			[self updateAll];
			
			[itemManager eventForDeleteItemTray:__ujid type:ItemTray_item_jewel];
			
			return [NSNumber numberWithBool:YES];
			
		} else {
			if (![self isExistJewel]) {
				return [NSNumber numberWithBool:NO];
			}
			
			NSDictionary *_data = [[JewelHelper shared] getJewelBy:__ujid];
			[tray updateWithDictionary:_data];
			[self updateAll];
			
			[itemManager eventForDeleteItemTray:__ujid type:ItemTray_item_jewel];
			
			return [NSNumber numberWithBool:YES];
		}
	}
	return [NSNumber numberWithBool:NO];
}

-(id)requestShiftWithDictionary:(NSDictionary *)_dict
{
	if (_dict == nil || isRequesting) return [NSNumber numberWithBool:NO];
	
	CGPoint _pt = [[_dict objectForKey:@"point"] CGPointValue];
	
	int _ujid = [[_dict objectForKey:@"id"] intValue];
	if (_ujid <= 0) return [NSNumber numberWithBool:NO];
	
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		
		CGPoint pt = [tray.parent convertToWorldSpace:tray.position];
		float _dis = ccpDistance(pt, _pt);
		if (_dis <= tray.contentSize.width/2) {
			
			// 不存在珠宝的时候，该槽不可操作
			if (![self isExistJewel]) {
				break;
			}
			return [self addJewelWithUjid:_ujid tag:i];
			
		}
	}
	
	ModuleTray *mainTray = (ModuleTray*)[mainBg getChildByTag:Tag_Tray_main];
	CGPoint pt = [mainTray.parent convertToWorldSpace:mainTray.position];
	float _dis = ccpDistance(pt, _pt);
	if (_dis <= mainTray.contentSize.width/2) {
		
		return [self addJewelWithUjid:_ujid tag:Tag_Tray_main];
		
	}
	
	// 如果没拖拽到槽中，则返回一个合适的槽的tag
	int __tag = [self getUsableTag:_pt];
	if (__tag == -1) {
		[ShowItem showItemAct:NSLocalizedString(@"jewel_jewel_full",nil)];
		return [NSNumber numberWithBool:NO];
	} else if (__tag == -2) {
		return [NSNumber numberWithBool:NO];
	} else {
		return [self addJewelWithUjid:_ujid tag:__tag];
	}
}

// 获取可用的tag
-(int)getUsableTag:(CGPoint)_pt
{
	CGPoint pt = [mainBg.parent convertToWorldSpace:mainBg.position];
	CGPoint finalPoint = ccpSub(_pt, pt);
	
	CGRect rect = CGRectMake(0, 0, mainBg.contentSize.width*mainBg.scaleX, mainBg.contentSize.height*mainBg.scaleY);
	// 拖放到镶嵌相关层
	if (CGRectContainsPoint(rect, finalPoint)) {
		
		ModuleTray *mainTray = (ModuleTray*)[mainBg getChildByTag:Tag_Tray_main];
		if (mainTray.uxid <= 0) {
			return Tag_Tray_main;
		}
		
		for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
			ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
			if (tray.uxid <= 0) {
				return i;
			}
		}
		return -1;
	}
	return -2;
}

-(void)doTakeOff:(NSMutableDictionary*)_dict
{
	if (isRequesting) return;
	
	int _ujid = [[_dict objectForKey:@"uxid"] intValue];
	BOOL isFind = NO;
	
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		if (tray.uxid == _ujid) {
			isFind = YES;
			[tray doTakeOffItem];
			break;
		}
	}
	
	if (!isFind) {
		ModuleTray *mainTray = (ModuleTray*)[mainBg getChildByTag:Tag_Tray_main];
		if (mainTray.uxid == _ujid) {
			isFind = YES;
			[mainTray doTakeOffItem];
		}
	}
	
	if (isFind) {
		[self updateAll];
		if (itemManager) {
			NSDictionary *_dict = [[JewelHelper shared] getJewelBy:_ujid];
			[itemManager eventForAddJewel:_dict];
		}
	}
	
	if (![self isExistJewel]) {
		[self addMask];
	}
}

-(BOOL)isExistJewel
{
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		if (tray && tray.uxid > 0) return YES;
	}

	ModuleTray *mainTray = (ModuleTray*)[mainBg getChildByTag:Tag_Tray_main];
	if (mainTray && mainTray.uxid > 0) return YES;
	
	return NO;
}

-(BOOL)isExistMainJewel
{
	ModuleTray *mainTray = (ModuleTray*)[mainBg getChildByTag:Tag_Tray_main];
	if (mainTray && mainTray.uxid > 0) return YES;
	
	return NO;
}

-(void)addMask
{
	for (int i = 0; i < trayCount; i++) {
		int tag = Tag_Tray_Mask_start+i;
		CCNode *node = [mainBg getChildByTag:tag];
		if (node) {
			node.visible = YES;
		} else {
			CCSprite *sprite = [CCSprite spriteWithFile:@"images/ui/common/qualityMask.png"];
			sprite.position = [self getTrayPositionWithIndex:i+1];
			[mainBg addChild:sprite z:INT16_MAX+50 tag:tag];
		}
	}
}

-(void)removeMask
{
	for (int i = 0; i < trayCount; i++) {
		int tag = Tag_Tray_Mask_start+i;
		CCNode *node = [mainBg getChildByTag:tag];
		if (node) {
			node.visible = NO;
		}
	}
}

-(void)doRefine:(id)sender
{
	if (isRequesting)	return;
	if (isExiting)		return;
	
	CCNode *node = sender;
	int tag = node.tag;
	
	if (tag == 10002) return;
	
	// 先更新一次
	[self updateAll];
	if (successRate <= 0) return;
	
	[jewelIdArray removeAllObjects];
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		if (tray.uxid > 0) {
			[jewelIdArray addObject:[NSNumber numberWithInt:tray.uxid]];
		}
	}
	
	ModuleTray *mainTray = (ModuleTray*)[mainBg getChildByTag:Tag_Tray_main];
	if (!mainTray || mainTray.uxid <= 0) return;
	
	// 珠宝达最大等级不可升级
	NSDictionary *jewelInfo = [[JewelHelper shared] getJewelBy:mainTray.uxid];
	if (jewelInfo) {
		int level = [[jewelInfo objectForKey:@"level"] intValue];
		if (level >= maxLevel) {
			[ShowItem showItemAct:NSLocalizedString(@"jewel_had_maxlevel",nil)];
			return;
		}
	}
	
	BOOL isRecordUpgrade = [[[GameConfigure shared] getPlayerRecord:@"client.jewel.upgrade"] boolValue];
	if (isRecordUpgrade) {
		[self doRefineConfirm];
	} else {
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"jewel_refine_success_tips",nil), successRate];
		isCanExit = NO;
		[[AlertManager shared] showMessageWithSetting:message
											   target:self
											  confirm:@selector(doRefineConfirm)
												canel:@selector(doRefineCancel)
												  key:@"client.jewel.upgrade"];
	}
}

-(void)doRefineCancel
{
	isCanExit = YES;
}

-(void)doRefineConfirm
{
	ModuleTray *mainTray = (ModuleTray*)[mainBg getChildByTag:Tag_Tray_main];
	if (!mainTray || mainTray.uxid <= 0) return;
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:mainTray.uxid] forKey:@"gid"];
	[dict setObject:jewelIdArray forKey:@"stuff"];
	[GameConnection request:@"gemUpgrade" data:dict target:self call:@selector(didRefine::) arg:dict];
	
	isRequesting = YES;
	isCanExit = YES;
}

-(void)didRefine:(id)sender :(NSDictionary*)_dict
{
	if (checkResponseStatus(sender)) {
		
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			
			if (changeDict) {
				[changeDict release];
				changeDict = nil;
			}
			changeDict = [NSDictionary dictionaryWithDictionary:dict];
			[changeDict retain];
			
			if (otherDict) {
				[otherDict release];
				otherDict = nil;
			}
			otherDict = [NSDictionary dictionaryWithDictionary:_dict];
			[otherDict retain];
			
			// 没有其他珠宝协助升级
			BOOL isLevelSelf = YES;
			
			// 清空升级材料托盘
			BOOL isFirst = YES;
			for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
				ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
				if (tray.uxid > 0) {
					isLevelSelf = NO;
					
					// 动画效果
					CGPoint startPoint = tray.position;
					CGPoint endPoint = POS_Jewel;
					
					CGPoint middlePoint = ccpMidpoint(startPoint, endPoint);
					
					NSString *path = @"images/animations/jewel/refine/ref/";
					CCNode *effect = nil;
					if (isFirst) {
						id call = [CCCallFunc actionWithTarget:self selector:@selector(showChange)];
						effect = [ClickAnimation showInLayer:mainBg z:INT16_MAX+50 tag:0 call:call point:middlePoint path:path loop:NO];
						
						isFirst = NO;
					} else {
						effect = [ClickAnimation showInLayer:mainBg z:INT16_MAX+50 tag:0 call:nil point:middlePoint path:path loop:NO];
					}
					effect.rotation = -1*getAngle(startPoint, endPoint);
					
				}
			}
			
			if (isLevelSelf) {
				[self showChange];
			}
		}
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
		isRequesting = NO;
	}
}

-(void)showChange
{
	int isSuccess = [[changeDict objectForKey:@"rs"] intValue];
	[ShowItem showItemAct:(isSuccess==1)?NSLocalizedString(@"jewel_levelup_success",nil):NSLocalizedString(@"jewel_levelup_fail",nil)];
	
	NSString *path = nil;
	if (isSuccess) {
		path = @"images/animations/jewel/refine/suc/";
	} else {
		path = @"images/animations/jewel/refine/fail/";
	}
	[ClickAnimation showInLayer:mainBg z:INT16_MAX+51 tag:0 call:nil point:POS_Jewel path:path loop:NO];
	
	// 清空升级材料托盘
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		if (tray.uxid > 0) {
			[tray doTakeOffItem];
		}
	}
	
	// 删除相关材料珠宝
	[[JewelHelper shared] removeJewelsWithArray:[otherDict objectForKey:@"stuff"]];
	
	// 更新升级的珠宝
	NSDictionary *jewel = nil;
	NSDictionary *info = [changeDict objectForKey:@"info"];
	if (info) {
		NSArray *jewels = [info objectForKey:@"gem"];
		if (jewels) {
			jewel = [jewels objectAtIndex:0];
			
			int _ujid = [[otherDict objectForKey:@"gid"] intValue];
			[[JewelHelper shared] updateJewel:_ujid :jewel];
			
			// 更新升级珠宝信息
			ModuleTray *mainTray = (ModuleTray*)[mainBg getChildByTag:Tag_Tray_main];
			if (mainTray) {
				[mainTray updateWithDictionary:jewel];
			}
		}
	}
	
	[self updateAll];
	
	isRequesting = NO;
}

@end
