//
//  UnionPanel.h
//  TXSFGame
//
//  Created by efun on 12-12-7.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "Window.h"
#import "Panel.h"
#import "ScrollPanel.h"
#import "UnionConfig.h"
#import "UnionMember.h"
#import "UnionActivity.h"
#import "UnionInfo.h"
#import "UnionTab.h"
#import "WindowComponent.h"

@protocol UnionPanelDelegate <NSObject>

@optional
-(void)memberActionWithTag:(Tag_Union_Member_Action)action useId:(int)uid;

@end

// 同盟
@interface UnionPanel : WindowComponent <UnionPanelDelegate>{
	
    UnionInfo *unionInfo;
    UnionTab *unionTab;
	
	CCLayer * content;
	
	NSMutableDictionary * info;
	
	
}
@property(nonatomic,assign) CGPoint touchPoint;
@property(nonatomic,assign) NSDictionary * info;
+(UnionPanel*)getUnionPanel;
+(UnionPanel*)share;

+(void)start;
-(void)showLoading;
-(void)hideLoading;

-(void)getUnionInfo;
-(void)showUnionInfo;
-(void)showUnionList;

-(void)updatePost:(NSString*)_post info:(NSString*)_info;
-(void)updateBaseInfo;
@end
