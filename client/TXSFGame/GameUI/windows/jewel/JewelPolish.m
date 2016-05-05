//
//  JewelPolish.m
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "JewelPolish.h"
#import "ItemManager.h"
#import "ModuleTray.h"
#import "ShowItem.h"
#import "JewelHelper.h"
#import "JewlIconViewerContent.h"
#import "ItemIconViewerContent.h"
#import "ItemDescribetion.h"
#import "ClickAnimation.h"

#define Tag_back						300
#define Tag_Tray_start					2000

#define DELAY_move						1.0f
#define DELAY_scale						0.2f
#define DELAY_jump						0.8f

#define POS_effect						ccp(cFixedScale(266), cFixedScale(214))
#define POS_Jewel						ccp(cFixedScale(266), cFixedScale(221))
#define POS_button						CGPointMake(cFixedScale(263), cFixedScale(38))
#define OFFSET_button_x					cFixedScale(112)

#define POS_num_X						cFixedScale(15)
#define CGS__itemMgr					CGSizeMake(cFixedScale(276), cFixedScale(368))

#define POS_Attr_bg						ccp(cFixedScale(100), cFixedScale(100))

@implementation JewelPolish

-(id)init
{
	if (self = [super init]) {
		stoneIdArray = [NSMutableArray array];
		[stoneIdArray retain];
		
		trayCount = 4;
		isRequesting = NO;
		
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
	if (stoneIdArray) {
		[stoneIdArray release];
		stoneIdArray = nil;
	}
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/jewel_panel/bg_polish.jpg"];
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
	
	CCSprite *qualityBg = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
	qualityBg.position = POS_Jewel;
	[mainBg addChild:qualityBg];
	
	float tipsSize = 14;
	if (iPhoneRuningOnGame()) {
		tipsSize = 8;
	}
	CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"jewel_polish_tips",nil) fontName:getCommonFontName(FONT_1) fontSize:tipsSize];
	tipsLabel.anchorPoint = ccp(1, 1);
	tipsLabel.position = ccp(mainBg.contentSize.width-cFixedScale(15), mainBg.contentSize.height-cFixedScale(8));
	tipsLabel.color = ccc3(238, 228, 207);
	[mainBg addChild:tipsLabel];
	
	[self showPackageBackground];
	[self updatePackageAmount];
	
	// 属性
	CCLayer *layer = [CCLayerColor layerWithColor:ccc4(80, 80, 80, 0) width:cFixedScale(400) height:cFixedScale(60)];
	layer.tag = 500;
	layer.position = ccp(mainBg.contentSize.width/2-layer.contentSize.width/2, cFixedScale(297)-layer.contentSize.height/2);
	[mainBg addChild:layer z:10];
	
	// 托盘
	for (int i = 0; i < trayCount; i++) {
		
		ModuleTray *tray = [ModuleTray create:ItemTray_item_stone];
		tray.position = [self getTrayPosition:i];
		tray.tag = Tag_Tray_start+i;
		tray.takeOffTarget = self;
		tray.takeOffCall = @selector(doTakeOff:);
		[mainBg addChild:tray];
		
	}
	
	// 显示背包
	itemManager = [ItemManager initWithDimension:CGS__itemMgr];
	itemManager.dataType = DataHelper_jewel;
	itemManager.shiftType = ItemTray_item_stone;
	itemManager.shiftTarget = self;
	itemManager.shiftCall = @selector(requestShiftWithDictionary:);
	itemManager.position = _itemManagerPos;
	[self addChild:itemManager z:10];
	
	[itemManager updateContainerWithType:ItemManager_show_type_stone];
	
	[self updateButton];
	
	[GameConnection addPost:ConnPost_request_showInfo target:self call:@selector(requestShowItemTrayDescribe:)];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-180 swallowsTouches:NO];
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

-(CGPoint)getTrayPosition:(int)index
{
	CGPoint point = CGPointZero;
	switch (index) {
		case 0:
			point = ccp(cFixedScale(128), cFixedScale(341));
			break;
		case 1:
			point = ccp(cFixedScale(218), cFixedScale(389));
			break;
		case 2:
			point = ccp(cFixedScale(312), cFixedScale(390));
			break;
		case 3:
			point = ccp(cFixedScale(401), cFixedScale(338));
			break;
			
		default:
			break;
	}
	return point;
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

-(void)doBack
{
	[[Window shared] showWindow:PANEL_JEWEL];
}

-(void)updateButton
{
	BOOL isCanUse = YES;
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		if (tray.uxid <= 0) {
			isCanUse = NO;
			break;
		}
	}
	
	[mainBg removeChildByTag:10001];
	[mainBg removeChildByTag:10002];
	
	CCSimpleButton *simpleButton = nil;
	if (isCanUse) {
		simpleButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_polish_1.png"
											   select:@"images/ui/button/bt_polish_2.png"
											   target:self
												 call:@selector(doPolish:)];
		simpleButton.tag = 10001;
	} else {
		simpleButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_polish_3.png"
											   select:@"images/ui/button/bt_polish_3.png"
											   target:self
												 call:@selector(doPolish:)];
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

