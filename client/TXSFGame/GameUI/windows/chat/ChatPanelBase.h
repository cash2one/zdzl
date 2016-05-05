//
//  ChatPanelBase.h
//  TXSFGame
//
//  Created by Max on 13-3-19.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCPanel.h"
#import "ShowItem.h"
#import "AlertTuba.h"
#import "StretchingImg.h"
#import "WindowComponent.h"

#define BG_CHAT 1
#define BTN_CHATTEXTBOX 2
#define BTN_CHATCHANNEL 3
#define BTN_CHATEMO 4
#define BTN_CHATENTER 5
#define BTN_CHATCLOSE 6
#define BTN_CHATOPEN 7
#define TITLE_CHATCHANNEL 8
#define BG_EMO 9
#define BG_CHATCHANNEL 10
#define TYPETIPS 11
#define BTN_BIGCHAT 12

#define BASEPATH @"images/ui/chat/"

#define BTN_EMOBASE 200
#define BTN_CHATCHANNELBASE 70


#define BASECONTENTHIGHT cFixedScale(80)
#define CHAT_LAYERY cFixedScale(13)

@class ChatPanelBase;


@interface ListenChatData : NSObject{
	
}

@property (nonatomic,retain) NSMutableArray *baseAr;
@property (nonatomic,retain) NSMutableArray *chatSavingHistory;


+(ListenChatData*)share;
+(void)stop;



@end




@interface ChatPanelBase : WindowComponent<UITextFieldDelegate> {
	CCSprite *chatLayer;
	CCLayerColor *content;
	CCPanel *panel;
	bool keyBoradOpen;
	int currenChannel;
	int currenReadChannel;
	int chatInterval;
	CGPoint pointEmo;
	NSDictionary *chatcolor;
	bool isChatOpen;
	UITextField *textBox;
	NSMutableArray *chatHistory;
	
}

@property (nonatomic,assign)int ablWidth;
@property (nonatomic,assign)int baseHeight;
@property (nonatomic,assign)int kbHigth;
@property (nonatomic,assign)int kbBaseHigth;

@property (nonatomic,retain)NSMutableArray *chatHistory;
@property (nonatomic,retain)NSString *privateTargetName;
@property (nonatomic,assign)UITextField *textBox;
@property (nonatomic,assign)int privateTargetPid;



+(ChatPanelBase*)share;
-(void)showInputTextField;
-(void)hideInputTextField;
-(void)openEmo;

-(void)startAddHistroy;
-(void)stopAddHistory;


+(int)getPrivateMsgcount;
+(void)setPrivateMsgcount:(int)n;
+(void)sendInviteUnionTeam:(NSString*)content;
+(void)sendPrivateChannle:(NSString*)targetName pid:(int)_pid;

-(void)addHistroy;
-(void)addAllHistroy;
-(void)addNewHistroy;

-(void)loadBrow;

-(void)sendChatEvent:(NSString*)str;

-(void)AddChatContent:(NSString*)str;
-(void)AddChatContent:(NSString*)str color:(NSString*)_color;

-(void)removeTipsChangeButton;

-(void)loadTextBox;
-(void)closeTextBox;

-(void)setChannelBtn:(Channel_type)chl;
-(void)buttonChannelCallBack:(id)sender;
-(void)regPRAjoin;

@end
