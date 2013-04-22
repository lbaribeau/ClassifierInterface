@implementation Glyph : CPObject
{
    CPString    ulx             @accessors;
    CPString    uly             @accessors;
    CPString    nRows           @accessors;
    CPString    nCols           @accessors;
    // GlyphIds    ids             @accessors;  //TODO
    CPString    feature_scaling @accessors;
    CPArray     features        @accessors;
    CPData      pngData         @accessors;
}

+ (CPArray)glyphProperties
{
    return [
        ['ulx', 'ulx'],
        ['uly', 'uly'],
        ['nRows', 'nrows'],
        ['nCols', 'ncols'],
        ['featureScaling', 'feature_scaling']
        ['features', 'features'],
        ['pngData', 'data']
    ];
}

- (id)initWithJson:(JSObject)jsonObject
{
    // Takes JSON and makes a glyph object.  Uses glyphProperties to
    // index the values out of the JSON dictionary.
    // Usage: foo = [[Glyph alloc] initWithJson:serverResponse];
    var self = [self init];

    if (self)
    {
        var i = 0,
            count = [[Glyph glyphProperties] count],
            map = [Glyph glyphProperties];

        for (; i < count; i++)
        {
            var objectKey = map[i][0],
                serverKey = map[i][1];

            if (map[i][1] === 'data')
                [self setValue:[CPData dataWithBase64:jsonObject[serverKey]] forKey:objectKey];
            else
                [self setValue:jsonObject[serverKey] forKey:objectKey];
        }

    }

    return self;
}

+ (CPArray)objectsFromJson:(CPArray)aJsonArray
{
    var i = 0,
        count = [aJsonArray count],
        outArray = [];

    for (; i < count; ++i)
    {
        var glyph = [[Glyph alloc] initWithJson:[aJsonArray objectAtIndex:i]];
        [outArray addObject:glyph];
    };

    return outArray;
}

@end
