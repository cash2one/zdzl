//
//  UnionPracticeConfigTeam.h
//  TXSFGame
//
//  Created by Max on 13-5-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "ConfigTeamBase.h"




@interface UnionPracticeConfigTeam : ConfigTeamBase {
    CCSprite *bg;
	CCSprite *rewardbg;
	NSDictionary* stationInfo;
	bool isRunFirstConfig;
	CCLabelTTF *popleCountLabel;
	CCSimpleButton *invitebtn;
	CCSimpleButton *close_btn;
	bool isStartFight;
	bool isWaitting;
}
@property(nonatomic,assign)bool teamLeader;
@property(nonatomic,assign)int teamId;
@property(nonatomic,assign)int tbid;

+(bool)isOpen;
+(void)startLeaderWithMosterId:(int)tbid teamId:(int)tid;
+(void)startWithMosterId:(int)tbid teamId:(int)tid ;

@end

