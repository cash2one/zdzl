//
//  GameReporter.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-5.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "GameReporter.h"
#import "GCDiscreetNotificationView.h"
#import "ReportViewer.h"
#import "ASDepthModalViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "CJSONDeserializer.h"

#define GAME_REPORT_CHECK_TIMER 30*60.0f
//#define GAME_REPORT_CHECK_TIMER 2.0f
#define GAME_REPORT_REQUEST_METHOD @"POST"

#define GAME_REPORT_URL_SEND @"/question/"
#define GAME_REPORT_URL_REPLY @"/response/"
#define GAME_REPORT_URL_VIEW @"/read/"
#define GAME_REPORT_URL_CHECK @"/status/"
#define GAME_REPORT_URL_REPORTS @"/reports/"

static NSString * getReportUrlFrom(NSString*uri, NSString*path){
	if(uri){
		return [NSString stringWithFormat:@"%@%@",uri,path];
	}
	return @"";
}

static NSString * breakKeyword[] = {
	@"钓鱼岛",
	@"釣魚島",
	@"尖阁列岛",
	@"尖閣列島",
};

static NSString * checkKeyword(NSString * string){
	int total = sizeof(breakKeyword)/sizeof(breakKeyword[0]);
	for(int i=0;i<total;i++){
		NSString * keyword = breakKeyword[i];
		NSMutableString * stmp = [NSMutableString stringWithString:@""];
		for(int j=0;j<[keyword length];j++){
			[stmp appendString:@"*"];
		}
		NSArray * ary = [string componentsSeparatedByString:keyword];
		string = [ary componentsJoinedByString:stmp];
	}
	return string;
}

static GameReporter * gameReporter;

@implementation GameReporter

@synthesize winSize;
@synthesize reportData;
@synthesize reports;
@synthesize baseUri;

+(GameReporter*)shared{
	if(!gameReporter){
		gameReporter = [[GameReporter alloc] init];
	}
	return gameReporter;
}

+(void)stopAll{
	if(gameReporter){
		[gameReporter stop];
		[gameReporter release];
		gameReporter = nil;
	}
}

-(void)dealloc{
	[self stop];
	[super dealloc];
}

-(void)setBaseUri:(NSString *)uri{
	if(baseUri){
		[baseUri release];
		baseUri = nil;
	}
	if(uri){
		baseUri = [[NSString alloc] initWithString:uri];
	}
}

-(void)setReportData:(NSDictionary *)data{
	if(reportData){
		[reportData release];
		reportData = nil;
	}
	if(data){
		reportData = [[NSDictionary alloc] initWithDictionary:data];
	}
}

-(void)start{
	
	reports = [NSMutableArray array];
	[reports retain];
	
	//[self loadAllReposts];
	[self startTimer];
	
}

-(void)stop{
	
	if(notificationView){
		[notificationView removeFromSuperview];
		notificationView = nil;
	}
	
	[self stopTimer];
	
	if(reportData){
		[reportData release];
		reportData = nil;
	}
	
	if(reports){
		[reports release];
		reports = nil;
	}
	
	if(baseUri){
		[baseUri release];
		baseUri = nil;
	}
	
}

-(void)startTimer{
	timerCount = 0;
	checkTimer = [NSTimer scheduledTimerWithTimeInterval:GAME_REPORT_CHECK_TIMER 
												  target:self 
												selector:@selector(doCheckTimer:) 
												userInfo:nil repeats:YES];
	
	[NSTimer scheduledTimerWithTimeInterval:3.0f 
									 target:self 
								   selector:@selector(doCheckTimer:) 
								   userInfo:nil repeats:NO];
}

