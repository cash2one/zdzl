//
//  GameResourceLoader.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-18.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "ASINetworkQueue.h"
#import "SSZipArchive.h"
#import "Config.h"

#define DOWNLOAD_CACHEING NO
#define DOWNLOAD_RETRY_COUNT 0

#define DOWNLOAD_TIMEOUT (15*60)
#define DOWNLOAD_RESUME_FILE YES

static GameResourceLoader * resourceLoader = nil;
static id downloadPercentHandle = nil;

@implementation GameLoaderHelper

@synthesize path;
@synthesize target;
@synthesize call;
@synthesize isUnzip;
@synthesize isFire;
@synthesize type;
@synthesize isError;
@synthesize isPostLoading;

+(GameLoaderHelper*)createHelper{
	GameLoaderHelper * helper = [[[GameLoaderHelper alloc] init] autorelease];
	return helper;
}
+(GameLoaderHelper*)create:(NSString*)path{
	GameLoaderHelper * helper = [GameLoaderHelper createHelper];
	helper.path = path;
	return helper;
}
+(GameLoaderHelper*)create:(NSString*)path isUnzip:(BOOL)upzip{
	GameLoaderHelper * helper = [GameLoaderHelper createHelper];
	helper.path = path;
	helper.isUnzip = upzip;
	return helper;
}
+(GameLoaderHelper*)create:(NSString*)path target:(id)target call:(SEL)call{
	GameLoaderHelper * helper = [GameLoaderHelper createHelper];
	helper.path = path;
	helper.target = target;
	helper.call = call;
	return helper;
}

+(NSArray*)helpersFilter:(NSArray*)helpers{
	NSMutableArray * beDownload = [NSMutableArray array];
	NSMutableArray * cuts = [NSMutableArray array];
	for(GameLoaderHelper * helper1 in helpers){
		BOOL isNotIdentical = YES;
		for(GameLoaderHelper * helper2 in beDownload){
			if([helper2 isIdenticalHelper:helper1]){
				isNotIdentical = NO;
			}
		}
		if(isNotIdentical){
			[beDownload addObject:helper1];
		}else{
			[cuts addObject:helper1];
		}
	}
	
	for(GameLoaderHelper * helper1 in beDownload){
		[helper1 unbondOthers:cuts];
	}
	
	return beDownload;
}

-(void)setPath:(NSString*)_path{
	if(path){
		[path release];
		path = nil;
	}
	if(_path){
		path = _path;
		[path retain];
	}
}

-(id)init{
	if((self=[super init])!=nil){
		
	}
	return self;
}

-(void)setTarget:(id)_target{
	target = _target;
}

-(NSString*)getDownloadUrl{
	if(resourceLoader.downloadPath && path){
		return [resourceLoader.downloadPath stringByAppendingFormat:@"/%@",path];
	}
	return @"";
}
-(NSString*)getSavePath{
	if(resourceLoader.resourcePath && path){
		return [resourceLoader.resourcePath stringByAppendingPathComponent:path];
	}
	return @"";
}
-(NSString*)getTempPath{
	NSString * save = [self getSavePath];
	return [save stringByAppendingString:@".cache"];
}

-(ASIHTTPRequest*)getHTTPRequest{
	if(!request){
		request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[self getDownloadUrl]]];
		request.downloadDestinationPath = [self getSavePath];
		request.temporaryFileDownloadPath = [self getTempPath];
		request.timeOutSeconds = DOWNLOAD_TIMEOUT;
		request.allowResumeForFileDownloads = DOWNLOAD_RESUME_FILE;
		request.userInfo = [NSDictionary dictionaryWithObject:self forKey:@"helper"];
		if(DOWNLOAD_CACHEING){
			request.downloadCache = [ASIDownloadCache sharedCache];
		}
	}
	return request;
}

-(NSString*)getUnzipPath{
	NSString * savePath = [self getSavePath];
	return [savePath stringByDeletingLastPathComponent];
}

-(void)removeSaveFile{
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	[fileMgr removeItemAtPath:[self getSavePath] error:nil];
}

-(void)bondOthers:(NSArray*)helpers{
	if(bondingOther==nil){
		bondingOther = [[NSMutableArray alloc] init];
	}
	[bondingOther addObjectsFromArray:helpers];
	[bondingOther removeObject:self];
}
-(void)unbondHelper:(GameLoaderHelper*)helper{
	if(bondingOther){
		[bondingOther removeObject:helper];
	}
}
-(void)unbondOthers:(NSArray*)helpers{
	if(bondingOther){
		[bondingOther removeObjectsInArray:helpers];
	}
}

-(BOOL)checkBondingOthers{
	BOOL isComplete = YES;
	if(bondingOther){
		for(GameLoaderHelper * helper in bondingOther){
			[helper unbondHelper:self];
			if(!helper.isFire){
				isComplete = NO;
			}
		}
	}
	return isComplete;
}

