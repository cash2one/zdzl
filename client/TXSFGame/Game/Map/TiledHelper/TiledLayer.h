//
//  TiledLayer.h
//  TXSFGame
//
//  Created by TigerLeung on 13-1-6.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface TiledLayer : CCTMXLayer{
	NSString * sourceImage;
	CGRect contentRect;
	BOOL isLoadTexture;
	BOOL isPost;
}

+(void)checkMapPoint:(CGPoint)point;
-(void)checkContent:(CGPoint)point;

@end
