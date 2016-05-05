//
//  EFDeviceInfo.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFDeviceInfo.h"
#import "sys/utsname.h"
#import "UIDevice+IdentifierAddition.h"
#import "NSData+Base64.h"
#import "NSDataAES256.h"
#import "NSData+GZIP.h"
#import "NSString+MD5Addition.h"
#import "CJSONSerializer.h"
#import "CJSONDeserializer.h"

@implementation EFDeviceInfo

+(NSString*)model{
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString * machine = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	NSArray * machines = [machine componentsSeparatedByString:@","];
	return [machines objectAtIndex:0];
}

+(NSString*)version{
	return [[UIDevice currentDevice] systemVersion];
}

+(NSString*)macaddress{
	
	//TODO
	//return @"ee:ee:ee:ee:ee:F8";
	return [[UIDevice currentDevice] macaddress];
}

+(NSString*)dataPath{
	
	NSFileManager * fileMgr = [NSFileManager defaultManager];
	
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString * path = [paths objectAtIndex:0];
	
 	NSString * oldFile = [path stringByAppendingPathComponent:@"/UserData"];
	
	paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	path = [paths objectAtIndex:0];
	
	NSString * newFile = [path stringByAppendingPathComponent:@"/UserData"];
	
	if([fileMgr fileExistsAtPath:oldFile]){
		[fileMgr moveItemAtPath:oldFile toPath:newFile error:nil];
	}
	
	return newFile;
}

+(NSDictionary*)getCacheData{
	NSData * data = [NSData dataWithContentsOfFile:[self dataPath]];
	if(data){
		data = [data gunzippedData];
		data = [data AES256DecryptWithKey:[@"sdf4wousanflsd112" stringFromMD5]];
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer] deserializeAsDictionary:data error:&error];
		if(!error){
			return json;
		}
	}
	return nil;
}

+(void)saveCacheData:(NSDictionary*)data{
	NSError * error = nil;
	NSData * json = [[CJSONSerializer serializer] serializeObject:data error:&error];
	if(!error){
		json = [NSData gzipData:[json AES256EncryptWithKey:[@"sdf4wousanflsd112" stringFromMD5]]];
		[json writeToFile:[self dataPath] atomically:YES];
	}
}

@end
