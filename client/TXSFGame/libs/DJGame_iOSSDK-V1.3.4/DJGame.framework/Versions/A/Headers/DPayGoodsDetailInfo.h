//
//  DPayGoodsDetailInfo.h
//  DPay
//
//  Created by Liu Jinyong on 13-4-23.
//  Copyright (c) 2013年 Bodong NetDragon. All rights reserved.
//

#import "DPayGoodsInfo.h"

@interface DPayGoodsDetailInfo : DPayGoodsInfo {
    int _categoryIdentity;                //商品所属分类ID
    NSString *_categoryName;              //商品所属分类名称
    DPAY_TYPE_OF_CONSUME _type;           //商品所属消费类型
    BOOL _isLocalhost;                    //是否仅限本机使用
    NSString *_unit;                      //商品单位
    NSString *_description;               //商品描述
}

@property (nonatomic, assign) int categoryIdentity;
@property (nonatomic, copy) NSString *categoryName;
@property (nonatomic, assign) DPAY_TYPE_OF_CONSUME type;
@property (nonatomic, assign) BOOL isLocalhost;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, copy) NSString *description;

@end
