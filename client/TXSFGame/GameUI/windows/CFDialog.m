//
//  CFDialog.m
//  TXSFGame
//
//  Created by shoujun huang on 12-12-1.
//  Copyright 2012年 chao chen. All rights reserved.
//

#import "CFDialog.h"
#import "Config.h"
#import "StretchingImg.h"

@implementation CFDialog

@synthesize isCenterPoint;
@synthesize contentRect;
@synthesize contentLabel;
@synthesize args;
@synthesize menu;
@synthesize delegate = delegate_;

+(CFDialog*)create:(id)target background:(int)_type
{
	CFDialog *dialog = [[[CFDialog alloc] initWithDelegate:target background:_type] autorelease];
	return dialog;
}
+(CFDialog*)create:(id)target confirmSelector:(SEL)confirmSelector cancelSelector:(SEL)cancelSelector arg:(NSDictionary *)_dict
{
	CFDialog *dialog = [[[CFDialog alloc] initWithTarget:target confirmSelector:confirmSelector cancelSelector:cancelSelector] autorelease];
	if (dialog) {
		dialog.args=_dict;//传递参数
	}
	return dialog;
}
-(id)initWithDelegate:(id)_d background:(int)_type
{
	if (self = [super init]) {
		CCDirector *director = [CCDirector sharedDirector];
        [[director touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority swallowsTouches:YES];
		self.touchEnabled=YES;
		//菜单
		menu = [CCMenu node];
        menu.ignoreAnchorPointForPosition = YES;
        menu.position = CGPointZero;
        [self addChild:menu z:INT_MAX];
		self.delegate = _d;
		
		if (_type == 0) {
			CCSprite *background = [CCSprite spriteWithFile:@"images/ui/panel/p8.png"];
			if (background) {
				self.contentSize = background.contentSize;
				background.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
				[self addChild:background];
			}
		}else if(_type == 1){
			//TODO
			//fix chao
			
			CCSprite *background =[StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(592) height:cFixedScale(298) capx:cFixedScale(8) capy:cFixedScale(8)];
			if (background) {
				self.contentSize = background.contentSize;
				background.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
				[self addChild:background];
			}
			//end
		}
	}
	return self;
}
-(id)initWithTarget:(id)target confirmSelector:(SEL)confirmSelector cancelSelector:(SEL)cancelSelector;
{
    if (self = [super init]) {
        
        CCDirector *director = [CCDirector sharedDirector];
        [[director touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority swallowsTouches:YES];
        
        _target = target;
        _confirmSelector = confirmSelector;
        _cancelSelector = cancelSelector;
        
        CCSprite *background = [CCSprite spriteWithFile:@"images/ui/panel/p8.png"];
        self.contentSize = background.contentSize;
        background.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
        [self addChild:background];
        //fix chao
//        NSArray *array = getLabelSprites(@"images/ui/button/bt_background.png", @"images/ui/button/bt_background.png", @"确 认", 20, ccc4(65,197,186, 255), ccc4(65,197,186, 255));
//        NSArray *array2 = getLabelSprites(@"images/ui/button/bt_background.png", @"images/ui/button/bt_background.png", @"取 消", 20, ccc4(65,197,186, 255), ccc4(65,197,186, 255));
		NSArray *array = getBtnSpriteWithStatus(@"images/ui/button/bt_ok");
		NSArray *array2 = getBtnSpriteWithStatus(@"images/ui/button/bt_cancel");
		//end
        CCMenuItemImage *bt1 = [CCMenuItemImage itemWithNormalSprite:[array objectAtIndex:0]
                                                      selectedSprite:[array objectAtIndex:1]
                                                      disabledSprite:nil
                                                              target:self
                                                            selector:@selector(menuCallbackBack:)];
        bt1.tag = BT_CONFIRM_TAG;
        
        CCMenuItemImage *bt2 = [CCMenuItemImage itemWithNormalSprite:[array2 objectAtIndex:0]
                                                      selectedSprite:[array2 objectAtIndex:1]
                                                      disabledSprite:nil
                                                              target:self
                                                            selector:@selector(menuCallbackBack:)];
        bt2.tag = BT_CANCEL_TAG;
        
        menu = [CCMenu menuWithItems:bt1,bt2, nil];
        menu.ignoreAnchorPointForPosition = YES;
        menu.position = CGPointZero;
        [self addChild:menu z:1];
        bt1.anchorPoint=ccp(0, 0.5);
        bt2.anchorPoint=ccp(0, 0.5);
        bt1.position=ccp(96, 50);
        bt2.position=ccp(340, 50);
        
        contentRect = CGRectMake(50, 90, 483, 160);
        self.contentLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:16 dimensions:CGSizeMake(contentRect.size.width, contentRect.size.height) hAlignment:kCCTextAlignmentLeft];
        contentLabel.anchorPoint = ccp(0, 1);
        contentLabel.color = ccc3(237, 226, 205);
        contentLabel.position = ccp(contentRect.origin.x, contentRect.origin.y + contentRect.size.height);
        [self addChild:contentLabel];
    }
    
    return self;
}

-(id)initWithTarget:(id)target confirmSelector:(SEL)confirmSelector
{
    return [self initWithTarget:target confirmSelector:confirmSelector cancelSelector:nil];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}
-(void)menuCallbackBack:(id)sender
{
    CCMenuItemImage *item = (CCMenuItemImage *)sender;
    if (item.tag == BT_CONFIRM_TAG) {
        // 确认
        if (_target && [_target respondsToSelector:_confirmSelector]) {
			if (args) {
				 [_target performSelector:_confirmSelector withObject:args];
			}
			else {
				 [_target performSelector:_confirmSelector];
			}
        }
    }
    else if (item.tag == BT_CANCEL_TAG) {
        // 取消
        if (_cancelSelector && _target && [_target respondsToSelector:_cancelSelector]) {
			if (args) {
				 [_target performSelector:_cancelSelector withObject:args];
			}
			else {
				 [_target performSelector:_cancelSelector];
			}
        }
    }
    [self stopAllActions];
    [self removeFromParentAndCleanup:YES];
}
-(void)onEnter
{
	[super onEnter];
	if (delegate_) {
		if ([delegate_ respondsToSelector:@selector(onDialogEnter:)]) {
			[delegate_ onDialogEnter:self];
		}
	}
	
	// 位置为屏幕中心
	if (isCenterPoint) {
		CGSize winSize = [CCDirector sharedDirector].winSize;
		CGPoint finalPoint = CGPointMake(winSize.width/2 - self.contentSize.width/2,
										 winSize.height/2 - self.contentSize.height/2);
		CGPoint currentPoint = [self.parent convertToWorldSpace:self.position];
		
		self.position = ccpAdd(self.position, ccpSub(finalPoint, currentPoint));
	}
}
-(void)onExit
{
	[super onExit];
	if (args) {
		[args release];
		args = nil;
	}
	if (delegate_) {
		delegate_ = nil;
	}
	CCDirector *director = [CCDirector sharedDirector];
    [[director touchDispatcher] removeDelegate:self];
}
@end

