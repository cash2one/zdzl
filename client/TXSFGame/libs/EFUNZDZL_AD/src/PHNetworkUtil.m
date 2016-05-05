//
//  PHNetworkUtil.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 5/4/12.
//  Copyright (c) 2012 Playhaven. All rights reserved.
//

#import "PHNetworkUtil.h"
#import "PHConstants.h"
#import <netinet/in.h>
#include <arpa/inet.h>

@interface PHNetworkUtil ()
-(void)_backgroundCheckDNSResolutionForURLPath:(NSString *)urlPath;
@end

@implementation PHNetworkUtil

+(id)sharedInstance{
    static dispatch_once_t pred;
    static PHNetworkUtil *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[PHNetworkUtil alloc] init];
    });
    return shared;
}

-(void)checkDNSResolutionForURLPath:(NSString *)urlPath{
    [self performSelectorInBackground:@selector(_backgroundCheckDNSResolutionForURLPath:) withObject:urlPath];
}

-(void)_backgroundCheckDNSResolutionForURLPath:(NSString *)urlPath{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    Boolean result = FALSE;
    CFHostRef hostRef = NULL;
    NSArray *addresses;
    NSString *hostname = [urlPath substringFromIndex:7];
    hostRef = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)hostname);
    if (hostRef) {
        result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL); // pass an error instead of NULL here to find out why it failed
        if (result == TRUE) {
            addresses = (NSArray*)CFHostGetAddressing(hostRef, &result);
        }
    }
    if (result == TRUE) {
        [addresses enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *strDNS = [NSString stringWithUTF8String:inet_ntoa(*((struct in_addr *)obj))];
            NSLog(@"Resolved %@ -> %@", hostname, strDNS);
        }];
        
    } else {
        NSLog(@"Could not resolve %@", hostname);
    }
    
    if(hostRef)
    {
        CFRelease(hostRef);
    }
    
    [pool release];
}

@end
