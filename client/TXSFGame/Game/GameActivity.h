//
//  GameActivity.h
//  TXSFGame
//
//  Created by TigerLeung on 13-4-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"

@interface GameActivity : NSObject{
	
}

+(GameActivity*)shared;
+(void)stopAll;

-(void)checkStartActivity;
-(NSArray*)getActivityByType:(Activity_Type)type;
-(NSDictionary*)getActivity:(Activity_Type)type activityId:(int)_id;

@end
