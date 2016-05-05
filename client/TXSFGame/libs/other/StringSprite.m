//
//  StringSprite.m
//  TXSFGame
//
//  Created by Soul on 13-5-24.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "StringSprite.h"
#import "Config.h"
#import "EventLayer.h"
#import "BrowLayer.h"
#import "CCNode+AddHelper.h"

static inline NSArray* parseContent(NSString* content){
	return nil;
}

static inline NSString* getPaintContent(NSArray* cnt){
	if (cnt != nil && cnt.count > 0) {
		return [NSString stringWithFormat:@"%@",[cnt objectAtIndex:0]];
	}
	return nil;
}

static inline ccColor3B getPaintFontColor(NSArray* cnt,NSString* color){
	if (color == nil) {
		color = [NSString stringWithFormat:@"ffffff"];
	}
	if (cnt != nil && cnt.count > 1) {
		return color3BWithHexString([NSString stringWithFormat:@"%@",[cnt objectAtIndex:1]]);
	}
	return color3BWithHexString(color);;
}

static inline NSString* getPaintFontName(NSArray* cnt,NSString* name){
	if (name == nil) {
		name = [NSString stringWithFormat:@"STHeitiTC-Medium"];
	}
	if (cnt != nil && cnt.count > 3) {
		return getCommonFontName([[cnt objectAtIndex:3] intValue]);
	}
	return name;
}

static inline int getPaintFontSize(NSArray* cnt,int fontSize){
	if (cnt != nil && cnt.count > 2) {
		CCLOG(@"getPaintFontSize - > START");
		NSString* temp = [NSString stringWithFormat:@"%@",[cnt objectAtIndex:2]];
		//fontSize = [temp intValue]==0?fontSize:[temp intValue];
		int newFontHeight = [temp  intValue];
		if ([temp intValue]==0) {
			return fontSize;
		}
		CCLOG(@"getPaintFontSize - > END");
		return cFixedScale(newFontHeight);
	}
	return fontSize;
}

static inline NSString* getPaintEventContent(NSArray* cnt){
	if (cnt != nil && cnt.count > 4) {
		return [NSString stringWithFormat:@"%@",[cnt objectAtIndex:4]];
	}
	return nil;
}

