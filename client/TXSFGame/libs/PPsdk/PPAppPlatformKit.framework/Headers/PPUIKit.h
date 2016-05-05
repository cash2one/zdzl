//
//  PPUserUIKit.h
//  PPUserUIKit
//
//  Created by seven  mr on 1/14/13.
//  Copyright (c) 2013 张熙文. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface PPUIKit : NSObject
{
    
}


/// <summary>
/// 初始化SDK界面。必须写在window初始化完成之后
/// </summary>
/// <returns>返回PPUIKit单例</returns>
+ (PPUIKit *)sharedInstance;

/// <summary>
/// 设置SDK是否允许竖立设备Home键在下方向
/// </summary>
/// <param name="DeviceOrientationPortrait">是否允许</param>
/// <returns>无返回</returns>
+(void)setIsDeviceOrientationPortrait:(BOOL)paramDeviceOrientationPortrait;


/// <summary>
/// 设置SDK是否允许竖立设备Home键在上方向
/// </summary>
/// <param name="DeviceOrientationPortraitUpsideDown">是否允许</param>
/// <returns>无返回</returns>
+(void)setIsDeviceOrientationPortraitUpsideDown:(BOOL)paramDeviceOrientationPortraitUpsideDown;



/// <summary>
/// 设置SDK是否允许横放设备Home键在左方向
/// </summary>
/// <param name="DeviceOrientationLandscapeLeft">是否允许</param>
/// <returns>无返回</returns>
+(void)setIsDeviceOrientationLandscapeLeft:(BOOL)paramDeviceOrientationLandscapeLeft;



/// <summary>
/// 设置SDK是否允许横放设备Home键在右方向
/// </summary>
/// <param name="DeviceOrientationLandscapeRight">是否允许</param>
/// <returns>无返回</returns>
+(void)setIsDeviceOrientationLandscapeRight:(BOOL)paramDeviceOrientationLandscapeRight;



@end
