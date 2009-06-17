//
//  SIOutline.m
//
//  Copyright (c) 2009  Martin Kühl <purl.org/net/mkhl>
//

#import "SIOutline.h"
#import "Macros.h"

KVO_Context(SIDocumentChanged);
KVO_Context(SIPositionChanged);

NSView <OakTextView> *SIMainTextView(void)
{
  id view = [[[NSApp mainWindow] windowController] textView];
  if ([view isKindOfClass:NSClassFromString(@"OakTextView")])
    return (NSView <OakTextView> *)view;
  return nil;
}

NSView <OakStatusBar> *SIMainStatusBar(void)
{
  id view = [[[NSApp mainWindow] windowController] valueForKey:@"statusBar"];
  if ([view isKindOfClass:NSClassFromString(@"OakStatusBar")])
    return (NSView <OakStatusBar> *)view;
  return nil;
}

#pragma mark -
@implementation SIOutline

#pragma mark Accessors
- (NSWindow *)window
{
  return window;
}
- (void)setXml:(NSXMLDocument *)newXml
{
  [xml_ autorelease];
  [self willChangeValueForKey:@"xml"];
  xml_ = [newXml retain];
  [self didChangeValueForKey:@"xml"];
}
- (NSXMLDocument *)xml
{
  return xml_;
}
- (void)setScopeRanges:(NSDictionary *)newScopes
{
  [scopeRanges_ autorelease];
  [self willChangeValueForKey:@"scopeRanges"];
  scopeRanges_ = [newScopes retain];
  [self didChangeValueForKey:@"scopeRanges"];
}
- (NSDictionary *)scopeRanges
{
  return scopeRanges_;
}
- (void)setLineOffsets:(NSArray *)newLines
{
  [lineOffsets_ autorelease];
  [self willChangeValueForKey:@"lineOffsets"];
  lineOffsets_ = [newLines retain];
  [self didChangeValueForKey:@"lineOffsets"];
}
- (NSArray *)lineOffsets
{
  return lineOffsets_;
}

#pragma mark Convenience Accessors
- (NSRange)rangeForNode:(NSXMLNode *)node
{
  return [[[self scopeRanges] objectForKey:[node XPath]] rangeValue];
}

- (uint)offsetForLine:(uint)line column:(uint)column
{
  return [[[self lineOffsets] objectAtIndex:line] unsignedIntValue] + column;
}

#pragma mark -
#pragma mark Memory Management
- (void)awakeFromNib
{
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(outlineViewSelectionDidChange:)
                 name:NSOutlineViewSelectionDidChangeNotification
               object:view];
  [NSApp addObserver:self
          forKeyPath:@"mainWindow.windowController.textView.document"
             options:0
             context:SIDocumentChanged];
  [NSApp addObserver:self
          forKeyPath:@"mainWindow.windowController.statusBar.lineNumber"
             options:0
             context:SIPositionChanged];
  [NSApp addObserver:self
          forKeyPath:@"mainWindow.windowController.statusBar.columnNumber"
             options:0
             context:SIPositionChanged];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  DESTROY(xml_);
  DESTROY(scopeRanges_);
  DESTROY(lineOffsets_);
  [super dealloc];
}

#pragma mark Entry Point
- (void)update
{
  updating_ = YES;
  statusBar = SIMainStatusBar();
  textView = SIMainTextView();
  if (textView) {
    if ([window isVisible]) {
      if ([[textView xmlRepresentation] hash] != lastXMLHash_) {
        [self updateXML];
        [self updateScopes];
        [self updateLines];
        [self filterXML];
      }
    }
  }
  updating_ = NO;
}

#pragma mark -
#pragma mark Line Offsets
- (void)updateLines
{
  if ([self xml]) {
    NSMutableArray *offsets = [NSMutableArray array];
    NSArray *lines =  [[[self xml] stringValue] componentsSeparatedByString:@"\n"];
    uint offset = 0;
    uint i, count = [lines count];
    for (i = 0; i < count; i++) {
      [offsets addObject:[NSNumber numberWithUnsignedInt:offset]];
      offset += 1 + [[lines objectAtIndex:i] length];
    }
    [self setLineOffsets:offsets];
  }
}

#pragma mark Scope Ranges
- (void)updateScopeForNode:(NSXMLNode *)node
                  atOffset:(uint)offset
              inDictionary:(NSMutableDictionary *)dict
{
  NSRange range = NSMakeRange(offset, [[node stringValue] length]);
  [dict setObject:[NSValue valueWithRange:range] forKey:[node XPath]];
  uint currentOffset = offset;
  uint i, count = [node childCount];
  for (i = 0; i < count; i++) {
    NSXMLNode *child = [node childAtIndex:i];
    [self updateScopeForNode:child atOffset:currentOffset inDictionary:dict];
    currentOffset += [[child stringValue] length];
  }
}

- (void)updateScopes
{
  if ([self xml]) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [self updateScopeForNode:[[self xml] rootElement]
                    atOffset:0
                inDictionary:dict];
    [self setScopeRanges:dict]; 
  }
}

#pragma mark XML
- (void)filterXML
{
  if ([self xml]) {
    NSArray *nodes = [[self xml] nodesForXPath:@"//text()" error:nil];
    uint i, count = [nodes count];
    for (i = 0; i < count; i++) {
      NSXMLNode *node = [nodes objectAtIndex:i];
      NSIndexPath *path = [self indexPathForNode:node];
      [tree removeObjectAtArrangedObjectIndexPath:path];
      [node detach];
    }
  }
}

