//
//  TiledMapInfo.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-13.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "TiledMapInfo.h"

#import "NSData+GZIP.h"
#import "NSDataAES256.h"
#import "NSString+MD5Addition.h"

@implementation TiledMapInfo

-(id)initWithTMXFile:(NSString*)tmxFile{
	if( (self=[super init])) {
		[self internalInit:tmxFile resourcePath:nil];
		[self parseXMLFile:_filename];
	}
	return self;
}

-(void)internalInit:(NSString*)tmxFileName resourcePath:(NSString*)resourcePath{
	self.tilesets = [NSMutableArray arrayWithCapacity:4];
	self.layers = [NSMutableArray arrayWithCapacity:4];
	self.filename = tmxFileName;
	self.resources = resourcePath;
	self.objectGroups = [NSMutableArray arrayWithCapacity:4];
	self.properties = [NSMutableDictionary dictionaryWithCapacity:5];
	self.tileProperties = [NSMutableDictionary dictionaryWithCapacity:5];
	
	// tmp vars
	_currentString = [[NSMutableString alloc] initWithCapacity:1024];
	_storingCharacters = NO;
	_layerAttribs = TMXLayerAttribNone;
	_parentElement = TMXPropertyNone;
	_currentFirstGID = 0;
	
}

-(void)parseXMLFile:(NSString *)xmlFilename{
	NSURL * url = [NSURL fileURLWithPath:[[CCFileUtils sharedFileUtils] fullPathFromRelativePath:xmlFilename] ];
	NSData * data = [NSData dataWithContentsOfURL:url];
	[self parseXMLData:data];
}

-(void)parseXMLData:(NSData*)data{
	
	if(data){
		data = [data AES256DecryptWithKey:[@"cdgw097qmrnkwef" stringFromMD5]];
		data = [data gunzippedData];
	}
	
	NSXMLParser * parser = [[[NSXMLParser alloc] initWithData:data] autorelease];
	
	// we'll do the parsing
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	[parser parse];
	
	NSAssert1( ![parser parserError], @"Error parsing TMX data: %@.", [NSString stringWithCharacters:[data bytes] length:[data length]] );
	
}

