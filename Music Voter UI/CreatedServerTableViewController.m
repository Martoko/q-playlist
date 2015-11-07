//
//  CreatedServerTableViewController.m
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "CreatedServerTableViewController.h"

@interface CreatedServerTableViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UILabel *trackLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UIImageView *nowPlayingImage;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addItemButton;

-(void) setNowPlayingImageFromTrack: (SPTTrack*) track;

@end

@implementation CreatedServerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.title = [self.musicVoterServer getName];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.title = @"Creating...";
    self.musicVoterServer.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.musicVoterServer.published == NO) {
        [self.musicVoterServer publish];
        self.addItemButton.enabled = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    self.musicVoterServer.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}
- (IBAction)playPauseButtonPressed:(id)sender {
    if ([self.musicVoterServer getIsPlaying]) {
        [self.musicVoterServer pausePlaying];
        
        [sender setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
    } else {
        [self.musicVoterServer continueOrStartPlaying];
        
        [sender setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
    }
}

- (IBAction)skipButtonPressed:(id)sender {
    [self.musicVoterServer playNextTrack];
}

- (IBAction)voteButtonPressed:(id)sender {
    UIButton* button = sender;
    VoteTrackTableViewCell* cell = (VoteTrackTableViewCell*) button.superview.superview;
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    VoteTrack* selectedVoteTrack = [self.musicVoterServer.voteTracks objectAtIndex:indexPath.row];
    
    NSString* userID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    
    if ([selectedVoteTrack userHasVoted:[[UIDevice currentDevice].identifierForVendor UUIDString]] == YES) {
        [button setImage:[UIImage imageNamed:@"Star Blank"] forState:UIControlStateNormal];
        
        // Bad practice
        [self.musicVoterServer connection:nil user:userID removedVoteForTrack:selectedVoteTrack.track.uri.absoluteString];
    } else {
        [button setImage:[UIImage imageNamed:@"Star Filled"] forState:UIControlStateNormal];
        
        // Bad practice
        [self.musicVoterServer connection:nil user:userID addedVoteForTrack:selectedVoteTrack.track.uri.absoluteString];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.musicVoterServer.published) {
        return self.musicVoterServer.voteTracks.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VoteTrackTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VoteTrackCell" forIndexPath:indexPath];
    
    VoteTrack* voteTrack = [self.musicVoterServer.voteTracks objectAtIndex:indexPath.row];
    
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
    
    if ([voteTrack userHasVoted:[[UIDevice currentDevice].identifierForVendor UUIDString]] == YES) {
        [cell.voteButton setImage:[UIImage imageNamed:@"Star Filled"] forState:UIControlStateNormal];
    } else {
        [cell.voteButton setImage:[UIImage imageNamed:@"Star Blank"] forState:UIControlStateNormal];
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - MusicVoterServerDelegate

-(void)nowPlayingChanged:(SPTTrack*) newTrack {
    if (newTrack.identifier != NULL) {
        self.trackLabel.text = newTrack.name;
        self.albumLabel.text = newTrack.album.name;
        
        NSMutableString* artistsString = [[NSMutableString alloc] init];
        NSArray* artists = newTrack.artists;
        for (NSUInteger i = 0; i < artists.count; i++) {
            SPTPartialArtist* artist = [artists objectAtIndex:i];
            [artistsString appendString: artist.name];
            
            //if i != lastItem
            if (i != artists.count-1) {
                [artistsString appendString: @" & "];
            }
        }
        
        self.artistLabel.text = artistsString;
        
        [self setNowPlayingImageFromTrack: newTrack];
    } else {
        NSLog(@"Track changed to null");
#warning Track changed to null not implemented
    }
    
    [self.playPauseButton setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
}

-(void) setNowPlayingImageFromTrack: (SPTTrack*) track {
    if (track.identifier == NULL) {
        NSLog(@"Error track is empty");
        return;
    }
    
    NSURL *imageURL = track.album.largestCover.imageURL;
    if (imageURL == nil) {
        NSLog(@"Error imageURL is nil");
        return;
    }
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
            self.nowPlayingImage.image = image;
        });
    });
}

-(void)trackListChanged {
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)didPublish {
    self.title = [self.musicVoterServer getName];
    self.playPauseButton.enabled = YES;
    self.skipButton.enabled = YES;
    self.addItemButton.enabled = YES;
    
    for (UIView* subView in self.view.subviews) {
        [UIView transitionWithView:subView
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:NULL
                        completion:NULL];
        
        subView.hidden = NO;
    }
    
    [self.tableView reloadData];
}

#pragma mark - AddItemToCreatedServerTableViewControllerDelegate

- (void)didSelectTrack:(SPTPartialTrack*)track {
    // Bad practice
    [self.musicVoterServer connection:nil receivedAddTrack:track.uri.absoluteString];
}
- (void)didSelectPlaylist:(SPTPartialPlaylist*)playlist {
    [self.musicVoterServer addItemsFromPlaylist:playlist];
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
