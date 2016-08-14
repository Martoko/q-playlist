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

- (void) alert:(NSString*) message withTitle:(NSString*) title;

- (void)connectionReady;
- (void)trackListChanged: (NSArray<VoteTrack*>*)voteTracks;
- (void)nowPlayingChangedTo: (SPTPartialTrack*)track;

@optional
- (void)connectionTerminated;

@end

@protocol MusicVoterConnection <NSObject>

- (void)connectIfNot;
- (NSString*) getName;

- (void)sendAddTrack: (NSString*) trackURI;
- (void)sendAddedVoteForTrack: (NSString*) trackURI;
- (void)sendRemovedVoteForTrack: (NSString*) trackURI;

@property (nonatomic, weak) id<MusicVoterConnectionDelegate> delegate;
- (NSArray<VoteTrack*>*) getVoteTracks;

@optional
-(void) addItemsFromPlaylist: (SPTPartialPlaylist*) partialPlaylist;

@property (readonly) BOOL isPaused;
-(BOOL) getIsPlaying;
-(BOOL) playOrPauseReturnPlaying;
-(void) stopPlaying;
-(void) continuePlaying;
-(void) pausePlaying;
-(void) playNextTrack;

@end