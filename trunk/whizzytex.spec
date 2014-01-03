Summary: 	Emacs minor mode for incremental viewing of LaTeX documents.
Name: 		whizzytex
Version: 	1.3.3
Release: 	1
License: 	GPL
Group: 		Applications/Editors
#Group:		Applications/Editors/Emacs
#Group:		Applications/Publishing
Vendor: 	INRIA <whizzytex-bugs@inria.fr>
#Vendor: 	Didier R�my <whizzytex-bugs@inria.fr>
Packager: 	Jakub Narebski <jnareb@fuw.edu.pl>
URL: 		http://gallium.inria.fr/%{name}/%{name}-%{version}.tgz
Source: 	%{name}-%{version}.tgz
Patch: 		%{name}-makefile.patch
Requires: 	emacs bash tetex-latex
Prereq: 	/sbin/install-info
BuildRequires: 	emacs bash sed tetex-latex
BuildArch: 	noarch
BuildRoot: 	%{_tmppath}/%{name}-%{version}-buildroot
Prefix: 	%{_prefix}


%description 
WhizzyTeX provides a minor mode for Emacs and XEmacs, a (bash)
shell-script daemon and some LaTeX macros. It works under Unix with gv
and xdvi viewers, but the Active-DVI viewer will provided much better
visual effects and will offer more functionalities.

%if %{?_without_multiple:1}%{?!_without_multiple:0}
This package was compiled with assumption that advi-like previewer
cannot view multiple files
%endif


#
# PREPARE
#
%prep
%setup -q
%patch -p1


#
# BUILD
#
%build
./configure \
  -prefix  %{_prefix} \
  -libdir  %{_libdir}/%{name} \
  -datadir %{_datadir}/%{name} \
  -emacsdir  %{_datadir}/emacs/site-lisp \
  -xemacsdir %{_datadir}/xemacs/site-packages/lisp \
  %{?_without_multiple:-multiple false} \
  -elc
make all

echo -e   \
  ";; \n" \
  ";; %{name}-init.el\n" \
  ";; \n" \
  ";; Created for %{name}-%{version}-%{release}.noarch.rpm \n" \
  "(autoload 'whizzytex-mode\n" \
  "    \"whizzytex\"\n" \
  "    \"WhizzyTeX, a minor-mode WYSIWIG environment for LaTeX\" t)\n" \
  >> tmp/emacs/%{name}-init.el
cp tmp/emacs/%{name}-init.el tmp/xemacs/%{name}-init.el


#
# INSTALL
#
%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
mkdir -p "$RPM_BUILD_ROOT"
make DESTDIR="$RPM_BUILD_ROOT" install

## info files
#[ -e doc/whizzytex.info ] && gzip -9Nf doc/whizzytex.info
#install -d "$RPM_BUILD_ROOT"%{_infodir}
#install -m 644 -p doc/whizzytex.info.gz "$RPM_BUILD_ROOT"%{_infodir}

## autoload
install -m 644 -D tmp/emacs/%{name}-init.el \
  "$RPM_BUILD_ROOT"%{_datadir}/emacs/site-lisp/site-start.d/%{name}-init.el
install -m 644 -D tmp/xemacs/%{name}-init.el \
  "$RPM_BUILD_ROOT"%{_datadir}/xemacs/site-packages/lisp/site-start.d/%{name}-init.el

## docs will be generated by RPM files section, with version number
rm -rf "$RPM_BUILD_ROOT"%{_docdir}/%{name}/


#
# CLEAN
#
%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


#
# SCRIPTS
#
# after install
#%\post
#/sbin/install-info --info-dir=%{_infodir} %{_infodir}/%{name}.info.gz \
#  --section="GNU Emacs" 2> /dev/null || :

# before uninstall
#%\preun
## $1 is the number of versions of this package installed
## after this uninstallation
#if [ $1 -eq 0 ]; then
#  /sbin/install-info --delete --info-dir=%{_infodir} \
#    %{_infodir}/%{name}.info.gz 2> /dev/null || :
#fi


#
# FILES
#
%files
%defattr(-,root,root,-)
%doc COPYING GPL INSTALL doc/whizzytex.html
%{_bindir}/*
%{_datadir}/whizzytex
%{_datadir}/emacs/site-lisp/%{name}.el*
%{_datadir}/emacs/site-lisp/site-start.d/%{name}-init.el
%{_datadir}/xemacs/site-packages/lisp/%{name}.el*
%{_datadir}/xemacs/site-packages/lisp/site-start.d/%{name}-init.el
#%{_infodir}/*


#
# CHANGELOG
#
%changelog
* Mon Mar 22 2004 Jakub Nar�bski <jnareb@fuw.edu.pl> 1.1.3-1jn
- First build

* Thu Oct 30 2003 Jakub Nar�bski <jnareb@fuw.edu.pl> 
- Initial build.


