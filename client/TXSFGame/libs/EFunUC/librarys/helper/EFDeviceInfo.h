//
//  EFDeviceInfo.h
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFDeviceInfo : NSObject

+(NSString*)model;
+(NSString*)version;
+(NSString*)macaddress;

//+(NSString*)libraryPath;
+(NSString*)dataPath;

+(NSDictionary*)getCacheData;
+(void)saveCacheData:(NSDictionary*)data;

@end
