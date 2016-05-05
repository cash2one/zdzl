//
//  PlayerMember.m
//  TXSFGame
//
//  Created by Soul on 13-5-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "PlayerMember.h"
#import "CCNode+AddHelper.h"
#import "Config.h"
#import "GameConfigure.h"

enum{
	MemberTab_default_no		= 1009,
	MemberTab_default_yes		= 1010,
};

@implementation MemberTab

@synthesize rid = _rid;
@synthesize selected = _selected;

-(id)init{
	if ((self = [super init]) != nil) {
		
		CCSprite* p1 = [CCSprite spriteWithFile:@"images/ui/panel/t26.png"];
		CCSprite* p2 = [CCSprite spriteWithFile:@"images/ui/panel/t27.png"];
		
		[self setContentSize:p1.contentSize];
		[self Category_AddChildToCenter:p1 z:1 tag:MemberTab_default_no];
		[self Category_AddChildToCenter:p2 z:0 tag:MemberTab_default_yes];
		
		
		[self setSelected:NO];
		
		_touchEvent = YES;
		
	}
	return self;
}

-(void)setRid:(int)rid{
	_rid = rid;
	
	CCNode* n1 = [self getChildByTag:MemberTab_default_no];
	if (n1) {
		CCSprite* i1  = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
		[n1 Category_AddChildToCenter:i1];
	}
	
	CCNode* n2 = [self getChildByTag:MemberTab_default_yes];
	if (n2) {
		CCSprite* i2  = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
		[n2 Category_AddChildToCenter:i2];
	}
}

-(void)setSelected:(BOOL)selected{
	_selected = selected;
	
	CCNode* n1 = [self getChildByTag:MemberTab_default_no];
	CCNode* n2 = [self getChildByTag:MemberTab_default_yes];
	
	if (n1 != nil) {
		if (_selected) {
			n1.visible = NO ;
		}else{
			n1.visible = YES ;
		}
	}
	
	if (n2 != nil) {
		if (_selected) {
			n2.visible = YES ;
		}else{
			n2.visible = NO ;
		}
	}
	
}

-(void)resetStatus{
	self.selected = NO;
}

@end

@implementation PlayerMember

@synthesize members;
@synthesize startIndex;

+(PlayerMember*)defaultInstance:(id)__target call:(SEL)___call{
	return [PlayerMember defaultInstance:__target call:___call start:0];
}

+(PlayerMember*)defaultInstance:(id)__target call:(SEL)___call start:(int)_index{
	NSArray* array = [[GameConfigure shared] getRoleWithStatus:RoleStatus_in];
	CGSize size = CGSizeMake(120, 500);
	PlayerMember* result = [PlayerMember create:size array:array start:_index];
	result.target = __target;
	result.call = ___call;
	return result;
}

+(PlayerMember*)create:(CGSize)size{
	return [PlayerMember create:size array:nil];
}

+(PlayerMember*)create:(CGSize)size array:(NSArray *)ary{
	return [PlayerMember create:size array:ary start:0];
}

+(PlayerMember*)create:(CGSize)size array:(NSArray *)ary start:(int)index{
	PlayerMember* result = [PlayerMember node];
	result.contentSize = size;
	result.members = ary;
	result.startIndex = index;
	return result;
}

-(id)init{
	if ((self = [super init]) != nil) {
		_alignType = AlignType_linear_y;
		
		tabs = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc{
	if (members != nil) {
		[members release];
		members = nil;
	}
	if (tabs != nil) {
		[tabs release];
		tabs = nil;
	}
	[super dealloc];
}

-(void)onEnter{
	[super onEnter];
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-10 swallowsTouches:YES];
	
	[self initMembers];
	
}

-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(void)removeMemberTab:(int)_rid{
	for (MemberTab* tab in tabs) {
		if (tab.rid == _rid) {
			[self removeCell:tab];
			[tabs removeObject:tab];
			break ;
		}
	}
}

-(void)removeCell:(Widget *)widget{
	[super removeCell:widget];
	[self adjustPosition:ccp(0.5, 1)];
}

-(void)initMembers{
	if (members != nil) {
		NSMutableArray* temp = [NSMutableArray arrayWithArray:members];
		[temp sortUsingSelector:@selector(compare:)];
		int i = 0;
		for (NSNumber *number in members) {
			MemberTab* tab = [MemberTab node];
			tab.rid = [number intValue];
			
			[self addCell:tab];
			[tabs addObject:tab];
			
			if (i == startIndex) {
				[self focusWidget:tab];
			}
			
			i++;
		}
		[self alignWidgets];
		[self adjustPosition:ccp(0.5, 1)];
	}
}

-(BOOL)focusWidget:(Widget *)widget{
	if (![super focusWidget:widget]) {
		return NO;
	}
	if (widget != nil) {
		[self resetStatus];
		MemberTab* tab = (MemberTab*)widget;
		tab.selected = YES;
		if (_target != nil && _call != nil) {
			[_target performSelector:_call
						  withObject:[NSNumber numberWithInt:tab.rid]];
		}
	}
	return NO;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	return [self touchBegan:touch withEvent:event];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	[self touchEnded:touch withEvent:event];
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	[self touchMoved:touch withEvent:event];
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
	[self touchCancelled:touch withEvent:event];
}

@end
