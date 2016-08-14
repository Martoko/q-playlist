//
//  MusicVoterConnectionViewController.m
//  Music Voter UI
//
//  Created by Martoko on 08/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "MusicVoterConnectionViewController.h"

@interface MusicVoterConnectionViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *trackLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addItemButton;
@property (weak, nonatomic) IBOutlet UIView *nowPlayingView;
@property (weak, nonatomic) IBOutlet UIView *noSongPlayingView;
@property NSArray<VoteTrack*>* voteTracks;

- (IBAction)voteButtonPressed:(id)sender;
- (void)switchToNoSongPlayingUI;
- (void)switchToNowPlayingUI;

@end

@implementation MusicVoterConnectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.musicVoterConnection.delegate = self;
    //self.title = @"Loading...";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.musicVoterConnection.delegate = nil;
}

- (void) switchToNoSongPlayingUI {
    if (self.nowPlayingView.hidden == NO) {
        [UIView transitionWithView:self.nowPlayingView
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:NULL
                        completion:NULL];
        self.nowPlayingView.hidden = YES;
    }
    
    if (self.noSongPlayingView.hidden == YES) {
        [UIView transitionWithView:self.noSongPlayingView
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:NULL
                        completion:NULL];
        self.noSongPlayingView.hidden = NO;
    }
}

- (void) switchToNowPlayingUI {
    if (self.nowPlayingView.hidden == YES) {
        [UIView transitionWithView:self.nowPlayingView
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:NULL
                        completion:NULL];
        self.nowPlayingView.hidden = NO;
    }
    
    if (self.noSongPlayingView.hidden == NO) {
        [UIView transitionWithView:self.noSongPlayingView
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:NULL
                        completion:NULL];
        self.noSongPlayingView.hidden = YES;
    }
}

- (void) alert:(NSString*) message withTitle:(NSString*) title {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:true completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.voteTracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VoteTrackTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VoteTrackCell" forIndexPath:indexPath];
    VoteTrack* voteTrack;
    
    voteTrack = [self.voteTracks objectAtIndex:indexPath.row];
    
    cell.titleLabel.text = voteTrack.track.name;
    
    NSMutableString* subtitleString = [[NSMutableString alloc] init];
    
    NSArray* artists = voteTrack.track.artists;
    for (NSUInteger i = 0; i < artists.count; i++) {
        SPTPartialArtist* artist = [artists objectAtIndex:i];
        [subtitleString appendString: artist.name];
        
        //if i != lastItem
        if (i < artists.count-1) {
            [subtitleString appendString: @" & "];
        }
    }
    
    [subtitleString appendString:@" - "];
    [subtitleString appendString:voteTrack.track.album.name];
    
    cell.subtitleLabel.text = subtitleString;
    
    //cell.subtitleLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)voteTrack.remoteVotes.count];
    
    if ([voteTrack userHasVoted:[[UIDevice currentDevice].identifierForVendor UUIDString]] == YES) {
        [cell.voteButton setImage:[UIImage imageNamed:@"Star Filled"] forState:UIControlStateNormal];
    } else {
        [cell.voteButton setImage:[UIImage imageNamed:@"Star Blank"] forState:UIControlStateNormal];
    }
    
    return cell;
}

- (IBAction)voteButtonPressed:(id)sender {
    UIButton* button = sender;
    VoteTrackTableViewCell* cell = (VoteTrackTableViewCell*) button.superview.superview;
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    VoteTrack* selectedVoteTrack = [self.voteTracks objectAtIndex:indexPath.row];
    NSString* ourUserID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    
    if ([selectedVoteTrack userHasVoted:ourUserID] == YES) {
        [button setImage:[UIImage imageNamed:@"Star Blank"] forState:UIControlStateNormal];
        
        [selectedVoteTrack.remoteVotes removeObject:ourUserID];
        [self.musicVoterConnection sendRemovedVoteForTrack:selectedVoteTrack.track.uri.absoluteString];
        
    } else {
        [button setImage:[UIImage imageNamed:@"Star Filled"] forState:UIControlStateNormal];
        
        [selectedVoteTrack.remoteVotes addObject:ourUserID];
        [self.musicVoterConnection sendAddedVoteForTrack:selectedVoteTrack.track.uri.absoluteString];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.musicVoterConnection connectIfNot];
}

#pragma mark - MusicVoterConnectionDelegate

- (void)connectionReady {
    self.title = self.musicVoterConnection.getName;
    
    //Fade UI in, once we're ready
    self.addItemButton.enabled = YES;
    [self switchToNoSongPlayingUI];
    [UIView transitionWithView:self.tableView
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    self.tableView.hidden = NO;
}
- (void)trackListChanged: (NSArray<VoteTrack*>*)voteTracks {
    self.voteTracks = voteTracks;
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void) nowPlayingChangedTo:(SPTPartialTrack *)track {
    if (track.identifier != NULL) {
        self.trackLabel.text = track.name;
        self.albumLabel.text = track.album.name;
        
        NSMutableString* artistsString = [[NSMutableString alloc] init];
        NSArray* artists = track.artists;
        for (NSUInteger i = 0; i < artists.count; i++) {
            SPTPartialArtist* artist = [artists objectAtIndex:i];
            [artistsString appendString: artist.name];
            
            //if i != lastItem
            if (i != artists.count-1) {
                [artistsString appendString: @" & "];
            }
        }
        
        self.artistLabel.text = artistsString;
        
        [self setNowPlayingImageFromTrack: track];
    } else {
        [self switchToNoSongPlayingUI];
    }
}

-(void) setNowPlayingImageFromTrack: (SPTPartialTrack*) track {
    if (track.identifier == NULL) {
        NSLog(@"Error track is empty");
        return;
    }
    
    NSURL *imageURL = track.album.largestCover.imageURL;
    if (imageURL == nil) {
        NSLog(@"Error imageURL is nil");
        return;
    }
    __weak MusicVoterConnectionViewController * weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        UIImage *image = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL options: 0 error:&error];
        
        if (error) {
            NSLog(@"Error getting album image %@", error.localizedDescription);
        }
        
        if (imageData !=nil) {
            image = [UIImage imageWithData:imageData];
        } else {
            NSLog(@"Error, imagedata from request is nil");
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.imageView.image = image;
            [weakSelf switchToNowPlayingUI];
        });
        
    });
}

- (void)connectionTerminated {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
