//
//  EFForget.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-26.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFForget.h"
#import "EFUIWindow.h"
#import "EFAlert.h"
#import "EFUserAction.h"
#import "EFUserInfo.h"

@implementation EFForget

-(void)show{
	
	[super showBackground:@"ef_resources/bg_login.jpg"];
	[super showCloseBtn];
	[super showReturnBtn];
	[super showTitle:@"忘记密码"];
	
	UIImageView * bg = [[UIImageView alloc] initWithFrame:CGRectMake((480-337)/2, 80, 337, 114)];
	bg.image = [UIImage imageNamed:@"ef_resources/frame_3.png"];
	[self addSubview:bg];
	[bg release];
	
	UIButton * btn_modify = [EFBaseWindow getButton:@"确  定"];
	[btn_modify setFrame:CGRectMake((480-234)/2,230,
									btn_modify.frame.size.width,
									btn_modify.frame.size.height)
	 ];
	[btn_modify addTarget:self action:@selector(doForget:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:btn_modify];
	
	UILabel * label_1 = [EFBaseWindow getLabel];
	label_1.frame = CGRectMake(80,95,320,30);
	label_1.font = [UIFont systemFontOfSize:21];
	label_1.textAlignment = UITextAlignmentLeft;
	label_1.text = @"请在下框输入用户注册邮箱";
	[self addSubview:label_1];
	
	input_1 = [EFBaseWindow getTextField];
	input_1.frame = CGRectMake(80,150,320,30);
	input_1.text = @"";
	//input_1.text = [[EFUserInfo chooseUserInfo] getUserEmail];
	input_1.delegate = self;
	input_1.keyboardType = UIKeyboardTypeEmailAddress;
	[self addSubview:input_1];
	
}

-(void)doForget:(id)sender{
    if (isTouch || [EFUIWindow isRunAnimate] || [EFUserAction isSend]) {
        return;
    }
    isTouch = YES;
    [self reSetIsTouch];
    //
	[input_1 resignFirstResponder];
	NSString * emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate * emailVerify = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	if(![emailVerify evaluateWithObject:input_1.text]){
		[EFAlert alert:@"请输入正确的邮箱地址!"];
		return;
	}
	[EFUIWindow showLoading];
	[EFUserAction forget:input_1.text];
	input_1.text = @"";
}

-(BOOL)textFieldShouldBeginEditing:(UITextField*)textField{
	if([EFUIWindow isRunOniPhone]){
		[EFUIWindow moveContentToY:-50];
	}else{
		[EFUIWindow moveContentToY:-150];
	}
	return YES;
}
-(void)textFieldDidBeginEditing:(UITextField*)textField{
	
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField{
	[input_1 resignFirstResponder];
	return YES;
}

-(void)textFieldDidEndEditing:(UITextField*)textField{
	[EFUIWindow moveContentToOrigin];
}

@end
