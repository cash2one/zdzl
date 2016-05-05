//
//  AdTrackingYdUmtrack.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import "AdTrackingYdUmtrack.h"

@implementation AdTrackingYdUmtrack

-(void)tracking{
	
	[super tracking];
	
	NSString * appKey = @"9a11d89e5fac195d4cac8aa319e14c03";
	NSString * deviceName = [[[UIDevice currentDevice] name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString * mac = [self macString];
	NSString * urlString = [NSString stringWithFormat:@"http://log.umtrack.com/ping/%@/?devicename=%@&mac=%@", appKey,deviceName,mac];
	[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] delegate:nil];
	
	[self over];
}

-(NSString*)macString{
	
	int mib[6];
	size_t len;
	char * buf;
	unsigned char *ptr;
	struct if_msghdr*ifm;
	struct sockaddr_dl *sdl;
	
	mib[0] = CTL_NET;
	mib[1] = AF_ROUTE;
	mib[2] = 0;
	mib[3] = AF_LINK;
	mib[4] = NET_RT_IFLIST;
	
	if((mib[5] =if_nametoindex("en0")) ==0) {
		printf("Error: if_nametoindex error\n");
		return NULL;
	}
	
	if(sysctl(mib,6,NULL, &len,NULL,0) <0) {
		printf("Error: sysctl, take 1\n");
		return NULL;
	}
	
	if((buf =malloc(len)) ==NULL) {
		printf("Could not allocate memory. error!\n");
		return NULL;
	}
	
	if(sysctl(mib,6, buf, &len,NULL,0) <0) {
		printf("Error: sysctl, take 2");
		free(buf);
		return NULL;
	}
	
	ifm = (struct if_msghdr *)buf;
	sdl = (struct sockaddr_dl *)(ifm +1);
	ptr = (unsigned char*)LLADDR(sdl);
	NSString * macString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
							    *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
	free(buf);
	
	return macString;
}

@end
