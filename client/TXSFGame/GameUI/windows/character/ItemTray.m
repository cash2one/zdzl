//
//  ItemTray.m
//  TXSFGame
//
//  Created by Soul on 13-3-7.
//  Copyright 2013年 eGame. All rights reserved.
//

//
//物品托盘
//

#import "ItemTray.h"
#import "Item.h"
#import "PlayerDataHelper.h"
#import "JewelHelper.h"
#import "CCNode+AddHelper.h"
#import "GameConnection.h"

#import "GameResourceLoader.h"
#import "EquipmentIconViewerContent.h"
#import "FateIconViewerContent.h"
#import "ItemIconViewerContent.h"
#import "JewlIconViewerContent.h"

@implementation ItemTray

@synthesize type = _type ;
@synthesize number = _number;
@synthesize model =_model;
@synthesize isSelect = _isSelect;

@synthesize target = _target;
@synthesize infoCall = _infoCall;

@synthesize dataType;

-(id)init{
	CCLOG(@"ItemTray->init");
	if (self = [super init]) {
		self.contentSize = ITEMTRAY_SIZE;
		dataType = DataHelper_player;
	}
	return self;
}

-(void)dealloc{
	CCLOG(@"ItemTray->dealloc");
	[super dealloc];
}

-(void)onEnter{
	[super onEnter];
	
	//CCDirector *director =  [CCDirector sharedDirector];
	//[[director touchDispatcher] addTargetedDelegate:self priority:-150 swallowsTouches:YES];
	
	
	CCSprite* background = [CCSprite spriteWithFile:@"images/ui/common/quatily0.png"];
	[self addChild:background z:0];
	background.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	
	
}

-(void)onExit{
	
	//CCDirector *director =  [CCDirector sharedDirector];
	//[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(void)setModel:(ItemTray_model)model{
	_model = model;
	//---------------------------------------------------------------
	//
	[self removeChildByTag:1314 cleanup:YES];
	[self removeChildByTag:1315 cleanup:YES];
	
	if (self.type == ItemTray_item) {
		int type = [[PlayerDataHelper shared] getItemType:self.number];
		if (type == Item_gift_bag) {
			_model = ItemTray_normal ;
			return ;
		}
	}
	
	if (_model == ItemTray_market) {
		CCSprite* _sprite1 = [CCSprite spriteWithFile:@"images/ui/panel/pageItemSelect01.png"];
		CCSprite* _sprite2 = [CCSprite spriteWithFile:@"images/ui/panel/pageItemSelect02.png"];
		_sprite1.anchorPoint = _sprite2.anchorPoint = ccp(0.5, 1.0);
		
		[self addChild:_sprite1 z:101 tag:1314];
		[self addChild:_sprite2 z:100 tag:1315];
		
		_sprite1.position = _sprite2.position = ccp(self.contentSize.width/2, self.contentSize.height);
		
	}
	
	self.isSelect = NO;
}

-(void)setIsSelect:(BOOL)isSelect{
	_isSelect = isSelect;
	
	CCNode* n1 = [self getChildByTag:1314];
	CCNode* n2 = [self getChildByTag:1315];
	
	//不是销售模式的时候 就滚出去
	if (_model != ItemTray_market)  return ;
	
	
	if (n1 != nil) {
		if (_isSelect) {
			n1.visible = NO ;
		}else{
			n1.visible = YES ;
		}
	}
	
	if (n2 != nil) {
		if (_isSelect) {
			n2.visible = YES ;
		}else{
			n2.visible = NO ;
		}
	}
	
	//把东西添加到待出售的数据里面
	if (_isSelect) {
		[[PlayerDataHelper shared] addBatchItem:self.number type:self.type];
	}else{
		[[PlayerDataHelper shared] deleteBatchItem:self.number type:self.type];
	}
	
}

-(void)removeItem{
	_number = 0 ;
	_type = ItemTray_none;
	[self removeChildByTag:2013 cleanup:YES];
}

-(void)deleteItem{
	_number = 0 ;
	_type = ItemTray_none;
}

