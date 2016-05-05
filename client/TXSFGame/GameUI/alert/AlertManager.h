//
//  AlertManager.h
//  TXSFGame
//
//  Created by shoujun huang on 13-1-4.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "ShowItem.h"

typedef enum{
	Alert_none = 1000,
	Alert_moving,
	Alert_completed_task,
	Alert_revice_task,
}Alert_type;

@class Task;

@interface AlertManager : NSObject{
	NSMutableArray *alerts;
	GameAlert *runningAlert;
	CCLayerColor *inLayer;
}
+(AlertManager*)shared;
+(void)stopAll;
+(BOOL)hasAlert;
-(BOOL)hasAlert;

//普通确认提示框体
-(void)showReceiveItem:(NSDictionary*)ItemTips;
-(void)showReceiveItemWithArray:(NSArray*)itemTips;
-(void)showMessage:(NSString*)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel ;
-(void)showMessage:(NSString*)_content target:(id)_target call:(SEL)_call delay:(float)_time;
-(void)showMessageWithConfirm:(NSString*)_content target:(id)_target call:(SEL)_call;
-(void)showMessageWithCanel:(NSString*)_content target:(id)_target call:(SEL)_call;
-(GameAlert*)showMessage:(NSString*)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel father:(CCNode*)_father;

-(GameAlert*)showMessageWithSetting:(NSString*)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel key:(NSString*)_key;
-(GameAlert*)showMessageWithSetting:(NSString*)_content target:(id)_target confirm:(SEL)_confirm key:(NSString*)_key;
-(GameAlert*)showMessageWithSetting:(NSString*)_content target:(id)_target confirm:(SEL)_confirm key:(NSString*)_key tips:(NSString*)_tips;

-(GameAlert*)showMessageWithSettingFormFather:(NSString *)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)canel key:(NSString *)_key tips:(NSString *)_tips father:(CCNode *)_father;
-(GameAlert*)showMessageWithSettingFormFather:(NSString*)_content target:(id)_target confirm:(SEL)_confirm key:(NSString*)_key father:(CCNode*)_father;
-(GameAlert*)showMessageWithSettingFormFather:(NSString*)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)canel key:(NSString*)_key father:(CCNode*)_father;
-(GameAlert*)showMessageWithSettingFormFather:(NSString*)_content target:(id)_target confirm:(SEL)_confirm key:(NSString*)_key tips:(NSString*)_tips father:(CCNode*)_father;
-(void)showNPCMessage:(NSString*)_content npcId:(int)npcId target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel;

-(void)showActivity:(NSDictionary*)activity;


-(void)showGoodMessage:(NSString*)_content type:(int)_type good:(int)_good
				target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel
				   key:(NSString*)_key tips:(NSString*)_tips father:(CCNode*)_father;

-(GameAlert*)showError:(NSString*)_content target:(id)_target confirm:(SEL)_confirm father:(CCNode*)_father;
//--------------------------------------------------------------------------------

-(void)showUrgentMessage:(NSString*)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel ;
-(GameAlert*)showUrgentMessage:(NSString *)_content target:(id)_target confirm:(SEL)_confirm canel:(SEL)_canel father:(CCNode *)_father;
-(GameAlert*)showUrgentMessageWithSetting:(NSString*)_content target:(id)_target confirm:(SEL)_confirm key:(NSString*)_key;
-(GameAlert*)showUrgentMessageWithSetting:(NSString*)_content target:(id)_target confirm:(SEL)_confirm key:(NSString*)_key tips:(NSString*)_tips;


//--------------------------------------------------------------------------------
//-(void)showTaskAlert:(Task*)_task target:(id)_target call:(SEL)_call;
//-(void)showTaskAlert:(Task*)_task target:(id)_target call:(SEL)_call useInfo:(BOOL)_info;
//----------------------------------
-(void)checkStatus;
-(void)remove;
-(void)closeAlert;
//---------------------

-(BOOL)alertEnter:(CCNode*)_object;

@end
