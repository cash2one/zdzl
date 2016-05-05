//
//  UnionTitle.m
//  TXSFGame
//
//  Created by Max on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionTitle.h"


@implementation UnionTitle


@synthesize fontColor;
@synthesize fontSize;
@synthesize fontName;
-(id)initWithWidth:(float)width
{
    return [self initWithWidth:width title:@""];
}
-(id)initWithWidth:(float)width title:(NSString *)title
{
    if (self = [super init]) {
        self.contentSize = CGSizeMake(width, cFixedScale(29));
        
        CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/t33.png"];
        bg.position = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
        [self addChild:bg];
        
        bg.scaleX = width / bg.contentSize.width;
        
        self.fontSize = cFixedScale(16);
        self.fontColor = ccc3(64, 21, 12);
        self.fontName = getCommonFontName(FONT_1);
        
        if (![title isEqualToString:@""]) {
            CCLabelTTF *titleDefault = [CCLabelTTF labelWithString:title fontName:fontName fontSize:fontSize];
            titleDefault.color = fontColor;
//            titleDefault.scale=cFixedScale(1);
            titleDefault.position = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
            [self addChild:titleDefault];
        }
    }
    return self;
}

@end



