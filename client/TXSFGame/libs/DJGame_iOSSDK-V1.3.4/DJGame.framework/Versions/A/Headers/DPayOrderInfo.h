//
//  DPayOrderInfo.h
//  DPay
//
//  Created by lory qing on 11/29/12.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

typedef enum {
    DPayOrderStateFail = 0,
    DPayOrderStateSuccess = 1
}DPayOrderState;

@interface DPayOrderInfo : NSObject {
    NSString *_identity;                     //订单ID
    long long _userId;                       //用户ID
    float _total;                            //订单总额
    int _orderTime;                          //下单时间戳
    NSMutableArray *_purchasedGoodItems;     //用户购买的商品(DPayPurchasingItem)列表
	NSString *_extra;						 //开发者自定义购买信息
    DPayOrderState _state;
}

@property (nonatomic, copy) NSString *identity;
@property (nonatomic, assign) long long userId;
@property (nonatomic, assign) float total;
@property (nonatomic, assign) int orderTime;
@property (nonatomic, retain) NSMutableArray *purchasedGoodItems;
@property (nonatomic, retain) NSString *extra;
@property (nonatomic, assign) DPayOrderState state;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
