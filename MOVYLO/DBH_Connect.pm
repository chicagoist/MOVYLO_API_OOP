package MOVYLO::DBH_Connect {
    use v5.10;
    use FindBin qw($Bin);
    use lib "$Bin"; # в подкаталоге
    our $VERSION = '0.01';
    use POSIX qw(strftime);
    use File::Basename qw(dirname);
    use DBI;
    use LWP::UserAgent;
    use HTTP::Request;
    # use CGI;
    # use POSIX;
    # use Encode qw(decode_utf8);
    # use Encode qw(decode encode);
    #= BEGIN{@ARGV=map Encode::decode(#\$_,1),@ARGV;}
    # BEGIN{@ARGV = map decode_utf8(#\$_, 1), @ARGV;}
    # use open qw(:std :encoding(UTF-8));
    use utf8::all 'GLOBAL';
    # use Encode::Locale;
    # use Encode;
    # use diagnostics;
    use strict;
    use warnings FATAL => 'all';
    use autodie qw(:all);
    use utf8;
    binmode(STDIN, ':utf8');
    binmode(STDOUT, ':utf8');
    use Data::Dumper;
    use Bundle::Camelcade; # for Intellij IDEA
    use YAML;
    use DDP;

    #use Moose;
    use Moose::Role;
    use Moose::Util::TypeConstraints;
    use namespace::autoclean;

    #requires qw(authentication);


    sub dbh_connect {
        my $dbh_obj = MOVYLO::MOVYLO->new();
        my %attr = (
            PrintError => 0, # turn off error reporting via warn()
            RaiseError => 1, # turn on error reporting via die()
            AutoCommit => 1); # transaction enabled
        DBI->connect($dbh_obj->DSN, $dbh_obj->USERNAME_DB, $dbh_obj->PASSWORD_DB, \%attr) or
            die("Error connecting to the database: $DBI::errstr\n");
    }



   # __PACKAGE__->meta->make_immutable;
}
1;