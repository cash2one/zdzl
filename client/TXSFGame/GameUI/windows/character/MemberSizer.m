//
//  MemberSizer.m
//  TXSFGame
//
//  Created by Soul on 13-7-11.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "MemberSizer.h"
#import "ButtonGroup.h"
#import "GameConfigure.h"
#import "CCNode+AddHelper.h"
#import "Config.h"

#define MemberSizer_TouchPriority -2
#define MemberSizer_defaultSize   CGSizeMake(cFixedScale(100), cFixedScale(508))


static inline NSArray* getRoleTab(int rid){
	if (rid <= 0) {
		CCLOG(@"PlayerPanel->getRoleTab:%d",rid);
		return nil;
	}
	CCSprite* bg1 = nil;
	CCSprite* bg2 = nil;
	CCSprite* i1  = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
	CCSprite* i2  = getCharacterIcon(rid, ICON_PLAYER_NORMAL);
	bg1 = [CCSprite spriteWithFile:@"images/ui/panel/t26.png"];
	bg2 = [CCSprite spriteWithFile:@"images/ui/panel/t27.png"];
	if (iPhoneRuningOnGame()) {
		[bg1 addChild:i1];
		[bg2 addChild:i2];
		i2.position=ccp(bg2.contentSize.width- bg2.contentSize.width/2.0f+0.75f,bg2.contentSize.height/2.0f);
		i1.position=i2.position;
	}else{
		[bg1 Category_AddChildToCenter:i1];
		[bg2 Category_AddChildToCenter:i2];
	}
	
	NSArray* array = [NSArray arrayWithObjects:bg1,bg2,nil];
	
	return array;
}


@implementation MemberSizer

@synthesize call = call_;
@synthesize target = target_;
@synthesize defaultIndex = _defaultIndex;
@synthesize clearance = _clearance;


+(MemberSizer*)create:(NSArray*)_array target:(id)target call:(SEL)call defaultIndex:(int)_default{
	MemberSizer* _MemberSizer = [MemberSizer node];
	[_MemberSizer addArray:_array];
	_MemberSizer.defaultIndex = _default;
	_MemberSizer.target = target;
	_MemberSizer.call = call;
	return _MemberSizer;
}

-(id)init{
	if ((self = [super init]) != nil) {
		
		_members = [NSMutableArray array];
		[_members retain];
		
		self.clearance = 4 ;
		self.contentSize = MemberSizer_defaultSize;
//		CCSprite* sprite = [CCSprite spriteWithFile:@"images/ui/panel/t26.png"];
////		if (iPhoneRuningOnGame()) {
////			sprite.scale=1.1f;
////		}
//		self.contentSize = CGSizeMake(sprite.contentSize.width,
//									  sprite.contentSize.height*7 + 7*_clearance);
		
		
		
	}
	return self;
}

-(void)dealloc{
	if (_members) {
		[_members release];
		_members = nil ;
	}
	[super dealloc];
}

-(void)addArray:(NSArray *)_array{
	if (_members) {
		[_members addObjectsFromArray:_array];
	}
}

-(void)onEnter{
	[super onEnter];
	
	_buttons =[ButtonGroup node];
	[_buttons setTouchPriority:MemberSizer_TouchPriority];
	[self addChild:_buttons z:-1];
	
	[self showMembers];
}
-(void) setTouchEnabled:(BOOL)enabled
{
    [super setTouchEnabled:enabled];
    if (_buttons) {
        [_buttons setTouchEnabled:enabled];
    }
}
-(void)setClearance:(int)clearance{
	if (iPhoneRuningOnGame()) {
		_clearance = clearance*0.6 ;
	}else{
		_clearance = clearance ;
	}
	
}
-(void)showMembers{
	if (_buttons == nil || _members.count <= 0) {
		return ;
	}
	
	[_buttons removeAllChildrenWithCleanup:YES];
	[_members sortUsingSelector:@selector(compare:)];
	
	for (NSNumber *number in _members) {
		NSArray* spr = getRoleTab([number intValue]);
		CCMenuItem *_item = [CCMenuItemImage itemWithNormalSprite:[spr objectAtIndex:0]
												   selectedSprite:[spr objectAtIndex:1]
														   target:self
														 selector:@selector(doSelect:)];
		
		[_buttons addChild:_item];
		_item.tag = [number intValue];
		
	}
	
	[_buttons alignItemsVerticallyWithPadding:_clearance];
	[self adjustRoleTabsPosition];
	
	CCMenuItem* ___item = (CCMenuItem*)[_buttons getChildByTag:_defaultIndex];
	if (___item) {
		[_buttons setSelectedItem:___item];
	}else{
		if (_members.count > 0) {
			int ___rid = [[_members objectAtIndex:0] intValue];
			CCMenuItem* ___item = (CCMenuItem*)[_buttons getChildByTag:___rid];
			if (___item) {
				[_buttons setSelectedItem:___item];
			}
		}
	}

}

-(void)doSelect:(CCMenuItem*)sender{
	if (target_ != nil && call_ != nil) {
		[target_ performSelector:call_ withObject:[NSNumber numberWithInt:sender.tag]];
	}
}

-(void)adjustRoleTabsPosition{
	if (_buttons != nil) {
		CGSize size = _buttons.contentSize;
		CGSize __size = self.contentSize;
		_buttons.position=ccp(__size.width/2,__size.height - size.height/2 - _clearance/2);
		self.contentSize = CGSizeMake(size.width, self.contentSize.height);
	}
}

-(void)removeMember:(int)_rid{
	//主角不给离开
	int prid = [[GameConfigure shared] getPlayerRole];
	if (prid == _rid) return ;
	
	if (_rid > 0 && _buttons != nil) {
		//一切为了上一次
		int perRole = 0 ;
		for (NSNumber *number in  _members) {
			int _number = [number intValue] ;
			if (_rid == _number) {
				[_members removeObject:number];
				break ;
			}
			perRole = _number ;
		}
		
		[_buttons removeChildByTag:_rid cleanup:YES];
		[_buttons alignItemsVerticallyWithPadding:_clearance];
		[self adjustRoleTabsPosition];
		
		
		CCMenuItem* ___item = (CCMenuItem*)[_buttons getChildByTag:perRole];
		if (___item) {
			[_buttons setSelectedItem:___item];
		}else{
			if (_members.count > 0) {
				int ___rid = [[_members objectAtIndex:0] intValue];
				CCMenuItem* ___item = (CCMenuItem*)[_buttons getChildByTag:___rid];
				if (___item) {
					[_buttons setSelectedItem:___item];
				}
			}
		}
		
	}
}

@end
