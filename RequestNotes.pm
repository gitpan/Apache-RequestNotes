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

$Apache::RequestNotes::VERSION = '0.01';

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

  my %input;          # hash for form input
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
    # I don't know what to do here, but rather than error out, notify
    # everyone there was a parse failure so they can deal with it...

    $r->pnotes(PARSE_ERROR => 1);
   
    $log->warn("\tApache::RequestNotes encountered a parsing error!");
    $log->log("Exiting Apache::RequestNotes");
    return OK;
  }

  my @keys = $apr->param; 
  
  foreach (@keys) {
    $input{$_} = $apr->param($_);

    $log->info("\tquery string: name = $_, value = $input{$_}") 
      if $Apache::RequestNotes::DEBUG;
  }
 
#---------------------------------------------------------------------
# grab the cookies
#---------------------------------------------------------------------

  my %cookiejar = Apache::Cookie->new($r)->parse;

  foreach (sort keys %cookiejar) {
    my $cookie = $cookiejar{$_};

    $cookies{$cookie->name} =  $cookie->value; 

    $log->info("\tcookie: name = " . $cookie->name . 
       ", value = " . $cookie->value) if $Apache::RequestNotes::DEBUG;
  }

#---------------------------------------------------------------------
# put the form and cookie data in a pnote for access by other handlers
#---------------------------------------------------------------------

  $r->pnotes(INPUT => \%input);
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

Apache::RequestNotes - extract cookies and CGI form parameters for 
                       each request.

=head1 SYNOPSIS

  httpd.conf:

    PerlInitHandler Apache::RequestNotes
    PerlSetVar MaxPostSize 1024

  MaxUploadSize is in bytes and defaults to 1024.

=head1 DESCRIPTION

  Apache::RequestNotes provides a simple interface allowing all parts
  of the request cycle access to cookie or CGI input parameters in a 
  consistent manner.

=head1 EXAMPLE

  some Perl*Handler or Registry script:

    my $cookies           = $r->pnotes('COOKIES');
    my %cookies           = %$cookies;
    my $input             = $r->pnotes('INPUT');
    my %input             = %$input;

  httpd.conf:

    PerlInitHandler Apache::RequestNotes
    PerlSetVar MaxUploadSize 1024

  After using Apache::RequestNotes and dereferencing the hashes, 
  %input will contain both GET and POST data, and %cookies will
  contain the names and values of all cookies sent back to your domain
  and path.  Once the request is past the PerlInit phase, all other
  phases can have access to form input and cookie data without parsing
  it themselves. This relieves some strain, especially when the GET or 
  POST data is required by numerous handlers along the way.

=head1 NOTES

  Apache::RequestNotes does not allow for file uploads. If either a 
  file upload was attempted, or the POST data exceeds MaxPostSize,
  rather than barf it sets $r->pnotes('PARSE_ERROR').

  Verbose debugging is enabled by setting the variable
  $Apache::RequestNotes::DEBUG=1 to or greater. To turn off all debug
  information, set your apache LogLevel above info level.

  This is alpha software, and as such has not been tested on multiple
  platforms or environments.  It requires PERL_INIT=1, PERL_LOG_API=1, 
  and maybe other hooks to function properly.  Doug MacEachern's 
  libapreq is also required - you can get it from CPAN under the 
  Apache tree.

=head1 FEATURES/BUGS

  When parsing forms with duplicate keys some data is lost.  

=head1 SEE ALSO

  perl(1), mod_perl(1), Apache(3), libapreq(1)

=head1 AUTHOR

  Geoffrey Young <geoff@cpan.org>

=head1 COPYRIGHT

  Copyright 2000 Geoffrey Young - all rights reserved.

  This library is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
