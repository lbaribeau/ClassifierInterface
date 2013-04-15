
from django.db import models
from uuidfield import UUIDField


class Classifier(models.Model):
    uuid = UUIDField(primary_key=True, auto=True)
    name = models.CharField(max_length=255)
    # add "created"?
    # add "updated"?

    def __unicode__(self):
        return u"classifier" + str(self.uuid)


class Project(models.Model):
    # Rodan project.  Stub.
    classifiers = models.ManyToManyField(Classifier, related_name="classifiers", blank=True)
    pass
