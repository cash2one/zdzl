//
//  DPayPurchasingItem.h
//  DPay
//
//  Created by Liu Jinyong on 13-4-10.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

@interface DPayPurchasingItem : NSObject {
    int _goodsId;
    int _goodsPurcharsedNum;
}

@property (nonatomic, assign) int goodsId;
@property (nonatomic, assign) int goodsPurcharsedNum;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
