//
//  CCLayerList.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-20.
//  Copyright 2012 eGame. All rights reserved.
//

#import "CCLayerList.h"

@implementation CCLayerList

@synthesize paddingX = paddingX;
@synthesize paddingY = paddingY;
@synthesize startPos = startPos;
@synthesize layout = layout;
@synthesize row = nRow;
@synthesize col = nCol;
@synthesize delegate = delegate_;
@synthesize isDownward = isDownward_;
@synthesize isRight2Left = isRight2Left_;
@synthesize isForce = isForce_;

+(CCLayerList*)listWith:(LAYOUT_TYPE)_layout :(CGPoint)_offset :(float)_px :(float)_py
{
	return [[[CCLayerList alloc]create:_layout :_offset :_px :_py] autorelease];
}
+(CCLayerList*)meshlist:(int)_row :(int)_col :(CGPoint)_offset :(float)_px :(float)_py
{
	CCLayerList* _list = [[[CCLayerList alloc]create:LAYOUT_G :_offset :_px :_py] autorelease];
	if (_list) {
		[_list setRow:_row];
		[_list setCol:_col];
	}
	return _list;
}

-(CCLayerList*)create:(LAYOUT_TYPE)_layout :(CGPoint)_offset :(float)_px :(float)_py
{
	if( (self=[super initWithColor:ccc4(0, 0, 0, 0) width:20 height:20]) ) {
		self.paddingX = _px;
		self.paddingY = _py;
		self.startPos = _offset;
		self.layout = _layout;
		self.touchEnabled = YES;
		self.isForce = YES;
	}
	return self;
}

-(CCListItem *) itemForTouch: (UITouch *) touch
{
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	
	CCListItem* item;
	CCARRAY_FOREACH(_children, item){
		
		if ( [item visible] && [item isEnabled] ) {
			
			CGPoint local = [item convertToNodeSpace:touchLocation];
			CGRect r = [item rect];
			r.origin = CGPointZero;
			
			if( CGRectContainsPoint( r, local ) )
				return item;
		}
	}
	return nil;
}

-(void)addChild:(CCNode *)node
{
	[super addChild:node];
	[self _layout];
}

-(void)addChild:(CCNode *)node z:(NSInteger)z2
{
	[super addChild:node z:z2];
	[self _layout];
}

-(void)addChild:(CCNode *)node z:(NSInteger)z2 tag:(NSInteger)tag
{
	[super addChild:node z:z2 tag:tag];
	[self _layout];
}

-(void) registerWithTouchDispatcher
{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority+2 swallowsTouches:YES];
}