- (void)updateXML
{
  if (textView) {
    NSString *xmlString = [textView xmlRepresentation];
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[xmlString dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
    [parser setDelegate:self];
    BOOL ok = [parser parse];
    if (!ok) {
      DebugLog(@"Failed to parse XML Representation: %@",
               [parser parserError]);
    }
    lastXMLHash_ = [xmlString hash];
  }
}

#pragma mark NSTreeController Interaction
- (NSIndexPath *)indexPathForNode:(NSXMLNode *)node
{
  NSMutableArray *idxs = [NSMutableArray array];
  NSXMLNode *currentNode = node;
  while ([currentNode parent]) {
    [idxs addObject:[NSNumber numberWithUnsignedInt:[currentNode index]]];
    currentNode = [currentNode parent];
  }
  NSIndexPath *path = [NSIndexPath new];
  while ([idxs count] > 0) {
    path = [path indexPathByAddingIndex:[[idxs lastObject] unsignedIntValue]];
    [idxs removeLastObject];
  }
  return path;
}

#pragma mark -
#pragma mark OutlineView Notifications
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
  if (!updating_) {
    updating_ = YES;
    if (textView) {
      NSRange range = [self rangeForNode:[[tree selectedObjects] lastObject]];
      [self selectRange:range];
    }
    updating_ = NO;
  }
}

#pragma mark OakTextView Notifications
- (void)textViewSelectionDidChange:(NSNotification *)notification
{
  if (!updating_) {
    updating_ = YES;
    if (statusBar) {
      uint line = [[statusBar valueForKey:@"lineNumber"] unsignedIntValue];
      uint column = [[statusBar valueForKey:@"columnNumber"] unsignedIntValue];
      if ((lastLineNumber_ != line) || (lastColumnNumber_ != column)) {
        lastLineNumber_ = line;
        lastColumnNumber_ = column;
        uint offset = [self offsetForLine:line column:column];
        NSXMLNode *node = [self nodeForOffset:offset];
        NSIndexPath *path = [self indexPathForNode:node];
        [tree setSelectionIndexPath:path];
      }
    }
    updating_ = NO;
  }
}

#pragma mark Other Notifications
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if (context == SIDocumentChanged) {
    [self update];
  } else if (context == SIPositionChanged) {
    [self textViewSelectionDidChange:nil];
  } else {
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}

#pragma mark -
#pragma mark OakTextView Selection
- (NSArray *)coordinatesForOffset:(uint)offset
{
  uint i, count = [[self lineOffsets] count];
  for (i = 0; i < count; i++)
    if ([[[self lineOffsets] objectAtIndex:i] unsignedIntValue] > offset)
      break;
  uint lineOffset = [[[self lineOffsets] objectAtIndex:i-1] unsignedIntValue];
  uint columnNumber = 1 + offset - lineOffset;
  // The line number (1 based)
  NSNumber *line = [NSNumber numberWithUnsignedInt:i];
  // The column number (1 based)
  NSNumber *column = [NSNumber numberWithUnsignedInt:columnNumber];
  return [NSArray arrayWithObjects:line, column, nil];
}

- (void)selectRange:(NSRange)range
{
  if (textView) {
    NSArray *from = [self coordinatesForOffset:range.location];
    NSArray *to = [self coordinatesForOffset:(range.location + range.length)];
    [textView goToLineNumber:[from objectAtIndex:0]];
    [textView goToColumnNumber:[from objectAtIndex:1]];
    [textView selectToLine:[to objectAtIndex:0]
                 andColumn:[to objectAtIndex:1]];
  }
}

#pragma mark -
#pragma mark NSOutlineView Selection
- (NSXMLNode *)nodeForOffset:(uint)offset belowNode:(NSXMLNode *)node
{
  NSRange range = [self rangeForNode:node];
  uint from = range.location;
  uint to = range.location + range.length;
  if ((from > offset) || (to < offset))
    return nil;
  uint i, count = [node childCount];
  for (i = 0; i < count; i++) {
    NSXMLNode *child = [node childAtIndex:i];
    NSXMLNode *match = [self nodeForOffset:offset belowNode:child];
    if (match)
      return match;
  }
  return node;
}

- (NSXMLNode *)nodeForOffset:(uint)offset
{
  return [self nodeForOffset:offset belowNode:[[self xml] rootElement]];
}

#pragma mark -
#pragma mark NSXMLParser Delegate
// NSXMLDocument's own parser will always omit "ignorable whitespace" when 
// generating its `stringValue`, even when told to preserve whitespace.
// So we roll our own NSXMLParser to construct the NSXMLDocument.
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
  rootElement_ = nil;
  currentElement_ = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
  [self setXml:[[[NSXMLDocument alloc] initWithRootElement:rootElement_] autorelease]];
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict
{
  NSXMLElement *element = [NSXMLElement elementWithName:elementName];
  if (!rootElement_) {
    currentElement_ = rootElement_ = element;
  } else {
    [currentElement_ addChild:element];
    currentElement_ = element;
  } 
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
{
  currentElement_ = (NSXMLElement *)[currentElement_ parent];
}

- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
  [currentElement_ addChild:[NSXMLNode textWithStringValue:string]];
}

- (void)parser:(NSXMLParser *)parser
foundIgnorableWhitespace:(NSString *)string
{
  [currentElement_ addChild:[NSXMLNode textWithStringValue:string]];
}

@end
