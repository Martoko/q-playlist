//
//  MusicVoterServer.m
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "MusicVoterServer.h"

@interface MusicVoterServer ()

@property NSMutableArray<Connection*>* connections;
@property (nonatomic) SPTAudioStreamingController *player;
@property BonjourServer* bonjourServer;
@property SPTSession* session;
@property NSArray* nowPlayingURIs;

@end

@implementation MusicVoterServer

- (id)init
{
    return [self initWithName:nil];
}

- (id)initWithName: (NSString*) name;
{
    self = [super init];
    
    if (self) {
        if (name) {
            _bonjourServer = [[BonjourServer alloc] initWithName: name];
        } else {
            _bonjourServer = [[BonjourServer alloc] init];
        }
        
        SPTAuth *auth = [SPTAuth defaultInstance];
        
        _session = auth.session;
        _isPaused = NO;
        _bonjourServer.delegate = self;
        _voteTracks = [[NSMutableArray alloc] init];
        _nowPlayingURIs = [[NSArray alloc] init];
        _published = NO;
        _connections = [[NSMutableArray alloc] init];
        _allowSameSongName = NO;
    }
    
    return self;
}

- (void)dealloc
{
    self.bonjourServer.delegate = nil;
    self.player.playbackDelegate = nil;
    self.player.delegate = nil;
    [self.player logout:nil];
}

-(NSString*) getName {
    return [self.bonjourServer getName];
}

-(BOOL) getIsPlaying {
    return self.player.isPlaying;
}

- (void)connect {
    [self publish];
}

-(void) publish {
    [self.bonjourServer publish];
    
    SPTAuth* auth = [SPTAuth defaultInstance];
    
    self.player = [[SPTAudioStreamingController alloc]initWithClientId: auth.clientID];
    self.player.playbackDelegate = self;
    self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity: 1024 * 1024 * 64 /*mb*/];
    __unsafe_unretained MusicVoterServer* weakSelf = self;
    [self.player loginWithSession:self.session callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Error logging in to player %@ ", error.localizedDescription);
            weakSelf.bonjourServer.delegate = nil;
            weakSelf.bonjourServer = nil;
            weakSelf.player = nil;
        }
        [weakSelf updatePublishedStatus];
        //DEBUG
        NSURL* url = [NSURL URLWithString:@"spotify:track:478d70Vg2ljAG28eeDp2w5"];
        [weakSelf receivedAddTrack:[url absoluteString]];
        url = [NSURL URLWithString:@"spotify:track:38kZrYqFXrF96N3eLqKqqu"];
        [weakSelf receivedAddTrack:[url absoluteString]];
        url = [NSURL URLWithString:@"spotify:track:19UMWSbRxT22OUT961Gkwc"];
        [weakSelf receivedAddTrack:[url absoluteString]];
        //DEBUG END
    }];
}

-(void) playNextTrack {
    _isPaused = NO;
    if (self.voteTracks.count > 0) {
        VoteTrack* currentVoteTrack = self.voteTracks.firstObject;
        self.nowPlayingURIs = [[NSArray alloc] initWithObjects:currentVoteTrack.track.uri, nil];
        [self sendNowPlayingToAllClients:currentVoteTrack.track.uri.absoluteString];
        [self removeTrack:currentVoteTrack];
        
        [self.player playURIs:self.nowPlayingURIs fromIndex:0 callback:^(NSError *error) {
            if (error != nil) {
                NSLog(@"Error playing song: %@", error.localizedDescription);
            }
        }];
        [self sortArrayAndSendTrackListChanged];
    }
}

-(void)sendNowPlayingToAllClients: (NSString*)trackURI {
    for (Connection* connection in self.connections) {
        [connection sendNowPlayingChangedTo:trackURI];
    }
}

-(void) stopPlaying {
    [self.player stop:^(NSError *error) {
        if(error != nil) {
            NSLog(@"Error stopping player %@ ", error.localizedDescription);
        }
    }];
}

