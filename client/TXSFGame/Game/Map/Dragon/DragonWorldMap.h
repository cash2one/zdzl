//
//  DragonWorldMap.h
//  TXSFGame
//
//  Created by peak on 13-9-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "WindowComponent.h"
//
@class DragonWorldMapNode;
//
@interface DragonWorldMap : WindowComponent{
    DragonWorldMapNode *nodeMap;
    CCNode *mapViewer;
    //
    NSTimeInterval mapTime;
    NSTimeInterval mapMaxTime;
    BOOL isChange;
}
//
+(void)showMapWithSender:(id)sender;
+(void)removeMap;
-(void)loadNodeMap;
-(DragonWorldMapNode*)getNodeWithID:(int)nodeID_;
-(NSArray*)getLeafNode;
-(int)getDeep;
-(NSArray*)getNodeWithDeep:(int)deep;
-(void)drawMap;
-(void)drawMapLine;
-(BOOL)isChange;
-(void)setIsChange:(BOOL)isChange_;
@end
