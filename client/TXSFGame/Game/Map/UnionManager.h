//
//  UnionManager.h
//  TXSFGame
//
//  Created by TigerLeung on 13-1-29.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "InfoAlert.h"
#import "CCSimpleButton.h"

typedef enum{
	UNION_ACTION_TYPE_none			= 0,
	UNION_ACTION_TYPE_Cat			= 1,// 招财猫
    UNION_ACTION_TYPE_Challenge		= 2,// 组队挑战
    UNION_ACTION_TYPE_Donate		= 3,// 捐献斗舰
    UNION_ACTION_TYPE_Engrave		= 4,// 宝具铭刻
    UNION_ACTION_TYPE_MainChallenge	= 5,// 同盟首领战
    UNION_ACTION_TYPE_DragonDonate	= 6,// 同盟狩龙战捐晶
    UNION_ACTION_TYPE_DragonExchange	= 7,// 同盟狩龙战兑换
    //UNION_ACTION_TYPE_DragonRank	= 8,// 同盟狩龙战排行
}UNION_ACTION_TYPE;

@class UnionAction;

@interface UnionManager : CCLayer{
	
	UnionAction * currentAction;
    CCSimpleButton *close;
    RuleButton *ruleButton;
}

+(UnionManager*)shared;
+(void)stopAll;

+(void)enterUnion;
+(void)quitUnion;
+(void)checkStatus;
+(BOOL)checkIsUnionMember;

+(void)doUnionAction:(UNION_ACTION_TYPE)type;
+(void)endCurrentAction;
+(void)showButton;
+(void)hideButton;
@end

@interface UnionAction : NSObject{
	BOOL isRuning;
}
@property(nonatomic,assign) BOOL isRuning;
-(void)start;
-(void)action;
-(void)stop;
@end

@interface UnionActionCat : UnionAction
@end
@interface UnionActionEngrave : UnionAction
@end
//chao
@interface UnionActionDragonDonate : UnionAction
@end
//chao
@interface UnionActionDragonExchange : UnionAction
@end
