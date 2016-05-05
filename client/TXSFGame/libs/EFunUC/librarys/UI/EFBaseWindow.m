//
//  EFBaseWindow.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFBaseWindow.h"
#import "EFUIWindow.h"
#import <QuartzCore/QuartzCore.h>
#import "EFUserAction.h"

@interface UITextFieldPlaceholder : UITextField

@end

@implementation UITextFieldPlaceholder

-(void)drawPlaceholderInRect:(CGRect)rect
{
    [[UIColor grayColor] setFill];
    [[self placeholder] drawInRect:rect withFont:[UIFont systemFontOfSize:20]];
}

@end

@implementation EFBaseWindow

-(id)initWithFrame:(CGRect)frame{
	
	if((self = [super initWithFrame:frame])){
		
		//self.userInteractionEnabled = YES;
		//self.backgroundColor = [UIColor clearColor];
		//self.alpha = 1;
		//self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		/*
		self.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
                                    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin);
        
		UIColor * whiteColor = [UIColor colorWithRed:0.816 green:0.788 blue:0.788 alpha:1.000];
		self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8f];
		self.layer.borderColor = whiteColor.CGColor;
		self.layer.borderWidth = 2.0f;
		self.layer.cornerRadius = 10.f;
		*/
		isTouch = NO;
	}
    return self;
}

-(void)dealloc{
    [NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

+(EFBaseWindow*)getWindow:(NSString*)name{
	Class targetClass = NSClassFromString(name);
	if(targetClass){
		CGRect winRect = [EFUIWindow getWindowRect];
		CGRect rect = CGRectMake((winRect.size.width-480)/2, 
								 (winRect.size.height-320)/2, 
								 480, 320);
		
		EFBaseWindow * window = [[targetClass alloc] initWithFrame:rect];
		[window autorelease];
		[window show];
		return window;
	}
	return nil;
}

+(UILabel*)getLabel{
	UILabel * label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	label.textColor = EF_FONT_COLOR;
	
	label.backgroundColor = [UIColor clearColor];
	//label.backgroundColor = [UIColor whiteColor];
	
	label.adjustsFontSizeToFitWidth = YES;
	label.textAlignment = UITextAlignmentCenter;
	label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	label.font = [UIFont systemFontOfSize:28];
	label.numberOfLines = 0;
	return label;
}
+(UIButton*)getButton:(NSString*)name{
	UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
	[btn setFrame:CGRectMake(0,0,234,53)];
	[btn setImage:[UIImage imageNamed:@"ef_resources/btn_base_1.png"] forState:UIControlStateNormal];
	[btn setImage:[UIImage imageNamed:@"ef_resources/btn_base_2.png"] forState:UIControlStateHighlighted];
	UILabel * label = [EFBaseWindow getLabel];
	label.frame = CGRectMake(0,0,234,53);
	label.font = [UIFont systemFontOfSize:26];
	label.textAlignment = UITextAlignmentCenter;
	label.text = name;
	//label.textColor = EF_FONT_COLOR;
	label.textColor = [UIColor whiteColor];
	[btn addSubview:label];
	return btn;
}
+(UIButton*)getSmallButton:(NSString*)name{
	UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
	[btn setFrame:CGRectMake(0,0,150,53)];
	[btn setImage:[UIImage imageNamed:@"ef_resources/btn_small_1.png"] forState:UIControlStateNormal];
	[btn setImage:[UIImage imageNamed:@"ef_resources/btn_small_2.png"] forState:UIControlStateHighlighted];
	UILabel * label = [EFBaseWindow getLabel];
	label.frame = CGRectMake(0,0,150,53);
	label.font = [UIFont systemFontOfSize:26];
	label.textAlignment = UITextAlignmentCenter;
	label.text = name;
	//label.textColor = EF_FONT_COLOR;
	label.textColor = [UIColor whiteColor];
	[btn addSubview:label];
	return btn;
}

+(UITextField*)getTextField{
	UITextField * textField = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
	textField.font = [UIFont systemFontOfSize:20];
	textField.textColor = EF_FONT_COLOR;
	textField.textAlignment = NSTextAlignmentLeft;
	
	//textField.backgroundColor = [UIColor blackColor];
	
	textField.clearsOnBeginEditing = NO;
	textField.adjustsFontSizeToFitWidth = YES;
	return textField;
}

+(UITextField*)getTextFieldPlaceholder{
	UITextFieldPlaceholder * textField = [[[UITextFieldPlaceholder alloc] initWithFrame:CGRectZero] autorelease];
	textField.font = [UIFont systemFontOfSize:20];
	textField.textColor = EF_FONT_COLOR;
	textField.textAlignment = NSTextAlignmentLeft;
	
	//textField.backgroundColor = [UIColor blackColor];
	
	textField.clearsOnBeginEditing = NO;
	textField.adjustsFontSizeToFitWidth = YES;
	return textField;
}

-(void)show{
	
	
}

-(void)showBackground:(NSString*)bgFile{
	UIImageView * bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 480, 320)];
	bg.image = [UIImage imageNamed:bgFile];
	[self addSubview:bg];
	[bg release];
}

