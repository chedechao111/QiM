//
//  FAWFaultDiagnosisViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-5.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWAppDelegate.h"
#import "FAWBusinessLayer.h"
#import <UIKit/UIKit.h>

@interface FAWFaultDiagnosisViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>

@property (strong, nonatomic) NSMutableArray * menuTextsArray;
@property (strong, nonatomic) NSMutableArray * menuImagesArray;
@property (strong, nonatomic) NSMutableArray * menuControllersArray;
@property (weak, nonatomic) IBOutlet UITableView *menuTableView;
@property (strong, nonatomic) UIActionSheet * noticeActionSheet;
@property (strong, nonatomic) FAWBusinessLayer * businessLayer;

@end
