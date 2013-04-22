@implementation Glyph : CPObject
{
    CPString    ulx         @accessors;
    CPString    uly         @accessors;
    CPString    nCols       @accessors;
    CPString    nRows       @accessors;
    CPArray     features    @accessors;
    // TODO: ids, data, feature_scaling
}

+ (CPArray)glyphProperties
{
    return [
        ['pk', 'url'],
        ['ulx', 'ulx'],
        ['uly', 'uly'],
        ['nRows', 'nrows'],
        ['nCols', 'ncols'],
        ['features', 'features']
    ];
}

- (Glyph)initWithJson:(JSObject)jsonObject
{
    // Takes JSON and makes a glyph object.  Uses glyphProperties to
    // index the values out of the JSON dictionary.
    // Usage: foo = [[Glyph alloc] initWithJson:serverResponse];
    var self = [self init],
        i = 0,
        count = [[Glyph glyphProperties] count],
        map = [Glyph glyphProperties];

    for (; i < count; i++)
    {
        [self setValue:jsonObject[map[i][1]] forKey:map[i][0]];
    }

    return self;
}

// - (CPString)remotePath  //Ratatosk
// {
//     if ([self pk])
//         return [self pk];
//     else
//         return @"/classifiers/";
// }


@end


