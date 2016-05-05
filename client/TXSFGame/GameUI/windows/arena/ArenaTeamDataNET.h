//
//  ArenaTeamDataNET.h
//  TXSFGame
//
//  Created by Max on 13-5-24.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArenaTeamDataNET : NSObject{

}
@property(nonatomic,assign) SEL selector;
@property(nonatomic,assign) id target;

+(ArenaTeamDataNET*)share;


-(void)request:(NSString*)command arg:(NSString*)arg;

@end
