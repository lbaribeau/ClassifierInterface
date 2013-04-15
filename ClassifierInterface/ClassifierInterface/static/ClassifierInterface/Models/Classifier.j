
@implementation Classifier : WLRemoteObject
{
    CPString    pk          @accessors;
    CPString    name        @accessors;
    CPData      glyphPng    @accessors;
}
+ (CPArray)remoteProperties  //Ratatosk
{
    return [
        ['pk',          'url'],
        ['name',        'name',         nil, nil],
            // Will add name once serializer is working
            // Server side: implement Classifier model with a glyph_png function
            // that returns the png.  (This means that the xml file isn't an
            // argument... we'll see how that shapes together.)
        //['glyphPng',    'glyph_png',    [[PngTransformer alloc] init], true],
    ];
}
- (CPString)remotePath  //Ratatosk
{
    if ([self pk])
        return [self pk];
    else
        return @"/classifiers/";
}
@end
