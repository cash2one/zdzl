//
//  Copyright (c) 2012. Domob Ltd. All rights reserved.
//

#import "DMConversionTracker.h"
#import "OpenUDID.h"
#import "ODIN.h"
#import "JSONKit.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
#import <AdSupport/AdSupport.h>
#endif

NSInteger const DMCTReportRetryTimes = 3;
NSInteger const DMCTReportRetryInterval = 1;

NSString * const DMCTProfileUpdateURL = @"http://e.domob.cn/track/profile";
NSString * const DMCTFileName = @"domob_ct_profile.plist";

NSString * const DMCTJsonKeyTurnoff = @"turnoff";
NSString * const DMCTJsonKeyURL = @"url";

NSString * const DMCTParamTurnoff = @"DMCTTurnoff";
NSString * const DMCTParamActivationTime = @"DMCTActivationTime";

#define DM_TRACKING_TYPE_ACTIVATION @"act"
#define DM_TRACKING_TYPE_REGISTER @"reg"

@interface DMConversionTracker()
+ (void)startTracking:(NSString *)appId;
+ (BOOL)needTrackingConversion:(NSMutableDictionary *)localProfileDict;
+ (NSMutableDictionary *)updateProfile:(NSString *)appId;
+ (NSString *)createTrackingURLWithAppId:(NSString *)appId activationDate:(NSString *)date reportUrl:(NSString *)url trackingType:(NSString *)type;
+ (BOOL)trackingConversionToURL:(NSString *)url;

+ (NSString *)localProfilePath;
+ (NSMutableDictionary *)localProfileDict;
+ (BOOL)updateLocalProfile:(NSMutableDictionary *)profileDict;

+ (NSString *)macAddress;
+ (NSString *)hardwarePlatform;
+ (NSString *)bundleIdentifier;
+ (NSString *)convertRequestToStringWithDictionary:(NSDictionary *)dicRequest;
+ (NSString *)urlEncodedString:(NSString *)string;
+ (NSString *)identifierForAdvertising;
+ (NSString *)isLimitAdTracking;
@end

@implementation DMConversionTracker

+ (void)startAsynchronousConversionTrackingWithDomobAppId:(NSString *)appId
{
    @autoreleasepool 
    {
        NSArray *argsArray = [NSArray arrayWithObjects:appId, DM_TRACKING_TYPE_ACTIVATION, nil];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        NSInvocationOperation *iop= [[NSInvocationOperation alloc] initWithTarget:self 
                                                                         selector:@selector(startTracking:)
                                                                           object:argsArray];
        [queue addOperation:iop];
        [iop release];
        [queue release];        
    }
}

