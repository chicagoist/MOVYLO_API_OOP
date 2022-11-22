package MOVYLO::MerchCreat {
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

    requires qw(getToken);


    sub createMerchant {
        # createMerchant
        my $self = shift;
        # Call this API to obtain the 'account_id' that you need for the 'create store' API or to update
        # an existing merchant account
        my $create_merch = MOVYLO::MOVYLO->new();

        use HTTP::Request::Common;
        my $token = $create_merch->getToken();

        my %respond_merch;
        my %respond_content_merch = (deleted => "false"); # for next sub &merchant_delete_DEL;
        my %content_hash = (
            external_account_id => "",
            zip                 => "",
            partner_code        => $create_merch->PARTNER_CODE,
            device_id           => $create_merch->DEVICE_ID,
            business_name       => $create_merch->BUSINESS_NAME,
            city                => $create_merch->CITY,
            account_id          => $create_merch->ACCOUNT_ID_POST,
            phone               => $create_merch->PHONE,
            fiscal_code         => $create_merch->FISCAL_CODE,
            device_token        => $create_merch->DEVICE_TOKEN,
            state               => $create_merch->STATE,
            last_name           => $create_merch->LAST_NAME,
            first_name          => $create_merch->FIRST_NAME,
            address             => $create_merch->ADDRESS,
            username            => $create_merch->USERNAME_MERCH,
            country             => $create_merch->COUNTRY,
            password            => $create_merch->PASSWORD_MERCH,
            email               => $create_merch->EMAIL_MERCH,
            device_platform     => $create_merch->DEVICE_PLATFORM,
            vat_number          => $create_merch->VAT_NUMBER,
            zip                 => $create_merch->ZIP
        );

        my $dbh_merchant = $create_merch->dbh_connect(); # access to DB

        my @ddl_merchant = (
            # create table merchant
            "CREATE TABLE merchant (
    	  merch_id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    	  account_id varchar(255) NOT NULL,
    	  email varchar(255) NOT NULL,
    	  phone varchar(255),
    	  username varchar(255),
    	  password varchar(255),
    	  first_name varchar(255),
    	  last_name varchar(255),
    	  business_name varchar(255),
    	  vat_number varchar(255),
    	  fiscal_code varchar(255),
    	  address varchar(255),
    	  city varchar(255),
    	  state varchar(255),
    	  zip varchar(255),
    	  country varchar(255),
    	  device_id varchar(255),
    	  device_token varchar(255),
    	  device_platform varchar(255),
    	  external_account_id varchar(255),
    	  partner_code varchar(255) NOT NULL,
    	  deleted varchar(255),
    	  creation_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    	) ENGINE=InnoDB;"
        );

        my $sql_merchant = "SHOW TABLES LIKE 'merchant'";
        my $sth_merchant = $dbh_merchant->prepare($sql_merchant);
        # create a new table at DB if not exists
        if ($sth_merchant->execute() != 1) {
            # execute all create table statements
            foreach my $table (@ddl_merchant) {
                $dbh_merchant->do($table);
            }
            #print "Access to DB OK Merch! \n";
            $create_merch->save_log("Table 'merchant' was created in DB! :" . __FILE__ . "\tline :" . __LINE__);
        } else {
            # warn "Table already exist in DB!";
            $create_merch->save_log("Table 'merchant' already exist in DB! at : " . __FILE__ . "\tline :" . __LINE__);
        }
        $sth_merchant->finish();

        my $update_auth_content = sub {
            my $temp_value;
            my $answer;
            say "\nCreate a merchant/account";

            foreach my $key (sort keys %content_hash) {
                unless ($key =~ /^partner_code|^password|^account_id/) # default values
                {

                    say "\n$key => $content_hash{$key}";
                    print "change or new value for the $key ? [Y/n] ";
                    $answer = <>;

                    if ($answer =~ /^n/i) {
                        next;
                    }
                    if ($answer =~ /^y/i or $answer =~ /!^$/) {
                        print "Enter new value for the $key :";
                        $temp_value = <>;
                        chomp($temp_value);
                        unless ($temp_value =~ /^$/) {
                            if ($key =~ /^state|^country/) {
                                $content_hash{$key} = uc($temp_value);
                            } else {
                                $content_hash{$key} = $temp_value;
                            }
                        } else {
                            next;
                        }
                    } else {
                        next;
                    }
                }
            }

            # {# uncomment for debug only
            #     foreach (sort keys %content_hash)
            #     {
            #         say "$_ => ", $content_hash{$_};
            #     }
            # }

        };
        &{$update_auth_content}; # for manual change values

        # prepare for POST request
        my $ua_merch = LWP::UserAgent->new;
        my $req_merch = POST $create_merch->SERVER_API_MERCH,
            Authorization => 'Bearer ' . $token, # token == access_token from getToken()
            Content_Type  => $create_merch->CONTENT_TYPE,
            Content       => [ %content_hash ];

        # POST request to Merchant API
        %respond_merch = %{$ua_merch->request($req_merch)};

        # { # uncomment for debug only
        #     use DDP;
        #     say "\n\$respond_merch{_content}:";
        #     p $respond_merch{_content};
        # }

        # if respond 201 - OK
        if ($respond_merch{_rc} == 201) {
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
                $respond_content_merch{$1} = $2; # 'get in output code hash: account_id = 668, email = mail366@365.com, last_name = LastName'
            } split /,/, $respond_merch{_content}; # raw code from response: {"account_id":"668","username":"mail366@365.com","email":"mail366@365.com","last_name":"LastName","partner_code":"deluxe_p1va"}
        } else {
            $create_merch->save_log("Failed to create an account! $respond_merch{_content}" . __FILE__ . "\tline :" . __LINE__);
            warn "Failed to create an account! Read log file at $respond_merch{_content} : ", $create_merch->LOG_FILE;
        }

        { # uncomment for debug only
            foreach (sort keys %respond_content_merch) {
                print "$_ => $respond_content_merch{$_}\n";
            }
        }


        my $sql_insert_to_account_id = "INSERT INTO merchant(
