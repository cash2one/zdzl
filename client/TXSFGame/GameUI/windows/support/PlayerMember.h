//
//  PlayerMember.h
//  TXSFGame
//
//  Created by Soul on 13-5-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Widget.h"
#import "WidgetTable.h"

@class WidgetContainer;

@interface MemberTab : Widget{
	int		_rid;
	BOOL    _selected;
}
@property(nonatomic,assign)int		rid;
@property(nonatomic,assign)BOOL		selected;
@end

@interface PlayerMember : WidgetTable<CCTouchOneByOneDelegate>{
	NSArray* members;
	NSMutableArray* tabs;
	int		 startIndex;
}
@property(nonatomic,retain)NSArray* members;
@property(nonatomic,assign)int startIndex;

+(PlayerMember*)defaultInstance:(id)__target call:(SEL)___call;
+(PlayerMember*)defaultInstance:(id)__target call:(SEL)___call start:(int)_index;
+(PlayerMember*)create:(CGSize)size;
+(PlayerMember*)create:(CGSize)size array:(NSArray*)ary;
+(PlayerMember*)create:(CGSize)size array:(NSArray*)ary start:(int)index;

-(void)removeMemberTab:(int)_rid;

@end
