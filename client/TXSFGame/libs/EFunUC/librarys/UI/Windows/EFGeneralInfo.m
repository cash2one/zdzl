//
//  EFGeneralInfo.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-18.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFGeneralInfo.h"
#import "EFUIWindow.h"
#import "EFUserInfo.h"
#import "EFAlert.h"
#import "EFUserAction.h"
#import "Config.h"

@implementation EFGeneralInfo

-(void)show{
	[super showBackground:@"ef_resources/bg_general.jpg"];
	[super showCloseBtn];
	[super showTitle:@"帐号信息"];
	[super showTabs:0];
	
	EFUserInfo * userInfo = [EFUserInfo currentUserInfo];
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	
	UIImageView * bg = [[UIImageView alloc] initWithFrame:CGRectMake((480-337)/2, 80, 337, 114)];
	bg.image = [UIImage imageNamed:@"ef_resources/frame_3.png"];
	[self addSubview:bg];
	[bg release];
	
	UILabel * label_1 = [EFBaseWindow getLabel];
	label_1.frame = CGRectMake(80,95,60,30);
	label_1.font = [UIFont systemFontOfSize:21];
	label_1.textAlignment = UITextAlignmentLeft;
	label_1.text = @"邮箱 :";
	[self addSubview:label_1];
	
	UILabel * label_2 = [EFBaseWindow getLabel];
	label_2.frame = CGRectMake(80,150,60,30);
	label_2.font = [UIFont systemFontOfSize:21];
	label_2.textAlignment = UITextAlignmentLeft;
	label_2.text = @"昵称 :";
	[self addSubview:label_2];
	
	UILabel * label_3 = [EFBaseWindow getLabel];
	label_3.frame = CGRectMake(142,95,215,30);
	label_3.font = [UIFont systemFontOfSize:20];
	label_3.textAlignment = UITextAlignmentLeft;
	label_3.adjustsFontSizeToFitWidth = YES;
	if (version >= 6) {
		label_3.adjustsLetterSpacingToFitWidth = YES;
	}
	label_3.text = [userInfo getUserEmail];
	[self addSubview:label_3];
	
	input_1 = [EFBaseWindow getTextField];
	input_1.frame = CGRectMake(142,153,215,25);
	input_1.text = [userInfo getUserName];
	input_1.keyboardType = UIKeyboardTypeDefault;
	input_1.delegate = self;
	[self addSubview:input_1];
	
	UIButton * btn_1 = [UIButton buttonWithType:UIButtonTypeCustom];
	[btn_1 setFrame:CGRectMake(360,93,45,33)];
	[btn_1 setTitle:@"注销" forState:UIControlStateNormal];
	[btn_1 setTitleColor:[UIColor colorWithRed:0.14f green:0.27f blue:0.40f alpha:1.0f] forState:UIControlStateNormal];
	[btn_1 setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	[btn_1 addTarget:self action:@selector(doLogout:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_1];
	
	UIButton * btn_2 = [UIButton buttonWithType:UIButtonTypeCustom];
	[btn_2 setFrame:CGRectMake(360,149,45,33)];
	[btn_2 setTitle:@"修改" forState:UIControlStateNormal];
	[btn_2 setTitleColor:[UIColor colorWithRed:0.14f green:0.27f blue:0.40f alpha:1.0f] forState:UIControlStateNormal];
	[btn_2 setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
	[btn_2 addTarget:self action:@selector(doChange:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_2];
	
}

-(void)doLogout:(id)sender{
    //
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[input_1 resignFirstResponder];
	
	[EFUIWindow showLoading];
	[EFUserAction logout];
	
}
-(void)doChange:(id)sender{
    //
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[input_1 resignFirstResponder];
	
	if([input_1.text isEqualToString:[[EFUserInfo currentUserInfo] getUserName]]){
        //
        isTouch = NO;
		return;
	}
	
	if(input_1.text.length<=1){
		[EFAlert alert:@"昵称不能太短!"];
		return;
	}
	if(input_1.text.length>8){
		[EFAlert alert:@"昵称不能太长!"];
		return;
	}
	
	[EFUIWindow showLoading];
	[EFUserAction changeNickname:input_1.text];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField*)textField{
	if([EFUIWindow isRunOniPhone]){
		[EFUIWindow moveContentToY:-60];
	}else{
		[EFUIWindow moveContentToY:-150];
	}
	return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField{
	[textField resignFirstResponder];
	return YES;
}

-(void)textFieldDidEndEditing:(UITextField*)textField{
	[EFUIWindow moveContentToOrigin];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	return !isEmo(string);
}

@end
