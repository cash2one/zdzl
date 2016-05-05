//
//  UIDevice(Identifier).m
//  UIDeviceAddition
//
//  Created by Georg Kitz on 20.08.11.
//  Copyright 2011 Aurora Apps. All rights reserved.
//

#import "UIDevice+IdentifierAddition.h"
#import "NSString+MD5Addition.h"
#import <AdSupport/ASIdentifierManager.h>
#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"
#import "SSKeychain.h"
#import "NSData+Base64.h"
#import "NSDataAES256.h"

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

static NSString * Macaddress_keys[] = {
	@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",
	@"a",@"b",@"c",@"d",@"e",@"f",
};
static NSString * randomMacaddress(){
	NSString * result = [NSString string];
	int total = (sizeof(Macaddress_keys)/sizeof(Macaddress_keys[0]));
	for(int i=0;i<6;i++){
		for(int j=0;j<2;j++){
			int index = arc4random()%total;
			result = [result stringByAppendingString:Macaddress_keys[index]];
		}
		if(i<5){
			result = [result stringByAppendingString:@":"];
		}
	}
	return [result uppercaseString];
}

@interface UIDevice(Private)
- (NSString *) macaddress;
@end

@implementation UIDevice (IdentifierAddition)

static NSString * cache_macaddress = nil;
static NSString * cache_identifier = nil;

+(void)updateInfo{
	
	BOOL isLoadCache = NO;
	
	NSString * pwd = @"2dvb56is23pl90ad";
	NSString * key = [NSString stringWithFormat:@"%@.info",[[NSBundle mainBundle] bundleIdentifier]];
	
	NSString * keychain = [SSKeychain passwordForService:key account:[pwd stringFromMD5]];
	if(keychain){
		NSData * infoData = [NSData dataFromBase64String:keychain];
		infoData = [infoData AES256DecryptWithKey:pwd];
		NSDictionary * json = [[CJSONDeserializer deserializer] deserializeAsDictionary:infoData error:nil];
		if(json){
			
			cache_macaddress = [[NSString alloc] initWithString:[json objectForKey:@"macaddress"]];
			cache_identifier = [[NSString alloc] initWithString:[json objectForKey:@"identifier"]];
			
			//isLoadCache = YES;
			return;
		}
	}
	
	if(isLoadCache==NO){
		
		NSString * macaddress = [[UIDevice currentDevice] macaddress];
		NSString * identifier = [[UIDevice currentDevice] getDeviceIdentifier];
		
		NSMutableDictionary * info = [NSMutableDictionary dictionary];
		[info setObject:macaddress forKey:@"macaddress"];
		[info setObject:identifier forKey:@"identifier"];
		
		NSData * data = [[CJSONSerializer serializer] serializeObject:info error:nil];
		data = [data AES256EncryptWithKey:pwd];
		NSString * string = [data base64EncodedString];
		
		cache_macaddress = [[NSString alloc] initWithString:macaddress];
		cache_identifier = [[NSString alloc] initWithString:identifier];
		
		[SSKeychain setPassword:string forService:key account:[pwd stringFromMD5]];
		
	}
	
}

-(NSString*)getDeviceIdentifier{
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if(version>=6){
		//return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
		return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
	}
	CFUUIDRef cfuuid = CFUUIDCreate(kCFAllocatorDefault);
	NSString * result = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, cfuuid);
	NSString * udid = [NSString stringWithString:result];
	CFBridgingRelease(cfuuid);
	CFBridgingRelease(result);
	return udid;
}

static NSString * deviceToken = nil;

+(void)setDeviceToken:(NSString*)token{
	if(deviceToken) [deviceToken release];
	deviceToken = [[NSString alloc] initWithString:token];
}

+(NSString*)deviceToken{
	return [[UIDevice currentDevice] deviceToken];
}

-(NSString*)deviceToken{
	if(deviceToken){
		return deviceToken;
	}
	return [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods
- (NSString *) macaddress{
	if(cache_macaddress!=nil && cache_macaddress.length > 0) return cache_macaddress;
	
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if(version>=7){
		return randomMacaddress();
	}
	
	NSString * macaddress = [self macaddress:@":"];
	if([macaddress isEqualToString:@"02:00:00:00:00:00"]){
		return randomMacaddress();
	}
	return macaddress;
}

// Return the local MAC addy
// Courtesy of FreeBSD hackers email list
// Accidentally munged during previous update. Fixed thanks to erica sadun & mlamb.
- (NSString *) macaddress:(NSString*)space{
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
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X%@%02X%@%02X%@%02X%@%02X%@%02X", 
                           *ptr, space, *(ptr+1), space, *(ptr+2), space, *(ptr+3), space, *(ptr+4), space, *(ptr+5)];
    free(buf);
    
    return outstring;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

- (NSString *) uniqueDeviceIdentifier{
    NSString *macaddress = [[UIDevice currentDevice] macaddress];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *stringToHash = [NSString stringWithFormat:@"%@%@",macaddress,bundleIdentifier];
    return [stringToHash stringFromMD5];
}

- (NSString *) uniqueGlobalDeviceIdentifier{
    NSString *macaddress = [[UIDevice currentDevice] macaddress];
    return [macaddress stringFromMD5];
}

@end
