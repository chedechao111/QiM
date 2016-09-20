//
//  FAWAppDelegate.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-2.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FAWBusinessLayer.h"

@interface FAWAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSInteger userPrivilege;
@property (strong, nonatomic) FAWBusinessLayer *businessLayer;

@end
