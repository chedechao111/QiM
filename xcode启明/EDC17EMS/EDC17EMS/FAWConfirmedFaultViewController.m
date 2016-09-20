//
//  FAWConfirmedFaultViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-6.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWFrozenInfoViewController.h"
#import "FAWConfirmedFaultViewController.h"

@interface FAWConfirmedFaultViewController ()

@end

@implementation FAWConfirmedFaultViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        NSString * faultDescriptionsFilePath = [[NSBundle mainBundle] pathForResource:@"FaultDescriptions" ofType:@"plist"];
        self.faultDescriptionsDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:faultDescriptionsFilePath];
        
        
        self.businessLayer = ((FAWAppDelegate *)([[UIApplication sharedApplication] delegate])).businessLayer;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.contentTextsArray = [[NSMutableArray alloc] init];
    self.contentValuesArray = [[NSMutableArray alloc] init];
    self.contentExtrasArray = [[NSMutableArray alloc] init];
    
    [self.contentTableView reloadData];
    
    self.noFaultNotice.hidden = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"历史故障";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"获取" style:UIBarButtonItemStylePlain target:self action:@selector(actButtonPressed:)];
    
    self.noFaultNotice = [[UILabel alloc] initWithFrame:CGRectMake(0, 190, self.contentTableView.bounds.size.width, 22)];
    
    self.noFaultNotice.text = @"没有可显示的故障信息";
    self.noFaultNotice.textColor = [UIColor grayColor];
    self.noFaultNotice.font = [UIFont fontWithName:@"Helvetica" size:15];
    self.noFaultNotice.textAlignment = NSTextAlignmentCenter;
    self.noFaultNotice.backgroundColor = [UIColor clearColor];
    
    [self.contentTableView addSubview:self.noFaultNotice];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.contentTableView deselectRowAtIndexPath:[self.contentTableView indexPathForSelectedRow] animated:YES];
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
    return [self.contentTextsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * tableViewCell = [self.contentTableView dequeueReusableCellWithIdentifier:@"ContentTableViewCell"];
    
    if (tableViewCell == nil)
    {
        tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ContentTableViewCell"];
        tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    tableViewCell.textLabel.text = [self.contentTextsArray objectAtIndex:indexPath.row];
    tableViewCell.detailTextLabel.text = [self.contentValuesArray objectAtIndex:indexPath.row];
    
    return tableViewCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FAWFrozenInfoViewController * frozenInfoViewController = [[FAWFrozenInfoViewController alloc] initWithNibName:@"FAWFrozenInfoViewController" bundle:nil];
    
    frozenInfoViewController.navigationItemTitle = [NSString stringWithFormat:@"%@ 冻结帧", [self.contentTextsArray objectAtIndex:indexPath.row]];
    frozenInfoViewController.faultData = [self.contentExtrasArray objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:frozenInfoViewController animated:YES];
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actButtonPressed:(id)sender
{
    [self.contentTextsArray removeAllObjects];
    [self.contentValuesArray removeAllObjects];
    [self.contentExtrasArray removeAllObjects];
    
    [self.contentTableView reloadData];
    
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.noFaultNotice.hidden = YES;
    
    [SVProgressHUD showWithStatus:@"正在获取, 请稍后..." maskType:SVProgressHUDMaskTypeBlack];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self asyncWorkStarted];
                   });
}

- (void)asyncWorkStarted
{
    Error error = Success;
    
    NSMutableArray * tempFaultsArray = nil;
    
    error = [self.businessLayer prepareOperation];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    error = [self.businessLayer readConfirmedDTCToArray:&tempFaultsArray];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    for (NSInteger i = 0; i < [tempFaultsArray count]; ++i)
    {
        NSMutableDictionary * faultDictionary = [tempFaultsArray objectAtIndex:i];
        
        NSString * faultCode = [faultDictionary objectForKey:@"code"];
        
        [self.contentTextsArray addObject:faultCode];
        
        NSData * faultData = [faultDictionary objectForKey:@"data"];
        
        [self.contentExtrasArray addObject:faultData];
        
        NSString * faultDescription = [self.faultDescriptionsDictionary objectForKey:faultCode];
        
        if (faultDescription)
        {
            [self.contentValuesArray addObject:faultDescription];
        }
        else
        {
            [self.contentValuesArray addObject:@"未知故障"];
        }
    }
    
theEnd:
    
    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      [self.contentTableView reloadData];
                      
                      if (![self.contentTextsArray count])
                      {
                          self.noFaultNotice.hidden = NO;
                      }
                      
                      if (error == Success)
                      {
                          [SVProgressHUD showSuccessWithStatus:@"故障获取成功."];
                      }
                      else
                      {
                          [SVProgressHUD showErrorWithStatus:[self.businessLayer getErrorMessage:error]];
                      }
                      
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.enabled = YES;
                  });
    
    return;
}

@end
