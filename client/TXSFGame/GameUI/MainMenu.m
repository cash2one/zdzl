//
//  MainMenu.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-16.
//  Copyright 2012 eGame. All rights reserved.
//

#import "MainMenu.h"
#import "CCLabelFX.h"
#import "Window.h"
#import "AbyssManager.h"
#import "MapManager.h"
#import "Config.h"
#import "AlertManager.h"
#import "GameUI.h"
#import "TimeBox.h"
#import "GameStart.h"
#import "FightManager.h"
#import "FishingManager.h"
#import "Arena.h"
#import "GameConnection.h"
#import "Game.h"
#import "CCSimpleButton.h"
#import "PlayerSit.h"
#import "MiningManager.h"
#import "RolePlayer.h"
#import "RoleManager.h"
#import "MailList.h"
#import "PlayerPanel.h"
#import "GameTipsHelper.h"
#import "GameSoundManager.h"
#import "WorldBossManager.h"
#import "UnionBossManager.h"
#import "MessageContainer.h"

#define  MAINMENU_MOVE_DATA_TIME (0.2f)
#define  MAINMENU_BACK_TAG (123)

#define  XBUTTON						7
#define  YBUTTON			            3

static int RB_OFFSET			=			60;
static int  MENUITEM_GAP		=           2;
static int  MENUITEM_FACE		=           80;
static int  ITEM_RES_WIDTH	=           85;
static int  ITEM_RES_HEIGHT	=           92;


#define MENUITEM_STARTX             (RB_OFFSET + (MENUITEM_FACE/2) + MENUITEM_GAP + (ITEM_RES_WIDTH/2))
#define MENUITEM_STARTY             (RB_OFFSET + (MENUITEM_FACE/2) + MENUITEM_GAP + (ITEM_RES_HEIGHT/2))


static MainMenu * mainMenu;

@implementation MainMenu
@synthesize OpenMenu = m_bOpenMenu;

enum{
    MM_EXP_BG_TAG = 233,
	MM_EXP_BODY_TAG,
	MM_EXP_END_TAG,
};

+(id)getInstance{
    return [MainMenu node];
}

+(MainMenu*)share{
	if(!mainMenu){
		return [MainMenu getInstance];
	}
	return mainMenu;
}

+(int)totalButtons{
	if(mainMenu){
		return [mainMenu buttonCount];
	}
	return 0;
}

-(int)buttonCount{
	return [m_HImageItems count];
}

-(NSString*)getImage:(MENU_TAG)tag
{
	switch ((int)tag) {
        case BT_NONE_TAG: return nil;
        case BT_CONTROL_TAG:return @"images/ui/button/bt_control.png";
        case BT_ROLE_TAG:return @"images/ui/button/bt_role";
        case BT_PACKAGE_TAG:return @"images/ui/button/bt_package";
        case BT_PHALANX_TAG:return @"images/ui/button/bt_phalanx";
        case BT_HAMMER_TAG:return @"images/ui/button/bt_hammer";
		case BT_GUANXING_TAG:return @"images/ui/button/bt_guanxing";
		case BT_WEAPON_TAG:return @"images/ui/button/bt_weapon";
        case BT_RECRUIT_TAG:return @"images/ui/button/bt_recruits";
        case BT_UNION_TAG:return @"images/ui/button/bt_union";
        case BT_ZAZEN_TAG:return @"images/ui/button/bt_zazen";
        case BT_SETTING_TAG:return @"images/ui/button/bt_setting";
        case BT_FRIEND_TAG:return @"images/ui/button/bt_friend";
        case BT_TRADE_TAG:return @"images/ui/button/bt_trade";
        case BT_SHOW_MAP_TAG:return @"images/ui/button/bt_jumpmap";
        case BT_TASK_TAG:return @"images/ui/button/bt_task";
		case BT_TIMEBOX_TAG:return @"images/ui/button/bt_timebox";
		case BT_ARENA_TAG:return @"images/ui/button/bt_arena";
		case BT_DAILY_TAG:return @"images/ui/button/bt_daily";
		case BT_JEWEL_TAG:return @"images/ui/button/bt_jewel";
    }
    return nil;
}

-(id)init
{
    self = [super init];
    if (self) {
		//end
		if (iPhoneRuningOnGame()) {
			RB_OFFSET		=	60/2.0f;
			MENUITEM_FACE	=   80/2.0f;
			ITEM_RES_WIDTH	=	85*1.15f/2.0f;
			ITEM_RES_HEIGHT	=   92/2.0f;
		}else{
			RB_OFFSET		=	60;
			MENUITEM_FACE	=   80;
			ITEM_RES_WIDTH	=   85;
			ITEM_RES_HEIGHT	=   92;
		}
    }
    return self;
}

-(void)updateExp{
	NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
	if (player == nil) {
		CCLOG(@"player info error");
        return ;
	}
	
	int _level = [[player objectForKey:@"level"] intValue];
	int _exp = [[player objectForKey:@"exp"] intValue];
    int nextLevelExp = _exp;
	float _value = 0.0f;
	NSDictionary *next_expLevelDict = [[GameDB shared] getRoleExpInfo:_level+1];
	if(next_expLevelDict){
		nextLevelExp = [[next_expLevelDict objectForKey:@"exp"] intValue];
		_value = (float)_exp/(float)nextLevelExp;
		if (_value > 1.0) {
			_value = 1.0f;
		}
		if (_value < 0.0) {
			_value = 0.0f;
		}
	}else{
		CCLOG(@"update exp error!");
		_value = 1.0f;
	}
	
	CGSize size = [CCDirector sharedDirector].winSize;
	CCSprite *exp_body = (CCSprite *)[self getChildByTag:MM_EXP_BODY_TAG];
	
	if (exp_body) {
		exp_body.scaleX = (size.width/exp_body.contentSize.width) * _value;
	}
	
	CCSprite *exp_end = (CCSprite *)[self getChildByTag:MM_EXP_END_TAG];
	if (exp_end) {
		exp_end.position = ccp(exp_body.contentSize.width*exp_body.scaleX,0);
	}
    //fix chao
    if (exeSprite) {
        [exeSprite setString:[NSString stringWithFormat:@"%d/%d",_exp,nextLevelExp]];
    }
    //end
}
-(void)initAllButton
{
    if (m_HImageItems == nil) {
        m_HImageItems = [NSMutableArray array];
        [m_HImageItems retain];
    }else {
        [m_HImageItems removeAllObjects];
    }
    
    if (m_VImageItems == nil) {
        m_VImageItems = [NSMutableArray array];
        [m_VImageItems retain];
    }else {
        [m_VImageItems removeAllObjects];
    }
    
    if (m_HIphoneImageItems == nil) {
        m_HIphoneImageItems = [NSMutableArray array];
        [m_HIphoneImageItems retain];
    }else{
        [m_HIphoneImageItems removeAllObjects];
    }
    
    if (m_VIphoneImageItems == nil) {
        m_VIphoneImageItems = [NSMutableArray array];
        [m_VIphoneImageItems retain];
    }else{
        [m_VIphoneImageItems removeAllObjects];
    }

}

