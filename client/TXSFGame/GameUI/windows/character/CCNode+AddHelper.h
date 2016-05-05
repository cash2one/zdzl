//
//  CCNode+AddHelper.h
//  TXSFGame
//
//  Created by Soul on 13-3-4.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"

@interface CCNode (AddHelper)

-(void)Category_AddChildToCenter:(CCNode*)_node;
-(void)Category_AddChildToCenter:(CCNode*)_node z:(int)_z;
-(void)Category_AddChildToCenter:(CCNode*)_node z:(int)_z tag:(int)_tag;

@end
