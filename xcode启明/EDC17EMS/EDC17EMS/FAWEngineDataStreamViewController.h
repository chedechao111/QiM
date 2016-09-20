//
//  FAWEngineDataStreamViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-2.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FAWAppDelegate.h"
#import "FAWBusinessLayer.h"

@interface FAWEngineDataStreamViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray * contentTextsArray;
@property (strong, nonatomic) NSMutableArray * contentValuesArray;
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;
@property (nonatomic) BOOL isNowWorking;
@property (nonatomic) NSInteger dataIndex;
@property (strong, nonatomic) FAWBusinessLayer * businessLayer;

@end
