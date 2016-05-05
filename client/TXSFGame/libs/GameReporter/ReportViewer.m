//
//  ReportViewer.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-5.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "ReportViewer.h"
#import "ASDepthModalViewController.h"
#import "GameReporter.h"
#import <QuartzCore/QuartzCore.h>

#define DEF_COLOR [UIColor colorWithRed:221/255.0f green:178/255.0f blue:41/255.0f alpha:1]
#define SEL_COLOR [UIColor whiteColor]
#define DEF_IPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define DEF_FONT [UIFont fontWithName:@"Helvetica-Bold" size:(DEF_IPHONE?13:18)]

static NSString * contactInfos[] = {
#ifdef GAME_SNS_TYPE
	
#if GAME_SNS_TYPE==1
	@"QQ:800039802",
	@"QQ:稍后开通",
	@"群号:295219450",
	@"群号:稍后开通",
	@"Email:zl@efun.com",
	@"电话:020-38987039",
#endif
	
#if GAME_SNS_TYPE==2
	@"QQ:800039802",
	@"QQ:稍后开通",
	@"群号:114909747",
	@"群号:稍后开通",
	@"Email:zl@efun.com",
	@"电话:020-38987039",
#endif
	
#if GAME_SNS_TYPE==4
	@"QQ:2330686342",
	@"QQ:稍后开通",
	@"群号:325544349",
	@"群号:稍后开通",
	@"Email:稍后开通",
	@"电话:稍后开通",
#endif
	
#if GAME_SNS_TYPE==5
	@"QQ:800039802",
	@"QQ:稍后开通",
	@"群号:312571421",
	@"群号:稍后开通",
	@"Email:zl@efun.com",
	@"电话:020-38987039",
#endif
	
#if GAME_SNS_TYPE==6
	@"QQ:800039802",
	@"QQ:稍後開通",
	@"群號:312571421",
	@"群號:稍後開通",
	@"Email:zl@efun.com",
	@"電話:020-38987039",
#endif
	
#if GAME_SNS_TYPE==7
	@"QQ:1565878700",
	@"QQ:稍后开通",
	@"群号:253188635",
	@"群号:稍后开通",
	@"184521152@qq.com",
	@"电话:稍后开通",
#endif
	
#if GAME_SNS_TYPE==8
	@"QQ:2328709155",
	@"QQ:稍后开通",
	@"群号:稍后开通",
	@"群号:稍后开通",
	@"Email:稍后开通",
	@"电话:稍后开通",
#endif
	
#if GAME_SNS_TYPE==9
	@"QQ:1565878700",
	@"QQ:稍后开通",
	@"群号:253188635",
	@"群号:稍后开通",
	@"184521152@qq.com",
	@"电话:稍后开通",
#endif
	
#if GAME_SNS_TYPE==10
	@"2330686342",
	@"48898341(充值)",
	@"群号:173612879",
	@"群号:稍后开通",
	@"Email:稍后开通",
	@"电话:0592-2179189",
#endif
	
#if GAME_SNS_TYPE==11
	@"QQ:2328709155",
	@"QQ:稍后开通",
	@"群号:稍后开通",
	@"群号:稍后开通",
	@"Email:稍后开通",
	@"电话:010-82872310",
#endif
	
#if GAME_SNS_TYPE==12
	@"QQ:2330686342",
	@"QQ:稍后开通",
	@"群号:325544349",
	@"群号:稍后开通",
	@"Email:稍后开通",
	@"电话:稍后开通",
#endif
	
#endif
};

static NSString * getContactInfo(int index){
	int total = sizeof(contactInfos)/sizeof(contactInfos[0]);
	if(total>index){
		return contactInfos[index];
	}
	return @"";
}

static ReportViewer * reportViewer;

@implementation ReportViewer

@synthesize select1;
@synthesize select2;
@synthesize select3;
@synthesize select4;
@synthesize select5;

@synthesize sbtn1;
@synthesize sbtn2;
@synthesize sbtn3;
@synthesize sbtn4;
@synthesize sbtn5;

@synthesize tab1;
@synthesize tab2;

@synthesize tbtn1;
@synthesize tbtn2;

@synthesize conten1;
@synthesize conten2;

@synthesize inputText;

@synthesize table1;
@synthesize table2;

@synthesize label_qq1;
@synthesize label_qq2;
@synthesize label_qq_group1;
@synthesize label_qq_group2;
@synthesize label_email;
@synthesize label_phone;

