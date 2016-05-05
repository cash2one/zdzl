//
//  DPayPurchasedGoodsDetailInfo.h
//  DPay
//
//  Created by Liu Jinyong on 13-4-23.
//  Copyright (c) 2013年 Bodong NetDragon. All rights reserved.
//

#import "DPayStructDefine.h"

@interface DPayPurchasedGoodsDetailInfo : NSObject {
    int _identity;                           //商品ID
    DPAY_TYPE_OF_CONSUME _type;              //消耗类型
    int _buyNum;                             //购买次数
    int _usedNum;                            //使用次数
    int _remainingNum;                       //剩余次数
    int _startTime;                          //开始时间
    int _expirationTime;                     //过期时间
    BOOL _isAvailable;                       //商品当前是否可用
}

@property (nonatomic, assign) int identity;
@property (nonatomic, assign) DPAY_TYPE_OF_CONSUME type;
@property (nonatomic, assign) int buyNum;
@property (nonatomic, assign) int usedNum;
@property (nonatomic, assign) int remainingNum;
@property (nonatomic, assign) int startTime;
@property (nonatomic, assign) int expirationTime;
@property (nonatomic, assign) BOOL isAvailable;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
