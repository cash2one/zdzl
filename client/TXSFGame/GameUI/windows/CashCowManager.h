//
//  CashCowManager.h
//  TXSFGame
//
//  Created by Soul on 13-5-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WindowComponent.h"
#import "Widget.h"
/*
typedef enum{
	RedeemType_none = 0 ,
	RedeemType_cy = 1 ,//财运亨通
	RedeemType_zc = 2 ,//招财进宝
	RedeemType_ct = 3 ,//财通天下
}RedeemType;
*/

@interface CashCard :Widget{
	int redeemType;
	BOOL isTouch;
    //
    int coin1;//银币
    int coin2;//元宝
}
@property(nonatomic,assign)int redeemType;
@property(nonatomic,assign)BOOL isTouch;

@end

@interface CashCowManager : WindowComponent {
	NSMutableArray* cards ;
    int redeemTimes;
    int redeemCoin1;
    int redeemCoin2;
    //
    BOOL isSender;
}

+(BOOL)checkOpenSystem;

@end
