//
//  EFAbout.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-19.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFAbout.h"

@implementation EFAbout

-(void)showContent:(float)height{
	
	UIImageView * bg = [[UIImageView alloc] initWithFrame:CGRectMake((480-435)/2, 73+height, 435, 152)];
	bg.image = [UIImage imageNamed:@"ef_resources/frame_1.png"];
	[self addSubview:bg];
	[bg release];
	
	UILabel * label_1 = [EFBaseWindow getLabel];
	label_1.frame = CGRectMake(35,85+height,210,30);
	label_1.font = [UIFont systemFontOfSize:21];
	label_1.textAlignment = UITextAlignmentLeft;
	label_1.text = @"QQ : 800039802";
	[self addSubview:label_1];
	
//	UILabel * label_2 = [EFBaseWindow getLabel];
//	label_2.frame = CGRectMake(250,85+height,200,30);
//	label_2.font = [UIFont systemFontOfSize:21];
//	label_2.textAlignment = UITextAlignmentRight;
//	label_2.text = @"QQ : 2827896738";
//	[self addSubview:label_2];
	
	UILabel * label_3 = [EFBaseWindow getLabel];
	label_3.frame = CGRectMake(35,135+height,210,30);
	label_3.font = [UIFont systemFontOfSize:21];
	label_3.textAlignment = UITextAlignmentLeft;
	label_3.text = @"Email : zl@efun.com";
	[self addSubview:label_3];
	
//	UILabel * label_4 = [EFBaseWindow getLabel];
//	label_4.frame = CGRectMake(250,135+height,200,30);
//	label_4.font = [UIFont systemFontOfSize:21];
//	label_4.textAlignment = UITextAlignmentRight;
//	label_4.text = @"群号 : 295219450";
//	[self addSubview:label_4];
	
	UILabel * label_5 = [EFBaseWindow getLabel];
	label_5.frame = CGRectMake(35,185+height,210,30);
	label_5.font = [UIFont systemFontOfSize:21];
	label_5.textAlignment = UITextAlignmentLeft;
	label_5.text = @"电话 : 020-38987039";
	[self addSubview:label_5];
	
//	UILabel * label_6 = [EFBaseWindow getLabel];
//	label_6.frame = CGRectMake(250,185+height,200,30);
//	label_6.font = [UIFont systemFontOfSize:21];
//	label_6.textAlignment = UITextAlignmentRight;
//	label_6.text = @"电话:XXXXXXXX";
//	[self addSubview:label_6];
	
}

-(void)show{
	
	[super showBackground:@"ef_resources/bg_general.jpg"];
	[super showCloseBtn];
	[super showTitle:@"联系客服"];
	[super showTabs:2];
	
	[self showContent:0];
	
}

@end
