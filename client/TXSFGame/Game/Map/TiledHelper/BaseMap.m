//
//  BaseMap.m
//  TXSFGame
//
//  Created by TigerLeung on 13-2-26.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "BaseMap.h"
#import "TiledMapInfo.h"

#import "Game.h"

@implementation BaseMap

+(id)tiledMapWithTMXFile:(NSString*)tmxFile{
	return [[[self alloc] initWithTMXFile:tmxFile] autorelease];
}

-(void)onEnter{
	[super onEnter];
}

-(id)initWithTMXFile:(NSString*)tmxFile{
	if((self=[super init])){
		[self setContentSize:CGSizeZero];
		
		if(tmxFile){
			TiledMapInfo * mapInfo = [TiledMapInfo formatWithTMXFile:tmxFile];
			
			if([mapInfo.tilesets count]>0){
				[self buildWithMapInfo:mapInfo];
			}
			
		}
		
	}
	return self;
}

-(void) buildWithMapInfo:(CCTMXMapInfo*)mapInfo{
	
	
}

@end
