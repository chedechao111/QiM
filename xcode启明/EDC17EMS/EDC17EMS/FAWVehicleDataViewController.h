//
//  FAWVehicleDataViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-4.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FAWBusinessLayer.h"

@interface FAWVehicleDataViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray * generalTextsArray;
@property (strong, nonatomic) NSMutableArray * generalValuesArray;
@property (strong, nonatomic) NSMutableArray * engineTextsArray;
@property (strong, nonatomic) NSMutableArray * engineValuesArray;
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

@property (strong, nonatomic) FAWBusinessLayer * businessLayer;

@end
