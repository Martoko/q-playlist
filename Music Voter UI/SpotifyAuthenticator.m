//
//  SpotifyAuthenticator.m
//  Music Voter UI
//
//  Created by Martoko on 20/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "SpotifyAuthenticator.h"

@interface SpotifyAuthenticator ()

@property UIViewController* viewController;
@property SPTAuthViewController *authViewController;
- (void)sendUserAndSession: (SPTSession*) session;

@end

@implementation SpotifyAuthenticator

- (id)init {
    return [self initWithViewController:nil];
}

- (id)initWithViewController: (UIViewController*) viewController;
{
    self = [super init];
    if (self) {
        _viewController = viewController;
        _delegate = nil;
        
        _authViewController = [SPTAuthViewController authenticationViewController];
        _authViewController.delegate = self;
        _authViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        _authViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        _viewController.modalPresentationStyle = UIModalPresentationCurrentContext;
        _viewController.definesPresentationContext = YES;
    }
    return self;
}

- (void)dealloc
{
    self.authViewController.delegate = nil;
}

- (void)displayLoginOverlay {
    [self.viewController presentViewController:self.authViewController animated:NO completion:nil];
}

- (void)restoreOldSessionIfValidOtherwiseClearIt {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (auth.session == nil) {
        //Do nothing
    }
    if ([auth.session isValid]) {
        [self sendUserAndSession: auth.session];
    } else {
        //renew session
        [self logout];
    }
}

- (void) sendUserAndSession: (SPTSession*) session {
    [self.delegate spotifyAuthenticatorStartedLoading:self];
    __weak SpotifyAuthenticator * weakSelf = self;
    [SPTUser requestCurrentUserWithAccessToken:session.accessToken callback:^(NSError *error, id object) {
        if (error == nil) {
            SPTUser* currentUser = object;
            [weakSelf.delegate spotifyAuthenticator:self loggedInWithSession:session andUser:currentUser];
        }
    }];
}

- (void)logout {
    [self.authViewController clearCookies:nil];
}


#pragma mark - SPTAuthDelegate

- (void)authenticationViewController:(SPTAuthViewController *)viewcontroller didLoginWithSession:(SPTSession *)session {
    [self sendUserAndSession:session];
}

- (void)authenticationViewController:(SPTAuthViewController *)viewcontroller didFailToLogin:(NSError *)error {
    [self.delegate spotifyAuthenticator:self failedToLoginWithError:error];
}

-(void)authenticationViewControllerDidCancelLogin:(SpotifyAuthenticator*) spotifyAuthenticator {
    
}

@end
