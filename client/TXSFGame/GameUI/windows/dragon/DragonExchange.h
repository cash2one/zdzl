//
//  DragonExchange.h
//  TXSFGame
//
//  Created by peak on 13-9-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "WindowComponent.h"

@interface DragonExchange : WindowComponent {
    int iconId;
    int donateValue;
}
-(void)setDonateValue:(int)value;
@end
