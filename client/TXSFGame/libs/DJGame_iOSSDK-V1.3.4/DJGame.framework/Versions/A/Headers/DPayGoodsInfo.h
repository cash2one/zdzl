//
//  DPayGoodsInfo.h
//  DPay
//
//  Created by Lin fei hong on 11/28/12.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

#import "DPayStructDefine.h"

@interface DPayGoodsInfo : NSObject {
    int _identity;                        //商品ID
    NSString *_name;                      //商品名称
    float _originalPrice;                 //单价
    float _specialPrice;                  //特价、促销价（-1为无特价）
    NSString *_imageUrl;                  //商品图片URl
}

@property (nonatomic, assign) int identity;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) float originalPrice;
@property (nonatomic, assign) float specialPrice;
@property (nonatomic, copy) NSString *imageUrl;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
