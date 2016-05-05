//
//  MemberSizer.h
//  TXSFGame
//
//  Created by Soul on 13-7-11.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"

@class ButtonGroup;

@interface MemberSizer : CCLayer{
	id  target_;
	SEL call_;
	ButtonGroup*		_buttons;
	NSMutableArray*		_members;
	int					_defaultIndex;
	int					_clearance;
}

@property(nonatomic,assign)id				target;
@property(nonatomic,assign)SEL				call;
@property(nonatomic,assign)int				defaultIndex;
@property(nonatomic,assign)int				clearance;

+(MemberSizer*)create:(NSArray*)_array target:(id)target call:(SEL)call defaultIndex:(int)_default;
-(void)addArray:(NSArray*)_array;
-(void)removeMember:(int)_rid;

@end
