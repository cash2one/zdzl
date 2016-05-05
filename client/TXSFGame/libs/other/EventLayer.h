//
//  EventLayer.h
//  TXSFGame
//
//  Created by Soul on 13-5-23.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface EventLayer : CCLayer {
    CCMenu* memu;
	float clipHeight;
}
@property(nonatomic,assign)float clipHeight;

+(EventLayer*)create:(CGSize)size clip:(int)_clip;

-(void)addMemuItem:(NSDictionary*)content;

@end
