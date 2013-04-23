
from django.db import models
from uuidfield import UUIDField

import os
from django.conf import settings

from lxml import etree
import re
import png
import StringIO
import base64


#class Glyph(object):
#    """ A database-less model class for glyphs """
#    def __init__(self, **kwargs):
#        self.__dict__.update(kwargs)
# output_glyph = Glyph(**glyph_dict)


class Classifier(models.Model):
    uuid = UUIDField(primary_key=True, auto=True)
    name = models.CharField(max_length=255)
    # add "created"?
    # add "updated"?

    class Meta:
        app_label = "ClassifierInterface"

    def __unicode__(self):
        return u"classifier" + str(self.uuid)

    @property
    def classifier_path(self):
        # TODO: change this when integrating to rodan
        return os.path.join(settings.MEDIA_ROOT, "projects/1/classifiers", "{0}.xml".format(str(self.uuid)))

    @property
    def glyphs(self):
        """ Makes a dictionary out of the gamera XML and returns it.
        See the footnote for the dictionary's structure.
        With one exception, all of the values of the dictionary are strings
        right from the XML.  The exception is the 'data' field which is
        converted from Gamera's runlength encoding to PNG."""

        parser = etree.XMLParser(resolve_entities=True)
        classifier = etree.parse(open(self.classifier_path, 'r'), parser)
        glyphs = []

        for glyph in classifier.xpath("//glyph"):
            # Should I type these?
            # Keep them as strings, they'll just need to be
            # displayed anyway.

            # TODO: This only works if all of the fields are in the
            # XML.  Add support for missing fields
            #  (features or id element)
            ids = glyph.find('ids')
            id_element = ids.find('id')
            features = glyph.find('features')  # 'features' element
            feature_list = features.getchildren()  # list of 'feature' elements
            # or features.xpath("feature")
            glyph_dict = {
                'ulx': glyph.get('ulx'),
                'uly': glyph.get('uly'),
                'nrows': glyph.get('nrows'),
                'ncols': glyph.get('ncols'),
                # 'ids': {
                #     'state': ids.get('state'),
                #     'id': {
                #         'name': id_element.get('name'),
                #         'confidence': id_element.get('confidence')
                #     }
                # },
                'id_state': ids.get('state'),
                'id_name': id_element.get('name'),
                'id_confidence': id_element.get('confidence'),
                'data': self._base64_encode(glyph),
                'feature_scaling': features.get('scaling'),
                'features': [{
                    'name': f.get('name'),
                    'values': f.text.split()
                } for f in feature_list]
            }
            #glyph_dict = glyph.attrib
            glyphs.append(glyph_dict)
        return glyphs

    def _base64_encode(self, glyph):
        """ Takes an xpath glyph element and returns a png image of the
        glyph. """
        nrows = int(glyph.get('nrows'))
        ncols = int(glyph.get('ncols'))
        # Make an iterable that yields each row in boxed row flat pixel format:
        #   http://pypng.googlecode.com/svn/trunk/code/png.py
        # Method: Make a list of length nrows * ncols then after make sublists of
        # length ncols.
        pixels = []
        white_or_black = True
        for n in re.findall("\d+", glyph.find('data').text):
            pixels.extend([255 * white_or_black] * int(n))
            white_or_black = not(white_or_black)
        png_writer = png.Writer(width=ncols, height=nrows, greyscale=True)
        pixels_2D = []
        for i in xrange(nrows):
            pixels_2D.append(pixels[i*ncols: (i+1)*ncols])  # Index one row of pixels
        # StringIO.StringIO lets you write to strings as files: it gives you a file descriptor.
        # (pypng expects a file descriptor)
        buf = StringIO.StringIO()
        png_writer.write(buf, pixels_2D)
        my_png = buf.getvalue()
        return base64.b64encode(my_png)


### GAMERA XML AS A DICTIONARY ###
# Glyph Object
#{
#    'ulx':
#    'uly':
#    'nrows':
#    'ncols':
#    'ids': {
#            'state':
#             'id': { 'name': 'confidence': }
#            }
#    'data': base64 encoded PNG
#    'feature_scaling':
#    'features': [
#                    {'name': name 'values': [split of text values]}
#                    ...
#                ]
#}

### IDS ###
# ids has a state and an id
# id has a name and a confidence
# I'm pretty sure you can only have one id in an ids thing.
# So why not change it to a single element?
# id: {'state': 'name': 'confidence'}
# Even better: Just fan it back into the glyph object

#{
#    'ulx':
#    'uly':
#    'nrows':
#    'ncols':
#    'id_state':
#    'id_name':
#    'id_confidence':
#    'data': base64 encoded PNG
#    'feature_scaling':
#    'features': [
#                    {'name': name 'values': [split of text values]}
#                    ...
#                ]
#}

# Do I need to write an XML schema and run it against a lot of gamera
# XML to ensure that it all follows my assumptions, especially
#  <ids> only has one <id> child
# I can't imagine a glyph having two states and names and
# confidences... so I don't need to.

# States can be
#  MANUAL AUTOMATIC HEURISTIC UNCLASSIFIED
# Example of unclassified:
#    <glyph uly="628" ulx="783" nrows="5" ncols="15">
#      <ids state="UNCLASSIFIED">
#      </ids>
#      <data>
#        1 13 1 45 1 13 1 0
#      </data>
#    </glyph>
# So, the schema might say
# - Required: ulx, uly, nrows, ncols, ids, data
# - ids is necessary but id is not if ids is UNCLASSIFIED
# - features are optional (along with feature_scaling)


# Glyph Object

### SYMBOLS ###
# There should also be a Symbol object
#<gamera-database version="2.0">
#  <symbols>
#    <symbol name="_group"/>
#    <symbol name="_group._part"/>
#    <symbol name="_group._part.clef.c"/>
#    <symbol name="_group._part.division.final"/>
# It's just a list of names.  Very simple.
# The symbols get saved when you save page glyphs.
# It can honesly just be a 1d array of strings.








