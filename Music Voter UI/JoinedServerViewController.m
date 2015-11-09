//
//  JoinedServerViewController2.m
//  Music Voter UI
//
//  Created by Martoko on 08/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "JoinedServerViewController.h"

@interface JoinedServerViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *trackLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addItemButton;
@property (weak, nonatomic) IBOutlet UIView *nowPlayingView;
@property (weak, nonatomic) IBOutlet UIView *noSongPlayingView;

@end

@implementation JoinedServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Joining...";
}


#pragma mark - AddItemToJoinedServerTableViewController Delegate

- (void)didSelectTrack:(SPTPartialTrack *)track {
    [self.musicVoterConnection sendAddTrack:track.uri.absoluteString];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier  isEqualToString: @"JoinedServerToAddItem"]) {
        AddItemToJoinedServerTableViewController* newViewController = [segue destinationViewController];
        newViewController.delegate = self;
        
    }
}

@end
