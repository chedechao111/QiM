//
//  FAWSpeedCompareTestViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-10.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWSpeedCompareTestViewController.h"

@interface FAWSpeedCompareTestViewController ()

@end

@implementation FAWSpeedCompareTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentTextsArray = [NSMutableArray arrayWithObjects:@"第1缸转速", @"第2缸转速", @"第3缸转速", @"第4缸转速", @"第5缸转速", @"第6缸转速", nil];
        
        self.businessLayer = ((FAWAppDelegate *)([[UIApplication sharedApplication] delegate])).businessLayer;
        
        self.dataIndex = -1;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.contentValuesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.contentTextsArray count]; ++i)
    {
        [self.contentValuesArray addObject:@"等待测试"];
    }
    
    [self.contentTableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"转速比较";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"测试" style:UIBarButtonItemStylePlain target:self action:@selector(actButtonPressed:)];
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
        tableViewCell.accessoryView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    tableViewCell.textLabel.text = [self.contentTextsArray objectAtIndex:indexPath.row];
    tableViewCell.detailTextLabel.text = [self.contentValuesArray objectAtIndex:indexPath.row];
    
    UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)tableViewCell.accessoryView;
    
    if (self.dataIndex == indexPath.row)
    {
        activityIndicatorView.hidden = NO;
        [activityIndicatorView startAnimating];
    }
    else
    {
        [activityIndicatorView stopAnimating];
        activityIndicatorView.hidden = YES;
    }
    
    return tableViewCell;
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actButtonPressed:(id)sender
{
    if (!self.isNowWorking)
    {
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"停止";
        
        self.isNowWorking = YES;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{
                           [self asyncWorkStarted];
                       });
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [SVProgressHUD showWithStatus:@"正在停止..."];
        
        self.isNowWorking = NO;
    }
}

- (void)asyncWorkStarted
{
    Error error = Success;
    NSInteger counter = 0;
    
    //发动机每缸转速, 数组元素分别对应发动机1、2、3、4、5、6缸.
    ushort speedIdentifiers[] = {0x01d1, 0x01d5, 0x01d3, 0x01d6, 0x01d2, 0x01d4};
    
    if (!self.isNowWorking)
    {
        error = Canceled;
        goto theEnd;
    }
    
    error = [self.businessLayer prepareOperation];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    //改变会话模式: 会话模式标识码0x40, 意义未知.
    error = [self.businessLayer changeSessionMode:0x40];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    error = [self.businessLayer passAccessLimit];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    //转速比较, 例程服务标识0x0312.
    error = [self.businessLayer startRoutineControlByIdentifier:0x0312 withData:nil];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    sleep(1);
    
    while (YES)
    {
        for (int i = 0; i < sizeof(speedIdentifiers) / sizeof(speedIdentifiers[0]); ++i)
        {
            self.dataIndex = i;
            
            dispatch_sync(dispatch_get_main_queue(),
                          ^{
                              UITableViewCell *tableViewCell = [self.contentTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataIndex inSection:0]];
                              UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)tableViewCell.accessoryView;
                              activityIndicatorView.hidden = NO;
                              [activityIndicatorView startAnimating];
                          });
            
            NSData * speedData = nil;
            error = [self.businessLayer readData:&speedData byIdentifier:speedIdentifiers[i]];
            
            if (!self.isNowWorking)
            {
                error = Canceled;
                goto theEnd;
            }
            
            NSString * speedText = nil;
            
            if (error != Success)
            {
                speedText = @"测试失败";
            }
            else
            {
                Byte * speedBytes = (Byte *)[speedData bytes];
                
                double speedNumber = ((speedBytes[0] << 8) + speedBytes[1]) * 0.5;
                
                speedText = [NSString stringWithFormat:@"%.2f rpm", speedNumber];
            }
            
            [self.contentValuesArray replaceObjectAtIndex:self.dataIndex withObject:speedText];
            
            dispatch_sync(dispatch_get_main_queue(),
                          ^{
                              UITableViewCell *tableViewCell = [self.contentTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataIndex inSection:0]];
                              UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)tableViewCell.accessoryView;
                              tableViewCell.detailTextLabel.text = speedText;
                              [activityIndicatorView stopAnimating];
                              activityIndicatorView.hidden = YES;
                          });
        }
        
        //请求例程状态
        error = [self.businessLayer getRoutineControlStatusByIdentifier:0x0312];
        
        if (error == Success)
        {
            break;
        }
        
        if (error != RoutineControlFailure)
        {
            goto theEnd;
        }
        
        ++counter;
        
        if (counter > 29)
        {
            error = Success;
            goto theEnd;
        }
        
        sleep(1);
    }
    
theEnd:
    
    //结束时停止服务标识为0x0312的例程控制.
    [self.businessLayer stopRoutineControlByIdentifier:0x0312];
    
    
    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      if (error != Success)
                      {
                          [SVProgressHUD showErrorWithStatus:[self.businessLayer getErrorMessage:error]];
                      }
                      else
                      {
                          [SVProgressHUD showSuccessWithStatus:@"转速比较测试完成."];
                      }
                      
                      self.dataIndex = -1;
                      self.isNowWorking = NO;
                      
                      [self.contentTableView reloadData];
                      
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.title = @"测试";
                  });
    
    return;
}

@end
