Summary: perl-Pylon.
Name: perl-Pylon
Version: 0.0.0
Release: 1
Epoch: 0
License: GPL
URL: http://www.minorimpact.com/pylon
Group: Applications/System
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-root
BuildArch: noarch

#Requires: 

Provides: perl(Pylon)

%description
perl-Pylon.

%prep
%setup

%build

%install
rm -rf $RPM_BUILD_ROOT

mkdir -p ${RPM_BUILD_ROOT}
cp -r ${RPM_BUILD_DIR}/%{name}-%{version}/* ${RPM_BUILD_ROOT}/

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/*

# Changelog - update this with every build of the package
%changelog
* Wed Dec 17 2014 <pgilan@minorimpact.com> 0.0.1-1
- Initial build.
