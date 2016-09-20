//
//  FAWStartupFaultTestViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-10.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWStartupFaultTestViewController.h"

@interface FAWStartupFaultTestViewController ()

@end

@implementation FAWStartupFaultTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.businessLayer = ((FAWAppDelegate *)([[UIApplication sharedApplication] delegate])).businessLayer;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"启动故障信息";
    
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

- (void)viewWillAppear:(BOOL)animated
{
    self.contentTextsArray = [[NSMutableArray alloc] init];
    
    [self.contentTableView reloadData];
    
    self.noFaultNotice.hidden = NO;
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
        tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ContentTableViewCell"];
    }
    
    tableViewCell.textLabel.text = [self.contentTextsArray objectAtIndex:indexPath.row];
    
    return tableViewCell;
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actButtonPressed:(id)sender
{
    [self.contentTextsArray removeAllObjects];
    
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
    NSData * faultData = nil;
    Byte * faultBytes = nil;
    NSInteger faultNumber = 0;
    
    error = [self.businessLayer prepareOperation];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    error = [self.businessLayer changeSessionMode:0x40];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    error = [self.businessLayer passAccessLimit];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    error = [self.businessLayer readData:&faultData byIdentifier:0x0193];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    faultBytes = (Byte *)[faultData bytes];
    
    faultNumber = faultBytes[0];
    
    //当数据为0时表示无故障信息
    if (!faultNumber)
    {
        goto theEnd;
    }
    else if (faultNumber & 1)
    {
        [self.contentTextsArray addObject:@"轨压建立失败"];
    }
    else if (faultNumber & 2)
    {
        [self.contentTextsArray addObject:@"启动转速过低"];
    }
    else if (faultNumber & 4)
    {
        [self.contentTextsArray addObject:@"发动机同步信号异常"];
    }
    else if (faultNumber & 8)
    {
        [self.contentTextsArray addObject:@"严重系统故障"];
    }
    else if (faultNumber & 32)
    {
        [self.contentTextsArray addObject:@"启动机继电器工作异常"];
    }
    else
    {
        [self.contentTextsArray addObject:@"其他故障"];
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
                          [SVProgressHUD showSuccessWithStatus:@"启动故障获取成功."];
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
