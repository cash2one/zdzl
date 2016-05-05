//
//  EquipmentTray.m
//  TXSFGame
//
//  Created by Soul on 13-3-10.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "EquipmentTray.h"
#import "PlayerDataHelper.h"
#import "CCNode+AddHelper.h"
#import "Equipment.h"
#import "CCSimpleButton.h"
#import "PlayerPanel.h"
#import "AlertManager.h"
#import "Config.h"

#define POS_Shift_bt_offsetX	cFixedScale(10)
#define POS_Shift_bt_offsetY	cFixedScale(10)
#define CGS_self  CGSizeMake(cFixedScale(86), cFixedScale(86))

@implementation EquipmentTray

@synthesize ueid = _ueid;
@synthesize eid	= _eid;
@synthesize part = _part;
@synthesize rid = _rid;
@synthesize userAction = _userAction;
@synthesize eDict = _eDict ;
@synthesize isShowInfo = _isShowInfo;

-(id)init{
	if (self = [super init]) {
		self.contentSize=CGS_self;
	}
	return self ;
}

-(void)dealloc{
	if (_eDict) {
		[_eDict release];
		_eDict = nil ;
	}
	[super dealloc];
}

-(void)onEnter{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-148 swallowsTouches:YES];
	
}

-(void)onExit{
	[self unscheduleAllSelectors];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(void)setPart:(int)part{
	_part = part ;
	//---------------------------
	
	[self removeChildByTag:2008 cleanup:YES];
	
	NSString* path = [NSString stringWithFormat:@"images/ui/panel/character_panel/eq%d.png",part];
	CCSprite* _sprite = [CCSprite spriteWithFile:path];
	[self Category_AddChildToCenter:_sprite z:0 tag:2008];
	
	
}

-(void)updateWithDictionary:(NSDictionary*)_dict{
	
	if (_dict == nil) {
		//没有装备的情况下
		CCLOG(@"EquipmentTab->part->%d->nil equipment",_part);
		
	}else{
		CCLOG(@"EquipmentTab->part->%d",_part);
		
		
		self.eid = [[_dict objectForKey:@"eid"] intValue];
		self.ueid = [[_dict objectForKey:@"id"] intValue];
		int _level = [[_dict objectForKey:@"level"] intValue];
		
		int _qua = [[PlayerDataHelper shared] getEquipmentQuality:self.eid];
		
		Equipment* equipment = [Equipment getEquipment:self.rid
												   eid:self.eid
												  ueid:self.ueid
												  part:self.part
												 level:_level
											   quality:_qua];
		
		
		[self Category_AddChildToCenter:equipment z:2 tag:10102];
		/*
		UserEquipment* equip = [UserEquipment makeEquipment:self.eid level:_level quality:_qua];
		equip.target = self;
		equip.takeOffCall = @selector(doTakeOffEquipment);
		[self Category_AddChildToCenter:equip z:2 tag:10102];
		 */
		
	}
	
	[self checkEquipmentStatus];
}

-(void)updateWithDictionary:(int)_roleId dict:(NSDictionary*)_dict{
	
	[self removeEquipment];
	
	self.rid = _roleId ;
	
	[self updateWithDictionary:_dict];
	
}

-(void)checkEquipmentStatus{
	
	self.userAction = Equipment_action_none ;
	
	self.eDict = [[PlayerDataHelper shared] getNewEquipForRole:self.rid part:self.part-1];
	self.userAction = [[self.eDict objectForKey:@"action"] intValue];
	
	if (self.userAction != Equipment_action_none) {
		CCSimpleButton* bnt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_shift_1.png"
													  select:@"images/ui/button/bt_shift_2.png"
													  target:self
														call:@selector(doUpdateEquipment:)
													priority:-150];
		[self addChild:bnt z:10 tag:10101];
		
		bnt.position=ccp(self.contentSize.width -  POS_Shift_bt_offsetX,
						 self.contentSize.height - POS_Shift_bt_offsetY);
		
		return ;
	}
}

-(void)removeEquipment{
	
	[self removeChildByTag:10101 cleanup:YES];//清除按钮
	[self removeChildByTag:10102 cleanup:YES];//清除装备
	
	self.ueid = 0 ;
	self.eid  = 0 ;
	self.rid  = 0 ;
	self.userAction = Equipment_action_none ;
	
}

-(void)endUpdateEquipment{
	if ([PlayerPanel shared] != nil) {
		[[PlayerPanel shared] requestShiftWithPart:self.part action:self.eDict];
	}
}

