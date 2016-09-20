//
//  FAWAftertreatmentTestViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-11.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FAWAppDelegate.h"
#import "FAWBusinessLayer.h"

@interface FAWAftertreatmentTestViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray * contentTextsArray;
@property (strong, nonatomic) NSMutableArray * contentValuesArray;
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;
@property (strong, nonatomic) FAWBusinessLayer * businessLayer;
@property (nonatomic) BOOL isNowWorking;
@property (nonatomic) NSInteger dataIndex;

@end
