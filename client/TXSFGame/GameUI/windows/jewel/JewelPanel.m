//
//  JewelPanel.m
//  TXSFGame
//
//  Created by Soul on 13-5-13.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "JewelPanel.h"
#import "GameConfigure.h"
#import "ItemManager.h"
#import "GameConnection.h"
#import "MemberSizer.h"
#import "JewelHelper.h"
#import "CCSimpleButton.h"
#import "RoleImageViewerContent.h"
#import "EquipmentIconViewerContent.h"
#import "Window.h"
#import "JewelSet.h"
#import "JewlIconViewerContent.h"
#import "ClickAnimation.h"

#define JewelPanel_Attr_column		3
#define JewelPanel_Attr_point		CGPointMake(cFixedScale(70), cFixedScale(20))
#define JewelPanel_Attr_offset		CGPointMake(cFixedScale(138), cFixedScale(20))

#define JewelPanel_Point_head		CGPointMake(cFixedScale(88), cFixedScale(430))
#define JewelPanel_Point_body		CGPointMake(cFixedScale(88), cFixedScale(330))
#define JewelPanel_Point_foot		CGPointMake(cFixedScale(88), cFixedScale(230))
#define JewelPanel_Point_necklace	CGPointMake(cFixedScale(460), cFixedScale(430))
#define JewelPanel_Point_sash		CGPointMake(cFixedScale(460), cFixedScale(330))
#define JewelPanel_Point_ring		CGPointMake(cFixedScale(460), cFixedScale(230))

@implementation JewelPanel

-(id)init
{
	if (self = [super init]) {
		roleId = -1;
		
		countArray = [NSMutableArray array];
		[countArray retain];
		
		NSString *string = [[[GameDB shared] getGlobalConfig] objectForKey:@"gemMaxIndex"];
		NSArray *array = [string componentsSeparatedByString:@"|"];
		for (int i = 0; i < array.count; i++) {
			NSString *_string = [array objectAtIndex:i];
			NSArray *_array = [_string componentsSeparatedByString:@":"];
			[countArray addObject:_array];
		}
		
		maxCount = [[[countArray lastObject] objectAtIndex:0] intValue];
		
		jewelHole = [NSMutableDictionary dictionary];
		[jewelHole retain];
		
		NSString *_info = [[[GameDB shared] getGlobalConfig] objectForKey:@"jewelHole"];
		NSArray *_array = [_info componentsSeparatedByString:@"|"];
		for (NSString *_string in _array) {
			NSArray *__array = [_string componentsSeparatedByString:@":"];
			for (int i = 0; i < __array.count; i++) {
				if (i > 0) {
					NSString *__key = [__array objectAtIndex:i];
					NSString *__value = [__array objectAtIndex:0];
					
					[jewelHole setObject:__value forKey:__key];
				}
			}
		}
	}
	return self;
}

