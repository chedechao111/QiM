//
//  FAWMainViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-6-28.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FAWMainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray * menuTextsArray;
@property (strong, nonatomic) NSMutableArray * menuImagesArray;
@property (strong, nonatomic) NSMutableArray * menuControllersNormalArray;
@property (strong, nonatomic) NSMutableArray * menuControllersPreniumArray;
@property (strong, nonatomic) NSMutableArray * menuControllersArray;
@property (weak, nonatomic) IBOutlet UITableView *menuTableView;
@property (nonatomic) NSInteger userPrivilege;

@end
