//
//  SuccessView.h
//  TXSFGame
//
//  Created by Soul on 13-4-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

@class CCPanel;

typedef enum{
	SuccessComponentType_none,
	SuccessComponentType_success,
	SuccessComponentType_log,
}SuccessComponentType;

@interface CCLayer (SuccessLayout)
-(void)successLinearLayout:(float)_offset;
-(BOOL)checkComponent;
@end

@interface SuccessComponent : CCSprite{
	SuccessComponentType _type;
	int successId;
	int successType;
	NSString* _data;
	
}
+(SuccessComponent*)create:(NSString*)_data type:(SuccessComponentType)_t;
@end

@interface SuccessView : CCLayer {
	SuccessType _type;
}
@property(nonatomic,assign)SuccessType type;

+(SuccessView*)viewWithDimension:(float)_width height:(float)_height;

@end
