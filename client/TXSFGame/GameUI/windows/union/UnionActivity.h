//
//  UnionActivity.h
//  TXSFGame
//
//  Created by Max on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "UnionConfig.h"
#import "ScrollPanel.h"

@interface UnionActivityItem : CCSprite
-(id)initWithType:(Tag_Union_Activity_Type)type count:(int)count;
-(id)initWithType:(Tag_Union_Activity_Type)type activity:(NSString *)activity status:(Tag_Union_Activity_Status)status count:(int)count;
@end


// 活动
//@interface UnionActivity : CCLayerColor <ScrollPanelDelegate>
@interface UnionActivity : CCLayerColor{
    int unionId;	
    CCLayer *listLayer;
}
-(id)initWithUnionId:(int)uid;
@end