-(void)stopTimer{
	
	if(checkTimer){
		[checkTimer invalidate];
		checkTimer = nil;
	}
	
}
-(void)doCheckTimer:(NSTimer*)timer{
	
	if(baseUri==nil) return;
	
	timerCount++;
	
	if(reportData){
		NSURL * url = [NSURL URLWithString:getReportUrlFrom(baseUri,GAME_REPORT_URL_CHECK)];
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
		for(NSString * key in reportData){
			[request setPostValue:[reportData objectForKey:key] forKey:key];
		}
		[request setCompletionBlock:^{
			/*
			NSData * d = [request responseData];
			if(d){
				
			}
			*/
			
			NSError * error = nil;
			NSDictionary * json = [[CJSONDeserializer deserializer] 
								   deserializeAsDictionary:[request responseData] 
								   error:&error];
			if(!error){
				int ret = [[json objectForKey:@"Ret"] intValue];
				if(ret==1){
					id sts = [json objectForKey:@"Data"];
					if([sts isKindOfClass:[NSArray class]]){
						[self checkStatus:sts];
					}
				}
			}
		}];
		[request setRequestMethod:GAME_REPORT_REQUEST_METHOD];
		[request startAsynchronous];
	}
}

-(void)checkStatus:(NSArray*)data{
	if([data count]>0){
		BOOL isShow = NO;
		for(NSDictionary * status in data){
			int s = [[status objectForKey:@"Status"] intValue];
			if(s==GameReporterStatus_reply){
				isShow = YES;
			}
		}
		if(isShow){
			[self showNotification];
		}
	}
}

-(void)showNotification{
	
	if(!notificationView){
		//notificationView = [[GCDiscreetNotificationView alloc] initWithText:@"客服GM已经回复您，请点击进入查看"];
        notificationView = [[GCDiscreetNotificationView alloc] initWithText:NSLocalizedString(@"reporter_in",nil)];
		notificationView.superSize = winSize;
		notificationView.target = self;
		notificationView.call = @selector(show);
	}
	
	if(!notificationView.showing && ![ReportViewer hasViewer]){
		[NSTimer scheduledTimerWithTimeInterval:0.001f 
										 target:notificationView 
									   selector:@selector(showAnimated) 
									   userInfo:nil repeats:NO];
	}
	
}

-(void)show{
	if(notificationView){
		if(notificationView.showing){
			[notificationView hideAnimated];
		}
	}
	
	[self loadAllReposts];
	[ReportViewer showViewer];
}
-(void)hide{
	if(notificationView){
		if(notificationView.showing){
			[notificationView hideAnimated];
		}
	}
	[ReportViewer closeViewer];
}

-(void)loadAllReposts{
	
	if(baseUri==nil) return;
	
	NSURL * url = [NSURL URLWithString:getReportUrlFrom(baseUri,GAME_REPORT_URL_REPORTS)];
	ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
	for(NSString * key in reportData){
		[request setPostValue:[reportData objectForKey:key] forKey:key];
	}
	
	[request setCompletionBlock:^{
		
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer] 
							   deserializeAsDictionary:[request responseData] 
							   error:&error];
		if(!error){
			int ret = [[json objectForKey:@"Ret"] intValue];
			if(ret==1){
				id rps = [json objectForKey:@"Data"];
				if([rps isKindOfClass:[NSArray class]]){
					[self saveReports:rps];
				}
			}
		}
		
	}];
	[request setFailedBlock:^{
		//NSLog([[request error] description]);
	}];
	
	[request setRequestMethod:GAME_REPORT_REQUEST_METHOD];
	[request startAsynchronous];
	
}

-(void)saveReports:(NSArray*)rps{
	[reports removeAllObjects];
	[reports addObjectsFromArray:rps];
	[ReportViewer reload];
}

