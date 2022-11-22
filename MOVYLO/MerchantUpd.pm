package MOVYLO::MerchantUpd {
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

    sub updateMerchant {
        # updateMerchant_PUT
        my $self = shift;
        # Update a merchant account
        my $update_merch = MOVYLO::MOVYLO->new();

        use HTTP::Request::Common;
        my ($account_id, $merch_id, $partner_code, $creation_date);
        my $token = $update_merch->getToken();

        # access to DB
        my $dbh_merch_put = $update_merch->dbh_connect();

        ## create query to get all from DB table merchant with last merch_id
        my $sql_get_merchant_all = "SELECT * FROM merchant WHERE merch_id = ?";
        # create query to get all from DB table merchant with manual account_id
        my $sql_get_account_id = "SELECT * FROM merchant WHERE account_id = ?";
        # create query to get last (newest) merch_id of merchant table:
        my $sql_max_merch_id = "SELECT MAX(merch_id) FROM merchant";

        print "\nIn order to make changes to the account you created, need 'account_id'.\n";
        print "Specify the 'account_id' manually? [y/n] ";
        my $answer = <>;
        chomp($answer);
        my $temp_value;
        my @merch_account_id_last;
        my $merch_account_id_manual;
        my $merchant_last_row;
        my $sth_get_merchant;

        if ($answer =~ /^y/) {
            print "\nEnter the account_id : ";
            $temp_value = <>;
            chomp($temp_value);
            $merch_account_id_manual = $temp_value;
        } elsif ($answer =~ /^n/ or $answer =~ /^$/) {
            # execute the query to get merch_id
            my $max_merch_id = $dbh_merch_put->prepare($sql_max_merch_id);
            if ($max_merch_id->execute()) {
                @merch_account_id_last = $max_merch_id->fetchrow_array();
                print "The script get the last (active) account_id from the database!\n";
            }
            $max_merch_id->finish();

        } else {
            $update_merch->save_log("Failed to get an account! @merch_account_id_last OR $merch_account_id_manual" . __FILE__ . "\tline :" . __LINE__);
            warn "Failed to get an account! \@merch_account_id_last OR \$merch_account_id_manual", $update_merch->LOG_FILE;
            exit;
        }

        if (defined $merch_account_id_manual) {
            # execute the query to get all from DB table merchant with last account_id: manual
            $sth_get_merchant = $dbh_merch_put->prepare($sql_get_account_id);
            $sth_get_merchant->execute($merch_account_id_manual);
            $merchant_last_row = $sth_get_merchant->fetchrow_hashref;
            $sth_get_merchant->finish();
        } elsif ($merch_account_id_last[0]) {
            # execute the query to get all from DB table merchant with last account_id: last
            $sth_get_merchant = $dbh_merch_put->prepare($sql_get_merchant_all);
            $sth_get_merchant->execute($merch_account_id_last[0]);
            $merchant_last_row = $sth_get_merchant->fetchrow_hashref;
            $sth_get_merchant->finish();
        } else {
            $update_merch->save_log("No $merch_account_id_last[0] OR No $merch_account_id_manual" . __FILE__ . "\tline :" . __LINE__);
            warn "No \$merch_account_id_last[0] OR No \$merch_account_id_manual at : ", $update_merch->LOG_FILE;
        }

        # { # debug
        #     use DDP;
        #     say "\n\$merchant_last_row :";
        #     p %{$merchant_last_row};
        # }

        # get merch_id, partner_code and account_id values
        $account_id = ${$merchant_last_row}{account_id};
        $merch_id = ${$merchant_last_row}{merch_id};
        $partner_code = ${$merchant_last_row}{partner_code};
        $creation_date = ${$merchant_last_row}{creation_date};
        $merch_id = ${$merchant_last_row}{merch_id};

        # here change some values for PUT
        my %change_values = (
            partner_code  => $partner_code,
            account_id    => $account_id,
            merch_id      => $merch_id,
            creation_date => $creation_date
        ); # default values

        my $update_account_values = sub {
            my $temp;
            my $answer_temp;

            foreach my $key (sort keys %{$merchant_last_row}) {
                unless ($key =~ /^partner_code|^account_id|^creation_date|^merch_id/) # default values
                {

                    ${$merchant_last_row}{$key} = ${$merchant_last_row}{$key} ? ${$merchant_last_row}{$key} : "";

                    say "\n$key => ${$merchant_last_row}{$key}";
                    print "change or new value for the $key ? [Y/n] ";
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

                                $change_values{$key} = uc($temp);

                            } else {

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
        my $req_merch = PUT $update_merch->SERVER_API_MERCH,
            Authorization => 'Bearer ' . $token, # token == access_token from getToken()
            Content_Type  => $update_merch->CONTENT_TYPE,
            Content       => [ %change_values ];


        # PUT request to Merchant API
        my %respond_merch = %{$ua_merch->request($req_merch)};

        {
            # debug
            use DDP;
            say "\n\$respond_merch{_content}:";
            p $respond_merch{_content};
        }

        # if respond 201 - OK
        my %respond_content_merch;
        if ($respond_merch{_rc} == 201) {
            grep {
                /\{?"([\w | \s]*)":\s?"?([\d | \w | \@ |\.*| \-]*)"?\}?/g;
                $respond_content_merch{$1} = $2; # 'get in output code hash: account_id = 668, email = mail366@365.com, last_name = LastName'
            } split /,/, $respond_merch{_content}; # raw code from response: {"account_id":"668","username":"mail366@365.com","email":"mail366@365.com","last_name":"LastName","partner_code":"deluxe_p1va"}
        } else {
            $update_merch->save_log("Error processing response $respond_merch{_content}" . __FILE__ . "\tline :" . __LINE__);
            warn "Error processing response \$respond_merch{_content} = $respond_merch{_content} failed: ", $update_merch->LOG_FILE;
        }

        {
            # debug
            use DDP;
            say "\n\%respond_content_merch:";
            p % respond_content_merch;
        }

        if ($respond_merch{_rc} == 201) {

            foreach (sort keys %respond_content_merch) {
                unless ($_ =~ /^account_id/) {
                    my $sql_update_element = "UPDATE merchant SET $_ = ? WHERE merch_id = ?";
                    my $sth_update = $dbh_merch_put->prepare($sql_update_element);
                    # bind the corresponding parameter
                    #say "$_ = $respond_content_merch{$_}"; # debug
                    $sth_update->bind_param(1, $respond_content_merch{$_});
                    $sth_update->bind_param(2, $merch_id);

                    # execute the query
                    if ($sth_update->execute()) {
                        $update_merch->save_log("Updated merchant:$merch_id with $_ was changed in `merchant` ! :" . __FILE__ . "\tline :" . __LINE__);
                    } else {
                        $update_merch->save_log("Failed insert updated merchant:$merch_id to table!" . __FILE__ . "\tline :" . __LINE__);
                        warn "Failed insert updated merchant:$merch_id to table!", $update_merch->LOG_FILE;
                    }
                    $sth_update->finish();
                }
            }
        }

        # { # debug
        #
        # foreach (sort keys %respond_content_merch)
        # {
        #     print $_, '=>', $respond_content_merch{$_} // '', "\n";
        # }
        #}

        # disconnect from the MySQL database
        $dbh_merch_put->disconnect();
        undef $update_merch;
        undef $self;
    }




   # __PACKAGE__->meta->make_immutable;
}
1;