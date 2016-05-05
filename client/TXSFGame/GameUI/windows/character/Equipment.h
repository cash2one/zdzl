//
//  Equipment.h
//  TXSFGame
//
//  Created by Soul on 13-3-10.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

@interface Equipment : CCSprite {
	int				_rid;
	int				_eid;
	int             _ueid;
	
	int				_part;
	int				_level;
	ItemQuality		_quality;
	
}

@property(nonatomic,assign)int rid;
@property(nonatomic,assign)int eid;
@property(nonatomic,assign)int ueid;
@property(nonatomic,assign)int part;
@property(nonatomic,assign)int level;
@property(nonatomic,assign)ItemQuality quality;


+(Equipment*)getEquipment:(int)_role eid:(int)_e ueid:(int)_ue part:(int)_p level:(int)_lv quality:(int)_q;


-(void)showSelect:(BOOL)_isSelect;
-(void)showOther:(BOOL)_isShow;


@end
