//
//  DPayStructDefine.h
//  DPay
//
//  Created by lory qing on 11/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef DPay_DPayStructDefine_h
#define DPay_DPayStructDefine_h

//商品消费类型
typedef enum _DPAY_TYPE_OF_CONSUME {    
	DPAY_ALL_TYPE = 0,                       //全部
	DPAY_CONSUME = 1,                        //消费型
	DPAY_NON_CONSUME = 2,                    //非消费型
	DPAY_SUBSCRIPTION = 3,                   //订阅型
    DPAY_CONSUME_OR_NON_CONSUME = 4,         //消费型 和 非消费型
    DPAY_CONSUME_OR_SUBSCRIPTION = 5,        //消费型 和 订阅型
    DPAY_NON_CONSUME_OR_SUBSCRIPTION = 6     //非消费型 和 订阅型
}DPAY_TYPE_OF_CONSUME;

//货币类型
typedef enum _DPAY_CURRENCY_TYPE {    
	DPAY_OFFICIAL_CURRENCY = 0,              //官币
	DPAY_TOKEN = 1,                          //代币
	DPAY_VIRTUAL_CURRENCY = 2                //虚拟货币
}DPAY_CURRENCY_TYPE;

//充值状态
typedef enum _DPAY_RECHARGE_STATUS {    
	DPAY_RECHARGE_WAITTING = 0,              //未到账
	DPAY_RECHARGE_SUCCESS = 1,               //到账
    DPAY_RECHARGE_FAILED = 2                 //充值失败  
}DPAY_RECHARGE_STATUS;


#endif
