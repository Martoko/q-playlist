//
//  SpotifyAuthenticator.h
//  Music Voter UI
//
//  Created by Martoko on 20/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

@interface SpotifyAuthenticator : NSObject <SPTAuthViewDelegate>

@property (nonatomic, weak) id delegate;

- (id)initWithViewController: (UIViewController*) viewController;
- (void)restoreOldSessionIfValidOtherwiseClearIt;
- (void)displayLoginOverlay;
- (void)logout;

@end

@protocol SpotifyAuthenticatorDelegate <NSObject>

- (void)spotifyAuthenticator: (SpotifyAuthenticator*)spotifyAuthenticator loggedInWithSession: (SPTSession*)session andUser: (SPTUser*)user;
- (void)spotifyAuthenticator: (SpotifyAuthenticator*)spotifyAuthenticator failedToLoginWithError: (NSError *)error;

- (void)spotifyAuthenticatorStartedLoading: (SpotifyAuthenticator*)spotifyAuthenticator;
@end