+ (void)startAsynchronousRegisterTrackingWithDomobAppId:(NSString *)appId {
    @autoreleasepool
    {
        NSArray *argsArray = [NSArray arrayWithObjects:appId, DM_TRACKING_TYPE_ACTIVATION, nil];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        NSInvocationOperation *iop= [[NSInvocationOperation alloc] initWithTarget:self
                                                                         selector:@selector(startTracking:)
                                                                           object:argsArray];
        [queue addOperation:iop];
        [iop release];
        [queue release];
    }
}
// 由于方法通过selector放在NSInvocationOperation中执行，只能传递一个id类型的参数，因此采用argsArray，顺序存储多个参数来传递。
// 参数说明：[0]:appID, [1]:tracking type
+ (void)startTracking:(NSArray *)argsArray
{
    @try {
        [argsArray retain];
        NSString *appId;
        NSString *trackingType;
        if (argsArray.count > 1) {
            appId = [argsArray objectAtIndex:0];
            trackingType = [argsArray objectAtIndex:1];
        } else if (argsArray.count == 1) {
            appId = [argsArray objectAtIndex:0];
            trackingType = DM_TRACKING_TYPE_ACTIVATION;
        }
        
        // 获取本地配置，如果没有则进行初始化
        NSMutableDictionary *localProfileDict = [self localProfileDict];
        // 需要区分tracking类型，当是激活类型是，需要在已经激活过。其它类型则不检查。
        if (trackingType && [trackingType isEqualToString:DM_TRACKING_TYPE_ACTIVATION]) {
            // 检查是否已激活，若已激活则忽略tracking激活的请求
            if (![self needTrackingConversion:localProfileDict]) {
                return;
            }
        }
        
        // update profile
        NSMutableDictionary *jsonDict = [self updateProfile:appId];
        
        // check whether turnoff——总开关
        NSNumber *turnoffNum = (NSNumber *)[jsonDict objectForKey:DMCTJsonKeyTurnoff];
        BOOL turnoff = (turnoffNum && [turnoffNum boolValue]) ? YES : NO;
        if (turnoff)
        {
            return;
        }
        
        // Start tracking
        NSString *reportURL = (NSString *)[jsonDict objectForKey:DMCTJsonKeyURL];
        if (reportURL)
        {
            NSDate *activationDate = (NSDate *)[localProfileDict objectForKey:DMCTParamActivationTime];
            NSString *activationDateStr = [NSString stringWithFormat:@"%1.f", [activationDate timeIntervalSince1970] * 1000];
            
            NSString *trackingUrl = [self createTrackingURLWithAppId:appId
                                                      activationDate:activationDateStr
                                                           reportUrl:reportURL
                                                        trackingType:trackingType];
            if ([self trackingConversionToURL:trackingUrl])
            {
                // 只有当type为激活时，tracking成功后需要记录一下已激活，之后再想发激活tracking就直接忽略了
                if ([trackingType isEqualToString:DM_TRACKING_TYPE_ACTIVATION]) {
                    [localProfileDict setObject:[NSNumber numberWithBool:YES] forKey:DMCTParamTurnoff];
                    [self updateLocalProfile:localProfileDict];
                }
            }
        }
    } @catch (NSException *exception) {
    } @finally {
        [argsArray release];
    }
}

+ (BOOL)needTrackingConversion:(NSMutableDictionary *)localProfileDict
{
    NSNumber *turnoffNum = (NSNumber *)[localProfileDict objectForKey:DMCTParamTurnoff];
    return (nil != turnoffNum && [turnoffNum boolValue]) ? NO : YES;
}

+ (NSMutableDictionary *)updateProfile:(NSString *)appId
{
    NSString *reqUrl = [NSString stringWithFormat:@"%@?app_id=%@", DMCTProfileUpdateURL, appId];
    NSURLRequest *profileUpdateReq = [NSURLRequest requestWithURL:[NSURL URLWithString:reqUrl]];
    NSURLResponse *profileUpdateResp = nil;
    NSError *error = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:profileUpdateReq
                                                 returningResponse:&profileUpdateResp
                                                             error:&error];

    NSMutableDictionary *profileDict = nil;
    if((!error) && ([(NSHTTPURLResponse *)profileUpdateResp statusCode] == 200) && ([responseData length] > 0))
    {
        NSString *tmpStr = [[NSString alloc] initWithData:responseData
                                                 encoding:NSUTF8StringEncoding];
        profileDict = [tmpStr objectFromJSONString];
        [tmpStr release];
    }
    
    return profileDict;
}

+ (NSString *)createTrackingURLWithAppId:(NSString *)appId activationDate:(NSString *)date reportUrl:(NSString *)url trackingType:(NSString *)type
{
    NSString *ts = [NSString stringWithFormat:@"%.f", ([[NSDate date] timeIntervalSince1970] * 1000)];
    NSDictionary *paramDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"5",@"v",
                                @"ios",@"os",
                                [self hardwarePlatform],@"device",
                                appId,@"app_id",
                                [self macAddress], @"omac",
                                [self md5:[self macAddress]],@"ma",
                                [OpenUDID value],@"oid",
                                ODIN1(),@"odin1",
                                [self bundleIdentifier],@"pkg",
                                ts,@"ts",
                                date,@"date",
                                [self identifierForAdvertising],@"ifa",
                                [self isLimitAdTracking],@"lat",
                                type,@"tt",
                                nil];
    
    return [NSString stringWithFormat:@"%@?%@",url, [self convertRequestToStringWithDictionary:paramDict]];
}

