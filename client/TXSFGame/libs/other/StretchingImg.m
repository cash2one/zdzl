//
//  StretchingImg.m
//  TXSFGame
//
//  Created by Max on 13-1-4.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "StretchingImg.h"


@implementation StretchingImg




//传入图片路径 要扩大宽度，高度,x=从x轴开始阔大一个像素，y=从y轴开始阔大一个像素
+(CCSprite*)stretchingImg:(NSString*)path width:(int)w height:(int)h capx:(int)x capy:(int)y{
	
	//CCSprite *sprite=[CCSprite node];
	//NSAssert(w>0,@"w 不能为0");
	//NSAssert(h>0,@"h 不能为0");
	
	if(w<32) w=32;
	if(h<32) h=32;
	if(w>1024) w=1024;
	if(h>1024) h=1024;
	
	CCSprite *src=[CCSprite spriteWithFile:path];
	CCRenderTexture *cr=[CCRenderTexture renderTextureWithWidth:w height:h];
	float leftpartw=x;
	float rigthpartw=src.contentSize.width-x-1;
	float uppartw=y;
	float downpartw=src.contentSize.height-y-1;
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
		
		cr=[CCRenderTexture renderTextureWithWidth:w height:src.contentSize.height];
		[cr begin];
        [sp_partleft visit];
        [sp_partstre visit];
        [sp_partrigth visit];
		[cr end];
	}
	if(h>src.contentSize.height){
		
		//sprite=[CCSprite node];
		CCSpriteFrame *sf_parttop = nil;
		CCSpriteFrame *streY_sf = nil;
		CCSpriteFrame *sf_partbottom = nil;
		
		if(w>src.contentSize.width){
			sf_parttop=[CCSpriteFrame frameWithTexture:cr.sprite.texture rect:CGRectMake(0, src.contentSize.height-y, w, y)];
			streY_sf=[CCSpriteFrame frameWithTexture:cr.sprite.texture rect:CGRectMake(0, y, w, 1)];
			sf_partbottom=[CCSpriteFrame frameWithTexture:cr.sprite.texture rect:CGRectMake(0,0 , w, downpartw)];
		}else{
			sf_parttop=[CCSpriteFrame frameWithTextureFilename:path rect:CGRectMake(0,src.contentSize.height-y, src.contentSize.width,y)];
			streY_sf=[CCSpriteFrame frameWithTextureFilename:path rect:CGRectMake(0, y, src.contentSize.width, 1)];
			sf_partbottom=[CCSpriteFrame frameWithTextureFilename:path rect:CGRectMake(0, 0, src.contentSize.width, downpartw)];
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
		[sp_parttop setPosition:ccp(0,0)];
		[sp_partbottom setPosition:ccp(0, y+(h-uppartw-downpartw))];
		cr=[CCRenderTexture renderTextureWithWidth:w height:h];
		[cr begin];
        [sp_parttop visit];
        [sp_partstre visit];
        [sp_partbottom visit];
		[cr end];
	}
	CCSprite * sprite = [CCSprite spriteWithTexture:cr.sprite.texture];
	return sprite;
}

@end
