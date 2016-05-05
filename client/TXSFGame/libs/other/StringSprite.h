//
//  StringSprite.h
//  TXSFGame
//
//  Created by Soul on 13-5-24.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface StringSprite : CCSprite {
	int			rowHeight;
	BOOL		isDouble;
	int			fontSize;
	int			gapping;
	CGSize		viewSize;
	NSString*	colorStr;
	NSString*   fontName;
	NSString*	contentStr;
	
	ccColor4B	background;
	BOOL		isWrapping;
}

@property(nonatomic,assign)int gapping;
@property(nonatomic,assign)int rowHeight;
@property(nonatomic,assign)BOOL isDouble;
@property(nonatomic,assign)BOOL isWrapping;
@property(nonatomic,assign)int fontSize;
@property(nonatomic,assign)CGSize viewSize;
@property(nonatomic,assign)ccColor4B background;

@property(nonatomic,retain)NSString* colorStr;
@property(nonatomic,retain)NSString* fontName;
@property(nonatomic,retain)NSString* contentStr;

+(StringSprite*)create:(NSString*)content
			  fontName:(NSString*)font
				 color:(NSString*)color
				  size:(CGSize)viewSize
			  fontSize:(int)fontSize
				   row:(int)rowH
			  wrapping:(BOOL)isDouble;


@end
