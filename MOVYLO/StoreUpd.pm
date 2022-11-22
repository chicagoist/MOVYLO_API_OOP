package MOVYLO::StoreUpd {
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


    sub updateStore {
        # updateStore
        my $self = shift;
        # Update the Store info. This updates only the passed parameters, all the parameters not set will be left untouched.

        my $store_update = MOVYLO::MOVYLO->new();
        use HTTP::Request::Common;
        my $token = $store_update->getToken();

        print "\nIn order to make changes to the store you created, need store_id.\n";

        my $temp_value;
        my @store_id;

        print "\nEnter the store_id :";
        $temp_value = <>;
        chomp($temp_value);
        $store_id[0] = $temp_value;


        # prepare for GET request
        my $ua_get_data = LWP::UserAgent->new;
        my $req_created_store = GET 'https://api.sandbox.movylo.com/v3/Store/'.$store_id[0].'/',
            Authorization => 'Bearer '.$token,
            Content_Type  => 'application/x-www-form-urlencoded; charset=UTF-8';

        # GET request to Movylo API
        my %respond_store = %{$ua_get_data->request($req_created_store)};

        #{# debug
        #  use DDP;
        #
        # say "\$respond_store{_content}:";
        # p $respond_store{_content};
        #}

        # if respond 200 - OK
        my %respond_content = ();
        if ($respond_store{_rc} == 200) {
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
                $respond_content{$1} = $2;# 'get in output code hash: store_id = 805, account_id = 800, etc.'
            } split /,/, $respond_store{_content};# raw code from response: {\"store_id\":\"805\",\"account_id\":\"805\",\"store_name\":\"New Update Name\",\"store_name_url\":\"business-updates-two\",\"code\":\"deluxe_p1va\",\"plan_id\":\"601\",\"currency\":\"USD\",\"country\":\"UA\",\"partner_code\":\"deluxe_p1va\",\"creation_date\":\"2022-04-15\",\"expiration_date\":\"2022-11-03\"}
        }
        else {
            $store_update->saveLogs("Failed to get an response from API: $respond_store{_content}".__FILE__."\tline :".__LINE__);
            warn "Failed to get an response from API: $respond_store{_rc} failed: ", $store_update->LOG_FILE;
            exit;
        }

        #### CHANGE THIS BLOCK FOR MANUAL
        my $update_store_content = sub {
            $temp_value = undef;
            my $answer = undef;
            say "\n\tUpdate store's content.";

            foreach my $key_v (sort keys %respond_content) {
                unless ($key_v =~ /^partner_code|^creation_date|^store_id|^account_id|^code/)# default values
                {
                    if (defined $respond_content{$key_v}) {
                        say "\n$key_v => $respond_content{$key_v}";
                    }
                    print "change or new value for the $key_v ? [Y/n] ";
                    $answer = <>;

                    if ($answer =~ /^n/i) {
                        next;
                    }
                    if ($answer =~ /^y/i or $answer =~ /!^$/) {
                        print "Enter new value for the :";
                        $temp_value = <>;
                        chomp($temp_value);
                        unless ($temp_value =~ /^$/) {
                            if ($key_v =~ /^country|^currency/) {
                                $respond_content{$key_v} = uc($temp_value);
                            }
                            else {
                                $respond_content{$key_v} = $temp_value;
                            }
                        }
                        else {
                            next;
                        }
                    }
                    else {
                        next;
                    }
                }
            }

            # {# debug
            #     foreach (sort keys %respond_content)
            #     {
            #         say "$_ => ", $respond_content{$_};
            #     }
            # }

        };
        &{$update_store_content};

        #say "\$respond_content{store_id}:";
        # p $respond_content{store_id};

        # prepare for PUT request
        my $ua_update_store = LWP::UserAgent->new;
        my $req_update_store = PUT 'https://api.sandbox.movylo.com/v3/Store/'.$respond_content{store_id}.'/',
            Authorization => 'Bearer '.$token,
            Content_Type  => 'application/x-www-form-urlencoded; charset=UTF-8',
            Content       => [\%respond_content];

        # PUT request to Movylo API
        my %respond_updated_store = %{$ua_update_store->request($req_update_store)};

        # if respond 200 - OK
        if ($respond_updated_store{_rc} == 200) {
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
                $respond_content{$1} = $2;# 'get in output code hash: store_id = 805, account_id = 800, etc.'
            } split /,/, $respond_updated_store{_content};# raw code from response: {\"store_id\":\"805\",\"account_id\":\"805\",\"store_name\":\"New Update Name\",\"store_name_url\":\"business-updates-two\",\"code\":\"deluxe_p1va\",\"plan_id\":\"601\",\"currency\":\"USD\",\"country\":\"UA\",\"partner_code\":\"deluxe_p1va\",\"creation_date\":\"2022-04-15\",\"expiration_date\":\"2022-11-03\"}
        }
        else {
            $store_update->saveLogs("Failed to get an response from API: $respond_updated_store{_content}".__FILE__."\tline :".__LINE__);
            warn "Failed to get an response from API: $respond_updated_store{_rc} failed: ", $store_update->LOG_FILE;
            exit;
        }

        {
            # debug
            use DDP;
            # say "\$respond_updated_store{_rc}:";# debug
            # p $respond_updated_store{_rc};
            say "\%respond_content:";# debug
            p % respond_content;
        }

        # my ($dsn, $username_db, $password_db) = (DSN, USERNAME_DB, PASSWORD_DB);
        # my %attr = (
        #     PrintError => 0,# turn off error reporting via warn()
        #     RaiseError => 1,# turn on error reporting via die()
        #     AutoCommit => 1);# transaction enabled
        # my $dbh = DBI->connect(${$dsn}, ${$username_db}, ${$password_db}, \%attr) or
        #     die("Error connecting to the database: $DBI::errstr\n");

        my $dbh = $store_update->dbh_connect(); # access to DB

        if ($respond_updated_store{_rc} == 200) {

            my $if_exist_store_id = "SELECT store_id FROM created_store WHERE store_id LIKE $respond_content{store_id}";
            my $sth_check_store_id = $dbh->prepare($if_exist_store_id);
            # check a store_id at DB if exists if not - insert to table
            if ($sth_check_store_id->execute() != 1) {
                #say "store_id NOT in table!";
                my $insert_to_table = "INSERT INTO created_store(
    	  store_id,
    	  account_id,
    	  store_name,
    	  store_name_url,
    	  code,
    	  plan_id,
    	  currency,
    	  country,
    	  partner_code,
    	  creation_date,
    	  expiration_date
)
    VALUES(?,?,?,?,?,?,?,?,?,?,?)";

                my $stmt_to_input = $dbh->prepare($insert_to_table);

                # execute the query for insert to table created_store
                foreach my $respond_content (\%respond_content) {
                    if ($stmt_to_input->execute(
                        $respond_content->{store_id},
                        $respond_content->{account_id} // "",
                        $respond_content->{store_name},
                        $respond_content->{store_name_url},
                        $respond_content->{code},
                        $respond_content->{plan_id},
                        $respond_content->{currency},
                        $respond_content->{country},
                        $respond_content->{partner_code},
                        $respond_content->{creation_date},# = strftime("%Y-%m-%d", localtime()),
                        $respond_content->{expiration_date})
                    ) {
                        $store_update->saveLogs("Updated store's data was inserted in NEW row `created_store` ! :".__FILE__."\tline :".__LINE__);
                        1;
                    }
                    else {
                        $store_update->saveLogs("Failed store's data insert in table `created_store` ! :".__FILE__."\tline :".__LINE__);
                        warn "Failed store's data insert in table `created_store` ! ", $store_update->LOG_FILE;
                    }
                }
                $stmt_to_input->finish();

            }
            else {
                # warn "store_id already exist in 'created_store'!";
                $store_update->saveLogs("store_id:$respond_content{store_id} already exist in 'created_store'! at : ".__FILE__."\tline :".__LINE__);

                foreach (sort keys %respond_content) {
                    unless ($_ =~ /^account_id|^store_id|^creation_date|^partner_code/) {
                        my $sql_update_element = "UPDATE created_store SET $_ = ? WHERE store_id = ?";
                        my $sth_update = $dbh->prepare($sql_update_element);

                        # bind the corresponding parameter
                        # say "\n\$respond_content{$_}:"; # debug
                        # say $respond_content{$_};
                        $sth_update->bind_param(1, $respond_content{$_});
                        $sth_update->bind_param(2, $respond_content{store_id});
                        # execute the query
                        if ($sth_update->execute()) {
                            $store_update->saveLogs("Updated store:$respond_content{store_id} with [$_] was changed in `created_store` ! :".__FILE__."\tline :".__LINE__);
                            1;
                        }
                        else {
                            $store_update->saveLogs("Failed insert updated store:$respond_content{store_id} to table!".__FILE__."\tline :".__LINE__);
                            warn "Failed insert updated store:$respond_content{store_id} to table!", $store_update->LOG_FILE;
                        }
                        $sth_update->finish();
                    }
                }
                $sth_check_store_id->finish();

                # disconnect from the MySQL database
                $dbh->disconnect();

            }

        }
        undef $store_update;
        undef $self;

    }



   # __PACKAGE__->meta->make_immutable;
}
1;