//
//  FAWMainViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-6-28.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWVehicleDataViewController.h"
#import "FAWDynamicDataViewController.h"
#import "FAWFaultDiagnosisViewController.h"
#import "FAWExternalTestViewController.h"
#import "FAWAftertreatmentTestViewController.h"
#import "FAWROIViewController.h"
#import "FAWAppDelegate.h"
#import "FAWMainViewController.h"

@interface FAWMainViewController ()

@end

@implementation FAWMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.menuControllersPreniumArray = [NSMutableArray arrayWithObjects:[[FAWVehicleDataViewController alloc] initWithNibName:@"FAWVehicleDataViewController" bundle:nil], [[FAWDynamicDataViewController alloc] initWithNibName:@"FAWDynamicDataViewController" bundle:nil], [[FAWFaultDiagnosisViewController alloc] initWithNibName:@"FAWFaultDiagnosisViewController" bundle:nil], [[FAWExternalTestViewController alloc] initWithNibName:@"FAWExternalTestViewController" bundle:nil], [[FAWAftertreatmentTestViewController alloc] initWithNibName:@"FAWAftertreatmentTestViewController" bundle:nil], [[FAWROIViewController alloc] initWithNibName:@"FAWROIViewController" bundle:nil],nil];
        
        self.menuControllersNormalArray = [NSMutableArray arrayWithObjects:[[FAWVehicleDataViewController alloc] initWithNibName:@"FAWVehicleDataViewController" bundle:nil], [[FAWDynamicDataViewController alloc] initWithNibName:@"FAWDynamicDataViewController" bundle:nil], [[FAWFaultDiagnosisViewController alloc] initWithNibName:@"FAWFaultDiagnosisViewController" bundle:nil], [[FAWROIViewController alloc] initWithNibName:@"FAWROIViewController" bundle:nil],nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"EDC17EMS";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"注销" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.userPrivilege = ((FAWAppDelegate *)[[UIApplication sharedApplication] delegate]).userPrivilege;
    
    if (self.userPrivilege == 0)
    {
        self.menuTextsArray = [NSMutableArray arrayWithObjects:@"车辆数据", @"动态数据", @"故障诊断", @"外部测试", @"后处理测试", @"用户关注点", nil];
        self.menuControllersArray = self.menuControllersPreniumArray;
    }
    
    if (self.userPrivilege == 1)
    {
        self.menuTextsArray = [NSMutableArray arrayWithObjects:@"车辆数据", @"动态数据", @"故障诊断", @"用户关注点", nil];
        self.menuControllersArray = self.menuControllersNormalArray;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    NSIndexPath * selectedIndexPath = self.menuTableView.indexPathForSelectedRow;
    [self.menuTableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.menuTextsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * tableViewCell = [self.menuTableView dequeueReusableCellWithIdentifier:@"MenuTableViewCell"];
    
    if (tableViewCell == nil)
    {
        tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MenuTableViewCell"];
    }
    
    tableViewCell.textLabel.text = [self.menuTextsArray objectAtIndex:indexPath.row];
    tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return tableViewCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController pushViewController:[self.menuControllersArray objectAtIndex:indexPath.row] animated:YES];
}

- (void)backButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
