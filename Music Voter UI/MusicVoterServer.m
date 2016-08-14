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
@property NSMutableArray* voteTracks;
@property dispatch_queue_t voteTracksQueue;

@end

#warning P:LOW; what happens, if the user is signed out remotely while the server is running?

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
        _allowSameSongName = YES; // Changing this to NO, means having to handle it in the addVote function
                                  // it currently only works on trackURI's not names
        _voteTracksQueue = dispatch_queue_create("hostVoteTracksQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)dealloc
{
    self.bonjourServer.delegate = nil;
    self.player.playbackDelegate = nil;
    self.player.delegate = nil;
    [self audioStreamingDidLogout:nil];
}

- (NSArray<VoteTrack*>*) getVoteTracks {
    return [[NSArray alloc] initWithArray:self.voteTracks];
}

-(NSString*) getName {
    return [self.bonjourServer getName];
}

-(BOOL) getIsPlaying {
    return self.player.isPlaying;
}

- (void) connectIfNot {
    if (self.published == NO) {
        [self publish];
    }
}

-(void) publish {
    [self.bonjourServer publish];
    
    SPTAuth* auth = [SPTAuth defaultInstance];
    
    if (self.player == nil) {
        NSError *error = nil;
        self.player = [SPTAudioStreamingController sharedInstance];
        if ([self.player startWithClientId: auth.clientID error: &error]) {
            self.player.delegate = self;
            self.player.playbackDelegate = self;
            self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity: 1024 * 1024 * 64];
            [self.player loginWithAccessToken: auth.session.accessToken];
        } else {
            self.bonjourServer.delegate = nil;
            self.bonjourServer = nil;
            self.player = nil;
            
            NSLog(@"Error logging in to Spotify: %@", error.description);
            [self audioStreamingDidLogout:nil];
            [self.delegate connectionTerminated];
        }
        [self updatePublishedStatus];
    }
}

-(void) playNextTrack {
    __weak MusicVoterServer* weakSelf = self;
    
    dispatch_async(self.voteTracksQueue, ^{
        _isPaused = NO;
        if (weakSelf.voteTracks.count > 0) {
            VoteTrack* currentVoteTrack = weakSelf.voteTracks.firstObject;
            weakSelf.nowPlayingURIs = [[NSArray alloc] initWithObjects:currentVoteTrack.track.uri, nil];
            
            [weakSelf sendNowPlayingToAllClients:currentVoteTrack.track.uri.absoluteString];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate nowPlayingChangedTo:currentVoteTrack.track];
            });
            
            [weakSelf removeTrack:currentVoteTrack];
            
            [weakSelf.player playURIs:weakSelf.nowPlayingURIs  fromIndex:0 callback:^(NSError *error) {
                if (error != nil) {
                    NSLog(@"Error playing song: %@", error.description);
                    if (weakSelf.voteTracks.count > 0) {
                        [weakSelf playNextTrack];
                    }
                }
            }];
        } else {
            [weakSelf.player stop:nil];
            // UI changes must not happen from background queue
            [weakSelf sendNowPlayingToAllClients:@"none"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate nowPlayingChangedTo:[[SPTTrack alloc] init]];
            });
        }
    });
}

-(void)sendNowPlayingToAllClients: (NSString*)trackURI {
    for (Connection* connection in self.connections) {
        [connection sendNowPlayingChangedTo:trackURI];
    }
}

