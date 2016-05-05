//
//  DPayUserAccountInfo.h
//  DPay
//
//  Created by Liu Jinyong on 13-4-11.
//  Copyright (c) 2013年 Bodong NetDragon. All rights reserved.
//

@interface DPayUserAccountInfo : NSObject {
    long long _userId;      //用户ID
    float _consume;         //消费总额
    float _recharge;        //充值总额
    float _balance;         //当前余额
    
	float _officeConsume;   //消费官币
	float _officeRecharge;  //充值官币
	float _officeBalance;   //当前官币
}

@property (nonatomic, assign) long long userId;
@property (nonatomic, assign) float consume;
@property (nonatomic, assign) float recharge;
@property (nonatomic, assign) float balance;
@property (nonatomic, assign) float officeConsume;
@property (nonatomic, assign) float officeBalance;
@property (nonatomic, assign) float officeRecharge;

+ (DPayUserAccountInfo *) sharedInstance;

- (DPayUserAccountInfo *)refreshWithDictionary:(NSDictionary *)dictionary;

@end
