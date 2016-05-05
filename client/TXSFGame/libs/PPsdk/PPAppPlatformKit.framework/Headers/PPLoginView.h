//
//  PPLoginView.h
//  PPUserUIKit
//
//  Created by seven  mr on 1/21/13.
//  Copyright (c) 2013 张熙文. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface PPLoginView : UIView
{
    
}

/// <summary>
/// 获取登陆界面
/// </summary>
/// <returns>返回PPLoginView单例</returns>
+ (PPLoginView *)sharedInstance;

/// <summary>
/// 登陆从右边展示
/// </summary>
/// <returns>无返回</returns>
-(void)showLoginViewByRight;






@end