-(void)doUpdateEquipment:(CCSimpleButton*)_sender{
	CCLOG(@"doUpdateEquipment:role->%d|part:%d",self.rid,self.part);
	if ([[PlayerPanel shared] isMarkModel]) {
		return ;
	}
	if (self.userAction != Equipment_action_none) {
		
		if (self.userAction == Equipment_action_swap) {
			//------
			[self endUpdateEquipment];
		}else if(self.userAction == Equipment_action_convert){
			
			int lv1 = [[PlayerDataHelper shared] getEquipmentLevel:self.ueid];
			NSDictionary* _temp = [self.eDict objectForKey:@"data"];
			int lv2 = [_temp intForKey:@"level"];
			
			int price = [[PlayerDataHelper shared] getEquipmentMoveCost:lv1 with:lv2];
			int money = [[GameConfigure shared] getPlayerMoney];
			
			if (money >= price) {
//				[[AlertManager shared] showMessage:[NSString stringWithFormat:@"转换装备强化等级需要花费%d银币，是否继续？",price]
//											target:self
//										   confirm:@selector(endUpdateEquipment)
//											 canel:nil];
                [[AlertManager shared] showMessage:[NSString stringWithFormat:NSLocalizedString(@"equipment_change_spend",nil),price]
											target:self
										   confirm:@selector(endUpdateEquipment)
											 canel:nil];
			}else{
//				[[AlertManager shared] showMessageWithConfirm:[NSString stringWithFormat:@"对不起，银币不够！完成该操作需要%d银币",price]
//													   target:nil
//														 call:nil];
                [[AlertManager shared] showMessageWithConfirm:[NSString stringWithFormat:NSLocalizedString(@"equipment_no_money",nil),price]
													   target:nil
														 call:nil];
			}
			
		}
	}
}

-(void)doTakeOffEquipment{
	CCLOG(@"doTakeOffEquipment:role->%d|part:%d",_rid,_part);
	if ([PlayerPanel shared] != nil && self.ueid > 0) {
		
		NSMutableDictionary* ___data = [NSMutableDictionary dictionary];
		[___data setObject:[NSNumber numberWithInt:self.ueid] forKey:@"id"];
		
		int _urid = [[PlayerDataHelper shared] getUserRoleId:self.rid];
		[___data setObject:[NSNumber numberWithInt:_urid] forKey:@"rid"];
		
		if ([PlayerPanel shared] != nil) {
			[[PlayerPanel shared] takeOffEquipment:___data];
		}
	}
}

-(BOOL)isShowUpdate{
	//检测是不是有更换装备的按钮
	CCNode* __node = [self getChildByTag:10101];
	return (__node != nil);
}

-(void)showInfo{
	//TODO show Info
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

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
	CCNode* ___node = [self getChildByTag:10102];
	if (___node != nil) {
		if ([___node isKindOfClass:[Equipment class]]) {
			Equipment* _temp = (Equipment*)___node;
			[_temp showOther:YES];
		}
		___node.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	if ([self isTouchInSite:touch]) {
		CCLOG(@"EquipmentTray->ccTouchBegan:%d",self.part);
		touchSwipe_ = touchPoint;
		
		status_ = 1 ;
		
		return YES;
	}
	return NO ;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	if ( (status_ == 1)&&((fabsf(touchPoint.x-touchSwipe_.x)>= 10)||(fabsf(touchPoint.y-touchSwipe_.y) >= 10))){
		
		status_ = 2;
		touchSwipe_ = touchPoint;
		
		//???
		[self.parent reorderChild:self z:INT16_MAX];
		//[[PlayerPanel shared] reorderChild:self z:INT16_MAX];
		
		CCNode* ___node = [self getChildByTag:10102];
		if (___node != nil) {
			if ([___node isKindOfClass:[Equipment class]]) {
				Equipment* _temp = (Equipment*)___node;
				[_temp showOther:NO];
			}
		}
		
	}
	
	if (status_ == 2) {
		CGPoint temp = ccpSub(touchPoint, touchSwipe_);
		CCLOG(@"touchMoved:x=%f|y=%f",temp.x,temp.y);
		CGPoint newPt = ccpAdd(temp, ccp(self.contentSize.width/2, self.contentSize.height/2));
		
		CCNode* ___node = [self getChildByTag:10102];
		if (___node != nil) {
			___node.position = newPt;
		}
	}
	
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if (status_ == 1) {
		if (self.ueid != 0 && self.part != 0) {
			[[PlayerPanel shared] requestShowEquipmentDescribe:self.ueid part:self.part];
		}
	}
	
	if (status_ == 2) {
		[self.parent reorderChild:self z:INT16_MAX-10];
		
		CCNode* ___node = [self getChildByTag:10102];
		if (___node != nil) {
			if ([___node isKindOfClass:[Equipment class]]) {
				Equipment* _temp = (Equipment*)___node;
				[_temp showOther:YES];
				_temp.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
			}
		}
		
		[self doTakeOffEquipment];
	}
}



@end
