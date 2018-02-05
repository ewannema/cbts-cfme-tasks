VERSION := 1.2.0
RELEASE := 1
NAME := cbts-cfme-tasks

.PHONY: clean rpm

SOURCEDIR := $(shell rpmbuild -E %{_sourcedir})
TARBALL := $(SOURCEDIR)/$(NAME)-$(VERSION)-$(RELEASE).tgz

rpm:
	rm -rf $(NAME) && \
	mkdir -p $(NAME) && \
	cp *.rake $(NAME) && \
	mkdir -p $(SOURCEDIR) && \
	tar zcf "$(TARBALL)" $(NAME) && \
	rm -rf $(NAME) && \
	rpmbuild -bb --define "_rpmdir $(shell pwd)/rpm" $(NAME).spec

clean:
	rm -rf $(NAME)
	rm -f "$(TARBALL)"
