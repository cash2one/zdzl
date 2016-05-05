//
//  PPExchange.h
//  PPAppPlatformKit
//
//  Created by 张熙文 on 1/11/13.
//  Copyright (c) 2013 张熙文. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface PPExchange : NSObject
{
}




/// <summary>
/// 直接用PP币兑换获得道具
/// </summary>
/// <param name="BillNo">订单号</param>
/// <param name="Amount">该道具所需要得金额</param>
/// <param name="RoleId">发放道具的角色ID【若无请写0】</param>
/// <param name="ZoneId">发放道具的服务器ID【若无请写0】</param>
/// <returns>是否添加写入成功</returns>
-(void)ppExchangeToGameRequestWithBillNo:(NSString *)paramBillNo Amount:(NSString *)paramAmount
                                  RoleId:(NSString *)paramRoldId ZoneId:(int)paramZoneId;



/// <summary>
/// 同步查询当前账户信息的PP币余额
/// </summary>
/// <returns>失败返回-1，成功返回PP币余额</returns>
-(double)ppSYPPMoneyRequest;




@end
