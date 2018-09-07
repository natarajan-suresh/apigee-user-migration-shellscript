#!/bin/bash
# This script is very useful to create , migrate whole user and roles from one cluster to other
# usage: ./apigee-utility-user-migration.sh <Options=add|remove|migrate> <from_apigee url> <to_apigee2 url> <username> <password>  <environment> 
# example 1: ./apigee-utility-user-migration.sh migrate http://apigee-dev-mgmt-server:8080 http://apigee-stage-mgmt-server:8080 user@apigee.com A1ndi@123 stage

 ## Add users from /tmp/apigee_user_list.txt
_add_users_from_file()
{

if [[ "$filename" == "" ]]; then
	filename="./apigee_user_list.txt"
fi

if [[ -f $filename ]] ; then
    echo "The file $filename exists. Adding/Migrating userid from this file."
	ignoreFileMsg="The file $filename exists. Adding/Migrating userid from this file."

	#exists=$(grep -F -c $name $filename)
	#if [[ $exists -gt 0 ]]; then
	#	echo "name found"
	#fi
	## Read file api list and remove from unused proxy list
	while IFS=$'\t\r\n' read -r -a userid || [[ -n "$line" ]]; do
		#echo "Name read from file - $userid"
		list_of_users="$list_of_users <br>$userid"
		userid=`echo -n $userid | tr -d "\n"`
		_add_users $userid
		
	done < "$filename"
	echo $list_of_users
	_hipchat_notification "batch"
else
    echo "The file $filename does not exist. Please create a file and put usedid in it."
    ignoreFileMsg="The file $filename does not exist."
	return 0
fi
}

## add users

 _add_users()
{
userid=$1

	if [[ "$userid" != "" ]]; then
	echo " Adding user : $userid to apigee $apigeeurl2"

	curl -X POST -s -u $username:$password $apigeeurl2/v1/users  --header "Content-Type: application/json" -d "{  \
   \"firstName\" : \"$userid\", \
   \"lastName\" : \"User\", \
   \"password\" : \"Test#123\", \
   \"emailId\" : \"$userid\" \
   }"
   
   ### OR use the below xml format to add new user
   # <User>
   # <FirstName>temp</FirstName>
   # <LastName>user</LastName>
   # <Password>1qaz2Wsx</Password>
   # <EmailId>testaccount2@apigee.com</EmailId>
   # </User>

			role="businessuser"
			if	 curl --fail -s -X POST -H "Content-Type:application/x-www-form-urlencoded" -u $username:$password $apigeeurl2/v1/o/$org/userroles/$role/users?id=$userid; then
				echo "$userid has been associated with role : $role successsfully."
			else
				echo "$userid is failed to associate with role  :$role"
			fi
			role="opsadmin"
			if	 curl --fail -s -X POST -H "Content-Type:application/x-www-form-urlencoded" -u $username:$password $apigeeurl2/v1/o/$org/userroles/$role/users?id=$userid; then
				echo "$userid has been associated with role : $role successsfully."
			else
				echo "$userid is failed to associate with role  :$role"
			fi
			role="orgadmin"
			if	 curl --fail -s -X POST -H "Content-Type:application/x-www-form-urlencoded" -u $username:$password $apigeeurl2/v1/o/$org/userroles/$role/users?id=$userid; then
				echo "$userid has been associated with role : $role successsfully."
			else
				echo "$userid is failed to associate with role  :$role"
			fi
			role="user"
			if	 curl --fail -s -X POST -H "Content-Type:application/x-www-form-urlencoded" -u $username:$password $apigeeurl2/v1/o/$org/userroles/$role/users?id=$userid; then
				echo "$userid has been associated with role : $role successsfully."
			else
				echo "$userid is failed to associate with role  :$role"
			fi
   	echo " "
	echo "User : $userid has been successfully added to apigee $apigeeurl2"
	_hipchat_notification "single"
  fi 

 return 0				
}

