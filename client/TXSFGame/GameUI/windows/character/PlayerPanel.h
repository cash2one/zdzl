//
//  PlayerPanel.h
//  TXSFGame
//
//  Created by Soul on 13-1-31.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "WindowComponent.h"

@interface PowerSprite : CCSprite

-(void)updatePower:(int)_power;

@end

@interface FunctionButton : CCSimpleButton{
	int		  _func;
}
@property(nonatomic,assign)int func;

+(FunctionButton*)makeWeapon;
+(FunctionButton*)makeFate;
-(void)setInfo:(NSString*)_str;

@end

@class ButtonGroup;
@class ItemManager;
@class ItemSizer;
@class MessageBox;
@class RoleDescribetion;
@class WindowComponent;

@class MemberSizer;

#if Window_debug == 1
@interface PlayerPanel : WindowComponent<CCTouchOneByOneDelegate> {
	//ButtonGroup*		_buttons;
	MemberSizer*		_memberSizer;
	MessageBox*			_msgMgr;
	ItemManager*		_itemMgr;
	ItemSizer*			_sizerMgr;
	RoleDescribetion*	_rDescribetion;
	int					_roleId;
	CGPoint				_panelPos;
    //
	BOOL isSend;
    BOOL isButtonTouch;
}
+(PlayerPanel*)shared;

@property(nonatomic,assign)int roleId;

+(void)setShowRole:(int)_rid;

-(void)takeOffEquipment:(NSDictionary*)data;
-(void)requestShiftWithPart:(int)_part action:(NSDictionary*)_act;
-(void)requestShiftWithPart:(int)_part role:(int)_rid action:(NSDictionary*)_act;

-(void)requestShiftWithDescribetion:(NSNumber*)_ueid;

-(id)requestShiftWithDictionary:(NSDictionary*)_dict;

//-(BOOL)requestShiftWithTouch:(CGPoint)_pt ueid:(int)_ueid;
-(void)requestShowEquipmentDescribe:(int)_ueid part:(int)_prt;
-(void)requestShowItemTrayDescribe:(int)_nid type:(ItemTray_type)_typ;

-(BOOL)isMarkModel;

-(void)batckSellItems;

-(void)requestSellWithDescribetion;

-(void)doUseItem:(int)_id type:(ItemTray_type)_type;//使用碎片合成一件套装

@end
#else
@interface PlayerPanel : CCSprite<CCTouchOneByOneDelegate> {
	ButtonGroup*		_buttons;
	MessageBox*			_msgMgr;
	ItemManager*		_itemMgr;
	ItemSizer*			_sizerMgr;
	RoleDescribetion*	_rDescribetion;
	int					_roleId;
	CGPoint				_panelPos;
	//
    BOOL isSend;
    BOOL isButtonTouch;
}
+(PlayerPanel*)shared;

@property(nonatomic,assign)int roleId;

+(void)setShowRole:(int)_rid;

-(void)takeOffEquipment:(NSDictionary*)data;
-(void)requestShiftWithPart:(int)_part action:(NSDictionary*)_act;
-(void)requestShiftWithPart:(int)_part role:(int)_rid action:(NSDictionary*)_act;

-(void)requestShiftWithDescribetion:(NSNumber*)_ueid;

-(BOOL)requestShiftWithTouch:(CGPoint)_pt ueid:(int)_ueid;
-(void)requestShowEquipmentDescribe:(int)_ueid part:(int)_prt;
-(void)requestShowItemTrayDescribe:(int)_nid type:(ItemTray_type)_typ;
-(void)requestShowItemTrayDescribe:(NSDictionary*)dict;


-(void)batckSellItems;

-(void)requestSellWithDescribetion;

-(void)doUseItem:(int)_id type:(ItemTray_type)_type;//使用碎片合成一件套装

@end
#endif
	
