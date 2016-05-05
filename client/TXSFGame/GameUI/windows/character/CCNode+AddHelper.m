//
//  CCNode+AddHelper.m
//  TXSFGame
//
//  Created by Soul on 13-3-4.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "CCNode+AddHelper.h"

@implementation CCNode (AddHelper)

-(void)Category_AddChildToCenter:(CCNode *)_obj{
	if (_obj != nil) {
		[self addChild:_obj];
		_obj.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
	}
}

-(void)Category_AddChildToCenter:(CCNode *)_obj z:(int)_z{
	if (_obj != nil) {
		[self addChild:_obj z:_z];
		_obj.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
	}
}

-(void)Category_AddChildToCenter:(CCNode *)_obj z:(int)_z tag:(int)__tag{
	if (_obj != nil) {
		[self addChild:_obj z:_z tag:__tag];
		_obj.position=ccp(self.contentSize.width/2, self.contentSize.height/2);
	}
}

@end
