//
//  FAWExternalTestViewController.h
//  EDC17EMS
//
//  Created by Zephyr on 15-7-4.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FAWExternalTestViewController : UIViewController

@property (strong, nonatomic) NSMutableArray * menuTextsArray;
@property (strong, nonatomic) NSMutableArray * menuImagesArray;
@property (strong, nonatomic) NSMutableArray * menuControllersArray;
@property (weak, nonatomic) IBOutlet UITableView *menuTableView;

@end
