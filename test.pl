#!/usr/bin/perl -w

use v5.10;
use FindBin qw($Bin);
use lib "$Bin";
use DBI;

use strict;
use warnings FATAL => 'all';
use MOVYLO::MOVYLO;


my $foo = MOVYLO::MOVYLO->new();


print $foo->getToken();
#$foo->createMerchant('mailGyx@365.com', {first_name => 'Master',last_name => 'Slave',business_name => 'Master Slave', zip=>'39601'},862);
#$foo->updateMerchant();
#$foo->createStore(855);
#$foo->updateStore(864, {store_name=>'Vietnam Store Name',currency=>'VND', country=>'VN',business_name => 'Business Vietnam'});
#$foo->suspendStore(864);
#$foo->reactiveStore(864);
#$foo->deleteMerchant(856);
#$foo->updateExpireDate(86, {expireDate=>'suspend'});
#$foo->updateExpireDate(86, {expireDate=>'reactivate'});