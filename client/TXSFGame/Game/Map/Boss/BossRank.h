//
//  BossRank.h
//  TXSFGame
//
//  Created by Soul on 13-4-10.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


@interface RankMember : CCSprite{
	NSString* _des;
}
@property(nonatomic,retain)NSString* des;

+(RankMember*)memberWithDimension:(CGSize)_size :(NSString*)_info;

@end

@interface BossRank : CCSprite {
    
}
-(void)updatePlayerHurt:(float)_value hurt:(float)_total;
-(void)updateRank:(NSArray *)_array1 :(NSArray *)_array2 hp:(float)_hp;

@end