+(ReportViewer*)showViewer{
	if(!reportViewer){
		
		if(DEF_IPHONE){
			reportViewer = [[ReportViewerIphone alloc] initWithNibName:@"ReportViewer-iPhone" bundle:nil];
			//reportViewer.view.frame = CGRectMake(0, 0, 480, 320);
		}else{
			reportViewer = [[ReportViewerIpad alloc] initWithNibName:@"ReportViewer-iPad" bundle:nil];
		}
		//[ASDepthModalViewController presentView:viewer.view withBackgroundColor:color popupAnimationStyle:style];
		[ASDepthModalViewController presentView:reportViewer.view];
		
	}
	return reportViewer;
}

+(BOOL)hasViewer{
	if(reportViewer){
		return YES;
	}
	return NO;
}
+(void)reload{
	if(reportViewer){
		[reportViewer reloadData];
		[reportViewer scrollToEnd:NO];
	}
}

+(void)closeViewer{
	if(reportViewer){
		[ASDepthModalViewController dismiss];
		[reportViewer release];
		reportViewer = nil;
	}
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		
		if(label_qq1){
			
		}
		
    }
    return self;
}

-(NSUInteger)supportedInterfaceOrientations {
	
	// iPhone only
	if( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone )
		return UIInterfaceOrientationMaskLandscape;
	
	// iPad only
	return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// iPhone only
	if( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone )
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	
	// iPad only
	// iPhone only
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)viewDidLoad{
	
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	[self selectTab:tbtn2];
	[self selectTargetType:sbtn1];
	
	[inputText setBorderStyle:UITextBorderStyleNone];
	//[inputText becomeFirstResponder];
	
	table2.backgroundColor = [UIColor clearColor];
	
	label_qq1.text =		getContactInfo(0);
	label_qq2.text =		getContactInfo(1);
	label_qq_group1.text =	getContactInfo(2);
	label_qq_group2.text =	getContactInfo(3);
	label_email.text =		getContactInfo(4);
	label_phone.text =		getContactInfo(5);
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)selectTab:(UIButton*)sender{
	
	selectReportIndex = -1;
	
	[self reloadData];
	
	[inputText resignFirstResponder];
	
	[conten1 setHidden:YES];
	[conten2 setHidden:YES];
	
	[tab1 setHidden:YES];
	[tab2 setHidden:YES];
	
	tbtn1.titleLabel.textColor = DEF_COLOR;
	tbtn2.titleLabel.textColor = DEF_COLOR;
	
	if(sender==tbtn1){
		[tab1 setHidden:NO];
		[conten1 setHidden:NO];
		tbtn1.titleLabel.textColor = SEL_COLOR;
		selectTab = 1;
	}
	if(sender==tbtn2){
		[tab2 setHidden:NO];
		[conten2 setHidden:NO];
		tbtn2.titleLabel.textColor = SEL_COLOR;
		selectTab = 2;
	}
	
}

-(IBAction)selectTargetType:(UIButton*)sender{
	
	[select1 setHidden:YES];
	[select2 setHidden:YES];
	[select3 setHidden:YES];
	[select4 setHidden:YES];
	[select5 setHidden:YES];
	
	sbtn1.titleLabel.textColor = DEF_COLOR;
	sbtn2.titleLabel.textColor = DEF_COLOR;
	sbtn3.titleLabel.textColor = DEF_COLOR;
	sbtn4.titleLabel.textColor = DEF_COLOR;
	sbtn5.titleLabel.textColor = DEF_COLOR;
	
	if(sender==sbtn1){
		[select1 setHidden:NO];
		sbtn1.titleLabel.textColor = SEL_COLOR;
		selectType = 1;
	}
	if(sender==sbtn2){
		[select2 setHidden:NO];
		sbtn2.titleLabel.textColor = SEL_COLOR;
		selectType = 2;
	}
	if(sender==sbtn3){
		[select3 setHidden:NO];
		sbtn3.titleLabel.textColor = SEL_COLOR;
		selectType = 3;
	}
	if(sender==sbtn4){
		[select4 setHidden:NO];
		sbtn4.titleLabel.textColor = SEL_COLOR;
		selectType = 4;
	}
	if(sender==sbtn5){
		[select5 setHidden:NO];
		sbtn5.titleLabel.textColor = SEL_COLOR;
		selectType = 5;
	}
	
}

-(IBAction)closeViewer:(id)sender{
	[inputText resignFirstResponder];
	[ReportViewer closeViewer];
}

