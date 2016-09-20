//
//  FAWCompressionTestViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-5.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "SVProgressHUD.h"
#import "FAWAppDelegate.h"
#import "FAWCompressionTestViewController.h"

@interface FAWCompressionTestViewController ()

@end

@implementation FAWCompressionTestViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.contentSectionsArray = [NSMutableArray arrayWithObjects:@"第1缸", @"第2缸", @"第3缸", @"第4缸", @"第5缸", @"第6缸", nil];
        self.contentTextsArray = [NSMutableArray arrayWithObjects:@"时间", @"转速", @"偏差", nil];
        
        self.businessLayer = ((FAWAppDelegate *)([[UIApplication sharedApplication] delegate])).businessLayer;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.contentValuesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.contentSectionsArray count]; ++i)
    {
        NSMutableArray * tempArray = [NSMutableArray arrayWithObjects:@"等待测试", @"等待测试", @"等待测试", nil];
        [self.contentValuesArray addObject:tempArray];
    }
    
    [self.contentTableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"压缩测试";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"测试" style:UIBarButtonItemStylePlain target:self action:@selector(actButtonPressed:)];
    self.noticeAlertView = [[UIAlertView alloc] initWithTitle:@"请您确认" message:@"开始压缩测试之前, 请将机动车钥匙门置于ON挡位置, 若您已经完成该操作, 请点击\"继续\", 否则请点击\"停止\"." delegate:self cancelButtonTitle:@"停止" otherButtonTitles:@"继续", nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.contentSectionsArray count];
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
    NSMutableArray * tempArray = [self.contentValuesArray objectAtIndex:indexPath.section];
    tableViewCell.detailTextLabel.text = [tempArray objectAtIndex:indexPath.row];
    
    return tableViewCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.contentSectionsArray objectAtIndex:section];
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actButtonPressed:(id)sender
{
    if (!self.isNowWorking)
    {
        [self.noticeAlertView show];
    }
    else
    {
        self.isNowWorking = NO;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        return;
    }
    
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.title = @"停止";
    
    self.contentValuesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.contentSectionsArray count]; ++i)
    {
        NSMutableArray * tempArray = [NSMutableArray arrayWithObjects:@"等待测试", @"等待测试", @"等待测试", nil];
        [self.contentValuesArray addObject:tempArray];
    }
    
    [self.contentTableView reloadData];
    
    self.isNowWorking = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self asyncWorkStarted];
                   });
}

