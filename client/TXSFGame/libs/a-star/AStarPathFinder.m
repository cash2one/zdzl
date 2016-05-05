/*
 * AStarPathfinder https://github.com/sqlboy/tiled-games
 *
 * Copyright (c) 2011 Matt Chambers
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "AStarPathFinder.h"
#import "cocos2d.h"

@interface AStarPathFinder (Private)
- (AStarNode *)lowCostNode:(NSMutableSet*)nodes;
- (BOOL) isCollision:(CGPoint)point;
- (AStarNode *) findPathFrom:(CGPoint)src to:(CGPoint)dst;
//- (CGImageRef) makePathTile;
@end

@implementation AStarPathFinder
//@synthesize collideKey;
//@synthesize collideValue;
@synthesize considerDiagonalMovement;
//@synthesize groundLayer;

// Pre-define the neighboring tiles checked by the A* algorithm.
static const int numAdjacentTiles = 8;
static const int adjacentTiles[8][2] = {
	-1,1,	0,1,	1,1,
	-1,0,			1,0,
	-1,-1,	0,-1,	1,-1
};
// The default path highlight color
//static const float defaultPathFillColor[4] = {0.2, 0.5, 0.2, 0.3};

- (id) initWithTileMap:(CCTMXTiledMap*)aTileMap groundLayer:(NSString*)name
{
	if ((self=[super init])) {
		
		//tileMap = [aTileMap retain];
		
		CCTMXLayer * groundLayer = [aTileMap layerNamed:name];
		groundLayerSize = CGSizeMake(groundLayer.layerSize.width, groundLayer.layerSize.height);
		
		//openNodes = [[NSMutableSet setWithCapacity:16] retain];
		//closedNodes = [[NSMutableSet setWithCapacity:64] retain];
		
		collideLayers = [[NSMutableSet set] retain];
		
		//collideKey = ASTAR_COLLIDE_PROP_NAME;
		//collideValue = ASTAR_COLLIDE_PROP_VALUE;
		considerDiagonalMovement = YES;
		
		/*
		 memcpy(pathFillColor, defaultPathFillColor,
		 sizeof(defaultPathFillColor));
		 pathHighlightImage = [self makePathTile];
		 */
		
	}
	
	return self;
}

-(void)delayRelease{
	isRelease = YES;
	[self performSelector:@selector(release) withObject:nil afterDelay:3];
}

- (void) dealloc
{
	CCLOG(@"A-star dealloc");
	
	//[tileMap release];
	
	//[openNodes release];
	//[closedNodes release];
	[collideLayers release];
	//[collideKey release];
	//[collideValue release];
	/*
	 if (nil != pathHighlightImage) {
	 CFRelease(pathHighlightImage);
	 }
	 */
	[super dealloc];
}
/*
 - (CGImageRef) makePathTile
 {
 int width = [tileMap tileSize].width;
 int height = [tileMap tileSize].height;
 
 CGContextRef context = NULL;
 CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();
 
 context = CGBitmapContextCreate(NULL, width,
 height, 8, width * 4, imageColorSpace, kCGImageAlphaPremultipliedLast);
 
 CGContextSetRGBFillColor(context, pathFillColor[0],
 pathFillColor[1], pathFillColor[2], pathFillColor[3]);
 CGContextFillRect(context, CGRectMake(0, 0, width, height));
 
 return CGBitmapContextCreateImage(context);
 }
 */

