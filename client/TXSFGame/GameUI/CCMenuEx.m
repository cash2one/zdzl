//
//  MyCocos2DClass.m
//  TXSFGame
//
//  Created by chao chen on 12-11-14.
//  Copyright 2012 eGame. All rights reserved.
//

#import "CCMenuEx.h"
@implementation CCMenuEx

-(CCMenuItem *) itemForTouch: (UITouch *) touch
{
    CGPoint touchLocation = [touch locationInView: [touch view]];
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	touchLocation = [self convertToNodeSpace:touchLocation];
	
    CCMenuItem* item = nil;
    CCMenuItem* hitItem = nil;
    CCARRAY_FOREACH(_children, item){
        if ( [item visible] && [item isEnabled] ) {
			//if (CGRectContainsPoint([item rect], touchLocation)) {
			if (CGRectContainsPoint([item activeArea], touchLocation)) {
                if (hitItem) {
                    if ([hitItem zOrder] < item.zOrder) {
                        hitItem = item;
                    }
                } else {
                    hitItem = item;
                }
            }
        }
    }
    return hitItem;
}



@end