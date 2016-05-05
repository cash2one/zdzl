//
//  SectionManager.h
//  TXSFGame
//
//  Created by Soul on 13-7-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface Section : CCSprite<CCTouchOneByOneDelegate>{
	int						radius;
	int						radius_half;
	CGPoint					center;
    int     roleUpLevel;
    id selfManager;
    //
    BOOL isMove;
    //
    CGPoint startMovePos;
    //
}
@property(nonatomic,assign)id selfManager;
@property(nonatomic,assign)int roleUpLevel;
//@property(nonatomic,assign)int space;
+(Section*)create:(CGSize)_size;

-(void)showSction:(NSDictionary*)dict;
-(void)showFrameTo:(int)frame;
@end

@interface SectionQueue : CCNode
-(void)insert:(Section *)section index:(int)index;
@end

@interface SectionQueueRect : CCLayer

@end

@interface SectionManager : CCSprite{
	int _roleId;
    int _roleUpStartQuality;
    int _roleUpQuality;
    int _roleupSelectQuality;
    int _roleUpLevel;
    int _roleUpStep;
    //
    BOOL isUpdateState;
    //
    CGPoint oldPoint;
    //
    SectionQueue *content;
	SectionQueueRect *contentRect;
    //
    Section *leftSection;
    Section *middlelSection;
    Section *rightSection;
    //
    NSDictionary *dictInfo;
    //
    BOOL isShowFrameEffect;
}
@property (retain,nonatomic) NSDictionary* dictInfo;
@property (assign,nonatomic) BOOL isShowFrameEffect;
//
-(void)setUpdateState:(BOOL)isUpdate;
-(void)contentMoveOff:(CGPoint)pos;
-(void)setRoleId:(int)_value;
-(void)setSelectQuality:(int)_value;
//
-(void)setPage:(int)index;
-(void)checkPoint;
//
-(int)roleId;
-(int)pageIndex;
-(int)selectQuality;
-(int)roleQuality;
-(int)roleLevel;
-(int)roleStep;
-(void)checkButtonState;
//
-(void)showEffect;
@end

