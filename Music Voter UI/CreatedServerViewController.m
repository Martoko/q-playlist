//
//  CreatedServerViewController.m
//  Music Voter UI
//
//  Created by Martoko on 08/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "CreatedServerViewController.h"

@interface CreatedServerViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *trackLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addItemButton;
@property (weak, nonatomic) IBOutlet UIView *nowPlayingView;
@property (weak, nonatomic) IBOutlet UIView *noSongPlayingView;
@property (weak, nonatomic) IBOutlet UIView *playerControlsView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation CreatedServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Creating...";
}

- (IBAction)playPauseButtonPressed:(id)sender {
    if([self.musicVoterConnection playOrPauseReturnPlaying]) {
        [sender setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
    } else {
        [sender setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
    }
}

- (IBAction)skipButtonPressed:(id)sender {
    [self.musicVoterConnection playNextTrack];
}

#pragma mark - MusicVoterConnectionDelegate

- (void)nowPlayingChangedTo:(SPTTrack *)track {
    [super nowPlayingChangedTo:track];
    
    if (track.identifier != NULL) {
        [self.playButton setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
    } else {
        [self.playButton setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
    }
}

- (void)connectionReady {
    [super connectionReady];
    [UIView transitionWithView:self.playerControlsView
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    self.playerControlsView.hidden = NO;
}

#pragma mark - AddItemToCreatedServerTableViewControllerDelegate

- (void)didSelectTrack:(SPTPartialTrack*)track {
    [self.musicVoterConnection sendAddedVoteForTrack:track.uri.absoluteString];
}
- (void)didSelectPlaylist:(SPTPartialPlaylist*)playlist {
    [self.musicVoterConnection addItemsFromPlaylist:playlist];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier  isEqualToString: @"CreatedServerToAddItemSegue"]) {
        AddItemToCreatedServerTableViewController* newViewController = [segue destinationViewController];
        newViewController.delegate = self;
    }
}

@end