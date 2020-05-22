
%.gif:
	for dir in ./$*/diagrams/*/ ; do \
		dir=$${dir%*/} ; \
		convert -delay 375 ./$$dir/*.png ./$$dir/example-one.gif ; \
	done
	# convert -delay 375 ./tasks-inputs-101/diagrams/example-one/*.png ./tasks-inputs-101/diagrams/example-one/example-one.gif
