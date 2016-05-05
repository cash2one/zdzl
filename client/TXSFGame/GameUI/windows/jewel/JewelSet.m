//
//  JewelSet.m
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "JewelSet.h"
#import "JewelHelper.h"
#import "ButtonGroup.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "ModuleTray.h"
#import "ItemManager.h"
#import "MemberSizer.h"
#import "GameConnection.h"
#import "ItemDescribetion.h"

#define POS_scroll				CGPointMake(cFixedScale(280), cFixedScale(245))

#define DELAY_scroll			0.3f
#define CGS_scroll				CGSizeMake(cFixedScale(130), cFixedScale(100))
#define OFFSET_scroll_y			cFixedScale(20.0f)

#define JewelSet_Tray_Start_tag			5000
#define POS_num_X						cFixedScale(15)
#define CGS__itemMgr					CGSizeMake(cFixedScale(276), cFixedScale(368))

static JewelSet *s_JewelSet = nil;

@implementation JewelSetScroll

@synthesize roleId;
@synthesize part;
@synthesize target;
@synthesize call;

-(id)init
{
	if (self = [super init]) {
		self.contentSize = CGS_scroll;
		
		partArray = [NSMutableArray array];
		[partArray retain];
		
		upIcon = nil;
		downIcon = nil;
	}
	return self;
}

-(void)dealloc
{
	if (partArray) {
		[partArray release];
		partArray = nil;
	}
	
	[super dealloc];
}

// part为0表示没有装备
+(JewelSetScroll*)create:(int)_roleId part:(int)_part
{
	JewelSetScroll *scroll = [JewelSetScroll node];
	
	scroll.roleId = _roleId;
	scroll.part = _part;
	
	return scroll;
}

-(void)onEnter
{
	[super onEnter];
	
	upIcon = [CCSprite spriteWithFile:@"images/ui/button/bt_GXRDir.png"];
	upIcon.position = ccp(self.position.x+self.contentSize.width/2,
						  self.position.y+self.contentSize.height+OFFSET_scroll_y);
	upIcon.scale = 0.6f;
	upIcon.rotation = 90;
	[self.parent addChild:upIcon z:INT16_MAX];
	
	downIcon = [CCSprite spriteWithFile:@"images/ui/button/bt_GXRDir.png"];
	downIcon.position = ccp(self.position.x+self.contentSize.width/2,
							self.position.y-OFFSET_scroll_y);
	downIcon.scale = 0.6f;
	downIcon.rotation = -90;
	[self.parent addChild:downIcon z:INT16_MAX];
	
	typeLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(26)];
	typeLabel.position = ccp(self.position.x+self.contentSize.width/2,
							 self.position.y-cFixedScale(100));
	typeLabel.color = ccc3(229, 187, 71);
	[self.parent addChild:typeLabel z:INT16_MAX];
	
	CCLayer *layer = [CCLayer node];
	layer.contentSize = CGSizeMake(self.contentSize.width, self.contentSize.height);
	[self addChild:layer z:-1];
	
	[self updateScroll:roleId part:part];
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-179 swallowsTouches:YES];
}

-(void)onExit
{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	if (upIcon) {
		[upIcon removeFromParent];
		upIcon = nil;
	}
	if (downIcon) {
		[downIcon removeFromParent];
		downIcon = nil;
	}
	if (typeLabel) {
		[typeLabel removeFromParent];
		typeLabel = nil;
	}
	
	[super onExit];
}

-(void)setPosition:(CGPoint)position_
{
	_position = position_;
	
	if (upIcon) {
		upIcon.position = ccp(self.position.x+self.contentSize.width/2,
							  self.position.y+self.contentSize.height+OFFSET_scroll_y);
	}
	if (downIcon) {
		downIcon.position = ccp(self.position.x+self.contentSize.width/2,
								self.position.y-OFFSET_scroll_y);
	}
	if (typeLabel) {
		typeLabel.position = ccp(self.position.x+self.contentSize.width/2,
								 self.position.y-cFixedScale(100));
	}
}

