//
//  DPayPurchasedGoodsInfo.h
//  DPay
//
//  Created by Liu Jinyong on 13-4-23.
//  Copyright (c) 2013年 Bodong NetDragon. All rights reserved.
//

#import "DPayGoodsDetailInfo.h"

@interface DPayPurchasedGoodsInfo : DPayGoodsDetailInfo {
    int _number;                          //商品数量
    BOOL _isAvailable;                    //商品当前是否可用
}

@property (nonatomic, assign) int number;
@property (nonatomic, assign) BOOL isAvailable;

@end