- (AStarNode *) findPathFrom:(CGPoint)src to:(CGPoint)dst
{
	
	//[openNodes removeAllObjects];
	//[closedNodes removeAllObjects];
	
	NSMutableSet * openNodes = [NSMutableSet setWithCapacity:16];
	NSMutableSet * closedNodes = [NSMutableSet setWithCapacity:64];
	
	if ([self isCollision:src]) return nil;
	if ([self isCollision:dst]) return nil;
	
	AStarNode *origin = [AStarNode nodeAtPoint:src];
	//origin->parent = nil;
	origin.parent = nil;
	
	[openNodes addObject:origin];

	AStarNode * closestNode = nil;
	while ([openNodes count]){
		
		if(isRelease) return nil;
		
		closestNode = [self lowCostNode:openNodes];
		
		if (closestNode->point.x == dst.x && closestNode->point.y == dst.y){
			return closestNode;
		}
		
		[openNodes removeObject:closestNode];
		[closedNodes addObject:closestNode];
		
		for (int i=0; i<numAdjacentTiles; i++) {
			
			int x = adjacentTiles[i][0];
			int y = adjacentTiles[i][1];
			
			
			
			AStarNode * adjacentNode = [AStarNode nodeAtPoint:ccp(x + closestNode->point.x, y + closestNode->point.y)];
			
			//adjacentNode->parent = closestNode;
			adjacentNode.parent = closestNode;
			
			// Skip over this node if its already been closed.
			if ([closedNodes containsObject:adjacentNode])
				continue;
			
			// Skip over collide nodes, and add them to the closed set.
			if ([self isCollision:adjacentNode->point])
			{
				[closedNodes addObject:adjacentNode];
				//CCLOG(@"astart :run %i x:%i y:%i loop:%i  adjacentNode:%f :%f ",loopcount++,x,y,i,adjacentNode->point.x,adjacentNode->point.y);
				continue;
			}
			
			// Calculate G
			// G cost is 10 for adjacent and 14 for a diagonal move.
			// We use these numbers because the distance to move diagonally
			// is the square root of 2, or 1.414 the cost of moving
			// horizontally or vertically.
			if (abs(x) == 1 && abs(y) == 1)
			{
				if (![self considerDiagonalMovement])
					continue;
				adjacentNode->G = 14 + closestNode->G;
			}
			else
				adjacentNode->G = 10 + closestNode->G;
			
			// If the node is already in the open set, check and see if going
			// through the current node is a better path.
			if ([openNodes containsObject:adjacentNode])
			{
				AStarNode *otherNode = [openNodes member:adjacentNode];
				//int newCost = otherNode->G - otherNode->parent->G + closestNode->G;
				int newCost = otherNode->G - otherNode.parent->G + closestNode->G;
				if (newCost < otherNode->G)
				{
					otherNode->G = newCost;
					//otherNode->parent = closestNode;
					otherNode.parent = closestNode;
				}
			}
			else
			{
				// Calculate H
				// Uses 'Mahhattan' method wich is just the number
				// of horizonal and vertical hops to the target.
				adjacentNode->H = (abs(adjacentNode->point.x - dst.x) + abs(adjacentNode->point.y - dst.y)) * 10;
				[openNodes addObject:adjacentNode];
			}
		}
	}
	return nil;
}

- (NSArray*) getPath:(CGPoint)src to:(CGPoint)dst
{
	NSMutableArray *paths = [NSMutableArray array];
	AStarNode *node = [self findPathFrom:src to:dst];
	if (node == nil)
		return paths;
	while(node != nil){
		[paths addObject:node];
		//node = node->parent;
		node = node.parent;
	}
	
	return [[paths reverseObjectEnumerator] allObjects];
}

- (NSArray*) getPath:(CGPoint)src from:(CGPoint)dst{
	NSMutableArray *paths = [NSMutableArray array];
	AStarNode *node = [self findPathFrom:src to:dst];
	if (node == nil)
		return paths;
	while(node != nil){
		[paths addObject:node];
		//[paths insertObject:node atIndex:0];
		//node = node->parent;
		node = node.parent;
	}
	//return [[paths reverseObjectEnumerator] allObjects];
	return paths;
}

-(NSArray*)getBasePathFrom:(CGPoint)src to:(CGPoint)dst{
	NSArray * path1 = NULL;
	
	
	
	if((src.x<dst.x && src.y>dst.y) || (src.x>dst.x && src.y<dst.y)){
		path1 = [self getPath:dst from:src];
		return path1;
	}
	if((src.x>dst.x && src.y>dst.y) || (src.x<dst.x && src.y<dst.y)){
		path1 = [self getPath:src to:dst];
		return path1;
	}
	path1=[self getPath:src to:dst];
	
	/*
	 path1 = [self getPath:src to:dst];
	 
	 return path1;
	 */
	/*
	 if([path1 count]>0){
	 NSArray * path2 = [self getPath:dst from:src];
	 AStarNode * node1 = [path1 objectAtIndex:[path1 count]-1];
	 AStarNode * node2 = [path2 objectAtIndex:0];
	 if(node1->cod<node2->cod || [path1 count]<[path2 count]){
	 return path1;
	 }else{
	 return path2;
	 }
	 }
	 */
	if([path1 count]>0){
		return path1;
	}else{
		return [NSArray array];
	}
}

/*
 - (void) highlightPathFrom:(CGPoint)src to:(CGPoint)dst
 {
 [self clearHighlightPath];
 
 //NSArray *nodes = [self getPath:src to:dst];
 NSArray *nodes = [self getPath:src from:dst];
 
 if ([nodes count] == 0){
 return;
 }
 
 int tileWidthOffset = [tileMap tileSize].width / 2;
 int tileHeightOffset = [tileMap tileSize].height / 2;
 
 for(AStarNode *node in nodes)
 {
 CGPoint p1 = [groundLayer
 positionAt:node->point];
 p1.x = p1.x + tileWidthOffset;
 p1.y = p1.y + tileHeightOffset;
 
 CCSprite *spr = [CCSprite spriteWithCGImage:pathHighlightImage key:@"T"];
 spr.position = p1;
 [self addChild:spr];
 }
 }
 
 - (void) clearHighlightPath
 {
 [self removeAllChildrenWithCleanup:YES];
 }
 */
