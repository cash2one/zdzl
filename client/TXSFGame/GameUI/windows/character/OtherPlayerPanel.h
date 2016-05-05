//
//  OtherPlayerPanel.h
//  TXSFGame
//
//  Created by Soul on 13-3-17.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

@class ButtonGroup;
@class MessageBox;

@interface Cbe : CCSprite

-(void)updatePower:(int)_power;

@end

@interface OtherEquipmentTray : CCSprite<CCTouchOneByOneDelegate>{
	int				_ueid;
	int				_eid;
	int				_part;
	int				_rid;
	int				_level;
	ItemQuality		_quality;

}

@property(nonatomic,assign)int ueid;
@property(nonatomic,assign)int eid;
@property(nonatomic,assign)int part;
@property(nonatomic,assign)int rid;
@property(nonatomic,assign)int level;
@property(nonatomic,assign)ItemQuality quality;

@end

@interface OtherPlayerPanel : CCSprite<CCTouchOneByOneDelegate> {
	
	NSDictionary* _info ;
	
	NSMutableDictionary * roleInfos;
	NSMutableDictionary * equipInfos;
	NSMutableDictionary * equipSetInfos;
	NSMutableDictionary * fateInfos;
	
	NSMutableDictionary * armInfos;
	NSMutableDictionary * skillInfos;
	
	
	ButtonGroup*		_buttons;
	CCSprite*			_fateSpr;
	CCSprite*			_armSpr;
	CCLabelTTF*			_armLabel;
	CCLabelTTF*			_fateLabel;
	
	MessageBox*			_msgMgr;
	Cbe*				_cbeMgr;

	int					_roleId;
	
}

+(void)show:(NSDictionary*)_info;
+(void)showOver:(NSDictionary *)_info;
-(void)setInfo:(NSDictionary *)info;
-(void)requestShowEquipmentDescribe:(int)_ueid part:(int)_prt;

@end
