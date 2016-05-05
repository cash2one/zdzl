//
//  CCPanel.h
//  Jinni
//
//  Created by shoujun huang on 13-1-6.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#define PANEL_DEBUG FALSE

typedef enum
{
	kCCScrollLayerStateIdle,
	kCCScrollLayerStateSliding,
	
}Touch_state;

typedef enum{
	Swipe_none,
	Swipe_vertical,
	Swipe_horizon,
}Swipe_type;

typedef enum{
	AligningType_none ,
	AligningType_top ,
	AligningType_bottom ,
}AligningType;

@interface ClipLayer :  CCLayerColor{
	AligningType aligning;
	id _endTarget;	// 移动到底部回调
	SEL _endCall;
}
@property(nonatomic,assign)AligningType aligning;
@property(nonatomic,assign)id endTarget;
@property(nonatomic,assign)SEL endCall;
-(void)addContent:(CCNode*)_layer;
-(CGPoint)getContentPosition;
-(void)updateContentPosition:(CGPoint)_pt;
-(void)stopSwipe;
-(void)revisionSwipe;
-(void)swipeEnd:(CGPoint)_start end:(CGPoint)_end;
@end

@interface CCPanel : CCLayerColor {
	ClipLayer* content;
	UITouch *scrollTouch_;
	CGPoint touchSwipe_;
	CGPoint layerSwipe_;
	CGPoint powerSwipe_;
	CGFloat minimumTouchLengthToSlide_; 
	CGFloat minimumTouchLengthToChangePage_; 
	int state_;
	BOOL stealTouches_;
	Swipe_type swipeDir_;
	CCSprite *scrollbar;
	CCSprite *scrollHorzbar;
	int lasthight;
	bool isRunAct;
	BOOL _isTouchValid;
	BOOL _isLock;
	NSTimeInterval dropDelayTime;
	CGPoint beginTouch;
	bool isDropEDGE;
	id _endTarget;	// 移动到底部回调
	SEL _endCall;
}
@property(nonatomic,assign)BOOL isTouchValid;
@property(nonatomic,assign)BOOL isLock;
@property(nonatomic,assign)Swipe_type swipeDir;
@property(nonatomic,assign)CGPoint touchSwipe;
@property(nonatomic,assign)BOOL stealTouches;
@property(nonatomic,assign)BOOL inertia;
@property(nonatomic,assign)id endTarget;
@property(nonatomic,assign)SEL endCall;

+(CCPanel*)panelWithContent:(CCNode*)_content viewSize:(CGSize)_vSize;
+(CCPanel*)panelWithContent:(CCNode*)_content viewPosition:(CGPoint)_vPotion viewSize:(CGSize)_vSize;
+(void)makeNodeQueue:(CCNode*)n vertical:(bool)vert ascending:(bool)asc gep:(int)gep;
-(CCNode*)getContent;

-(void)cutOffTouch:(UITouch *)aTouch;

-(void)revisionSwipe;
-(void)updateContentToTop;
-(void)updateContentToTopAndSetAligning:(AligningType)_t;
-(void)updateContentToBottom;
-(void)updateContent;
-(void)updateContentToTop:(float)_height;
-(void)showScrollBar:(NSString*)path;
-(void)showHorzScrollBar:(NSString*)path;


@end
