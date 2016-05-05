//
//  AppDelegate.m
//  PointingKing
//
//  Created by TigerLeung on 13-1-17.
//  Copyright TigerLeung 2013年. All rights reserved.
//

#import "cocos2d.h"

#import "AppDelegate.h"
#import "Game.h"
#import "Config.h"
#import "SNSHelper.h"
#import "UIDevice+IdentifierAddition.h"
#include <sys/xattr.h>
#if (GAME_SNS_TYPE==5 || GAME_SNS_TYPE==6 || GAME_SNS_TYPE==7)
#import "InAppPurchasesHelper.h"
#endif

@implementation MyNavigationController

// The available orientations should be defined in the Info.plist file.
// And in iOS 6+ only, you can override it in the Root View controller in the "supportedInterfaceOrientations" method.
// Only valid for iOS 6+. NOT VALID for iOS 4 / 5.
-(NSUInteger)supportedInterfaceOrientations {
	
	[SNSHelper updateOrientation];
	
	// iPhone only
	if( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ){
		return UIInterfaceOrientationMaskLandscape;
	}
	
	// iPad only
	return UIInterfaceOrientationMaskLandscape;
}

// Supported orientations. Customize it for your own needs
// Only valid on iOS 4 / 5. NOT VALID for iOS 6.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	
	[SNSHelper updateOrientation];
	
	// iPhone only
	if( [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ){
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	}
	
	// iPad only
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

// This is needed for iOS4 and iOS5 in order to ensure
// that the 1st scene has the correct dimensions
// This is not needed on iOS6 and could be added to the application:didFinish...
-(void) directorDidReshapeProjection:(CCDirector*)director
{
	if(director.runningScene == nil) {
		// Add the first scene to the stack. The director will draw it immediately into the framebuffer. (Animation is started automatically when the view is displayed.)
		// and add the scene to the stack. The director will run it when it automatically when the view is displayed.
		[director runWithScene: [Game shared]];
	}
}
@end

@implementation AppController

@synthesize window=window_, navController=navController_, director=director_;

-(void)checkOldData:(NSString*)key{
	
	NSFileManager * fileMgr = [NSFileManager defaultManager];
	
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString * libraryPath = [paths objectAtIndex:0];
	NSURL * path = [NSURL fileURLWithPath:[libraryPath stringByAppendingPathComponent:key]];
	
	BOOL isDir = NO;
	[fileMgr fileExistsAtPath:[path path] isDirectory:&isDir];
	
	if(isDir==YES){
		NSArray * paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString * cachesPath = [paths objectAtIndex:0];
		
		NSURL * target = [NSURL fileURLWithPath:[cachesPath stringByAppendingPathComponent:key]];
		NSError * error = nil;
		[fileMgr moveItemAtURL:path toURL:target error:&error];
	}
	
}

-(BOOL)addSkipBackupAttributeToItemAtURL:(NSURL*)URL{
	
	NSFileManager * fileMgr = [NSFileManager defaultManager];
	BOOL isDir = NO;
	BOOL exited = [fileMgr fileExistsAtPath:[URL path] isDirectory:&isDir];
	if (!(isDir == YES && exited == YES)) {
		[fileMgr createDirectoryAtPath:[URL path] withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	if(&NSURLIsExcludedFromBackupKey==nil){
		const char * filePath = [[URL path] fileSystemRepresentation];            
		const char * attrName = "com.apple.MobileBackup";
		u_int8_t attrValue = 1;
		int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0); 
		return result == 0;
	}else{
		NSError * error = nil;
		BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES] 
									  forKey:NSURLIsExcludedFromBackupKey 
									   error:&error];
		return success;
	}
	return NO;
}

