
%.gifs:
	for dir in ./$*/diagrams/*/ ; do \
		dir=$${dir%*/} ; \
		name=$$(basename $$dir) ; \
		convert -delay 375 $$dir/*.png ./$$dir/$$name.gif ; \
	done
	# convert -delay 375 ./tasks-inputs-101/diagrams/example-one/*.png ./tasks-inputs-101/diagrams/example-one/example-one.gif
