//
//  UnionTitle.h
//  TXSFGame
//
//  Created by Max on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

// 标题
@interface UnionTitle : CCSprite
{
    ccColor3B fontColor;
    float fontSize;
}
@property (nonatomic) ccColor3B fontColor;

@property (nonatomic) float fontSize;
@property (nonatomic, retain) NSString *fontName;

-(id)initWithWidth:(float)width;
-(id)initWithWidth:(float)width title:(NSString *)title;
@end