-(void)dealloc
{
	if (jewelHole) {
		[jewelHole release];
		jewelHole = nil;
	}
	
	if (countArray) {
		[countArray release];
		countArray = nil;
	}
	
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	CCSprite *roleLayer = [CCSprite spriteWithFile:@"images/ui/panel/jewel_panel/bg_main.png"];
	roleLayer.anchorPoint = CGPointZero;
	if (iPhoneRuningOnGame()) {
		roleLayer.scale = cFixedScale(550)/roleLayer.contentSize.height;
		roleLayer.position = ccp(111, 18);
	} else {
		roleLayer.position=ccp(119, 19);
	}
	roleLayer.tag = 10000;
	[self addChild:roleLayer z:10];
	
	NSArray *roles = [[JewelHelper shared] getRoleWithStatus:RoleStatus_in];
	
	// 默认显示第一个
	MemberSizer *memberSizer = [MemberSizer create:roles target:self call:@selector(doSelectRole:) defaultIndex:0];
	if (iPhoneRuningOnGame()) {
		memberSizer.position = ccp(roleLayer.position.x-memberSizer.contentSize.width+1.2f, 38.5f);
	} else {
		memberSizer.position = ccp(22, 18);
	}
	[self addChild:memberSizer z:20];
	
	// 默认显示第一个
	if (roles.count > 0) {
		int _roleId = [[roles objectAtIndex:0] intValue];
		[self updateWithRoleId:_roleId];
	}
	
	CCLayer *_layer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 190) width:cFixedScale(169) height:cFixedScale(505)];
	CCLayer *layer = getSideLayer(_layer, cFixedScale(1.5f));
	layer.anchorPoint = CGPointZero;
	if (iPhoneRuningOnGame()) {
		layer.scale = cFixedScale(550)/layer.contentSize.height;
		layer.position = ccp(roleLayer.position.x+roleLayer.contentSize.width*roleLayer.scaleX+3,
							 roleLayer.position.y);
	} else {
		layer.position = ccp(676, 19);
	}
	[self addChild:layer];
	
	// 开采
	CCSimpleButton *mineButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_jump_mine_1.png"
														 select:@"images/ui/button/bt_jump_mine_2.png"
														 target:self
														   call:@selector(doOpenOtherWindow:)];
	mineButton.position = ccp(layer.contentSize.width/2, cFixedScale(405));
	mineButton.tag = 50001;
	[layer addChild:mineButton];
	
	// 打磨
	CCSimpleButton *polishButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_jump_polish_1.png"
														   select:@"images/ui/button/bt_jump_polish_2.png"
														   target:self
															 call:@selector(doOpenOtherWindow:)];
	polishButton.position = ccp(layer.contentSize.width/2, cFixedScale(265));
	polishButton.tag = 50002;
	[layer addChild:polishButton];
	
	// 提炼
	CCSimpleButton *refineButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_jump_refine_1.png"
														   select:@"images/ui/button/bt_jump_refine_2.png"
														   target:self
															 call:@selector(doOpenOtherWindow:)];
	refineButton.position = ccp(layer.contentSize.width/2, cFixedScale(125));
	refineButton.tag = 50003;
	[layer addChild:refineButton];
}

-(void)onExit
{
	[JewelHelper stop];
	
	[super onExit];
}

-(void)updateWithRoleId:(int)_roleId
{
	if (roleId == _roleId) return;
	roleId = _roleId;
	
	CCNode *roleLayer = [self getChildByTag:10000];
	[roleLayer removeAllChildren];
	
	float tipsSize = 14;
	if (iPhoneRuningOnGame()) {
		tipsSize = 8;
	}
	CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"jewel_panel_tips",nil) fontName:getCommonFontName(FONT_1) fontSize:tipsSize];
	tipsLabel.anchorPoint = ccp(1, 1);
	tipsLabel.position = ccp(roleLayer.contentSize.width-cFixedScale(15), roleLayer.contentSize.height-cFixedScale(8));
	tipsLabel.color = ccc3(238, 228, 207);
	[roleLayer addChild:tipsLabel];
	
	// 人物
	CCSprite *roleSprite = [RoleImageViewerContent create:_roleId];
	roleSprite.anchorPoint = ccp(0.5, 0);
	roleSprite.position = ccp(roleLayer.contentSize.width/2, cFixedScale(160));
	[roleLayer addChild:roleSprite];
	
	// 属性描述
	CCLayer *attrLayer = [CCLayerColor layerWithColor:ccc4(200, 200, 200, 0) width:cFixedScale(500) height:cFixedScale(120)];
	attrLayer.position = ccp((roleLayer.contentSize.width-attrLayer.contentSize.width)/2, cFixedScale(22));
	[roleLayer addChild:attrLayer];
	
	float labelSize = 16;
	if (iPhoneRuningOnGame()) {
		labelSize = 9;
	}
	CCLabelTTF *jewelAttrLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"jewel_attr",nil) fontName:getCommonFontName(FONT_1) fontSize:labelSize];
	jewelAttrLabel.position = ccp(roleLayer.contentSize.width/2, cFixedScale(145));
	jewelAttrLabel.color = ccc3(193, 154, 31);
	[roleLayer addChild:jewelAttrLabel];
	
	NSString *attrDesc = [[JewelHelper shared] getJewelAdditionBy:_roleId];
	NSArray *attrArray = [attrDesc componentsSeparatedByString:@"|"];
	for (int i = 0; i < attrArray.count; i++) {
		float x = JewelPanel_Attr_point.x + (i%JewelPanel_Attr_column)*JewelPanel_Attr_offset.x;
		float y = attrLayer.contentSize.height-JewelPanel_Attr_point.y-(i/JewelPanel_Attr_column)*JewelPanel_Attr_offset.y;
		CGPoint point = ccp(x, y);
		
		float fontSize = 14;
		if (iPhoneRuningOnGame()) {
			fontSize = 7;
		}
		NSString *attr = [attrArray objectAtIndex:i];
		
		// "0或0.0%"转为"--"显示
		NSArray *__attr = [attr componentsSeparatedByString:@":"];
		if (__attr.count >= 2) {
			NSString *__string = [__attr objectAtIndex:1];
			if ([__string isEqualToString:@"0"] || [__string isEqualToString:@"0.0%"]) {
				attr = [NSString stringWithFormat:@"%@:--", [__attr objectAtIndex:0]];
			}
		}
		
		CCLabelTTF *label = [CCLabelTTF labelWithString:attr fontName:getCommonFontName(FONT_1) fontSize:fontSize];
		label.anchorPoint = ccp(0, 0.5);
		label.position = point;
		label.color = ccc3(204, 125, 14);
		[attrLayer addChild:label];
	}
	
	// 装备
	for (int i = EquipmentPart_head; i <= EquipmentPart_ring; i++) {
		CCSimpleButton *simpleButton = [self getButtonWithRoleId:_roleId part:i];
		if (simpleButton) {
			[roleLayer addChild:simpleButton];
		}
	}
	
}

