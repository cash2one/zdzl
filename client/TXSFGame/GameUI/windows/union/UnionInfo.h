//
//  UnionInfo.h
//  TXSFGame
//
//  Created by peak on 13-4-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

// 同盟信息，公告
@interface UnionInfo : CCLayerColor
{
    int unionId;
    CCSprite *scrollLeft;
    CCSprite *scrollMiddle;
    CCSprite *scrollRight;
    
    //CCLabelTTF *noticeLabel;
    UITextView * postTextView;
}
-(id)initWithUnionId:(int)uid;
-(void)updateNotice:(NSString*)note;
@end