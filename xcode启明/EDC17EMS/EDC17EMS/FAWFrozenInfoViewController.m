//
//  FAWFrozenInfoViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-14.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWFrozenInfoViewController.h"

@interface FAWFrozenInfoViewController ()

@end

@implementation FAWFrozenInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentTextsArray = [NSMutableArray arrayWithObjects:@"计算负载值", @"中冷后温度", @"歧管绝对压力", @"发动机转速", @"车速", @"油压", @"气压", @"电压", @"环境温度", @"加速踏板位置1", nil];
        
        self.contentValuesArray = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < [self.contentTextsArray count]; ++i)
        {
            [self.contentValuesArray addObject:@"等待获取"];
        }
        
        self.businessLayer = ((FAWAppDelegate *)[[UIApplication sharedApplication] delegate]).businessLayer;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"获取" style:UIBarButtonItemStylePlain target:self action:@selector(actButtonPressed:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationItem.title = self.navigationItemTitle;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self actButtonPressed:nil];
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
    }
    
    tableViewCell.textLabel.text = [self.contentTextsArray objectAtIndex:indexPath.row];
    tableViewCell.detailTextLabel.text = [self.contentValuesArray objectAtIndex:indexPath.row];

    
    return tableViewCell;
}

- (void)actButtonPressed:(id)sender
{
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.contentValuesArray = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < [self.contentTextsArray count]; ++i)
    {
        [self.contentValuesArray addObject:@"等待获取"];
    }
    
    [self.contentTableView reloadData];
    
    [SVProgressHUD showWithStatus:@"正在获取, 请稍后..." maskType:SVProgressHUDMaskTypeBlack];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self asyncWorkStarted];
                   });
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)asyncWorkStarted
{
    Error error = Success;
    
    NSData * data = nil;
    
    Byte * bytes = nil;
    
    NSString * text = nil;

    error = [self.businessLayer prepareOperation];
        
    if (error != Success)
    {
        goto theEnd;
    }
    
    error = [self.businessLayer readFrozenFramesToData:&data byDTCData:self.faultData];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    if ([data length])
    {
        bytes = (Byte *)[data bytes];
        
        double number = bytes[0] * 0.012207;
        
        text = [NSString stringWithFormat:@"%.2f %%", number];
        
        [self.contentValuesArray replaceObjectAtIndex:0 withObject:text];
        
        number = bytes[1] - 40;
        
        text = [NSString stringWithFormat:@"%.2f ℃", number];
        
        [self.contentValuesArray replaceObjectAtIndex:1 withObject:text];
        
        number = bytes[2];
        
        text = [NSString stringWithFormat:@"%.2f kPa", number];
        
        [self.contentValuesArray replaceObjectAtIndex:2 withObject:text];
        
        number = ((bytes[3] << 8) + bytes[4]) * 0.25;
        
        text = [NSString stringWithFormat:@"%.2f rpm", number];
        
        [self.contentValuesArray replaceObjectAtIndex:3 withObject:text];
        
        number = bytes[5];
        
        text = [NSString stringWithFormat:@"%.2f km", number];
        
        [self.contentValuesArray replaceObjectAtIndex:4 withObject:text];
        
        number = ((bytes[6] << 8) + bytes[7]) * 100;
        
        text = [NSString stringWithFormat:@"%.2f hPa", number];
        
        [self.contentValuesArray replaceObjectAtIndex:5 withObject:text];
        
        number = bytes[8];
        
        text = [NSString stringWithFormat:@"%.2f kPa", number];
        
        [self.contentValuesArray replaceObjectAtIndex:6 withObject:text];
        
        number = ((bytes[9] << 8) + bytes[10]) * 0.001;
        
        text = [NSString stringWithFormat:@"%.2f V", number];
        
        [self.contentValuesArray replaceObjectAtIndex:7 withObject:text];
        
        number = bytes[11];
        
        text = [NSString stringWithFormat:@"%.2f ℃", number];
        
        [self.contentValuesArray replaceObjectAtIndex:8 withObject:text];
        
        number = bytes[12] * 19.62156;
        
        text = [NSString stringWithFormat:@"%.2f mV", number];
        
        [self.contentValuesArray replaceObjectAtIndex:9 withObject:text];
    }
    else
    {
        for (NSInteger i = 0; i < [self.contentTextsArray count]; ++i)
        {
            [self.contentValuesArray replaceObjectAtIndex:i withObject:@"暂无信息"];
        }
    }
    
theEnd:
    
    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      if (error != Success)
                      {
                          [SVProgressHUD showErrorWithStatus:[self.businessLayer getErrorMessage:error]];
                      }
                      else
                      {
                          [SVProgressHUD showSuccessWithStatus:@"冻结帧获取成功."];
                      }
                      
                      [self.contentTableView reloadData];
                      
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.enabled = YES;
                  });
        
        return;
}

@end
