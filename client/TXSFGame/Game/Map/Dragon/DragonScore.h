//
//  DragonScore.h
//  TXSFGame
//
//  Created by peak on 13-9-25.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface DragonScore : CCNode {
    NSString *scoreLevelStr;
    NSTimeInterval scoreTime;
    NSTimeInterval scoreMaxTime;
}
@property(assign,nonatomic) NSString* scoreLevelStr;
+(void)showScoreWithSender:(id)sender;
@end
