//
//  WindowComponent.m
//  TXSFGame
//
//  Created by Soul on 13-5-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "WindowComponent.h"
#import "CCNode+AddHelper.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "Config.h"
#import "InfoAlert.h"

static inline NSString* getBackgroundImage(WINDOW_TYPE _type){
	if (iPhoneRuningOnGame()) {
		if (_type == PANEL_FRIEND) {
			return @"images/ui/wback/p2.png";
		} else if (_type == PANEL_RANK) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_FATEROOM) {
			return @"images/ui/wback/GXRBack.jpg";
		}else if(_type== PANEL_CHAT){
			return nil;
		}
		return @"images/ui/wback/fun_bg.jpg";
	} else {
		if (_type == PANEL_CHARACTER) {
			return @"images/ui/panel/character_panel/bg.png";
		} else if (_type == PANEL_PHALANX) {
			return @"images/ui/panel/p4.png";
		} else if (_type == PANEL_RECRUIT) {
			return @"images/ui/panel/p4.png";
		} else if (_type == PANEL_SACRIFICE) {
			return @"images/ui/panel/p4.png";
		} else if (_type == PANEL_WEAPON) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_HAMMER) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_FATE) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_UNION) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_EXCHANGE) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_REWARD) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_ACTIVITY) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_DAILY) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_UNION_Cat) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_UNION_Engrave) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_TASK) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_SETTING) {
			return @"images/ui/panel/p3.png";
		} else if (_type == PANEL_CAR) {
			return @"images/ui/panel/p1.png";
		} else if (_type == PANEL_FISH_Box) {
			return @"images/ui/panel/p4.png";
		} else if (_type == PANEL_FRIEND) {
			return @"images/ui/panel/p2.png";
		} else if (_type == PANEL_BUSINESSMAN) {
			return @"images/ui/panel/p4.png";
		} else if (_type == PANEL_RANK) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_ITEMSYNTHESIZE) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_FATEROOM) {
			return @"images/ui/panel/GXRBack.jpg";
		} else if (_type == PANEL_JEWEL_buy) {
			return @"images/ui/panel/p4.png";	// 暂用神秘商店的
		} else if (_type == PANEL_CASHCOW) {
			return @"images/ui/panel/p5.png";
		} else if (_type == PANEL_JEWEL) {
			return @"images/ui/panel/character_panel/bg.png";
		} else if (_type == PANEL_JEWEL_set) {
			return @"images/ui/panel/character_panel/bg.png";
		} else if (_type == PANEL_JEWEL_mine) {
			return @"images/ui/panel/character_panel/bg.png";
		} else if (_type == PANEL_JEWEL_polish) {
			return @"images/ui/panel/character_panel/bg.png";
		} else if (_type == PANEL_JEWEL_refine) {
			return @"images/ui/panel/character_panel/bg.png";
		} else if (_type == PANEL_ROLE_CULTIVATE) {
			return @"images/ui/panel/p5.png";
		}else if (_type == PANEL_ROLE_UP) {
			return @"images/ui/panel/p5.png";
		}else if(_type== PANEL_CHAT){
			return nil;
		}else if(_type== PANEL_CHAT_BIG){
			return @"images/ui/panel/p5.png";
		}
	}
	if (_type == PANEL_JEWEL) {
		return @"images/ui/panel/character_panel/bg.png";
	}
	
	return nil;
}

static inline NSString* getCaptionImage(WINDOW_TYPE _type){
	if (_type == PANEL_CHARACTER) {
		return @"images/ui/panel/t8.png";
	} else if (_type == PANEL_PHALANX) {
		return @"images/ui/panel/t18.png";
	} else if (_type == PANEL_RECRUIT) {
		return @"images/ui/panel/t3.png";
	} else if (_type == PANEL_SACRIFICE) {
		return @"images/ui/panel/t7.png";
	} else if (_type == PANEL_WEAPON) {
		return @"images/ui/panel/t2.png";
	} else if (_type == PANEL_HAMMER) {
		return @"images/ui/panel/t4.png";
	} else if (_type == PANEL_FATE) {
		return @"images/ui/panel/t5.png";
	} else if (_type == PANEL_UNION) {
		return @"images/ui/panel/t14.png";
	} else if (_type == PANEL_EXCHANGE) {
		return @"images/ui/panel/t67.png";
	} else if (_type == PANEL_REWARD) {
		return @"images/ui/panel/t71.png";
	} else if (_type == PANEL_ACTIVITY) {
		return @"images/ui/panel/t6.png";
	} else if (_type == PANEL_DAILY) {
		return @"images/ui/panel/t11.png";
	} else if (_type == PANEL_UNION_Cat) {
		return @"images/ui/union/title-cat.png";
	} else if (_type == PANEL_UNION_Engrave) {
		return @"images/ui/union/title.png";
	} else if (_type == PANEL_TASK) {
		return @"images/ui/panel/t10.png";
	} else if (_type == PANEL_SETTING) {
		return @"images/ui/panel/t17.png";
	} else if (_type == PANEL_CAR) {
		return @"images/ui/car/title.png";
	} else if (_type == PANEL_FISH_Box) {
		return @"images/ui/panel/t66.png";
	} else if (_type == PANEL_FRIEND) {	// 背景图包括标题了
		return nil;
	} else if (_type == PANEL_BUSINESSMAN) {
		return @"images/ui/panel/t13.png";
	} else if (_type == PANEL_RANK) {
		return @"images/ui/panel/t15.png";
	} else if (_type == PANEL_ITEMSYNTHESIZE) {
		return @"images/ui/panel/t16.png";
	} else if (_type == PANEL_FATEROOM) {
		return @"images/ui/panel/t73.png";
	} else if (_type == PANEL_JEWEL_buy) {
		return @"images/ui/panel/t13.png";
	}else if (_type == PANEL_CASHCOW) {
		return @"images/ui/panel/t74.png";	
	}else if (_type == PANEL_JEWEL) {
		return @"images/ui/panel/t80.png";
	}else if (_type == PANEL_JEWEL_set) {
		return @"images/ui/panel/t76.png";
	}else if (_type == PANEL_JEWEL_mine) {
		return @"images/ui/panel/t77.png";
	}else if (_type == PANEL_JEWEL_polish) {
		return @"images/ui/panel/t79.png";
	}else if (_type == PANEL_JEWEL_refine) {
		return @"images/ui/panel/t78.png";
	}else if(_type == PANEL_ROLE_CULTIVATE){
        return @"images/ui/panel/t74.png";	
    }else if(_type == PANEL_ROLE_UP){
        return @"images/ui/panel/t75.png";
    }
	return nil;
}

