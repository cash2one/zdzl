//
//  BaseGameConfig.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-3.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "BaseGameConfig.h"
#import "Config.h"
#import "SSKeychain.h"
#import "NSData+Base64.h"
#import "NSDataAES256.h"
#import "NSString+MD5Addition.h"
#import "UIDevice+IdentifierAddition.h"

#define CONFIGURATION_KEYCHAIN_SERVICE @"com.service.game"
#define CONFIGURATION_KEYCHAIN_FILE @"file_"
#define CONFIGURATION_KEYCHAIN_PASSWORD @"password_"

#define CONFIGURATION_KEYCHAIN_LOCAL_RECORD @"efun.game.local.record"

static int sortBytLogout(NSDictionary*p1, NSDictionary*p2, void*context){
	
	int pid = [(NSNumber*)context intValue];
	
	if([[p1 objectForKey:@"id"] intValue]==pid){
		return NSOrderedAscending;
	}
	if([[p2 objectForKey:@"id"] intValue]==pid){
		return NSOrderedDescending;
	}
	
	int tLogout1 = [[p1 objectForKey:@"tLogout"] intValue];
	int tLogout2 = [[p2 objectForKey:@"tLogout"] intValue];
	if(tLogout1>tLogout2) return NSOrderedAscending;
	return NSOrderedDescending;
}

@implementation BaseGameConfig

@synthesize userId;
@synthesize serverId;
@synthesize userInfo;

@synthesize playerId;

-(void)dealloc{
	[self freeRecord];
	[super dealloc];
}