-(CCSimpleButton *)getButtonWithTag:(MENU_TAG)tag
{
	
	return (CCSimpleButton *)[buttonLayer getChildByTag:tag];
}

/*
 * 添加菜单选项
 * tag 通过MENU_TAG 定义来匹配
 * dir 0 是X轴，1 是Y轴
 */
-(void) addMenuItem:(int)tag Dir:(int)dir
{
    if (tag <= BT_ROLE_TAG ) {
        if (iPhoneRuningOnGame() && [self isIphoneItemWithTag:tag]) {
            bool canAdd = true ;
            for (NSNumber *nbr in m_HIphoneImageItems) {
                int _temp = [nbr intValue];
                if (_temp == tag) {
                    canAdd  = false;
                    break ;
                }
            }
            if (canAdd) {
                [m_HIphoneImageItems addObject: [NSNumber numberWithInt:tag]];
            }
        }else{
            bool canAdd = true ;
            for ( NSNumber *nbr in m_HImageItems) {
                int _temp = [nbr intValue];
                if (_temp == tag) {
                    canAdd  = false;
                    break ;
                }
            }
            if (canAdd) {
                [m_HImageItems addObject: [NSNumber numberWithInt:tag]];
            }
        }
    }
    else
    {
        if (iPhoneRuningOnGame() && [self isIphoneItemWithTag:tag]) {
            bool canAdd = true ;
            for (NSNumber *nbr in m_VIphoneImageItems) {
                int _temp = [nbr intValue];
                if (_temp == tag) {
                    canAdd  = false;
                    break ;
                }
            }
            if (canAdd) {
                [m_VIphoneImageItems addObject: [NSNumber numberWithInt:tag]];
            }
        }else{
            bool canAdd = true ;
            for (NSNumber *nbr in m_VImageItems) {
                int _temp = [nbr intValue];
                if (_temp == tag) {
                    canAdd  = false;
                    break ;
                }
            }
            if (canAdd) {
                [m_VImageItems addObject: [NSNumber numberWithInt:tag]];
            }
        }
    }
    
    [[GameConfigure shared] updateUserMenuList:tag];
	
	//TODO need sort all items
	//m_bFresh = true;
	[self sortAllMenuItem:YES];
	if (iPhoneRuningOnGame()) {
        [self sortAllIphoneMenuItem:YES];
    }
	[MailList moveTop];
	
	//新手教程打开阵型
	
	
}
/*
 * 删除菜单选项
 * tag 通过MENU_TAG 定义来匹配
 * dir 0 是X轴，1 是Y轴
 */
-(void) removeMenuItem:(int)tag Dir:(int)dir
{
	CCSimpleButton *item = (CCSimpleButton*)[buttonLayer getChildByTag:tag];
    if (item) {
        [item setVisible:false];
    }
    if (dir == 0) {
        if (iPhoneRuningOnGame()) {
            if ([self isIphoneItemWithTag:tag]) {
                [m_HIphoneImageItems removeObject:[NSNumber numberWithInt:tag]];
            }else{
                [m_HImageItems removeObject:[NSNumber numberWithInt:tag]];
            }
        }else{
            [m_HImageItems removeObject:[NSNumber numberWithInt:tag]];
        }
        //[m_HImageItems removeObject:[NSNumber numberWithInt:tag]];
    }else {
        if (iPhoneRuningOnGame()) {
            if ([self isIphoneItemWithTag:tag]) {
                [m_VIphoneImageItems removeObject:[NSNumber numberWithInt:tag]];
            }else{
                [m_VImageItems removeObject:[NSNumber numberWithInt:tag]];
            }
        }else{
            [m_VImageItems removeObject:[NSNumber numberWithInt:tag]];
        }
        
    }
	
	//TODO need sort all items
    //m_bFresh = true;
	[self sortAllMenuItem:YES];
    if (iPhoneRuningOnGame()) {
        [self sortAllIphoneMenuItem:YES];
    }
}
/*
 全部删除右下方的按钮，除了那个菜单开关
 */
-(void) removeAllMenuItem
{
    if (m_HImageItems) {
        for (NSNumber *number in m_HImageItems) {
            int tag = [number intValue];
			if (buttonLayer) {
                [buttonLayer removeChildByTag:tag cleanup:true];
            }
        }
        [m_HImageItems removeAllObjects];
    }
    
    if (m_VImageItems) {
        for (NSNumber *number in m_VImageItems) {
            int tag = [number intValue];
			if (buttonLayer) {
                [buttonLayer removeChildByTag:tag cleanup:true];
            }
        }
        [m_VImageItems removeAllObjects];
    }
    
    if (m_HIphoneImageItems) {
        for (NSNumber *number in m_HIphoneImageItems) {
            int tag = [number intValue];
			if (buttonLayer) {
                [buttonLayer removeChildByTag:tag cleanup:true];
            }
        }
        [m_HIphoneImageItems removeAllObjects];
    }
    
    if (m_VIphoneImageItems) {
        for (NSNumber *number in m_VIphoneImageItems) {
            int tag = [number intValue];
			if (buttonLayer) {
                [buttonLayer removeChildByTag:tag cleanup:true];
            }
        }
        [m_VIphoneImageItems removeAllObjects];
    }
    
	[self sortAllMenuItem:NO];
    if (iPhoneRuningOnGame()) {
        [self sortAllIphoneMenuItem:NO];
    }
}
/*
 * 加载菜单数据，并且通知需要排列
 */
