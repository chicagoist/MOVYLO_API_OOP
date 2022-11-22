package MOVYLO::StoreCreat {
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

    requires qw(authentication);

    sub createStore {
        # createStore

        my $self = shift;
        # Creates a Store associated to the account specified by the 'account_id' parameter.
        # If you don't have the Account you need to call before the 'create merchant' API
        my $create_store = MOVYLO::MOVYLO->new();

        use HTTP::Request::Common;
        my $token = $create_store->authentication();

        my ($account_id, $partner_code, $store_name, $store_name_url) = qw();# for request

        # access to DB
        my $dbh_create_store = $create_store->dbh_connect();

        ## create query to get all from DB table merchant with last merch_id
        my $sql_get_all_last = "SELECT * FROM merchant WHERE merch_id = ?";
        # with manual account_id
        my $sql_get_all_manual = "SELECT * FROM merchant WHERE account_id = ?";
        # #create query to get last (newest) merch_id of merchant table:
        my $sql_max_merch_id = "SELECT MAX(merch_id) FROM merchant";

        print "\nTo create a store, you need to specify the 'account_id' that you created earlier.\n";
        print "Specify the 'account_id' manually? [y/n] ";
        my $answer = <>;
        chomp($answer);
        my $temp_value;
        my @merch_account_id_last;
        my $merch_account_id_manual;
        my $merchant_last_row;
        my $sth_get_merchant;

        # Or manually select an account_id for work or select the latest from the database:
        if ($answer =~ /^y/) {
            print "\nEnter the 'account_id' : ";
            $temp_value = <>;
            chomp($temp_value);
            $merch_account_id_manual = $temp_value;
        }
        elsif ($answer =~ /^n/ or $answer =~ /^$/) {
            # execute the query to get merch_id
            my $max_merch_id = $dbh_create_store->prepare($sql_max_merch_id);
            if ($max_merch_id->execute()) {
                @merch_account_id_last = $max_merch_id->fetchrow_array();
                print "The script get the last (active) account_id from the database!\n";
            }
            $max_merch_id->finish();
        }
        else {
            $create_store->save_log("1.NO @merch_account_id_last or NO  $merch_account_id_manual at: ".__FILE__."\tline :".__LINE__);
            warn "1.No account_id get. Read log file : ", $create_store->LOG_FILE;
            exit;
        }
        if (defined $merch_account_id_manual) {
            # execute the query to get all from DB table merchant with exactly account_id manual
            $sth_get_merchant = $dbh_create_store->prepare($sql_get_all_manual);
            $sth_get_merchant->execute($merch_account_id_manual);
            $merchant_last_row = $sth_get_merchant->fetchrow_hashref;
            $sth_get_merchant->finish();
        }
        elsif ($merch_account_id_last[0]) {
            # execute the query to get all from DB table merchant with last account_id auto
            $sth_get_merchant = $dbh_create_store->prepare($sql_get_all_last);
            $sth_get_merchant->execute($merch_account_id_last[0]);
            $merchant_last_row = $sth_get_merchant->fetchrow_hashref;
            $sth_get_merchant->finish();
        }
        else {
            $create_store->save_log("2.No $merch_account_id_last[0] OR No $merch_account_id_manual".__FILE__."\tline :".__LINE__);
            warn "2.No \$merch_account_id_last[0] OR No \$merch_account_id_manual at : ", $create_store->LOG_FILE;
            exit;
        }

        # get values from hash's ref $merchant
        $account_id = ($account_id ? $merch_account_id_manual:$merchant_last_row->{account_id});
        $partner_code = $create_store->PARTNER_CODE;#${$partner_code}

        my %store_values = (
            account_id   => $account_id,
            partner_code => $create_store->PARTNER_CODE #${$partner_code}# ref from PARTNER_CODE
        );# default values

        # { # debug
        #     use DDP;
        # say "\%store_values:"; # debug
        # p %store_values;
        #}

        # prepare for PUT request for get merchant's data to updated or change manually later
        my $ua_merchant = LWP::UserAgent->new;
        my $req_merchant = PUT $create_store->SERVER_API_MERCH, #'https://api.sandbox.movylo.com/v3/Merchant/',
            Authorization => 'Bearer '.$token,
            Content_Type  => $create_store->CONTENT_TYPE, #'application/x-www-form-urlencoded; charset=UTF-8',
            Content       => [%store_values];

        # PUT request to Merchant API
        my %respond_merch = %{$ua_merchant->request($req_merchant)};

        # { # uncomment for debug only
        #     use DDP;
        # say "\%respond_merch:"; # debug
        # p %respond_merch;
        #}

        # if respond 201 - OK
        if ($respond_merch{_rc} == 201) {
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.*| \-]*)"?\}?/g;
                $store_values{$1} = $2;# get in output code hash: account_id = 668, email = mail366@365.com, last_name = LastName'
            } split /,/, $respond_merch{_content};# raw code from response: {"account_id":"668","username":"mail366@365.com","email":"mail366@365.com","last_name":"LastName","partner_code":"deluxe_p1va"}
        }
        else {
            $create_store->save_log("Error processing response $respond_merch{_content}".__FILE__."\tline :".__LINE__);
            warn "Error processing response \$respond_merch{_content} = $respond_merch{_content} failed: ", $create_store->LOG_FILE;
            exit;
        }

        # { # uncomment for debug only
        #     use DDP;
        # say "\%store_values:"; # debug
        # p %store_values;
        #}

        unless ($store_values{first_name}) {
            $store_values{first_name} = '';
        }
        unless ($store_values{last_name}) {
            $store_values{last_name} = '';
        }

        if ($store_values{business_name} or ($store_values{first_name} and $store_values{last_name})) {
            # $store_name should not be empty by default.
            $store_name = $store_values{business_name} ? $store_values{business_name}:
                "$store_values{first_name} $store_values{last_name}";
        }
        else {
            warn "1.Not exists or 'business_name' or 'first_name' with 'last_name'";
            $create_store->save_log("1.Not exists or 'business_name' or 'first_name' with 'last_name' at : ".__FILE__."\tline :".__LINE__);
            exit;
        }

        # say "\$store_name = $store_name"; # uncomment for debug only

        map {# to create store_name_url from store_name
            if (defined $_) {
                ($_ = ${$_}) =~ s/(\.*)\W$/$1/g;# Ltd. to Ltd or some point at end of store_name
                ($_ = $_) =~ s/\.*\s+\.*/-/g;
                if (s/\.*\s+\.*/-/g) {
                    ($_ = ${$_}) =~ s/\.*\s+\.*/-/g;
                }
                $store_name_url = (lc($_).".incentive-engine.com" // "incentive-engine.com");
            }
            else {
                warn "2.Not exists or 'business_name' or 'first_name' with` 'last_name'";
                $create_store->save_log("2.Not exists or 'business_name' or 'first_name' with 'last_name' at : ".__FILE__."\tline :".__LINE__);
                exit;
            }
        } \$store_name;

        # say "\$store_name_url = $store_name_url"; # uncomment for debug only

        # here values for POST create store
        my %pre_store_values = (
            store_id          => "",
            account_id        => $store_values{account_id},
            store_name        => $store_name,
            store_name_url    => $store_name_url,
            code              => "",
            currency          => "",
            country           => $store_values{country},
            external_store_id => "",
            plan_id           => "",
            partner_code      => $store_values{partner_code}
        );

        # { # uncomment for debug only
        #     use DDP;
        # say "\%pre_store_values:"; # debug
        # p %pre_store_values;
        # }

        #### CHANGE THIS BLOCK FOR MANUAL
        my $update_store_content = sub {
            $temp_value = undef;
            $answer = undef;
            say "\n\tCreate a store";

            foreach my $key (sort keys %pre_store_values) {
                unless ($key =~ /^partner_code|^account_id|^code|^store_name_url|^store_id/)# default values
                {

                    $pre_store_values{$key} = $pre_store_values{$key} ? $pre_store_values{$key}:"";
                    say "\n$key => $pre_store_values{$key}";
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
                            if ($key =~ /^country|^currency/) {
                                $pre_store_values{$key} = uc($temp_value);
                            }
                            else {
                                $pre_store_values{$key} = $temp_value;
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

            # {# uncomment for debug only
            #     foreach (sort keys %pre_store_values)
            #     {
            #         say "$_ => ", $pre_store_values{$_};
            #     }
            # }

        };

        &{$update_store_content};

        # { # debug
        #     use DDP;
        # say "\%pre_store_values:"; # debug
        # p %pre_store_values;
        # }

        # prepare for POST request for create store with new data
        my $ua_create_store = LWP::UserAgent->new;
        my $req_create_store = POST $create_store->SERVER_API_STORE, #'https://api.sandbox.movylo.com/v3/Store/',
            Authorization => 'Bearer '.$token,
            Content_Type  =>  $create_store->CONTENT_TYPE, #'application/x-www-form-urlencoded; charset=UTF-8',
            Content       => [%pre_store_values];

        # POST request to Movylo API
        my %respond_store = %{$ua_create_store->request($req_create_store)};

        ## if respond 201 - OK
        my %respond_content_store;
        if ($respond_store{_rc} == 201) {
            $create_store->save_log("Store created successfully $respond_store{_content}".__FILE__."\tline :".__LINE__);
            grep {
                chomp;
                if (/\{?"(.*)":"(.*)"\}?/g) {
                    $respond_content_store{$1} = $2;# 'get in output code hash: account_id = 668, email = mail366@365.com, last_name = LastName'
                }
                elsif (/"(.*)":(.*)\}?/g) {

                    $respond_content_store{$1} = $2;# 'get in output code hash: account_id = 668, email = mail366@365.com, last_name = LastName'
                }
            } split /\{?,/, $respond_store{_content};
        }
        else {
            $create_store->save_log("Error creating store. $respond_store{_content}".__FILE__."\tline :".__LINE__);
            warn "Error creating store. Read log file at : ", $create_store->LOG_FILE;
            exit;
        }

        # { # uncomment for debug only
        #     use DDP;
        # say "\n \%respond_content_store:"; #debug
        # p %respond_content_store;
        # }

        # create table respond_after_creating
        my @ddl_respond_after_creating = (
            "CREATE TABLE respond_after_creating (
    	  id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    	  store_id varchar(255),
    	  account_id varchar(255) NOT NULL,
    	  store_name varchar(255) NOT NULL,
    	  store_name_url varchar(50),
    	  store_logo_url varchar(255),
    	  login_url varchar(255),
    	  status varchar(255),
    	  store_currency varchar(255),
    	  store_currency_html varchar(255),
    	  store_url varchar(255),
    	  is_lite varchar(255),
    	  creation_date  DATE
    	) ENGINE=InnoDB;"
        );

        my $sql_if_exist = "SHOW TABLES LIKE 'respond_after_creating'";
        my $sth_after_crt = $dbh_create_store->prepare($sql_if_exist);
        # create a new table at DB if not exists
        if ($sth_after_crt->execute() != 1) {
            # execute all create table statements
            foreach my $table (@ddl_respond_after_creating) {
                $dbh_create_store->do($table);
            }
            #print "Access to DB OK Pre Store exists! \n";
            $create_store->save_log("Table 'respond_after_creating' was created in DB! :".__FILE__."\tline :".__LINE__);
        }
        else {
            # warn "Table 'respond_after_creating' already exist in DB!";
            $create_store->save_log("Table 'respond_after_creating' already exist in DB! at : ".__FILE__."\tline :".__LINE__);
        }
        $sth_after_crt->finish();

        my $sql_after_crt = "INSERT INTO respond_after_creating(
    	  store_id,
    	  account_id,
    	  store_name,
    	  store_name_url,
    	  store_logo_url,
    	  login_url,
    	  status,
    	  store_currency,
    	  store_currency_html,
    	  store_url,
    	  is_lite,
          creation_date
    	  )
    VALUES(?,?,?,?,?,?,?,?,?,?,?,?)";
        my $stmt_after_crt = $dbh_create_store->prepare($sql_after_crt);
        # execute the query for insert to table merchant
        foreach my $after_crt (\%respond_content_store) {
            if ($stmt_after_crt->execute(
                $after_crt->{store_id},
                $pre_store_values{account_id},
                $after_crt->{store_name} // "",
                $after_crt->{store_name_url} // "",
                $after_crt->{store_logo_url} // "",
                $after_crt->{login_url} // '',
                $after_crt->{status} // '',
                $after_crt->{store_currency} // '',
                $after_crt->{store_currency_html} // '',
                $after_crt->{store_url} // "",
                $after_crt->{is_lite} // "",
                strftime("%Y-%m-%d", localtime())
            )
            ) {
                $create_store->save_log("New row was inserted successfully to table 'respond_after_creating'! :".__FILE__."\tline :".__LINE__);
                1;
            }
        }
        $stmt_after_crt->finish();

        # { # uncomment for debug only
        #     use DDP;
        # say "\n\$pre_store_values{account_id} = $pre_store_values{account_id}"; # debug
        # say "\$respond_content_store{store_id} = $respond_content_store{store_id}";
        # }

        # prepare for GET request for store values to local DB
        my $ua_GET_store = LWP::UserAgent->new;
        my $req_GET_store = GET 'https://api.sandbox.movylo.com/v3/Store/'.$respond_content_store{store_id}.'/',
            Authorization => 'Bearer '.$token,
            Content_Type  =>  $create_store->CONTENT_TYPE; #'application/x-www-form-urlencoded; charset=UTF-8';

        # GET request to Movylo API
        my %respond_GET = %{$ua_GET_store->request($req_GET_store)};

        # { # debug
        #     use DDP;
        # say "\n\%respond_GET:"; #debug
        # p %respond_GET;
        #}

        # if respond 200 - OK
        my %created_store = ();
        if ($respond_GET{_rc} == 200) {
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.*| \-]*)"?\}?/g;
                $created_store{$1} = $2;# 'get in output code hash: account_id = 668, email = mail366@365.com, last_name = LastName'
            } split /,/, $respond_GET{_content};# raw code from response: {"account_id":"668","username":"mail366@365.com","email":"mail366@365.com","last_name":"LastName","partner_code":"deluxe_p1va"}
        }
        else {
            $create_store->save_log("An error occurred while getting data from the store. $respond_GET{_content}".__FILE__."\tline :".__LINE__);
            warn "An error occurred while getting data from the store. \$respond_GET{_content} = $respond_GET{_content} failed: ", $create_store->LOG_FILE;
            exit;
        }

        # {
        #     # uncomment for debug only
        #     use DDP;
        #     say "\n\$respond_GET{_content}:";
        #     p $respond_GET{_content};
        #     say "\n\%created_store";# debug
        #     p % created_store;
        # }

        # create table created_store
        my @ddl_created_store = (
            "CREATE TABLE created_store (
    	  id int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    	  store_id varchar(255) NOT NULL,
    	  account_id varchar(255) NOT NULL,
    	  store_name varchar(255) NOT NULL,
    	  store_name_url varchar(50) NOT NULL,
    	  code varchar(255) NOT NULL,
    	  plan_id varchar(255) NOT NULL,
    	  currency varchar(255) NOT NULL,
    	  country varchar(255) NOT NULL,
    	  partner_code varchar(255) NOT NULL,
    	  creation_date  DATE,
    	  expiration_date  DATE
    	) ENGINE=InnoDB;"
        );

        my $sql_if_exist_created_store = "SHOW TABLES LIKE 'created_store'";
        my $sth_created_store = $dbh_create_store->prepare($sql_if_exist_created_store);
        # create a new table at DB if not exists
        if ($sth_created_store->execute() != 1) {
            # execute all create table statements
            foreach my $table (@ddl_created_store) {
                $dbh_create_store->do($table);
            }
            #print "Access to DB OK! \n";
            $create_store->save_log("Table `created_store` was created successfully in DB! :".__FILE__."\tline :".__LINE__);
        }
        else {
            # warn "Table 'created_store' already exist in DB!";
            $create_store->save_log("Table 'created_store' already was exist in DB! at : ".__FILE__."\tline :".__LINE__);
        }
        $sth_created_store->finish();

        my $sql_insert_respond_store = "INSERT INTO created_store(
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

        my $stmt_respond_to_store = $dbh_create_store->prepare($sql_insert_respond_store);

        # execute the query for insert to table created_store
        foreach my $respond_content (\%created_store) {
            if ($stmt_respond_to_store->execute(
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
                # {# uncomment for debug only
                #     foreach (sort keys %created_store) {
                #         say "$_ => ", $created_store{$_};
                #     }
                # }
                $create_store->save_log("New row was inserted successfully to table 'created_store'! :".__FILE__."\tline :".__LINE__);
                1;
            }
            else {
                $create_store->save_log("Failed inserting row to the table 'created_store'! :".__FILE__."\tline :".__LINE__);
                warn "Failed inserting row to the table 'created_store'", $create_store->LOG_FILE;
                exit;
            }
        }
        $stmt_respond_to_store->finish();

        # disconnect from the MySQL database
        $dbh_create_store->disconnect();
        undef $create_store;
        undef $self;

    }




   # __PACKAGE__->meta->make_immutable;
}
1;