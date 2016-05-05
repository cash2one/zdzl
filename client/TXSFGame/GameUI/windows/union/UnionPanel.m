//
//  UnionPanel.m
//  TXSFGame
//
//  Created by efun on 12-12-7.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "UnionPanel.h"
#import "GameDB.h"
#import "GameConnection.h"

#import "CCSimpleButton.h"
#import "UnionManager.h"
#import "UnionConfig.h"
#import "UnionCreate.h"
#import "UnionViewer.h"
#import "UnionTitle.h"
#import "InfoAlert.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "UnionBossSetting.h"
#import "UnionSetting.h"

//#define PanelLayer_Height (cFixedScale(429))

static UnionPanel *unionPanel;

@interface UnionPanelTouchLayer : CCLayer{
	
}
@property(nonatomic,assign)CGPoint touchPoint;

@end

@implementation UnionPanelTouchLayer

@synthesize touchPoint;




-(void)onEnter{
	[super onEnter];
	[[[CCDirector sharedDirector]touchDispatcher]addTargetedDelegate:self priority:-999 swallowsTouches:NO];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	
	[unionPanel setTouchPoint:getGLpoint(touch)];
	//[unionPanel removeChildByTag:UnionMemberActionMenu];
    return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	//[unionPanel removeChildByTag:UnionMemberActionMenu];
	
}


@end

#define UNIONINFO_OFF_W (13)
#define UNIONINFO_OFF_H (16)

@implementation UnionPanel

@synthesize info;
@synthesize touchPoint;
+(UnionPanel*)getUnionPanel{
    return unionPanel;
}
+(UnionPanel*)share{
	if(!unionPanel){
		[UnionPanel start];
	}
	return unionPanel;
}

+(void)start{
	if(!unionPanel){
		unionPanel = [UnionPanel node];
		unionPanel.windowType = PANEL_UNION;
		[[Window shared] addChild:unionPanel z:10 tag:PANEL_UNION];
		[unionPanel checkStatus];
	}
}
//fix chao
-(void)updateBaseInfo{
    [GameConnection request:@"allyOwn" format:@"" target:self call:@selector(didGetBaseInfo:)];
}
-(void)didGetBaseInfo:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		if(info){
			[info release];
			info = nil;
		}
		
		//info = [[NSDictionary alloc] initWithDictionary:getResponseData(response)];
		
		NSDictionary * data = getResponseData(response);
		
		info = [[NSMutableDictionary alloc] init];
		[info setValuesForKeysWithDictionary:data];
		[info removeObjectForKey:@"ally"];
		[info setValuesForKeysWithDictionary:[data objectForKey:@"ally"]];
		
		[[GameConfigure shared] setPlayerAlly:info];
		
		//[self showUnionInfo];
        if (unionInfo) {
            [content removeChild:unionInfo cleanup:YES];
            unionInfo = nil;
            
            [self hideLoading];
            
            unionInfo = [[[UnionInfo alloc] initWithUnionId:0] autorelease];
            if (iPhoneRuningOnGame()) {
				unionInfo.position = ccp(-self.contentSize.width/2+cFixedScale(UNIONINFO_OFF_W)+44,-unionInfo.contentSize.height/2-cFixedScale(UNIONINFO_OFF_H));
            }else{
                unionInfo.position = ccp(cFixedScale(-412),cFixedScale( -268));
            }
			unionInfo.position = ccpAdd(unionInfo.position, ccp(self.contentSize.width/2,self.contentSize.height/2));
            [content addChild:unionInfo];
        }
		
	}else{
		[self showUnionList];
	}
}
//end
-(void)checkStatus{
	
	[self showLoading];
	
	/*
	 NSDictionary * ally = [[GameConfigure shared] getPlayerAlly];
	 if(ally){
	 [self getUnionInfo];
	 }else{
	 [self showUnionList];
	 }
	 */
	
	[GameConnection request:@"allyOwn" format:@"" target:self call:@selector(didGetAllyOwn:)];
	
}

-(void)getUnionInfo{
	
	if(info){
		[self showUnionInfo];
	}else{
		[GameConnection request:@"allyOwn" format:@"" target:self call:@selector(didGetAllyOwn:)];
	}
	
}

-(void)didGetAllyOwn:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		if(info){
			[info release];
			info = nil;
		}
		
		//info = [[NSDictionary alloc] initWithDictionary:getResponseData(response)];
		
		NSDictionary * data = getResponseData(response);
		
		info = [[NSMutableDictionary alloc] init];
		[info setValuesForKeysWithDictionary:data];
		[info removeObjectForKey:@"ally"];
		[info setValuesForKeysWithDictionary:[data objectForKey:@"ally"]];
		
		[[GameConfigure shared] setPlayerAlly:info];
        //fix chao
        RolePlayer *player = [RoleManager shared].player;
        if (player) {
            NSDictionary *playerAlly=[[GameConfigure shared]getPlayerAlly];
            player.allyName=[playerAlly objectForKey:@"n"];
            [player updateViewer];
        }
        //end
		[self showUnionInfo];
		
	}else{
		[self showUnionList];
	}
}