- (void)asyncWorkStarted
{
    Error error = Success;
    Byte routineBytes[13] = {0x00};
    NSData * routineData = nil;
    NSInteger counter = 0;
    NSData * tempData = nil;
    Byte * tempBytes = nil;
    ushort identifiers[] = {0x01f2, 0x01f6, 0x01f4, 0x01f7, 0x01f3, 0x01f5};
    double times[6] = {0};
    double speeds[6] = {0};
    double minuts[6] = {0};
    NSUInteger specialError = 0;
    
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
    
    routineData = [NSData dataWithBytes:routineBytes length:sizeof(routineBytes)];
    
    error = [self.businessLayer startRoutineControlByIdentifier:0x0318 withData:routineData];
    
    if (!self.isNowWorking)
    {
        error = Canceled;
    }
    
    if (error != Success && error != NegativeResponse)
    {
        goto theEnd;
    }
    
    if (error == NegativeResponse)
    {
        NSData * data = nil;
        error = [self.businessLayer readData:&data byIdentifier:0x01eb];
        
        if (error != Success)
        {
            error = RoutineControlTimeout;
            goto theEnd;
        }
        
        Byte * dataBytes = (Byte *)[data bytes];
        
        specialError = dataBytes[0];
        
        error = RoutineControlException;
        
        goto theEnd;
    }

    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      [SVProgressHUD showWithStatus:@"请将机动车钥匙门置于START挡, 并保持其一直处于该位置..."];
                  });
    
    while (YES)
    {
        error = [self.businessLayer readData:&tempData byIdentifier:0x015e];
        
        if (!self.isNowWorking)
        {
            error = Canceled;
            goto theEnd;
        }
        
        if (error != Success)
        {
            goto theEnd;
        }
        
        tempBytes = (Byte *)[tempData bytes];
        
        double number = (NSInteger)((tempBytes[0] << 8) + tempBytes[1]) * 0.5;
        
        if (number)
        {
            break;
        }
        
        ++counter;
        
        if (counter > 9)
        {
            error = RoutineControlTimeout;
            goto theEnd;
        }
    }
    
    counter = 0;
    
    while (YES)
    {
        error = [self.businessLayer getRoutineControlStatusByIdentifier:0x0318];
        
        if (!self.isNowWorking)
        {
            error = Canceled;
            goto theEnd;
        }
        
        if (error == Success)
        {
            break;
        }
        
        if (error == RoutineControlFailure)
        {
            NSData * stopFlagData = nil;
            Error innerError = [self.businessLayer readData:&stopFlagData byIdentifier:0x01eb];
            
            if (!self.isNowWorking)
            {
                error = Canceled;
                goto theEnd;
            }
            
            if (innerError != Success && innerError != NegativeResponse)
            {
                error = innerError;
                goto theEnd;
            }
            
            if (innerError == Success)
            {
                Byte * stopFlagBytes = (Byte *)[stopFlagData bytes];
                
                if (stopFlagBytes[0])
                {
                    error = RoutineControlException;
                    specialError = stopFlagBytes[0];
                    goto theEnd;
                }
            }
            else
            {
                error = RoutineControlTimeout;
                goto theEnd;
            }
        }
        
        if (error != RoutineControlFailure && error != NegativeResponse)
        {
            goto theEnd;
        }
        
        ++counter;
        
        if (counter > 29)
        {
            error = RoutineControlTimeout;
            goto theEnd;
        }
        
        sleep(1);
    }
    
    for (int i = 0; i < sizeof(identifiers) / sizeof(identifiers[0]); ++i)
    {
        error = [self.businessLayer readData:&tempData byIdentifier:identifiers[i]];
        
        if (!self.isNowWorking)
        {
            error = Canceled;
        }
        
        if (error != Success)
        {
            goto theEnd;
        }
        
        tempBytes = (Byte *)[tempData bytes];
        
        times[i] = (double)((tempBytes[0] << 24) + (tempBytes[1] << 16) + (tempBytes[2] << 8) + tempBytes[3]);
        speeds[i] = 1000000 / times[i];
    }
    
    for (int i = 0; i < sizeof(identifiers) / sizeof(identifiers[0]); ++i)
    {
        double temp = 0;
        
        for (int j = 0; j < sizeof(identifiers) / sizeof(identifiers[0]); ++j)
        {
            if (i != j)
            {
                temp += times[j];
            }
        }
        
        temp = temp / (sizeof(identifiers) / sizeof(identifiers[0]) - 1);
        
        minuts[i] = ((times[i] - temp) >= 0 ? (times[i] - temp) : (temp - times[i])) / times[i];
    }

    for (int i = 0; i < [self.contentValuesArray count]; ++i)
    {
        NSMutableArray * array = [self.contentValuesArray objectAtIndex:i];
        
        [array replaceObjectAtIndex:0 withObject:[NSString stringWithFormat:@"%.2f", times[i]]];
        [array replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%.2f", speeds[i]]];
        [array replaceObjectAtIndex:2 withObject:[NSString stringWithFormat:@"%.2f", minuts[i]]];
    }
    
theEnd:
    
    [self.businessLayer stopRoutineControlByIdentifier:0x0318];
    
    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      if (error != Success)
                      {
                          if (error != RoutineControlException)
                          {
                              [SVProgressHUD showErrorWithStatus:[self.businessLayer getErrorMessage:error]];
                          }
                          else
                          {
                              NSMutableString * errorMessage = [[NSMutableString alloc] init];
                              
                              if (specialError & 1)
                              {
                                  [errorMessage appendString:@"系统故障存在.\n"];
                              }
                              
                              if (specialError & 4)
                              {
                                  [errorMessage appendString:@"车速不是0.\n"];
                              }
                              
                              if (specialError & 16)
                              {
                                  [errorMessage appendString:@"测试启动时发动机转速不为0.\n"];
                              }
                              
                              if (specialError & 32)
                              {
                                  [errorMessage appendString:@"测试超时.\n"];
                              }
                              
                              if (specialError & 64)
                              {
                                  [errorMessage appendString:@"测试中电池电压过低.\n"];
                              }
                              
                              [SVProgressHUD showErrorWithStatus:errorMessage];
                          }
                      }
                      else
                      {
                          [SVProgressHUD showSuccessWithStatus:@"压缩测试完成"];
                      }
                      
                      self.isNowWorking = NO;
                      
                      [self.contentTableView reloadData];
                      
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.title = @"测试";
                  });
    
    return;
}

@end
