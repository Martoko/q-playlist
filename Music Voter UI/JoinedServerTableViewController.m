//
//  JoinedServerTableViewController.m
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "JoinedServerTableViewController.h"

@interface JoinedServerTableViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *songLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addItemButton;


-(void) setNowPlayingImageFromTrack: (SPTPartialTrack*) track;

@end

@implementation JoinedServerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.serverConnection.delegate = self;
    self.title = @"Joining...";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.serverConnection.delegate = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.serverConnection.voteTracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SingleVoteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JoinedServerCell" forIndexPath:indexPath];
    
    VoteTrack* voteTrack = [self.serverConnection.voteTracks objectAtIndex:indexPath.row];
    
    cell.titleLabel.text = voteTrack.track.name;
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)voteTrack.remoteVotes.count];
    
    if ([voteTrack userHasVoted:[[UIDevice currentDevice].identifierForVendor UUIDString]] == YES) {
        [cell.voteButton setTitle:@"[X]" forState:UIControlStateNormal];
    } else {
        [cell.voteButton setTitle:@"[  ]" forState:UIControlStateNormal];
    }
    
    return cell;
}

- (IBAction)voteButtonPressed:(id)sender {
    UIButton* button = sender;
    SingleVoteTableViewCell* cell = (SingleVoteTableViewCell*) button.superview.superview;
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    VoteTrack* selectedVoteTrack = [self.serverConnection.voteTracks objectAtIndex:indexPath.row];
    
    if ([selectedVoteTrack userHasVoted:[[UIDevice currentDevice].identifierForVendor UUIDString]] == YES) {
        [button setTitle:@"[  ]" forState:UIControlStateNormal];
        [self.serverConnection removeVoteForTrack:selectedVoteTrack];
        [selectedVoteTrack.remoteVotes removeObject:[[UIDevice currentDevice].identifierForVendor UUIDString]];
    } else {
        [button setTitle:@"[X]" forState:UIControlStateNormal];
        [self.serverConnection addVoteForTrack:selectedVoteTrack];
        [selectedVoteTrack.remoteVotes addObject:[[UIDevice currentDevice].identifierForVendor UUIDString]];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.serverConnection connectIfNotConnected];
}

#pragma mark - ServerConnectionDelegate

- (void)connectionEstablished {
    self.title = [self.serverConnection getName];
    self.addItemButton.enabled = YES;
}

- (void)connectionTerminated {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)trackListChanged {
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void) nowPlayingChangedTo:(SPTPartialTrack *)track {
    if (track.identifier != NULL) {
        self.songLabel.text = track.name;
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
        NSLog(@"Track changed to null");
#warning Track changed to null not implemented
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
            self.imageView.image = image;
        });
        
    });
}


#pragma mark - AddItemToJoinedServerTableViewController Delegate

- (void)didSelectTrack:(SPTPartialTrack *)track {
    [self.serverConnection addTrack:[track.uri absoluteString]];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier  isEqualToString: @"JoinedServerToAddItemSegue"]) {
        AddItemToJoinedServerTableViewController* newViewController = [segue destinationViewController];
        newViewController.delegate = self;
        
    }
}


@end
