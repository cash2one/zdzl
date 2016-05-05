//
//  TipsBox.m
//  TXSFGame
//
//  Created by efun on 12-12-3.
//  Copyright (c) 2012年 chao chen. All rights reserved.
//

#import "TipsBox.h"

#define TIPS_BOX_WITDH	400

@implementation TipsBox

@synthesize tipsLabel;

//-(void)draw
//{
//    [super draw];
//    glLineWidth(1.0f);
//    ccDrawColor4B(150, 100, 20, 255);
//    ccDrawRect(ccp(0, 0), ccp(self.contentSize.width, self.contentSize.height));
//}

+(void)create{
    //[[[super alloc] initWithString:@"材料不足" width:0 height:0] autorelease];
    [[[super alloc] initWithString:NSLocalizedString(@"tips_box_no_material",nil) width:0 height:0] autorelease];
}

+(void)createWithString:(NSString *)string
{
    [[[super alloc] initWithString:string width:0 height:0] autorelease];
}

+(void)createWithString:(NSString *)string width:(float)width height:(float)height
{
    [[[super alloc] initWithString:string width:width height:height] autorelease];
}

+(void)showMessage:(NSString *)message
{
	CGSize winSize = [CCDirector sharedDirector].winSize;
	[self showMessage:message position:ccp(winSize.width/2, winSize.height/2)];
}

+(void)showMessage:(NSString *)message position:(CGPoint)pos
{
	[[[super alloc] initWithMessage:message position:pos] autorelease];
}

-(id)initWithMessage:(NSString *)message position:(CGPoint)pos
{
	if (self = [super init]) {
		if (!message) {
			message = @"";
		}
		CCSprite *sprite = drawString(message, CGSizeMake(TIPS_BOX_WITDH, 0), getCommonFontName(FONT_1), 16, 20, getHexColorByQuality(IQ_WHITE));
		
		self.contentSize = sprite.contentSize;
		sprite.anchorPoint = CGPointZero;
		[self addChild:sprite];
		
		float duration = 1.5;
        id actionMove = [CCMoveBy actionWithDuration:duration position:ccp(0, 130)];
		id actionMoveEaseOut = [CCEaseOut actionWithAction:actionMove rate:2];
		[self runAction:[CCSequence actions:
						 actionMoveEaseOut,
						 [CCCallFunc actionWithTarget:self selector:@selector(actionDone)],
						 nil]];
		
        self.position = ccp(pos.x-self.contentSize.width/2,
							pos.y-self.contentSize.height/2);
		
		[[Window shared] addChild:self z:INT32_MAX-1];
	}
	return self;
}

-(id)initWithString:(NSString *)string width:(float)width height:(float)height
{
    if (self = [super init]) {

		tipsLabel = [CCLabelTTF labelWithString:string fontName:getCommonFontName(FONT_1) fontSize:16.0];
		if (width == 0 && height == 0) {
			float maxWidth = 300;
			float lineHeight = tipsLabel.contentSize.height;
			float paddingX = 25;
			float paddingY = 25;
			float tipsWidth = tipsLabel.contentSize.width;
			if (tipsWidth >= maxWidth) {
				width = maxWidth + paddingX * 2;
				int lineCount = tipsWidth / maxWidth + 1;
				height = lineHeight * lineCount + paddingY * 2;
				tipsLabel = nil;
				tipsLabel = [CCLabelTTF labelWithString:string fontName:getCommonFontName(FONT_1) fontSize:16.0 dimensions:CGSizeMake(maxWidth, lineHeight * lineCount) hAlignment:kCCTextAlignmentLeft];
				tipsLabel.anchorPoint = ccp(0, 0);
				tipsLabel.position = ccp(paddingX, paddingY);
			} else {
				width = tipsLabel.contentSize.width + paddingX * 2;
				height = lineHeight + paddingY * 2;
				tipsLabel.position = ccp(width / 2, height / 2);
			}
		} else {
			tipsLabel.position = ccp(width / 2, height / 2);
		}
		

		self.contentSize = CGSizeMake(width, height);

        tipsLabel.color = ccc3(237, 226, 207);
        [self addChild:tipsLabel];
        
        float duration = 1.2;
//		float fadeDuration = 0.3;
        id actionMove = [CCMoveBy actionWithDuration:duration position:ccp(0, 150)];
		id actionMoveEaseOut = [CCEaseOut actionWithAction:actionMove rate:2];
//		id actionFade = [CCFadeTo actionWithDuration:fadeDuration opacity:0];
//      id actionSpawn = [CCSpawn actions:actionMoveEaseOut, actionFade, nil];
		
		[self runAction:[CCSequence actions:actionMoveEaseOut, [CCCallFunc actionWithTarget:self selector:@selector(actionDone)], nil]];
		
        CGSize winSize = [CCDirector sharedDirector].winSize;
        self.position = ccp(winSize.width / 2 - self.contentSize.width / 2,
                            winSize.height / 2 - self.contentSize.height / 2);
		[[Window shared] addChild:self z:INT32_MAX-1];
    }
    return self;
}

-(void)actionDone
{
    [self removeFromParentAndCleanup:YES];
    self = nil;
}

@end