-(void)registerDefaultsFromSettingsBundle{
	NSString * settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
	if(!settingsBundle) return;
	NSDictionary * settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
	NSArray * preferences = [settings objectForKey:@"PreferenceSpecifiers"];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	for(NSDictionary * preference in preferences){
		NSString * key = [preference objectForKey:@"Key"];
		if(key){
			if(![defaults objectForKey:key]){
				[defaults setObject:[preference objectForKey:@"DefaultValue"] forKey:key];
			}
		}
	}
	[defaults synchronize];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
	
	//[self addSkipBackupAttributeToItemAtURL:];
	
	[UIDevice updateInfo];
	
	[self checkOldData:GAME_DB_DIR];
	[self checkOldData:GAME_Resources_DIR];
	
	/*
	NSString * libraryPath = getLibraryPath();
	[self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:[libraryPath stringByAppendingPathComponent:GAME_DB_DIR]]];
	[self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:[libraryPath stringByAppendingPathComponent:GAME_Resources_DIR]]];
	*/
	
	[self performSelector:@selector(registerDefaultsFromSettingsBundle)];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] 
				forKey:@"zl_version"];
	[defaults synchronize];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert)];
	
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	[[UIApplication sharedApplication] cancelAllLocalNotifications];
	
	// Create the main window
	window_ = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Create an CCGLView with a RGB565 color buffer, and a depth buffer of 0-bits
	CCGLView *glView = [CCGLView viewWithFrame:[window_ bounds]
								   pixelFormat:kEAGLColorFormatRGB565	//kEAGLColorFormatRGBA8
								   depthFormat:0	//GL_DEPTH_COMPONENT24_OES
							preserveBackbuffer:NO
									sharegroup:nil
								 multiSampling:NO
							   numberOfSamples:0];
	glView.multipleTouchEnabled = YES;
	
	director_ = (CCDirectorIOS*) [CCDirector sharedDirector];
	director_.wantsFullScreenLayout = YES;
	
	// Display FSP and SPF
	//[director_ setDisplayStats:YES];
	
	// set FPS at 60
	[director_ setAnimationInterval:1.0/60];
	
	// attach the openglView to the director
	[director_ setView:glView];
	
	// 2D projection
	[director_ setProjection:kCCDirectorProjection2D];
	//[director setProjection:kCCDirectorProjection3D];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change this setting at any time.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
	
	if([Game iPhoneRuningOnGame]){
		
		// Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
		if( ! [director_ enableRetinaDisplay:YES] ){
			CCLOG(@"Retina Display Not supported");
		}else{
			[Game isRetinaDisplay:YES];
		}
		
		// If the 1st suffix is not found and if fallback is enabled then fallback suffixes are going to searched. If none is found, it will try with the name without suffix.
		// On iPad HD  : "-ipadhd", "-ipad",  "-hd"
		// On iPad     : "-ipad", "-hd"
		// On iPhone HD: "-hd"
		CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
		[sharedFileUtils setEnableFallbackSuffixes:NO];				// Default: NO. No fallback suffixes are going to be used
		[sharedFileUtils setiPhoneRetinaDisplaySuffix:@""];		// Default on iPhone RetinaDisplay is "-hd"
		//[sharedFileUtils setiPadSuffix:@"-ipad"];					// Default on iPad is "ipad"
		//[sharedFileUtils setiPadRetinaDisplaySuffix:@"-ipadhd"];	// Default on iPad RetinaDisplay is "-ipadhd"
		
	}else{
		
		// If the 1st suffix is not found and if fallback is enabled then fallback suffixes are going to searched. If none is found, it will try with the name without suffix.
		// On iPad HD  : "-ipadhd", "-ipad",  "-hd"
		// On iPad     : "-ipad", "-hd"
		// On iPhone HD: "-hd"
		CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
		[sharedFileUtils setEnableFallbackSuffixes:NO];				// Default: NO. No fallback suffixes are going to be used
		//[sharedFileUtils setiPhoneRetinaDisplaySuffix:@"-hd"];		// Default on iPhone RetinaDisplay is "-hd"
		[sharedFileUtils setiPadSuffix:@"-ipad"];					// Default on iPad is "ipad"
		[sharedFileUtils setiPadRetinaDisplaySuffix:@"-ipadhd"];	// Default on iPad RetinaDisplay is "-ipadhd"
		
	}
	
	// Assume that PVR images have premultiplied alpha
	[CCTexture2D PVRImagesHavePremultipliedAlpha:YES];
	
	// Create a Navigation Controller with the Director
	navController_ = [[MyNavigationController alloc] initWithRootViewController:director_];
	navController_.navigationBarHidden = YES;

	// for rotation and other messages
	[director_ setDelegate:navController_];
	
	// set the Navigation Controller as the root view controller
	[window_ setRootViewController:navController_];
	
	// make main window visible
	[window_ makeKeyAndVisible];
	
	[SNSHelper initSNS:launchOptions];

	
#if (GAME_SNS_TYPE==5 || GAME_SNS_TYPE==6 || GAME_SNS_TYPE==7)
	[InAppPurchasesHelper shared];
#endif
	return YES;
}

-(BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url{
	if(url){
		
	}
	return YES;
}

// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
	if( [navController_ visibleViewController] == director_ ){
		[director_ pause];
		[Game resignActive];
	}
}

// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
	
	[SNSHelper applicationDidBecomeActive];
	
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];	
	if( [navController_ visibleViewController] == director_ ){
		[director_ resume];
		[Game becomeActive];
	}
}

-(void) applicationDidEnterBackground:(UIApplication*)application
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];
	
	if( [navController_ visibleViewController] == director_ ){
		[director_ stopAnimation];
		[Game enterBackground];
	}
	
}

-(void) applicationWillEnterForeground:(UIApplication*)application{
	
	if( [navController_ visibleViewController] == director_ ){
		[director_ startAnimation];
		[Game enterForeground];
	}
	
	[[SNSHelper shared] pause];
}

// application will be killed
- (void)applicationWillTerminate:(UIApplication *)application
{
	CC_DIRECTOR_END();
}

// purge memory
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[Game receiveMemoryWarning];
	[[CCDirector sharedDirector] purgeCachedData];
}

// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

-(void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken{
	
	NSString * token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	[UIDevice setDeviceToken:token];
	
	[SNSHelper applicationDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
	
}

-(void)application:(UIApplication*)app didFailToRegisterForRemoteNotificationsWithError:(NSError*)error{
	
}

-(void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo{
	
	[SNSHelper applicationDidReceiveRemoteNotification:userInfo];
	
}

-(BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation{
	
	[SNSHelper applicationOpenURL:url application:application];
	
	return YES;
}

#if GAME_SNS_TYPE==8
- (NSUInteger)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window{
	//return UIInterfaceOrientationMaskLandscape;
	return UIInterfaceOrientationMaskAll;
}
#endif

- (void) dealloc
{
	[window_ release];
	[navController_ release];
	
	[super dealloc];
}
@end
