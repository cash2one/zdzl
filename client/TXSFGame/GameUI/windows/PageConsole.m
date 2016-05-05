//
//  PageConsole.m
//  TXSFGame
//
//  Created by Max on 12-12-30.
//  Copyright 2012年 eGame. All rights reserved.
//

#import "PageConsole.h"

@implementation PageConsole


@synthesize currenPage;

-(id)initPageCount:(int)pagecount{
	if((self=[super init])!=nil){
		pageCount=pagecount;
		currenPage=0;
	}
	return self;
}


-(void)onEnter{
	[super onEnter];
	
	sf1=[CCSpriteFrame frameWithTextureFilename:@"images/ui/button/timebox/dot.png" rect:CGRectMake(0, 0, 10, 8.9f)];
	sf2=[CCSpriteFrame frameWithTextureFilename:@"images/ui/button/timebox/dot_select.png" rect:CGRectMake(0, 0, 14, 14)];
	[self setContentSize:CGSizeMake((pageCount-1)*30, 14)];
	self.ignoreAnchorPointForPosition=NO;
	[self setAnchorPoint:ccp(0.5,0.5)];
	
	float parentx=self.parent.contentSize.width/2;
	[self setPosition:(ccp(parentx,0))];
	CCLOG(@"parent %f",self.parent.contentSize.width);
	for(int i=0;i<pageCount;i++){
		CCSprite *dot=[CCSprite spriteWithSpriteFrame:sf1];
		dot.tag=i;
		[dot setPosition:ccp(i*30,10)];
		[self addChild:dot];
	}
	[self changPage:currenPage];
}

-(void)changPage:(int)pagenum{
	sf1=[CCSpriteFrame frameWithTextureFilename:@"images/ui/button/timebox/dot.png" rect:CGRectMake(0, 0, 10, 8.9f)];
	sf2=[CCSpriteFrame frameWithTextureFilename:@"images/ui/button/timebox/dot_select.png" rect:CGRectMake(0, 0, 14, 14)];
	for(int i=0;i<pageCount;i++){
		CCSprite *sprite=(CCSprite*)[self getChildByTag:i];
		CCLOG(@"%@,%@",sf2,sf1);
		i==pagenum?[sprite setDisplayFrame:sf2]:[sprite setDisplayFrame:sf1];
	}
}

@end