-(void)visit
{
	CGPoint pt = [self.parent convertToWorldSpace:self.position];
	int clipX = pt.x;
	int clipY = pt.y-self.contentSize.height;
	int clipW = self.contentSize.width;
	int clipH = self.contentSize.height*3;
	float zoom = [[CCDirector sharedDirector] contentScaleFactor];//高清时候需要放大
	glScissor(clipX*zoom, clipY*zoom, clipW*zoom, clipH*zoom);
    glEnable(GL_SCISSOR_TEST);
    [super visit];
    glDisable(GL_SCISSOR_TEST);
}

-(void)updateLayer
{
	[self updateInfo];
	[self removeChildByTag:200];
	
	if (partArray.count <=0) return;
	
	CCLayer *layer = [CCLayer node];
	layer.contentSize = CGSizeMake(self.contentSize.width, CGS_scroll.height*partArray.count);
	layer.position = [self getPointByIndex:index];
	layer.tag = 200;
	[self addChild:layer];
	
	for (int i = 0; i < partArray.count; i++) {
		int eid = [[partArray objectAtIndex:i] intValue];
		EquipmentIconViewerContent *icon = [EquipmentIconViewerContent create:eid];
		icon.position = [self getEquipmentPointByIndex:i];
		[layer addChild:icon];
	}
}

-(void)updateScroll:(int)_roleId part:(int)_part
{
	roleId = _roleId;
	part = _part;
	index = 0;
	
	[partArray removeAllObjects];
	
	NSArray *equipmentList = [[JewelHelper shared] getEquipmentsEach:roleId];
	
	for (int i = 0; i < equipmentList.count; i++) {
		NSDictionary *equipment = [equipmentList objectAtIndex:i];
		
		int eid = [[equipment objectForKey:@"eid"] intValue];
		[partArray addObject:[NSNumber numberWithInt:eid]];
		
		_part = [[equipment objectForKey:@"part"] intValue];
		if (_part == part) {
			index = i;
		}
	}
	
	[self updateLayer];
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self endScroll];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCNode *layer = [self getChildByTag:200];
	if (layer == nil) return NO;
	
	if (s_JewelSet.isRequesting) return NO;
	
	[layer stopAllActions];
	
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	
	CGRect rect = CGRectMake(0, -OFFSET_scroll_y, CGS_scroll.width, CGS_scroll.height+2*OFFSET_scroll_y);
	if (CGRectContainsPoint(rect, touchLocation)) {
		return YES;
	}
	return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCNode *layer = [self getChildByTag:200];
	if (layer == nil) return;
	
	CGPoint pervisionPoint = [touch previousLocationInView:touch.view];
	CGPoint currentPoint = [touch locationInView:touch.view];
	CGPoint offsetPoint = ccpSub(currentPoint, pervisionPoint);
	
	float minY = (partArray.count-1) * CGS_scroll.height * -1;
	
	float y = layer.position.y - offsetPoint.y;
	y = MAX(MIN(y, 0), minY);

	layer.position = ccp(layer.position.x, y);
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self endScroll];
}

-(void)endScroll
{
	CCNode *layer = [self getChildByTag:200];
	if (layer == nil) return;
	
	int _index = 0;
	float distance = 10000;
	for (int i = 0; i < partArray.count; i++) {
		float _y = -1*i*CGS_scroll.height;
		float _distance = ABS(_y-layer.position.y);
		if (_distance < distance) {
			distance = _distance;
			_index = i;
		}
	}
	index = partArray.count-1-_index;
	
	id move = [CCMoveTo actionWithDuration:DELAY_scroll position:[self getPointByIndex:index]];
	id movebuffer = [CCEaseIn actionWithAction:move rate:0.5];
	[layer runAction:[CCSequence actions:movebuffer, [CCCallFunc actionWithTarget:self selector:@selector(didEndScroll:)], nil]];
}

-(void)didEndScroll:(id)sender
{
	[self updateInfo];
	
	if (target != nil && call != nil) {
		[target performSelector:call withObject:[partArray objectAtIndex:index]];
	}
}

