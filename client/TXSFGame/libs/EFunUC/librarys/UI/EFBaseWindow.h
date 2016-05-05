//
//  EFBaseWindow.h
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <UIKit/UIKit.h>

#define EF_FONT_COLOR [UIColor colorWithRed:48/255.f green:21/255.f blue:9/255.f alpha:1]

@interface EFBaseWindow : UIView <UITextFieldDelegate>{
    BOOL isTouch;
}

+(EFBaseWindow*)getWindow:(NSString*)name;

-(void)showBackground:(NSString*)bgFile;
-(void)showCloseBtn;
-(void)showReturnBtn;

+(UILabel*)getLabel;
+(UIButton*)getButton:(NSString*)name;
+(UIButton*)getSmallButton:(NSString*)name;
+(UITextField*)getTextField;
+(UITextField*)getTextFieldPlaceholder;

-(void)showTitle:(NSString*)title;
-(void)showTabs:(int)index;
//
-(void)reSetIsTouch;
@end
