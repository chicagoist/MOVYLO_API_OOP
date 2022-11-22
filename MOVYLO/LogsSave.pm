package MOVYLO::LogsSave {
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

    # use Moose;
    use Moose::Role;
    use Moose::Util::TypeConstraints;
    use namespace::autoclean;


    requires qw(getToken);

    sub saveLogs {
        my $self = shift;
        # Log files in dir LOGS
        my $log = MOVYLO::MOVYLO->new();

        unless (-d dirname(__FILE__) . "/LOGS") {
            mkdir dirname(__FILE__) . "/LOGS";
        }

        my ($str) = "[ " . strftime("%H:%M:%S", localtime()) . " ] @_\n";
        my ($fh);
        open($fh, ">>", $log->LOG_FILE) || die("Could not open " . $log->LOG_FILE);
        print($fh $str);
        close($fh);

        undef $log;

        return 1;
    }


    # __PACKAGE__->meta->make_immutable;
}
1;