//
//  GRPreferencesController.m
//  Grid
//
//  Created by Rob Rix on 11-09-27.
//  Copyright 2011 Rob Rix. All rights reserved.
//

#import "GRPreferencesController.h"
#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"
#import "SRValidator.h"
#import "SRRecorderCell.h"
#import "SRRecorderControl.h"

NSString * const GRShortcutWasPressedNotification = @"GRShortcutWasPressedNotification";

OSStatus GRShortcutWasPressed(EventHandlerCallRef nextHandler, EventRef event, void *userData);

@interface GRPreferencesController ()

@property (nonatomic, assign) SRRecorderControl *shortcutRecorder;

@property (nonatomic, assign) EventHotKeyRef shortcutReference;
@property (nonatomic, copy) NSDictionary *shortcut;

@end

@implementation GRPreferencesController

@synthesize shortcutView, shortcutRecorder, shortcutReference;


+(void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"`", @"characters",
			[NSNumber numberWithInteger:50], @"keyCode",
			[NSNumber numberWithUnsignedInteger:cmdKey + optionKey], @"modifierFlags",
		nil], @"GRShortcut",
		(id)kCFBooleanTrue, @"GRShowDockIcon",
	nil]];
}


-(void)awakeFromNib {
	shortcutRecorder = [[SRRecorderControl alloc] initWithFrame:shortcutView.frame];
	
	[shortcutView.superview addSubview:shortcutRecorder];
	[shortcutView removeFromSuperview];
	
	shortcutRecorder.delegate = self;
	shortcutRecorder.canCaptureGlobalHotKeys = YES;
	
	shortcutRecorder.objectValue = self.shortcut;
	
	EventTypeSpec eventType = {
		.eventClass = kEventClassKeyboard,
		.eventKind = kEventHotKeyPressed
	};
	InstallApplicationEventHandler(&GRShortcutWasPressed, 1, &eventType, self, NULL);
	
	[shortcutRecorder release];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"GRShowDockIcon"]) {
		ProcessSerialNumber psn = { 0, kCurrentProcess };
		TransformProcessType(&psn, kProcessTransformToForegroundApplication);
	}
}


-(IBAction)showWindow:(id)sender {
	[self.window center];
	[super showWindow:sender];
}


-(NSDictionary *)shortcut {
	return [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"GRShortcut"];
}

-(void)setShortcut:(NSDictionary *)shortcut {
	[[NSUserDefaults standardUserDefaults] setObject:shortcut forKey:@"GRShortcut"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	if(shortcut) {
		EventHotKeyID shortcutIdentifier = {
			.id = 1,
			.signature = 'GRSc'
		};
		
		NSInteger keyCode = [[shortcut objectForKey:@"keyCode"] integerValue];
		NSUInteger modifierFlags = [[shortcut objectForKey:@"modifierFlags"] unsignedIntegerValue];
		// if(shortcutReference) {
		UnregisterEventHotKey(shortcutReference);
		// }
		OSErr error = RegisterEventHotKey(keyCode, [shortcutRecorder cocoaToCarbonFlags:modifierFlags], shortcutIdentifier, GetApplicationEventTarget(), 0, &shortcutReference);
		if(error != noErr) {
			NSLog(@"error when registering hot key: %i", error);
		}
	}
}


-(BOOL)showDockIcon {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GRShowDockIcon"];
}

-(void)setShowDockIcon:(BOOL)showDockIcon {
	[[NSUserDefaults standardUserDefaults] setBool:showDockIcon forKey:@"GRShowDockIcon"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo {
	self.shortcut = shortcutRecorder.objectValue;
}

@end


OSStatus GRShortcutWasPressed(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
	[[NSNotificationCenter defaultCenter] postNotificationName:GRShortcutWasPressedNotification object:nil];
	return noErr;
}


@implementation SRValidator (GRCanCaptureGlobalHotKeysIsBroken)

-(BOOL)isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags error:(NSError **)error {
	return NO;
}

@end
