//
//  GameFilter.h
//  TXSFGame
//
//  Created by Max on 13-2-20.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameDB.h"

@interface GameFilter : NSObject {
    NSMutableDictionary *filterKeyWord;
}

@property (nonatomic,retain) NSMutableDictionary *filterKeyWord;


+(GameFilter*)share;
+(void)stopAll;

-(void)loadKeyword;
-(void)freeKeyword;

-(NSString*)chatFilter:(NSString*)str;
+(BOOL)validContract:(NSString*)str;

-(bool)nameFilter:(NSString*)str;

@end