-(void)doTakeOff:(NSMutableDictionary*)_dict
{
	if (isRequesting) return;
	
	int _uiid = [[_dict objectForKey:@"uxid"] intValue];
	
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		if (tray.uxid == _uiid) {
			[tray doTakeOffItem];
			[self updateButton];
			
			if (itemManager) {
				NSDictionary *_dict = [[JewelHelper shared] getItemBy:_uiid];
				[itemManager eventForAddStone:_dict];
			}
			break;
		}
	}
}

-(void)updateAttributeInfo:(NSDictionary*)_dict
{
	if (_dict == nil) return;
	
	CCNode *layer = [mainBg getChildByTag:500];
	if (layer) {
		[layer removeAllChildren];
		[self unschedule:@selector(removeAttributeLabel)];
	}
	
	int gid = [[_dict objectForKey:@"gid"] intValue];
	int level = [[_dict objectForKey:@"level"] intValue];
	NSDictionary* jewelInfo = [[GameDB shared] getJewelLevelInfoWithLevel:gid level:level];
	if (jewelInfo) {
		BaseAttribute attribute = BaseAttributeFromDict(jewelInfo);
		NSString *string = BaseAttributeToDisplayStringWithOutZero(attribute);
		NSArray *array = [string componentsSeparatedByString:@"|"];
		
		NSMutableArray *_array = [NSMutableArray array];
		for (NSString *_string in array) {
			NSArray *_a = [_string componentsSeparatedByString:@":"];
			if (_a.count >= 2) {
				NSString *_s = [NSString stringWithFormat:@"%@|+%@#30B652|", [_a objectAtIndex:0], [_a objectAtIndex:1]];
				[_array addObject:_s];
			}
		}
		NSString *_attribute = [_array componentsJoinedByString:@" "];
		
		NSDictionary *jewelDict = [[JewelHelper shared] getJewelInfoBy:gid];
		if (jewelDict) {
			NSString *name = [jewelDict objectForKey:@"name"];
			ItemQuality quality = [[jewelDict objectForKey:@"quality"] intValue];
			
			float fontSize = 16;
			NSString *message = [NSString stringWithFormat:@"|%@%@| Lv%d： %@", name, getHexColorByQuality(quality), level, _attribute];
			CCSprite *label = drawString(message, CGSizeMake(400, 0), getCommonFontName(FONT_1), fontSize, fontSize+cFixedScale(4), @"#F0E4D0");
			label.position = ccp(layer.contentSize.width/2, layer.contentSize.height/2);
			[layer addChild:label];
			
			[self scheduleOnce:@selector(removeAttributeLabel) delay:6.0f];
		}
	}
}

-(void)removeAttributeLabel
{
	CCNode *layer = [mainBg getChildByTag:500];
	if (layer) {
		[layer removeAllChildren];
	}
}

-(void)showJewel:(int)jid isHadRate:(BOOL)isHadRate
{
	NSString *path = @"images/animations/jewel/polish/u/";
	[ClickAnimation showInLayer:mainBg z:INT16_MAX+50 tag:0 call:nil point:POS_Jewel path:path loop:NO];
	
	JewlIconViewerContent *icon = [JewlIconViewerContent create:jid];
	icon.isHadRate = isHadRate;
	icon.scale = 1.0f;
	icon.position = ccp(mainBg.position.x + POS_Jewel.x * mainBg.scaleX,
						mainBg.position.y + POS_Jewel.y * mainBg.scaleY);
	[self addChild:icon z:INT16_MAX+10];
	
	CGPoint jumpPoint = ccp(itemManager.position.x + itemManager.contentSize.width/2,
							itemManager.position.y + itemManager.contentSize.width/2 + cFixedScale(80));
	
	id scaleAction = [CCScaleTo actionWithDuration:DELAY_scale scale:1.0f];
	id jumpAction = [CCJumpTo actionWithDuration:DELAY_jump position:jumpPoint height:cFixedScale(100) jumps:1];
	
	[icon runAction:[CCSequence actions:scaleAction, jumpAction, [CCCallFuncN actionWithTarget:self selector:@selector(doMoveDone:)], nil]];
}

