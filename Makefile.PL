use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "\nChecking libapreq dependencies...\n";
eval {
    require Apache::Request;
    require Apache::Cookie;
};
if ($@) {
  print "\n\tWhoops!  You must install libapreq for Apache::RequestNotes to work.
\tPlease see the README for module and hook dependencies.\n\n";
} else {
  print "\nApache::Request and Apache::Cookie found.  Good...
Please see the README for mod_perl hook dependencies.\n\n";
}

WriteMakefile(
    'NAME'	=> 'Apache::RequestNotes',
    'VERSION_FROM' => 'RequestNotes.pm', # finds $VERSION
);
