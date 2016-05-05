//
//  DPayPurchasingCustomItem.h
//  DPay
//
//  Created by Liu Jinyong on 13-4-10.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

#import "DPayPurchasingItem.h"

@interface DPayPurchasingCustomItem : DPayPurchasingItem {
    NSString *_goodsName;
    NSString *_goodsUnit;
    float _goodsPrice;
    float _goodsSpecialPrice;
    NSString *_extra;
}

@property (nonatomic, copy) NSString *extra;
@property (nonatomic, copy) NSString *goodsName;
@property (nonatomic, copy) NSString *goodsUnit;
@property (nonatomic, assign) float goodsPrice;
@property (nonatomic, assign) float goodsSpecialPrice;

@end