-(void) pausePlaying {
    _isPaused = YES;
    [self.player setIsPlaying:NO callback:nil];
}

-(void) continueOrStartPlaying {
    if (self.isPaused) {
        [self.player setIsPlaying:YES callback:nil];
    } else {
        [self playNextTrack];
    }
    _isPaused = NO;
}

-(void) addItemsFromPlaylist: (SPTPartialPlaylist*) partialPlaylist {
    __unsafe_unretained MusicVoterServer* weakSelf = self;
    [SPTPlaylistSnapshot playlistWithURI:partialPlaylist.uri session:self.session callback:^(NSError *error, id object) {
        if(error == nil) {
            SPTPlaylistSnapshot* fullPlaylist = object;
            SPTListPage* playlistPartialTracks = fullPlaylist.firstTrackPage;
            for (NSUInteger i = 0; i < playlistPartialTracks.items.count ; i++) {
                VoteTrack* newVoteTrack = [[VoteTrack alloc] initWithTrack:[playlistPartialTracks.items objectAtIndex:i]];
                [weakSelf.voteTracks addObject:newVoteTrack];
                [weakSelf sendTrackAddedToAllClients:newVoteTrack.track.uri.absoluteString];
            }
        }
        [weakSelf sortArrayAndSendTrackListChanged];
    } ];
}

-(void)sortArrayAndSendTrackListChanged {
    [self sortArray];
    [self.delegate trackListChanged];
}

-(void)sortArray {
    [self.voteTracks sortUsingComparator:^NSComparisonResult(VoteTrack*  _Nonnull voteTrack1, VoteTrack*  _Nonnull voteTrack2) {
        return voteTrack1.remoteVotes.count < voteTrack2.remoteVotes.count;
    }];
}

#pragma mark - BonjourServerDelegate

-(void)bonjourServerDidPublish {
    [self updatePublishedStatus];
}

-(void) updatePublishedStatus {
    _published = self.player.loggedIn && self.bonjourServer.published;
    if (_published) {
        [self.delegate connectionReady];
    }
}

-(void) removeTrack: (VoteTrack*) voteTrack {
    [self removeTrackFromAllClients: voteTrack];
    [self.voteTracks removeObject:voteTrack];
}

-(void)removeTrackFromAllClients:(VoteTrack*) voteTrack {
    for (Connection* connection in self.connections) {
        [connection sendRemoveTrack:voteTrack.track.uri.absoluteString];
    }
}

#pragma mark - Connection delegate

- (void)connectionTerminated:(Connection *)connection {
    [self.connections removeObject:connection];
}

- (void)sendAddTrack:(NSString *)trackURI {
    [self receivedAddTrack:trackURI];
}

//received track
- (void)receivedAddTrack: (NSString*) trackURI {
    NSURL* realTrackURI = [NSURL URLWithString:trackURI];
    __unsafe_unretained MusicVoterServer* weakSelf = self;
    [SPTTrack trackWithURI:realTrackURI session:nil callback:^(NSError *error, id track) {
        if (error == nil) {
            VoteTrack* newVoteTrack = [[VoteTrack alloc] initWithTrack:track];
            
            BOOL alreadyInList = NO;
            
            //only add if not already in list
            for (VoteTrack* voteTrack in weakSelf.voteTracks) {
                if (weakSelf.allowSameSongName) {
                    if ([voteTrack.track.uri.absoluteString isEqualToString:trackURI]) {
                        alreadyInList = YES;
                    }
                } else {
                    if ([voteTrack.track.uri.absoluteString isEqualToString:trackURI] || [voteTrack.track.name isEqualToString:newVoteTrack.track.name]) {
                        alreadyInList = YES;
                    }
                }
                
            }
            
            if (alreadyInList == NO) {
                [weakSelf.voteTracks addObject:newVoteTrack];
                [weakSelf sortArrayAndSendTrackListChanged];
                [weakSelf sendTrackAddedToAllClients: trackURI];
            }
        } else {
            NSLog(@"Error getting track %@ ", error.localizedDescription);
        }
    }];
}