## remove users

 _remove_users()
{
userid=$1
	if [[ "$userid" != "" ]]; then
		echo " Removing user : $userid from apigee $apigeeurl2"

		if [[ "$userid" != "admin@apigee.com" ]]; then
			if [[ "$option" == "remove" ]]; then

				if curl --fail -s -X DELETE -u $username:$password $apigeeurl2/v1/users/$userid; then
					echo "Removed user : $userid from apigee $env"
				else
					echo "Failed to remove $userid afrom apigee $env"
				fi
			fi
		fi
	else
	
	users=$(curl -s -u $username:$password $apigeeurl2/v1/users ) #| python -c "import sys, json; print(json.load(sys.stdin)['user'][0]['name'])" )
	echo "Removing users from $apigeeurl2"
	if [[ "$users" != "" ]]; then
	for i in {0..500}  # loop should break if index out of bounds
	do
		if userid=$(python -c "import sys, json; n = json.dumps($users); print(json.loads(n)['user'][$i]['name'])" ); then
		if [[ "$userid" != "" ]]; then
		if [[ "$userid" != "admin@apigee.com" ]]; then

		if [[ "$option" == "remove" ]]; then	 
		 	if curl --fail -s -X DELETE -u $username:$password $apigeeurl2/v1/users/$userid; then
					echo "Removed user : $userid from apigee $env"
				else
					echo "Failed to remove $userid afrom apigee $env"
			fi
			
		fi	
		fi
		fi

		else
		echo "List of users processed = $i "
		echo "WARNING: Maximum 500 users will be removed at a time. re-run this script to clean up if more than 500 users there."
		break
		fi
	done
	fi
    fi 
 return 0				
}
# Migrate/Copy users & roles associated from one LDAP/Apigee server to another 
 _migrate_users()
 {

 userroles=$(curl -s -u $username:$password $apigeeurl/v1/o/$org/userroles)
if [[ "$userroles" != "" ]]; then
 echo "Available userroles for $org"
  IFS=",['] \" "
  for role in $userroles
  do
	if [[ "$role" != "" ]]; then
	users=$(curl -s -u $username:$password $apigeeurl/v1/o/$org/userroles/$role/users)
	if [[ "$users" != "" ]]; then
	echo "Available users for $org"
	IFS=",['] \" "
	for userid in $users
	do
		if [[ "$userid" != "" ]]; then
		if [[ "$option" == "migrate" ]]; then
		    ### Add/migrate users
			_add_users $userid
			if	 curl --fail -s -X POST -H "Content-Type:application/x-www-form-urlencoded" -u $username:$password $apigeeurl2/v1/o/$org/userroles/$role/users?id=$userid; then
				echo "$userid has been associated with role : $role successsfully."
			else
				echo "$userid is failed to associate with role  :$role"
			fi
		 else   
		    #### Delete user
			if [[ "$userid" != "admin@apigee.com" ]]; then
			if [[ "$option" == "remove" ]]; then
			_remove_users $userid
			fi
			fi
		 fi
		 fi
	done
	fi 
	fi 
  done
 fi 
 return 0
 }

 _list_users()
 {
 	users=$(curl -s -u $username:$password $apigeeurl/v1/users )
	echo "Fetching users from $apigeeurl"
	echo "### Apigee Users from $apigeeurl" |& tee ./apigee_user_list.txt
	if [[ "$users" != "" ]]; then
	for i in {0..1000}  # loop should break if index out of bounds
	do
		if userid=$(python -c "import sys, json; n = json.dumps($users); print(json.loads(n)['user'][$i]['name'])" ); then
			if [[ "$userid" != "" ]]; then
				echo -e "$userid" |& tee -a ./apigee_user_list.txt
			fi
		else
			echo -e "\nList of users processed = $i "
			echo -e "\nWARNING: Maximum 1000 users will be fetched at a time."
			break
		fi
	done
	fi
 }
