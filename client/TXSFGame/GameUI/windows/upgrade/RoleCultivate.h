//
//  RoleCultivate.h
//  TXSFGame
//
//  Created by peak on 13-7-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "WindowComponent.h"

//@interface RoleCultivate : WindowComponent {
@interface RoleCultivate : CCLayer {
    int roleCultivateType;
    int roleQuality;
    int roleCultivateLevel;
    int roleCultivateStep;
    int roleID;
    //
    int yinbiValue;
    int yuanbaoValue;
    BOOL isSave;
    //
    BOOL isSend;
    //
    int labelLength;
}
@property (readonly,nonatomic) int labelLength;
@property (assign,nonatomic) BOOL isSave;
@property (assign,nonatomic) BOOL isSend;

@property (assign,nonatomic) int roleID;

-(void)checkButtonState;
-(void)labelSaveData;
+(void)didRoleCultivate:(NSDictionary*)sender;
+(void)didRoleCultivateSave:(NSDictionary*)sender :(NSDictionary*)arg;
@end
