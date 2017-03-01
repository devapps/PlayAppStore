//
//  PASSettingController.m
//  PlayAppStore
//
//  Created by Winn on 2017/2/18.
//  Copyright © 2017年 Winn. All rights reserved.
//

#import "PASSettingController.h"
#import "PASSettingActionCell.h"
#import "PASServerAddressController.h"
#import "PASLoacalDataManager.h"
#import "MBProgressHUD.h"
#import "PASChangeLanguageController.h"
#import "PASPushNotificationController.h"




@interface PASSettingController () <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

@property (nonatomic, copy) NSArray *settingArray;
@property (nonatomic, copy) NSArray *manualArray;
@property (nonatomic, copy) NSArray *otherArray;
@property (nonatomic, copy) NSArray *aboutArray;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGFloat cacheSize;

@end

@implementation PASSettingController

#pragma mark - LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadNav];
    [self configData];
    [self addSubviews];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    self.navLine.hidden = YES;
}




- (void)didSelectRowWithActionTag:(NSInteger)tag
{
    switch (tag) {
        case 100:
        {
            //server address
            PASServerAddressController *listViewC = [[PASServerAddressController alloc] init];
            [self.navigationController pushViewController:listViewC animated:YES];

        }
            break;
            
        case 101:
        {
            //language
            PASChangeLanguageController *listViewC = [[PASChangeLanguageController alloc] init];
            [self.navigationController pushViewController:listViewC animated:YES];
        }
            break;
        case 102:
        {
            //notifications
            PASPushNotificationController *listViewC = [[PASPushNotificationController alloc] init];
            [self.navigationController pushViewController:listViewC animated:YES];

        }
            break;
        case 103:
        {
            //shortcut
        }
            break;
        case 104:
        {
            //display settings
        }
            break;

        case 105:
        {
            //manual
        }
            break;

        case 106:
        {
            //faq
        }
            break;

        case 107:
        {
           //clear cache
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"确认清除缓存" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
            [alert show];
        }
            break;

        case 108:
        {
           //share app to your frieds
            [self shareAppToFriends];
        }
            break;

        case 109:
        {
            //designer
            [self openScheme:@"https://github.com/playappstore/PlayAppStore"];
        }
            break;
        case 110:
        {
            //follow us
        }
            break;

        default:
            break;
    }
}

#pragma mark - Share
- (void)shareAppToFriends {
    NSString *text = @"分享内容";
    
    UIImage *image = [UIImage imageNamed:@"pas_QRCode"];
    
    NSURL *url = [NSURL URLWithString:@"https://github.com/playappstore/PlayAppStore"];
    
    //数组中放入分享的内容
    
    NSArray *activityItems = @[text, image, url];
    
    //自定义 customActivity继承于UIActivity,创建自定义的Activity加在数组Activities中。
//    PASShareActivity * custom = [[PASShareActivity alloc] initWithTitie:@"二维码" withActivityImage:[UIImage imageNamed:@"pas_QRCode"] withUrl:url withType:@"customActivity" withShareContext:activityItems];
//    custom.delegate = self;
//    NSArray *activities = @[custom];
    
    // 实现服务类型控制器
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
//    activityViewController.excludedActivityTypes = @[UIActivityTypePostToVimeo, UIActivityTypePrint, UIActivityTypeAddToReadingList, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypePostToTencentWeibo, UIActivityTypeCopyToPasteboard];
    // 分享类型
    [activityViewController setCompletionWithItemsHandler:^(NSString * __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError){
        
        // 显示选中的分享类型
        NSLog(@"当前选择分享平台 %@",activityType);
        
        if (completed) {
            
            NSLog(@"分享成功");
            
        }else {
            
            NSLog(@"分享失败");
            
        }
    }];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark -AboutUS
- (void)openScheme:(NSString *)scheme {
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *URL = [NSURL URLWithString:scheme];
    
    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [application openURL:URL options:@{}
           completionHandler:^(BOOL success) {
               NSLog(@"Open %@: %d",scheme,success);
           }];
    } else {
        BOOL success = [application openURL:URL];
        NSLog(@"Open %@: %d",scheme,success);
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self clearCacheButtonClicked];
    }
}