-(void) setSelected:(CCListItem*)_item
{
	CCListItem *item;
	CCARRAY_FOREACH(_children, item){
		
		if ( item == _item) {
			[item setIsSelect:YES];
			if (delegate_) {
				if ([self.delegate respondsToSelector:@selector(selectedEvent::)])
				{
					[delegate_ selectedEvent:self :item];
				}
				
			}
		}
		else {
			[item setIsSelect:NO];
		}
	}
}
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	
	if(!_visible)
		return NO;
	
	for( CCNode *c = self.parent; c != nil; c = c.parent )
		if( c.visible == NO )
			return NO;
	
	CCListItem *selectedItem_ = [self itemForTouch:touch];
	
	if( selectedItem_ ) {
		[self setSelected:selectedItem_];
		if (delegate_) {
			if ([delegate_ respondsToSelector:@selector(callbackTouch:::)]) {
				[delegate_ callbackTouch:self :selectedItem_ :touch];
			}
		}
		[selectedItem_ setIsSelect:true];
		if (self.isForce) {
			return YES;
		}
	}
	return NO;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	//	NSAssert(state_ == kCCMenuStateTrackingTouch, @"[Menu ccTouchEnded] -- invalid state");
	//	
	//	[selectedItem_ unselected];
	//	[selectedItem_ activate];
	//	
	//	state_ = kCCMenuStateWaiting;
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	//	NSAssert(state_ == kCCMenuStateTrackingTouch, @"[Menu ccTouchCancelled] -- invalid state");
	//	
	//	[selectedItem_ unselected];
	//	
	//	state_ = kCCMenuStateWaiting;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	//	NSAssert(state_ == kCCMenuStateTrackingTouch, @"[Menu ccTouchMoved] -- invalid state");
	//	
	//	CCMenuItem *currentItem = [self itemForTouch:touch];
	//	
	//	if (currentItem != selectedItem_) {
	//		[selectedItem_ unselected];
	//		selectedItem_ = currentItem;
	//		[selectedItem_ selected];
	//	}
}
-(CGSize)calItemSize:(CCListItem*)_item
{
	float _max_x = 2;
	float _max_y = 2;
	
	if (_item) {
		CCArray *mychildren = [_item children];
		CCListItem *item;
		
		CCARRAY_FOREACH(mychildren, item)
		{
			if (item.contentSize.height*item.scaleY > _max_y) {
				_max_y = item.contentSize.height*item.scaleY;
			}
			if (item.contentSize.width*item.scaleX > _max_x) {
				_max_x = item.contentSize.width*item.scaleX;
			}
		}
		
	}
	return CGSizeMake(_max_x, _max_y);
}
-(void) _Vlayout
{
	float _max_x = 0 ;
	float _max_y = -paddingY ;
	
	CCListItem *item;
	CCARRAY_FOREACH(_children, item)
	{
		if (item.contentSize.width == 0 || item.contentSize.height == 0) {
			item.contentSize =  [self calItemSize:item];
		}
		if (item.contentSize.width*item.scaleX > _max_x) {
			_max_x = item.contentSize.width*item.scaleX;
		}
		_max_y += (paddingY + item.contentSize.height*item.scaleY);
	}
	
	_max_x += (startPos.x*2);
	_max_y += (startPos.y*2);
	
	self.contentSize = CGSizeMake(_max_x, _max_y);
	
	item = nil;
	
	if (isDownward_) {
		CGSize _size = self.contentSize;
		float _x = _max_x/2;
		float _py = _size.height - startPos.y;
		
		CCARRAY_FOREACH(_children, item)
		{
			CGSize itemSize = item.contentSize;
			item.anchorPoint = ccp(0.5f, 0.5f);
			item.position = ccp(_x, _py - (itemSize.height*item.scaleY)/2);
			_py -= (itemSize.height*item.scaleY + paddingY);
		}
		
	}
	else {
		float _x = _max_x/2;
		float _py = startPos.y;
		
		CCARRAY_FOREACH(_children, item)
		{
			CGSize itemSize = item.contentSize;
			item.anchorPoint = ccp(0.5f, 0.5f);
			item.position = ccp(_x, _py + (itemSize.height*item.scaleY)/2);
			_py += (itemSize.height*item.scaleY + paddingY);
		}
	}
	
	
}
-(void) _Hlayout
{
	float _max_x = -paddingX ;
	float _max_y = 0 ;
	
	CCListItem *item;
	CCARRAY_FOREACH(_children, item)
	{
		if (item.contentSize.width == 0 || item.contentSize.height == 0) {
			item.contentSize =  [self calItemSize:item];
		}
		if (item.contentSize.height*item.scaleY > _max_y) {
			_max_y = item.contentSize.height*item.scaleY;
		}
		_max_x += (paddingX + item.contentSize.width*item.scaleX);
	}
	
	_max_x += (startPos.x*2);
	_max_y += (startPos.y*2);
	
	self.contentSize = CGSizeMake(_max_x, _max_y);
	
	item = nil;
	
	if (isRight2Left_) {
		CGSize _size = self.contentSize;
		float _x = _size.width -  startPos.x;
		float _y = _max_y/2;
		
		CCARRAY_FOREACH(_children, item)
		{
			CGSize itemSize = item.contentSize;
			item.anchorPoint = ccp(0.5f, 0.5f);
			item.position = ccp(_x - (itemSize.width*item.scaleX/2),_y);
			_x -= (itemSize.width*item.scaleX + paddingX);
		}
	}
	else {
		float _x = startPos.x;
		float _y = _max_y/2;
		
		CCARRAY_FOREACH(_children, item)
		{
			CGSize itemSize = item.contentSize;
			item.anchorPoint = ccp(0.5f, 0.5f);
			item.position = ccp(_x + (itemSize.width*item.scaleX/2),_y);
			_x += (itemSize.width*item.scaleX + paddingX);
		}
	}
	
}
-(void) _Glayout
{
	//TODO
	float _max_x = 0 ;
	float _max_y = 0 ;
	CCListItem *item;
	CCARRAY_FOREACH(_children, item)
	{
		if (item.contentSize.width == 0 || item.contentSize.height == 0) {
			item.contentSize =  [self calItemSize:item];
		}
		if (item.contentSize.height*item.scaleY > _max_y) {
			_max_y = item.contentSize.height*item.scaleY;
		}
		if (item.contentSize.width*item.scaleX > _max_x) {
			_max_x = item.contentSize.width*item.scaleX;
		}
	}
	
	item = nil;
	float _px = -paddingX;
	float _py = -paddingY;
	
	for (int i = 0 ; i < nCol; i++) {
		_px += (paddingX + _max_x);
	}
	
	for (int i = 0 ; i < nRow; i++) {
		_py += (paddingY + _max_y);
	}
	
	_px += startPos.x*2;
	_py += startPos.y*2;
	
	self.contentSize = CGSizeMake(_px, _py);
	
	if (isDownward_) {
		int _r = 0 ;
		int _c = 0 ;
		CGSize _size = self.contentSize;
		float _dx = startPos.x ;
		float _dy = _size.height - startPos.y ;
		CCARRAY_FOREACH(_children, item)
		{
			
			item.anchorPoint = ccp(0.5f, 0.5f);
			item.position = ccp(_dx + _max_x/2,_dy - _max_y/2);
			_dx += (paddingX + _max_x);
			_c++;
			if (_c >= nCol) {
				_c = 0;
				_dx = startPos.x;
				_r++;
				_dy -= (paddingY + _max_y);
			}
		}
	}
	else {
		int _r = 0 ;
		int _c = 0 ;
		float _dx = startPos.x ;
		float _dy = startPos.y ;
		CCARRAY_FOREACH(_children, item)
		{
			
			item.anchorPoint = ccp(0.5f, 0.5f);
			item.position = ccp(_dx + _max_x/2,_dy + _max_y/2);
			_dx += (paddingX + _max_x);
			_c++;
			if (_c >= nCol) {
				_c = 0;
				_dx = startPos.x;
				_r++;
				_dy += (paddingY + _max_y);
			}
		}
	}
	
}

-(void)onEnter
{
	[super onEnter];
	[self _layout];
}

-(void)onExit
{
	[super onExit];
	self.delegate = nil;
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
}
-(void)_layout
{
	if (layout == LAYOUT_X) {
		[self _Hlayout];
	}else if (layout == LAYOUT_Y) {
		[self _Vlayout];
	}else if(layout == LAYOUT_G) {
		[self _Glayout];
	}
}
@end
