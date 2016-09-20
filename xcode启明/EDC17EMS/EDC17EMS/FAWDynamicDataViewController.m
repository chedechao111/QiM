//
//  FAWDynamicDataViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-11.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWEngineDataStreamViewController.h"
#import "FAWVehicleDataStreamViewController.h"
#import "FAWAftertreatmentDataStreamViewController.h"
#import "FAWDynamicDataViewController.h"

@interface FAWDynamicDataViewController ()

@end

@implementation FAWDynamicDataViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.menuTextsArray = [NSMutableArray arrayWithObjects:@"发动机数据流", @"整车数据流", @"后处理数据流", nil];
        self.menuControllersArray = [NSMutableArray arrayWithObjects:[[FAWEngineDataStreamViewController alloc] initWithNibName:@"FAWEngineDataStreamViewController" bundle:nil], [[FAWVehicleDataStreamViewController alloc] initWithNibName:@"FAWVehicleDataStreamViewController" bundle:nil], [[FAWAftertreatmentDataStreamViewController alloc] initWithNibName:@"FAWAftertreatmentDataStreamViewController" bundle:nil], nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"动态数据";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.menuTableView deselectRowAtIndexPath:[self.menuTableView indexPathForSelectedRow] animated:YES];
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
    [self.navigationController popViewControllerAnimated:YES];
}

@end
