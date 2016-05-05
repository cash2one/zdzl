//
//  UserObject.h
//  TXSFGame
//
//  Created by Soul on 13-3-4.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"


typedef enum{
	UIObject_none = 0 ,
	UIObject_equipment = 1 ,
}UIObject_type;

typedef enum{
	
	Touch_wait  = 0 ,
	Touch_begin = 1 ,
	Touch_move  = 2 ,
	Touch_end   = 3 ,
	
}Touch_event;


#pragma mark UserObject
@interface UserObject : CCSprite {
	int		_rid;
	int		_objectId;
	
	Touch_event _event ;
	
	ItemQuality		_quality;
}
@property(nonatomic,assign)int  rid;
@property(nonatomic,assign)int  objectId;

@property(nonatomic,assign)Touch_event event;
@property(nonatomic,assign)ItemQuality quality;

-(int)getType;

@end


#pragma mark UserEquipment
@interface UserEquipment : UserObject<CCTouchOneByOneDelegate>{
	
	int             _ueid;
	int				_part;
	int				_level;
	
	BOOL			_isSelect;
	BOOL			_isPick;
	
	id				_target;
	SEL				_takeOffCall;
	SEL				_showInfoCall;
}

@property(nonatomic,assign)id  target;
@property(nonatomic,assign)SEL takeOffCall;
@property(nonatomic,assign)SEL showInfoCall;

@property(nonatomic,assign)int ueid;
@property(nonatomic,assign)int part;
@property(nonatomic,assign)int level;

@property(nonatomic,assign)BOOL isSelect;
@property(nonatomic,assign)BOOL isPick;

+(UserEquipment*)makeEquipment:(int)_eid level:(int)_lv quality:(int)_quality;

@end

#pragma mark UserItem








