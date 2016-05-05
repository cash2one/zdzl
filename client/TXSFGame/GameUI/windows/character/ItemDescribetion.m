//
//  ItemDescribetion.m
//  TXSFGame
//
//  Created by Soul on 13-3-11.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ItemDescribetion.h"
#import "PlayerDataHelper.h"
#import "CCSimpleButton.h"
#import "MessageBox.h"
#import "GameConnection.h"
#import "PlayerPanel.h"
#import "GameConfigure.h"
#import "JewelHelper.h"

#define POS_bt_offsetX				 cFixedScale(20)
#define POS_bt_offsetY				 cFixedScale(10)
#define POS_Msg_startX			     cFixedScale(10)
#define Default_width				 cFixedScale(200)
#define Default_height				 cFixedScale(300)
#define Default_bt_height			 cFixedScale(40)
#define Default_RoleDescribetion_width	cFixedScale(180)
#define Default_RoleDescribetion_height	cFixedScale(540)

#define VALUE_left cFixedScale(20)
#define VALUE_start cFixedScale(30)
#define VALUE__space cFixedScale(20)

@implementation RoleDescribetion

@synthesize isEnter = _isEnter;
@synthesize isExit = _isExit;


+(RoleDescribetion*)showDescribetion{
	RoleDescribetion *m_instance =nil;
	if (iPhoneRuningOnGame()) {
		m_instance=[[[RoleDescribetion alloc] initWithColor:ccc4(0, 0, 0, 80)
													  width:160/2.0f
													 height:555/2.0f] autorelease];
	}else{
		m_instance=[[[RoleDescribetion alloc] initWithColor:ccc4(0, 0, 0, 80)
																	  width:Default_RoleDescribetion_width
																	 height:Default_RoleDescribetion_height] autorelease];
	}
	return  m_instance;
}

-(void)draw{
	[super draw];
	ccDrawSolidRect( CGPointZero, ccp(self.contentSize.width, self.contentSize.height ), ccc4FFromccc4B(ccc4(0, 0, 0, 180)));
	ccDrawColor4B(204, 125, 14, 168);
	ccDrawRect(ccp(0,0), ccp(self.contentSize.width, self.contentSize.height));
}

-(void)showAttribute:(NSDictionary*)_attribute{
	[self removeAllChildrenWithCleanup:YES];
	
	NSDictionary* dict = [NSDictionary dictionaryWithDictionary:_attribute];//BaseAttributeToDictionary(_attribute);
	
	int left = VALUE_left;
    int start = VALUE_start;
	int _space = VALUE__space;
	if (iPhoneRuningOnGame()) {
		left=VALUE_left-5;
		start=VALUE_start+5;
	}
	float fontSize=16;
	if (iPhoneRuningOnGame()) {
		fontSize=9;
	}
	for (int i = 20; i >= 0; i--) {
		//NSArray *args = [attribute_map[i] componentsSeparatedByString:@"|"];
        NSArray *args = [NSLocalizedString(attribute_map[i],nil) componentsSeparatedByString:@"|"];
		
		if (args.count == 3) {
			
			NSString* _key = [args objectAtIndex:0];
			NSString* _abc = [args objectAtIndex:1];
			
			float _value = [[dict objectForKey:_key] floatValue];
			
			NSString *str = [NSString stringWithFormat:@"%@  %.1f%@",_abc,_value,@"%"];
			

			
			CCLabelTTF *m_tuf = [CCLabelTTF labelWithString:str
												   fontName:getCommonFontName(FONT_1)
												   fontSize:fontSize];

			m_tuf.color = ccc3(204, 204, 204);
			m_tuf.anchorPoint = ccp(0, 0.5);
			[m_tuf setVerticalAlignment:kCCVerticalTextAlignmentCenter];
			[m_tuf setHorizontalAlignment:kCCTextAlignmentLeft];
			[self addChild:m_tuf];
			m_tuf.position=ccp(left, start);
			
			start += _space;
			
		}else if (args.count == 2){
			
			NSString* _key = [args objectAtIndex:0];
			NSString* _abc = [args objectAtIndex:1];
			
			int _value = [[dict objectForKey:_key] intValue];
			
			NSString *str = [NSString stringWithFormat:@"%@  %d",_abc,_value];
			
			CCLabelTTF *m_tuf = [CCLabelTTF labelWithString:str
												   fontName:getCommonFontName(FONT_1)
												   fontSize:fontSize];
			
			m_tuf.color = ccc3(204, 204, 204);
			m_tuf.anchorPoint = ccp(0, 0.5);
			[m_tuf setVerticalAlignment:kCCVerticalTextAlignmentCenter];
			[m_tuf setHorizontalAlignment:kCCTextAlignmentLeft];
			[self addChild:m_tuf];
			m_tuf.position=ccp(left, start);
			
			start += _space;
		}
		
		if (i == 12 || i == 6) {
			start += _space;
		}
	}
	
	
	start += _space;
	fontSize=22;
    if (iPhoneRuningOnGame()) {
		fontSize=14;
    }
	
	//CCLabelTTF *m_label = [CCLabelTTF labelWithString:@"属性" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    CCLabelTTF *m_label = [CCLabelTTF labelWithString:NSLocalizedString(@"item_dec_property",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	m_label.color = ccc3(204, 125, 14);
	m_label.anchorPoint = ccp(0, 0.5);
	[m_label setVerticalAlignment:kCCVerticalTextAlignmentCenter];
	[m_label setHorizontalAlignment:kCCTextAlignmentLeft];
	[self addChild:m_label];
	m_label.position=ccp(left, start);
	
	
}