static inline BOOL checkHelper(WINDOW_TYPE _type){
	if (_type == PANEL_PHALANX ||
		_type == PANEL_RECRUIT ||
		_type == PANEL_SACRIFICE ||
		_type == PANEL_WEAPON ||
		_type == PANEL_HAMMER ||
		_type == PANEL_FATE ||
		_type == PANEL_UNION ||
		_type == PANEL_DAILY ||
		_type == PANEL_UNION_Engrave ||
		_type == PANEL_TASK ||
		_type == PANEL_CAR ||
		_type == PANEL_BUSINESSMAN ||
		_type == PANEL_FATEROOM ||
        _type == PANEL_CASHCOW ||
		_type == PANEL_JEWEL ||
		_type == PANEL_JEWEL_set ||
		_type == PANEL_JEWEL_mine ||
		_type == PANEL_JEWEL_polish ||
		_type == PANEL_JEWEL_refine ||
        //_type == PANEL_ROLE_CULTIVATE ||
        _type == PANEL_ROLE_UP
        ) {
		return YES;
	}
	return NO;
}

static inline RuleType getRuleTypeByWindow(WINDOW_TYPE _type){
	if (_type == PANEL_PHALANX) {
		return RuleType_phalanxSystem;
	} else if (_type == PANEL_RECRUIT) {
		return RuleType_recruit;
	} else if (_type == PANEL_SACRIFICE) {
		return RuleType_sacrifice;
	} else if (_type == PANEL_WEAPON) {
		return RuleType_weaponSystem;
	} else if (_type == PANEL_HAMMER) {
		return RuleType_strengthen;
	} else if (_type == PANEL_FATE) {
		return RuleType_guanxingSystem;
	} else if (_type == PANEL_UNION) {
		return RuleType_unionSystem;
	} else if (_type == PANEL_DAILY) {
		return RuleType_dailySystem;
	} else if (_type == PANEL_UNION_Engrave) {
		return RuleType_engrave;
	} else if (_type == PANEL_TASK) {
		return RuleType_offerTask;
	} else if (_type == PANEL_CAR) {
		return RuleType_car;
	} else if (_type == PANEL_BUSINESSMAN) {
		return RuleType_shop;
	} else if (_type == PANEL_FATEROOM) {
		return RuleType_starRoom;
	}else if (_type == PANEL_CASHCOW) {
		return RuleType_ctree;
	}else if (_type == PANEL_JEWEL) {
		return RuleType_jewelMain;
	}else if (_type == PANEL_JEWEL_set) {
		return RuleType_jewelSet;
	}else if (_type == PANEL_JEWEL_mine) {
		return RuleType_jewelMine;
	}else if (_type == PANEL_JEWEL_polish) {
		return RuleType_jewelPolish;
	}else if (_type == PANEL_JEWEL_refine) {
		return RuleType_jewelRefine;
	}else if (_type == PANEL_ROLE_UP) {
		return RuleType_roleUp;
	}
	return 0;
}


@implementation WindowComponent

@synthesize windowType;
@synthesize touchEnabled = __touchEnabled;
@synthesize touchPriority = __touchPriority;

-(id)init{
	if ((self = [super init]) != nil) {
		self.ignoreAnchorPointForPosition = NO;
		self.anchorPoint = ccp(0.5, 0.5);
		
		__touchEnabled = NO;
		__touchPriority = 0;
		_closePy = -150;
		
	}
	return self;
}



