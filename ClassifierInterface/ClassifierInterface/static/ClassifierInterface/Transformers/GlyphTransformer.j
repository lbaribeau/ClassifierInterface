@import "../Models/Glyph.j"

@implementation GlyphTransformer : CPObject //See WLRemoteTransformers.j in Ratatosk
{

}

+ (BOOL)allowsReverseTransformation
{
    return YES;  // Change to YES to save glyphs
}

+ (Class)transformedValueClass
{
    return [Glyph class];
}

- (id)transformedValue:(CPArray)arrayOfGlyphs
{
    return [Glyph objectsFromJson:arrayOfGlyphs];
}

- (id)reverseTransformedValue:(id)values
{
}

@end
