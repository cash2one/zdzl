//
//  DragonRank.h
//  TXSFGame
//
//  Created by peak on 13-9-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "WindowComponent.h"
//typedef enum{
//    RIT_union = 1,
//    RIT_world,
//}RankItemType;

#pragma mark -
#pragma mark union rank
@interface DragonUnionRank : WindowComponent {
    int rankValue;
    int currentPageCount;
    NSMutableArray *mutItemArray;
}
@property(nonatomic,assign) int rankValue;
@end

#pragma mark -
#pragma mark world rank
@interface DragonWorldRank : WindowComponent {
    int rankValue;
    int currentPageCount;
    NSMutableArray *mutItemArray;
}
@property(nonatomic,assign) int rankValue;
@end
