//
//  AdTrackingAdwo.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#include <stdio.h> 
#include <stdlib.h> 
#include <math.h> 
#include <string.h> 
#include <unistd.h> 
#include <sys/ioctl.h> 
#include <sys/types.h> 
#include <sys/sysctl.h> 
#include <sys/socket.h> 
#include <netinet/in.h> 
#include <netdb.h> 
#include <arpa/inet.h> 
#include <sys/sockio.h> 
#include <net/if.h> 
#include <net/ethernet.h>
#include <errno.h> 
#include <net/if_dl.h> 
#include <ifaddrs.h> 
#include <mach/machine.h>

static BOOL GetMACAddress(char macAddr[64]) { 
	int mib[6];
	size_t len; 
	char buf[1024];
	unsigned char *ptr; 
	struct if_msghdr *ifm;
	struct sockaddr_dl *sdl;
	
	mib[0] = CTL_NET; 
	mib[1] = AF_ROUTE; 
	mib[2] = 0; 
	mib[3] = AF_LINK; 
	mib[4] = NET_RT_IFLIST; 
	
	if ((mib[5] = if_nametoindex("en0")) == 0) { 
		printf("Error: if_nametoindex error/n"); 
		return FALSE;
	} 
	
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
		printf("Error: sysctl, take 1/n"); 
		return FALSE; 
	} 
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) { 
		printf("Error: sysctl, take 2");
		return FALSE; 
	} 
	ifm = (struct if_msghdr *)buf; 
	sdl = (struct sockaddr_dl *)(ifm + 1); 
	ptr = (unsigned char *)LLADDR(sdl); 
	sprintf(macAddr, "%.2X:%.2X:%.2X:%.2X:%.2X:%.2X", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5));
	return TRUE;
}


#import "AdTrackingAdwo.h"
#import "ASIFormDataRequest.h"
#import "UIDevice+IdentifierAddition.h"

@implementation AdTrackingAdwo

-(void)tracking{
	
	[super tracking];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults]; 
	NSString * key = [NSString stringWithFormat:@"%@_adwoInstall",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]]; 
	
	if([defaults boolForKey:key]==NO){
		
		NSString * bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]; 
		NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		
		char buffer[64] = {'\0'};
		
		NSString * macAddress = @"00:00:00:00:00:00";
		if(GetMACAddress(buffer)){
			macAddress = [NSString stringWithFormat:@"%s", buffer];
			memset(buffer, 0, sizeof(buffer));
		}
		
		size_t size = 64;
		sysctlbyname("hw.machine", buffer, &size, NULL, 0);
		
		NSString * deviceType = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
		
		////////////////////////////////////////////////////////////////////////
		
		/*
		NSString * uri = @"http://offer.adwo.com:8080/offerwall_track/track?pack=%@&imei=%@&code=%@&ostype=%@";
		NSString * url = [[NSString stringWithFormat:uri, bundleName, macAddress, version, deviceType] 
						  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
												 cachePolicy:NSURLRequestReloadIgnoringCacheData 
											 timeoutInterval:12.0];
		NSURLResponse *urlResponse = nil;
		NSError *error = nil;
		
		[NSURLConnection sendSynchronousRequest:request 
							  returningResponse:&urlResponse
										  error:&error];
		
		int code = (urlResponse ? [(NSHTTPURLResponse *)urlResponse statusCode] : -1); 
		if (!error && (code == 200)) {
			[defaults setBool:YES forKey:key];
			[self over];
		}
		*/
		
		NSURL * url = [NSURL URLWithString:@"http://offer.adwo.com:8080/offerwall_track/track"];
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
		
		[request setPostValue:bundleName forKey:@"pack"];
		[request setPostValue:macAddress forKey:@"imei"];
		[request setPostValue:version forKey:@"code"];
		[request setPostValue:deviceType forKey:@"ostype"];
		
		[request setCompletionBlock:^{
			[defaults setBool:YES forKey:key];
			[defaults synchronize];
			[self over];
		}];
		
		[request setFailedBlock:^{
			[defaults setBool:NO forKey:key];
			[self over];
		}];
		
		[request setRequestMethod:@"GET"];
		[request startAsynchronous];
		
	}else{
		[self over];
	}
	
}

@end
