//
//  FAWHiPotTestViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-7.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWAppDelegate.h"
#import "FAWBusinessLayer.h"
#import <UIKit/UIKit.h>

@interface FAWHiPotTestViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray * contentTextsArray;
@property (strong, nonatomic) NSMutableArray * contentValuesArray;
@property (strong, nonatomic) FAWBusinessLayer * businessLayer;
@property (nonatomic) BOOL isNowWorking;

@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

@end
