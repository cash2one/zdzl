//
//  BrowLayer.h
//  TXSFGame
//
//  Created by Soul on 13-5-23.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface BrowLayer : CCLayer {
    float clipHeight;
	NSArray* brows;
}
@property(nonatomic,retain)NSArray* brows;
@property(nonatomic,assign)float clipHeight;

+(BrowLayer*)create:(CGSize)size array:(NSArray*)array clip:(int)_clip;

@end
