//
//  EventLayer.m
//  TXSFGame
//
//  Created by Soul on 13-5-23.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "EventLayer.h"
#import "GameConnection.h"
#import "Config.h"


@implementation EventLayer

@synthesize clipHeight;

+(EventLayer*)create:(CGSize)size clip:(int)_clip{
	EventLayer* content = [EventLayer node];
	content.contentSize = size ;
	content.clipHeight = _clip;
	return content;
}

-(id)init{
	if ((self=[super init]) != nil) {
		memu = [CCMenu menuWithItems:nil];
		memu.ignoreAnchorPointForPosition = NO;
		[self addChild:memu];
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	[super onExit];
}

-(void)addMemuItem:(NSDictionary*)content{
	if (content != nil) {
		NSArray* keys = [content allKeys];
		if (keys.count > 0) {
			for (NSString *key in keys) {
				NSArray* values = [content objectForKey:key];
				NSArray* ary = [key componentsSeparatedByString:@":::"];
				if (ary.count == 2) {
					NSString* colorStr = [ary objectAtIndex:1];
					ccColor3B c3b = color3BWithHexString(colorStr);
					NSString* eventStr = [ary objectAtIndex:0];
					for (NSValue *value in values) {
						
						CGRect rect = [value CGRectValue];
						CCLayerColor* temp = [CCLayerColor layerWithColor:ccc4(c3b.r, c3b.g, c3b.b, 255)
																	width:rect.size.width - 4 height:2];
						[self addChild:temp];
						temp.position = ccp(rect.origin.x + 2, rect.origin.y - clipHeight);
						
						CCMenuItem *memuItem = [CCMenuItem itemWithTarget:self
																 selector:@selector(menuCallbackBack:)];
						[memuItem setAnchorPoint:ccp(0,0)];
						[memuItem setContentSize:rect.size];
						[memuItem setPosition:ccp(rect.origin.x + 2, rect.origin.y - clipHeight)];
						[memu addChild:memuItem];
						memuItem.userObject = eventStr;
						
					}
				}
			}
		}
	}
}

-(void)menuCallbackBack:(id)sender{
	CCLOG(@"EventLayer");
	CCNode* _____node = (CCNode*)sender;
	NSString* content = _____node.userObject;
	if (content) {
		NSArray* array = [content componentsSeparatedByString:@"::"];
		if (array.count == 2) {
			NSString* head = [array objectAtIndex:0];
			NSString* arg = [array objectAtIndex:1];
			[GameConnection post:head object:arg];
		}else{
			//兼容旧数据
			//AAA000
			if ([content length] > 3) {
				NSString *NofName= [content substringToIndex:3];
				NSString *Nofcontent=[content substringFromIndex:3];
				if (NofName != nil && Nofcontent != nil) {
					[GameConnection post:NofName object:Nofcontent];
				}
			}
		}
	}
}

@end
