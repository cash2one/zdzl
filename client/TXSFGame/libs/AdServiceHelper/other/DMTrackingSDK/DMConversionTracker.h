//
//  Copyright (c) 2012. Domob Ltd. All rights reserved.
//

@interface DMConversionTracker : NSObject
// 跟踪App“激活”行为
+ (void)startAsynchronousConversionTrackingWithDomobAppId:(NSString *)appId;
// 跟踪用户“注册”行为
+ (void)startAsynchronousRegisterTrackingWithDomobAppId:(NSString *)appId;
@end
