//
//  GameFileUtils.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-18.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "GameFileUtils.h"

@implementation CCFileUtils(GameFileUtils)

+(BOOL)hasFilePathByTarget:(NSString*)target{
	//return NO;
	return [[CCFileUtils sharedFileUtils] checkHasTarget:target];
}

-(void)addSearchPathDirectory:(NSSearchPathDirectory)path target:(NSString*)target{
	NSArray * paths = NSSearchPathForDirectoriesInDomains(path, NSUserDomainMask, YES);
	NSString * tPath = [paths objectAtIndex:0];
	tPath = [tPath stringByAppendingPathComponent:target];
	[self addSearchPath:tPath];
}

-(void)addSearchPathDirectory:(NSSearchPathDirectory)path{
	NSArray * paths = NSSearchPathForDirectoriesInDomains(path, NSUserDomainMask, YES);
	[self addSearchPath:[paths objectAtIndex:0]];
}

-(void)addSearchPath:(NSString*)path{
	if(path && [path length]>0){
		BOOL beAddPath = YES;
		for(NSString * key in _searchPath){
			if([[key uppercaseString] isEqualToString:[path uppercaseString]]){
				beAddPath = NO;
			}
		}
		if(beAddPath){
			[_searchPath addObject:path];
			[self checkDirectory:path];
		}
	}
}

-(BOOL)checkHasTarget:(NSString*)path{
	//NSString * target = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:path];
	NSString * target = [self fullPathFromSearchPath:path];
	if([[NSFileManager defaultManager] fileExistsAtPath:target]){
		return YES;
	}
	return NO;
}

-(void)checkDirectory:(NSString*)path{
	if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
		[[NSFileManager defaultManager] createDirectoryAtPath:path 
								  withIntermediateDirectories:YES 
												   attributes:nil 
														error:nil];
	}
}


#pragma mark -

-(NSString*)fullPathFromSearchPath:relPath{
	
	BOOL found = NO;
	NSString * ret = @"";
	
	for( NSString *path in _searchPath ) {
		
		NSString *fileWithPath = [path stringByAppendingPathComponent:relPath];
		
		// Search with Suffixes
		for( NSString *device in _searchResolutionsOrder ) {
			
			if( _searchMode == kCCFileUtilsSearchSuffixMode ) {
				// Search using suffixes
				NSString *suffix = [_suffixesDict objectForKey:device];
				ret = [self getGamePath:fileWithPath forSuffix:suffix];
				
			} else {
				// Search in subdirectories
				NSString *directory = [_directoriesDict objectForKey:device];
				ret = [self getGamePath:fileWithPath forDirectory:directory];
			}
			
			if( ret ) {
				found = YES;
				break;
			}
			
		}
		
		if(found){
			break;
		}
	}
	
	if(!found){
		ret = relPath;
	}
	
	return ret;
	
}

#pragma mark -

-(NSString*) getGamePath:(NSString*)path forSuffix:(NSString*)suffix{
	NSString *newName = path;
	
	// only recreate filename if suffix is valid
	if( suffix && [suffix length] > 0)
	{
		NSString *pathWithoutExtension = [path stringByDeletingPathExtension];
		NSString *name = [pathWithoutExtension lastPathComponent];
		
		// check if path already has the suffix.
		if( [name rangeOfString:suffix].location == NSNotFound ) {
			
			
			NSString *extension = [path pathExtension];
			
			if( [extension isEqualToString:@"ccz"] || [extension isEqualToString:@"gz"] )
			{
				// All ccz / gz files should be in the format filename.xxx.ccz
				// so we need to pull off the .xxx part of the extension as well
				extension = [NSString stringWithFormat:@"%@.%@", [pathWithoutExtension pathExtension], extension];
				pathWithoutExtension = [pathWithoutExtension stringByDeletingPathExtension];
			}
			
			
			newName = [pathWithoutExtension stringByAppendingString:suffix];
			newName = [newName stringByAppendingPathExtension:extension];
		} else
			CCLOGWARN(@"cocos2d: WARNING Filename(%@) already has the suffix %@. Using it.", name, suffix);
	}
	
	NSString *ret = nil;
	// only if it is not an absolute path
	if( ! [path isAbsolutePath] ) {
		
		// pathForResource also searches in .lproj directories. issue #1230
		// If the file does not exist it will return nil.
		NSString *filename = [newName lastPathComponent];
		NSString *imageDirectory = [path stringByDeletingLastPathComponent];
		
		// on iOS it is OK to pass inDirector=nil and pass a path in "Resources",
		// but on OS X it doesn't work.
		ret = [self gamePathResource:filename
							  ofType:nil
						 inDirectory:imageDirectory];
	}
	else if( [_fileManager fileExistsAtPath:newName] )
		ret = newName;
	
	if( ! ret )
		CCLOGINFO(@"cocos2d: CCFileUtils: file not found: %@", [newName lastPathComponent] );
	
	return ret;
}

-(NSString*)getGamePath:(NSString*)path forDirectory:(NSString*)directory{	
	NSString *ret = nil;
	// only if it is not an absolute path
	if( ! [path isAbsolutePath] ) {
		
		// pathForResource also searches in .lproj directories. issue #1230
		// If the file does not exist it will return nil.
		NSString *filename = [path lastPathComponent];
		NSString *imageDirectory = [directory stringByAppendingPathComponent: [path stringByDeletingLastPathComponent]];
		
		// on iOS it is OK to pass inDirector=nil and pass a path in "Resources",
		// but on OS X it doesn't work.
		ret = [self gamePathResource:filename
							  ofType:nil
						 inDirectory:imageDirectory];
	}
	else
	{
		NSString* newDir = [path stringByDeletingLastPathComponent];
		NSString* newFile = [path lastPathComponent];
		NSString *newName = [[newDir stringByAppendingPathComponent:directory] stringByAppendingPathComponent:newFile];
		if ([_fileManager fileExistsAtPath:newName])
			ret = newName;
	}
	
	return ret;
}

-(NSString*)gamePathResource:(NSString*)resource ofType:(NSString *)ext inDirectory:(NSString *)subpath{
	// Default to normal resource directory
	return [_bundle pathForResource:resource
							 ofType:ext
						inDirectory:subpath];
}
@end