-(void) sendTrackAddedToAllClients: (NSString*) trackURI {
#warning sendTrackAddedToAllClients is called way too often
    NSLog(@"warning: sendTrackAddedToAllClients is called way too often");
    for (Connection* connection in self.connections) {
        [connection sendAddTrack:trackURI];
    }
}

//received add vote
- (void)sendAddedVoteForTrack:(NSString *)trackURI {
    NSString* ourID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    [self user:ourID addedVoteForTrack:trackURI];
}

- (void)user: (NSString*) userID addedVoteForTrack: (NSString*) trackURI {
    for (VoteTrack* voteTrack in self.voteTracks) {
        if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
            // Makes sure there is no doubles votes
            [voteTrack.remoteVotes removeObject:userID];
            [voteTrack.remoteVotes addObject:userID];
        }
    }
    [self sendVoteAddedToAllClients:userID track:trackURI];
    [self sortArrayAndSendTrackListChanged];
}

-(void)sendVoteAddedToAllClients: (NSString*)userID track: (NSString*) trackURI {
    for (Connection* connection in self.connections) {
        [connection sendUser:userID addedVoteForTrack:trackURI];
    }
}

//received remove vote
- (void)sendRemovedVoteForTrack:(NSString *)trackURI {
    NSString* ourID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    [self user:ourID removedVoteForTrack:trackURI];
}

- (void)user: (NSString*) userID removedVoteForTrack: (NSString*) trackURI {
    for (VoteTrack* voteTrack in self.voteTracks) {
        if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
            [voteTrack.remoteVotes removeObject:userID];
        }
    }
    [self sendVoteRemovedToAllClients:userID track:trackURI];
    [self sortArrayAndSendTrackListChanged];
}

-(void)sendVoteRemovedToAllClients: (NSString*)userID track: (NSString*) trackURI {
    for (Connection* connection in self.connections) {
        [connection sendUser:userID removedVoteForTrack:trackURI];
    }
}

//new connection
-(void)connectionEstablished: (Connection*) connection {
    connection.delegate = self;
    [self sendAllTracksAddedToClient:connection];
    if (self.player.currentTrackURI == NULL) {
        [connection sendNowPlayingChangedTo:@"none"];
    } else {
        [connection sendNowPlayingChangedTo:self.player.currentTrackURI.absoluteString];
    }
    [self.connections addObject:connection];
}

-(void) sendAllTracksAddedToClient: (Connection*) client {
    for (VoteTrack* voteTrack in self.voteTracks) {
        [client sendAddTrack:voteTrack.track.uri.absoluteString];
        for (NSString* userID in voteTrack.remoteVotes) {
            [client sendUser:userID addedVoteForTrack:voteTrack.track.uri.absoluteString];
        }
    }
}

#pragma mark - Spotify player delegate
-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    
    if (self.player.currentTrackURI.absoluteString == nil) {
        if (self.voteTracks.count > 0) {
            [self playNextTrack];
        } else {
            [self sendNowPlayingToAllClients:@"none"];
            [self.delegate nowPlayingChangedTo:[[SPTTrack alloc] init]];
        }
        
    } else {
        __unsafe_unretained MusicVoterServer* weakSelf = self;
        [SPTTrack trackWithURI:self.player.currentTrackURI session: self.session callback:^(NSError *error, id object) {
            if (error == nil) {
                // only send if we are still playing
                // Stops the sending of an extra bogus call, when the player stops
                if ([weakSelf getIsPlaying]) {
                    SPTTrack* newTrack = object;
                    [weakSelf.delegate nowPlayingChangedTo:newTrack];
                    [weakSelf sortArrayAndSendTrackListChanged];
                }
            } else {
                NSLog(@"Error playing track %@", error.localizedDescription);
            }
        }];
    }
}


@end
