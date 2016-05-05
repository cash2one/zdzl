//
//  RoleUp.h
//  TXSFGame
//
//  Created by peak on 13-7-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "WindowComponent.h"

@interface RoleUp : WindowComponent {
    int symbolCount;
    int symbolCost;
    
    int roleUpCount;
    //
    int roleUpQuality;
    int roleUpLevel;
    int roleUpStep;
    int roleUpStartQuality;
    
    NSString *nameString;
    //
    int roleRID;
    int symbolID;

    //
    int selectQuality;
    CGPoint startMovePos;
    //
    BOOL isSend;
    BOOL isMoveContent;
}
@property (assign,nonatomic) int roleRID;
@property (assign,nonatomic) int symbolID;
@property (assign,nonatomic) BOOL isSend;
@property (assign,nonatomic) BOOL isMoveContent;
@property (assign,nonatomic) int roleUpCount;
@property (assign,nonatomic) int symbolCount;
@property (assign,nonatomic) int symbolCost;
@property (assign,nonatomic) int roleUpQuality;
@property (retain,nonatomic) NSString* nameString;
+(void)setRoleUpStaticRid:(int)rid;
+(void)buttonBack;
+(void)didRoleUpButton:(NSDictionary*)sender :(NSDictionary*)arg;
+(void)loadStepDisplayWithRid:(int)rid_ quality:(int)quality_ roleUpLevel:(int)upLevel_ step:(int)step_;
@end
