//
//  CCListItem.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-26.
//  Copyright 2012 eGame. All rights reserved.
//

#import "CCListItem.h"


@implementation CCListItem
@synthesize isSelect = isSelected_;
-(id)init
{
	self= [super init];
	isEnabled_ = true;
	return self;
}
-(BOOL)isEnabled
{
	return isEnabled_;
}
-(CGRect)rect
{
	return CGRectMake( _position.x - _contentSize.width*_anchorPoint.x,
					  _position.y - _contentSize.height*_anchorPoint.y,
					  _contentSize.width, _contentSize.height);
}
@end
