//
//  ClickAnimation.h
//  TXSFGame
//
//  Created by chao chen on 13-1-11.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "AnimationViewer.h"

@interface ClickAnimation : AnimationViewer {
    BOOL looped;
}
@property (assign,nonatomic) BOOL looped;
+(id)show:(CGPoint)_point;

+(id)showSpriteInLayer:(CCNode*)content z:(NSInteger)z call:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint sprite:(CCSprite*)spr loop:(BOOL)isLoop;
+(id)showSpriteInLayer:(CCNode*)content z:(NSInteger)z tag:(NSInteger)tag call:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint sprite:(CCSprite*)spr loop:(BOOL)isLoop;

+(id)showSpriteInLayer:(CCNode*)content z:(NSInteger)z call:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint path:(NSString*)path loop:(BOOL)isLoop;
+(id)showSpriteInLayer:(CCNode*)content z:(NSInteger)z tag:(NSInteger)tag call:(id)call point:(CGPoint)_point moveTo:(CGPoint)_toPoint path:(NSString*)path loop:(BOOL)isLoop;

+(id)showInLayer:(CCNode*)content z:(NSInteger)z tag:(NSInteger)tag call:(id)call point:(CGPoint)_point scaleX:(float)scale_x  scaleY:(float)scale_y path:(NSString*)path loop:(BOOL)isLoop;

+(id)showInLayer:(CCNode*)content z:(NSInteger)z tag:(NSInteger)tag call:(id)call point:(CGPoint)_point path:(NSString*)path loop:(BOOL)isLoop;
+(id)showInLayer:(CCNode*)content tag:(NSInteger)tag call:(id)call point:(CGPoint)_point path:(NSString*)path loop:(BOOL)isLoop;
+(id)showInLayer:(CCNode*)content point:(CGPoint)_point path:(NSString*)path loop:(BOOL)isLoop;
@end