account_id,
email,
phone,
username,
first_name,
last_name,
business_name,
vat_number,
fiscal_code,
address,
city,
state,
zip,
country,
device_id,
device_token,
device_platform,
external_account_id,
partner_code,
deleted)
    VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        my $stmt_to_account_id = $dbh_merchant->prepare($sql_insert_to_account_id);

        if ($stmt_to_account_id->execute(
            $respond_content_merch{account_id},
            $respond_content_merch{email},
            $respond_content_merch{phone},
            $respond_content_merch{username},
            $respond_content_merch{first_name},
            $respond_content_merch{last_name},
            $respond_content_merch{business_name},
            $respond_content_merch{vat_number},
            $respond_content_merch{fiscal_code},
            $respond_content_merch{address},
            $respond_content_merch{city},
            $respond_content_merch{state},
            $respond_content_merch{zip},
            $respond_content_merch{country},
            $respond_content_merch{device_id},
            $respond_content_merch{device_token},
            $respond_content_merch{device_platform},
            $respond_content_merch{external_account_id},
            $respond_content_merch{partner_code},
            $respond_content_merch{deleted}

        )
        ) {
            $create_merch->save_log("Merchant's data inserted successfully to table! :" . __FILE__ . "\tline :" . __LINE__);
            1;
        } else {
            $create_merch->save_log("Merchant's data wasn't inserted to table!!! :" . __FILE__ . "\tline :" . __LINE__);
            warn "Merchant's data wasn't inserted to table!!!", $create_merch->LOG_FILE;
            1;
        }
        $stmt_to_account_id->finish();

        # disconnect from the MySQL database
        $dbh_merchant->disconnect();

        undef $create_merch;
        undef $dbh_merchant;
        undef $create_merch;

    }



   # __PACKAGE__->meta->make_immutable;
}
1;