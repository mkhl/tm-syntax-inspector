//
//  SIWindowController.m
//
//  Copyright (c) 2009  Martin Kühl <purl.org/net/mkhl>
//

#import "SIWindowController.h"
#import "SIOutline.h"
#import "Macros.h"

#pragma mark Static Data
static NSString *SIMenuItemTitle = @"Show Syntax Inspector";

#pragma mark Helper Functions
NSMenu *SIWindowMenu(void)
{
  return [[[NSApp mainMenu] itemWithTitle:@"Window"] submenu];
}

#pragma mark -
@implementation SIWindowController

#pragma mark Memory Management
- (id)initWithPlugInController:(id <TMPlugInController>)controller
{
  SIOutline *it = [[[SIOutline alloc] init] autorelease];
	self = [super initWithWindowNibName:@"SyntaxInspector" owner:it];
  if (!self)
    return nil;
  outline = [it retain];
  menuItem = [[self createMenuItem] retain];
  [self installMenuItem];
	return self;
}

- (void)dealloc
{
  [self uninstallMenuItem];
  DESTROY(outline);
  DESTROY(menuItem);
  [super dealloc];
}

#pragma mark Menu Item
- (NSMenuItem *)createMenuItem
{
  NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:SIMenuItemTitle
                                                 action:@selector(showWindow:)
                                          keyEquivalent:@""]
                      autorelease];
  [item setTarget:self];
  return item;
}

- (void)installMenuItem
{
  NSMenu *windowMenu = SIWindowMenu();
  if (windowMenu) {
    uint separators, i, count = [windowMenu numberOfItems];
    for (separators = 0, i = 0; (separators < 2) && (i < count); i++)
      if ([[windowMenu itemAtIndex:i] isSeparatorItem])
        separators++;
    [windowMenu insertItem:menuItem atIndex:(separators < 2 ? 0 : i - 1)];
  }
}

- (void)uninstallMenuItem
{
  [SIWindowMenu() removeItem:menuItem];
}

#pragma mark NSWindowController
- (void)showWindow:(id)sender
{
  [super showWindow:sender];
  [self setWindow:[outline window]];
  [outline update];
}

@end
