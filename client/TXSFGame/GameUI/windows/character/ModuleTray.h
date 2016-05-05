//
//  ModuleTray.h
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "Config.h"

@interface ModuleTray : CCSprite<CCTouchOneByOneDelegate>
{
	int _xid;
	int _uxid;
	int _belongId;
	
	ItemTray_type _type;
	
	CGPoint touchSwipe_;
	int status_;
	
	id		_takeOffTarget;
	SEL		_takeOffCall;
}

@property(nonatomic, assign) int xid;
@property(nonatomic, assign) int uxid;
@property(nonatomic, assign) int belongId;

@property(nonatomic, assign) ItemTray_type type;
@property(nonatomic, assign) id takeOffTarget;
@property(nonatomic, assign) SEL takeOffCall;


+(ModuleTray*)create:(ItemTray_type)_t;

// 外部根据实际情况调用
-(void)doTakeOffItem;

-(void)updateWithDictionary:(int)_bid dict:(NSDictionary*)_dict;
-(void)updateWithDictionary:(NSDictionary*)_dict;

@end
