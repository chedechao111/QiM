//
//  FAWROIViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-1.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWAppDelegate.h"
#import "FAWBusinessLayer.h"
#import <UIKit/UIKit.h>

@interface FAWROIViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray * contentTextsArray;
@property (strong, nonatomic) NSMutableArray * contentValuesArray;
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

@property (nonatomic) BOOL isNowWorking;
@property (nonatomic) NSInteger dataIndex;
@property (strong, nonatomic) FAWBusinessLayer * businessLayer;

@end
