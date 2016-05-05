//
//  DPayRechargeOrderInfo.h
//  DPay
//
//  Created by Liu Jinyong on 13-4-11.
//  Copyright (c) 2013年 Bodong NetDragon. All rights reserved.
//

@interface DPayRechargeOrderInfo : NSObject {
    float       _rechargeMoney; //充值金额
    int         _rechargeGold;  //充值游戏币
    NSString    *_rechargeId;   //充值交易号
    NSString    *_uRechargeId;  //开发者自定义的交易号
    NSString    *_extra;        //开发者自定义字段
}

@property (nonatomic, assign) float rechargeMoney;
@property (nonatomic, assign) int   rechargeGold;
@property (nonatomic, copy) NSString *rechargeId;
@property (nonatomic, copy) NSString *uRechargeId;
@property (nonatomic, copy) NSString *extra;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
