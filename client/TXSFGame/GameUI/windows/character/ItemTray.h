//
//  ItemTray.h
//  TXSFGame
//
//  Created by Soul on 13-3-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

#define ITEMTRAY_SIZE	CGSizeMake(cFixedScale(92), cFixedScale(92))

typedef enum{
	ItemTray_normal,
	ItemTray_market,
}ItemTray_model;


//@interface ItemTray : CCSprite<CCTouchOneByOneDelegate> {
@interface ItemTray : CCSprite{
	int					_number ;
	ItemTray_type		_type;
	ItemTray_model		_model;
	int					_status;
	CGPoint				touchSwipe_;
	BOOL				_isSelect;
	
	
	id  _target;
	SEL _infoCall;
	
}


@property(nonatomic,assign)id  target;
@property(nonatomic,assign)SEL infoCall;


@property(nonatomic,assign)BOOL isSelect;
@property(nonatomic,assign)ItemTray_model model;
@property(nonatomic,assign)int number;
@property(nonatomic,assign)ItemTray_type type;
@property(nonatomic,assign)DataHelper_type dataType;


-(BOOL)isNone;

-(void)removeItem;

-(void)doStartMove;
-(void)doEndMove;

-(void)addItem:(NSDictionary*)_id	type:(ItemTray_type)_t dataType:(DataHelper_type)_dataType;
-(void)addItem:(NSDictionary*)_id	type:(ItemTray_type)_t;

-(BOOL)checkEvent:(UITouch*)touch;


-(BOOL)touchBegan:(UITouch *)touch;

-(void)touchMoved:(UITouch *)touch;

-(void)touchEnded:(UITouch *)touch;


-(void)doRequestShowInfo;


@end
