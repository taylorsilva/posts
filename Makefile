
# **Requires ImageMagick to be installed**
# Will generate all gifs for the blog post
# Blog post folder must have a diagrams folder that contain a folder for each
# image
%.gifs:
	for dir in ./$*/diagrams/*/ ; do \
		dir=$${dir%*/} ; \
		name=$$(basename $$dir) ; \
		convert -delay 375 $$dir/*.png ./$$dir/$$name.gif ; \
	done