-(void)onEnter{
	[super onEnter];
	
	CGSize size = [CCDirector sharedDirector].winSize;
	[self setPosition:ccp(size.width/2, size.height/2)];
	
	[self freeWindow];
	[self initBackground];
}

-(void)onExit{
	[self freeWindow];

	if (__touchEnabled) {
		CCDirector *director = [CCDirector sharedDirector];
		[[director touchDispatcher] removeDelegate:self];
	}
	[GameConnection post:ConnPost_window_close object:[NSNumber numberWithInt:self.windowType]];
	[super onExit];
}

-(void) setTouchEnabled:(BOOL)enabled{
	if( __touchEnabled != enabled ) {
		__touchEnabled = enabled;
		
		CCDirector *director = [CCDirector sharedDirector];
		if( enabled ){
			[[director touchDispatcher] addTargetedDelegate:self
												   priority:__touchPriority
											swallowsTouches:YES];
		}else {
			[[director touchDispatcher] removeDelegate:self];
		}
	}
}

-(void) setTouchPriority:(NSInteger)touchPriority___{
	if( __touchPriority != touchPriority___ ) {
		__touchPriority = touchPriority___;
		if( __touchEnabled) {
			[self setTouchEnabled:NO];
			[self setTouchEnabled:YES];
		}
	}
}


-(void)freeWindow{
	if (_background != nil) {
		[_background removeFromParentAndCleanup:YES];
		_background = nil;
	}
	if (_closeBnt != nil) {
		[_closeBnt removeFromParentAndCleanup:YES];
		_closeBnt = nil;
	}
}

-(NSString*)getBackgroundPath{
	return getBackgroundImage(self.windowType);
}

-(NSString*)getCaptionPath{
	return getCaptionImage(self.windowType);
}

-(void)initBackground{
	//NSString* path = getBackgroundImage(self.windowType);
	NSString* path = [self getBackgroundPath];
	if (path != nil) {
		
		_background = [self getBackground:path];
		if (_background) {
			self.contentSize = _background.contentSize;
			
			[self Category_AddChildToCenter:_background z:-1];
			
			
			path = nil;
			//path = getCaptionImage(self.windowType);
			path = [self getCaptionPath];
			if (path) {
				CCSprite *title = [CCSprite spriteWithFile:path];
				if (title) {
					if (iPhoneRuningOnGame()) {
						title.scale = 1.19f;
					}
					title.position = [self getCaptionPosition];
					[self addChild:title z:[self getAboutZIndex]];
				}
			}
			
			_closeBnt = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"
														  select:nil
														  target:self
															call:@selector(closeWindow)
														priority:_closePy];
			if (iPhoneRuningOnGame()) {
				_closeBnt.scale = 0.95f;
			}
			_closeBnt.position = [self getClosePosition];
			[self addChild:_closeBnt z:[self getAboutZIndex]];
			
			if (checkHelper(self.windowType)) {
				RuleButton *ruleButton = [RuleButton node];
				if (iPhoneRuningOnGame()) {
					ruleButton.scale = 0.95f;
				}
				ruleButton.position = ccp(_closeBnt.position.x- cFixedScale(WINDOW_RULE_OFF_X * ruleButton.scale)-cFixedScale(6), _closeBnt.position.y-cFixedScale(WINDOW_RULE_OFF_Y* ruleButton.scale));
				ruleButton.type = getRuleTypeByWindow(self.windowType);
				ruleButton.priority = -129;
				[self addChild:ruleButton z:[self getAboutZIndex]];
				
			}
			
		}
	}
}

-(void)closeWindow{
	[[Window shared] removeWindow:self.windowType];
}

-(CCSprite*)getBackground:(NSString*)path
{
	return [CCSprite spriteWithFile:path];
}

-(CGPoint)getCaptionPosition{
	if (iPhoneRuningOnGame()) {
		return ccp(self.contentSize.width/2,
							 self.contentSize.height-18);
	}else{
		return  ccp(self.contentSize.width/2,
							 self.contentSize.height-cFixedScale(10));
	}
}

-(CGPoint)getClosePosition
{
	if (iPhoneRuningOnGame()) {
		CGPoint pt = ccp(self.contentSize.width*self.scaleX - _closeBnt.contentSize.width* _closeBnt.scaleX/2-ccpIphone4X(0),
						 self.contentSize.height*self.scaleY-_closeBnt.contentSize.height*_closeBnt.scaleY/2 );

		CGSize size = [CCDirector sharedDirector].winSize;
		if (self.contentSize.width < size.width) {
			pt = ccp(self.contentSize.width*self.scaleX - _closeBnt.contentSize.width *_closeBnt.scaleX/2,
					 self.contentSize.height*self.scaleY-_closeBnt.contentSize.height* _closeBnt.scaleY/2);
		}
		return pt;
	}else{
		return ccp(self.contentSize.width - cFixedScale(44),
				   self.contentSize.height - cFixedScale(42));
	}
}

-(int)getAboutZIndex
{
	return 100;
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCLOG(@"WindowComponent->ccTouchBegan");
	return YES;
}


@end