-(void)free{
	target = nil;
	call = nil;
}

-(void)fire{
	
	if(!resourceLoader) return;
	
	isPostLoading = NO;
	
	if(request.responseStatusCode>=300){
		
		CCLOG(@"Download error %@",[self getDownloadUrl]);
		
		request = nil;
		[self removeSaveFile];
		
		//TODO redownload???
		if(//type==PathType_map ||
		   //type==PathType_fight_bg ||
		   //type==PathType_fight_role ||
		   //type==PathType_fight_effects ||
		   //type==PathType_fight_sname ||
		   (retryCount<DOWNLOAD_RETRY_COUNT)){
			retryCount++;
			[[GameResourceLoader shared] delayDownloadHelper:self time:1.5f];
			return;
		}
		
		[self error];
		
		if(retryCount>=(DOWNLOAD_RETRY_COUNT-1)){
			//TODO show error message
			[self doFireCallTarget];
			return;
		}
		
	}
	
	if(isUnzip){
		[self retain];
		dispatch_queue_t find_queue = dispatch_queue_create("process.unziper", NULL);
		dispatch_async(find_queue, ^{
			
			NSString * refile = [self getSavePath];
			NSString * filename = [[refile componentsSeparatedByString:@"/"] lastObject];
			filename = [filename stringByDeletingPathExtension];
			
			NSString * tofile = [NSString stringWithFormat:@"%@/%@.%@",[self getUnzipPath],filename,randomLetter(6)];
			
			[SSZipArchive unzipFileAtPath:refile toDestination:tofile];
			[self removeSaveFile];
			
			NSString * spath = [NSString stringWithFormat:@"%@/%@",tofile,filename];
			NSString * tpath = [[self getSavePath] stringByDeletingPathExtension];
			
			NSFileManager *fileMgr = [NSFileManager defaultManager];
			[fileMgr moveItemAtPath:spath toPath:tpath error:nil];
			[fileMgr removeItemAtPath:tofile error:nil];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self doFireCallTarget];
				[self release];
			});
			
		});
		dispatch_release(find_queue);
		
	}else{
		[self doFireCallTarget];
	}
}

-(void)doFireCallTarget{
	if(isFire) return;
	isFire = YES;
	if([self checkBondingOthers]){
		if(target!=nil && call!=nil){
			if([target respondsToSelector:call]){
				[target performSelector:call];
			}
		}
	}
	[self checkParallelHelpers];
}

-(BOOL)isIdenticalHelper:(GameLoaderHelper*)helper{
	if([self isEqualUrlHelper:helper]){
		return [self isEqualCallHelper:helper];
	}
	return NO;
}
-(BOOL)isEqualUrlHelper:(GameLoaderHelper*)helper{
	NSString * url1 = [self getDownloadUrl];
	NSString * url2 = [helper getDownloadUrl];
	if([[url1 uppercaseString] isEqualToString:[url2 uppercaseString]]){
		return YES;
	}
	return NO;
}
-(BOOL)isEqualCallHelper:(GameLoaderHelper*)helper{
	if(self.target==helper.target && self.call==helper.call){
		return YES;
	}
	return NO;
}

-(void)addParallelHelper:(GameLoaderHelper*)helper{
	
	if(self==helper) return;
	if(![self isEqualUrlHelper:helper]) return;
	
	if(parallelHelpers==nil){
		parallelHelpers = [[NSMutableArray alloc] init];
	}
	
	if([self isEqualCallHelper:helper]){
		[self free];
	}
	
	for(GameLoaderHelper * loader in parallelHelpers){
		if([loader isEqualCallHelper:helper]){
			[loader free];
		}
	}
	[parallelHelpers addObject:helper];
}

-(void)error{
	isError = YES;
	if(parallelHelpers){
		for(GameLoaderHelper * loader in parallelHelpers){
			[loader error];
		}
	}
}

-(void)checkParallelHelpers{
	if(parallelHelpers){
		for(GameLoaderHelper * loader in parallelHelpers){
			[loader doFireCallTarget];
		}
	}
}

-(void)dealloc{
	
	if(path){
		[path release];
		path = nil;
	}
	if(bondingOther){
		[bondingOther release];
		bondingOther = nil;
	}
	if(parallelHelpers){
		[parallelHelpers release];
		parallelHelpers = nil;
	}
	
	CCLOG(@"GameLoaderHelper dealloc");
	
	[super dealloc];
}

-(NSString*)description{
	NSString * description = [super description];
	return [NSString stringWithFormat:@"%@ %@",description,[self getDownloadUrl]];
}

@end

@implementation GameResourceLoader

@synthesize resourcePath;
@synthesize downloadPath;