-(void)logUserId:(int)uid{
	
	NSUserDefaults * def = [NSUserDefaults standardUserDefaults];  
	[def setObject:[NSNumber numberWithInt:uid] forKey:@"currentUser"];
	
	BOOL isLog = NO;
	NSArray * ary = [def objectForKey:@"uids"];
	if(!ary) ary = [NSArray array];
	NSMutableArray * uids = [NSMutableArray arrayWithArray:ary];
	for(NSNumber * tid in uids){
		if([tid intValue]==uid){
			isLog = YES;
		}
	}
	if(isLog){
		[uids addObject:[NSNumber numberWithInt:uid]];
		[def setObject:uids forKey:@"uids"];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)logServerId:(int)sid{
	NSUserDefaults * def = [NSUserDefaults standardUserDefaults];  
	[def setObject:[NSNumber numberWithInt:sid] forKey:@"currentServer"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(id)loadLogByKey:(NSString*)key{
	NSUserDefaults * def = [NSUserDefaults standardUserDefaults];  
	return [def objectForKey:key];
}

#pragma mark -

-(void)start{
	userId = [[self loadLogByKey:@"currentUser"] intValue];
	serverId = [[self loadLogByKey:@"currentServer"] intValue];
	[self loadUserInfo];
}

-(void)loadUserInfo{
	
	if(userId>0 && serverId>0){
		
		if(userInfo){
			[userInfo release];
			userInfo = nil;
		}
		
		NSString * key = [self loadUserKey];
		if([self checkHasRecord:key]){
			NSDictionary * dict = [self readRecord:key];
			userInfo = [[NSMutableDictionary alloc] initWithDictionary:dict];
		}else{
			userInfo = [[NSMutableDictionary alloc] init];
			[userInfo setObject:[NSNumber numberWithInt:userId] forKey:@"uid"];
			[userInfo setObject:@"" forKey:@"username"];
			[userInfo setObject:@"" forKey:@"password"];
			[userInfo setObject:[NSNumber numberWithInt:serverId] forKey:@"servetId"];
			[userInfo setObject:[NSArray array] forKey:@"players"];
			[self saveRecord:userInfo key:key];
		}
	}
}
-(NSString*)loadUserKey{
	return [NSString stringWithFormat:@"user_%d_%d",userId,serverId];
}

#pragma mark -

-(void)save:(NSString*)username password:(NSString*)password{
	if(userInfo){
		[userInfo setObject:username forKey:@"username"];
		[userInfo setObject:password forKey:@"password"];
		[self saveRecord:userInfo key:[self loadUserKey]];
	}
}

-(void)savePlayerList:(NSArray*)players{
	if(userInfo){
		[userInfo setObject:players forKey:@"players"];
		[self saveRecord:userInfo key:[self loadUserKey]];
	}
}
-(void)addPlayerToList:(NSDictionary*)player{
	if(userInfo){
		NSMutableArray * players = [NSMutableArray arrayWithArray:[userInfo objectForKey:@"players"]];
		[players addObject:player];
		[userInfo setObject:players forKey:@"players"];
		[self saveRecord:userInfo key:[self loadUserKey]];
	}
}
-(NSArray*)getPlayerList{
	if(userInfo){
		NSMutableArray * result = [NSMutableArray arrayWithArray:[userInfo objectForKey:@"players"]];
		[result sortUsingFunction:sortBytLogout context:[NSNumber numberWithInt:playerId]];
		return result;
	}
	return nil;
}
#pragma mark -

-(void)setUserId:(int)uid{
	if(userId==uid) return;
	userId = uid;
	[self logUserId:userId];
	[self loadUserInfo];
	
	[self freeRecord];
}

-(void)setServerId:(int)sid{
	if(serverId==sid) return;
	serverId = sid;
	[self logServerId:serverId];
	[self loadUserInfo];
	
	[self freeRecord];
}

//==============================================================================
#pragma mark -
//==============================================================================

-(void)initPlayerData:(NSDictionary*)data{
	//NSMutableDictionary *data1=[NSMutableDictionary dictionaryWithDictionary:data];
	NSDictionary * player = [data objectForKey:@"player"];
	self.playerId = [[player objectForKey:@"id"] intValue];
	gameRecord = [[NSMutableDictionary alloc] initWithDictionary:data];
	[self saveGameRecord];
}
-(void)resetPlayerData:(NSDictionary*)data{ 
	
	self.playerId = [[[data objectForKey:@"player"] objectForKey:@"id"] intValue];
	//TODO check all data?
	gameRecord = [[NSMutableDictionary alloc] initWithDictionary:data];
	
	[self saveGameRecord];
}

-(void)setPlayerId:(int)pid{
	if(playerId==pid) return;
	[self freeRecord];
	
	//load or create new record
	playerId = pid;
	
	/*
	if([self checkHasRecord:[self loadPlayerKey]]){
		[self readGameRecord];
	}else{
		[self createGameRecord];
	}
	*/
	
}

-(void)freeRecord{
	if(gameRecord){
		[self saveGameRecord];
		[gameRecord release];
		gameRecord = nil;
	}
	playerId = 0;
}

-(NSString*)loadPlayerKey{
	return [NSString stringWithFormat:@"%@_%d",[self loadUserKey],playerId];
}

//==============================================================================
#pragma mark -
//==============================================================================

-(BOOL)checkHasRecord:(NSString*)key{
	NSString * filePath = getFilePathByName([self getRandomFileName:key]);
	if(checkHasFile(filePath)){
		return YES;
	}
	return NO;
}

-(NSString*)getRandomFileName:(NSString*)key{
	NSString * filename = [NSString stringWithFormat:@"%@_%@",CONFIGURATION_KEYCHAIN_FILE,key];
	filename = [filename stringFromMD5];
	NSString * string = [SSKeychain passwordForService:CONFIGURATION_KEYCHAIN_SERVICE account:filename];
	if(string==nil){
		[SSKeychain setPassword:randomLetter(16)
					 forService:CONFIGURATION_KEYCHAIN_SERVICE 
						account:filename];
		string = [SSKeychain passwordForService:CONFIGURATION_KEYCHAIN_SERVICE 
										account:filename];
	}
	return [NSString stringWithFormat:@"_%@_",string];
}

-(NSString*)getRandomPassword:(NSString*)key{
	NSString * password = [NSString stringWithFormat:@"%@_%@",CONFIGURATION_KEYCHAIN_PASSWORD,key];
	password = [password stringFromMD5];
	NSString * string = [SSKeychain passwordForService:CONFIGURATION_KEYCHAIN_SERVICE 
											   account:password];
	if(string==nil){
		[SSKeychain setPassword:randomLetter(16)
					 forService:CONFIGURATION_KEYCHAIN_SERVICE 
						account:password];
		string = [SSKeychain passwordForService:CONFIGURATION_KEYCHAIN_SERVICE 
										account:password];
	}
	return string;
}

-(void)saveRecord:(NSDictionary*)target key:(NSString*)key{
	
	//TODO 用default 来存储 soul
	return;
	
//	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//	[defaults setBool:isPlayBackgroundMusic forKey:MUSIC_SETTING_PLAY_BG];
//	[defaults setBool:isPlayEffectMusic forKey:MUSIC_SETTING_PLAY_EF];
//	[defaults synchronize];
	
	
	NSString * gameRecordPassword = [self getRandomPassword:key];
	
	NSDictionary * dict = [NSDictionary dictionaryWithDictionary:target];
	NSString * filePath = getFilePathByName([self getRandomFileName:key]);
	NSString * error;
	NSData * data = [NSPropertyListSerialization dataFromPropertyList:dict 
															   format:NSPropertyListBinaryFormat_v1_0 
													 errorDescription:&error];
	NSData * encodeData = [data AES256EncryptWithKey:gameRecordPassword];
	NSString * str = [encodeData base64EncodedString];
	
	[NSKeyedArchiver archiveRootObject:str toFile:filePath];
	
}

-(NSDictionary*)readRecord:(NSString*)key{
	
	if(![self checkHasRecord:key]) return nil;
	
	NSString * gameRecordPassword = [self getRandomPassword:key];
	NSString * filePath = getFilePathByName([self getRandomFileName:key]);
	
	NSString * str = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
	NSData * data = [NSData dataFromBase64String:str];
	NSData * decodeData = [data AES256DecryptWithKey:gameRecordPassword];
	
	if(decodeData==nil){
		[self createGameRecord];
	}
	NSString *error;
	NSPropertyListFormat format;
	NSDictionary * dict = (NSDictionary*)[NSPropertyListSerialization propertyListFromData:decodeData 
																		  mutabilityOption:NSPropertyListImmutable 
																					format:&format 
																		  errorDescription:&error];
	
	return dict;
}

//==============================================================================
#pragma mark -
//==============================================================================

-(void)createGameRecord{
	gameRecord = [[NSMutableDictionary alloc] init];
	
	[gameRecord setObject:[NSString stringWithFormat:@"%d", playerId] forKey:@"pid"];
	[gameRecord setObject:[[UIDevice currentDevice] uniqueGlobalDeviceIdentifier] forKey:@"udid"];
	
	[self saveGameRecord];
}

-(void)readGameRecord{
	NSDictionary * dict = [self readRecord:[self loadPlayerKey]];
	gameRecord = [[NSMutableDictionary alloc] initWithDictionary:dict];
}

-(void)saveGameRecord{
	[self saveRecord:gameRecord key:[self loadPlayerKey]];
}

//==============================================================================
#pragma mark -
//==============================================================================

-(void)addData:(id)data key:(NSString*)key{
	[gameRecord setObject:data forKey:key];
	[self saveGameRecord];
}
-(id)getDataBykey:(NSString*)key{
	return [gameRecord objectForKey:key];
}

//==============================================================================
//保存本地数据
//==============================================================================
-(void)addLocalData:(id)data key:(NSString *)key
{
	NSDictionary *rms = [self readRecord:CONFIGURATION_KEYCHAIN_LOCAL_RECORD];
	if (!rms) {
		rms = [NSDictionary dictionary];
	}
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:rms];
	[dict setObject:data forKey:key];
	[self saveRecord:dict key:CONFIGURATION_KEYCHAIN_LOCAL_RECORD];
}
-(NSDictionary*)getLocalData
{
	NSDictionary *rms = [self readRecord:CONFIGURATION_KEYCHAIN_LOCAL_RECORD];
	if (!rms) {
		rms = [NSDictionary dictionary];
	}
	return rms;
}

@end