static inline NSString* checkDrawImage(NSString* cnt ,int index){
	//检测组合
	NSDictionary* css = getParseSetting(0);
	NSString* start = [NSString stringWithFormat:[css objectForKey:@"brewLeft"]];
	NSString* end = [NSString stringWithFormat:[css objectForKey:@"brewRight"]];
	
	if (cnt != nil && (index+start.length) < cnt.length) {
		NSRange rang;
		rang.location = index;
		rang.length = start.length;
		NSString *chars = [cnt substringWithRange:rang];
		if ([start isEqualToString:chars]) {
			NSString* right = [cnt substringFromIndex:index+start.length];
			NSRange rg = [right rangeOfString:end];
			if (rg.length > 0) {
				NSString* _temp = [right substringToIndex:rg.location];
				if (_temp != nil) {
					NSString* _str = [_temp stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
					if (_str.length == 0) {
						return [NSString stringWithFormat:@"%@%@%@",start,_temp,end];
					}
				}
			}
		}
	}
	return nil;
}

static inline int getDrawImageId(NSString* str){
	if (str != nil) {
		
		NSDictionary* css = getParseSetting(0);
		NSString* start = [NSString stringWithFormat:[css objectForKey:@"brewLeft"]];
		NSString* end = [NSString stringWithFormat:[css objectForKey:@"brewRight"]];
		
		NSRange rang;
		rang.location = start.length;
		rang.length = str.length - (start.length + end.length);
		NSString* temp = [str substringWithRange:rang];
		return [temp intValue];
	}
	return 0;
}

static inline CGSize getDrawImageRect(int pic){
	return CGSizeMake(cFixedScale(30),cFixedScale(30));
}

static inline NSArray* checkDrawLines(NSString* content ,
									NSString* font,
									CGSize viewSize,
									int fontSize,
									int rowH){
	
	CCLabelTTF *pen = [CCLabelTTF labelWithString:@"" fontName:font fontSize:fontSize];
	pen.verticalAlignment = kCCVerticalTextAlignmentCenter;
	pen.horizontalAlignment = kCCTextAlignmentLeft;
	pen.anchorPoint = ccp(0, 0.5);
	
	NSDictionary* css = getParseSetting(0);
	NSArray* tds = [content componentsSeparatedByString:[css objectForKey:@"td"]];
	
	int drawHeight = 0 ;
	int drawX = 0;
	
	NSMutableArray* heights = [NSMutableArray array];
	
	for (NSString* td in tds){
		NSArray* objs = [td componentsSeparatedByString:[css objectForKey:@"cell"]];
		NSString* pContent = getPaintContent(objs);
		pen.fontName = getPaintFontName(objs, font);
		pen.fontSize = getPaintFontSize(objs, fontSize);
		
		if (pContent != nil) {
			int length = pContent.length;
			for (int i = 0 ; i < length ; i++){
				NSString* iconStr = checkDrawImage(pContent, i);
				if (iconStr != nil) {
					i = i + iconStr.length - 1;
					
					float tWidth = getDrawImageRect(0).width;
					float tHeight = getDrawImageRect(0).height > rowH ? getDrawImageRect(0).height :rowH;
					
					if ((drawX + tWidth) > viewSize.width) {
						[heights addObject:[NSNumber numberWithInt:drawHeight]];
						drawX = 0 ;
						drawHeight = 0;
					}
					
					if (tHeight > drawHeight) {
						drawHeight = tHeight;
					}
					
					drawX += tWidth;
					continue;
				}
				
				NSRange rang;
				rang.location = i;
				rang.length = 1;
				NSString *chars = [pContent substringWithRange:rang];
				pen.string = chars;
				
				float tWidth = pen.contentSize.width;
				float tHeight = pen.contentSize.height > rowH ? pen.contentSize.height : rowH;
				
				if ((drawX + tWidth) > viewSize.width) {
					[heights addObject:[NSNumber numberWithInt:drawHeight]];
					drawX = 0 ;
					drawHeight = 0;
				}
				
				if (tHeight > drawHeight) {
					drawHeight = tHeight;
				}
				
				drawX += tWidth;
			}
		}
	}
	
	[heights addObject:[NSNumber numberWithInt:drawHeight]];
	
	return heights;
	
}

static int posxy[4][2]={{0,1},{1,0},{-1,0},{0,-1}};

//static CCRenderTexture* result = NULL ;

@implementation StringSprite

@synthesize fontName;
@synthesize contentStr;
@synthesize colorStr;

@synthesize fontSize;
@synthesize rowHeight;
@synthesize viewSize;
@synthesize isDouble;
@synthesize gapping;

@synthesize background;
@synthesize isWrapping;

+(StringSprite*)create:(NSString *)content
			  fontName:(NSString *)font
				 color:(NSString *)color
				  size:(CGSize)viewSize
			  fontSize:(int)fontSize
				   row:(int)rowH
			  wrapping:(BOOL)isDouble{
	
	StringSprite* sprite = [StringSprite node];
	
	sprite.isDouble = isDouble;
	sprite.viewSize = viewSize;
	sprite.rowHeight = rowH;
	sprite.fontSize = fontSize;
	sprite.colorStr = color;
	sprite.contentStr = content;
	sprite.fontName = font;
	
	[sprite parse];
	
	return sprite;
}

/*
 *删除CCRenderTexture
 */
+(void)cleanCCRenderTexture{
//	if (result) {
//		[result release];
//		result = nil;
//	}
}

-(void)setFontSize:(int)fontSize__{
	fontSize = cFixedScale(fontSize__);
}

-(void)setRowHeight:(int)rowHeight___{
	rowHeight = cFixedScale(rowHeight___);
}
-(void)setViewSize:(CGSize)viewSize__{
	viewSize = CGSizeMake(cFixedScale(viewSize__.width), viewSize__.height);
}

-(id)init{
	if ((self = [super init]) != nil) {
		gapping = 2 ;
		background = ccc4(255, 255, 255, 0);
		isWrapping = NO;
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	
	if (contentStr) {
		[contentStr release];
		contentStr = nil;
	}
	
	if (fontName) {
		[fontName release];
		fontName = nil;
	}
	
	if (colorStr) {
		[colorStr release];
		colorStr = nil;
	}
		
	[super onExit];
}

-(BOOL)checkDefault{
	if (fontName == nil) {
		self.fontName = getCommonFontName(FONT_1);
	}
	if (contentStr == nil) {
		return NO;
	}
	return YES;
}

-(void)parse{
	
	if (![self checkDefault]) {
		return ;
	}
	
//	if (result == nil) {
//		CGSize dSize = [CCDirector sharedDirector].winSize;
//		result = [CCRenderTexture renderTextureWithWidth:dSize.width height:512];
//		[result retain];
//	}
	
	CGSize defaultSize = CGSizeMake(viewSize.width, 512);//[CCDirector sharedDirector].winSize;
	CCRenderTexture* result = [CCRenderTexture renderTextureWithWidth:defaultSize.width height:defaultSize.height];
	CCLabelTTF *pen = [CCLabelTTF labelWithString:@"" fontName:self.fontName fontSize:fontSize];
	pen.verticalAlignment = kCCVerticalTextAlignmentCenter;
	pen.horizontalAlignment = kCCTextAlignmentLeft;
	pen.anchorPoint = ccp(0, 0);
	
	float rightX = 0;
	float paintX = 0;
	float paintY = defaultSize.height - self.gapping;
	
	NSMutableArray *emopos=[NSMutableArray array];
	NSMutableDictionary* eventDict = [NSMutableDictionary dictionary];

	
	[result clear:0 g:0 b:0 a:0];
	[result begin];
	
	NSDictionary* css = getParseSetting(0);
	NSArray* lines = [contentStr componentsSeparatedByString:[css objectForKey:@"tr"]];
	for (NSString *lineContent in lines) {
		if ([lineContent hasPrefix:[css objectForKey:@"bl"]]) {
			if (lineContent.length > 1) {
				NSString *strValue = [lineContent substringFromIndex:1];
				int iValue = [strValue intValue];
				//paintX = 0 ;
				paintY -= iValue;
				//gapping
				paintY -= self.gapping;
			}else{
				//paintX = 0 ;
				paintY -= rowHeight;
				//gapping
				paintY -= self.gapping;
			}
			continue ;
		}
		
		NSMutableArray* heights = [NSMutableArray arrayWithArray:checkDrawLines(lineContent, fontName, viewSize, fontSize, rowHeight)];
		NSArray* tds = [lineContent componentsSeparatedByString:[css objectForKey:@"td"]];
		int drawHeight = rowHeight;
		if (heights != nil && heights.count > 0) {
			NSNumber* number = [heights objectAtIndex:0];
			drawHeight = [number intValue];
			[heights removeObjectAtIndex:0];
		}
		
		paintX = 0 ;
		paintY -= drawHeight;
		
		for (NSString* td in tds) {
			NSArray* objs = [td componentsSeparatedByString:[css objectForKey:@"cell"]];
			NSString* pEvent = getPaintEventContent(objs);
			NSString* pContent = getPaintContent(objs);
			pen.fontName = getPaintFontName(objs, fontName);
			pen.fontSize = getPaintFontSize(objs, fontSize);
			pen.color = getPaintFontColor(objs, colorStr);
			
			float eventX = paintX ;
			float eventY = paintY ;
			
			float eventWidth = 0;
			float eventHeight = 0;
			
			NSMutableArray* eventRects = [NSMutableArray array];
			
			if (pContent != nil) {
				int length = pContent.length;
				for (int i = 0 ; i < length ; i++){
					NSString* iconStr = checkDrawImage(pContent, i);
					if (iconStr != nil) {
						i = i + iconStr.length - 1;
						int amiIndex = getDrawImageId(iconStr);
						float tWidth = getDrawImageRect(amiIndex).width;
						
						if ((paintX + tWidth) > viewSize.width) {
							rightX = viewSize.width;
//							rightX = paintX + tWidth/2;
//							rightX = rightX > viewSize.width ? viewSize.width :rightX;
							
							paintX = 0 ;
							if (pEvent != nil) {
								NSValue* value = [NSValue valueWithCGRect:CGRectMake(eventX, eventY, eventWidth, eventHeight)];
								[eventRects addObject:value];
							}
							
							
							if (heights != nil && heights.count > 0) {
								NSNumber* number = [heights objectAtIndex:0];
								drawHeight = [number intValue];
								[heights removeObjectAtIndex:0];
							}else{
								drawHeight = rowHeight ;
							}
							
							paintY -= drawHeight;
							//gapping
							paintY -= self.gapping;
							
							if (pEvent != nil) {
								eventX = paintX;
								eventY = paintY;
								eventWidth = 0;
								eventHeight = drawHeight;
							}
						}
						
						NSMutableDictionary *dict=[NSMutableDictionary dictionary];
						[dict setObject:[NSNumber numberWithFloat:(paintX + tWidth/2)] forKey:@"XX"];
						[dict setObject:[NSNumber numberWithFloat:(paintY)] forKey:@"YY"];
						[dict setObject:[NSNumber numberWithFloat:amiIndex] forKey:@"amiid"];
						[emopos addObject:dict];
						paintX += tWidth;
						
						if (paintX > rightX) {
							rightX = paintX;
						}
						
						if (pEvent != nil) {
							eventWidth += tWidth;
							eventHeight = drawHeight;
						}
						
						continue;
					}
					
					NSRange rang;
					rang.location = i;
					rang.length = 1;
					NSString *chars = [pContent substringWithRange:rang];
					pen.string = chars;
					
					float tWidth = pen.contentSize.width;
					
					if ((paintX + tWidth) > viewSize.width) {
						rightX = viewSize.width;
//						rightX = paintX + tWidth/2;
//						rightX = rightX > viewSize.width ? viewSize.width :rightX;
						
						paintX = 0 ;
						if (pEvent != nil) {
							NSValue* value = [NSValue valueWithCGRect:CGRectMake(eventX, eventY, eventWidth, eventHeight)];
							[eventRects addObject:value];
						}
						
						if (heights != nil && heights.count > 0) {
							NSNumber* number = [heights objectAtIndex:0];
							drawHeight = [number intValue];
							[heights removeObjectAtIndex:0];
						}else{
							drawHeight = rowHeight ;
						}
						paintY -= drawHeight;
						//gapping
						paintY -= self.gapping;
						
						if (pEvent != nil) {
							eventX = paintX;
							eventY = paintY;
							eventWidth = 0;
							eventHeight = drawHeight;
						}
					}
					
					pen.position = ccp(paintX, paintY + cFixedScale(2));
					paintX += tWidth;
					
					if (paintX > rightX) {
						rightX = paintX;
					}
					
					if (pEvent != nil) {
						eventWidth += tWidth;
						eventHeight = drawHeight;
					}
					if (self.isDouble) {
						ccColor3B tempColor = pen.color;
						CGPoint tempPos = pen.position;
						
						for (int i = 0; i < 4; i++) {
							pen.color = ccc3(0, 0, 0);
							pen.position = ccpAdd(tempPos, ccp(posxy[i][0], posxy[i][1]));
							[pen visit];
						}
						
						pen.color = tempColor;
						pen.position = tempPos;
						
					}
					[pen visit];
				}
			}
			
			if (pEvent != nil) {
				NSValue* value = [NSValue valueWithCGRect:CGRectMake(eventX, eventY, eventWidth, eventHeight)];
				[eventRects addObject:value];
			}
			
			if (pEvent != nil) {
				//颜色并上事件的字符串
				NSString* str = getHexStringWithColor3B(pen.color);
				NSString* key = [NSString stringWithFormat:@"%@:::%@",pEvent,str];
				[eventDict setObject:eventRects forKey:key];
			}
		}
	}
	[result end];
	
	//gapping
	float bottomY = paintY - self.gapping;
	CGRect rect = CGRectMake(0, bottomY, rightX + cFixedScale(2), defaultSize.height - bottomY);
	CCSprite *spr=[CCSprite spriteWithTexture:result.sprite.texture rect:rect];
	[spr setFlipY:YES];
	
	BrowLayer* browLayer = [BrowLayer create:spr.contentSize array:emopos clip:bottomY];
	if (browLayer != nil) {
		[spr addChild:browLayer];
	}
	
	EventLayer* layer = [EventLayer create:spr.contentSize clip:bottomY];
	if (layer != nil) {
		[layer addMemuItem:eventDict];
		[spr addChild:layer];
	}
	
	CCLayerColor* bg = [CCLayerColor layerWithColor:background];
	bg.contentSize = spr.contentSize;
	[spr addChild:bg z:-1];
	
	self.contentSize = spr.contentSize;
	[self Category_AddChildToCenter:spr];
}

@end