-(void)actEnd:(id)_sender{
	self.visible = !self.visible;
}

-(void)doEnter{
	float _x = self.position.x ;
	float _y = self.position.y ;
	_x -= self.contentSize.width;
	CCCallFuncN *act2 = [CCCallFuncN actionWithTarget:self selector:@selector(actEnd:)];
	CGPoint pt = CGPointZero;
	if (iPhoneRuningOnGame()) {
		pt = ccp(_x-self.contentSize.width/2.0f-4.5,_y);
	}else{
		pt = ccp(_x,_y);
	}
	CCMoveTo* act1 = [CCMoveTo actionWithDuration:0.1 position: pt];
	CCSequence *act = [CCSequence actions:act2,act1,nil];
	
	[self runAction:act];

    
}

-(void)doExit{
	float _x = self.parent.contentSize.width ;
	float _y = self.position.y ;
	
	CCMoveTo* act1 = [CCMoveTo actionWithDuration:0.1 position:ccp(_x, _y)];
	CCCallFuncN *act2 = [CCCallFuncN actionWithTarget:self selector:@selector(actEnd:)];
	CCSequence *act = [CCSequence actions:act1,act2,nil];
	
	[self runAction:act];
}

@end


@implementation ItemDescribetion

@synthesize did = _did;
@synthesize type = _type;
@synthesize dataType = _dataType;


+(ItemDescribetion*)showDescribetion:(int)_iid type:(ItemTray_type)_typ{
		
	if (YES) {
		ItemDescribetion* _des = [ItemDescribetion layerWithColor:ccc4(0, 0, 0, 0)
															width:Default_width
														   height:Default_height];
		
		_des.did  = _iid;
		_des.type = _typ;
		_des.dataType = DataHelper_player;
		
		return _des;
	}
	
	return nil ;
	
}

+(ItemDescribetion*)showDescribetion:(int)_iid type:(ItemTray_type)_typ dataType:(DataHelper_type)_dtype
{
	if (YES) {
		ItemDescribetion* _des = [ItemDescribetion layerWithColor:ccc4(0, 0, 0, 0)
															width:Default_width
														   height:Default_height];
		
		_des.did  = _iid;
		_des.type = _typ;
		_des.dataType = _dtype;
		
		return _des;
	}
	
	return nil ;
}

-(void)draw{
	[super draw];
	ccDrawSolidRect( CGPointZero, ccp(self.contentSize.width, self.contentSize.height ), ccc4FFromccc4B(ccc4(0, 0, 0, 180)));
	ccDrawColor4B(204, 125, 14, 168);
	ccDrawRect(ccp(0,0), ccp(self.contentSize.width, self.contentSize.height));
}

-(void)doConfirm:(CCSimpleButton*)_sender
{
	[self removeFromParent];
}

-(void)doEquipment:(CCSimpleButton*)_sender{
	[[PlayerPanel shared] requestShiftWithDescribetion:[NSNumber numberWithInt:self.did]];
	[self removeFromParentAndCleanup:YES];
}

-(void)doSell:(CCSimpleButton*)_sender{
	
	[[PlayerDataHelper shared] cleanupBatchData];
	[[PlayerDataHelper shared] addBatchItem:self.did type:self.type];
	[[PlayerPanel shared] requestSellWithDescribetion];
	
	[self removeFromParentAndCleanup:YES];
}

