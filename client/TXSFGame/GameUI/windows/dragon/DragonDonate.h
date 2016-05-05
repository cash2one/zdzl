//
//  DragonDonate.h
//  TXSFGame
//
//  Created by peak on 13-9-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "WindowComponent.h"

@interface DragonDonate : WindowComponent {
    int iconId;
    int crystalCount;
    int donateValue;
}
-(void)setCrystalCount:(int)count;
-(void)setDonateValue:(int)value;
@end