-(CCSimpleButton*)getButtonWithRoleId:(int)_roleId part:(int)part
{
	CCSimpleButton *simpleButton = nil;
	
	NSDictionary *equipment = [[JewelHelper shared] getEquipmentForRole:_roleId part:part-1];
	if (equipment) {
		
		CCSprite *equipBg = nil;
		
		int eid = [[equipment objectForKey:@"eid"] intValue];
		NSDictionary *equipmentInfo = [[JewelHelper shared] getEquipInfoBy:eid];
		if (equipmentInfo) {
			int quality = [[JewelHelper shared] getEquipmentQuality:eid];
			equipBg = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/common/quality%d.png", quality]];
		}
		if (equipBg == nil) {
			equipBg = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
		}
		
		simpleButton = [CCSimpleButton node];
		[simpleButton setContentSize:equipBg.contentSize];
		[simpleButton setTarget:self];
		[simpleButton setCall:@selector(doSelectEquipment:)];
		[simpleButton setTag:part+2000];
		
		equipBg.position = ccp(simpleButton.contentSize.width/2,
							   simpleButton.contentSize.height/2);
		[simpleButton addChild:equipBg];
		
		// 加装备图标
		EquipmentIconViewerContent *equipIcon = [EquipmentIconViewerContent create:eid];
		equipIcon.position = ccp(simpleButton.contentSize.width/2,
								 simpleButton.contentSize.height/2);
		[simpleButton addChild:equipIcon];
		
		int openCount = 0;
		NSDictionary *setInfo = [[JewelHelper shared] getEquipSetInfoBy:eid];
		if (setInfo) {
			int seqLevel = [[setInfo objectForKey:@"lv"] intValue];
			openCount = [self getCountWithSeqLevel:seqLevel];
		}
		
		NSDictionary *gem = [equipment objectForKey:@"gem"];
		NSArray *gemKeys = [gem allKeys];
		
		for (int i = 1; i <= openCount; i++) {
			CGPoint position = [self getPosition:i total:openCount];
			
			NSString *key = [NSString stringWithFormat:@"%d", i];
			// 此孔有宝石
			if ([gemKeys containsObject:key]) {
				
				int ujid = [[gem objectForKey:key] intValue];
				NSDictionary *jewel = [[JewelHelper shared] getJewelBy:ujid];
				int gid = [[jewel objectForKey:@"gid"] intValue];
				
				NSDictionary *jewelInfo = [[JewelHelper shared] getJewelInfoBy:gid];
				if (jewelInfo) {
					CGPoint position = [self getPosition:i total:openCount];
					
					int type = [[jewelInfo objectForKey:@"type"] intValue];
					CCSprite *icon = [self getSpriteWithType:type];
					icon.position = position;
					[simpleButton addChild:icon z:10];
					
					// 记录成功率加效果
					float upSucc = [[jewel objectForKey:@"upSucc"] floatValue];
					BOOL isHadRate = (BOOL)(upSucc > 0);
					if (isHadRate) {
						float scale = 0.3f;
						
						NSString *path = @"images/animations/jewel/hadSuc/";
						[ClickAnimation showInLayer:simpleButton z:5 tag:0 call:nil point:position scaleX:scale scaleY:scale path:path loop:YES];
					}
				}
				
			}
			// 此孔没有宝石
			else {
				CCSprite *icon = [self getSpriteWithType:0];
				icon.position = position;
				[simpleButton addChild:icon z:10];
			}
		}
		
	} else {
		
		CCSprite *equipBg = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
		
		simpleButton = [CCSimpleButton node];
		[simpleButton setContentSize:equipBg.contentSize];
		[simpleButton setTouchScale:1.0f];
		equipBg.position = ccp(simpleButton.contentSize.width/2,
							   simpleButton.contentSize.height/2);
		[simpleButton addChild:equipBg];
		
	}

	switch (part) {
		case EquipmentPart_head:
			simpleButton.position = JewelPanel_Point_head;
			break;
		case EquipmentPart_body:
			simpleButton.position = JewelPanel_Point_body;
			break;
		case EquipmentPart_foot:
			simpleButton.position = JewelPanel_Point_foot;
			break;
		case EquipmentPart_necklace:
			simpleButton.position = JewelPanel_Point_necklace;
			break;
		case EquipmentPart_sash:
			simpleButton.position = JewelPanel_Point_sash;
			break;
		case EquipmentPart_ring:
			simpleButton.position = JewelPanel_Point_ring;
			break;
			
		default:
			break;
	}
	
	return simpleButton;
}

