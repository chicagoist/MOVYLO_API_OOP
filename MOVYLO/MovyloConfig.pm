package MOVYLO::MovyloConfig {
    use v5.10;
    use FindBin qw($Bin);
    use lib "$Bin"; # в подкаталоге
    our $VERSION = '0.03';
    use POSIX qw(strftime);
    use File::Basename qw(dirname);
    use utf8::all 'GLOBAL';
    use strict;
    use warnings FATAL => 'all';
    use utf8;
    binmode(STDIN, ':utf8');
    binmode(STDOUT, ':utf8');
    use Data::Dumper;
    use DDP;

    use Moose;
    use Moose::Util::TypeConstraints;
    use namespace::autoclean;

    has 'LOG_FILE' => (
        is      => 'ro',
        default => sub {dirname(__FILE__) . "/LOGS/API_connect_" . strftime("%Y-%m-%d", localtime()) . ".log";},
    );

    has 'SERVER_API_AUTH' => (
        is      => 'ro',
        writer => '_private_set_server_api_auth',
        default => sub {'https://api.sandbox.movylo.com/v3/Authentication/';},
    );

    has 'SERVER_API_MERCH' => (
        is      => 'ro',
        writer => '_private_set_server_api_merch',
        default => sub {'https://api.sandbox.movylo.com/v3/Merchant/';},
    );

    has 'SERVER_API_STORE' => (
        is      => 'ro',
        writer => '_private_set_server_api_store',
        default => sub {'https://api.sandbox.movylo.com/v3/Store/';},
    );

    has 'CONTENT_TYPE' => (
        is      => 'ro',
        default => sub {'application/x-www-form-urlencoded; charset=UTF-8';},
    );

    has 'DSN' => (
        is      => 'ro',
        writer => '_private_set_dbi_mysql',
        default => sub {'DBI:mysql:movyloDB';},
    );

    has 'USERNAME_DB' => (
        is      => 'ro',
        writer => '_private_set_username_db',
        default => sub {'user';},
    );

    has 'PASSWORD_DB' => (
        is      => 'ro',
        writer => '_private_set_password_db',
        default => sub {'заглушка';},
    );

    has 'EMAIL_MERCH' => (
        is      => 'ro',
        writer => '_private_set_email_merch',
        default => sub {'емайл'},
    );

    has 'PARTNER_CODE' => (
        is      => 'ro',
        writer => '_private_set_partner_code',
        default => sub {'заглушка'},
    );
    has 'STORE_ID' => (
        is      => 'ro',
        writer => '_private_set_store_id',
    );

    has 'ACCOUNT_ID_POST' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'USERNAME_MERCH' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'PASSWORD_MERCH' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'FIRST_NAME' => (
        is      => 'rw',
        default => sub {'FirstName';},
    );

    has 'LAST_NAME' => (
        is      => 'rw',
        default => sub {'LastName';},
    );

    has 'VAT_NUMBER' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'ADDRESS' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'CITY' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'STATE' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'ZIP' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'COUNTRY' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'EXTERNAL_ACCOUNT_ID' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'DEVICE_ID' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'BUSINESS_NAME' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'PHONE' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'FISCAL_CODE' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'DEVICE_TOKEN' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'DEVICE_PLATFORM' => (
        is      => 'rw',
        default => sub {'';},
    );

    has 'AUTH_CONTENT' => (
        is      => 'ro',
        writer => '_private_set_auth_content',
        default => sub {
            {
                match         => "www",
                errors        => 0,
                client_id     => "deluxe-movylo-api",
                client_secret => "секрет",
                partner_code  => "партнёрский_код",
                grant_type    => "client_credentials"
            }
        },
    );




    sub test {
        my $self = shift;
        $self->LOG_FILE;
    }



    __PACKAGE__->meta->make_immutable;
}
1;