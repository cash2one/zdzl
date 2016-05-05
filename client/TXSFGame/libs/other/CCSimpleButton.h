//
//  CCSimpleButton.h
//  TXSFGame
//
//  Created by TigerLeung on 13-1-6.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface CCSimpleButton : CCSprite<CCTouchOneByOneDelegate>{
	id target;
	SEL call;
	BOOL isEnabled_;
	CCSprite* normal;
	CCSprite* select;
	CCSprite* invalid;
	float touchScale;
	int	priority;
	BOOL bTouchDelay;
	float delayTime;
	void (^_block)(void);
}
@property(nonatomic,assign) float delayTime;
@property(nonatomic,assign) int priority;
@property(nonatomic,assign) BOOL isEnabled;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL call;
@property(nonatomic,assign) float touchScale;
@property(nonatomic,assign) bool swallows;
@property(nonatomic,assign) bool selected;

-(void)setNormalSprite:(CCSprite*)_sprite;
-(void)setSelectSprite:(CCSprite*)_sprite;
-(void)setInvalidSprite:(CCSprite*)_sprite;

+(CCSimpleButton*)spriteWithSize:(CGSize)_rect block:(void(^)(void))_block ;
+(CCSimpleButton*)spriteWithFile:(NSString*)_normal;
+(CCSimpleButton*)spriteWithFile:(NSString*)_normal select:(NSString*)_select;
+(CCSimpleButton*)spriteWithFile:(NSString*)_normal select:(NSString*)_select target:(id)_target call:(SEL)_call;
+(CCSimpleButton*)spriteWithFile:(NSString*)_normal select:(NSString*)_select invalid:(NSString*)_invalid target:(id)_target call:(SEL)_call;
+(CCSimpleButton*)spriteWithSpriteFrameName:(NSString*)_normal;
+(CCSimpleButton*)spriteWithFile:(NSString*)_normal select:(NSString*)_select target:(id)_target call:(SEL)_call priority:(int)_priority;
+(CCSimpleButton*)spriteWithNode:(CCNode*)_normal;


-(void)showSuggest;

-(void)setSelected:(bool)b;
-(void)setInvalid:(bool)b;

-(void)showCount:(int)count;

@end
