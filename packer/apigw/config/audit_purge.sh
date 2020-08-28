#!/bin/sh
#
# Script to purge non SEVERE audit records over a certain age
#
# WARNING: Only run this script on one database node in a cluster, preferably
# the primary database node. Replication will handle purging records in the
# second database.
#
# Obtaining database user passwords from a Layer 7 Gateway
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# This scripts requires two passwords, one to access the MySQL database on
# the remote system, the other to access an admin user on the local database
# for purging the binlogs if replication is working. Storing password in the
# clear in a script is not advisable. To get around this you can store
# passwords in the encrypted password store of a Layer 7 Gateway and make
# the password available via a REST service. For instructions on doing this
# please contact Layer 7 Support.
#
# Revision History:
# ~~~~~~~~~~~~~~~~~
# Jay MacDonald - v1 - 20080122
# Jay MacDonald - v2 - 20090130 - Added OPTIMIZE TABLES
# Jay MacDonald - v3 - 20100926 - Added looping with LIMIT constraint and command line parsing
# Jay MacDonald - v4 - 20120601 - Added SNMP GET, PURGE=no as default, logger stuff
# Beiming Wang - v5 - 20140219 - Use pw assist file instead of getPwd service
################################################# Configurable settings

# Set the default age of the oldest record to keep
#AGE="2 months"
#AGE="3 weeks"
AGE="10 days"			# Override with '-a'

# Define number of records to delete with each pass. Need this for handling
# large number of records
LIMIT=5000			# Override with '-l'

# Default PURGE=no, meaning do not purge
PURGE=no			# Override with '-p'

# Define the database connection settings. This can be refined using the
# ACL in MySQL if necessary, else just use the same creds as the SSG
DB="ssg"
DBHOST="localhost"
DBUSER="gateway"


# Dump SNMP_GET style output?
NOTIFY_SNMP_GET="no"		# Override with -g

# Set VERBOSE to yes when debugging. Under normal operations it should
# probably be set to "no".
VERBOSE="no"			# Override with '-v'

###########################################################################
################################################# End configurable settings
###########################################################################

########################################################## Define functions

clean_up() {
        rm -f /tmp/ap*.$$
        exit $1
}

print_help () {
	echo "$0 - Purge audit records from SecureSpan Database"
	echo ""
	echo "Command line parameters:"
	echo "  -p          : Purge records in the database"
	echo "  -l <#>      : Number of records to purge on each pass (default: $LIMIT)"
	echo "  -a <period> : Age of records to purge (default: $AGE)"
	echo "  -g          : SNMP GET style output (purgable:purged:remaining)"
	echo "  -v          : Verbose output"
	echo "  -d          : Print the configured defaults and exit"
	echo "  -h          : Print this list and exit"
	echo ""
	echo "Exit status 0 if success, 1 if not"
	echo ""
	echo "Examples:"
	echo "  # $0 -a '1 day' -l 10000 -p -v"
	echo "  Found 20923 audit records, 19269 older than 1 day"
	echo "    ==> Purging 10000 audit records..."
	echo "    ==> Purging 9269 audit records..."
	echo "    ==> Optimizing audit tables..."
	echo "  There are currently 1654 audit records in the database"
	echo "  #"
	echo ""
	echo "  # $0 -a '1 day' -l 10000 -g"
	echo "  19269:0:20923 (purgable:purged:remaining)"
	echo "  #"
	echo ""
	echo "  # $0 -a '1 day' -l 10000 -p -g"
	echo "  19269:19269:1654 (purgable:purged:remaining)"
	echo "  #"
	echo ""
}

print_defaults () {
	echo "Default settings:"
	echo "  VERBOSE=$VERBOSE"
	echo "  NOTIFY_SNMP_GET=$NOTIFY_SNMP_GET"
	echo "  AGE=$AGE"
	echo "  LIMIT=$LIMIT"
	echo "  DBHOST=$DBHOST"
	echo "  DB=$DB"	
}

