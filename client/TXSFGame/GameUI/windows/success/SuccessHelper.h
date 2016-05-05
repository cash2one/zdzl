//
//  SuccessHelper.h
//  TXSFGame
//
//  Created by Soul on 13-4-12.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"

@interface SuccessHelper : NSObject{
	NSMutableDictionary* successDict;
	BOOL _isReady;
}
@property(nonatomic,assign)BOOL isReady;


+(SuccessHelper*)shared;
+(void)start;
+(void)stopAll;


-(void)endGetSuccrss:(NSDictionary*)_sender;

-(NSArray*)getSuccessesInfo:(SuccessType)_type;
-(NSArray*)getSuccessesLog;

@end
