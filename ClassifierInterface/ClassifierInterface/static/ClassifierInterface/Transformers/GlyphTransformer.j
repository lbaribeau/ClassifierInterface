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

- (CPArray)transformedValue:(CPArray)JsonArrayOfGlyphs
{
    var output = [Glyph objectsFromJson:JsonArrayOfGlyphs];
    console.log("Transformer input:");
    console.log(JsonArrayOfGlyphs);
    console.log(output);
    return output;
}

- (id)reverseTransformedValue:(CPArray)glyphs
{
    // Print JSON given an array of Glyphs
    /*
    var i = 0,
        count = [glyphs count],
        outArray = [];

    for (; i < count; ++i)
    {
        var JsonObject;
        if([glyphs objectAtIndex:i])
         = [[glyphs objectAtIndex:i] copy]
        var JsonObject = [glyphs objectAtIndex:i];
        [JsonObject pngData

    }*/
    return [Glyph objectsToJson:glyphs];

}

@end