-(void)doGet:(CCSimpleButton*)_seder{
	[[PlayerPanel shared] doUseItem:self.did type:self.type];
	
	[self removeFromParentAndCleanup:YES];
}
// 打开渔获
-(void)doOpen:(CCSimpleButton*)_sender{
	CCLOG(@"打开物品");
	[[PlayerPanel shared] doUseItem:self.did type:self.type];
	
	[self removeFromParentAndCleanup:YES];
}

-(void)doMerge:(CCSimpleButton*)_sender{
	
	CCLOG(@"物品合成");
	[[PlayerPanel shared] doUseItem:self.did type:self.type];
		
	[self removeFromParentAndCleanup:YES];
	
}

-(void)onEnter{
	[super onEnter];
	
	/*
	MessageBox *messageBox = [MessageBox create:CGPointZero color:ccc4(0, 0, 0, 0) background:ccc4(0, 0, 0, 0)];
	messageBox.position = ccp(POS_Msg_startX,Default_bt_height);


	[self addChild:messageBox];
	
	NSString* _msg = [[PlayerDataHelper shared] getDescribetion:_did type:_type];
	
	if (_msg) {
		[messageBox message:_msg];
		self.contentSize = CGSizeMake(self.contentSize.width,
									  messageBox.contentSize.height + Default_bt_height + POS_Msg_startX);
		
	}*/
	
	
	//TODO
	/*
	float fontSize=16;
	if (iPhoneRuningOnGame()) {
		fontSize=9;
	}
	*/
	NSString* _msg = nil;
	if (_dataType == DataHelper_jewel) {
		_msg = [[JewelHelper shared] getDescribetion:_did type:_type];
	} else {
		_msg = [[PlayerDataHelper shared] getDescribetion:_did type:_type];
	}
	if (_msg) {
		CCSprite* _sprite = drawString(_msg,
									   CGSizeMake(180, 300),
									   getCommonFontName(FONT_1),
									   16, 18, @"#ffffff");
		
		self.contentSize = CGSizeMake(self.contentSize.width,
									  _sprite.contentSize.height + Default_bt_height + POS_Msg_startX);
		
		[self addChild:_sprite];
		
		_sprite.position = ccp(self.contentSize.width/2,self.contentSize.height/2 + Default_bt_height/2);
	}
	
	// 珠宝相关界面只显示确定按钮
	if (_dataType == DataHelper_jewel) {
		CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_pass_1.png"
													   select:@"images/ui/button/bts_pass_2.png"
													   target:self
														 call:@selector(doConfirm:)
													 priority:-256];
		[self addChild:bnt2 z:10 tag:102];
		bnt2.anchorPoint=ccp(0.5, 0);
		bnt2.position=ccp(self.contentSize.width/2,
						  POS_bt_offsetY);
		if (iPhoneRuningOnGame()) {
			bnt2.scale=1.3f;
		}
		return;
	}
	
	if (self.type == ItemTray_armor) {
		CCSimpleButton* bnt1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_equip_1.png"
													  select:@"images/ui/button/bts_equip_2.png"
													  target:self
														call:@selector(doEquipment:)
													priority:-256];
		[self addChild:bnt1 z:10 tag:101];
		bnt1.anchorPoint = ccp(0, 0);
		
		bnt1.position=ccp(POS_bt_offsetX,
						 POS_bt_offsetY);
		
		CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_sell_1.png"
													  select:@"images/ui/button/bts_sell_2.png"
													  target:self
														call:@selector(doSell:)
													priority:-256];
		[self addChild:bnt2 z:10 tag:102];
		bnt2.anchorPoint = ccp(1.0, 0);
		
		bnt2.position=ccp(self.contentSize.width - POS_bt_offsetX,
						 POS_bt_offsetY);
		if (iPhoneRuningOnGame()) {
			bnt1.scale=1.3f;
			bnt2.scale=bnt1.scale;
			bnt1.position=ccp(POS_bt_offsetX-9,POS_bt_offsetY);
			bnt2.position=ccp(self.contentSize.width - POS_bt_offsetX+9,
							  POS_bt_offsetY);
		}
		
	}else if (self.type == ItemTray_fate){
		CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_sell_1.png"
													   select:@"images/ui/button/bts_sell_2.png"
													   target:self
														 call:@selector(doSell:)
													 priority:-256];
		[self addChild:bnt2 z:10 tag:102];
		bnt2.anchorPoint=ccp(0.5, 0);
		bnt2.position=ccp(self.contentSize.width/2,
						  POS_bt_offsetY);
		if (iPhoneRuningOnGame()) {
			bnt2.scale=1.3f;
		}

	}else{
		int type = [[PlayerDataHelper shared] getItemType:self.did];
		
		if (type == Item_gift_bag) {
			CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_get_1.png"
														   select:@"images/ui/button/bts_get_2.png"
														   target:self
															 call:@selector(doGet:)
														 priority:-256];
			[self addChild:bnt2 z:10 tag:102];
			bnt2.anchorPoint=ccp(0.5, 0);
			bnt2.position=ccp(self.contentSize.width/2,
							  POS_bt_offsetY);
			if (iPhoneRuningOnGame()) {
				bnt2.scale=1.3f;
			}

		}else if (type == Item_splinter){
			CCSimpleButton* bnt1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_merge_1.png"
														   select:@"images/ui/button/bts_merge_2.png"
														   target:self
															 call:@selector(doMerge:)
														 priority:-256];
			[self addChild:bnt1 z:10 tag:101];
			bnt1.anchorPoint = ccp(0, 0);
			
			bnt1.position=ccp(POS_bt_offsetX,
							  POS_bt_offsetY);
			
			CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_sell_1.png"
														   select:@"images/ui/button/bts_sell_2.png"
														   target:self
															 call:@selector(doSell:)
														 priority:-256];
			[self addChild:bnt2 z:10 tag:102];
			bnt2.anchorPoint = ccp(1.0, 0);
			
			bnt2.position=ccp(self.contentSize.width - POS_bt_offsetX,
							  POS_bt_offsetY);
			if (iPhoneRuningOnGame()) {
				bnt1.scale=1.3f;
				bnt2.scale=bnt1.scale;
				bnt1.position=ccp(POS_bt_offsetX-9,POS_bt_offsetY);
				bnt2.position=ccp(self.contentSize.width - POS_bt_offsetX+9,
								  POS_bt_offsetY);
			}
		}else if (type == Item_fish_item){
			
			CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_open_1.png"
														   select:@"images/ui/button/bts_open_1.png"
														   target:self
															 call:@selector(doOpen:)
														 priority:-256];
			[self addChild:bnt2 z:10 tag:102];
			bnt2.anchorPoint=ccp(0.5, 0);
			bnt2.position=ccp(self.contentSize.width/2,
							  POS_bt_offsetY);
			if (iPhoneRuningOnGame()) {
				bnt2.scale=1.3f;
			}
			
		}else{
			CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_sell_1.png"
														   select:@"images/ui/button/bts_sell_2.png"
														   target:self
															 call:@selector(doSell:)
														 priority:-256];
			[self addChild:bnt2 z:10 tag:102];
			bnt2.anchorPoint=ccp(0.5, 0);
			bnt2.position=ccp(self.contentSize.width/2,
							  POS_bt_offsetY);
			if (iPhoneRuningOnGame()) {
				bnt2.scale=1.3f;
			}
		}
		
	}
	/*
	else if (self.type == ItemTray_item_armor) {
	
		CCSimpleButton* bnt1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_merge_1.png"
													   select:@"images/ui/button/bts_merge_2.png"
													   target:self
														 call:@selector(doMerge:)
													 priority:-256];
		[self addChild:bnt1 z:10 tag:101];
		bnt1.anchorPoint = ccp(0, 0);
		
		bnt1.position=ccp(POS_bt_offsetX,
						  POS_bt_offsetY);
		
		CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_sell_1.png"
													   select:@"images/ui/button/bts_sell_2.png"
													   target:self
														 call:@selector(doSell:)
													 priority:-256];
		[self addChild:bnt2 z:10 tag:102];
		bnt2.anchorPoint = ccp(1.0, 0);
		
		bnt2.position=ccp(self.contentSize.width - POS_bt_offsetX,
						  POS_bt_offsetY);
		
	} else{
		CCSimpleButton* bnt2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_sell_1.png"
													   select:@"images/ui/button/bts_sell_2.png"
													   target:self
														 call:@selector(doSell:)
													 priority:-256];
		[self addChild:bnt2 z:10 tag:102];
		bnt2.anchorPoint=ccp(0.5, 0);
		bnt2.position=ccp(self.contentSize.width/2,
						  POS_bt_offsetY);
	}
	*/
}

-(void)onExit{
	[super onExit];
}

@end
