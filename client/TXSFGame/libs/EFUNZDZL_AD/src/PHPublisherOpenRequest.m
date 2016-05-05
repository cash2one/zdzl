//
//  PHPublisherOpenRequest.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 3/30/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import "PHPublisherOpenRequest.h"
#import "PHConstants.h"
#import "SDURLCache.h"
#import "PHTimeInGame.h"
#import "PHTimeInGame.h"

#if PH_USE_OPENUDID == 1
#import "OpenUDID.h"
#endif

#if PH_USE_MAC_ADDRESS == 1
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <mach-o/dyld.h>

NSString *getMACAddress(void);

NSString *getMACAddress(){
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

    if ((mib[5] = if_nametoindex("en0")) == 0) 
    {
        PH_NOTE(@"Error: if_nametoindex error\n");
        return NULL;
    }

    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
    {
        PH_NOTE(@"Error: sysctl, take 1\n");
        return NULL;
    }

    if ((buf = malloc(len)) == NULL) 
    {
        PH_NOTE(@"Could not allocate memory. error!\n");
        return NULL;
    }

    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) 
    {
        PH_NOTE(@"Error: sysctl, take 2");
        free(buf);
        return NULL;
    }

    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *macAddress = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X", 
                            *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    macAddress = [macAddress lowercaseString];
    free(buf);

    return macAddress;
}
#endif


@interface PHAPIRequest(Private)
-(void)finish;
+(void)setSession:(NSString *)session;
@end

@implementation PHPublisherOpenRequest

+(void)initialize{
    
    if  (self == [PHPublisherOpenRequest class]){
        // Initializes pre-fetching and webview caching
        PH_SDURLCACHE_CLASS *urlCache = [[PH_SDURLCACHE_CLASS alloc] initWithMemoryCapacity:PH_MAX_SIZE_MEMORY_CACHE
                                                                 diskCapacity:PH_MAX_SIZE_FILESYSTEM_CACHE
                                                                     diskPath:[PH_SDURLCACHE_CLASS defaultCachePath]];
        [NSURLCache setSharedURLCache:urlCache];
        [urlCache release];
    }
}

@synthesize customUDID = _customUDID;

-(NSDictionary *)additionalParameters{    
    NSMutableDictionary *additionalParameters = [NSMutableDictionary dictionary];

    if (!!self.customUDID) {
        [additionalParameters setValue:self.customUDID forKey:@"d_custom"];
    }
    
#if PH_USE_OPENUDID == 1
        [additionalParameters setValue:[PH_OPENUDID_CLASS value] forKey:@"d_odid"];
#endif
#if PH_USE_MAC_ADDRESS == 1
    if (![PHAPIRequest optOutStatus]) {
        [additionalParameters setValue:getMACAddress() forKey:@"d_mac"];
    }
#endif
    
    [additionalParameters setValue:[NSNumber numberWithInt:[[PHTimeInGame getInstance] getCountSessions]] forKey:@"scount"];
    [additionalParameters setValue:[NSNumber numberWithInt:(int)floor([[PHTimeInGame getInstance] getSumSessionDuration])] forKey:@"ssum"];

    return  additionalParameters;
}

-(NSString *)urlPath{
    return PH_URL(/v3/publisher/open/);
}

#pragma mark - PHAPIRequest response delegate
-(void)send{
    [super send];
    [[PHTimeInGame getInstance] gameSessionStarted];
}

-(void)didSucceedWithResponse:(NSDictionary *)responseData{
    NSArray *urlArray = (NSArray *)[responseData valueForKey:@"precache"];
    if (!!urlArray) {
        for (NSString *urlString in urlArray){            
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:PH_REQUEST_TIMEOUT];
            NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:nil];
            [connection start];
        }
    }
    
    NSString *session = (NSString *)[responseData valueForKey:@"session"];
    if (!!session){
        [PHAPIRequest setSession:session];
    }
    
    if ([self.delegate respondsToSelector:@selector(request:didSucceedWithResponse:)]) {
        [self.delegate performSelector:@selector(request:didSucceedWithResponse:) withObject:self withObject:responseData];
    }
    
    // Reset time in game counters;
    [[PHTimeInGame getInstance] resetCounters];
    
    [self finish];
    
}

#pragma mark - NSObject

- (void)dealloc{
    [_customUDID release], _customUDID = nil;
    [super dealloc];
}

#pragma mark - NSOperationQueue observer
@end
