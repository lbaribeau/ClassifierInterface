from lxml import etree
tree=etree.parse("salzinnes_demo_classifier.xml")
dir(parser)
dir(tree)
tree.find
tree.find()
dir(tree.find)
tree.find("glyph")
tree.find("glyph")
tree.find("glyph")
tree.find("glyph")
tree.find("glyph")
dir(tree)
etree.tostring(tree.getroot())
tree.getroot()
dir(tree)
tree=etree.parse("salzinnes_demo_classifier.xml")
i=0
for event, element in etree.iterparse("salzinnes_demo_classifier.xml"):
	print("%s, %4s, %s" % (event, element.tag, element.text))
	i=i+1
	if(i==10):
		break
for event, element in etree.iterparse("salzinnes_demo_classifier.xml"):
	if(element.tag == "data"):
		runlength_encode=element.text
		break
print runlength_encode
history
