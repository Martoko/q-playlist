//
//  JoinServerTableViewController.m
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "JoinServerTableViewController.h"

@interface JoinServerTableViewController ()

@property BonjourBrowser* bonjourBrowser;

@end

@implementation JoinServerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void) viewDidAppear:(BOOL)animated {
    self.bonjourBrowser = [[BonjourBrowser alloc] init];
    self.bonjourBrowser.delegate = self;
}


- (void)viewDidDisappear:(BOOL)animated {
    self.bonjourBrowser.delegate = nil;
    self.bonjourBrowser = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.bonjourBrowser.foundServers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JoinServerCell" forIndexPath:indexPath];
    
    NSNetService* server = [self.bonjourBrowser.foundServers objectAtIndex:indexPath.row];
    
    cell.textLabel.text = server.name;
    
    return cell;
}

#pragma mark - BonjourBrowser delegate

-(void) serverlistChanged {
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier  isEqual: @"JoinServerToJoinedServer"]) {
        JoinedServerTableViewController* newViewController = [segue destinationViewController];
        NSIndexPath *selectedPath = [self.tableView indexPathForSelectedRow];
        NSNetService* selectedNetService = [self.bonjourBrowser.foundServers objectAtIndex:selectedPath.row];
        
        
        newViewController.serverConnection = [[ServerConnection alloc] initWithNetService:selectedNetService];
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
