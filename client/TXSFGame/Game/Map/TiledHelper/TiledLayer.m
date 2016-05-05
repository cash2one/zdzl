//
//  TiledLayer.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-6.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "TiledLayer.h"
#import "TiledMap.h"
#import "GameConnection.h"
#import "Config.h"

static NSMutableArray * tiledLayers;
static CGPoint targetPoint;

@implementation TiledLayer

+(void)checkMapPoint:(CGPoint)point{
	targetPoint = point;
	for(TiledLayer * layer in tiledLayers){
		[layer checkShow];
	}
}

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	
	CCLOG(@"TiledLayer onExit!");
	
	[tiledLayers removeObject:self];
	[super onExit];
}

-(void)dealloc{
	
	CCLOG(@"TiledLayer dealloc!");
	
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
		
		_blendFunc.src = CC_BLEND_SRC;
		_blendFunc.dst = CC_BLEND_DST;
		
		// no lazy alloc in this node
		_children = [[CCArray alloc] initWithCapacity:capacity];
		_descendants = [[CCArray alloc] initWithCapacity:capacity];
		self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTextureColor];
		
		// layerInfo
		self.layerName = layerInfo.name;
		
		sourceImage = tilesetInfo.sourceImage;
		[sourceImage retain];
		
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
		 CC_SIZE_PIXELS_TO_POINTS(CGSizeMake(_layerSize.width * _mapTileSize.width, 
											 _layerSize.height * _mapTileSize.height ))
		 ];
		
		_useAutomaticVertexZ= NO;
		_vertexZvalue = 0;
		
		if(!tiledLayers){
			tiledLayers = [[NSMutableArray alloc] init];
		}
		[tiledLayers addObject:self];
		
	}
	
	return self;
}

-(void)checkContent:(CGPoint)point{
	
	int t_w = _tileset.imageSize.width;
	int t_h = _tileset.imageSize.height;
	CGPoint p = [self positionAt:point];
	
	contentRect = CGRectMake(p.x, p.y, t_w, t_h);
	
}

-(void)postAction{
	if(isPost) return;
	isPost = YES;
	
	[GameConnection post:ConnPost_loadMapProgress object:nil];
	//[self scheduleOnce:@selector(doCall) delay:(getRandomInt(1000,5000)/1000)];
	
}
-(void)doCall{
	//[GameConnection post:ConnPost_loadMapProgress object:nil];
}

-(BOOL)isInShow{
	
	//TODO test on iPhone
	//return YES;
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	int tmp = 100;
	if([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone){
		tmp = 50;
	}
	CGRect winRect = CGRectMake(abs(targetPoint.x+tmp/2), abs(targetPoint.y+tmp/2), 
								winSize.width+tmp, winSize.height+tmp);
	
	if(CGRectIntersectsRect(contentRect,winRect)){
		return YES;
	}
	return NO;
}
-(void)checkShow{
	if([self isInShow]){
		[self loadTexture];
	}else{
		[self unloadTexture];
		[self postAction];
	}
}

-(void)loadTexture{
	
	if(isLoadTexture) return;
	isLoadTexture = YES;
	
	[[CCTextureCache sharedTextureCache] addImageAsync:sourceImage withBlock:^(CCTexture2D*tex){
		
		//CCLOG(@"load map file : \n\n%@\n\n",sourceImage);
		
		float capacity = (_layerSize.width * _layerSize.height) * 0.35f + 1;
		
		_textureAtlas = [[CCTextureAtlas alloc] initWithTexture:tex capacity:capacity];
		
		/*
		if(![textureAtlas_.texture hasPremultipliedAlpha]){
			blendFunc_.src = GL_SRC_ALPHA;
			blendFunc_.dst = GL_ONE_MINUS_SRC_ALPHA;
		}
		*/
		
		[self setupTiles];
		[self postAction];
		
	}];
}

-(void)unloadTexture{
	
	if(!isLoadTexture) return;
	isLoadTexture = NO;
	
	[super removeAllChildrenWithCleanup:YES];
	
	ccCArrayFree(_atlasIndexArray);
	_atlasIndexArray = ccCArrayNew(_layerSize.width * _layerSize.height);
	
	if(_textureAtlas) [_textureAtlas release];
	if(_reusedTile) [_reusedTile release];
	_textureAtlas = nil;
	_reusedTile = nil;
	
	//[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	
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
