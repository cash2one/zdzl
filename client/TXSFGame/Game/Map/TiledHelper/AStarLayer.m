//
//  AStarLayer.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-25.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AStarLayer.h"

@implementation AStarLayer


-(void)dealloc{
	if(sourceImage){
		[sourceImage release];
		sourceImage = nil;
	}
	
	[super dealloc];
	
}

-(id) initWithTilesetInfo:(CCTMXTilesetInfo*)tilesetInfo 
				layerInfo:(CCTMXLayerInfo*)layerInfo 
				  mapInfo:(CCTMXMapInfo*)mapInfo{
	
	if((self = [super init])) {
		
		float capacity = (_layerSize.width * _layerSize.height) * 0.35f + 1;
		
		sourceImage = tilesetInfo.sourceImage;
		[sourceImage retain];
		
		_blendFunc.src = CC_BLEND_SRC;
		_blendFunc.dst = CC_BLEND_DST;
		
		// no lazy alloc in this node
		_children = [[CCArray alloc] initWithCapacity:capacity];
		_descendants = [[CCArray alloc] initWithCapacity:capacity];
		self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTextureColor];
		
		// layerInfo
		self.layerName = layerInfo.name;
		
		_layerSize = layerInfo.layerSize;
		_tiles = layerInfo.tiles;
		_minGID = layerInfo.minGID;
		_maxGID = layerInfo.maxGID;
		_opacity = layerInfo.opacity;
		self.properties = [NSMutableDictionary dictionaryWithDictionary:layerInfo.properties];
		
		self.tileset = tilesetInfo;
		
		_mapTileSize = mapInfo.tileSize;
		_layerOrientation = mapInfo.orientation;
		
		CGPoint offset = [self calculateOffset:layerInfo.offset];
		[self setPosition:CC_POINT_PIXELS_TO_POINTS(offset)];
		
		_atlasIndexArray = ccCArrayNew(_layerSize.width * _layerSize.height);
		
		[self setContentSize:
		 CC_SIZE_PIXELS_TO_POINTS(CGSizeMake( _layerSize.width * _mapTileSize.width, 
											 _layerSize.height * _mapTileSize.height ))
		 ];
		
		_useAutomaticVertexZ = NO;
		_vertexZvalue = 0;
		
		
		//[self loadTexture];
		
	}
	
	return self;
}

-(void)loadTexture{
	
	[[CCTextureCache sharedTextureCache] addImageAsync:sourceImage withBlock:^(CCTexture2D*tex){
		
		float capacity = (_layerSize.width * _layerSize.height) * 0.35f + 1;
		_textureAtlas = [[CCTextureAtlas alloc] initWithTexture:tex capacity:capacity];
		
		[self setupTiles];
		
	}];
}

-(CGPoint)calculateOffset:(CGPoint)pos{
	CGPoint ret = CGPointZero;
	switch( _layerOrientation ) {
		case CCTMXOrientationOrtho:
			ret = ccp( pos.x * _mapTileSize.width, -pos.y *_mapTileSize.height);
			break;
		case CCTMXOrientationIso:
			ret = ccp( (_mapTileSize.width /2) * (pos.x - pos.y),
					  (_mapTileSize.height /2 ) * (-pos.x - pos.y) );
			break;
		case CCTMXOrientationHex:
			NSAssert(CGPointEqualToPoint(pos, CGPointZero), @"offset for hexagonal map not implemented yet");
			break;
	}
	return ret;
}

-(uint32_t)tileGIDAt:(CGPoint)pos withFlags:(ccTMXTileFlags*)flags{
	
	if(!(_tiles && _atlasIndexArray)) return 0;
	
	if(pos.x<=0) return 0;
	if(pos.y<=0) return 0;
	if(pos.x>=_layerSize.width ) return 0;
	if(pos.y>=_layerSize.height) return 0;
	
	pos = ccp(MAX(pos.x, 0), MAX(pos.y, 0));
	pos = ccp(MIN(pos.x, _layerSize.width), MIN(pos.y, _layerSize.height));
	
	NSInteger idx = pos.x + pos.y * _layerSize.width;
	uint32_t tile = _tiles[idx];
	
	// issue1264, flipped tiles can be changed dynamically
	if (flags){
		*flags = tile & kCCFlipedAll;
	}
	
	return ( tile & kCCFlippedMask);
}

@end
