//
//  ConfigTeamBase.h
//  TXSFGame
//
//  Created by Max on 13-5-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCSimpleButton.h"
#import "RoleViewerContent.h"
#define ROLEARBASE 100
#define CHARACTERARBASE 200
#define ROLEVIEWBASE 300
#define cc {{2,5,8},{1,4,7},{0,3,6}};

@interface ConfigTeamBase : CCLayer {
	NSMutableDictionary *roleAr;
	NSMutableDictionary *roleArMe;
	CCLabelTTF *onRLabel;
	RoleViewerContent *currenDropObj;
	int roleArId;
	SEL upRoleDataFun;
	bool isTouched;
	
	CCNode * roleList;
}

@property (nonatomic,assign)int mid;
@property (nonatomic,assign)int rewardid;
@property(nonatomic,assign)int fightid;
@property(nonatomic,assign)int colId;
@property(nonatomic,assign)SEL upRoleDataFun;

-(void)setRoleAndMeValue:(id)value keyname:(NSString*)key;
-(void)creatArrangment:(int[3])n;
-(bool)checkOnCol:(int)raId;

@end