-(BOOL)isNone{
	return ((_number == 0)&&(_type == ItemTray_none));
}

-(void)addItem:(NSDictionary *)_id type:(ItemTray_type)_t dataType:(DataHelper_type)_dataType
{
	dataType = _dataType;
	[self addItem:_id type:_t];
}

-(void)addItem:(NSDictionary *)_info type:(ItemTray_type)_t{
	
	[self deleteItem];
	[self removeChildByTag:2013 cleanup:YES];
	
	_type = _t;
	
	if (_type == ItemTray_armor) {
		
		int _eid = [_info intForKey:@"eid"];
		int _lv = [_info intForKey:@"level"];
		int _qua = [[PlayerDataHelper shared] getEquipmentQuality:_eid];
		
		_number = [_info intForKey:@"id"];
		
		//NSString * name = [NSString stringWithFormat:@"equip%d.png",_eid];
		//NSString *path = [NSString stringWithFormat:@"images/ui/equipment/equip%d.png",_eid];
		//NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_equip target:name];
		
		EquipmentIconViewerContent * icon = [EquipmentIconViewerContent create:_eid];
		Item* _item = [Item createByIcon:icon quality:_qua count:0 level:_lv];
		[self Category_AddChildToCenter:_item z:2 tag:2013];
		
		return ;
	}
	
	if (_type == ItemTray_fate) {
		
		int _fid = [_info intForKey:@"fid"];
		int _lv = [_info intForKey:@"level"];
		
		int _qua = [[PlayerDataHelper shared] getFateQuality:_fid];
		
		_number = [_info intForKey:@"id"];
		
		//NSString * name = [NSString stringWithFormat:@"soul%d.png",_fid];
		//NSString *path = [NSString stringWithFormat:@"images/ui/fate/soul%d.png",_fid];
		//NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_fate target:name];
		
		FateIconViewerContent * icon = [FateIconViewerContent create:_fid];
		icon.quality = _qua;
		Item* _item = [Item createByIcon:icon quality:_qua count:0 level:_lv];
		[self Category_AddChildToCenter:_item z:2 tag:2013];
		
		return ;
	}
	
	if (_type == ItemTray_item) {
		
		int _iid = [_info intForKey:@"iid"];
		int _cut = [_info intForKey:@"count"];
		int _qua = [[PlayerDataHelper shared] getItemQuality:_iid];
		
		_number = [_info intForKey:@"id"];
		
		//NSString * name = [NSString stringWithFormat:@"item%d.png",_iid];
		//NSString *path = [NSString stringWithFormat:@"images/ui/item/item%d.png",_iid];
		//NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_item target:name];
		
		ItemIconViewerContent * icon = [ItemIconViewerContent create:_iid];
		Item* _item = [Item createByIcon:icon quality:_qua count:_cut level:0];
		[self Category_AddChildToCenter:_item z:2 tag:2013];
		
		return ;
	}
	
	if (_type == ItemTray_item_armor) {
		
		int _iid = [_info intForKey:@"iid"];
		int _cut = [_info intForKey:@"count"];
		int _qua = [[PlayerDataHelper shared] getItemQuality:_iid];
		
		_number = [_info intForKey:@"id"];
		
		//NSString * name = [NSString stringWithFormat:@"item%d.png",_iid];
		//NSString *path = [NSString stringWithFormat:@"images/ui/item/item%d.png",_iid];
		//NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_item target:name];
		
		ItemIconViewerContent * icon = [ItemIconViewerContent create:_iid];
		Item* _item = [Item createByIcon:icon quality:_qua count:_cut level:0];
		
		[self Category_AddChildToCenter:_item z:2 tag:2013];
		
		return ;
	}
	
	if (_type == ItemTray_item_gift) {
		
		int _iid = [_info intForKey:@"iid"];
		int _cut = [_info intForKey:@"count"];
		int _qua = [[PlayerDataHelper shared] getItemQuality:_iid];
		
		_number = [_info intForKey:@"id"];
		
		//NSString * name = [NSString stringWithFormat:@"item%d.png",_iid];
		//NSString *path = [NSString stringWithFormat:@"images/ui/item/item%d.png",_iid];
		//NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_item target:name];
		
		ItemIconViewerContent * icon = [ItemIconViewerContent create:_iid];
		Item* _item = [Item createByIcon:icon quality:_qua count:_cut level:0];
		
		[self Category_AddChildToCenter:_item z:2 tag:2013];
		
		return ;
	}
	
	if (_type == ItemTray_item_jewel) {
		//珠宝系统
		
		int _gid = [_info intForKey:@"gid"];
		int _lv = [_info intForKey:@"level"];
		int _qua = 0;
		if (dataType == DataHelper_jewel) {
			_qua = [[JewelHelper shared] getJewelQuality:_gid];
		} else {
			_qua = [[PlayerDataHelper shared] getJewelQuality:_gid];
		}
		
		float upSucc = [[_info objectForKey:@"upSucc"] floatValue];
		BOOL isHadRate = (BOOL)(upSucc > 0);
		
		_number = [_info intForKey:@"id"];
		
		JewlIconViewerContent * icon = [JewlIconViewerContent create:_gid];
		icon.isHadRate = isHadRate;
		
		Item* _item = [Item createByIcon:icon quality:_qua count:0 level:_lv];
		
		[self Category_AddChildToCenter:_item z:2 tag:2013];
		
		return ;
	}
	
	// 原石
	if (_type == ItemTray_item_stone) {
		
		int _iid = [_info intForKey:@"iid"];
		int _cut = [_info intForKey:@"count"];
		int _qua = 0;
		if (dataType == DataHelper_jewel) {
			_qua = [[JewelHelper shared] getItemQuality:_iid];
		} else {
			_qua = [[PlayerDataHelper shared] getItemQuality:_iid];
		}
		
		_number = [_info intForKey:@"id"];
		
		ItemIconViewerContent * icon = [ItemIconViewerContent create:_iid];
		Item* _item = [Item createByIcon:icon quality:_qua count:_cut level:0];
		[self Category_AddChildToCenter:_item z:2 tag:2013];
		
		return;
		
	}
	
}


