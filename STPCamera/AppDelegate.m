//
//  AppDelegate.m
//  STPCamera
//
//  Created by Norikazu on 2015/07/13.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [STPCameraViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}


@end
