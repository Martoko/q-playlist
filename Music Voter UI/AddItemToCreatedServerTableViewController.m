//
//  AddItemToCreatedServerTableViewController.m
//  Music Voter UI
//
//  Created by Martoko on 03/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "AddItemToCreatedServerTableViewController.h"

@interface AddItemToCreatedServerTableViewController () <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating>

@property (nonatomic) UISearchController *searchController;
@property SPTListPage* searchResultsPage;
@property SPTPlaylistList* userPlaylistList;
@property NSArray* filteredUserPlaylists;
@property BOOL perfomingSearch;

@end

@implementation AddItemToCreatedServerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _perfomingSearch = NO;
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchResultsPage = [[SPTListPage alloc] init];
    _userPlaylistList = [[SPTPlaylistList alloc] init];
    self.searchController.searchBar.scopeButtonTitles = @[@"Song", @"Playlist"];
    self.searchController.searchResultsUpdater = self;
    [self.searchController.searchBar sizeToFit];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //update user playlists
    SPTSession* spotifySession = [SPTAuth defaultInstance].session;
    [SPTPlaylistList playlistsForUserWithSession:spotifySession callback:^(NSError *error, id playlistList) {
        if(error == nil) {
            self.userPlaylistList = playlistList;
            [self.tableView reloadData];
        }
    }];
    [self.searchController setActive:YES];
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
    NSString* scope = [self.searchController.searchBar.scopeButtonTitles objectAtIndex:self.searchController.searchBar.selectedScopeButtonIndex];
    
    if ([scope isEqualToString:@"Song"]) {
        return self.searchResultsPage.items.count;
    } else {
        return self.filteredUserPlaylists.count;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddItemToCreatedServerCell" forIndexPath:indexPath];
    
    NSString* scope = [self.searchController.searchBar.scopeButtonTitles objectAtIndex:self.searchController.searchBar.selectedScopeButtonIndex];
    
    if ([scope isEqualToString:@"Song"]) {
        SPTPartialTrack* selectedTrack = [self.searchResultsPage.items objectAtIndex:indexPath.row];
        cell.textLabel.text = selectedTrack.name;
    } else {
        SPTPartialPlaylist* selectedPlaylist = [self.filteredUserPlaylists objectAtIndex:indexPath.row];
        cell.textLabel.text = selectedPlaylist.name;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* scope = [self.searchController.searchBar.scopeButtonTitles objectAtIndex:self.searchController.searchBar.selectedScopeButtonIndex];
    
    if ([scope isEqualToString:@"Song"]) {
        SPTPartialTrack* selectedTrack = [self.searchResultsPage.items objectAtIndex:indexPath.row];
        [self.delegate didSelectTrack:selectedTrack];
    
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        SPTPartialPlaylist* selectedPlaylist = [self.filteredUserPlaylists objectAtIndex:indexPath.row];
        [self.delegate didSelectPlaylist:selectedPlaylist];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UISearchBarDelegate

// add two extra search update hooks

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [self updateSearchResultsForSearchController:self.searchController];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self updateSearchResultsForSearchController:self.searchController];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // update the filtered array based on the search text
    NSString *searchText = searchController.searchBar.text;
    
    // strip out all the leading and trailing spaces
    NSString *strippedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString* scope = [self.searchController.searchBar.scopeButtonTitles objectAtIndex:self.searchController.searchBar.selectedScopeButtonIndex];
    
    if ([scope isEqualToString:@"Song"]) {
        if (self.perfomingSearch == NO && strippedString.length >= 3) {
            [self performTrackSearchAndUpdate:strippedString];
        } else {
            [self.tableView reloadData];
        }
            
    } else {
        [self performPlaylistSearchAndUpdate:strippedString];
    }
}

- (void)performTrackSearchAndUpdate: (NSString*) searchQuery {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.perfomingSearch = YES;
    [SPTSearch performSearchWithQuery:searchQuery queryType:SPTQueryTypeTrack accessToken:nil callback:^(NSError *error, id resultsPage) {
        if (error == nil) {
            self.searchResultsPage = resultsPage;
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
        [self.tableView reloadData];
    }];
}

- (void)performPlaylistSearchAndUpdate: (NSString*) searchQuery {
    if ([searchQuery isEqualToString:@""]) {
        self.filteredUserPlaylists = self.userPlaylistList.items;
    } else {
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", searchQuery];
        self.filteredUserPlaylists = [self.userPlaylistList.items filteredArrayUsingPredicate:resultPredicate];
    }
    
    
    [self.tableView reloadData];
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
