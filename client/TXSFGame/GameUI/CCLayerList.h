//
//  CCLayerList.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-20.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCListItem.h"

typedef enum {
	LAYOUT_X,
	LAYOUT_Y,
	LAYOUT_G,
}LAYOUT_TYPE;

@class CCLayerList;

@protocol CCListDelegate <NSObject>
@optional
-(void) selectedEvent:(CCLayerList*)_list :(CCListItem*)_listItem;
-(void) callbackTouch:(CCLayerList*)_list :(CCListItem*) _listItem : (UITouch *)touch ;
@end

@interface CCLayerList : CCLayerColor {
	float						paddingX;
	float						paddingY;
	CGPoint						startPos;
	LAYOUT_TYPE					layout;
	unsigned int				nRow;
	unsigned int				nCol;
	BOOL						isDownward_;
	BOOL						isRight2Left_;
	BOOL						isForce_;
	NSObject<CCListDelegate> *delegate_;
}
@property (readwrite, assign) NSObject <CCListDelegate> *delegate;
@property(nonatomic,assign)float paddingX;
@property(nonatomic,assign)float paddingY;
@property(nonatomic,assign)CGPoint startPos;
@property(nonatomic,assign)LAYOUT_TYPE layout;
@property(nonatomic,assign)unsigned int row;
@property(nonatomic,assign)unsigned int col;
@property(nonatomic,assign)BOOL  isDownward;
@property(nonatomic,assign)BOOL  isRight2Left;
@property(nonatomic,assign)BOOL  isForce;

+(CCLayerList*)listWith:(LAYOUT_TYPE)_layout :(CGPoint)_offset :(float)_px :(float)_py;
+(CCLayerList*)meshlist:(int)_row :(int)_col :(CGPoint)_offset :(float)_px :(float)_py;

-(CCLayerList*)create:(LAYOUT_TYPE)_layout :(CGPoint)_offset :(float)_px :(float)_py;
-(void) setSelected:(CCListItem*)_item;
-(void) _Vlayout;
-(void) _Hlayout;
-(void) _Glayout;
-(void) _layout;
//fix chao
-(CCListItem *) itemForTouch: (UITouch *) touch;
//end
@end
