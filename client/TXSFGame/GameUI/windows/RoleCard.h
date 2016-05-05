//
//  RoleCard.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-26.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCListItem.h"

typedef enum
{
	CARD_NONE = 0,
	CARD_CHARACTER,
	CARD_WEAPON,
}CARD_TYPE;


@interface RoleCard : CCListItem {
    CARD_TYPE				_type;
	int						_role_id;
	CCSprite				*bg1;
	CCSprite				*bg2;
	CCSprite				*icon;
}
@property(nonatomic,assign)int RoleID;
@property(nonatomic,assign)CARD_TYPE type;
+(RoleCard*) create:(CARD_TYPE) _type;
-(void) initFormID:(int)_rid;
@end
