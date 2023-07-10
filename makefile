clean:
	find examples -mindepth 1 -maxdepth 1 -type d -exec make -C {} clean \;
