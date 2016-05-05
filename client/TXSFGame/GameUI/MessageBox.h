//
//  MessageBox.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-28.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

/*
 * 用于解析字符串，并绘制在面板上
 */
@interface MessageBox : CCLayerColor {
	CGPoint	offset_;
	int		lineH;
	ccColor4B	bcolor_;
	float adjust_width;//宽度计算误差
	float adjust_height;
}
+(MessageBox*)create:(CGPoint)_offset color:(ccColor4B)_cl  background:(ccColor4B)_bl;
+(MessageBox*)create:(CGPoint)_offset color:(ccColor4B)_cl;
+(CCNode*)create:(NSString*)str target:(id)tar sel:(SEL)call;


@property(nonatomic,assign)ccColor4B boundColor;
@property(nonatomic,assign)BOOL isDown;
@property(nonatomic,assign)CGPoint offset;
@property(nonatomic,assign)float AdjustWidth;
@property(nonatomic,assign)float AdjustHeight;
-(void)message:(NSString *)_msg;
-(void)messageWithArray:(NSArray*)_list;
-(void)messageWithArgs:(NSString *)_msg , ...;


@end
