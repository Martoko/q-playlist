//
//  AddItemToJoinedServerTableViewController.m
//  Music Voter UI
//
//  Created by Martoko on 03/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "AddItemToJoinedServerTableViewController.h"

@interface AddItemToJoinedServerTableViewController () <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic) UISearchController *searchController;
@property SPTListPage* searchResultsPage;
@property BOOL perfomingSearch;

@end

@implementation AddItemToJoinedServerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _perfomingSearch = NO;
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchResultsPage = [[SPTListPage alloc] init];
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.placeholder = @"Search for song";
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO; // default is YES
    self.searchController.searchBar.delegate = self; // so we can monitor text changes + others
    
    //style the search bar
    self.searchController.searchBar.barTintColor = [UIColor colorWithRed:(63/255.0) green:(63/255.0) blue:(63/255.0) alpha:1.0];
    self.searchController.searchBar.tintColor = [UIColor colorWithRed:(50/255.0) green:(241/255.0) blue:(71/255.0) alpha:1.0];
    UITextField* searchBarTextField = [self.searchController.searchBar valueForKey:@"searchField"];
    searchBarTextField.backgroundColor =[UIColor colorWithRed:(163/255.0) green:(165/255.0) blue:(170/255.0) alpha:1.0];
    
    // Search is now just presenting a view controller. As such, normal view controller
    // presentation semantics apply. Namely that presentation will walk up the view controller
    // hierarchy until it finds the root view controller or one that defines a presentation context.
    //
    self.definesPresentationContext = YES;  // know where you want UISearchController to be displayed
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // bugfix
    // see http://www.openradar.me/22250107
    // and http://stackoverflow.com/questions/32282401
    [self.searchController loadViewIfNeeded];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResultsPage.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JoinedServerAddTrackCell" forIndexPath:indexPath];
    
    SPTTrack* track = [self.searchResultsPage.items objectAtIndex:indexPath.row];
    cell.textLabel.text = track.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SPTPartialTrack* selectedTrack = [self.searchResultsPage.items objectAtIndex:indexPath.row];
    [self.delegate didSelectTrack:selectedTrack];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self updateSearchResultsForSearchController:self.searchController];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // update the filtered array based on the search text
    NSString *searchText = searchController.searchBar.text;
    
    // strip out all the leading and trailing spaces
    NSString *strippedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (self.perfomingSearch == NO && strippedString.length >= 3) {
        [self performSearchAndUpdate:strippedString];
    }
    
}

-(void) performSearchAndUpdate: (NSString*)searchQuery {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.perfomingSearch = YES;
    [SPTSearch performSearchWithQuery:searchQuery queryType:SPTQueryTypeTrack accessToken:nil callback:^(NSError *error, id resultsPage) {
        if (error == nil) {
            self.searchResultsPage = resultsPage;
            [self.tableView reloadData];
        } else {
            NSString* message = [NSString stringWithFormat:@"The following error occured while searching in: %@", error.localizedDescription];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message: message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        self.perfomingSearch = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