-(void) loadMenuItemList
{
    NSMutableArray *_array = [[GameConfigure shared] getUserMenuList];
    if (_array) {
        for (NSNumber *nbr in _array) {
            int __tag = [nbr intValue];
            if (__tag <= BT_ROLE_TAG ) {
                if(iPhoneRuningOnGame()){
					if([self isIphoneItemWithTag:__tag]){
						[m_HIphoneImageItems addObject: [NSNumber numberWithInt:__tag]];
					}else{
                        [m_HImageItems addObject: [NSNumber numberWithInt:__tag]];
                    }
				}else{
					[m_HImageItems addObject: [NSNumber numberWithInt:__tag]];
				}
                //[m_HImageItems addObject: [NSNumber numberWithInt:__tag]];
            }else{
				if(iPhoneRuningOnGame()){
					if([self isIphoneItemWithTag:__tag]){
						[m_VIphoneImageItems addObject: [NSNumber numberWithInt:__tag]];
					}else{
                        [m_VImageItems addObject: [NSNumber numberWithInt:__tag]];
                    }
				}else{
					[m_VImageItems addObject: [NSNumber numberWithInt:__tag]];
				}
            }
        }
    } else {
        CCLOG(@"please check for menu data");
    }
	//TODO need sort all items
    //m_bFresh = true;
	[self sortAllMenuItem:NO];
	if (iPhoneRuningOnGame()) {
        [self sortAllIphoneMenuItem:NO];
    }
}

/**
 当菜单出现增删，这里面从新为菜单选项排列位置
 */