// 套装等级获得开孔数
-(int)getCountWithSeqLevel:(int)_seqLevel
{
	for (int i = 0; i < countArray.count; i++) {
		NSArray *array = [countArray objectAtIndex:i];
		int count = [[array objectAtIndex:0] intValue];
		int min = [[array objectAtIndex:1] intValue];
		int max = [[array objectAtIndex:2] intValue];
		
		if (_seqLevel >= min && _seqLevel <= max) {
			return count;
		}
	}
	return 0;
}

-(CCSprite*)getSpriteWithType:(int)_type
{
	NSString *key = [NSString stringWithFormat:@"%d", _type];
	int index = [[jewelHole objectForKey:key] intValue];
	CCSprite *icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/panel/jewel_panel/hole%d.png", index]];
	return icon;
}

-(CGPoint)getPosition:(int)index total:(int)total
{
	if (index > total) return CGPointZero;
	
	CCSprite *equipBg = [CCSprite spriteWithFile:@"images/ui/common/quality0.png"];
	float radius = equipBg.contentSize.width/2-cFixedScale(3);
	
	float angle = M_PI;
	float perAngle = 2.0f*M_PI/total;
	// 所有y轴对称，total为6时，最高点在y轴上
	if (total != 1) {
		if (total == 6) {
			angle -= (M_PI/2-perAngle);
		} else {
			angle -= (M_PI/2-perAngle/2);
		}
	}
	
	CGPoint point = ccpMult(ccpForAngle(angle-(index-1)*perAngle), radius);
	point = ccpAdd(point, ccp(equipBg.contentSize.width/2, equipBg.contentSize.height/2));
	
	return point;
}

-(void)doSelectRole:(NSNumber*)number
{
	int _roleId = [number intValue];
	[self updateWithRoleId:_roleId];
}

-(void)doSelectEquipment:(id)sender
{
	CCNode *node = sender;
	int tag = node.tag;
	int part = tag - 2000;
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:roleId] forKey:@"roleId"];
	[dict setObject:[NSNumber numberWithInt:part] forKey:@"part"];
	[[Window shared] showWindow:PANEL_JEWEL_set dictionary:dict];
}

-(void)doOpenOtherWindow:(id)sender
{
	CCNode *node = sender;
	int tag = node.tag;
	if (tag == 50001) {
		[[Window shared] showWindow:PANEL_JEWEL_mine];
	} else if (tag == 50002) {
		[[Window shared] showWindow:PANEL_JEWEL_polish];
	} else if (tag == 50003) {
		[[Window shared] showWindow:PANEL_JEWEL_refine];
	}
}

@end