-(void)sendReport:(NSString*)report type:(int)type{
	
	if(baseUri==nil) return;
	
	report = checkKeyword(report);
	
	NSURL * url = [NSURL URLWithString:getReportUrlFrom(baseUri,GAME_REPORT_URL_SEND)];
	ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
	for(NSString * key in reportData){
		[request setPostValue:[reportData objectForKey:key] forKey:key];
	}
	[request setPostValue:report forKey:@"report"];
	[request setPostValue:[NSNumber numberWithInt:type] forKey:@"type"];
	[request setRequestMethod:GAME_REPORT_REQUEST_METHOD];
	
	[request setCompletionBlock:^{
		[self loadAllReposts];
	}];
	[request setFailedBlock:^{
		//NSLog([[request error] description]);
	}];
	
	[request startAsynchronous];
	
}
-(void)replyReport:(NSString*)reportString index:(int)index{
	
	if(baseUri==nil) return;
	if(index>=[reports count]){
		return;
	}
	
	NSDictionary * report = [reports objectAtIndex:index];
	if(report){
		NSURL * url = [NSURL URLWithString:getReportUrlFrom(baseUri,GAME_REPORT_URL_REPLY)];
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
		[request setPostValue:[report objectForKey:@"Id"] forKey:@"id"];
		[request setPostValue:checkKeyword(reportString) forKey:@"m"];
		[request setRequestMethod:GAME_REPORT_REQUEST_METHOD];
		[request setCompletionBlock:^{
			[self loadAllReposts];
		}];
		[request startAsynchronous];
	}
	
}

-(void)viewReportAtIndex:(int)index{
	
	if(baseUri==nil) return;
	
	if(index>=[reports count]){
		return;
	}
	NSDictionary * report = [reports objectAtIndex:index];
	if(report){
		int status = [[report objectForKey:@"Status"] intValue];
		if(status==GameReporterStatus_reply){
			NSURL * url = [NSURL URLWithString:getReportUrlFrom(baseUri,GAME_REPORT_URL_VIEW)];
			ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
			[request setPostValue:[report objectForKey:@"Id"] forKey:@"id"];
			[request setRequestMethod:GAME_REPORT_REQUEST_METHOD];
			[request startAsynchronous];
		}
	}
}

-(NSString*)getReportTitleAt:(int)index{
	
	if(index>=[reports count]){
		return [NSString stringWithFormat:@" %d.",(index+1)];
	};
	
	NSDictionary * report = [reports objectAtIndex:index];
	NSArray * content = [report objectForKey:@"Contents"];
	for(NSDictionary * msg in content){
		if([[msg objectForKey:@"T"] intValue]==1){
			return [NSString stringWithFormat:@" %d. %@",(index+1),checkKeyword([msg objectForKey:@"M"])];
		}
	}
	return @"";
}

-(int)getReportContentCountAt:(int)index{
	if(index>=[reports count]) return 0;
	NSDictionary * report = [reports objectAtIndex:index];
	NSArray * content = [report objectForKey:@"Contents"];
	return [content count];
}

-(NSDictionary*)getReportContent:(int)cIndex infoAt:(int)mIndex{
	
	if(cIndex>=[reports count]){
		return nil;
	}
	
	NSDictionary * report = [reports objectAtIndex:cIndex];
	NSArray * content = [report objectForKey:@"Contents"];
	
	if(mIndex>=[content count]) return nil;
	
	NSMutableDictionary * info = [NSMutableDictionary dictionaryWithDictionary:[content objectAtIndex:mIndex]];
	NSString * message = checkKeyword([info objectForKey:@"M"]);
	[info setObject:message forKey:@"M"];
	
	return info;
}

-(NSString*)getReportContent:(int)cIndex msgAt:(int)mIndex{
	NSDictionary * msg = [self getReportContent:cIndex infoAt:mIndex];
	if(msg){
		if([[msg objectForKey:@"T"] intValue]==1){
			//return [NSString stringWithFormat:@"[你]: %@",[msg objectForKey:@"M"]];
            return [NSString stringWithFormat:NSLocalizedString(@"reporter_you",nil),[msg objectForKey:@"M"]];
		}
		if([[msg objectForKey:@"T"] intValue]==2){
			//return [NSString stringWithFormat:@"[客服]: %@",[msg objectForKey:@"M"]];
            return [NSString stringWithFormat:NSLocalizedString(@"reporter_service",nil),[msg objectForKey:@"M"]];
		}
	}
	return @"";
}

@end
