//
//  ItemDescribetion.h
//  TXSFGame
//
//  Created by Soul on 13-3-11.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "GameDefine.h"

@class MessageBox;

@interface RoleDescribetion : CCLayerColor{
	BOOL		_isEnter;
	BOOL		_isExit;
}

@property(nonatomic,assign)BOOL isEnter;
@property(nonatomic,assign)BOOL isExit;

+(RoleDescribetion*)showDescribetion;
-(void)showAttribute:(NSDictionary*)_attribute;

-(void)doExit;
-(void)doEnter;

@end


@interface ItemDescribetion : CCLayerColor {
	int					_did;
	ItemTray_type		_type;
	DataHelper_type		_dataType;
}

@property(nonatomic,assign)int			 did;
@property(nonatomic,assign)ItemTray_type type;
@property(nonatomic,assign)DataHelper_type dataType;

+(ItemDescribetion*)showDescribetion:(int)_iid type:(ItemTray_type)_typ;
+(ItemDescribetion*)showDescribetion:(int)_iid type:(ItemTray_type)_typ dataType:(DataHelper_type)_dtype;

@end
