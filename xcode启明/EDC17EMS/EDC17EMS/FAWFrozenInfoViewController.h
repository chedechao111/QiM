//
//  FAWFrozenInfoViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-14.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWAppDelegate.h"
#import "FAWBusinessLayer.h"
#import <UIKit/UIKit.h>

@interface FAWFrozenInfoViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray * contentTextsArray;
@property (strong, nonatomic) NSMutableArray * contentValuesArray;
@property (strong, nonatomic) FAWBusinessLayer * businessLayer;
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;
@property (strong, nonatomic) NSString * navigationItemTitle;
@property (strong, nonatomic) NSData * faultData;

@end
