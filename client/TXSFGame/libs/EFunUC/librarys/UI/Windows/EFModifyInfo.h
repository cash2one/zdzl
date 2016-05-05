//
//  EFModifyInfo.h
//  TXSFGame
//
//  Created by TigerLeung on 13-7-19.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFBaseWindow.h"
@interface EFModifyInfo : EFBaseWindow{
	UITextField * input_1;
	UITextField * input_2;
	UITextField * input_3;
	
	BOOL isBeginInput;
}

@end