+(void)cleanCache{
	NSString * path = getLibraryPath();
	NSString * dir = [NSString stringWithFormat:@"%@/%@/",path,GAME_Resources_DIR];
	deleteFile(dir);
}

+(GameResourceLoader*)shared{
	if(!resourceLoader){
		resourceLoader = [[GameResourceLoader alloc] init];
		[GameResourceLoader createAllDirectory];
	}
	return resourceLoader;
}

+(void)downloadPercentHandle:(id)handle{
	downloadPercentHandle = handle;
}

+(void)stopAll{
	if(resourceLoader){
		//[resourceLoader release];
		//resourceLoader = nil;
		[resourceLoader stop];
	}
}

+(NSString*)getFilePathByType:(PathType)type target:(NSString*)target{
	NSString * path = @"";
	
	if(type==PathType_map)				path = @"gmaps";
	if(type==PathType_map_npc)			path = @"images/npcs";
	if(type==PathType_map_monster)		path = @"images/monsters";
	
	if(type==PathType_fight_bg)			path = @"images/fight/fbg";
	if(type==PathType_fight_role)		path = @"images/fight/ani";
	if(type==PathType_fight_effects)	path = @"images/fight/eff/effects";
	if(type==PathType_fight_sname)		path = @"images/fight/sname";
	
	if(type==PathType_car)				path = @"images/animations/car";
	if(type==PathType_role)				path = @"images/animations/role";
	if(type==PathType_role_image)		path = @"images/ui/equip_pic";
	if(type==PathType_role_thumb)		path = @"images/ui/characterIcon/recruit_icon";
	
	if(type==PathType_icon_equip)		path = @"images/ui/equipment";
	if(type==PathType_icon_fate)		path = @"images/ui/fate";
	if(type==PathType_icon_item)		path = @"images/ui/item";
	if(type==PathType_icon_spirit)		path = @"images/ui/spirits";
	if(type==PathType_icon_task)		path = @"images/ui/task_icon";
	if(type==PathType_icon_car)			path = @"images/ui/carIcons";
	
	if(type==PathType_icon_role)		path = @"images/ui/characterIcon/head_icon";
	if(type==PathType_icon_monster)		path = @"images/ui/characterIcon/monster_icon";
	if(type==PathType_icon_member)		path = @"images/ui/characterIcon/mumber_icon";
	if(type==PathType_icon_team)		path = @"images/ui/characterIcon/team_icon";
	
	if(type==PathType_weapon)			path = @"images/ui/weapon";
	
	if(type==PathType_talk_npc)			path = @"images/talk/n";
	if(type==PathType_talk_role)		path = @"images/talk/r";
	
	if(type==PathType_inbetweening)		path = @"images/inbetweening";
	
	if(type==PathType_activity)			path = @"activity";
	
	if(type==PathType_icon_jewel)		path = @"images/ui/jewel";
	
	if([path length]>0){
		return [NSString stringWithFormat:@"%@/%@",path,target];
	}
	
	return path;
}

+(void)createAllDirectory{
	
	[GameResourceLoader createDirectoryByType:PathType_map];
	[GameResourceLoader createDirectoryByType:PathType_map_npc];
	[GameResourceLoader createDirectoryByType:PathType_map_monster];
	
	[GameResourceLoader createDirectoryByType:PathType_fight_bg];
	[GameResourceLoader createDirectoryByType:PathType_fight_role];
	[GameResourceLoader createDirectoryByType:PathType_fight_effects];
	[GameResourceLoader createDirectoryByType:PathType_fight_sname];
	
	[GameResourceLoader createDirectoryByType:PathType_car];
	[GameResourceLoader createDirectoryByType:PathType_role];
	[GameResourceLoader createDirectoryByType:PathType_role_image];
	[GameResourceLoader createDirectoryByType:PathType_role_thumb];
	
	[GameResourceLoader createDirectoryByType:PathType_icon_equip];
	[GameResourceLoader createDirectoryByType:PathType_icon_fate];
	[GameResourceLoader createDirectoryByType:PathType_icon_item];
	[GameResourceLoader createDirectoryByType:PathType_icon_spirit];
	[GameResourceLoader createDirectoryByType:PathType_icon_task];
	[GameResourceLoader createDirectoryByType:PathType_icon_car];
	
	[GameResourceLoader createDirectoryByType:PathType_icon_role];
	[GameResourceLoader createDirectoryByType:PathType_icon_monster];
	[GameResourceLoader createDirectoryByType:PathType_icon_member];
	[GameResourceLoader createDirectoryByType:PathType_icon_team];
	
	[GameResourceLoader createDirectoryByType:PathType_weapon];
	
	[GameResourceLoader createDirectoryByType:PathType_talk_npc];
	[GameResourceLoader createDirectoryByType:PathType_talk_role];
	
	[GameResourceLoader createDirectoryByType:PathType_activity];
	
	[GameResourceLoader createDirectoryByType:PathType_inbetweening];
	[GameResourceLoader createDirectoryByType:PathType_icon_jewel];
	
}

