//
//  EfunAD.h
//  Efunad
//
//  Created by zhangguangyang on 1/24/13.
//  Copyright (c) 2013 zhangguangyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMAdTracker.h"
#import "IMCommonUtil.h"
#import "PlayHavenSDK.h"
#import "DMConversionTracker.h"
@interface EfunAD : NSObject
<NSURLConnectionDataDelegate>
{
    NSMutableData * ResourtData;
}
+(void)setEfunAD;
@end