-(void)updatePost:(NSString*)_post info:(NSString*)_info{
	if(info){
		[info setObject:_post forKey:@"post"];
		[info setObject:_info forKey:@"info"];
		[[GameConfigure shared] setPlayerAlly:info];
		
		if(unionInfo){
			[unionInfo updateNotice:_post];
		}
		
	}
}

-(void)showUnionInfo{
	
	[content removeAllChildrenWithCleanup:YES];
	
	[self hideLoading];
	
    unionInfo = [[[UnionInfo alloc] initWithUnionId:0] autorelease];
    if (iPhoneRuningOnGame()) {
		unionInfo.position = ccp(-self.contentSize.width/2+cFixedScale(UNIONINFO_OFF_W)+44,-unionInfo.contentSize.height/2-cFixedScale(UNIONINFO_OFF_H));
    }else{
        unionInfo.position = ccp(cFixedScale(-412),cFixedScale( -268));
    }
	unionInfo.position = ccpAdd(unionInfo.position, ccp(self.contentSize.width/2,self.contentSize.height/2));
	
    [content addChild:unionInfo];
    
    unionTab = [[[UnionTab alloc] initWithUnionId:0] autorelease];
    if (iPhoneRuningOnGame()) {
		unionTab.position = ccp(self.contentSize.width/2-unionTab.contentSize.width-cFixedScale(UNIONINFO_OFF_W+88)-44,-unionTab.contentSize.height/2-cFixedScale(UNIONINFO_OFF_H-14));
    }else{
        unionTab.position = ccp(cFixedScale(-106),cFixedScale( -268));
    }
    unionTab.position = ccpAdd(unionTab.position, ccp(self.contentSize.width/2,self.contentSize.height/2));
	
    [content addChild:unionTab];
	
}

-(void)showUnionList{
	
	[content removeAllChildrenWithCleanup:YES];
	
	unionInfo = nil;
	unionTab = nil;
	
	[self hideLoading];
	
	UnionCreate * node = [UnionCreate node];
	node.position = ccpAdd(node.position, ccp(self.contentSize.width/2,self.contentSize.height/2));
	[content addChild:node z:100];
	
}

-(void)showLoading{
	
	//TODO show loading
	
}
-(void)hideLoading{
	
	//TODO hide loading
	
}


#pragma mark UnionPanel onEnter
-(void)onEnter{
	
    [super onEnter];
    
	self.touchEnabled = YES;
	if (iPhoneRuningOnGame()) {
		self.touchPriority = -2;
	} else {
		self.touchPriority = -1;
	}
	
	content = [CCLayer node];
	[self addChild:content z:50];
	
	UnionPanelTouchLayer *toptouch=[UnionPanelTouchLayer node];
	[toptouch setPosition:CGPointZero];
	[self addChild:toptouch];
    //fix chao
    [GameConnection addPost:ConnPost_KickApply_success target:self call:@selector(closeWindowTapped)];
    //end
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	[unionTab ccTouchBegan:touch withEvent:event];
    return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	
	[unionTab ccTouchEnded:touch withEvent:event];
}

-(void)onExit{
	
    //fix chao
    [GameConnection removePostTarget:self];
    //end
    
	unionPanel = nil;
	unionInfo = nil;
    unionTab = nil;
	
	if(info){
		[info release];
		info = nil;
	}
	
	CCDirector *director = [CCDirector sharedDirector];
    [[director touchDispatcher] removeDelegate:self];
	
	//unionSetting = nil;
    [UnionSetting setStaticUnionSettingNil];
	unionPanel = nil;
	//unionViewer = nil;
	
    [super onExit];
    
}

-(void)closeWindowTapped
{
    [[Window shared] removeWindow:PANEL_UNION];
}

#pragma mark -
#pragma mark UnionPanelDelegate

-(void)memberActionWithTag:(Tag_Union_Member_Action)action useId:(int)uid
{
    if (action == Tag_Union_Member_Talk) {
        [[Window shared] removeWindow:PANEL_UNION];
        
        CCLOG(@"弹出私聊框，与Id为%d的用户进行聊天", uid);
    }
    else if (action == Tag_Union_Member_Add) {
        
        CCLOG(@"加为好友提示");
    }
    else if (action == Tag_Union_Member_Look) {
        [[Window shared] removeWindow:PANEL_UNION];
        
        CCLOG(@"查看Id为%d的用户信息", uid);
    }
}

@end
