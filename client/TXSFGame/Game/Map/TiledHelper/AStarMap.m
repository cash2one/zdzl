//
//  AStartMap.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-25.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AStarMap.h"
#import "TiledMapInfo.h"
#import "AStarLayer.h"

@implementation AStartMap

/*
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
*/

-(void) buildWithMapInfo:(CCTMXMapInfo*)mapInfo{
	
	_mapSize = mapInfo.mapSize;
	_tileSize = mapInfo.tileSize;
	_mapOrientation = mapInfo.orientation;
	_objectGroups = [mapInfo.objectGroups retain];
	_properties = [mapInfo.properties retain];
	_tileProperties = [mapInfo.tileProperties retain];
	
	// set content size for tile info
	[self setContentSize:CGSizeMake(_mapSize.width*_tileSize.width, _mapSize.height*_tileSize.height)];
	
	int idx=0;
	
	for( CCTMXLayerInfo *layerInfo in mapInfo.layers ) {
		if( layerInfo.visible && ([layerInfo.name isEqualToString:TILED_COLLIDE] ||
								  [layerInfo.name isEqualToString:TILED_BLOCK] )) {
			CCNode *child = [self parseLayer:layerInfo map:mapInfo];
			[self addChild:child z:idx tag:idx];
			idx++;
		}
	}
	
}

-(id)parseLayer:(CCTMXLayerInfo*)layerInfo map:(CCTMXMapInfo*)mapInfo{
	
	NSDictionary * info = [self tilesetForLayer:layerInfo map:mapInfo];
	if(info){
		CCTMXTilesetInfo * tileset = [info objectForKey:@"tileset"];
		AStarLayer * layer = [AStarLayer layerWithTilesetInfo:tileset layerInfo:layerInfo mapInfo:mapInfo];
		layerInfo.ownTiles = NO;
		return layer;
	}
	
	return nil;
}

-(NSDictionary*)tilesetForLayer:(CCTMXLayerInfo*)layerInfo map:(CCTMXMapInfo*)mapInfo{
	CGSize size = layerInfo.layerSize;
	
	id iter = [mapInfo.tilesets reverseObjectEnumerator];
	for( CCTMXTilesetInfo* tileset in iter) {
		for( unsigned int y = 0; y < size.height; y++ ) {
			for( unsigned int x = 0; x < size.width; x++ ) {
				
				unsigned int pos = x + size.width * y;
				unsigned int gid = layerInfo.tiles[ pos ];
				
				// gid are stored in little endian.
				// if host is big endian, then swap
				gid = CFSwapInt32LittleToHost( gid );
				
				// XXX: gid == 0 --> empty tile
				if( gid != 0 ) {
					
					// Optimization: quick return
					// if the layer is invalid (more than 1 tileset per layer) an assert will be thrown later
					if( (gid & kCCFlippedMask) >= tileset.firstGid ){
						
						NSMutableDictionary * result = [NSMutableDictionary dictionary];
						[result setObject:tileset forKey:@"tileset"];
						[result setObject:[NSValue valueWithCGPoint:ccp(x,y)] forKey:@"point"];
						
						return result;
					}
				}
			}
		}
	}
	
	// If all the tiles are 0, return empty tileset
	CCLOG(@"cocos2d: Warning: TMX Layer '%@' has no tiles", layerInfo.name);
	return nil;
}

@end