-(void) sortAllMenuItem:(BOOL)isEffects
{
    CGSize size = [[CCDirector sharedDirector] winSize];
	float distanceX=0;
	float distanceY=0;
	if (iPhoneRuningOnGame()) {
		distanceX=4;
		distanceY=8;
	}
    float _x = size.width - MENUITEM_STARTX-distanceX;
    float _y = MENUITEM_STARTY+distanceY;
	
	BOOL isNew = NO;
	
    [m_HImageItems sortUsingSelector:@selector(compare:)];
    for (NSNumber *number in m_HImageItems) {
        int tag = [number intValue];
		isNew = NO;
		CCSimpleButton *item = (CCSimpleButton*)[buttonLayer getChildByTag:tag];
        if (!item) {
			NSString *normal = [NSString stringWithFormat:@"%@_1.png", [self getImage:tag]];
			NSString *select = [NSString stringWithFormat:@"%@_2.png", [self getImage:tag]];
			item = [CCSimpleButton spriteWithFile:normal
										   select:select
										   target:self
											 call:@selector(menuCallbackBack:)];
			
			item.position = ccp(size.width/2,size.height/2);
            if (iPhoneRuningOnGame()) {
				item.scale=1.15f;
			}
			//item.priority = -57 ;
			
			[buttonLayer addChild:item z:1 tag:tag];
			
			isNew = YES;
			
		}
		[item setVisible:[self OpenMenu]];
		if(isEffects && [self OpenMenu]){
			id action;
			if(isNew){
				item.scale=0;
				item.position=ccp(_x, RB_OFFSET);
				if (iPhoneRuningOnGame()) {
					action =[CCScaleTo actionWithDuration:0.4 scale:1.15f];
				}else{
					action =[CCScaleTo actionWithDuration:0.4 scale:1];
				}
			}else{
				action = [CCMoveTo actionWithDuration:0.3f position:ccp(_x, RB_OFFSET)];
			}
			[item runAction:action];
		}else{
			[item setPosition:ccp(_x, RB_OFFSET)];
		}
		_x = _x - MENUITEM_GAP - ITEM_RES_WIDTH ;
		
		switch (tag) {
			case BT_RECRUIT_TAG:
				[[Intro share] runIntroTager:item step:INTRO_OPEN_Recruit];
				break;
			case BT_PHALANX_TAG:
				[[Intro share] runIntroTager:item step:INTRO_OPEN_Phalanx];
				break;
			case BT_HAMMER_TAG:
				[[Intro share] runIntroTager:item step:INTRO_OPEN_Hammer];
				break;
			case BT_WEAPON_TAG:
				[[Intro share] runIntroTager:item step:INTRO_OPEN_Weapon];
				break;
			case BT_GUANXING_TAG:
				[[Intro share] runIntroTager:item step:INTRO_OPEN_GuangXing];
				break;
			default:
				break;
		}
    }
	[m_VImageItems sortUsingSelector:@selector(compare:)];
    for (NSNumber *number in m_VImageItems) {
        int tag = [number intValue];
		isNew = NO;
		CCSimpleButton *item = (CCSimpleButton*)[buttonLayer getChildByTag:tag];
        if (!item) {
			NSString *normal = [NSString stringWithFormat:@"%@_1.png", [self getImage:tag]];
			NSString *select = [NSString stringWithFormat:@"%@_2.png", [self getImage:tag]];
			item = [CCSimpleButton spriteWithFile:normal
										   select:select
										   target:self
											 call:@selector(menuCallbackBack:)];
			//item.priority = -57 ;
			
			item.position = ccp(size.width/2,size.height/2);
			if (iPhoneRuningOnGame()) {
				item.scale=1.15f;
			}
			//			[m_Menu addChild:item z:1 tag:tag];
			[buttonLayer addChild:item z:1 tag:tag];
			
			
			isNew = YES;
		}
		[item setVisible:[self OpenMenu]];
		if(isEffects && [self OpenMenu]){
			id action;
			if(isNew){
				item.scale=0;
				item.position=ccp(size.width - RB_OFFSET, _y);
				if (iPhoneRuningOnGame()) {
					action =[CCScaleTo actionWithDuration:0.4 scale:1.15f];
				}else{
					action =[CCScaleTo actionWithDuration:0.4 scale:1];
				}
			}else{
				action = [CCMoveTo actionWithDuration:0.3f position:ccp(size.width - RB_OFFSET, _y)];
			}
			[item runAction:action];
		}else{
			[item setPosition:ccp(size.width - RB_OFFSET, _y)];
		}
        _y = _y + ITEM_RES_HEIGHT + MENUITEM_GAP ;
		CCLOG(@"%f,%f",item.anchorPoint.x,item.anchorPoint.y);
		switch (tag) {
			case BT_TIMEBOX_TAG:
				//CCLOG(@"%f,%f",item.position.x,item.position.y);
				[[Intro share] runIntroTager:item step:INTRO_OPEN_TimeBox];
				break;
			default:
				break;
		}
    }
}
//
-(void)showFireEffectWithTag:(int)tag{
    if (buttonLayer) {
        CCSimpleButton *item = (CCSimpleButton *)[buttonLayer getChildByTag:tag];
        if (item) {
            NSArray *frame=[AnimationViewer loadFileByFileFullPath:@"images/ui/intro/fire/" name:@"%d.png"];
            AnimationViewer *fire_logo=[AnimationViewer node];
            [fire_logo playAnimation:frame];
            [fire_logo setPosition:ccp(item.contentSize.width/2,item.contentSize.height/2)];
            fire_logo.tag = tag;
            [item addChild:fire_logo];
            return;
        }
    }
    //
    CCLOG(@"no main menu item.....");
}
//
-(void)hideFireEffectWithTag:(int)tag{
    CCSimpleButton *item = (CCSimpleButton *)[buttonLayer getChildByTag:tag];
    [item removeChildByTag:tag cleanup:YES];  
}
//fix chao
-(void)showItemBackCall:(id)sender{
	CCNode *item = sender;
	[item setVisible:[self OpenMenu]];
}
-(void)hideItemBackCall:(id)sender{
	CCNode *item = sender;
    if ( iPhoneRuningOnGame() ) {
        if (BT_ROLE_TAG != item.tag) {
            [item setVisible:[self OpenMenu]];
        }
        
    }else{
        [item setVisible:[self OpenMenu]];
    }
	//[item setVisible:[self OpenMenu]];
}
-(void) sortAllIphoneMenuItem:(BOOL)isEffects{
    CGSize size = [[CCDirector sharedDirector] winSize];
	float distanceX=0;
	float distanceY=0;
	if (iPhoneRuningOnGame()) {
		distanceX=4;
		distanceY=8;
	}
    float _x = size.width - MENUITEM_STARTX-distanceX - (ITEM_RES_HEIGHT + MENUITEM_GAP);
	float _y = MENUITEM_STARTY+distanceY;
    
	BOOL isNew = NO;
    /////------
    [m_HIphoneImageItems sortUsingSelector:@selector(compare:)];
    for (NSNumber *number in m_HIphoneImageItems) {
        int tag = [number intValue];
		isNew = NO;
		CCSimpleButton *item = (CCSimpleButton*)[buttonLayer getChildByTag:tag];
        if (!item) {
			NSString *normal = [NSString stringWithFormat:@"%@_1.png", [self getImage:tag]];
			NSString *select = [NSString stringWithFormat:@"%@_2.png", [self getImage:tag]];
			item = [CCSimpleButton spriteWithFile:normal
										   select:select
										   target:self
											 call:@selector(menuCallbackBack:)];
			//item.priority = -57 ;
			
			item.position = ccp(size.width/2,size.height/2);
			if (iPhoneRuningOnGame()) {
				item.scale=1.15f;
			}
			//			[m_Menu addChild:item z:1 tag:tag];
			[buttonLayer addChild:item z:1 tag:tag];
			
			
			isNew = YES;
		}
		[item setVisible:YES];
		if(isEffects && ![self OpenMenu]){
			id action;
			if(isNew){
				item.scale=0;
				item.position=ccp(_x,+ RB_OFFSET);
				action =[CCScaleTo actionWithDuration:0.4 scale:1];
			}else{
				action = [CCMoveTo actionWithDuration:0.3f position:ccp(_x,+ RB_OFFSET)];
			}
			[item runAction:action];
		}else
        {
			[item setPosition:ccp(_x,- RB_OFFSET)];
		}
        _x = _x - ITEM_RES_HEIGHT - MENUITEM_GAP ;
    }
    ////-------
    [m_VIphoneImageItems sortUsingSelector:@selector(compare:)];
    for (NSNumber *number in m_VIphoneImageItems) {
        int tag = [number intValue];
		isNew = NO;
		CCSimpleButton *item = (CCSimpleButton*)[buttonLayer getChildByTag:tag];
        if (!item) {
			NSString *normal = [NSString stringWithFormat:@"%@_1.png", [self getImage:tag]];
			NSString *select = [NSString stringWithFormat:@"%@_2.png", [self getImage:tag]];
			item = [CCSimpleButton spriteWithFile:normal
										   select:select
										   target:self
											 call:@selector(menuCallbackBack:)];
			//item.priority = -57 ;
			
			item.position = ccp(size.width/2,size.height/2);
			if (iPhoneRuningOnGame()) {
				item.scale=1.15f;
			}
			//			[m_Menu addChild:item z:1 tag:tag];
			[buttonLayer addChild:item z:1 tag:tag];
			
			
			isNew = YES;
		}
		[item setVisible:YES];
		if(isEffects && ![self OpenMenu]){
			id action;
			if(isNew){
				item.scale=0;
				item.position=ccp(size.width - RB_OFFSET, _y);
				action =[CCScaleTo actionWithDuration:0.4 scale:1];
			}else{
				action = [CCMoveTo actionWithDuration:0.3f position:ccp(size.width - RB_OFFSET, _y)];
			}
			[item runAction:action];
		}else
        {
			[item setPosition:ccp(size.width + RB_OFFSET, _y)];
		}
        _y = _y + ITEM_RES_HEIGHT + MENUITEM_GAP ;
		CCLOG(@"%f,%f",item.anchorPoint.x,item.anchorPoint.y);
		switch (tag) {
			case BT_TIMEBOX_TAG:
				[[Intro share] runIntroTager:item step:INTRO_OPEN_TimeBox];
				break;
			default:
				break;
		}
    }
}
-(BOOL)isIphoneItemWithTag:(int)tag{
    if ( BT_FRIEND_TAG == tag || BT_SETTING_TAG == tag || BT_JEWEL_TAG == tag ) {
        return YES;
    }else{
        return NO;
    }
}
-(void)showIphoneItemWith:(BOOL)isShow{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    for (NSNumber *number in m_HIphoneImageItems){
        int tag = [number intValue];
		CCSimpleButton *item = (CCSimpleButton *)[buttonLayer getChildByTag:tag];
		if (item) {
            CGPoint pt = item.position;
            if (isShow) {
                pt.y = +RB_OFFSET;
            }else{
                pt.y = -RB_OFFSET;
            }
			[item stopAllActions];
			
			if (iPhoneRuningOnGame()) {
				item.scale = 1.15f;
			}else{
				item.scale = 1.0f;
			}
			
            [item runAction:[CCMoveTo actionWithDuration:MAINMENU_MOVE_DATA_TIME position:pt]];
		}
    }
    for (NSNumber *number in m_VIphoneImageItems){
        int tag = [number intValue];
		CCSimpleButton *item = (CCSimpleButton *)[buttonLayer getChildByTag:tag];
		if (item) {
            CGPoint pt = item.position;
            if (isShow) {
                pt.x = winSize.width-RB_OFFSET;
            }else{
                pt.x = winSize.width+RB_OFFSET;
            }
			[item stopAllActions];
			
			if (iPhoneRuningOnGame()) {
				item.scale = 1.15f;
			}else{
				item.scale = 1.0f;
			}
			
            [item runAction:[CCMoveTo actionWithDuration:MAINMENU_MOVE_DATA_TIME position:pt]];
		}
    }
}
-(void)closeMenu{
	
	//fix chao
	if (![self OpenMenu]) {
		return;
	}
	
	[MailList moveDown];
	
	[[Intro share]hideCurrenTips];
	
	CCSimpleButton *item = (CCSimpleButton *)[self getChildByTag:BT_CONTROL_TAG];
	
	CGPoint pt = item.position;
	CCAction *action = [CCRotateTo actionWithDuration:0.2f angle:0.0f];
	//end
	if (item) {
		//fix chao
		//[item setRotation:135.0f];
		[item setRotation:45.0f];
		//end
		[item runAction:action];
	}
	
	//
	[self setOpenMenu:false];
	//fix chao
	int i = 1;
	float d_time = MAINMENU_MOVE_DATA_TIME/[m_HImageItems count];
    
    CGPoint t_pt = pt;
    if ( iPhoneRuningOnGame() && buttonLayer ) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        float distanceX=0;
        //float distanceY=0;
        if (iPhoneRuningOnGame()) {
            distanceX=4;
            //distanceY=8;
        }
        t_pt.x = size.width - MENUITEM_STARTX-distanceX;
    }
	for (NSNumber *number in m_HImageItems) {
		int tag = [number intValue];
		CCSimpleButton *item = (CCSimpleButton *)[buttonLayer getChildByTag:tag];
		if (item) {
			[item stopAllActions];
			if (iPhoneRuningOnGame()) {
				item.scale=1.15f;
			}else{
				item.scale = 1.0f;
			}
			[item runAction:[CCSequence actions:[CCMoveTo actionWithDuration:i*d_time position:t_pt],[CCCallFuncN actionWithTarget:self selector:@selector(hideItemBackCall:)],nil]];
			i++;
		}
	}
	
	i = 1;
	d_time = MAINMENU_MOVE_DATA_TIME/[m_VImageItems count];
	for (NSNumber *number in m_VImageItems) {
		int tag = [number intValue];
		CCSimpleButton *item = (CCSimpleButton *)[buttonLayer getChildByTag:tag];
		if (item) {
			[item stopAllActions];
			if (iPhoneRuningOnGame()) {
				item.scale=1.15f;
			}else{
				item.scale = 1.0f;
			}
			[item runAction:[CCSequence actions:[CCMoveTo actionWithDuration:i*d_time position:pt],[CCCallFuncN actionWithTarget:self selector:@selector(hideItemBackCall:)],nil]];
			i++;
		}
	}
	CCSprite *backSpr = (CCSprite *)[self getChildByTag:MAINMENU_BACK_TAG];
	if (backSpr) {
		[backSpr runAction:[CCMoveTo actionWithDuration:MAINMENU_MOVE_DATA_TIME position:ccp(backSpr.position.x,-RB_OFFSET/2)]];
	}
    
	[self showIphoneItemWith:YES];
	//TODO
	//[[GameUI shared] openLowerLeftChat];
	
}
//end
/*
 按钮的回调函数，通过TAG去分别处理
 所有的跳转都在这里呼应
 */
