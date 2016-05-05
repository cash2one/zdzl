//
//  DPayGoodsCategory.h
//  DPay
//
//  Created by lory qing on 11/27/12.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

@interface DPayGoodsCategory : NSObject {
    int _identity;            //分类ID
    NSString *_name;          //分类名称
    NSString *_iconUrl;       //分类图片Url
    NSString *_description;   //分类描述
}

@property (nonatomic, assign) int identity;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *description;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
