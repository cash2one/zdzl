//
//  PHNetworkUtil.h
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 5/4/12.
//  Copyright (c) 2012 Playhaven. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PHNetworkUtil : NSObject
+(id)sharedInstance;
-(void)checkDNSResolutionForURLPath:(NSString *)urlPath;
@end
