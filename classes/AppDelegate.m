//
//  AppDelegate.m
//  mdxplayer
//
//  Created by asada on 2013/04/03.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import "AppDelegate.h"
#import "CFileManager.h"
#import <Dropbox/Dropbox.h>

NSString *kNotifyNetOn = @"__NETON";
NSString *kNotifyNetOff = @"__NETOFF";


@implementation AppDelegate
{
    int netcnt;
	UIBackgroundTaskIdentifier backgroundTask; 
}

-(void)startNetActive
{
    netcnt++;
    if(netcnt) [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void)endNetActive
{
    netcnt--;
    if(netcnt < 0) netcnt = 0;
    if(!netcnt) [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(PlayerVC*) playerVC {
    if (!_playerVC)
        _playerVC = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"player"];
    return _playerVC;
}

-(NSString*) cFileManagerStyledPathForPath:(NSString*)path {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsPath = [paths objectAtIndex:0];
    
    // Deal with /private/var paths
    if ([path hasPrefix:@"/private/var"] && [documentsPath hasPrefix:@"/var"])
        documentsPath = [@"/private" stringByAppendingString:documentsPath];
    
    return [path stringByReplacingOccurrencesOfString:documentsPath withString:cfmFolderDocuments];
}

-(BOOL) processFileURL:(NSURL*)url {
    if (url && [url isFileURL]) {
        NSString* filePath = [self cFileManagerStyledPathForPath:[url path]];
        NSString* parentPath = [filePath stringByDeletingLastPathComponent];
        [self.playerVC playFile:filePath path:parentPath];
        return YES;
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//	[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navbar1"] forBarMetrics:UIBarMetricsDefault];
//	[[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName  : [UIColor colorWithWhite:0.3 alpha:1],
//						 NSShadowAttributeName : [UIColor clearColor]}];

//	[[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
	
    [NCenter addObserver:self selector:@selector(startNetActive) name:kNotifyNetOn object:nil];
    [NCenter addObserver:self selector:@selector(endNetActive) name:kNotifyNetOff object:nil];

    return YES;
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([self processFileURL:url])
        return YES;
    
	DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
	if (account)
    {
        [NCenter postNotificationName:@"DROPBOX_LOGINED" object:nil];
	}
	
	return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
	
	backgroundTask = [application beginBackgroundTaskWithExpirationHandler: ^{
		[application endBackgroundTask:backgroundTask];
	}];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type != UIEventTypeRemoteControl) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"REMOTE" object:event userInfo:nil];
}

@end
