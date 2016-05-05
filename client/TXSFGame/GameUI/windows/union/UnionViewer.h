//
//  UnionViewer.h
//  TXSFGame
//
//  Created by Max on 13-3-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "UnionConfig.h"
#import "UnionPanel.h"



@interface UnionViewer : CCLayer {
    
}

+(void)show:(NSDictionary*)info;
+(void)hide;

@end
