//
//  ViewController.m
//  DMRefreshControlExample
//
//  Created by Daniel McCarthy on 1/1/15.
//  Copyright (c) 2015 Daniel McCarthy. All rights reserved.
//

#import "ViewController.h"
#import "DMRefreshControl.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) DMRefreshControl *refreshControl;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTheStuff];
}

- (void)setupTheStuff {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    
    /*-----------------------------------------------------------------*/
    //This is the important stuff to setup the refresh control and connect it to a scrollview
    
    __weak id weakSelf = self;
    self.refreshControl = [[DMRefreshControl alloc] initWithColor:[UIColor whiteColor] inScrollView:self.tableView];
    [self.refreshControl addRefreshControlToViewController:self forScrollViews:@[self.tableView]];
    [self.refreshControl addCalledForRefreshHandler:^{
        [weakSelf calledForRefresh];
    }];
    
    //Dont forget to stop the refresh control when your refresh call to the server is complete
    /*-----------------------------------------------------------------*/
}

- (void)calledForRefresh {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Boom" message:@"Called for refresh... now you can call your server" delegate:self cancelButtonTitle:@"Radical" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)stopTheRefreshControl {
    [self.refreshControl stopRefreshing];
}

#pragma mark - alertview delegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self performSelector:@selector(stopTheRefreshControl) withObject:nil afterDelay:1.0];
}

#pragma mark - tableview delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellIdentifier"];
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %li",indexPath.row];
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