-(id)addStoneWithUiid:(int)__uiid tag:(int)__tag
{
	ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:__tag];
	
	if (tray.uxid > 0) {
		[ShowItem showItemAct:NSLocalizedString(@"jewel_had_other_stone",nil)];
		return [NSNumber numberWithBool:NO];
	} else {
		NSDictionary *_data = [[JewelHelper shared] getItemBy:__uiid];
		[tray updateWithDictionary:_data];
		[self updateButton];
		
		[itemManager eventForDeleteItemTray:__uiid type:ItemTray_item_stone];
		
		return [NSNumber numberWithBool:YES];
	}
}

-(id)requestShiftWithDictionary:(NSDictionary*)_dict
{
	if (_dict == nil || isRequesting) return [NSNumber numberWithBool:NO];
	
	CGPoint _pt = [[_dict objectForKey:@"point"] CGPointValue];
	
	int _uiid = [[_dict objectForKey:@"id"] intValue];
	if (_uiid <= 0) return [NSNumber numberWithBool:NO];
	
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		
		CGPoint pt = [tray.parent convertToWorldSpace:tray.position];
		float _dis = ccpDistance(pt, _pt);
		if (_dis <= tray.contentSize.width/2) {
			
			return [self addStoneWithUiid:_uiid tag:i];
			
		}
	}
	
	// 如果没拖拽到槽中，则返回一个合适的槽的tag
	int __tag = [self getUsableTag:_pt];
	if (__tag == -1) {
		[ShowItem showItemAct:NSLocalizedString(@"jewel_stone_full",nil)];
		return [NSNumber numberWithBool:NO];
	} else if (__tag == -2) {
		return [NSNumber numberWithBool:NO];
	} else {
		return [self addStoneWithUiid:_uiid tag:__tag];
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

-(void)doPolish:(id)sender
{
	if (isRequesting) return;
	
	CCNode *node = sender;
	int tag = node.tag;
	
	if (tag == 10002) return;
	
	[stoneIdArray removeAllObjects];
	for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
		ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
		if (tray.uxid > 0) {
			[stoneIdArray addObject:[NSNumber numberWithInt:tray.uxid]];
		}
	}
	
	if (stoneIdArray.count < trayCount) {
		[ShowItem showItemAct:NSLocalizedString(@"jewel_stone_no_enough",nil)];
		return;
	}
	
	isRequesting = YES;
	
	NSString *path = @"images/animations/jewel/polish/d/";
	id call = [CCCallFunc actionWithTarget:self selector:@selector(doRequest)];
	
	[ClickAnimation showInLayer:mainBg z:-1 tag:0 call:call point:POS_effect path:path loop:NO];
}

-(void)doMoveDone:(id)sender
{
	CCNode *node = sender;
	[node removeFromParent];
	node = nil;
}

-(void)doRequest
{
	NSMutableDictionary *_dict = [NSMutableDictionary dictionary];
	[_dict setObject:stoneIdArray forKey:@"stuff"];
	[GameConnection request:@"gemSanding" data:_dict target:self call:@selector(didPolish::) arg:_dict];
}

-(void)didPolish:(id)sender :(NSDictionary*)_dict
{
	if (checkResponseStatus(sender)) {
		
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			
			// 清空升级材料托盘
			for (int i = Tag_Tray_start; i < Tag_Tray_start+trayCount; i++) {
				ModuleTray *tray = (ModuleTray*)[mainBg getChildByTag:i];
				if (tray.uxid > 0) {
					[tray doTakeOffItem];
				}
			}
			
			// 显示更新的物品
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			// 删除原石
			[[JewelHelper shared] removeItemsWithArray:[_dict objectForKey:@"stuff"]];
			
			NSDictionary *jewel = nil;
			NSArray *jewels = [dict objectForKey:@"gem"];
			if (jewels) {
				jewel = [jewels objectAtIndex:0];
				
				// 添加珠宝
				[[JewelHelper shared] addJewelWithData:jewel];
				
				// 显示珠宝
				int gid = [[jewel objectForKey:@"gid"] intValue];
				float upSucc = [[jewel objectForKey:@"upSucc"] floatValue];
				BOOL isHadRate = (BOOL)(upSucc > 0);
				
				[self showJewel:gid isHadRate:isHadRate];
				
				// 显示珠宝属性
				[self updateAttributeInfo:jewel];
			}
			
			[self updateButton];
			[self updatePackageAmount];
		}
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
	
	isRequesting = NO;
}

@end