-(void) menuCallbackBack: (id) sender{
	
	
	CCLOG(@"MainMenu:menuCallbackBack");
	
	[[GameSoundManager shared] click];
	
	if (self.visible == NO) {
		CCLOG(@"MainMenu is no visible!");
		return ;
	}
	
	//GameUi 如果不可以见，不给点击的～～
	if (![GameUI checkGameUI]) {
		return ;
	}
    
    if ([[Window shared] isHasWindow] /*&& iPhoneRuningOnGame()*/ ) {
        return ;
    }
	
	
	if (![WorldBossManager checkWorldBossTouch]) {
		return ;
	}
	
	if (![UnionBossManager checkAllyBossTouch]) {
		return ;
	}
	
	
	//    CCMenuItemImage *item = (CCMenuItemImage*)sender;
	CCSimpleButton *item = (CCSimpleButton*)sender;
    if (BT_CONTROL_TAG == [item tag]) {
        CCLOG(@"handle control button");
		[self endRaise];
		[self endUnfold];
		if ([self OpenMenu]) {
			[self closeMenu];
			[[LowerLeftChat share]EventOpenChat:nil];
		}else {
			[self unfoldMenu];
			[[Intro share]showCurrenTips];
		}
    }else if(BT_ROLE_TAG == [item tag]){
        CCLOG(@"handle role button");
		//
		[PlayerPanel setShowRole:0];
		[[Window shared] showWindow:PANEL_CHARACTER];
		//[[Window shared] showWindow:PANEL_JEWEL];
//		if (![[Game shared] getChildByTag:9584583495]) {
//			MessageContainer* cnt = [MessageContainer node];
//			[[Game shared] addChild:cnt z:INT32_MAX tag:9584583495];
//			cnt.channelId = CHANNEL_ALL;
//			cnt.position = ccp(100, 50);
//		}else{
//			[[Game shared] removeChildByTag:9584583495 cleanup:YES];
//		}
	}else if(BT_PHALANX_TAG == [item tag]){
		[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_Phalanx];
        [[Window shared] showWindow:PANEL_PHALANX];
        CCLOG(@"handle phalanx button");
    }else if(BT_HAMMER_TAG == [item tag]){
        CCLOG(@"handle hammer button");
		if([[GameConfigure shared]checkPlayerFunction:Unlock_mine]){
			[[Intro share] removeCurrenTipsAndNextStep:INTRO_ENTER_Mining];
		}else{
			[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_Hammer];
		}
		[[Window shared] showWindow:PANEL_HAMMER];
    }else if(BT_GUANXING_TAG == [item tag]){
        CCLOG(@"handle guan xing button");
		[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_GuangXing];
		[[Window shared] showWindow:PANEL_FATE];
    }else if(BT_WEAPON_TAG == [item tag]){
        CCLOG(@"handle weapon button");
		[[Intro share]removeCurrenTipsAndNextStep:INTRO_OPEN_Weapon];
		[[Window shared] showWindow:PANEL_WEAPON];
		if([Intro getCurrenStep]){}
		
		
    }else if(BT_RECRUIT_TAG == [item tag]){
        CCLOG(@"handle recruit button");
		[[Intro share] removeCurrenTipsAndNextStep:INTRO_OPEN_Recruit];
		[[Window shared] showWindow:PANEL_RECRUIT];
		
    }else if(BT_ZAZEN_TAG == [item tag]){
		[[PlayerSitManager shared]startSit];
        CCLOG(@"handle zazen button");
    }else if(BT_SETTING_TAG == [item tag]){
        CCLOG(@"handle setting button");
		//fix chao
		[[Window shared] showWindow:PANEL_SETTING];
    }else if(BT_FRIEND_TAG == [item tag]){
        CCLOG(@"handle friend button");
		//TODO test abyss
		//[AbyssManager enterAbyss];
		//[FishingManager enterFishing];
		[[Window shared] showWindow:PANEL_FRIEND];
    }else if(BT_TRADE_TAG == [item tag]){
        CCLOG(@"handle trade button");
		
    }else if(BT_UNION_TAG == [item tag]){
        CCLOG(@"handle union button");
        [[Window shared] showWindow:PANEL_UNION];
    }else if(BT_TIMEBOX_TAG==[item tag]){
		CCLOG(@"handle timebox button");
		[[Intro share]removeCurrenTipsAndNextStep:INTRO_OPEN_TimeBox];
		//停止移动....
		[[RoleManager shared].player stopMoveAndTask];
		//开始战斗的时候 不给进时光盒
		if (![MiningManager isMining] &&
			![FightManager isFighting]) {
			[TimeBox enterTimeBox];
		}
		//[Arena quitArena];
		
	}else if(BT_ARENA_TAG==[item tag]){
		
		[Arena enterArena];
		
		 
	}else if(MM_EXP_BG_TAG == [item tag]){
        [self showExe];
    }else if (BT_JEWEL_TAG == [item tag]) {
		[[Window shared] showWindow:PANEL_JEWEL];
	}
}
-(void)unfoldMenu{
	if (self.OpenMenu) {
		return ;
	}
	
	[MailList moveTop];
	
	[[GameUI shared] closeLowerLeftChat];
	CCSimpleButton *item = (CCSimpleButton *)[self getChildByTag:BT_CONTROL_TAG];
	CCAction *action = [CCRotateTo actionWithDuration:0.2f angle:45.0f];
	if (item) {
		[item setRotation:0.0f];
		[item runAction:action];
	}
	CGPoint pt = item.position;
	//
	if (iPhoneRuningOnGame()) {
		pt=ccp(pt.x-4, pt.y);
	}
	
	[self setOpenMenu:true];
	[self startUnfold:pt];
	
	CCSprite *backSpr = (CCSprite *)[self getChildByTag:MAINMENU_BACK_TAG];
	if (backSpr) {
		[backSpr runAction:[CCMoveTo actionWithDuration:MAINMENU_MOVE_DATA_TIME position:ccp(backSpr.position.x,RB_OFFSET/2)]];
	}
    //
    [self showIphoneItemWith:NO];
}


