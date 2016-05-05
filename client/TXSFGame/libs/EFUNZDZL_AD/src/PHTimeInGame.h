//
//  PHTimeInGame.h
//  playhaven-sdk-ios
//
//  Created by Thomas DiZoglio on 7/5/12.
//  Copyright (c) 2012 Play Haven. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
    
@interface PHTimeInGame : NSObject {

    CFAbsoluteTime sessionStartTime;
}

+(PHTimeInGame *) getInstance;

-(void) gameSessionStarted;
-(void) gameSessionStopped;
-(void) gameSessionRestart;

-(void) resetCounters;

// These should only be called with-in the PH SDK
-(CFAbsoluteTime) getSumSessionDuration;
-(int) getCountSessions;
-(CFAbsoluteTime) getCurrentSessionDuration;

@end