-(void)updateInfo
{
	if (part == 0) {
		upIcon.visible = NO;
		downIcon.visible = NO;
		typeLabel.string = @"";
		return;
	}
	
	if (upIcon)	upIcon.visible = (BOOL)(index > 0);
	if (downIcon) downIcon.visible = (BOOL)(index < partArray.count-1);
	
	switch (part) {
		case 1:
			typeLabel.string = NSLocalizedString(@"config_equipment_part_head",nil);
			break;
		case 2:
			typeLabel.string = NSLocalizedString(@"config_equipment_part_body",nil);
			break;
		case 3:
			typeLabel.string = NSLocalizedString(@"config_equipment_part_foot",nil);
			break;
		case 4:
			typeLabel.string = NSLocalizedString(@"config_equipment_part_necklace",nil);
			break;
		case 5:
			typeLabel.string = NSLocalizedString(@"config_equipment_part_sash",nil);
			break;
		case 6:
			typeLabel.string = NSLocalizedString(@"config_equipment_part_ring",nil);
			break;
			
		default:
			break;
	}
}

-(CGPoint)getPointByIndex:(int)_index
{
	float y = (partArray.count-1-_index)*CGS_scroll.height;
	return ccp(0, -1*y);
}

-(CGPoint)getEquipmentPointByIndex:(int)_index
{
	float y = (partArray.count-1-_index)*CGS_scroll.height;
	CGPoint point = ccp(0, y);
	return ccpAdd(point, ccp(CGS_scroll.width/2, CGS_scroll.height/2));
}

@end


@implementation JewelSet

@synthesize part;
@synthesize ueid;
@synthesize roleId;
@synthesize isRequesting;

+(JewelSet*)create:(NSDictionary *)jInfo{
	if (jInfo) {
		int _roleId = [[jInfo objectForKey:@"roleId"] intValue];
		int _part = [[jInfo objectForKey:@"part"] intValue];
		if (_roleId > 0 && _part >= EquipmentPart_head && _part <= EquipmentPart_ring) {
			return [JewelSet create:_roleId part:_part];
		}
	}
	return [JewelSet create] ;
}

+(JewelSet*)create:(int)_roleId part:(int)_part
{
	JewelSet *jewelSet = [JewelSet node];
	
	NSDictionary *equipment = [[JewelHelper shared] getEquipmentForRole:_roleId part:_part-1];
	if (equipment) {
		
		jewelSet.roleId = _roleId;
		jewelSet.part = _part;
		jewelSet.ueid = [[equipment objectForKey:@"id"] intValue];
		
		return jewelSet;
	}
	
	return nil;
}

+(JewelSet*)create
{
	NSArray *roleList = [[JewelHelper shared] getRoleWithStatus:RoleStatus_in];
	
	if (roleList.count > 0) {
		int _roleId = [[roleList objectAtIndex:0] intValue];
		for (int _part = EquipmentPart_head; _part <= EquipmentPart_ring; _part++) {
			NSDictionary *equipment = [[JewelHelper shared] getEquipmentForRole:_roleId part:_part-1];
			if (equipment) {
				return [self create:_roleId part:_part];
			}
		}
	}
	
	return nil;
}

-(id)init
{
	if (self = [super init]) {
		
		isRequesting = NO;
		
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
		
		if (iPhoneRuningOnGame()) {
			_itemManagerPos = CGPointMake(358, 46);
			_packageAmountPos = CGPointMake(358, 272);
			_dialPos = CGPointMake(233, 167);
			_scrollPos = CGPointMake(200, 140);
		} else {
			_itemManagerPos = CGPointMake(567, 60);
			_packageAmountPos = CGPointMake(567, 500);
			_dialPos = CGPointMake(346, 295);
			_scrollPos = ccp(280, 245);
		}
	}
	return self;
}