+(void)createDirectoryByType:(PathType)type{
	NSString * path = [GameResourceLoader getFilePathByType:type target:@""];
	path = [resourceLoader.resourcePath stringByAppendingPathComponent:path];
	if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
		[[NSFileManager defaultManager] createDirectoryAtPath:path 
								  withIntermediateDirectories:YES 
												   attributes:nil 
														error:nil];
	}
}

#pragma mark -

-(id)init{
	
	if((self=[super init])!=nil){
		
		//NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		//NSString * tPath = [paths objectAtIndex:0];
		
		NSString * tPath = getLibraryPath();
		resourcePath = [tPath stringByAppendingPathComponent:GAME_Resources_DIR];
		[resourcePath retain];
		
		[[CCFileUtils sharedFileUtils] addSearchPath:resourcePath];
		
		networkQueue = [[ASINetworkQueue alloc] init];
		[networkQueue setRequestDidFinishSelector:@selector(downloadComplete:)];
		[networkQueue setRequestDidFailSelector:@selector(downloadFailed:)];
		
		networkQueue.delegate = self;
		networkQueue.showAccurateProgress = YES;
		networkQueue.downloadProgressDelegate = self;
		
		downloading = [[NSMutableArray alloc] init];
		
	}
	return self;
}

-(void)dealloc{
	
	resourceLoader = nil;
	
	[resourcePath release];
	resourcePath = nil;
	
	[networkQueue reset];
	[networkQueue release];
	networkQueue = nil;
	
	[downloading release];
	downloading = nil;
	
	if(downloadPath){
		[downloadPath release];
		downloadPath = nil;
	}
	
	[super dealloc];
}

-(void)setDownloadPath:(NSString*)path{
	if(downloadPath){
		[downloadPath release];
		downloadPath = nil;
	}
	downloadPath = path;
	[downloadPath retain];
}

#pragma mark -
-(void)downloadComplete:(ASIHTTPRequest*)request{
	GameLoaderHelper * helper = [request.userInfo objectForKey:@"helper"];
	[helper fire];
	[downloading removeObject:helper];
}

-(void)downloadFailed:(ASIHTTPRequest*)request{
	GameLoaderHelper * helper = [request.userInfo objectForKey:@"helper"];
	[helper fire];
	[downloading removeObject:helper];
}

#pragma mark -

-(void)syncDownloadHelpers:(NSArray*)helpers{
	
	helpers = [GameLoaderHelper helpersFilter:helpers];
	
	BOOL isGo = NO;	
	for(id target in helpers){
		if([target isKindOfClass:[GameLoaderHelper class]]){
			
			GameLoaderHelper * helper = target;
			
			if(![self checkDownloadingTarget:helper]){
				[downloading addObject:helper];
				[networkQueue addOperation:[helper getHTTPRequest]];
				isGo = YES;
			}
			
		}
	}
	
	if(isGo) [networkQueue go];
}

-(void)downloadHelper:(GameLoaderHelper*)helper{
	if(![self checkDownloadingTarget:helper]){
		[downloading addObject:helper];
		[networkQueue addOperation:[helper getHTTPRequest]];
		[networkQueue go];
	}
}

-(void)delayDownloadHelper:(GameLoaderHelper*)helper time:(float)time{
	[NSTimer scheduledTimerWithTimeInterval:time 
									 target:self 
								   selector:@selector(doDelayDownloadHelper:) 
								   userInfo:helper 
									repeats:NO];
}

-(void)doDelayDownloadHelper:(NSTimer*)timer{
	[self downloadHelper:timer.userInfo];
}

-(void)setProgress:(float)percent{
	if(downloadPercentHandle && [self checkisPost]){
		SEL selector = @selector(downloadPercent:);
		if([downloadPercentHandle respondsToSelector:selector]){
			[downloadPercentHandle performSelector:selector 
										withObject:[NSNumber numberWithFloat:percent]];
		}
	}
}

-(BOOL)checkDownloadingTarget:(GameLoaderHelper*)target{
	for(GameLoaderHelper * helper in downloading){
		if([helper isEqualUrlHelper:target]){
			if(!helper.isError){
				[helper addParallelHelper:target];
				return YES;
			}
		}
	}
	return NO;
}

-(BOOL)checkisPost{
	for(GameLoaderHelper * helper in downloading){
		if(helper.isPostLoading){
			return YES;
		}
	}
	return NO;
}

-(void)stop{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	for(GameLoaderHelper * helper in downloading){
		[helper free];
	}
	if(networkQueue){
		[networkQueue cancelAllOperations];
	}
}


@end