+ (BOOL)trackingConversionToURL:(NSString *)url
{
    for (int i = 0; i < DMCTReportRetryTimes; i++)
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSURLResponse *response;
        NSError *error = nil;
        
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                     returningResponse:&response
                                                                 error:&error];
        
        if((!error) && ([(NSHTTPURLResponse *)response statusCode] == 200) && ([responseData length] > 0))
        {
            return YES;
        }
        else
        {
            [NSThread sleepForTimeInterval:DMCTReportRetryInterval];
            continue;
        }
    }
    
    return NO;
}

// 获得本地配置文件的路径
+ (NSString *)localProfilePath
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [searchPaths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:DMCTFileName];
}

// 获取本地的Profile文件，如果文件不存在，则创建一个新文件，并使用初始值初始化
+ (NSMutableDictionary *)localProfileDict
{
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    NSString *path = [self localProfilePath];
    NSMutableDictionary *localProfileDict = nil;

    if ([fileManager fileExistsAtPath:path])
    {
        localProfileDict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        
    }
    else
    {
        localProfileDict = [NSMutableDictionary dictionary];
        [localProfileDict setValue:[NSDate date] forKey:DMCTParamActivationTime];
        [localProfileDict setValue:[NSNumber numberWithBool:NO] forKey:DMCTParamTurnoff];
        [self updateLocalProfile:localProfileDict];
    }
    
    return localProfileDict;
}

// 更新本地配置文件，将内容持久化到存储中
+ (BOOL)updateLocalProfile:(NSMutableDictionary *)profileDict
{
    BOOL isSuccess = [profileDict writeToFile:[self localProfilePath] atomically:NO];
    if (!isSuccess)
    {
        NSLog(@"[Domob] Fail to persist profile file. %@", [self localProfilePath]);
    }
    return isSuccess;
}

#pragma mark -
#pragma mark Utils

+ (NSString *)macAddress
{
    // MAC address
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        return nil;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        return nil;
    }
    
    if ((buf = malloc(len)) == NULL) {
        return nil;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
		free(buf);
        return nil;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    
    NSString *macStr = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                        *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    
    free(buf);
    
    return macStr;
}

+ (NSString *)md5:(NSString *)string
{
    NSString *tmp = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (tmp && [tmp length] > 0)
    {
        const char *cStr = [string UTF8String];
        unsigned char result[CC_MD5_DIGEST_LENGTH];
        CC_MD5( cStr, strlen(cStr), result );
        
        return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
                result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
    }
    return [NSString string];
}

+ (NSString *)bundleIdentifier
{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:bundlePath];
    NSString *pbidentifier = [dict valueForKey:@"CFBundleIdentifier"];
    
    return pbidentifier ? pbidentifier : @"";
}

+ (NSString *)convertRequestToStringWithDictionary:(NSDictionary *)dicRequest
{
	NSString *tmp = nil;
	NSArray *keys = [dicRequest allKeys];
	for (NSString *key in keys)
    {	
		NSString *value=[dicRequest valueForKey:key];
		if (tmp == nil) {
			tmp = [NSString stringWithFormat:@"%@=%@", key, [self urlEncodedString:value]];
		}
		else {
			tmp = [tmp stringByAppendingFormat:@"&%@=%@", key, [self urlEncodedString:value]];
		}
	}
	return tmp;
}

+ (NSString *)urlEncodedString:(NSString *)string
{
	NSString *newString = [NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))) autorelease];
	if (newString) {
		return newString;
	}
	return @"";
}

+ (NSString *)hardwarePlatform
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    
    return platform;
}

+ (NSString *)identifierForAdvertising
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if (NSClassFromString(@"ASIdentifierManager"))
    {
        return [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
    }
#endif
    return @"";
}

+ (NSString *)isLimitAdTracking
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if (NSClassFromString(@"ASIdentifierManager"))
    {
        NSString *ifa = [ASIdentifierManager sharedManager].advertisingTrackingEnabled ? @"0" : @"1";
        return ifa;
    }
#endif
    return @"0";
}
@end
