//
//  AdServiceHelper.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdServiceHelper : NSObject

+(AdServiceHelper*)shared;
+(void)stopAll;

-(void)sendTracking;

@end
