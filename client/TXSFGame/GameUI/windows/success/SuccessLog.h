//
//  SuccessLog.h
//  TXSFGame
//
//  Created by Soul on 13-4-19.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface SuccessLog : CCLayer {
    
}

+(void)addSuccessLog:(NSArray*)_array;
+(void)freeSuccessLog;

@end
