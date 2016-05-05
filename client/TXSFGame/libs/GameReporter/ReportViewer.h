//
//  ReportViewer.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-5.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReportViewer : UIViewController <UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate> {
	
	UIImageView * select1;
	UIImageView * select2;
	UIImageView * select3;
	UIImageView * select4;
	UIImageView * select5;
	
	UIButton * sbtn1;
	UIButton * sbtn2;
	UIButton * sbtn3;
	UIButton * sbtn4;
	UIButton * sbtn5;
	
	UIImageView * tab1;
	UIImageView * tab2;
	
	UIButton * tbtn1;
	UIButton * tbtn2;
	
	UIView * conten1;
	UIView * conten2;
	
	UITextField * inputText;
	
	int selectReportIndex;
	int selectTab;
	int selectType;
	
	UITableView * table1;
	UITableView * table2;
	
	UILabel * label_qq1;
	UILabel * label_qq2;
	UILabel * label_qq_group1;
	UILabel * label_qq_group2;
	UILabel * label_email;
	UILabel * label_phone;
	
}

@property(nonatomic,assign) IBOutlet UIImageView * select1;
@property(nonatomic,assign) IBOutlet UIImageView * select2;
@property(nonatomic,assign) IBOutlet UIImageView * select3;
@property(nonatomic,assign) IBOutlet UIImageView * select4;
@property(nonatomic,assign) IBOutlet UIImageView * select5;

@property(nonatomic,assign) IBOutlet UIButton * sbtn1;
@property(nonatomic,assign) IBOutlet UIButton * sbtn2;
@property(nonatomic,assign) IBOutlet UIButton * sbtn3;
@property(nonatomic,assign) IBOutlet UIButton * sbtn4;
@property(nonatomic,assign) IBOutlet UIButton * sbtn5;

@property(nonatomic,assign) IBOutlet UIImageView * tab1;
@property(nonatomic,assign) IBOutlet UIImageView * tab2;

@property(nonatomic,assign) IBOutlet UIButton * tbtn1;
@property(nonatomic,assign) IBOutlet UIButton * tbtn2;

@property(nonatomic,assign) IBOutlet UIView * conten1;
@property(nonatomic,assign) IBOutlet UIView * conten2;

@property(nonatomic,assign) IBOutlet UITextField * inputText;

@property(nonatomic,assign) IBOutlet UITableView * table1;
@property(nonatomic,assign) IBOutlet UITableView * table2;

@property(nonatomic,assign) IBOutlet UILabel * label_qq1;
@property(nonatomic,assign) IBOutlet UILabel * label_qq2;
@property(nonatomic,assign) IBOutlet UILabel * label_qq_group1;
@property(nonatomic,assign) IBOutlet UILabel * label_qq_group2;
@property(nonatomic,assign) IBOutlet UILabel * label_email;
@property(nonatomic,assign) IBOutlet UILabel * label_phone;

-(IBAction)selectTab:(id)sender;
-(IBAction)selectTargetType:(id)sender;
-(IBAction)closeViewer:(id)sender;
-(IBAction)doSend:(id)sender;

+(ReportViewer*)showViewer;
+(BOOL)hasViewer;
+(void)reload;
+(void)closeViewer;

@end

@interface ReportViewerIpad : ReportViewer{
}
@end

@interface ReportViewerIphone : ReportViewer{
	UIButton * closeBtn;
}
@property(nonatomic,assign) IBOutlet UIButton * closeBtn;
@end