-(void)showCloseBtn{
	UIButton * btn_close = [UIButton buttonWithType:UIButtonTypeCustom];
	[btn_close setFrame:CGRectMake(430,6,46,46)];
	[btn_close setImage:[UIImage imageNamed:@"ef_resources/btn_close.png"] forState:UIControlStateNormal];
	[btn_close addTarget:self action:@selector(onClose:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_close];
}

-(void)onClose:(id)sender{
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[EFUIWindow closeWindows];
}

-(void)showReturnBtn{
	UIButton * btn_return = [UIButton buttonWithType:UIButtonTypeCustom];
	[btn_return setFrame:CGRectMake(6,6,46,46)];
	[btn_return setImage:[UIImage imageNamed:@"ef_resources/btn_return.png"] forState:UIControlStateNormal];
	[btn_return addTarget:self action:@selector(onReturn:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_return];
}
-(void)onReturn:(id)sender{
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[EFUIWindow returnWindow];
}

-(void)showTitle:(NSString*)title{
	UILabel * label = [EFBaseWindow getLabel];
	label.frame = CGRectMake(50,18,380,30);
	label.font = [UIFont systemFontOfSize:28];
	[label setText:title];
	[self addSubview:label];
}

-(void)showTabs:(int)index{
	
	UIButton * tab_1 = [UIButton buttonWithType:UIButtonTypeCustom];
	UIButton * tab_2 = [UIButton buttonWithType:UIButtonTypeCustom];
	UIButton * tab_3 = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[tab_1 setTag:0];
	[tab_1 setFrame:CGRectMake(50,(320-68),106,61)];
	[tab_1 setImage:[UIImage imageNamed:@"ef_resources/tab_1_0.png"] forState:UIControlStateNormal];
	[tab_1 setImage:[UIImage imageNamed:@"ef_resources/tab_1_1.png"] forState:UIControlStateHighlighted];
	[tab_1 setImage:[UIImage imageNamed:@"ef_resources/tab_1_1.png"] forState:UIControlStateSelected];
	
	[tab_2 setTag:1];
	[tab_2 setFrame:CGRectMake(192,(320-68),106,61)];
	[tab_2 setImage:[UIImage imageNamed:@"ef_resources/tab_2_0.png"] forState:UIControlStateNormal];
	[tab_2 setImage:[UIImage imageNamed:@"ef_resources/tab_2_1.png"] forState:UIControlStateHighlighted];
	[tab_2 setImage:[UIImage imageNamed:@"ef_resources/tab_2_1.png"] forState:UIControlStateSelected];
	
	[tab_3 setTag:2];
	[tab_3 setFrame:CGRectMake(330,(320-68),106,61)];
	[tab_3 setImage:[UIImage imageNamed:@"ef_resources/tab_3_0.png"] forState:UIControlStateNormal];
	[tab_3 setImage:[UIImage imageNamed:@"ef_resources/tab_3_1.png"] forState:UIControlStateHighlighted];
	[tab_3 setImage:[UIImage imageNamed:@"ef_resources/tab_3_1.png"] forState:UIControlStateSelected];
	
	[tab_1 addTarget:self action:@selector(onTab:) forControlEvents:UIControlEventTouchUpInside];
	[tab_2 addTarget:self action:@selector(onTab:) forControlEvents:UIControlEventTouchUpInside];
	[tab_3 addTarget:self action:@selector(onTab:) forControlEvents:UIControlEventTouchUpInside];
	
	[self addSubview:tab_1];
	[self addSubview:tab_2];
	[self addSubview:tab_3];
	
	if(index==0) [tab_1 setSelected:YES];
	if(index==1) [tab_2 setSelected:YES];
	if(index==2) [tab_3 setSelected:YES];
	
	UILabel * label_1 = [EFBaseWindow getLabel];
	label_1.frame = CGRectMake(50,(320-36),106,30);
	label_1.font = [UIFont systemFontOfSize:20];
	label_1.text = @"帐号信息";
	[self addSubview:label_1];
	
	UILabel * label_2 = [EFBaseWindow getLabel];
	label_2.frame = CGRectMake(192,(320-36),106,30);
	label_2.font = [UIFont systemFontOfSize:20];
	label_2.text = @"修改资料";
	[self addSubview:label_2];
	
	UILabel * label_3 = [EFBaseWindow getLabel];
	label_3.frame = CGRectMake(330,(320-36),106,30);
	label_3.font = [UIFont systemFontOfSize:20];
	label_3.text = @"联系客服";
	[self addSubview:label_3];
	
}
-(void)setIsTouchNO{
    isTouch = NO;
}
-(void)reSetIsTouch{
    [NSTimer scheduledTimerWithTimeInterval:1.5
                                     target:self
                                   selector:@selector(setIsTouchNO)
                                   userInfo:nil repeats:NO];
}

-(void)onTab:(UIButton*)sender{
    
	if(sender.selected) return;
    //
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	if(sender.tag==0) [EFUIWindow showUserCenter];
	if(sender.tag==1) [EFUIWindow showModifyInfo];
	if(sender.tag==2) [EFUIWindow showAbout];
}

@end