-(void)startUnfold:(CGPoint)pt{
	
	float distanceX=0;
	float distanceY=0;
	
	if (iPhoneRuningOnGame()) {
		distanceX=0;
		distanceY=2;
	}
	if ([m_HImageItems count] > 0) {
		for (int j=[m_HImageItems count] -1 ;;j--) {
			if (j>=0) {
				int tag = [[m_HImageItems objectAtIndex:j] intValue];
				CCSimpleButton *_object = (CCSimpleButton*)[buttonLayer getChildByTag:tag];
				_object.visible = NO;
				_object.position=pt;
				
			}else{
				break;
			}
		}
		int count = m_HImageItems.count;
		float rate = 1.0/count;
		
		CGPoint h_targetPt = ccpAdd(pt, ccp(-(count)*(MENUITEM_GAP + ITEM_RES_WIDTH)-distanceX, 0));
		int tag = [[m_HImageItems objectAtIndex:count-1] intValue];
		CCSimpleButton *h_head = (CCSimpleButton*)[buttonLayer getChildByTag:tag];
		h_head.visible = YES;
		[h_head stopAllActions];
		id act1 = [CCMoveTo actionWithDuration:rate*count position:h_targetPt];
		id act2 = [CCEaseElasticOut actionWithAction:act1 period:0.9];
		[h_head runAction:[CCSequence actions:act2,
						   [CCDelayTime actionWithDuration:2*1.0f/30.0f],
						   [CCCallFunc actionWithTarget:self selector:@selector(endUnfold)],nil]];
		[self schedule:@selector(unfold) interval:1.0f/30.0f];
	}
	
	if ([m_VImageItems count] > 0) {
		for (int j=[m_VImageItems count] -1 ;;j--) {
			if (j >= 0) {
				int tag = [[m_VImageItems objectAtIndex:j] intValue];
				CCSimpleButton *_object = (CCSimpleButton*)[buttonLayer getChildByTag:tag];
				_object.visible = NO;
				_object.position=pt;
			}else{
				break;
			}
		}
		int vCount = m_VImageItems.count;
		CGPoint v_targetPt = ccpAdd(pt, ccp(0, (ITEM_RES_HEIGHT + MENUITEM_GAP)*(vCount)+distanceY));
		int tag = [[m_VImageItems objectAtIndex:m_VImageItems.count-1] intValue];
		CCSimpleButton *v_head = (CCSimpleButton*)[buttonLayer getChildByTag:tag];
		v_head.visible = YES;
		id act3 = [CCMoveTo actionWithDuration:0.7 position:v_targetPt];
		id act4 = [CCEaseElasticOut actionWithAction:act3 period:0.9];
		[v_head stopAllActions];
		[v_head runAction:[CCSequence actions:act4,
						   [CCDelayTime actionWithDuration:2*1.0f/30.0f],
						   [CCCallFunc actionWithTarget:self selector:@selector(endRaise)],nil]];
		
		[self schedule:@selector(raise) interval:1.0f/30.0f];
	}
	
	
}
-(void)endRaise{
	[self unschedule:@selector(raise)];
}
-(void)raise{
	for (int j= m_VImageItems.count - 1  ;; j--) {
		if (j >= 1) {
			int tag1 = [[m_VImageItems objectAtIndex:j] intValue];
			int tag2 = [[m_VImageItems objectAtIndex:j-1] intValue];
			CCSimpleButton *_object1 = (CCSimpleButton*)[buttonLayer getChildByTag:tag1];
			CCSimpleButton *_object2 = (CCSimpleButton*)[buttonLayer getChildByTag:tag2];
			float dictance = ccpDistance(_object1.position, _object2.position);
			dictance = fabsf(dictance);
			if (_object1.visible && !_object2.visible) {
				if (dictance >= (ITEM_RES_HEIGHT + MENUITEM_GAP)) {
					CGPoint nPt = ccpAdd(_object1.position, ccp(0,-1*(ITEM_RES_HEIGHT + MENUITEM_GAP)));
					_object2.visible=YES;
					_object2.position=nPt;
				}
			}else if (_object1.visible && _object2.visible){
				if (dictance != (ITEM_RES_HEIGHT + MENUITEM_GAP)) {
					CGPoint nPt = ccpAdd(_object1.position, ccp(0,-1*(ITEM_RES_HEIGHT + MENUITEM_GAP)));
					_object2.position=nPt;
				}
			}
		}else{
			break;
		}
	}
}
-(void)endUnfold{
	[self unschedule:@selector(unfold)];
}
-(void)unfold{
	for (int j=[m_HImageItems count] - 2 ;;j--) {
		if (j >= 0) {
			int tag1 = [[m_HImageItems objectAtIndex:j] intValue];
			int tag2 = [[m_HImageItems objectAtIndex:j+1] intValue];
			CCSimpleButton *_object1 = (CCSimpleButton*)[buttonLayer getChildByTag:tag1];
			CCSimpleButton *_object2 = (CCSimpleButton*)[buttonLayer getChildByTag:tag2];
			float dictance = ccpDistance(_object1.position, _object2.position);
			dictance = fabsf(dictance);
			if (_object2.visible && !_object1.visible) {
				if (dictance >= (MENUITEM_GAP + ITEM_RES_WIDTH)) {
					CGPoint nPt = ccpAdd(_object2.position, ccp(MENUITEM_GAP + ITEM_RES_WIDTH, 0));
					_object1.visible=YES;
					_object1.position=nPt;
				}
			}else if (_object2.visible && _object1.visible){
				if (dictance != (MENUITEM_GAP + ITEM_RES_WIDTH)) {
					CGPoint nPt = ccpAdd(_object2.position, ccp(MENUITEM_GAP + ITEM_RES_WIDTH, 0));
					_object1.position=nPt;
				}
			}
		}else{
			break;
		}
	}
	
}
//图标右上角的提示按钮
-(void)showTips:(NSNotification*)_data{
	if ([[GameUI shared] checkPartVisible:GAMEUI_PART_RD]) {
		if (YES) {
			NSDictionary* dict = [NSDictionary dictionaryWithDictionary:_data.object];
			
			int c1 = [[dict objectForKey:@"arm_count"] intValue];
			int c2 = [[dict objectForKey:@"pos_count"] intValue];
			int c3 = [[dict objectForKey:@"role_count"] intValue];
			
			if (c1 > 0) {
				CCSimpleButton* bts = (CCSimpleButton*)[self getButtonWithTag:BT_WEAPON_TAG];
				if (bts != nil) {
					[bts showSuggest];
				}
			}
			
			if (c2 > 0) {
				CCSimpleButton* bts = (CCSimpleButton*)[self getButtonWithTag:BT_PHALANX_TAG];
				if (bts != nil) {
					[bts showSuggest];
				}
			}
			
			if (c3 > 0) {
				CCSimpleButton* bts = (CCSimpleButton*)[self getButtonWithTag:BT_RECRUIT_TAG];
				if (bts != nil) {
					[bts showSuggest];
				}
			}
			
		}
	}
}
//fix chao
-(void)showExe{
    if (exeSprite) {
        return;
    }
    
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	exeSprite = [CCLabelFX labelWithString:@""
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:getCommonFontName(FONT_1)
								  fontSize:12
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:2.0f];
	exeSprite.position = ccp(winSize.width/2,cFixedScale(6));
	[self addChild:exeSprite z:99];
	[self updateExp];
}
//end
-(void)onEnter
{
    [super onEnter];
    
	mainMenu = self;
	exeSprite = nil;
    
    [GameConnection addPost:ConnPost_updatePlayerInfo target:self call:@selector(updateExp)];
	[GameConnection addPost:Post_GameTipsHelper_message target:self call:@selector(showTips:)];
	
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    CCSprite *backSpr = getSpriteWithSpriteAndNewSize([CCSprite spriteWithFile:@"images/ui/button/bt_mainback.png"],CGSizeMake(size.width, RB_OFFSET));
    [backSpr setAnchorPoint:ccp(0.5f, 0.5f)];
	[backSpr setPosition:ccp(size.width/2, RB_OFFSET/2)];
	[self addChild:backSpr z:0 tag:MAINMENU_BACK_TAG];
    
    CCSprite *mSpr = [CCSprite spriteWithFile:@"images/ui/button/bt_control_face.png"];
	
    [self addChild:mSpr z:10];
    
    [self setOpenMenu:true];
    [self initAllButton];
    
    buttonLayer = [CCLayer node];
    [self addChild:buttonLayer z:5];
    
    controlButton = [CCSimpleButton spriteWithFile:[self getImage:BT_CONTROL_TAG]
                                            select:[self getImage:BT_CONTROL_TAG]
                                            target:self
                                              call:@selector(menuCallbackBack:)
                                          priority:-6];
	CCSimpleButton *controlButtonreg=[CCSimpleButton spriteWithSize:controlButton.contentSize block:^{
		[self menuCallbackBack:controlButton];
	}];
	
	if (iPhoneRuningOnGame()) {
		controlButton.scale = 1.35f;
		controlButtonreg.scale=1.35f;
		controlButtonreg.scale=3.0f;
		mSpr.scale=1.15f;
		[mSpr setPosition:ccp(size.width - RB_OFFSET+5, RB_OFFSET)];
		controlButton.position = ccp(size.width-RB_OFFSET+5, RB_OFFSET);
		[controlButtonreg setPosition:ccp(size.width-RB_OFFSET+5, RB_OFFSET)];
	}else{
		controlButton.scale = 1.2f;
		controlButtonreg.scale=3.0f;
		[mSpr setPosition:ccp(size.width - RB_OFFSET, RB_OFFSET)];
		controlButton.position = ccp(size.width-RB_OFFSET, RB_OFFSET);
		[controlButtonreg setPosition:ccp(size.width-RB_OFFSET, RB_OFFSET)];
	}
	
	
	[self addChild:controlButtonreg z:21];
    [self addChild:controlButton z:20 tag:BT_CONTROL_TAG];
    
    //fix chao
	/*
	 CCSprite *exp_bg = [CCSprite spriteWithFile:@"images/ui/panel/mainmenu_exp_bg.png"];
	 
	 [self addChild:exp_bg];
	 exp_bg.anchorPoint = ccp(0.5,0);
	 exp_bg.position = ccp(size.width/2,0);
	 exp_bg.scale = size.width/exp_bg.contentSize.width;
	 */
    CCSimpleButton *exp_bg_button = [CCSimpleButton spriteWithFile:@"images/ui/panel/mainmenu_exp_bg.png"
                                                            select:@"images/ui/panel/mainmenu_exp_bg.png"
                                                            target:self
                                                              call:@selector(menuCallbackBack:)
                                                          priority:-3];
	
	[self addChild:exp_bg_button];
    exp_bg_button.tag = MM_EXP_BG_TAG;
    exp_bg_button.anchorPoint = ccp(0.5,0);
    exp_bg_button.position = ccp(size.width/2,0);
	exp_bg_button.scale = size.width/exp_bg_button.contentSize.width;
    //
    CCSprite *exp_body = [CCSprite spriteWithFile:@"images/ui/panel/mainmenu_exp_2.png"];
    [self addChild:exp_body];
    exp_body.tag = MM_EXP_BODY_TAG;
    exp_body.scaleX = 0.0;
    exp_body.anchorPoint = ccp(0,0);
    exp_body.position = ccp(0,0);
    //
    CCSprite *exp_end = [CCSprite spriteWithFile:@"images/ui/panel/mainmenu_exp_1.png"];
    [self addChild:exp_end];
    exp_end.tag = MM_EXP_END_TAG;
    exp_end.anchorPoint = ccp(0,0);
    exp_end.position = ccp(exp_body.contentSize.width*exp_body.scaleX,0);
    //
	
    CCSprite *exp_bf = [CCSprite spriteWithFile:@"images/ui/panel/mainmenu_exp_before.png"];
    [self addChild:exp_bf];
    exp_bf.anchorPoint = ccp(0.5,0);
    exp_bf.position = ccp(size.width/2,0);
	exp_bf.scale = size.width/exp_bf.contentSize.width;
    
    [self updateExp];
    
    if ([self OpenMenu]) {
		if (controlButton) {
			[controlButton setRotation:45.0f];
		}
		
        [self loadMenuItemList];
    }
    //fix chao
    [self showExe];
    //end
}

-(void)onExit
{
	
    CCLOG(@"MainMenu OnExit!!!!!!!!!!!!");
	
	if (exeSprite) {
        [exeSprite removeFromParentAndCleanup:YES];
        exeSprite = nil;
    }
	
	mainMenu = nil;
	
	[GameConnection removePostTarget:self];
	
	[m_HImageItems release];
	[m_VImageItems release];
    [m_HIphoneImageItems release];
	[m_VIphoneImageItems release];
    
	[super onExit];
	
}
-(void) dealloc
{
    [super dealloc];
}

@end
