//
//  FAWCompressionTestViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-5.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FAWBusinessLayer.h"

@interface FAWCompressionTestViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableArray * contentSectionsArray;
@property (strong, nonatomic) NSMutableArray * contentTextsArray;
@property (strong, nonatomic) NSMutableArray * contentValuesArray;
@property (strong , nonatomic) FAWBusinessLayer * businessLayer;
@property (strong, nonatomic) UIAlertView * noticeAlertView;
@property (nonatomic) BOOL isNowWorking;

@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

@end
