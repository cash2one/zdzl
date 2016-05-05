//
//  UnionMember.h
//  TXSFGame
//
//  Created by Max on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "UnionTitle.h"
#import "UnionConfig.h"
#define UnionMemberActionMenu 9999

@interface UnionMemberItem : CCSprite
{
    CCLabelTTF *nameLabel;
    CCLabelTTF *levelLabel;
    CCLabelTTF *jobLabel;
    CCLabelTTF *rankLabel;
    CCLabelTTF *contribLabel;
    CCLabelTTF *statusLabel;
    
    ccColor3B normalColor;
    ccColor3B selectedColor;
	int pid;
	
}
@property (nonatomic) BOOL isSelected;
@property (nonatomic) BOOL isMainUser;
@property (assign,nonatomic) int duty;
-(id)initWithName:(NSString *)name level:(int)level job:(NSString *)job rank:(int)rank contrib:(int)contrib status:(NSString *)status pid:(int)_pid;

@end


//操作成员
@interface UnionMemberAction : CCLayerColor{
	CCMenu *menu ;
}
@property (nonatomic) int userId;
@property (nonatomic,retain) NSString *playerName;
@property (nonatomic,assign) int playerId;
@property (assign,nonatomic) int duty;

+(UnionMemberAction*)memberAction:(NSString*)_name pid:(int)_pid;
@end




// 成员
@interface UnionMember : CCLayerColor 
{
    int unionId;
    CCLayer *listLayer;
	CCPanel *memberListPanel;
    UnionMemberAction *memberAction;
}
+(UnionMember*)getUnionMember;
-(CCPanel*)getCCPanel;
-(UnionMember*)share;
-(id)initWithUnionId:(int)uid;
@end


