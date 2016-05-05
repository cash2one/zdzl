//
//  EquipmentTray.h
//  TXSFGame
//
//  Created by Soul on 13-3-10.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

/*
 *装备的托盘
 */

@interface EquipmentTray : CCSprite<CCTouchOneByOneDelegate> {
	int _ueid;
	int _eid;
	int _part;
	int _rid;
	BOOL _isShowInfo;
	NSDictionary* _eDict;
	EQUIPMENT_ACTION_TYPE _userAction;
	
	
	CGPoint touchSwipe_;
	
	int status_;
}

@property(nonatomic,assign)BOOL isShowInfo;
@property(nonatomic,assign)int  ueid;
@property(nonatomic,assign)int  eid;
@property(nonatomic,assign)int  part;
@property(nonatomic,assign)int  rid;
@property(nonatomic,retain)NSDictionary* eDict;
@property(nonatomic,assign)EQUIPMENT_ACTION_TYPE userAction;

-(void)updateWithDictionary:(int)_roleId dict:(NSDictionary*)_dict;

@end
