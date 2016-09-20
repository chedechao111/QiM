//
//  FAWConfirmedFaultViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-6.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWAppDelegate.h"
#import "FAWBusinessLayer.h"
#import <UIKit/UIKit.h>

@interface FAWConfirmedFaultViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray * contentTextsArray;
@property (strong, nonatomic) NSMutableArray * contentValuesArray;
@property (strong, nonatomic) NSMutableArray * contentExtrasArray;
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

@property (strong, nonatomic) UILabel * noFaultNotice;
@property (strong, nonatomic) NSMutableDictionary * faultDescriptionsDictionary;
@property (strong, nonatomic) FAWBusinessLayer * businessLayer;

@end
