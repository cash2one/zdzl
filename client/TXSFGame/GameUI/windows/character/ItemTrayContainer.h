//
//  ItemTrayContainer.h
//  TXSFGame
//
//  Created by Soul on 13-3-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class ItemTray;

@interface ItemTrayContainer : CCLayer {
	int				_row;
	int				_column;
	
	BOOL			_isActivate;
	BOOL			_isFull;
	
	int				_startIndex;
	
}
@property(nonatomic,assign)int	row;
@property(nonatomic,assign)int	column;
@property(nonatomic,assign)int	startIndex;
@property(nonatomic,assign)BOOL isActivate;
@property(nonatomic,assign)BOOL isFull;

+(ItemTrayContainer*)initWithIndex:(int)_r1 column:(int)_c1 index:(int)_index;
+(ItemTrayContainer*)initWith:(int)_r1 column:(int)_c1;
+(ItemTrayContainer*)initWith:(int)_r1 column:(int)_c1 cell:(CGSize)_size;



-(void)openMarketModel:(BOOL)_isOpen;

-(ItemTray*)getFreeTray;
-(ItemTray*)getEventTray:(UITouch*)touch;

-(ItemTray*)removeItemTrayWith:(int)_iid type:(int)_tType;
-(void)freeAllSelect;

@end