-(IBAction)doSend:(id)sender{
	if([inputText.text length]==0){
//		UIAlertView * alert = [[[UIAlertView alloc] initWithTitle:@"请输入文字" 
//														  message:@"请输入你要反馈的问题!" 
//														 delegate:nil 
//												cancelButtonTitle:@"确定" 
//												otherButtonTitles:nil] 
//							   autorelease];
        UIAlertView * alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"report_viewer_input_text",nil)
														  message:NSLocalizedString(@"report_viewer_input_question",nil)
														 delegate:nil
												cancelButtonTitle:NSLocalizedString(@"report_viewer_sure",nil)
												otherButtonTitles:nil]
							   autorelease];
        
		[alert show];
		return;
	}
	
	[inputText resignFirstResponder];
	if(selectReportIndex>=0){
		[[GameReporter shared] replyReport:inputText.text index:selectReportIndex];
	}else{
		[[GameReporter shared] sendReport:inputText.text type:selectType];
		[self selectTab:tbtn2];
	}
	inputText.text = @"";
	
	//[self closeViewer:sender];
	
}

-(void)reloadData{
	[table1 reloadData];
	[table2 reloadData];
}
-(void)scrollToEnd:(BOOL)isScorll{
	NSIndexPath * row = [NSIndexPath indexPathForRow:0 inSection:0];
	int total = [self tableView:table1 numberOfRowsInSection:row];
	if(total>0){
		row = [NSIndexPath indexPathForRow:total-1 inSection:0];
		[table1 scrollToRowAtIndexPath:row
					  atScrollPosition:UITableViewScrollPositionBottom
							  animated:isScorll];
	}
}

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView{
    return 1;
}
-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section{
    return @"";
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section{
	int count = 0;
	if(tableView==table1){
		if(selectReportIndex>=0){
			count = [[GameReporter shared] getReportContentCountAt:selectReportIndex];
		}
	}
	if(tableView==table2){
		count = [[GameReporter shared].reports count];
	}
	
	return count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	if(tableView==table1){
		int index = [indexPath indexAtPosition:1];
		NSDictionary * info = [[GameReporter shared] getReportContent:selectReportIndex infoAt:index];
		if(info){
			
			NSString * msg = [info objectForKey:@"M"];
			CGSize constraintSize = CGSizeMake(450, MAXFLOAT);
			CGSize labelSize = [msg sizeWithFont:DEF_FONT 
							   constrainedToSize:constraintSize 
								   lineBreakMode:UILineBreakModeWordWrap];
			int h = labelSize.height;
			if(h<28) h = 28;
			return h+10;
		}
	}
	return 35;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath{
	
	UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	
	if(tableView==table1){
		if(selectReportIndex>=0){
			
			//cell.textLabel.textColor = [UIColor whiteColor];
			cell.backgroundColor = [UIColor clearColor];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			int index = [indexPath indexAtPosition:1];
			NSDictionary * info = [[GameReporter shared] getReportContent:selectReportIndex infoAt:index];
			if(info){
				
				UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(0,5,60,22)];
				title.backgroundColor = [UIColor clearColor];
				title.font = DEF_FONT;
				[title autorelease];
				[cell addSubview:title];
				
				if([[info objectForKey:@"T"] intValue]==1){
					//title.text = @" [你]:";
                    title.text = NSLocalizedString(@"report_viewer_you",nil);
					title.textColor = [UIColor redColor];
				}
				if([[info objectForKey:@"T"] intValue]==2){
					//title.text = @" [客服]:";
                    title.text = NSLocalizedString(@"report_viewer_serve",nil);
					title.textColor = [UIColor greenColor];
				}
				
				NSString * msg = [info objectForKey:@"M"];
				CGSize constraintSize = CGSizeMake(450, MAXFLOAT);
				CGSize labelHeight = [msg sizeWithFont:DEF_FONT];
				CGSize labelSize = [msg sizeWithFont:DEF_FONT 
								   constrainedToSize:constraintSize 
									   lineBreakMode:UILineBreakModeWordWrap];
				
				UILabel * content = [[UILabel alloc] initWithFrame:CGRectMake(65,5,labelSize.width,labelSize.height)];
				content.text = msg;
				content.font = DEF_FONT;
				content.textColor = [UIColor blackColor];
				content.backgroundColor = [UIColor whiteColor];
				content.numberOfLines = ceil(labelSize.height/labelHeight.height);
				content.lineBreakMode = UILineBreakModeWordWrap;
				[cell addSubview:content];
				[content release];
				
				content.layer.cornerRadius = 6;
				content.layer.shouldRasterize = YES;
				
			}
			
			//cell.textLabel.text = [[GameReporter shared] getReportContent:selectReportIndex msgAt:index];
			
		}
	}
	
	if(tableView==table2){
		int index = [indexPath indexAtPosition:1];
		cell.textLabel.text = [[GameReporter shared] getReportTitleAt:index];
		cell.textLabel.font = DEF_FONT;
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.backgroundColor = [UIColor clearColor];
	}
	
	[cell autorelease];
    return cell;
	
}

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath{
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if(tableView==table2){
		[self selectTab:tbtn1];
		selectReportIndex = [indexPath row];
		[self reloadData];
		[self scrollToEnd:NO];
		
		[[GameReporter shared] viewReportAtIndex:selectReportIndex];
		
	}
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField{
	[self doSend:nil];
	return NO;
}

@end

@implementation ReportViewerIpad

@end

@implementation ReportViewerIphone
@synthesize closeBtn;

-(void)viewDidLoad{
	CGRect rect = [[UIScreen mainScreen] bounds];
	if(rect.size.height==568){
		closeBtn.frame = CGRectMake(568-closeBtn.frame.size.width,
									closeBtn.frame.origin.y, 
									closeBtn.frame.size.width, 
									closeBtn.frame.size.height);
	}
	[super viewDidLoad];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField*)textField{
	[UIView animateWithDuration:0.25f
                     animations:^{
						 self.view.frame = CGRectMake (0,-12,self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished){}];
	return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
	[UIView animateWithDuration:0.25f
                     animations:^{
						 self.view.frame = CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished){}];
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField{
	[textField resignFirstResponder];
	[UIView animateWithDuration:0.25f
                     animations:^{
						 self.view.frame = CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished) {
						 [self doSend:nil];
                     }];
	return NO;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	if(tableView==table1){
		int index = [indexPath indexAtPosition:1];
		NSDictionary * info = [[GameReporter shared] getReportContent:selectReportIndex infoAt:index];
		if(info){
			
			NSString * msg = [info objectForKey:@"M"];
			CGSize constraintSize = CGSizeMake(245, MAXFLOAT);
			CGSize labelSize = [msg sizeWithFont:DEF_FONT 
							   constrainedToSize:constraintSize 
								   lineBreakMode:UILineBreakModeWordWrap];
			int h = labelSize.height;
			if(h<22) h = 22;
			return h+5;
		}
	}
	return 22;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath{
	
	UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	
	if(tableView==table1){
		if(selectReportIndex>=0){
			
			//cell.textLabel.textColor = [UIColor whiteColor];
			cell.backgroundColor = [UIColor clearColor];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			int index = [indexPath indexAtPosition:1];
			NSDictionary * info = [[GameReporter shared] getReportContent:selectReportIndex infoAt:index];
			if(info){
				
				UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(0,2,45,22)];
				title.backgroundColor = [UIColor clearColor];
				title.font = DEF_FONT;
				[title autorelease];
				[cell addSubview:title];
				
				if([[info objectForKey:@"T"] intValue]==1){
					//title.text = @" [你]:";
                    title.text = NSLocalizedString(@"report_viewer_you",nil);
					title.textColor = [UIColor redColor];
				}
				if([[info objectForKey:@"T"] intValue]==2){
					//title.text = @" [客服]:";
                    title.text = NSLocalizedString(@"report_viewer_serve",nil);
					title.textColor = [UIColor greenColor];
				}
				
				NSString * msg = [info objectForKey:@"M"];
				CGSize constraintSize = CGSizeMake(245, MAXFLOAT);
				CGSize labelHeight = [msg sizeWithFont:DEF_FONT];
				CGSize labelSize = [msg sizeWithFont:DEF_FONT 
								   constrainedToSize:constraintSize 
									   lineBreakMode:UILineBreakModeWordWrap];
				
				UILabel * content = [[UILabel alloc] initWithFrame:CGRectMake(47,5,labelSize.width,labelSize.height)];
				content.text = msg;
				content.font = DEF_FONT;
				content.textColor = [UIColor blackColor];
				content.backgroundColor = [UIColor whiteColor];
				content.numberOfLines = ceil(labelSize.height/labelHeight.height);
				content.lineBreakMode = UILineBreakModeWordWrap;
				[cell addSubview:content];
				[content release];
				
				content.layer.cornerRadius = 5;
				content.layer.shouldRasterize = YES;
				
			}
			
			//cell.textLabel.text = [[GameReporter shared] getReportContent:selectReportIndex msgAt:index];
			
		}
	}
	
	if(tableView==table2){
		int index = [indexPath indexAtPosition:1];
		cell.textLabel.text = [[GameReporter shared] getReportTitleAt:index];
		cell.textLabel.font = DEF_FONT;
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.backgroundColor = [UIColor clearColor];
	}
	
	[cell autorelease];
    return cell;
	
}

@end

