//
//  BrowLayer.m
//  TXSFGame
//
//  Created by Soul on 13-5-23.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "BrowLayer.h"
#import "Config.h"


@implementation BrowLayer

@synthesize clipHeight;
@synthesize brows;

+(BrowLayer*)create:(CGSize)size array:(NSArray *)array clip:(int)_clip{
	BrowLayer* content = [BrowLayer node];
	content.contentSize = size ;
	content.clipHeight = _clip;
	content.brows = array;
	return content;
}

-(void)onEnter{
	[super onEnter];
	NSString *imgpath=[NSString stringWithFormat:@"%@texture.plist",@"images/ui/chat/"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:imgpath];
	
	if (brows) {
		for(NSDictionary *dict in brows){
			int X=[[dict objectForKey:@"XX"]integerValue];
			int Y=[[dict objectForKey:@"YY"]integerValue] - clipHeight;
			int amiId=[[dict objectForKey:@"amiid"]integerValue];
			CCSprite *emo=[CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"face%i_1.png",amiId]];
			NSMutableArray *amiarry=[NSMutableArray array];
			for(int d=0;d<INT16_MAX;d++){
				CCSpriteFrame *f1=[[CCSpriteFrameCache sharedSpriteFrameCache]spriteFrameByName:[NSString stringWithFormat:@"face%i_%i.png",amiId,d+1]];
				if(!f1){
					break;
				}else{
					[amiarry addObject:f1];
				}
			}
			CCAnimation *c1=[CCAnimation animationWithSpriteFrames:amiarry delay:0.1];
			CCAnimate* animate = [CCAnimate actionWithAnimation:c1];
			CCSequence *seq = [CCSequence actions:animate,nil];
			CCRepeatForever* repeat = [CCRepeatForever actionWithAction:seq];
			[emo runAction:repeat];
			[emo setPosition:ccp(X, Y + cFixedScale(5))];
			emo.anchorPoint = ccp(0.5, 0);
			[self addChild:emo];
		}
	}
	
	
}

-(void)onExit{
	NSString *imgpath=[NSString stringWithFormat:@"%@texture.plist",@"images/ui/chat/"];
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeSpriteFramesFromFile:imgpath];
	if (brows) {
		[brows release];
		brows = nil;
	}
	[super onExit];
}

@end