/*
 - (void) moveSprite:(CCSprite*)sprite
 from:(CGPoint)src to:(CGPoint)dst atSpeed:(float)speed
 {
 
 NSArray *nodes = [self getPath:src to:dst];
 if ([nodes count] == 0)
 return;
 
 NSMutableArray *actionList = [NSMutableArray array];
 
 int tileWidthOffset = [tileMap tileSize].width / 2;
 int tileHeightOffset = [tileMap tileSize].height / 2;
 
 for(AStarNode *node in nodes)
 {
 CGPoint p1 = [groundLayer
 positionAt:node->point];
 p1.x = p1.x + tileWidthOffset;
 p1.y = p1.y + tileHeightOffset;
 
 CCAction *move = [CCMoveTo actionWithDuration: speed position: p1];
 [actionList addObject:move];
 }
 [sprite runAction:[CCSequence actionsWithArray:actionList]];
 }
 */
- (void) addCollideLayer:(NSString*)name tileMap:(CCTMXTiledMap*)tileMap
{
	CCTMXLayer *layer = [tileMap layerNamed:name];
	if (layer != nil)
	{
		[collideLayers addObject:layer];
	}
}

- (void) removeCollideLayer:(NSString*)name tileMap:(CCTMXTiledMap*)tileMap
{
	[collideLayers removeObject:[tileMap layerNamed:name]];
}

- (BOOL) isCollision:(CGPoint)point
{
	if (point.x >= groundLayerSize.width || point.x < 0){
		return YES;
	}
	
	if (point.y >= groundLayerSize.height || point.y < 0){
		return YES;
	}
	
	for(CCTMXLayer *collideLayer in collideLayers)
	{
		// Check for a tile in the collide layer.
		UInt32 tileGid = [collideLayer tileGIDAt:point];
		if (tileGid)
		{
			/*
			 // If a tile exists, see if collide is enabled on the entire layer.
			 NSDictionary *ldict = [collideLayer propertyNamed:collideKey];
			 if (ldict)
			 return YES;
			 
			 // If not, then check the tile for the collide property.
			 NSDictionary *dict = [tileMap propertiesForGID:tileGid];
			 if (dict)
			 {
			 NSString *collide = [dict valueForKey:collideKey];
			 if (collide && [collide compare:collideValue] == NSOrderedSame)
			 return YES;
			 }
			 */
			return NO;
		}
	}
	return YES;
}

-(AStarNode*)lowCostNode:(NSMutableSet*)nodes{
	AStarNode *lowCostNode = [nodes anyObject];
	for (AStarNode* otherNode in nodes){
		if ([otherNode cost] < [lowCostNode cost]){
			lowCostNode = otherNode;
		}else if ([otherNode cost] == [lowCostNode cost]){
			if (otherNode->H < lowCostNode->H){
				lowCostNode = otherNode;
			}
		}
	}
	return lowCostNode;
}
/*
 - (void) setPathRGBAFillColor:(float)red
 g:(float)green
 b:(float)blue
 a:(float)alpha;
 {
 pathFillColor[0] = red;
 pathFillColor[1] = green;
 pathFillColor[2] = blue;
 pathFillColor[3] = alpha;
 if (nil != pathHighlightImage) {
 CFRelease(pathHighlightImage);
 }
 //pathHighlightImage = [self makePathTile];
 }
 */

@end

@implementation AStarNode
@synthesize parent;

+ (id) nodeAtPoint:(CGPoint)point;
{
	return [[[AStarNode alloc] initAtPoint:point] autorelease];
}

- (id) initAtPoint:(CGPoint)pnt
{
	point = pnt;
	x = pnt.x;
	y = pnt.y;
	cod = 0;
	return self;
}

- (void) dealloc
{
	parent = nil;
	[super dealloc];
}

- (int) cost
{
	return G + H;
}

- (NSUInteger) hash
{
	return (x << 16) | (y & 0xFFFF);
}

-(void)setParent:(AStarNode *)_parent{
	parent = _parent;
	if(parent){
		cod = parent->cod;
		if(parent.parent){
			
			CGPoint p1 = parent->point;
			CGPoint p2 = parent.parent->point;
			CGPoint t1 = ccp(0,0);
			CGPoint t2 = ccp(0,0);
			
			t1.x = p2.x-p1.x;
			t1.y = p2.y-p1.y;
			t2.x = p1.x-point.x;
			t2.y = p1.y-point.y;
			
			if(t1.x!=t2.x || t1.y!=t2.y){
				cod += 1;
			}
			
		}
	}
}

- (BOOL)isEqual:(id)otherObject
{
	if (![otherObject isKindOfClass:[self class]])
	{
		return NO;
	}
	
	AStarNode *otherNode = (AStarNode*) otherObject;
	if (point.x == otherNode->point.x && point.y == otherNode->point.y)
	{
		return YES;
	}
	
	return NO;
}

@end

