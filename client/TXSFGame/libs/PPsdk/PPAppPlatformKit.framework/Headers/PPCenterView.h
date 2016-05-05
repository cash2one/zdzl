//
//  PPCenterView.h
//  PPUserUIKit
//
//  Created by seven  mr on 1/23/13.
//  Copyright (c) 2013 张熙文. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PPCenterView : UIView
{
}
/// <summary>
/// 获取用户中心
/// </summary>
/// <returns>返回PPCenterView单例</returns>
+ (PPCenterView *)sharedInstance;


/// <summary>
/// 用户中心从右边展示
/// </summary>
/// <returns>无返回</returns>
-(void)showCenterViewByRight;






@end