// the XML parser calls here with all the elements
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if([elementName isEqualToString:@"map"]) {
		NSString *version = [attributeDict objectForKey:@"version"];
		if( ! [version isEqualToString:@"1.0"] )
			CCLOG(@"cocos2d: TMXFormat: Unsupported TMX version: %@", version);
		NSString *orientationStr = [attributeDict objectForKey:@"orientation"];
		if( [orientationStr isEqualToString:@"orthogonal"])
			_orientation = CCTMXOrientationOrtho;
		else if ( [orientationStr isEqualToString:@"isometric"])
			_orientation = CCTMXOrientationIso;
		else if( [orientationStr isEqualToString:@"hexagonal"])
			_orientation = CCTMXOrientationHex;
		else
			CCLOG(@"cocos2d: TMXFomat: Unsupported orientation: %d", _orientation);
		
		_mapSize.width = [[attributeDict objectForKey:@"width"] intValue];
		_mapSize.height = [[attributeDict objectForKey:@"height"] intValue];
		_tileSize.width = [[attributeDict objectForKey:@"tilewidth"] intValue];
		_tileSize.height = [[attributeDict objectForKey:@"tileheight"] intValue];
		
		// The parent element is now "map"
		_parentElement = TMXPropertyMap;
	} else if([elementName isEqualToString:@"tileset"]) {
		
		// If this is an external tileset then start parsing that
		NSString *externalTilesetFilename = [attributeDict objectForKey:@"source"];
		if (externalTilesetFilename) {
			
			/*
			// Tileset file will be relative to the map file. So we need to convert it to an absolute path
			NSString *dir = [filename_ stringByDeletingLastPathComponent];	// Directory of map file
			if (!dir){
				dir = resources_;
			}
			
			//externalTilesetFilename = [dir stringByAppendingPathComponent:externalTilesetFilename];	// Append path to tileset file
			
			//TODO not use it 
			//[self parseXMLFile:externalTilesetFilename];
			*/
			
		} else {
			
			CCTMXTilesetInfo *tileset = [CCTMXTilesetInfo new];
			tileset.name = [attributeDict objectForKey:@"name"];
			tileset.firstGid = [[attributeDict objectForKey:@"firstgid"] intValue];
			tileset.spacing = [[attributeDict objectForKey:@"spacing"] intValue];
			tileset.margin = [[attributeDict objectForKey:@"margin"] intValue];
			CGSize s;
			s.width = [[attributeDict objectForKey:@"tilewidth"] intValue];
			s.height = [[attributeDict objectForKey:@"tileheight"] intValue];
			tileset.tileSize = s;
			
			[_tilesets addObject:tileset];
			[tileset release];
		}
		
	}else if([elementName isEqualToString:@"tile"]){
		CCTMXTilesetInfo* info = [_tilesets lastObject];
		NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:3];
		_parentGID =  [info firstGid] + [[attributeDict objectForKey:@"id"] intValue];
		[_tileProperties setObject:dict forKey:[NSNumber numberWithInt:_parentGID]];
		
		_parentElement = TMXPropertyTile;
		
	}else if([elementName isEqualToString:@"layer"]) {
		CCTMXLayerInfo *layer = [CCTMXLayerInfo new];
		layer.name = [attributeDict objectForKey:@"name"];
		
		CGSize s;
		s.width = [[attributeDict objectForKey:@"width"] intValue];
		s.height = [[attributeDict objectForKey:@"height"] intValue];
		layer.layerSize = s;
		
		layer.visible = ![[attributeDict objectForKey:@"visible"] isEqualToString:@"0"];
		
		if( [attributeDict objectForKey:@"opacity"] )
			layer.opacity = 255 * [[attributeDict objectForKey:@"opacity"] floatValue];
		else
			layer.opacity = 255;
		
		int x = [[attributeDict objectForKey:@"x"] intValue];
		int y = [[attributeDict objectForKey:@"y"] intValue];
		layer.offset = ccp(x,y);
		
		[_layers addObject:layer];
		[layer release];
		
		// The parent element is now "layer"
		_parentElement = TMXPropertyLayer;
		
	} else if([elementName isEqualToString:@"objectgroup"]) {
		
		CCTMXObjectGroup *objectGroup = [[CCTMXObjectGroup alloc] init];
		objectGroup.groupName = [attributeDict objectForKey:@"name"];
		CGPoint positionOffset;
		positionOffset.x = [[attributeDict objectForKey:@"x"] intValue] * _tileSize.width;
		positionOffset.y = [[attributeDict objectForKey:@"y"] intValue] * _tileSize.height;
		objectGroup.positionOffset = positionOffset;
		
		[_objectGroups addObject:objectGroup];
		[objectGroup release];
		
		// The parent element is now "objectgroup"
		_parentElement = TMXPropertyObjectGroup;
		
	} else if([elementName isEqualToString:@"image"]) {
		
		CCTMXTilesetInfo *tileset = [_tilesets lastObject];
		
		// build full path
		
		int width = [[attributeDict objectForKey:@"width"] intValue];
		int height = [[attributeDict objectForKey:@"height"] intValue];
		tileset.imageSize = CGSizeMake(width, height);
		
		NSString *imagename = [attributeDict objectForKey:@"source"];
		NSString *path = [_filename stringByDeletingLastPathComponent];
		if (!path)
			path = _resources;
		tileset.sourceImage = [path stringByAppendingPathComponent:imagename];
		
	} else if([elementName isEqualToString:@"data"]) {
		NSString *encoding = [attributeDict objectForKey:@"encoding"];
		NSString *compression = [attributeDict objectForKey:@"compression"];
		
		if( [encoding isEqualToString:@"base64"] ) {
			_layerAttribs |= TMXLayerAttribBase64;
			_storingCharacters = YES;
			
			if( [compression isEqualToString:@"gzip"] )
				_layerAttribs |= TMXLayerAttribGzip;
			
			else if( [compression isEqualToString:@"zlib"] )
				_layerAttribs |= TMXLayerAttribZlib;
			
			NSAssert( !compression || [compression isEqualToString:@"gzip"] || [compression isEqualToString:@"zlib"], @"TMX: unsupported compression method" );
		}
		
		NSAssert( _layerAttribs != TMXLayerAttribNone, @"TMX tile map: Only base64 and/or gzip/zlib maps are supported" );
		
	} else if([elementName isEqualToString:@"object"]) {
		
		CCTMXObjectGroup *objectGroup = [_objectGroups lastObject];
		
		// The value for "type" was blank or not a valid class name
		// Create an instance of TMXObjectInfo to store the object and its properties
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:10];
		
		// Parse everything automatically
		NSArray *array = [NSArray arrayWithObjects:@"name", @"type", @"width", @"height", @"gid", nil];
		for( id key in array ) {
			NSObject *obj = [attributeDict objectForKey:key];
			if( obj )
				[dict setObject:obj forKey:key];
		}
		
		// But X and Y since they need special treatment
		// X
		NSString *value = [attributeDict objectForKey:@"x"];
		if( value ) {
			int x = [value intValue] + objectGroup.positionOffset.x;
			[dict setObject:[NSNumber numberWithInt:x] forKey:@"x"];
		}
		
		// Y
		value = [attributeDict objectForKey:@"y"];
		if( value )  {
			int y = [value intValue] + objectGroup.positionOffset.y;
			
			// Correct y position. (Tiled uses Flipped, cocos2d uses Standard)
			y = (_mapSize.height * _tileSize.height) - y - [[attributeDict objectForKey:@"height"] intValue];
			[dict setObject:[NSNumber numberWithInt:y] forKey:@"y"];
		}
		
		// Add the object to the objectGroup
		[[objectGroup objects] addObject:dict];
		[dict release];
		
		// The parent element is now "object"
		_parentElement = TMXPropertyObject;
		
	} else if([elementName isEqualToString:@"property"]) {
		
		if ( _parentElement == TMXPropertyNone ) {
			
			CCLOG( @"TMX tile map: Parent element is unsupported. Cannot add property named '%@' with value '%@'",
				  [attributeDict objectForKey:@"name"], [attributeDict objectForKey:@"value"] );
			
		} else if ( _parentElement == TMXPropertyMap ) {
			
			// The parent element is the map
			[_properties setObject:[attributeDict objectForKey:@"value"] forKey:[attributeDict objectForKey:@"name"]];
			
		} else if ( _parentElement == TMXPropertyLayer ) {
			
			// The parent element is the last layer
			CCTMXLayerInfo *layer = [_layers lastObject];
			// Add the property to the layer
			[[layer properties] setObject:[attributeDict objectForKey:@"value"] forKey:[attributeDict objectForKey:@"name"]];
			
		} else if ( _parentElement == TMXPropertyObjectGroup ) {
			
			// The parent element is the last object group
			CCTMXObjectGroup *objectGroup = [_objectGroups lastObject];
			[[objectGroup properties] setObject:[attributeDict objectForKey:@"value"] forKey:[attributeDict objectForKey:@"name"]];
			
		} else if ( _parentElement == TMXPropertyObject ) {
			
			// The parent element is the last object
			CCTMXObjectGroup *objectGroup = [_objectGroups lastObject];
			NSMutableDictionary *dict = [[objectGroup objects] lastObject];
			
			NSString *propertyName = [attributeDict objectForKey:@"name"];
			NSString *propertyValue = [attributeDict objectForKey:@"value"];
			
			[dict setObject:propertyValue forKey:propertyName];
			
		} else if ( _parentElement == TMXPropertyTile ) {
			
			NSMutableDictionary* dict = [_tileProperties objectForKey:[NSNumber numberWithInt:_parentGID]];
			NSString *propertyName = [attributeDict objectForKey:@"name"];
			NSString *propertyValue = [attributeDict objectForKey:@"value"];
			[dict setObject:propertyValue forKey:propertyName];
		}
		
	} else if ([elementName isEqualToString:@"polygon"]) {
		
		// find parent object's dict and add polygon-points to it
		CCTMXObjectGroup *objectGroup = [_objectGroups lastObject];
		NSMutableDictionary *dict = [[objectGroup objects] lastObject];
		[dict setObject:[attributeDict objectForKey:@"points"] forKey:@"polygonPoints"];
		
	} else if ([elementName isEqualToString:@"polyline"]) {
		
		// find parent object's dict and add polyline-points to it
		CCTMXObjectGroup *objectGroup = [_objectGroups lastObject];
		NSMutableDictionary *dict = [[objectGroup objects] lastObject];
		[dict setObject:[attributeDict objectForKey:@"points"] forKey:@"polylinePoints"];
	}
}


@end
