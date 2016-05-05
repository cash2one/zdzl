//
//  ItemTrayContainer.m
//  TXSFGame
//
//  Created by Soul on 13-3-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ItemTrayContainer.h"
#import "ItemTray.h"

@implementation ItemTrayContainer

@synthesize row = _row;
@synthesize column = _column;
@synthesize startIndex = _startIndex;
@synthesize isActivate = _isActivate;
@synthesize isFull = _isFull;

+(ItemTrayContainer*)initWithIndex:(int)_r1 column:(int)_c1 index:(int)_index{
	return [[[ItemTrayContainer alloc] initWithRowColumn:_r1
												  column:_c1
													cell:ITEMTRAY_SIZE
												   index:_index] autorelease];
}

+(ItemTrayContainer*)initWith:(int)_r1 column:(int)_c1{
	return [ItemTrayContainer initWith:_r1 column:_c1 cell:ITEMTRAY_SIZE];
}

+(ItemTrayContainer*)initWith:(int)_r1 column:(int)_c1 cell:(CGSize)_size{
	return [[[ItemTrayContainer alloc] initWithRowColumn:_r1
												  column:_c1
													cell:_size index:0] autorelease];
}

-(id)initWithRowColumn:(int)_r1 column:(int)_c1 cell:(CGSize)_s1 index:(int)_index{
	if ((self=[super init])) {
		
		_row = _r1 ;
		_column = _c1;
		_startIndex = _index;
		
		float _w = _s1.width*_column;
		float _h = _s1.height*_row;
		
		self.contentSize = CGSizeMake(_w, _h);
		
		[self fillItemTray];

	}
	return self;
}

-(void)fillItemTray{
	
	int _w = self.contentSize.width/_column;
	int _h = self.contentSize.height/_row;
	
	float startX = _w/2;
	float startY = self.contentSize.height - _h/2;
	
	
	for (int i = 0; i < _row; i++) {
		for (int j = 0; j < _column; j++) {
		
			ItemTray* _tray = [ItemTray node];
			
			[self addChild:_tray z:1 tag:_startIndex + i*_column + j];
			
			_tray.position = ccp(startX + j*_w, startY - i*_h);
			
		}
	}
	
}

-(void)freeAllSelect{
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[ItemTray class]]) {
				ItemTray* _tray = (ItemTray*)____node;
				if (![_tray isNone]) {
					if (_tray.model == ItemTray_market) {
						_tray.isSelect = NO;
					}
				}
			}
		}
	}
}

-(ItemTray*)removeItemTrayWith:(int)_iid type:(int)_tType{
	
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[ItemTray class]]) {
				ItemTray* _tray = (ItemTray*)____node;
				if (_tray.number == _iid && _tray.type == _tType) {
					[_tray removeItem];
					self.isFull = NO ;
					return _tray;
				}
			}
		}
	}
	
	return nil;
}

-(ItemTray*)getEventTray:(UITouch*)touch{
	
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[ItemTray class]]) {
				ItemTray* _tray = (ItemTray*)____node;
				if ([_tray checkEvent:touch]) {
					return _tray;
				}
			}
		}
	}
	
	return nil;
}

-(void)openMarketModel:(BOOL)_isOpen{
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[ItemTray class]]) {
				ItemTray* _tray = (ItemTray*)____node;
				if (![_tray isNone]) {
					if (_isOpen) {
						_tray.model = ItemTray_market;
					}else{
						_tray.model = ItemTray_normal;
					}
				}
			}
		}
	}
}

-(ItemTray*)getFreeTray{
	
	if (_isFull) {
		return nil;
	}
	
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[ItemTray class]]) {
				ItemTray* _tray = (ItemTray*)____node;
				if ([_tray isNone]) {
					return _tray;
				}
			}
		}
	}
	
	_isFull = YES ;
	
	return nil;
}

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	[super onExit];
}

-(void)dealloc{
	CCLOG(@"ItemTrayContainer->dealloc");
	[super dealloc];
}

@end
