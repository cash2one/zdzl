//
//  WorldBossTips.h
//  TXSFGame
//
//  Created by Max on 13-4-16.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


@interface WorldBossTips : CCLayer {
    bool isStart;
}


@property (nonatomic,assign)bool isStart;
@property (nonatomic,retain)CCLabelTTF *labelTime;


+(void)hide;
+(void)show:(bool)b;
+(void)resetThisTimeClose;
+(void)updateStatus;

@end
