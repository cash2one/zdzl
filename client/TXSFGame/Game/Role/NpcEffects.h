//
//  NpcEffects.h
//  TXSFGame
//
//  Created by huang shoujun on 13-1-13.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "AnimationViewer.h"

@class AnimationViewer;

@interface NpcEffects : AnimationViewer {
    
}
-(void)showEffect:(int)_eid target:(id)_target call:(SEL)_call;

@end