_apigee_users_migration()
{
option=$1
apigeeurl=$2
apigeeurl2=$3
username=$4
password=$5
userid=$6
env=$7
filename=""
testOnly=""
list_of_users=""
echo .
echo "$(date) === Apigee User and Roles migration to  $2 ======= " 
usedProxies=""
unUsedProxies=""
ndays="0"
org="dfw"
cleanAllNoTrafficProxies="false"
ignoreFileMsg=""
if [[ "$filename" == "" ]]; then
	filename="./apigee_user_list.txt"
fi
if [[ "$testOnly" == "" ]]; then
	testOnly="true"
fi
if [[ "$1" == "" ]]; then
	option="list"
	else
	option="$1"
fi
if [[ "$option" == "migrate" ]]; then
apigeeurl=$2
apigeeurl2=$3
username=$4
password=$5
userid=$6
env=$7
if [[ "$apigeeurl" == "" ]] && [[ "$apigeeurl2" == "" ]] && [[ "$username" == "" ]] &&[[ "$password" == "" ]]; then
	echo " usage: ./apigee-utility-user-migration.sh <option =add|remove|migrate> <apigee mgmt server from_url> <apigee mgmt to_url> <username> <password> <userid>"
	echo " example 1: ./apigee-utility-user-migration.sh http://api-dev.apigee.com:8080 http://api-stage.apigee.com:8080 user@apigee.com A1ndi@123 new-user@apigee.com"
	exit
fi
else
	apigeeurl=""
	apigeeurl2=$2
	username=$3
	password=$4
	userid=$5
	env=$6
	if [[ "$apigeeurl2" == "" ]] && [[ "$username" == "" ]] &&[[ "$password" == "" ]]; then
		echo " usage: ./apigee-utility-user-migration.sh <option =add|remove|migrate> <apigee mgmt server to_url> <username> <password> <usedid>"
		echo " example 1: ./apigee-utility-user-migration.sh http://api-dev-ui.apigee.com:8080 user@apigee.com A1ndi@123 new-user@apigee.com"
		exit
	fi
fi
if [[ "$env" == "" ]]; then
	env="Apigee"
fi
echo "	option		=	$option"
echo "	apigeeurl	=	$apigeeurl"
echo "	apigeeurl2	=	$apigeeurl2"
echo "	username	=	$username"
echo "	userid		=	$userid"
echo "	env			=	$env"

if [[ "$option" == "migrate" ]]; then
	option="migrate"
	userid=$6
	_migrate_users
fi
if [[ "$option" == "add" ]]; then
	apigeeurl2=$2
	userid=$5
	apigeeurl=""
	if [[ "$userid" == "" ]]; then
	_add_users_from_file
	else
	_add_users $userid
	fi
fi
if [[ "$option" == "remove" ]]; then
	apigeeurl2=$2
	userid=$5
	apigeeurl=""
	_remove_users ""
fi

if [[ "$option" == "" ]] || [[ "$option" == "list" ]]; then
	apigeeurl=$2
	_list_users
fi 
}


# Migrate user and roles Main  
#uncomment the below function calls to execute this script 
# usage: ./apigee-utility-user-migration.sh <option =add|remove|migrate|list> <apigee mgmt server to_url> <username> <password> <usedid>

clear
#_apigee_users_migration "$1" "$2" "$3" "$4" "$5" "$6" "$7" |& tee -a ./apigee_user_migration.log



#For Example  - Uncomment below applicable line to work with
#Sample Environment : Update you dev or stage apigee mgmt server IP or URL here
# Add given single user or provided with a user file
#_apigee_users_migration "list" "http://apigee-dev-mgmt-server.apigee.com:8080" "admin@apigee.com" "Apigee#123" "" "dev" |& tee  /tmp/apigee_user_migration.log

#Sample Environment : Copy or migrate users from one env to other env apigee cluster
#_apigee_users_migration "migrate" "http://api-dev-apigee.com:8080" "http://api-stage.apigee.com:8080" "admin@apigee.com" "Apigee#123" "" |& tee  ./apigee_user_migration.log
