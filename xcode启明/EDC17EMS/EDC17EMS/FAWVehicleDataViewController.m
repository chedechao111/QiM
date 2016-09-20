//
//  FAWVehicleDataViewController.m
//  EDC17EMS
//
//  Created by Zephyr on 15-7-4.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import "FAWAppDelegate.h"
#import "SVProgressHUD.h"
#import "FAWVehicleDataViewController.h"

@interface FAWVehicleDataViewController ()

@end

@implementation FAWVehicleDataViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.generalTextsArray = [NSMutableArray arrayWithObjects:@"车辆标识码(VIN)", @"整车型号", nil];
        self.engineTextsArray = [NSMutableArray arrayWithObjects:@"OEM零件号", @"客户生产文件版本号", @"客户软件版本号", @"汽车制造商ECU软件版本号", @"系统供应商ECU软件号", @"汽车制造商ECU硬件号", @"系统供应商ECU硬件号", @"系统供应商ECU硬件版本号", @"系统供应商ECU软件号", @"系统供应商ECU软件版本号", @"系统名称或发动机型号", @"发动机标识码(EIN)", @"喷油器补偿量", nil];
        
        self.businessLayer = ((FAWAppDelegate *)([[UIApplication sharedApplication] delegate])).businessLayer;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.generalValuesArray = [[NSMutableArray alloc] init];
    self.engineValuesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [self.generalTextsArray count]; ++i)
    {
        [self.generalValuesArray addObject:@"等待获取"];
    }
    
    for (int i = 0; i < [self.engineTextsArray count]; ++i)
    {
        [self.engineValuesArray addObject:@"等待获取"];
    }
    
    [self.contentTableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"车辆数据";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"获取" style:UIBarButtonItemStylePlain target:self action:@selector(actButtonPressed:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"整车信息";
    }
    
    if (section == 1)
    {
        return @"发动机信息";
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return [self.generalTextsArray count];
    }
    
    if (section == 1)
    {
        return [self.engineTextsArray count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * tableViewCell = [self.contentTableView dequeueReusableCellWithIdentifier:@"ContentTableViewCell"];
    
    if (tableViewCell == nil)
    {
        tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ContentTableViewCell"];
    }
    
    if (indexPath.section == 0)
    {
        tableViewCell.textLabel.text = [self.generalTextsArray objectAtIndex:indexPath.row];
        tableViewCell.detailTextLabel.text = [self.generalValuesArray objectAtIndex:indexPath.row];
    }
    
    if (indexPath.section == 1)
    {
        tableViewCell.textLabel.text = [self.engineTextsArray objectAtIndex:indexPath.row];
        tableViewCell.detailTextLabel.text = [self.engineValuesArray objectAtIndex:indexPath.row];
    }
    
    return tableViewCell;
}

- (void)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actButtonPressed:(id)sender
{
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.generalValuesArray = [[NSMutableArray alloc] init];
    self.engineValuesArray = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < [self.generalTextsArray count]; ++i)
    {
        [self.generalValuesArray addObject:@"等待获取"];
    }
    
    for (NSInteger i = 0; i < [self.engineTextsArray count]; ++i)
    {
        [self.engineValuesArray addObject:@"等待获取"];
    }
    
    [self.contentTableView reloadData];
    
    [SVProgressHUD showWithStatus:@"正在获取, 请稍后..." maskType:SVProgressHUDMaskTypeBlack];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       [self asyncWorkStarted];
                   });
}

- (void)asyncWorkStarted
{
    Error error = Success;
    
    NSData * data = nil;
    
    Byte * bytes = nil;
    
    NSString * text = nil;
    
    unsigned short generalIdentifiers[] = {0xf190, 0xf1a5};
    unsigned short engineIdentifiers[] = {0xf187, 0xf120, 0xf121, 0xf189, 0xf18a, 0xf191, 0xf192, 0xf193, 0xf194, 0xf195, 0xf197, 0xf1a6, 0x03f6};
    
    error = [self.businessLayer prepareOperation];
    
    if (error != Success)
    {
        goto theEnd;
    }
    
    for (NSInteger i = 0; i < sizeof(generalIdentifiers) / sizeof(generalIdentifiers[0]); ++i)
    {
        error = [self.businessLayer readData:&data byIdentifier:generalIdentifiers[i]];
        
        if (error != Success)
        {
            goto theEnd;
        }
        
        bytes = (Byte *)[data bytes];
        
        text = [NSString stringWithCString:(char *)bytes encoding:NSUTF8StringEncoding];
        
        if (!text || [text compare:@""] == NSOrderedSame)
        {
            text = @"不可见";
        }
        
        [self.generalValuesArray replaceObjectAtIndex:i withObject:text];
    }
    
    for (NSInteger i = 0; i < sizeof(engineIdentifiers) / sizeof(engineIdentifiers[0]); ++i)
    {
        error = [self.businessLayer readData:&data byIdentifier:engineIdentifiers[i]];
        
        if (error != Success)
        {
            goto theEnd;
        }
        
        bytes = (Byte *)[data bytes];
        
        switch (i)
        {
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
            case 6:
            case 7:
            case 8:
            case 9:
            case 10:
            case 11:
            {
                text = [NSString stringWithCString:(char *)bytes encoding:NSUTF8StringEncoding];
                
                if (!text || [text compare:@""] == NSOrderedSame)
                {
                    text = @"不可见";
                }
                
                break;
            }
            case 12:
            {
                text = @"暂不支持";
                break;
            }
        }
        
        [self.engineValuesArray replaceObjectAtIndex:i withObject:text];
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
                          [SVProgressHUD showSuccessWithStatus:@"数据获取成功."];
                      }
                      
                      [self.contentTableView reloadData];
                      
                      self.navigationItem.leftBarButtonItem.enabled = YES;
                      self.navigationItem.rightBarButtonItem.enabled = YES;
                  });
}

@end
