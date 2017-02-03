VERSION := 1.0.0
RELEASE := 2
NAME := cbts-cfme-tasks

.PHONY: clean rpm

TARBALL := $(shell rpmbuild -E %{_sourcedir})/$(NAME)-$(VERSION)-$(RELEASE).tgz

rpm:
	rm -rf $(NAME) && \
	mkdir -p $(NAME) && \
	cp *.rake $(NAME) && \
	tar zcf "$(TARBALL)" $(NAME) && \
	rm -rf $(NAME) && \
	rpmbuild -bb --define "_rpmdir $(shell pwd)/rpm" $(NAME).spec

clean:
	rm -rf $(NAME)
	rm -f "$(TARBALL)"
