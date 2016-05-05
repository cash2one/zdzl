//
//  UnionSetting.h
//  TXSFGame
//
//  Created by peak on 13-4-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface UnionSetting : CCLayer<UITextViewDelegate>{
	UITextView * postInput;
	UITextView * infoInput;
	BOOL isChange;
}
+(void)show;
+(void)hide;
+(void)setStaticUnionSettingNil;
@end

//职任设置
@interface UnionDisbandSetting : CCLayer{
    CCMenu *menu;
    int select_index;
    int memberID;
    int playerDuty;
    NSString *playerName;
    NSMutableArray *select_array;
}
@property(assign,nonatomic)int select_index;
@property(assign,nonatomic)int memberID;
@property(assign,nonatomic)int playerDuty;
@property(nonatomic,retain) NSString *playerName;
//+(void)show;
+(void)showWithID:(int)member_id name:(NSString*)name duty:(int)duty;
+(void)hide;
@end