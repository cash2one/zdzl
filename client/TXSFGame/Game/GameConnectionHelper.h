//
//  GameConnectionHelper.h
//  TXSFGame
//
//  Created by Soul on 13-4-19.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameConnectionHelper : NSObject{
	
}

+(GameConnectionHelper*)shared;
+(void)stopAll;
-(void)start;

@end
