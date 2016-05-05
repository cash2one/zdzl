//
//  BossBuff.h
//  TXSFGame
//
//  Created by Soul on 13-5-13.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface BossBuff : CCSprite {
	id		target;
	SEL		call;
}
@property(nonatomic,assign)id  target;
@property(nonatomic,assign)SEL call;

@end
