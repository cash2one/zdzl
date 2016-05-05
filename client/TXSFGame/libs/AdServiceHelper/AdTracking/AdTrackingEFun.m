//
//  AdTrackingEFun.m
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


#import "AdTrackingEFun.h"
#import "ASIFormDataRequest.h"

@implementation AdTrackingEFun

-(void)tracking{
	
	[super tracking];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults]; 
	NSString * key = [NSString stringWithFormat:@"%@_efun_Install",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]]; 
	
	if([defaults boolForKey:key]==NO){
		
		char buffer[64] = {'\0'};
		
		NSString * macAddress = @"00:00:00:00:00:00";
		if(GetMACAddress(buffer)){
			macAddress = [NSString stringWithFormat:@"%s", buffer];
			memset(buffer, 0, sizeof(buffer));
		}
		
		size_t size = 64;
		sysctlbyname("hw.machine", buffer, &size, NULL, 0);
		
		////////////////////////////////////////////////////////////////////////
		/*
		NSURL * url = [NSURL URLWithString:@"http://ad.52yh.com/ads_installStatistics.shtml"];
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
		[request setPostValue:macAddress forKey:@"mac"];
		[request setPostValue:@"zdzlios" forKey:@"gameCode"];
		[request setPostValue:@"iSNew_20130130" forKey:@"flage"];
		*/
		
		//ad.efun.com/ads_installStatistics.shtml?mac=xx&ip=xx&imei=xx&gameCode=zdzl&partner=efun&flage=iSNew_20130130
		NSURL * url = [NSURL URLWithString:@"http://ad.efun.com/ads_installStatistics.shtml"];
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
		[request setPostValue:macAddress forKey:@"mac"];
		[request setPostValue:@"zdzlios" forKey:@"gameCode"];
		[request setPostValue:@"efun" forKey:@"partner"];
		[request setPostValue:@"iSNew_20130130" forKey:@"flage"];
		
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