- (void)clearCacheButtonClicked
{
    
    MBProgressHUD *hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    if (_cacheSize > 0) {
        
        [PASLoacalDataManager clearDiskCache];
        hub.mode = MBProgressHUDModeText;
        
        hub.label.text = NSLocalizedString(@"清除成功", nil);
        hub.completionBlock = ^ {
            [self.tableView reloadData];
        };
        [hub hideAnimated:YES afterDelay:2];
    } else {
        
        hub.mode = MBProgressHUDModeText;
        
        hub.label.text = NSLocalizedString(@"还没有缓存", nil);
        hub.completionBlock = ^ {
        };
        [hub hideAnimated:YES afterDelay:2];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return _settingArray.count;
    } else if (section == 1) {
        return _otherArray.count;
    } else {
        return _aboutArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PASSettingActionCell * cell = [PASSettingActionCell cellCreatedWithTableView:tableView];
    NSArray *targetArray = [NSArray array];
    if (indexPath.section == 0) {
        targetArray = self.settingArray;
    } else if (indexPath.section == 1) {
        targetArray = self.otherArray;
    } else {
        targetArray = self.aboutArray;
    }

    cell.titleLabel.text = [targetArray[indexPath.row] objectForKey:@"title"];
    if (indexPath.section == 1 && indexPath.row == 0) {
        // 清除缓存
        cell.isFirstCell = YES;
        _cacheSize = [PASLoacalDataManager diskCacheSize];
        cell.detailLabel.text = [NSString stringWithFormat:@"%.2fMB", _cacheSize];
    }
    
    if (indexPath.row == targetArray.count-1) {
        cell.isLastCell = YES;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *targetArray = [NSArray array];
    if (indexPath.section == 0) {
        targetArray = self.settingArray;
    } else if (indexPath.section == 1) {
        targetArray = self.otherArray;
    } else {
        targetArray = self.aboutArray;
    }

    NSInteger tag = [[targetArray[indexPath.row] objectForKey:@"action"] integerValue];
    [self didSelectRowWithActionTag:tag];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView * view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 30)];
    view.backgroundColor = RGBColor(247, 249, 250);
    UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 29.5, SCREEN_WIDTH, 0.5)];
    lineView.backgroundColor = RGBColor(229, 229, 229);
    [view addSubview:lineView];
    NSString *sectionTitle = nil;
    if (section == 0) {
        sectionTitle = @"Setting";
    } else if (section == 1) {
        sectionTitle = @"Other";
    } else {
        sectionTitle = @"About";
    }

    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, SCREEN_WIDTH, 30)];
    label.text = NSLocalizedString(sectionTitle, nil);
    label.textColor = RGBColor(153, 153, 153);
    label.font = [UIFont systemFontOfSize:14];
    [view addSubview:label];
    
    return view;
}


#pragma mark - Setter && Getter
- (void)loadNav {
    self.view.backgroundColor = RGBCodeColor(0xf2f2f2);
}

- (void)addSubviews {

    [self.view addSubview:self.tableView];
    [self layoutSubviews];
}

- (void)layoutSubviews
{

}


- (void)configData {
    self.settingArray = @[
                    @{@"title":NSLocalizedString(@"Server address", nil), @"action":@(100)},
                    @{@"title":NSLocalizedString(@"Language", nil), @"action":@(101)},
                    @{@"title":NSLocalizedString(@"Notifications", nil), @"action":@(102)},
                    @{@"title":NSLocalizedString(@"Shortcut", nil), @"action":@(103)},
                    @{@"title":NSLocalizedString(@"Display setting", nil), @"action":@(104)}
                    ];
    self.manualArray = @[
                         @{@"title":NSLocalizedString(@"Manual", nil), @"action":@(105)},
                         @{@"title":NSLocalizedString(@"Faq", nil), @"action":@(106)}
                         ];
    self.otherArray = @[
                         @{@"title":NSLocalizedString(@"Clear cache", nil), @"action":@(107)},
                         @{@"title":NSLocalizedString(@"Share app to your friends", nil), @"action":@(108)}
                         ];
    self.aboutArray = @[
                        @{@"title":NSLocalizedString(@"Designer PlayAppStore", nil), @"action":@(109)},
                        @{@"title":NSLocalizedString(@"Follow us on twitter", nil), @"action":@(110)}
                        ];
}

- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end