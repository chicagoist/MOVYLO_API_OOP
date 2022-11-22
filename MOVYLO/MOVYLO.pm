package MOVYLO::MOVYLO {
    use v5.10;
    use FindBin qw($Bin);
    use lib "$Bin"; # в подкаталоге
    our $VERSION = '0.03';
    use POSIX qw(strftime);
    use File::Basename qw(dirname);
    use DBI;
    use LWP::UserAgent;
    use HTTP::Request;
    use strict;
    use warnings FATAL => 'all';
    use utf8;
    binmode(STDIN, ':utf8');
    binmode(STDOUT, ':utf8');
    use Data::Dumper;
    use DDP;
    use HTTP::Request::Common;

    use Moose;
    use Moose::Util::TypeConstraints;
    use namespace::autoclean;

    extends 'MOVYLO::MovyloConfig';

    # Log files in dir LOGS
    sub saveLogs {
        my ($self) = shift;

        unless (-d dirname(__FILE__) . "/LOGS") {
            mkdir dirname(__FILE__) . "/LOGS";
        }

        my ($str) = "[ " . strftime("%H:%M:%S", localtime()) . " ] @_\n";
        my ($fh);
        open($fh, ">>", $self->LOG_FILE()) || die("Could not open " . $self->LOG_FILE());
        print($fh $str);
        close($fh);
        undef $self;

        return 1;
    }



    # No parameters
    sub getToken {
        my ($self) = @_;
        my %respondAuth;
        my %respondContent;

        # prepare for POST request
        my $uaAuth = LWP::UserAgent->new;
        my $reqAuth = POST $self->SERVER_API_AUTH,
            Content_Type => $self->CONTENT_TYPE,
            Content      => $self->AUTH_CONTENT;
        # POST request to Movylo API
        %respondAuth = %{$uaAuth->request($reqAuth)};

        if ($respondAuth{_rc} == 200) {
            grep {
                /{?"([\w | \d]*)":"?([\d | \w]*)"?,?}?/g;
                $respondContent{$1} = $2;
            } split /,/, $respondAuth{_content};

            eval {$self->saveLogs("TOKEN was successfully created $respondAuth{_content} at :" . __FILE__ . "\tline :" . __LINE__);}
        } else {
            eval {
                $self->saveLogs("ERROR Token was NOT created!!! $respondAuth{_content} at :" . __FILE__ . "\tline :" . __LINE__);
                warn "ERROR Token was NOT created!!! $respondAuth{_content}", $self->LOG_FILE;
            }
        }

        if ($respondAuth{_rc} == 200) {
            grep {
                /{?"([\w | \d]*)":"?([\d | \w]*)"?,?}?/g;
                $respondContent{$1} = $2;
            } split /,/, $respondAuth{_content};
        } else {
            eval {
                $self->saveLogs($respondAuth{_content} . __FILE__ . "\tline :" . __LINE__);
                warn "Read log file : ", $self->LOG_FILE;
            }
        }
        undef $self;
        return $respondContent{access_token};
    }

    # account_id ** integer the id of the merchant account,is ONLY used when updating existing account/merchant, not creating one
    # email * string email of the merchant (is a required parameter)
    #
    # Call this API to obtain the 'account_id' that you need for the 'create store' API or to update
    # an existing merchant account
    #
    # Example:
    # my $foo = MOVYLO::MOVYLO->new();
    # Schema: >createMerchant(email *, hash, account_id **)<
    # $foo->createMerchant('mailGyw@365.com', {first_name => 'Master',last_name => 'John',business_name => 'Business Name', zip=>'39601'}, 862);
    sub createMerchant {

        my ($self, $email, $hashValues, $accountId) = @_;

        my $token = $self->getToken();
        my %respondMerch;
        my %respondContentMerch;
        my %contentHash = (
            external_account_id => "",
            partner_code        => $self->PARTNER_CODE,
            device_id           => $hashValues->{device_id} // $self->DEVICE_ID,
            business_name       => $hashValues->{business_name} // $self->BUSINESS_NAME,
            city                => $hashValues->{city} // $self->CITY,
            account_id          => $accountId // $self->ACCOUNT_ID_POST,
            phone               => $hashValues->{phone} // $self->PHONE,
            fiscal_code         => $hashValues->{fiscal_code} // $self->FISCAL_CODE,
            device_token        => $hashValues->{device_token} // $self->DEVICE_TOKEN,
            state               => $hashValues->{state} // $self->STATE,
            last_name           => $hashValues->{last_name} // $self->LAST_NAME,
            first_name          => $hashValues->{first_name} // $self->FIRST_NAME,
            address             => $hashValues->{address} // $self->ADDRESS,
            username            => $hashValues->{username} // $self->USERNAME_MERCH,
            country             => $hashValues->{country} // $self->COUNTRY,
            password            => $hashValues->{password} // $self->PASSWORD_MERCH,
            email               => $email,
            device_platform     => $hashValues->{device_platform} // $self->DEVICE_PLATFORM,
            vat_number          => $hashValues->{vat_number} // $self->VAT_NUMBER,
            zip                 => $hashValues->{zip} // $self->ZIP
        );

        # prepare for POST request
        my $uaMerch = LWP::UserAgent->new;
        my $reqMerch = POST $self->SERVER_API_MERCH,
            Authorization => 'Bearer '.$token,
            Content_Type  => $self->CONTENT_TYPE,
            Content       => [%contentHash];
        # POST request to Merchant API
        %respondMerch = %{$uaMerch->request($reqMerch)};

        # if respond 201 - OK
        if ($respondMerch{_rc} == 201) {
            eval { $self->saveLogs("SUCCESS to create an merchant! $respondMerch{_content} at : ".__FILE__."\tline :".__LINE__); };
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
                $respondContentMerch{$1} = $2;
            } split /,/, $respondMerch{_content};
        }
        else {
            eval {
                $self->saveLogs("ERROR Failed to create an merchant! $respondMerch{_content} at : ".__FILE__."\tline :".__LINE__);
            };
        }

        # { # uncomment for debug only
        #     foreach (sort keys %respondContentMerch) {
        #         print "$_ => $respondContentMerch{$_}\n";
        #     }
        # }

        undef $self;

    }





    # sub createStore
    # account_id * string The id of the merchant account who owns of the store, required for creation then read only
    # store_name ** string The name of the store, required for creation (must be equal-less than 25 characters)
    # Creates a Store associated to the account specified by the 'account_id' parameter.
    # If you don't have the Account you need to call before the 'create merchant' API
    #
    # Example:
    # my $foo = MOVYLO::MOVYLO->new();
    # Schema: >createStore(account_id *, store_name **)<
    # $foo->createStore(855, 'Vietnam Store Name');
    sub createStore {

        my ($self, $accountId, $storeName) = @_;

        my $token = $self->getToken();
        my ($storeNameUrl) = qw();
        my %storeValues = (
            account_id   => $accountId,
            partner_code => $self->PARTNER_CODE
        );

        my %respondMerch;
        if (defined $accountId) {
            # prepare for PUT request for get merchant's data to updated or change later
            my $uaMerchant = LWP::UserAgent->new;
            my $reqMerchant = PUT $self->SERVER_API_MERCH,
                Authorization => 'Bearer '.$token,
                Content_Type  => $self->CONTENT_TYPE,
                Content       => [%storeValues];
            # PUT request to Merchant API
            %respondMerch = %{$uaMerchant->request($reqMerchant)};

        }
        elsif (!defined $accountId) {
            eval { $self->saveLogs("ERROR 2.No \$accountId at : ".__FILE__."\tline :".__LINE__) };
            exit;
        }
        else {
            eval {
                $self->saveLogs("ERROR 3.No \$accountId at : ".__FILE__."\tline :".__LINE__);
            };
            exit;
        }

        # if respond 201 - OK
        if ($respondMerch{_rc} == 201) {
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.*| \-]*)"?\}?/g;
                $storeValues{$1} = $2;
            } split /,/, $respondMerch{_content};
        }
        else {
            eval {
                $self->saveLogs("ERROR processing response $respondMerch{_content} at: ".__FILE__."\tline :".__LINE__);
            };
            exit;
        }

        unless ($storeValues{first_name}) {
            $storeValues{first_name} = '';
        }
        unless ($storeValues{last_name}) {
            $storeValues{last_name} = '';
        }

        # $store_name should not be empty by default.
        unless (defined $storeName) {
            $storeName = $storeValues{business_name} ? $storeValues{business_name}:
                "$storeValues{first_name} $storeValues{last_name}";
        }
        elsif (!defined $storeName) {
            eval { $self->saveLogs("ERROR 1.Not exists or 'business_name' or 'first_name' with 'last_name' at : ".__FILE__."\tline :".__LINE__); }
        }

        map {# to create store_name_url from store_name
            if (defined $_) {
                ($_ = ${$_}) =~ s/(\.*)\W$/$1/g;# Ltd. to Ltd or some point at end of store_name
                ($_ = $_) =~ s/\.*\s+\.*/-/g;
                if (s/\.*\s+\.*/-/g) {
                    ($_ = ${$_}) =~ s/\.*\s+\.*/-/g;
                }
                $storeNameUrl = (lc($_).".incentive-engine.com" // "incentive-engine.com");
            }
            elsif (!defined $_) {
                eval {
                    $self->saveLogs("ERROR 2.Not exists or 'business_name' or 'first_name' with 'last_name' at : ".__FILE__."\tline :".__LINE__);
                };
                exit;
            }
        } \$storeName;

        # here values for POST create store
        my %preStoreValues = (
            store_id          => "",
            account_id        => $storeValues{account_id},
            store_name        => $storeName,
            store_name_url    => $storeNameUrl,
            code              => "",
            currency          => "",
            country           => $storeValues{country},
            external_store_id => "",
            plan_id           => "",
            partner_code      => $storeValues{partner_code}
        );

        # prepare for POST request for create store with data
        my $uaCreateStore = LWP::UserAgent->new;
        my $reqCreateStore = POST $self->SERVER_API_STORE,
            Authorization => 'Bearer '.$token,
            Content_Type  => $self->CONTENT_TYPE,
            Content       => [%preStoreValues];
        # POST request to Movylo API
        my %respondStore = %{$uaCreateStore->request($reqCreateStore)};

        ## if respond 201 - OK
        my %respondContentStore;
        if ($respondStore{_rc} == 201) {
            eval { $self->saveLogs("STORE created successfully $respondStore{_content} at : ".__FILE__."\tline :".__LINE__); };
            grep {
                chomp;
                if (/\{?"(.*)":"(.*)"\}?/g) {
                    $respondContentStore{$1} = $2;
                }
                elsif (/"(.*)":(.*)\}?/g) {

                    $respondContentStore{$1} = $2;
                }
            } split /\{?,/, $respondStore{_content};
        }
        else {
            eval {
                eval { $self->saveLogs("ERROR creating store. $respondStore{_content} at : ".__FILE__."\tline :".__LINE__);
                }
            };
            exit;
        }

        $self->_private_set_store_id($respondContentStore{store_id});# NOTE: please store “store_id” parameter(s)

        undef $self;

    }


    # In the event of a product upgrade or downgrade, we need to send a call to Movylo to make an update to the store.
    # We would need to Authenticate (see REQ 2) and then send the following PUT call
    #
    # NOTES:
    #     1) This call updates only the passed parameters
    #     2) Store_id is required in this call, as an endpoint on Movylo side
    #
    # Example values of hash for call the subprogram to update Store:
    #
    # my $foo = MOVYLO::MOVYLO->new();
    # Schema: >updateStore(store_id *, hash **)<
    # $foo->updateStore(870, {store_name=>'New Store Name',currency=>'USD', country=>'USA'});
    sub updateStore {
        my ($self, $storeId, $updateContent) = @_;
        my $token = $self->getToken();

        # prepare for PUT request
        my $uaUpdateStore = LWP::UserAgent->new;
        my $reqUpdateStore = PUT $self->SERVER_API_STORE.$storeId.'/',
            Authorization => 'Bearer '.$token,
            Content_Type  => $self->CONTENT_TYPE,
            Content       => [\%{$updateContent}];
        # PUT request to Movylo API
        my %respondUpdatedStore = %{$uaUpdateStore->request($reqUpdateStore)};

        # if respond 200 - OK
        my %respondContent = ();
        if ($respondUpdatedStore{_rc} == 200) {
            eval { $self->saveLogs("STORE successfully updated: "."@{[$respondUpdatedStore{_content}]}\n"." at ".__FILE__."\tline :".__LINE__); };
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
                $respondContent{$1} = $2;
            } split /,/, $respondUpdatedStore{_content};
        }
        else {
            eval {
                $self->saveLogs("ERROR Failed to get an response from API: $respondUpdatedStore{_content} at: ".__FILE__."\tline :".__LINE__);
            };
            exit;
        }
        undef $self;
    }



    # This method deletes the account and all the stores under this account
    #
    # my $foo = MOVYLO::MOVYLO->new();
    # Schema: >deleteMerchant(account_id *)<
    # $foo->deleteMerchant(855);
    sub deleteMerchant {
        use HTTP::Request::Common qw(DELETE);

        my ($self, $account) = @_;
        my $token = $self->getToken();

        if (defined $account) {
            # prepare for DELETE request
            my $uaDelData = LWP::UserAgent->new;
            my $reqDelStore = DELETE $self->SERVER_API_MERCH.$account.'/',
                Authorization => 'Bearer '.$token,
                Content_Type  => $self->CONTENT_TYPE;
            # DELETE request to Movylo API
            my %respondStore = %{$uaDelData->request($reqDelStore)};

            # if respond 200 - OK
            my %respondContent;
            if ($respondStore{_rc} == 200) {
                $respondContent{account_id} = $account;
                grep {
                    /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
                    $respondContent{$1} = $2;
                } split /,/, $respondStore{_content};
                eval { $self->saveLogs("DELETED account_id $respondContent{account_id} successfully! at :".__FILE__."\tline :".__LINE__); };
            }
            else {
                eval {
                    $self->saveLogs("ERROR for deleting account $account : ".'$respond_store{_rc} = '.$respondStore{_rc}." ".$respondStore{_content}." at: ".__FILE__."\tline :".__LINE__);
                };
            }

            # {
            #     use DDP;
            #     say "\%respondContent:";
            #     p % respondContent;
            #     say "\$respondStore{_rc}:";
            #     p $respondStore{_rc};
            # }
        }
        else {
            eval { $self->saveLogs("You have aborted the DELETING of account: $account at: ".__FILE__."\tline :".__LINE__); };
            exit;
        }
    }



    #  If the client fails to make their monthly obligation, we should send a call to Movylo to SUSPEND the store.
    #  We will do this by sending an expired expiration date (expiration_date).
    #
    #  For example: current date minus 7 days would be an expired date.
    #  my $foo = MOVYLO::MOVYLO->new();
    #  Schema: >updateExpireDate(store_id *, hash *)<
    #  $foo->updateExpireDate(86, {expireDate=>'suspend'});
    #
    #  Client has updated their billing info and has been charged, we need to REACTIVATE their
    #  subscription. We will send a new expiration date that is not expired.
    #  For example: current date + 1000 years (this will be a date that “never” expires).
    #  my $foo = MOVYLO::MOVYLO->new();
    #  Schema: >updateExpireDate(store_id *, hash *)<
    #  $foo->updateExpireDate(86, {expireDate=>'reactivate'});
    #
    sub updateExpireDate {

        my ($self, $storeId, $varReactiveOrSuspend) = @_;
        my $token = $self->getToken();

        # prepare for GET request: to get the data of the store we need.
        my $uaGetData = LWP::UserAgent->new;
        my $reqCreatedStore = GET $self->SERVER_API_STORE . $storeId . '/',
            Authorization => 'Bearer ' . $token,
            Content_Type  => $self->CONTENT_TYPE;
        # GET request to Movylo API
        my %respondStore = %{$uaGetData->request($reqCreatedStore)};

        # if respond 200 - OK
        my %respondContent = ();
        if ($respondStore{_rc} == 200) {
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
                $respondContent{$1} = $2;
            } split /,/, $respondStore{_content};
        } else {
            eval {
                $self->saveLogs("ERROR processing response $respondStore{_content} at: " . __FILE__ . "\tline :" . __LINE__);
            };
            exit;
        }

        my $executeApi = sub {
            # prepare for PUT request
            my $uaUpdateStore = LWP::UserAgent->new;
            my $reqUpdateStore = PUT $self->SERVER_API_STORE . $respondContent{store_id} . '/',
                Authorization => 'Bearer ' . $token,
                Content_Type  => $self->CONTENT_TYPE,
                Content       => [ %respondContent ];
            # PUT request to Movylo API
            return %{$uaUpdateStore->request($reqUpdateStore)};
        };

        if ($varReactiveOrSuspend->{expireDate} =~ /suspend/) {

            if (defined $respondContent{expiration_date}) {
                my $suspendDate = localtime();
                my $epoc = time();
                $epoc = $epoc - 168 * 60 * 60;
                $suspendDate = strftime("%Y-%m-%d", localtime($epoc));
                $respondContent{expiration_date} = $suspendDate;
            } else {
                eval {$self->saveLogs("ERROR suspend store $storeId to $respondContent{expiration_date} at :" . __FILE__ . "\tline :" . __LINE__)};
                exit;
            }

            my %respondUpdatedStore = &$executeApi;

            # if respond 200 - OK
            if ($respondUpdatedStore{_rc} == 200) {
                eval {$self->saveLogs("SUSPEND. 'expiration_date' was changed for store_id $respondContent{store_id} to $respondContent{expiration_date} at:" . __FILE__ . "\tline :" . __LINE__);};
                grep {
                    /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
                    $respondContent{$1} = $2;
                } split /,/, $respondUpdatedStore{_content};

            } else {
                eval {
                    $self->saveLogs("ERROR processing response: $respondUpdatedStore{_content} at : " . __FILE__ . "\tline :" . __LINE__);
                };
            }

            # {
            #     # debug
            #     use DDP;
            #     say "\%respondContent:"; # debug
            #     p % respondContent;
            #     say "\%respondUpdatedStore:";
            #     p % respondUpdatedStore;
            # }

        } elsif ($varReactiveOrSuspend->{expireDate} =~ /reactivate/) {

            if (defined $respondContent{expiration_date}) {
                my $suspendDate = localtime();
                my $epoc = time();
                $epoc = $epoc + 1000 * (365 * (24 * 60 * 60));
                $suspendDate = strftime("%Y-%m-%d", localtime($epoc));
                $respondContent{expiration_date} = $suspendDate;
            } else {
                eval {$self->saveLogs("ERROR reactivate store $storeId to $respondContent{expiration_date} at : " . __FILE__ . "\tline :" . __LINE__)};
                exit;
            }

            my %respondUpdatedStore = &$executeApi;
            # if respond 200 - OK
            if ($respondUpdatedStore{_rc} == 200) {
                grep {
                    /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
                    $respondContent{$1} = $2;
                } split /,/, $respondUpdatedStore{_content};
                eval {$self->saveLogs("REACTIVATED. 'expiration_date' was changed for store_id $respondContent{store_id} to $respondContent{expiration_date} at:" . __FILE__ . "\tline :" . __LINE__);};
            } else {
                eval {
                    $self->saveLogs("ERROR processing response: $respondUpdatedStore{_content} at : " . __FILE__ . "\tline :" . __LINE__);
                };
            }

            # { # debug
            #     use DDP;
            #     say "\%respondContent:";
            #     p %respondContent;
            #     say "\$respondUpdatedStore{_rc}:";
            #     p $respondUpdatedStore{_rc};
            # }

        } else {
            eval {
                $self->saveLogs("ERROR processing SUSPEND or REACTIVATE for store $storeId with $respondStore{_content} at: " . __FILE__ . "\tline :" . __LINE__);
            };
        }

        undef $self;
    }



    # sub connectDB {
    #     my $dbh_obj = MOVYLO::MOVYLO->new();
    #     my %attr = (
    #         PrintError => 0,  # turn off error reporting via warn()
    #         RaiseError => 1,  # turn on error reporting via die()
    #         AutoCommit => 1); # transaction enabled
    #     DBI->connect($dbh_obj->DSN, $dbh_obj->USERNAME_DB, $dbh_obj->PASSWORD_DB, \%attr) or
    #         die("Error connecting to the database: $DBI::errstr\n");
    # }


    #
    # # If the client fails to make their monthly obligation, we should send a call to Movylo to SUSPEND the store.
    # # We will do this by sending an expired expiration date (expiration_date).
    # #
    # # For example: current date minus 7 days would be an expired date.
    # # my $foo = MOVYLO::MOVYLO->new();
    # # Schema: >updateStore(store_id *)<
    # # $foo->suspendStore(870);
    # sub suspendStore {
    #
    #     my ($self, $storeId) = @_;
    #     my $token = $self->getToken();
    #
    #     # prepare for GET request: to get the data of the store we need.
    #     my $uaGetData = LWP::UserAgent->new;
    #     my $reqCreatedStore = GET $self->SERVER_API_STORE.$storeId.'/',
    #         Authorization => 'Bearer '.$token,
    #         Content_Type  => $self->CONTENT_TYPE;
    #     # GET request to Movylo API
    #     my %respondStore = %{$uaGetData->request($reqCreatedStore)};
    #
    #     # if respond 200 - OK
    #     my %respondContent = ();
    #     if ($respondStore{_rc} == 200) {
    #         grep {
    #             /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
    #             $respondContent{$1} = $2;
    #         } split /,/, $respondStore{_content};
    #     }
    #     else {
    #         eval {
    #             $self->saveLogs("ERROR processing response $respondStore{_content} at : ".__FILE__."\tline :".__LINE__);
    #         };
    #         exit;
    #     }
    #
    #     my $updateStoreContent = sub {
    #
    #         my $suspendDate = localtime();
    #         # print "Current date and time $suspend_date\n";
    #         my $epoc = time();
    #         $epoc = $epoc - 168 * 60 * 60;# one week ago of current date.
    #         $suspendDate = strftime("%Y-%m-%d", localtime($epoc));
    #         $respondContent{expiration_date} = $suspendDate;
    #     };
    #     &{$updateStoreContent};
    #
    #     # prepare for PUT request
    #     my $uaUpdateStore = LWP::UserAgent->new;
    #     my $reqUpdateStore = PUT $self->SERVER_API_STORE.$respondContent{store_id}.'/',
    #         Authorization => 'Bearer '.$token,
    #         Content_Type  => $self->CONTENT_TYPE,
    #         Content       => [%respondContent];
    #     # PUT request to Movylo API
    #     my %respondUpdatedStore = %{$uaUpdateStore->request($reqUpdateStore)};
    #
    #     # if respond 200 - OK
    #     if ($respondUpdatedStore{_rc} == 200) {
    #         eval { $self->saveLogs("SUSPEND. 'expiration_date' was changed for store_id $respondContent{store_id} to $respondContent{expiration_date} at:".__FILE__."\tline :".__LINE__); };
    #         grep {
    #             /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
    #             $respondContent{$1} = $2;
    #         } split /,/, $respondUpdatedStore{_content};
    #
    #     }
    #     else {
    #         eval {
    #             $self->saveLogs("ERROR processing response: $respondUpdatedStore{_content} at : ".__FILE__."\tline :".__LINE__);
    #         };
    #     }
    #
    #     # {
    #     #     # debug
    #     #     use DDP;
    #     #     say "\%respondContent:"; # debug
    #     #     p % respondContent;
    #     #     say "\%respondUpdatedStore:";
    #     #     p % respondUpdatedStore;
    #     # }
    #     undef $self;
    # }



    #
    # # Client has updated their billing info and has been charged, we need to reactivate their
    # # subscription. We will send a new expiration date that is not expired, for example:
    # # current date + 1000 years (this will be a date that “never” expires).
    # #
    # # my $foo = MOVYLO::MOVYLO->new();
    # # Schema: >reactiveStore(store_id *)<
    # # $foo->reactiveStore(870);
    # sub reactiveStore {
    #
    #     my ($self, $storeId) = @_;
    #     my $token = $self->getToken();
    #
    #     # prepare for GET request
    #     my $uaGetData = LWP::UserAgent->new;
    #     my $reqCreatedStore = GET $self->SERVER_API_STORE.$storeId.'/',
    #         Authorization => 'Bearer '.$token,
    #         Content_Type  => $self->CONTENT_TYPE;
    #     # GET request to Movylo API
    #     my %respondStore = %{$uaGetData->request($reqCreatedStore)};
    #
    #     # if respond 200 - OK
    #     my %respondContent = ();
    #     if ($respondStore{_rc} == 200) {
    #         grep {
    #             /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
    #             $respondContent{$1} = $2;
    #         } split /,/, $respondStore{_content};
    #     }
    #     else {
    #         eval { $self->saveLogs("ERROR processing response $respondStore{_content} at: ".__FILE__."\tline :".__LINE__);
    #         };
    #     }
    #
    #     my $updateStoreContent = sub {
    #
    #         if (defined $respondContent{expiration_date}) {
    #             my $suspendDate = localtime();
    #             my $epoc = time();
    #             $epoc = $epoc + 1000 * (365 * (24 * 60 * 60));
    #             $suspendDate = strftime("%Y-%m-%d", localtime($epoc));
    #             $respondContent{expiration_date} = $suspendDate;
    #         }
    #         else {
    #             eval { $self->saveLogs("ERROR reactivate store $storeId to $respondContent{expiration_date} at : " .__FILE__."\tline :".__LINE__) };
    #             exit;
    #         }
    #     };
    #     &{$updateStoreContent};
    #
    #     # prepare for PUT request
    #     my $uaUpdateStore = LWP::UserAgent->new;
    #     my $reqUpdateStore = PUT $self->SERVER_API_STORE.$respondContent{store_id}.'/',
    #         Authorization => 'Bearer '.$token,
    #         Content_Type  => $self->CONTENT_TYPE,
    #         Content       => [\%respondContent];
    #     # PUT request to Movylo API
    #     my %respondUpdatedStore = %{$uaUpdateStore->request($reqUpdateStore)};
    #     # if respond 200 - OK
    #     if ($respondUpdatedStore{_rc} == 200) {
    #         grep {
    #             /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.* | \-]*)"?\}?/g;
    #             $respondContent{$1} = $2;
    #         } split /,/, $respondUpdatedStore{_content};
    #         eval { $self->saveLogs("REACTIVATED store_id $respondContent{store_id} successfully to $respondContent{expiration_date} at :".__FILE__."\tline :".__LINE__); };
    #     }
    #     else {
    #         eval {
    #             $self->saveLogs("ERROR processing response: $respondUpdatedStore{_content} at: ".__FILE__."\tline :".__LINE__);
    #         };
    #     }
    #
    #     # { # debug
    #     #     use DDP;
    #     #     say "\%respondContent:";
    #     #     p %respondContent;
    #     #     say "\$respondUpdatedStore{_rc}:";
    #     #     p $respondUpdatedStore{_rc};
    #     # }
    #
    #     undef $self;
    # }


    sub updateMerchant {
        # Update a merchant account
        my ($self) = @_;
        my $token = $self->getToken();

        print "\nIn order to make changes to the account you created, need 'account_id'.\n";
        print "Specify the 'account_id' manually? [y/N] ";
        my $answer = <>;
        chomp($answer);
        my $temp_value;
        my $merch_account_id_manual;

        if ($answer =~ /^y/) {
            print "\nEnter the account_id : ";
            $temp_value = <>;
            chomp($temp_value);
            $merch_account_id_manual = $temp_value;
        } elsif ($answer =~ /^n/ or $answer =~ /^$/) {
            $self->saveLogs("ERROR Failed to get an account! \$merch_account_id_manual" . __FILE__ . "\tline :" . __LINE__);
            return 0;

        } else {
            $self->saveLogs("ERROR Failed to get an account! $merch_account_id_manual" . __FILE__ . "\tline :" . __LINE__);
            warn "ERROR Failed to get an account! \$merch_account_id_manual", $self->LOG_FILE;
            exit;
        }

        # here change some values for PUT
        my %change_values = (
            partner_code => $self->PARTNER_CODE,
            account_id   => $merch_account_id_manual
        ); # default values
        my %respond;
        my %respond_merch;
        my %respond_content_api;
        my %respond_content_merch;

        if (defined $merch_account_id_manual) {
            # prepare for PUT request
            my $ua_merch = LWP::UserAgent->new;
            my $req_merch = PUT $self->SERVER_API_MERCH,
                Authorization => 'Bearer ' . $token, # token == access_token from getToken()
                Content_Type  => $self->CONTENT_TYPE,
                Content       => [ %change_values ];
            # PUT request to Merchant API
            %respond_merch = %{$ua_merch->request($req_merch)};

            # if respond 201 - OK
            if ($respond_merch{_rc} == 201) {
                grep {
                    /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.*| \-]*)"?\}?/g;
                    $respond_content_merch{$1} = $2;   # 'get in output code hash: account_id = 668, email = mail366@365.com, last_name = LastName'
                } split /,/, $respond_merch{_content}; # raw code from response: {"account_id":"668","username":"mail366@365.com","email":"mail366@365.com","last_name":"LastName","partner_code":"deluxe_p1va"}
            } else {
                $self->saveLogs("Error processing response $respond_merch{_content}" . __FILE__ . "\tline :" . __LINE__);
                warn "Error processing response \$respond_merch{_content} = $respond_merch{_content} failed: ", $self->LOG_FILE;
            }

            {
                # debug
                use DDP;
                say "\n\%respond_content_merch:";
                p % respond_content_merch;
            }

        } else {
            $self->saveLogs("No $merch_account_id_manual" . __FILE__ . "\tline :" . __LINE__);
            warn "No \$merch_account_id_manual at : ", $self->LOG_FILE;
        }

        # { # debug
        #     use DDP;
        #     say "\n\$merchant_last_row :";
        #     p %{$merchant_last_row};
        # }

        my $update_account_values = sub {
            my $temp;
            my $answer_temp;

            foreach my $key (sort keys %respond_content_merch) {
                unless ($key =~ /^partner_code|^account_id|^creation_date|^merch_id/) # default values
                {

                    $respond_content_merch{$key} = $respond_content_merch{$key} ? $respond_content_merch{$key} : "";

                    say "\n$key => $respond_content_merch{$key}";
                    print "change or new value for the $key ? [y/N] ";
                    $answer_temp = <>;

                    if ($answer_temp =~ /^n/i or $answer_temp =~ /^$/) {
                        next;
                    }
                    if ($answer_temp =~ /^y/i or $answer_temp =~ /!^$/) {
                        print "Enter new value for the $key :";
                        $temp = <>;
                        chomp($temp);
                        unless ($temp =~ /^$/) {
                            if ($key =~ /^country|^state/) {

                                $self->saveLogs("Updated merchant:$key was changed to $change_values{$key} ! :" . __FILE__ . "\tline :" . __LINE__) if
                                    $change_values{$key} = uc($temp);
                            } else {

                                $self->saveLogs("Updated merchant:$key was changed to $change_values{$key} ! :" . __FILE__ . "\tline :" . __LINE__) if
                                    $change_values{$key} = $temp;
                            }
                        } else {
                            next;
                        }
                    } else {
                        next;
                    }
                }
            }
        };
        &{$update_account_values};

        # prepare for PUT request
        my $ua_merch = LWP::UserAgent->new;
        my $req_merch = PUT $self->SERVER_API_MERCH,
            Authorization => 'Bearer ' . $token, # token == access_token from getToken()
            Content_Type  => $self->CONTENT_TYPE,
            Content       => [ %change_values ];


        # PUT request to Merchant API
        %respond = %{$ua_merch->request($req_merch)};

        {
            # debug
            use DDP;
            say "\n\$respond_merch{_content}:";
            p $respond{_content};
        }

        # if respond 201 - OK
        if ($respond{_rc} == 201) {
            $self->saveLogs("Successfully processing response $respond{_content}" . __FILE__ . "\tline :" . __LINE__);
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.*| \-]*)"?\}?/g;
                $respond_content_api{$1} = $2; # 'get in output code hash: account_id = 668, email = mail366@365.com, last_name = LastName'
            } split /,/, $respond{_content};   # raw code from response: {"account_id":"668","username":"mail366@365.com","email":"mail366@365.com","last_name":"LastName","partner_code":"deluxe_p1va"}
        } else {
            $self->saveLogs("Error processing response $respond{_content}" . __FILE__ . "\tline :" . __LINE__);
            warn "Error processing response \$respond_merch{_content} = $respond{_content} failed: ", $self->LOG_FILE;
        }

        {
            # debug
            use DDP;
            say "\n\%respond_content_api:";
            p % respond_content_api;
        }

        # { # debug
        #
        # foreach (sort keys %respond_content_api)
        # {
        #     print $_, '=>', $respond_content_api{$_} // '', "\n";
        # }
        #}

        undef $self;
    }



    __PACKAGE__->meta->make_immutable;
}
1;