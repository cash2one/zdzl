//
//  ActivityKey.h
//  TXSFGame
//
//  Created by efun on 13-3-11.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "Config.h"

@interface ActivityKey : CCLayer <UITextFieldDelegate>
{
	NSString *key;
	CCLabelFX *keyLabel;
	UITextField *keyInput;
	int		aid;
}
@property(nonatomic,assign)int aid;
@property(nonatomic,assign)UITextField *keyInput;

-(void)loadData:(NSDictionary*)dict;
+(void) hideKeyboard:(ActivityKey*) keywin;

@end
