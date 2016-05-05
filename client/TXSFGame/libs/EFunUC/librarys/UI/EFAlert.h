//
//  EFAlert.h
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFAlert : NSObject

+(void)alert:(NSString*)message;
+(void)alert:(NSString*)message delay:(float)delay;

@end
