package Apache::RequestNotes;

#---------------------------------------------------------------------
#
# usage: PerlInitHandler Apache::RequestNotes
#        PerlSetVar  MaxPostSize 1024         # size in K that is
#                                               allowed to be POSTed
#
#---------------------------------------------------------------------

use 5.004;
use mod_perl 1.21;
use Apache::Constants qw( OK );
use Apache::Cookie;
use Apache::Log;
use Apache::Request;
use strict;

$Apache::RequestNotes::VERSION = '0.02';

# set debug level
#  0 - messages at info or debug log levels
#  1 - verbose output at info or debug log levels
$Apache::RequestNotes::DEBUG = 1;

sub handler {
#---------------------------------------------------------------------
# initialize request object and variables
#---------------------------------------------------------------------
  
  my $r               = shift;
  my $log             = $r->server->log;

  my $maxsize         = $r->dir_config('MaxPostSize') || 1024;

  my %cookies;        # hash for cookie names and values

#---------------------------------------------------------------------
# do some preliminary stuff...
#---------------------------------------------------------------------

  $log->info("Using Apache::RequestNotes");

#---------------------------------------------------------------------
# parse the form data
#---------------------------------------------------------------------

  # this routine works for either a get or post request
  my $apr = Apache::Request->new($r, POST_MAX => $maxsize,
                                     DISABLE_UPLOADS => 1);
  my $status = $apr->parse;

  if ($status) {
    # I don't know what to do here, but rather than error out, do
    # something that says there was a parse failure.
    # GET data is still available, but POST looks hosed...

    $Apache::RequestNotes::err = 1;
   
    $log->warn("\tApache::RequestNotes encountered a parsing error!");
    $log->info("Exiting Apache::RequestNotes");
    return OK;
  }

  my $input = $apr->parms;   # this is a hashref tied to Apache::Table

  if ($Apache::RequestNotes::DEBUG) {
    $input->do(sub {
      my ($key, $value) = @_;
      $log->info("\tquery string: name = $key, value = $value");
      1;
    });
  }
  
#---------------------------------------------------------------------
# grab the cookies
#---------------------------------------------------------------------

  my %cookiejar = Apache::Cookie->new($r)->parse;

  foreach (sort keys %cookiejar) {
    my $cookie = $cookiejar{$_};

    $cookies{$cookie->name} = $cookie->value; 

    $log->info("\tcookie: name = " . $cookie->name . 
       ", value = " . $cookie->value) if $Apache::RequestNotes::DEBUG;
  }

#---------------------------------------------------------------------
# put the form and cookie data in a pnote for access by other handlers
#---------------------------------------------------------------------

  $r->pnotes(INPUT => $input);
  $r->pnotes(COOKIES => \%cookies);

#---------------------------------------------------------------------
# wrap up...
#---------------------------------------------------------------------

  $log->info("Exiting Apache::RequestNotes");

  return OK;
}

1;

__END__

=head1 NAME

Apache::RequestNotes - allow easy, consistent access to cookie and 
                       form data across each request phase.

=head1 SYNOPSIS

  httpd.conf:

    PerlInitHandler Apache::RequestNotes
    PerlSetVar MaxPostSize 1024

  MaxUploadSize is in bytes and defaults to 1024, thus is optional.

=head1 DESCRIPTION

  Apache::RequestNotes provides a simple interface allowing all phases
  of the request cycle access to cookie or form input parameters in a 
  consistent manner.

=head1 EXAMPLE

  some Perl*Handler or Registry script:

    my $input      = $r->pnotes('INPUT');
    my $cookies    = $r->pnotes('COOKIES');
   
    # GET and POST data
    my $foo        = $input->get('foo');
 
    # cookie data
    my $bar        = $cookies->{'bar'};      # one way

    my %cookies    = %$cookies if $cookies;  # check, just to be safe
    my $baz        = $cookies{'baz'};        # another way

  httpd.conf:

    PerlInitHandler Apache::RequestNotes


  After using Apache::RequestNotes, $cookies contains a hashref with
  the names and values of all cookies sent back to your domain and
  path.  $input contains a reference to an Apache::Table object and
  can be accessed via Apache::Table methods.  If a form contains
  both GET and POST data, both are available via $input.

  Once the request is past the PerlInit phase, all other phases can
  have access to form input and cookie data without parsing it
  themselves. This relieves some strain, especially when the GET or 
  POST data is required by numerous handlers along the way.

=head1 NOTES

  Apache::RequestNotes does not allow for file uploads. If either a 
  file upload was attempted, or the POST data exceeds MaxPostSize,
  rather than return SERVER_ERROR it sets $Apache::RequestNotes::err.

  Verbose debugging is enabled by setting the variable
  $Apache::RequestNotes::DEBUG=1 to or greater. To turn off all debug
  information, set your apache LogLevel above info level.

  This is alpha software, and as such has not been tested on multiple
  platforms or environments.  It requires PERL_INIT=1, PERL_LOG_API=1, 
  and maybe other hooks to function properly.  Doug MacEachern's 
  libapreq is also required - you can get it from CPAN under the 
  Apache tree.

=head1 FEATURES/BUGS

  No known bugs or unexpected features at this time.

=head1 SEE ALSO

  perl(1), mod_perl(1), Apache(3), libapreq(1), Apache::Table(3)

=head1 AUTHOR

  Geoffrey Young <geoff@cpan.org>

=head1 COPYRIGHT

  Copyright 2000 Geoffrey Young - all rights reserved.

  This library is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
