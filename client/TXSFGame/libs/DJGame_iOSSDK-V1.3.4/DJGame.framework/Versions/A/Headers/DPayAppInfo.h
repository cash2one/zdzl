//
//  DPayApplicationInfo.h
//  DPay
//
//  Created by lory qing on 11/28/12.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

#import "DPayStructDefine.h"

@interface DPayAppInfo : NSObject {
    int _identity;
    NSString *_name;
    NSString *_version;
    NSString *_smallIconUrl;
    NSString *_bigIconUrl;
    NSString *_copyright;
    DPAY_CURRENCY_TYPE _currencyType;
    NSString *_currencyName;
    NSString *_currencyUnit;
    float _exchangeRate;
}

@property (nonatomic, assign) int identity;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *smallIconUrl;
@property (nonatomic, copy) NSString *bigIconUrl;
@property (nonatomic, copy) NSString *copyright;
@property (nonatomic, assign) DPAY_CURRENCY_TYPE currencyType;
@property (nonatomic, copy) NSString *currencyName;
@property (nonatomic, copy) NSString *currencyUnit;
@property (nonatomic, assign) float exchangeRate;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
