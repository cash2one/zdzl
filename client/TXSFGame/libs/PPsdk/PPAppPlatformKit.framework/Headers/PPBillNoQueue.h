//
//  PPBillNoQueue.h
//  PPAppPlatformKit
//
//  Created by seven  mr on 2/5/13.
//  Copyright (c) 2013 张熙文. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPBillNoQueue : NSObject
{

}


/// <summary>
/// 收到补发订单处理完毕后从队列中移除补发的的订单
/// </summary>
/// <param name="BillNo">订单号</param>
/// <returns>无返回</returns>
-(void)deleteBillNo:(NSString *)paramBillNo;

@end
