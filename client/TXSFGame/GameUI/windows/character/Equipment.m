//
//  Equipment.m
//  TXSFGame
//
//  Created by Soul on 13-3-10.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "Equipment.h"
#import "CCNode+AddHelper.h"
#import "Config.h"

#define Equipment_default_width				cFixedScale(86)
#define Equipment_default_height			cFixedScale(86)
#define CGR_rect CGRectMake(cFixedScale(150), 0, cFixedScale(15), cFixedScale(25))
#define POS_num_2_x cFixedScale(15)

@implementation Equipment

@synthesize rid  = _rid;
@synthesize eid  = _eid;
@synthesize ueid = _ueid;

@synthesize part = _part;
@synthesize level = _level;
@synthesize quality = _quality;


+(Equipment*)getEquipment:(int)_role eid:(int)_e ueid:(int)_ue part:(int)_p level:(int)_lv quality:(int)_q{
	Equipment* equipment = [Equipment node];
	
	//___________________________
	//
	//___________________________
	
	equipment.rid = _role;
	equipment.eid = _e;
	equipment.ueid = _ue;
	equipment.part = _p;
	equipment.level = _lv;
	equipment.quality = _q;
	
	//___________________________
	//
	//___________________________
	
	return equipment;
}

-(void)dealloc{
	[super dealloc];
}

-(id)init{
	if (self=[super init]) {
		self.contentSize=CGSizeMake(Equipment_default_width, Equipment_default_height);
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	[super onExit];
}

-(void)showOther:(BOOL)_isShow{

	CCNode* n1 = [self getChildByTag:2007];
	CCNode* n2 = [self getChildByTag:2008];
	
	CCNode* n3 = [self getChildByTag:2009];
	CCNode* n4 = [self getChildByTag:2010];
	
	if (n1)		n1.visible = _isShow;
	if (n2)		n2.visible = NO;
	if (n3)		n3.visible = _isShow;
	if (n4)		n4.visible = _isShow;
	
}

-(void)showSelect:(BOOL)_isSelect{
	
}

-(void)setQuality:(ItemQuality)quality{
	_quality = quality;
	
	[self removeChildByTag:2007 cleanup:YES];
	[self removeChildByTag:2008 cleanup:YES];
	
	if (_quality < IQ_WHITE) return ;
	
	NSString* path = [NSString stringWithFormat:@"images/ui/common/quality%d.png",quality];
	CCSprite* __sprite = [CCSprite spriteWithFile:path];
	__sprite.tag = 2007 ;
	__sprite.visible= YES;
	[self Category_AddChildToCenter:__sprite];
	
	NSString* path2 = [NSString stringWithFormat:@"images/ui/common/quality%dSelect.png",quality];
	CCSprite* __sprite2 = [CCSprite spriteWithFile:path2];
	__sprite2.tag = 2008;
	__sprite2.visible= NO;
	[self Category_AddChildToCenter:__sprite2];
	
}

-(void)setLevel:(int)level{
	_level = level ;
	
	[self removeChildByTag:2009 cleanup:YES];
	[self removeChildByTag:2010 cleanup:YES];
	
	if (_level <= 0) return ;
	
	CGRect rect = CGR_rect;
	CCSprite *num_1 = [CCSprite spriteWithFile:@"images/ui/num/num-1.png" rect:rect];
	
	CCSprite *num_2 = getImageNumber(@"images/ui/num/num-1.png", 15, 20, _level);
	
	[self addChild:num_1 z:5];
	[self addChild:num_2 z:5];
	
	num_1.anchorPoint = num_2.anchorPoint = ccp(0, 1.0);
	
	num_1.tag = 2009 ;
	num_2.tag = 2010 ;
	
	num_1.position=ccp(0, self.contentSize.height);
	num_2.position=ccp(POS_num_2_x, self.contentSize.height);
	
}

-(void)setEid:(int)eid{
	_eid = eid ;
	
	[self removeChildByTag:3008 cleanup:YES];
	
	if (eid <= 0) return ;
	
	CCSprite* __sprite = getEquipmentIcon(_eid);
	
	if (__sprite != nil) {
		__sprite.tag = 3008;
		[self Category_AddChildToCenter:__sprite z:1];
	}
	
}

@end