-(void)dealloc
{
	if (countArray) {
		[countArray release];
		countArray = nil;
	}
	
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	s_JewelSet = self;
	
	[self showDialBackground];
	[self showPackageBackground];
	
	float tipsSize = 14;
	if (iPhoneRuningOnGame()) {
		tipsSize = 8;
	}
	CCLabelTTF *tipsLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"jewel_set_tips",nil) fontName:getCommonFontName(FONT_1) fontSize:tipsSize];
	tipsLabel.anchorPoint = ccp(1, 1);
	tipsLabel.position = ccp(dialBg.contentSize.width-cFixedScale(15), dialBg.contentSize.height-cFixedScale(8));
	tipsLabel.color = ccc3(238, 228, 207);
	[dialBg addChild:tipsLabel];
	
	// 显示背包
	itemManager = [ItemManager initWithDimension:CGS__itemMgr];
	itemManager.dataType = DataHelper_jewel;
	itemManager.shiftType = ItemTray_item_jewel;
	itemManager.shiftTarget = self;
	itemManager.shiftCall = @selector(requestShiftWithDictionary:);
	itemManager.position = _itemManagerPos;
	[self addChild:itemManager z:10];
	
	// 返回按钮
	CCSimpleButton *simpleButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_return_1.png"
														   select:@"images/ui/button/bt_return_2.png"
														   target:self
															 call:@selector(doBack)];
	simpleButton.position = ccp(dialBg.contentSize.width/2, cFixedScale(45));
	[dialBg addChild:simpleButton];
		
	isFirstPart = YES;
	
	NSArray *roles = [[JewelHelper shared] getRoleWithStatus:RoleStatus_in];
	MemberSizer *memberSizer = [MemberSizer create:roles target:self call:@selector(doSelectRole:) defaultIndex:roleId];
	if (iPhoneRuningOnGame()) {
		memberSizer.position = ccp(dialBg.position.x-memberSizer.contentSize.width+1.2f, 38.5f);
	} else {
		memberSizer.position = ccp(22, 18);
	}
	[self addChild:memberSizer z:INT16_MAX];
	
	scrollLayer = [JewelSetScroll create:roleId part:part];
	scrollLayer.position = _scrollPos;
	scrollLayer.target = self;
	scrollLayer.call = @selector(doSelectPart:);
	[self addChild:scrollLayer];
	
	[GameConnection addPost:ConnPost_request_showInfo target:self call:@selector(requestShowItemTrayDescribe:)];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-180 swallowsTouches:NO];
}