-(void)doStartMove{
	CCNode* ___node = [self getChildByTag:2013];
	if (___node != nil) {
		if ([___node isKindOfClass:[Item class]]) {
			Item* _temp = (Item*)___node;
			[_temp showOther:NO];
		}
	}
}

-(void)doEndMove{
	CCNode* ___node = [self getChildByTag:2013];
	if (___node != nil) {
		___node.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
		if ([___node isKindOfClass:[Item class]]) {
			Item* _temp = (Item*)___node;
			[_temp showOther:YES];
		}
	}
}

-(BOOL)checkEvent:(UITouch *)touch{
	return [self isTouchInSite:touch];
}

-(BOOL)isTouchInSite:(UITouch*)touch{
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	
	CGSize size = self.contentSize;
	if(p.x<-size.width*self.anchorPoint.x)		return NO;
	if(p.x>size.width*(1-self.anchorPoint.x))	return NO;
	if(p.y<-size.height*self.anchorPoint.y)		return NO;
	if(p.y>size.height*(1-self.anchorPoint.y))	return NO;
	
	return YES;
}

-(BOOL)touchBegan:(UITouch *)touch{
	
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	touchSwipe_ = touchPoint;
	
	return NO;
}

-(void)touchMoved:(UITouch *)touch{
	
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	CGPoint temp = ccpSub(touchPoint, touchSwipe_);
	CCLOG(@"touchMoved:x=%f|y=%f",temp.x,temp.y);
	CGPoint newPt = ccpAdd(temp, ccp(self.contentSize.width/2, self.contentSize.height/2));
	CCNode* ___node = [self getChildByTag:2013];
	if (___node != nil) {
		___node.position = newPt;
	}
	
}

-(void)touchEnded:(UITouch *)touch{
	
}

-(void)doRequestShowInfo{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:self.number] forKey:@"id"];
	[dict setObject:[NSNumber numberWithInt:self.type] forKey:@"type"];
	[GameConnection post:ConnPost_request_showInfo object:dict];
}

@end








