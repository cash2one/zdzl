//
//  GameMoneyMini.h
//  TXSFGame
//
//  Created by chao chen on 13-3-6.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameMoneyMini : CCSprite {
    
}
-(void)setCoin:(int)type count:(int)c;
-(int)getCoin:(int)type;
-(void)updateMoneyWithCoin1:(NSInteger)coin1 coin2:(NSInteger)coin2 coin3:(NSInteger)coin3;
@end
