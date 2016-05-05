//
//  GameFileUtils.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-18.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface CCFileUtils(GameFileUtils){
	
}

+(BOOL)hasFilePathByTarget:(NSString*)target;

-(void)addSearchPathDirectory:(NSSearchPathDirectory)path target:(NSString*)target;
-(void)addSearchPathDirectory:(NSSearchPathDirectory)path;
-(void)addSearchPath:(NSString*)path;

-(BOOL)checkHasTarget:(NSString*)path;
-(void)checkDirectory:(NSString*)path;

@end
