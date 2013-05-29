@implementation SymbolCollection : CPObject
{
    CPString symbolName @accessors;
    CPMutableArray glyphList @accessors;
    int maxRows @accessors;
    int maxCols @accessors;
}
- (SymbolCollection)init
{
    self = [super init];
    [self setSymbolName:@""];
    [self setGlyphList:[[CPMutableArray alloc] init]];  // Mutable gives you addObject
    [self setMaxRows:0];
    [self setMaxCols:0];
    return self;
}
- (void)addGlyph:(Glyph)glyph
{
    [glyphList addObject:glyph];
}
@end
