//
//  CFDialog.h
//  TXSFGame
//
//  Created by shoujun huang on 12-12-1.
//  Copyright 2012年 chao chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class CFDialog;

@protocol CCDialogDelegate <NSObject>
@optional
-(void)onDialogEnter:(CFDialog*)_dialog;
@end

@interface CFDialog : CCLayerColor
{
	id _target;
    SEL _confirmSelector;
    SEL _cancelSelector;
	NSDictionary *args;
	CCMenu *menu;
	NSObject<CCDialogDelegate> *delegate_;
}
@property(nonatomic) BOOL isCenterPoint;	// 屏幕中间
@property(readwrite, assign)NSObject <CCDialogDelegate> *delegate;
@property(nonatomic)CGRect contentRect;                   // 内容区域
@property(nonatomic, assign)CCLabelTTF *contentLabel;     // 默认内容label
@property(nonatomic,retain)NSDictionary *args;
@property(nonatomic,assign)CCMenu* menu;

+(CFDialog*)create:(id)target background:(int)_type;
+(CFDialog*)create:(id)target confirmSelector:(SEL)confirmSelector cancelSelector:(SEL)cancelSelector arg:(NSDictionary*)_dict;

-(id)initWithTarget:(id)target confirmSelector:(SEL)confirmSelector;
-(id)initWithTarget:(id)target confirmSelector:(SEL)confirmSelector cancelSelector:(SEL)cancelSelector;

@end