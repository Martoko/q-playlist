//
//  MusicVoterConnectionProtocol.h
//  Music Voter UI
//
//  Created by Martoko on 08/11/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <Spotify/Spotify.h>
#import "VoteTrack.h"

@protocol MusicVoterConnectionDelegate <NSObject>

- (void)connectionReady;
- (void)trackListChanged;
- (void)nowPlayingChangedTo: (SPTTrack*)track;

@optional
- (void)connectionTerminated;

@end

@protocol MusicVoterConnection <NSObject>

- (void)connect;
- (NSString*) getName;

- (void)sendAddTrack: (NSString*) trackURI;
- (void)sendAddedVoteForTrack: (NSString*) trackURI;
- (void)sendRemovedVoteForTrack: (NSString*) trackURI;

@property (nonatomic, weak) id<MusicVoterConnectionDelegate> delegate;
@property (readonly) NSMutableArray<VoteTrack*>* voteTracks;

@optional
-(void) addItemsFromPlaylist: (SPTPartialPlaylist*) partialPlaylist;

@property (readonly) BOOL isPaused;
-(BOOL) getIsPlaying;
-(void) stopPlaying;
-(void) continueOrStartPlaying;
-(void) pausePlaying;
-(void) playNextTrack;

@end