-(void)onExit
{
	s_JewelSet = nil;
	
	[JewelHelper stop];
	[GameConnection freeRequest:self];
	[GameConnection removePostTarget:self];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(void)doBack
{
	[[Window shared] showWindow:PANEL_JEWEL];
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

//转盘背景
-(void)showDialBackground
{
	dialBg = [CCSprite spriteWithFile:@"images/ui/panel/jewel_panel/bg_dial.png"];
	dialBg.anchorPoint = CGPointZero;
	if (iPhoneRuningOnGame()) {
		dialBg.scale = cFixedScale(550)/dialBg.contentSize.height;
		dialBg.position = ccp(111, 18);
	} else {
		dialBg.position=ccp(120, 19);
	}
	[self addChild:dialBg z:10];
	
	dialBg2 = [CCSprite spriteWithFile:@"images/ui/panel/jewel_panel/bg_dial_2.png"];
	dialBg2.position=dialBg.position;
	dialBg2.scale = dialBg.scale;
	dialBg2.anchorPoint = dialBg.anchorPoint;
	[self addChild:dialBg2 z:-1];
}

// 右边背包背景
-(void)showPackageBackground{
	CCSprite *packageBg = [CCSprite spriteWithFile:@"images/ui/panel/character_panel/bg-package.png"];
	if (iPhoneRuningOnGame()) {
		packageBg.scale = cFixedScale(550)/packageBg.contentSize.height;
	}
	packageBg.anchorPoint = CGPointZero;
	packageBg.position = ccp(dialBg.position.x+dialBg.contentSize.width*dialBg.scaleX+cFixedScale(6),
							 dialBg.position.y);
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
	
	int count = [[JewelHelper shared] getJewelPackageAmountWith:part];
	int total = [[JewelHelper shared] getTotalPackageAmount];
	label.string = [NSString stringWithFormat:NSLocalizedString(@"player_capacity",nil),count,total];
}

// 选择角色
-(void)doSelectRole:(NSNumber*)number
{
	if (isRequesting) return;
	
	roleId = [number intValue];
	
	if (isFirstPart) {
		isFirstPart = NO;
		[self updateDial];
		return;
	}
	
	NSArray *equipmentList = [[JewelHelper shared] getEquipmentsEach:roleId];
	if (equipmentList.count > 0) {
		part = [[[equipmentList objectAtIndex:0] objectForKey:@"part"] intValue];
	} else {
		// 没有装备
		part = 0;
	}
	
	[self updateDial];
}

// 选择装备
-(void)doSelectPart:(id)sender
{
	if (isRequesting) return;
	
	NSNumber *number = sender;
	int eid = [number intValue];
	NSDictionary *equipment = [[JewelHelper shared] getEquipInfoBy:eid];
	if (equipment) {
		part = [[equipment objectForKey:@"part"] intValue];
	}
	
	[self updateDial];
}

-(void)updateDial
{
	[itemManager updateJewelContainerWithPart:part];
	[self updatePackageAmount];
	
	NSArray *equipmentList = [[JewelHelper shared] getEquipmentsEach:roleId];
	for (NSDictionary *equipment in equipmentList) {
		
		int _part = [[equipment objectForKey:@"part"] intValue];
		
		if (_part == part) {
			[scrollLayer updateScroll:roleId part:part];
			
			ueid = [[equipment objectForKey:@"ueid"] intValue];
			
			int _seqLevel = [[equipment objectForKey:@"seqLevel"] intValue];
			int _count = [self getCountWithSeqLevel:_seqLevel];
			[self updateDialWithCount:_count];
			
			return;
		}
	}
	
	ueid = 0;
	[scrollLayer updateScroll:roleId part:part];
	[self updateDialWithCount:0];
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

// 获得托盘位置index从1开始
-(CGPoint)getTrayPositionWithIndex:(int)_index
{
	CGPoint point;
	switch (_index) {
		case 1:
			point = ccp(cFixedScale(-123), cFixedScale(114));
			break;
		case 2:
			point = ccp(cFixedScale(-159), cFixedScale(0));
			break;
		case 3:
			point = ccp(cFixedScale(-122), cFixedScale(-111));
			break;
		case 4:
			point = ccp(cFixedScale(106), cFixedScale(113));
			break;
		case 5:
			point = ccp(cFixedScale(141), cFixedScale(1));
			break;
		case 6:
			point = ccp(cFixedScale(104), cFixedScale(-110));
			break;
			
		default:
			point = ccp(0, 0);
			break;
	}
	point = ccpMult(point, dialBg.scale);
	return ccpAdd(point, _dialPos);
}

// 更新转盘的托盘
-(void)updateDialWithCount:(int)_count
{
	for (int i = JewelSet_Tray_Start_tag; i < JewelSet_Tray_Start_tag+maxCount; i++) {
		[self removeChildByTag:i];
	}
	
	NSDictionary *equipment = [[JewelHelper shared] getEquipmentBy:ueid];
	if (equipment) {
		NSDictionary *gem = [equipment objectForKey:@"gem"];
		NSArray *gemKeys = [gem allKeys];
		
		for (int i = 1; i <= maxCount; i++) {
			int tag = JewelSet_Tray_Start_tag+i-1;
			CGPoint position = [self getTrayPositionWithIndex:i];
			
			NSString *key = [NSString stringWithFormat:@"%d", i];
			if ([gemKeys containsObject:key]) {
				
				// 该位置有珠宝，并且已经激活，正常
				if ([key intValue] <= _count) {
					
					ModuleTray *tray = [ModuleTray create:ItemTray_item_jewel];
					tray.position = position;
					tray.tag = tag;
					tray.takeOffTarget = self;
					tray.takeOffCall = @selector(doTakeOff:);
					[self addChild:tray z:INT16_MAX];
					
					int _ujid = [[gem objectForKey:key] intValue];
					NSDictionary *_info = [[JewelHelper shared] getJewelBy:_ujid];
					[tray updateWithDictionary:ueid dict:_info];
					
				}
				// 该位置有珠宝，但是该位置并没有激活，不正常
				else {
					CCLOG(@"ERROE----------------------------------");
					CCLOG(@"ERROE----------------------------------");
					CCLOG(@"updateDialWithCount 位置%d有珠宝，但是该装备最大开放孔数为%d", [key intValue], _count);
				}
				
			} else {
				
				// 该位置没有珠宝，但是已经激活，空托盘
				if ([key intValue] <= _count) {
					
					ModuleTray *tray = [ModuleTray create:ItemTray_item_jewel];
					tray.position = position;
					tray.tag = tag;
					tray.takeOffTarget = self;
					tray.takeOffCall = @selector(doTakeOff:);
					[self addChild:tray z:INT16_MAX];
					
				}
				// 该位置没有珠宝，并且还没激活
				else {
					CCSprite *closeSprite = [CCSprite spriteWithFile:@"images/ui/common/qualityClose.png"];
					closeSprite.position = position;
					closeSprite.tag = tag;
					[self addChild:closeSprite z:INT16_MAX];
				}
				
			}
		}
	} else {
		for (int i = 1; i <= maxCount; i++) {
			int tag = JewelSet_Tray_Start_tag+i-1;
			CGPoint position = [self getTrayPositionWithIndex:i];
			
			CCSprite *closeSprite = [CCSprite spriteWithFile:@"images/ui/common/qualityClose.png"];
			closeSprite.position = position;
			closeSprite.tag = tag;
			[self addChild:closeSprite z:INT16_MAX];
		}
	}
}

-(id)inlayJewelWithUjid:(int)__ujid ueid:(int)__ueid index:(int)__index
{
	NSDictionary *_dict = [[JewelHelper shared] checkJewelCanInlay:__ujid ueid:__ueid index:__index];
	BOOL isCanUse = [[_dict objectForKey:@"result"] boolValue];
	if (!isCanUse) {
		NSString *_info = [_dict objectForKey:@"info"];
		[ShowItem showItemAct:_info];
		return [NSNumber numberWithBool:NO];
	} else {
		if (isRequesting) {
			return [NSNumber numberWithBool:NO];
		}
		
		NSMutableDictionary *data = [NSMutableDictionary dictionary];
		[data setObject:[NSNumber numberWithInt:__ujid] forKey:@"gid"];
		[data setObject:[NSNumber numberWithInt:__ueid] forKey:@"eid"];
		[data setObject:[NSNumber numberWithInt:__index] forKey:@"index"];
		
		NSMutableDictionary *_data = [NSMutableDictionary dictionaryWithDictionary:data];
		[_data setObject:[NSNumber numberWithInt:JewelSet_Tray_Start_tag+__index-1] forKey:@"tag"];
		[GameConnection request:@"gemInlay" data:data target:self call:@selector(didInlayJewel::) arg:_data];
		
		isRequesting = YES;
		
		return [NSNumber numberWithBool:YES];
	}
}

-(id)requestShiftWithDictionary:(NSDictionary*)_dict
{
	if (_dict == nil) return [NSNumber numberWithBool:NO];
	
	CGPoint _pt = [[_dict objectForKey:@"point"] CGPointValue];
	
	int _ujid = [[_dict objectForKey:@"id"] intValue];
	if (_ujid <= 0) return [NSNumber numberWithBool:NO];
		
	for (int i = JewelSet_Tray_Start_tag; i < JewelSet_Tray_Start_tag+maxCount; i++) {
		CCNode *node = [self getChildByTag:i];
		if (![node isKindOfClass:[ModuleTray class]]) {
			continue;
		}
		
		CGPoint pt = [node.parent convertToWorldSpace:node.position];
		float _dis = ccpDistance(pt, _pt);
		if (_dis <= node.contentSize.width/2) {
			
			int index = i-JewelSet_Tray_Start_tag+1;
			return [self inlayJewelWithUjid:_ujid ueid:ueid index:index];
			
		}
	}
	
	// 如果没拖拽到槽中，则返回一个合适的槽的索引
	int __index = [self getCanInlayIndex:_pt];
	if (__index == -1) {
		[ShowItem showItemAct:NSLocalizedString(@"jewel_cannot_inlay_type",nil)];
		return [NSNumber numberWithBool:NO];
	} else if (__index == -2) {
		return [NSNumber numberWithBool:NO];
	} else {
		return [self inlayJewelWithUjid:_ujid ueid:ueid index:__index];
	}
}

// 获取能够镶嵌的索引
-(int)getCanInlayIndex:(CGPoint)_pt
{
	CGPoint pt = [dialBg.parent convertToWorldSpace:dialBg.position];
	CGPoint finalPoint = ccpSub(_pt, pt);
	
	CGRect rect = CGRectMake(0, 0, dialBg.contentSize.width*dialBg.scaleX, dialBg.contentSize.height*dialBg.scaleY);
	// 拖放到镶嵌相关层
	if (CGRectContainsPoint(rect, finalPoint)) {
		NSDictionary *equipment = [[JewelHelper shared] getEquipmentBy:ueid];
		if (equipment != nil) {
			NSDictionary *gem = [equipment objectForKey:@"gem"];
			NSArray *gemKeys = [gem allKeys];
			
			int eid = [[equipment objectForKey:@"eid"] intValue];
			NSDictionary *equipSet = [[JewelHelper shared] getEquipSetInfoBy:eid];
			int seqLevel = [[equipSet objectForKey:@"lv"] intValue];
			int count = [self getCountWithSeqLevel:seqLevel];
			
			for (int i = 1; i <= count; i++) {
				NSString *_key = [NSString stringWithFormat:@"%d", i];
				
				// 当前孔没有珠宝
				if (![gemKeys containsObject:_key]) {
					return i;
				}
			}
		}
		return -1;
	}
	return -2;
}

-(void)didInlayJewel:(NSDictionary*)sender :(NSDictionary*)_data
{
	if (checkResponseStatus(sender)) {
		
		int _ujid = [_data intForKey:@"gid"];
		int _ueid = [_data intForKey:@"eid"];
		int _index = [_data intForKey:@"index"];
		int _trayTag = [_data intForKey:@"tag"];
		
		[[JewelHelper shared] doInlayJewel:_ujid ueid:_ueid index:_index];
		[[JewelHelper shared] setJewelStatus:_ujid status:JewelStatus_used];
		
		CCNode *node = [self getChildByTag:_trayTag];
		if ([node isKindOfClass:[ModuleTray class]]) {
			NSDictionary *jewel = [[JewelHelper shared] getJewelBy:_ujid];
			
			ModuleTray *tray = (ModuleTray*)node;
			[tray updateWithDictionary:_ueid dict:jewel];
		}
		
		if (itemManager) {
			[itemManager eventForDeleteItemTray:_ujid type:ItemTray_item_jewel];
		}
		
		[self updatePackageAmount];
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
	
	isRequesting = NO;
}

-(void)doTakeOff:(NSMutableDictionary*)_dict
{
	int _ujid = [_dict intForKey:@"uxid"];
	int _ueid = [_dict intForKey:@"belongId"];
	
	for (int i = JewelSet_Tray_Start_tag; i < JewelSet_Tray_Start_tag+maxCount; i++) {
		CCNode *node = [self getChildByTag:i];
		if (![node isKindOfClass:[ModuleTray class]]) {
			continue;
		}
		
		ModuleTray *tray = (ModuleTray*)node;
		if (tray.uxid == _ujid) {
			
			if (isRequesting) return;
			
			int _index = i-JewelSet_Tray_Start_tag+1;
			NSMutableDictionary *data = [NSMutableDictionary dictionary];
			[data setObject:[NSNumber numberWithInt:_ueid] forKey:@"eid"];
			[data setObject:[NSNumber numberWithInt:_index] forKey:@"index"];
			
			NSMutableDictionary *_data = [NSMutableDictionary dictionaryWithDictionary:data];
			[_data setObject:[NSNumber numberWithInt:tray.tag] forKey:@"tag"];
			[_data setObject:[NSNumber numberWithInt:_ujid] forKey:@"ujid"];
			
			[GameConnection request:@"gemRemove" data:data target:self call:@selector(didTakeOff::) arg:_data];
			
			isRequesting = YES;
			
			break;
		}
	}
}

-(void)didTakeOff:(NSDictionary*)sender :(NSDictionary*)_data
{
	if (checkResponseStatus(sender)) {
		
		int _index = [_data intForKey:@"index"];
		int _ueid = [_data intForKey:@"eid"];
		int _ujid = [_data intForKey:@"ujid"];
		int _trayTag = [_data intForKey:@"tag"];
		
		[[JewelHelper shared] doTakeOffJewel:_ueid index:_index];
		[[JewelHelper shared] setJewelStatus:_ujid status:JewelStatus_unused];
		
		NSDictionary *jewel = [[JewelHelper shared] getJewelBy:_ujid];
		
		CCNode *node = [self getChildByTag:_trayTag];
		if ([node isKindOfClass:[ModuleTray class]]) {
			
			ModuleTray *tray = (ModuleTray*)node;
			[tray doTakeOffItem];
		}
		
		if (itemManager) {
			[itemManager eventForAddJewel:jewel];
		}
		
		[self updatePackageAmount];
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
	
	isRequesting = NO;
}

@end
