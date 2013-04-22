
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
            # Where do I do the typing... client side.
            # Who knows whether the types will even make it across.
            # Best keep them as strings.
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
                'ids': {
                    'state': ids.get('state'),
                    'id': {
                        'name': id_element.get('name'),
                        'confidence': id_element.get('confidence')
                    }
                },
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

#        UPLOADS = "/Users/lbaribeau/ClassifierInterface/uploads/"
        # Make a png from the xml file.
        # Server side path to xml file:
        # This won't be in home... it'll be at /classifier/[UUID]$
#        encoded_glyphs = []
#        for event, element in etree.iterparse(UPLOADS + "projects/1/classifiers/" + str(id) + "/" + str(id) + ".xml"):
#            if (element.tag == "data"):  # Maybe a better way in lxml to get to the data element
#                ncols = int(element.getparent().get("ncols"))
#                nrows = int(element.getparent().get("nrows"))
#                # Make an iterable that yields each row in boxed row flat pixel format.*
#                # *http://pypng.googlecode.com/svn/trunk/code/png.py
#                # Plan: make a list of length nrows * ncols * 3 then make sublists of length ncols * 3.
#                # The *3 is for RGB: (0,0,0) is black and (255,255,255) is white
#                pixels = []
#                white_or_black = True
#                for n in re.findall("\d+", element.text):
#                    pixels.extend([255 * white_or_black] * int(n))
#                    white_or_black = not(white_or_black)
#                png_writer = png.Writer(width=ncols, height=nrows, greyscale=True)
#                pixels_2D = []
#                for i in xrange(nrows):
#                    pixels_2D.append(pixels[i*ncols: (i+1)*ncols])  # Index one row of pixels
#                # StringIO.StringIO lets you write to strings as files: it gives you a file descriptor.
#                # (pypng expects a file descriptor)
#                buf = StringIO.StringIO()
#                #image = png.from_array(pixels_2D,mode='L')
#                #image.save(buf) # Hopefully this doesn't write to a file
#                png_writer.write(buf, pixels_2D)
#                my_png = buf.getvalue()
#                encoded_png = base64.b64encode(my_png)  # not sure why
#                encoded_glyphs.append(encoded_png)
#        return encoded_glyphs







