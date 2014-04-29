#!/usr/bin/perl -w

#########################################################################
### Import contacts webmail Horde to Roundcube 1.0                                                
###                                                                     
### Copyright (C) 2014 Stanislav Vastyl (stanislav@vastyl.cz)
###
### This program is free software: you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation, either version 3 of the License, or
### any later version.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
### GNU General Public License for more details.
###
### You should have received a copy of the GNU General Public License
### along with this program. If not, see <http://www.gnu.org/licenses/>.
#########################################################################

use strict;
use warnings;
use DBI;

my $uid="abc123";

my $driver   = "Pg"; 
### Horde DB
my $h_database = "horde";
my $h_dsn = "DBI:$driver:dbname=horde;host=host.com;port=5432";
my $h_userid = "horde";
my $h_password = "pass";
### Roundcube DB
my $r_database = "roundcube";
my $r_dsn = "DBI:$driver:dbname=roundcube;host=host.com;port=5432";
my $r_userid = "roundcube";
my $r_password = "pass";

### Open DB Horde
my $h_dbh = DBI->connect($h_dsn, $h_userid, $h_password, { RaiseError => 1 })
                      or die $DBI::errstr;
### Open DB Roundcube
my $r_dbh = DBI->connect($r_dsn, $r_userid, $r_password, { RaiseError => 1 })
                      or die $DBI::errstr;
                      
my $r_stmt = qq(SELECT user_id from users where username = '$uid';);
my $user_id = $r_dbh->selectrow_array($r_stmt);
print "USER_ID is: " .$user_id."\n\n";

my $h_stmt = qq(SELECT object_firstname, object_lastname, object_email from turba_objects where owner_id = '$uid';);
my $h_sth = $h_dbh->prepare( $h_stmt );
my $h_rv = $h_sth->execute() or die $DBI::errstr;
if($h_rv < 0){
   print $DBI::errstr;
}
my $i = 1;
while(my @row = $h_sth->fetchrow_array()) {
	  print "CONTACT - " .$i."\n"; $i++;
      print "FIRST NAME = ". $row[0] ."\n";
      print "LAST NAME = ". $row[1] ."\n";
      print "EMAIL = ". $row[2] ."\n\n";
      ### INSERT DATA TO ROUNDCUBE
      my $name=qq($row[0] $row[1]);
      print $name ."\n";
      my $vcard=qq(BEGIN:VCARD\nVERSION:3.0\nN:$row[0] $row[1];;;\nFN:$row[0] $row[1]\nEMAIL;TYPE=INTERNET;TYPE=HOME:$row[2]\nEND:VCARD);
      print $vcard;
      my $words= qq($row[1] $row[2]);
	  $r_stmt = qq(INSERT INTO contacts (contact_id,user_id,changed,del,name,email,firstname,surname,vcard,words)
	  VALUES (nextval('contacts_seq'::text::regclass),$user_id,now(),'0','$name','$row[2]','$row[0]','$row[1]','$vcard','$words'));
	  my $r_rv = $r_dbh->do($r_stmt) or die $DBI::errstr;
	  print "\n\n";
}
print "\nOperation done successfully\n";
$h_dbh->disconnect();
$r_dbh->disconnect();
