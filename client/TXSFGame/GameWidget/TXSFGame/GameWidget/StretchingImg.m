//
//  stretchingImg.m
//  TXSFGame
//
//  Created by Max on 13-1-4.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "StretchingImg.h"


@implementation stretchingImg




//传入图片路径 要扩大宽度，高度,x=从x轴开始阔大一个像素，y=从y轴开始阔大一个像素
+(CCSprite*)initStretchingImg:(NSString*)path width:(int)w height:(int)h capx:(int)x capy:(int)y{
	CCSprite *sprite=[CCSprite node];
	NSAssert(w>0,@"w 不能为0");
	NSAssert(h>0,@"h 不能为0");
	
	CCSprite *src=[CCSprite spriteWithFile:path];
	CCRenderTexture *cr=[CCRenderTexture renderTextureWithWidth:w height:h];
	int leftpartw=src.contentSize.width-x-2;
	int rigthpartw=src.contentSize.width-x-1;
	int uppartw=src.contentSize.height-y-2;
	int downpartw=src.contentSize.height-y-1;
	if(w>src.contentSize.width){
		CCSpriteFrame *sf_partleft=[CCSpriteFrame frameWithTextureFilename:path rect:CGRectMake(0, 0, x, src.contentSize.height)];
		CCSpriteFrame *streX_sf=[CCSpriteFrame frameWithTextureFilename:path rect:CGRectMake(x, 0, 1, src.contentSize.height)];
		CCSpriteFrame *sf_partrigth=[CCSpriteFrame frameWithTextureFilename:path rect:CGRectMake(x+1, 0,rigthpartw, src.contentSize.height)];
		
		
		CCSprite   *sp_partleft=[CCSprite spriteWithSpriteFrame:sf_partleft];
		CCSprite   *sp_partstre=[CCSprite spriteWithSpriteFrame:streX_sf];
		CCSprite   *sp_partrigth=[CCSprite spriteWithSpriteFrame:sf_partrigth];
		
		
		[sp_partleft setAnchorPoint:ccp(0, 0)];
		[sp_partstre setAnchorPoint:ccp(0, 0)];
		[sp_partrigth setAnchorPoint:ccp(0, 0)];
		
		
		[sp_partstre setScaleX:w-rigthpartw-leftpartw];
		[sp_partstre setPosition:ccp(leftpartw, 0)];
		[sp_partrigth setPosition:ccp(leftpartw+(w-rigthpartw-leftpartw), 0)];
		
		[sprite addChild:sp_partleft];
		[sprite addChild:sp_partstre];
		[sprite addChild:sp_partrigth];
		cr=[CCRenderTexture renderTextureWithWidth:w height:src.contentSize.height];
		[cr begin];
		[sprite visit];
		[cr end];
	}
	if(h>src.contentSize.height){
		sprite=[CCSprite node];
		CCSpriteFrame *sf_parttop;
		CCSpriteFrame *streY_sf;
		CCSpriteFrame *sf_partbottom;
		
		if(w>src.contentSize.width){
			sf_parttop=[CCSpriteFrame frameWithTexture:cr.sprite.texture rect:CGRectMake(0, 0, w, y)];
			streY_sf=[CCSpriteFrame frameWithTexture:cr.sprite.texture rect:CGRectMake(0, y, w, 1)];
			sf_partbottom=[CCSpriteFrame frameWithTexture:cr.sprite.texture rect:CGRectMake(0,uppartw+1 , w, downpartw)];
		}else{
			sf_parttop=[CCSpriteFrame frameWithTextureFilename:path rect:CGRectMake(0, 0, src.contentSize.width,y)];
			streY_sf=[CCSpriteFrame frameWithTextureFilename:path rect:CGRectMake(0, y, src.contentSize.width, 1)];
			sf_partbottom=[CCSpriteFrame frameWithTextureFilename:path rect:CGRectMake(0, y+1, src.contentSize.width, downpartw)];
			w=src.contentSize.width;
		}
		CCSprite *sp_parttop=[CCSprite spriteWithSpriteFrame:sf_parttop];
		CCSprite *sp_partstre=[CCSprite spriteWithSpriteFrame:streY_sf];
		CCSprite *sp_partbottom=[CCSprite spriteWithSpriteFrame:sf_partbottom];
		[sp_parttop setAnchorPoint:ccp(0, 0)];
		[sp_partstre setAnchorPoint:ccp(0, 0)];
		[sp_partbottom setAnchorPoint:ccp(0, 0)];
		
		[sp_partstre setScaleY:h-uppartw-downpartw];
		[sp_partstre setPosition:ccp(0, uppartw)];
		[sp_parttop setPosition:ccp(0,y+(h-uppartw-downpartw))];
		
		[sprite addChild:sp_parttop];
		[sprite addChild:sp_partstre];
		[sprite addChild:sp_partbottom];
		
		cr=[CCRenderTexture renderTextureWithWidth:w height:h];
		[cr begin];
		[sprite visit];
		[cr end];
	}
	sprite=[CCSprite spriteWithTexture:cr.sprite.texture];
	return sprite;
}

@end
