Name:      cbts-cfme-tasks
Version:   1.2.0
Release:   1
Summary:   ManageIQ/CloudForms helper tasks.

Group:     Applications/System
License:   GPLv3+
URL:       https://github.com/ewannema/%{name}
Source:    %{name}-%{version}-%{release}.tgz

BuildArch: noarch

%description
Rake tasks to help maintain ManageIQ/CloudForms.

%prep
%setup -q -n %{name}

%build

%install
mkdir -p "%{buildroot}/var/www/miq/vmdb/lib/tasks"
cd %{_builddir}/%{name}
install -m 0644 *.rake "%{buildroot}/var/www/miq/vmdb/lib/tasks"

%files
/var/www/miq/vmdb/lib/tasks/cbts-ae_domain-management.rake
/var/www/miq/vmdb/lib/tasks/cbts-ae_domain-migrate.rake
/var/www/miq/vmdb/lib/tasks/cbts-ae_domain-ordering.rake

%post

%changelog
* Thu Sep 08 2016 Eric Wannemacher <eric@wannemacher.us> 0.4-1
- Added rake:cbts:ae_domain:mark_up_to_date

* Fri Jul 22 2016 Eric Wannemacher <eric@wannemacher.us> 0.1-1
- Initial RPM release