verbose() {
	if test "$VERBOSE" == "yes" ; then
		if test "$1" = "-n" ; then
			arg="-n"
			string=$2
		else
			arg=""
			string=$1
		fi
		echo $arg $string
	fi
}

query () {
	RESULT=`$MYSQL -e "$SQL" $DB 2>/tmp/ap_error.$$`

	if test $? -ne 0; then
		cat /tmp/ap_error.$$ | logger -t $0 --

		echo ""
		echo "==> Error querying database"
		echo ""
		echo -n "Message: "
		cat /tmp/ap_error.$$
		echo ""
		echo "Refer to http://dev.mysql.com/doc/refman/5.1/en/error-messages-client.html"
		echo "for more information."
		echo ""
		clean_up 1
	fi
	rm -f /tmp/ap_error.$$
}


############################################ Parse the command line options

OPTS="vdhpgl:a:"

# Get the command line arguments to overwrite defaults
while getopts $OPTS opt ; do
	case $opt in
	   v)   VERBOSE='yes' ;;

	   g)   NOTIFY_SNMP_GET='yes' ;;

	   p)   PURGE='yes' ;;

	   l)   LIMIT=$OPTARG ;;

	   a)   AGE=$OPTARG ;;

	   d)   print_defaults
	        exit 0
	        ;;

	   h)   print_help
	        exit 0
	        ;;

	   ?)   exit 1 ;;
	esac
done


############################################################# Execute steps

# Define the base mysql command.
MYSQL="mysql --defaults-file=/root/.my.cnf -h $DBHOST --batch --skip-column-names"

# Define our query date. Tack on three zeroes to match the milliseconds
DATE=`date --date="$AGE ago" +%s000`

# Initialize the purged counter
PURGED=0

# How many records do we want to delete?
SQL="SELECT COUNT(*) FROM audit_main WHERE time<$DATE AND audit_level != 'SEVERE';"
query "$SQL"
PURGABLE=$RESULT

if test $PURGABLE -ne 0 ; then
	verbose "Found $PURGABLE purgable records older than $AGE"
	logger -t $0 "Found $PURGABLE purgable records older than $AGE"
	if test "$PURGE" == "yes" ; then
		while [ $RESULT -ne 0 ] ; do
			# Go ahead and delete them.
			if [ $RESULT -gt $LIMIT ] ; then
				COUNT=$LIMIT
			else
				COUNT=$RESULT
			fi
			verbose -n "  ==> Purging $COUNT audit records..."
			logger -t $0 "  ==> Purging $COUNT audit records..."
			SQL="DELETE FROM audit_main WHERE time<$DATE AND audit_level != 'SEVERE' LIMIT $LIMIT;"
			query "$SQL"
			verbose ""
			PURGED=$((PURGED + $COUNT))
	
			SQL="SELECT COUNT(*) FROM audit_main WHERE time<$DATE AND audit_level != 'SEVERE';"
			query "$SQL"
		done

		verbose -n "  ==> Optimizing audit tables..."
		logger -t $0 "  ==> Optimizing audit tables..."
		SQL="OPTIMIZE TABLE audit_main, audit_admin, audit_detail, audit_detail_params, audit_message, audit_system"
		query "$SQL"
		verbose ""
	else
		verbose "None were purged"
		logger -t $0 "None were purged"
	fi
else
	verbose "No audit records older than $AGE were found"
	logger -t $0 "No audit records older than $AGE were found"
fi

# How many records are left?
SQL="SELECT COUNT(*) FROM audit_main;"
query "$SQL"
REMAINING=$RESULT
verbose "There are currently $REMAINING audit records in the database"
logger -t $0 "There are currently $REMAINING audit records in the database"

if test "$NOTIFY_SNMP_GET" == "yes" ; then
	logger -t $0 "Dumping SNMP GET style output"
	echo "${PURGABLE}:${PURGED}:${REMAINING} (purgable:purged:remaining)"
fi

exit 0
