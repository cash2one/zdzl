//
//  UnionPractice.h
//  TXSFGame
//
//  Created by Max on 13-4-28.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCPanel.h"

@interface UnionPractice : CCLayer {
    CCSprite *bg;
	NSMutableDictionary *bidsData;
	int midArg;
}

+(void)statr;


@end



@interface UnionPracticeCreatJoin :CCLayer
{
	CCSprite *bg;
	CCPanel *panel;
	int currenTbid;
	int currenTid;

}

+(void)joinTeam:(int)tid tbid:(int)tbid;
+(void)statr;

@end
