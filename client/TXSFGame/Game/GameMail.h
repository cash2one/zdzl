//
//  GameMail.h
//  TXSFGame
//
//  Created by TigerLeung on 13-1-6.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

@class MailList;
@interface GameMail : NSObject{
	NSMutableArray * mails;
	MailList * targetList;
	NSMutableArray * removes;
	NSDictionary * inRemove;
}
@property(nonatomic,readonly,assign) NSMutableArray * mails;
@property(nonatomic,assign) MailList * targetList;

+(GameMail*)shared;
+(void)stopAll;

-(void)start;
-(int)count;
-(int)getCountByType:(Mail_type)type;

-(NSDictionary*)checkRewardTypeByFight;
-(NSDictionary*)checkRewardTypeByReward;

-(NSDictionary*)getMailByIndex:(int)index;
-(NSDictionary*)getMailByIndex:(int)index type:(Mail_type)type;
-(NSDictionary*)getMailById:(int)mid;
-(NSArray*)getMailsByType:(Mail_type)type;

-(void)removeMailById:(int)mid;
-(void)removeAllMailByType:(Mail_type)type;

@end
