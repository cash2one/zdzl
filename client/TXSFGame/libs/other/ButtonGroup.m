//
//  ButtonGroup.m
//  TXSFGame
//
//  Created by Soul on 13-2-1.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ButtonGroup.h"


@implementation ButtonGroup

//
//获得当前选择项的索引
//
-(int)getSelectedIndex{
	CCMenuItem* item = nil ;
	int index = 0 ;
	CCARRAY_FOREACH(_children, item){
		if (item == _selectedItem) {
			return index;
		}
		index++;
	}
	return -1;
}

-(void)removeChild:(CCNode *)node cleanup:(BOOL)cleanup{
	//
	CCMenuItem* _temp = (CCMenuItem*)node;
	if (_temp == _selectedItem) {
		_selectedItem = nil ;
	}
	//
	[super removeChild:node cleanup:cleanup];
}

//
//设置当前的激活的选项
//
- (void)setSelectedItem:(CCMenuItem *)_item {
	
	NSAssert(nil != _item, @"[ButtonGroup setSelectedItem] -- invalid _item");
	
	if (_item == _selectedItem) {
		return ;
	}
	
	if (nil != _selectedItem) {
		if (_selectedItem.isSelected) {
			[_selectedItem unselected];
		}
	}
    _selectedItem = _item;
	if (!_selectedItem.isSelected) {
		[_selectedItem selected];
	}
	[_selectedItem activate];
	
}

-(void) alignItemsVerticallyWithPadding:(float)padding
{
	float height = -padding;
	
	CCMenuItem *item;
	CCARRAY_FOREACH(_children, item)
	height += item.contentSize.height * item.scaleY + padding;
	
	float y = height / 2.0f;
	
	float itemWidth = 0 ;
	CCARRAY_FOREACH(_children, item) {
		CGSize itemSize = item.contentSize;
		if (itemSize.width > itemWidth) {
			itemWidth = itemSize.width;
		}
	    [item setPosition:ccp(0, y - itemSize.height * item.scaleY / 2.0f)];
	    y -= itemSize.height * item.scaleY + padding;
	}
	
	self.contentSize = CGSizeMake(itemWidth, height);
	
}


-(void) alignItemsHorizontallyWithPadding:(float)padding
{
	
	float width = -padding;
	CCMenuItem *item;
	CCARRAY_FOREACH(_children, item)
	width += item.contentSize.width * item.scaleX + padding;
	
	float x = -width / 2.0f;
	
	float itemHeight = 0 ;
	CCARRAY_FOREACH(_children, item){
		CGSize itemSize = item.contentSize;
		if (itemSize.height > itemHeight) {
			itemHeight = itemSize.height;
		}
		[item setPosition:ccp(x + itemSize.width * item.scaleX / 2.0f, 0)];
		x += itemSize.width * item.scaleX + padding;
	}
	
	self.contentSize = CGSizeMake(width, itemHeight);
	
	//adjuest
	CCARRAY_FOREACH(_children, item){
		CGPoint pt = item.position;
		pt = ccpAdd(pt, ccp(self.contentSize.width/2, self.contentSize.height/2));
		[item setPosition:pt];
	}
	
}

//
//判断被选中的菜单项
//
-(CCMenuItem *) itemForTouch: (UITouch *) touch
{
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	CCMenuItem* item = nil ;
	CCARRAY_FOREACH(_children, item){
		if ( [item visible] && [item isEnabled] ) {
			CGPoint local = [item convertToNodeSpace:touchLocation];
			//CGRect r = [item rect];
			CGRect r = [item activeArea];
			r.origin = CGPointZero;
			if( CGRectContainsPoint( r, local ) ){
				return item;
			}
		}
	}
	return nil;
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	
    if ( _state != kCCMenuStateWaiting ) return NO;
    
    CCMenuItem *item = [self itemForTouch:touch];
    m_Item = item;
    
    if (m_Item) {
        if (_selectedItem != item) {
            [_selectedItem unselected];//
			[item selected];//
        }
        _state = kCCMenuStateTrackingTouch;
        return YES;
    }
    return NO;
	
}

- (void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	
    NSAssert(_state == kCCMenuStateTrackingTouch, @"[Menu ccTouchEnded] -- invalid state");
	
    CCMenuItem *item = [self itemForTouch:touch];
    if (item != m_Item && item != nil) {
        [_selectedItem selected];
        [m_Item unselected];
        m_Item = nil;
        _state = kCCMenuStateWaiting;
        return;
    }
	
	[self setSelectedItem:m_Item];
    m_Item = nil;
	
	_state = kCCMenuStateWaiting;
    
}

- (void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
	
    NSAssert(_state == kCCMenuStateTrackingTouch, @"[Menu ccTouchCancelled] -- invalid state");
	
	if(_selectedItem!=m_Item){
		[m_Item unselected];
		[_selectedItem selected];
	}
    m_Item = nil;
	
	_state = kCCMenuStateWaiting;
    
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	NSAssert(_state == kCCMenuStateTrackingTouch, @"[Menu ccTouchMoved] -- invalid state");
	
	CCMenuItem *item = [self itemForTouch:touch];
    if (item != m_Item && item != nil) {
        [m_Item unselected];
        [item selected];
        m_Item = item;
        return;
    }
    
}

@end
