
from django.db import models
from uuidfield import UUIDField

from lxml import etree
import re
import png
import StringIO
import base64

UPLOADS = "/Users/lbaribeau/ClassifierInterface/uploads/"


class Classifier(models.Model):
    uuid = UUIDField(primary_key=True, auto=True)
    # add "name"?     maybe later
    # add "created"?  find out why other models have created
    # add "updated"?

    def __unicode__(self):
        return "classifier" + self.UUID


class Project(models.Model):
    # Rodan project
    classifiers = models.ManyToManyField(Classifier, related_name="classifiers", blank=True)
    pass