-(BOOL) playOrPauseReturnPlaying {
    if (self.voteTracks.count > 0) {
        if (_isPaused == NO && [self getIsPlaying]) {
            [self pausePlaying];
            return NO;
        } else if (_isPaused && [self getIsPlaying] == NO) {
            [self continuePlaying];
            return YES;
        } else if (_isPaused == NO && [self getIsPlaying] == NO) {
            [self playNextTrack];
            return YES;
        } else {
            NSLog(@"Vote track count > 0, and we don't know what to do with play/pause");
            return [self getIsPlaying];
        }
        
    } else {
        if (_isPaused == NO && [self getIsPlaying]) {
            [self pausePlaying];
            return NO;
        } else if (_isPaused && [self getIsPlaying] == NO) {
            [self continuePlaying];
            return YES;
        } else if (_isPaused == NO && [self getIsPlaying] == NO) {
            [self playNextTrack];
            return NO;
        } else {
            NSLog(@"Vote track count == 0, and we don't know what to do with play/pause");
            return [self getIsPlaying];
        }
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

-(void) continuePlaying {
    _isPaused = NO;
    [self.player setIsPlaying:YES callback:nil];
}

-(void) addItemsFromPlaylist: (SPTPartialPlaylist*) partialPlaylist {
    __weak MusicVoterServer* weakSelf = self;
    [SPTPlaylistSnapshot playlistWithURI:partialPlaylist.uri session:self.session callback:^(NSError *error, id object) {
        if(error == nil) {
                SPTPlaylistSnapshot* fullPlaylist = object;
                SPTListPage* playlistPartialTracks = fullPlaylist.firstTrackPage;
                NSInteger importedSongs = 0;
                for (NSUInteger i = 0; i < playlistPartialTracks.items.count ; i++) {
                    SPTTrack* newTrack = [playlistPartialTracks.items objectAtIndex:i];
                    [weakSelf addTrack:newTrack];
                    if(newTrack.playableUri == nil) {
                        importedSongs += 1;
                    }
                }
            
            if(importedSongs == playlistPartialTracks.items.count) {
                [weakSelf.delegate alert: @"It is not possible to add imported songs" withTitle: @"Cannot add songs"];
            }
        }
    }];
}

-(void)sortArrayAndSendTrackListChanged {
    [self sortArray];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate trackListChanged: [self getVoteTracks]];
    });
}

-(void)sortArray {
    NSSortDescriptor *remoteVotesSorter = [[NSSortDescriptor alloc] initWithKey:@"remoteVotes.@count" ascending:NO];
    NSSortDescriptor *playableUriSorter = [[NSSortDescriptor alloc] initWithKey:@"track.uri.absoluteString" ascending:NO];
    
    [self.voteTracks sortUsingDescriptors:[NSArray arrayWithObjects:remoteVotesSorter, playableUriSorter, nil]];
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
    __weak MusicVoterServer* weakSelf = self;
    dispatch_async(self.voteTracksQueue, ^{
        [weakSelf removeTrackFromAllClients: voteTrack];
        [weakSelf.voteTracks removeObject:voteTrack];
        [weakSelf sortArrayAndSendTrackListChanged];
    });
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
    __weak MusicVoterServer* weakSelf = self;
    [SPTTrack trackWithURI:realTrackURI session:nil callback:^(NSError *error, id track) {
        if (error == nil) {
            [weakSelf addTrack:track];
        } else {
            NSLog(@"Error getting track %@ ", error.localizedDescription);
        }
    }];
}

- (void)addTrack: (SPTTrack*) track {
     __weak MusicVoterServer* weakSelf = self;
    dispatch_async(self.voteTracksQueue, ^{
        VoteTrack* newVoteTrack = [[VoteTrack alloc] initWithTrack:track];
        
        BOOL alreadyInList = NO;
        
        if(track.playableUri.absoluteString == nil) {
            // Skip imported tracks
            // NSLog(@"Track has no playable URI: %@", track.name);
            return;
        }
        
        //only add if not already in list
        for (VoteTrack* voteTrack in weakSelf.voteTracks) {
            if (weakSelf.allowSameSongName) {
                if ([voteTrack.track.uri.absoluteString isEqualToString:track.uri.absoluteString]) {
                    alreadyInList = YES;
                }
            } else {
                if ([voteTrack.track.uri.absoluteString isEqualToString:track.uri.absoluteString] || [voteTrack.track.name isEqualToString:newVoteTrack.track.name]) {
                    alreadyInList = YES;
                }
            }
            
        }
        
        if (alreadyInList == NO) {
            [weakSelf.voteTracks addObject:newVoteTrack];
            [weakSelf sortArrayAndSendTrackListChanged];
            [weakSelf sendTrackAddedToAllClients: track.uri.absoluteString];
        }
    });
}

-(void) sendTrackAddedToAllClients: (NSString*) trackURI {
#warning P:LOW; sendTrackAddedToAllClients is called way too often
    // NSLog(@"warning: sendTrackAddedToAllClients is called way too often");
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
    __weak MusicVoterServer* weakSelf = self;
    dispatch_async(self.voteTracksQueue, ^{
        BOOL alreadyInList = NO;
        VoteTrack* chosenVoteTrack;
        for (VoteTrack* voteTrack in weakSelf.voteTracks) {
            if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
                chosenVoteTrack = voteTrack;
                alreadyInList = YES;
            }
        }
        
        if (alreadyInList) {
            // Makes sure there is no doubles votes
            [chosenVoteTrack.remoteVotes removeObject:userID];
            [chosenVoteTrack.remoteVotes addObject:userID];
            [weakSelf sendVoteAddedToAllClients:userID track:trackURI];
            [weakSelf sortArrayAndSendTrackListChanged];
            
        } else if (alreadyInList == NO) {
            NSURL* realTrackURI = [NSURL URLWithString:trackURI];
            [SPTTrack trackWithURI:realTrackURI session:nil callback:^(NSError *error, id track) {
                if (error == nil) {
                    [weakSelf addTrack:track];
                    [weakSelf user:userID addedVoteForTrack:trackURI];
                } else {
                    NSLog(@"Error getting track %@ ", error.localizedDescription);
                }
            }];
        }
    });
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
    __weak MusicVoterServer* weakSelf = self;
    dispatch_async(self.voteTracksQueue, ^{
        for (VoteTrack* voteTrack in weakSelf.voteTracks) {
            if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
                [voteTrack.remoteVotes removeObject:userID];
            }
        }
        [weakSelf sendVoteRemovedToAllClients:userID track:trackURI];
        [weakSelf sortArrayAndSendTrackListChanged];
    });
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
    __weak MusicVoterServer* weakSelf = self;
    dispatch_async(self.voteTracksQueue, ^{
        for (VoteTrack* voteTrack in weakSelf.voteTracks) {
            [client sendAddTrack:voteTrack.track.uri.absoluteString];
            for (NSString* userID in voteTrack.remoteVotes) {
                [client sendUser:userID addedVoteForTrack:voteTrack.track.uri.absoluteString];
            }
        }
    });
}

#pragma mark - Spotify player delegate

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    __weak MusicVoterServer* weakSelf = self;
    
    if (self.player.currentTrackURI.absoluteString == nil) {
        dispatch_async(self.voteTracksQueue, ^{
            if (weakSelf.voteTracks.count > 0) {
                [weakSelf playNextTrack];
            } else {
                [weakSelf sendNowPlayingToAllClients:@"none"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate nowPlayingChangedTo:[[SPTTrack alloc] init]];
                });
            }
        });
        
    } else {
        [SPTTrack trackWithURI:self.player.currentTrackURI session: self.session callback:^(NSError *error, id object) {
            if (error == nil) {
                // only send if we are still playing
                // Stops the sending of an extra bogus call, when the player stops
                if ([weakSelf getIsPlaying]) {
                    SPTTrack* newTrack = object;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.delegate nowPlayingChangedTo:newTrack];
                    });
                }
            } else {
                NSLog(@"Error playing track %@", error.localizedDescription);
            }
        }];
    }
}


- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message {
    NSLog(@"Message from Spotify: %@", message);
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didFailToPlayTrack:(NSURL *)trackUri {
    NSLog(@"failed to play track: %@", trackUri);
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    NSLog(@"is playing = %d", isPlaying);
}

- (void)audioStreamingDidLogout:(SPTAudioStreamingController *)audioStreaming {
    NSError *error = nil;
    if (![self.player stopWithError:&error]) {
        NSLog(@"Error logging out off Spotify: %@", error.description);
        [self audioStreamingDidLogout:nil];
    }
    [self updatePublishedStatus];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didEncounterError:(NSError *)error {
    if (error != nil) {
        NSLog(@"*** Playback got error: %@", error);
        return;
    }
}

- (void)audioStreamingDidLogin:(SPTAudioStreamingController *)audioStreaming {
//    NSLog(@"Did log in");
}

@end
