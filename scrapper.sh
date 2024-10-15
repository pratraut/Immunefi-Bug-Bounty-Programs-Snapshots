#!/bin/bash

SLEEP_TIME=.3
start_time=`date +%s`
echo -e "#################################`date`#######################################\n"

# clear logs
# echo "" > ./logs/stdout.log
# echo "" > ./logs/stderr.log

# Get NEXT_DATA in JSON format for bug bounties
NEXT_DATA=$(curl -s https://immunefi.com/bug-bounty/ | ggrep -oP "<script id=\"__NEXT_DATA__\".*>.*</script>" | ggrep -oP "{.*}" | jq)
if [[ -z $NEXT_DATA ]]; then
	echo "ERROR: Empty NEXT_DATA"
	exit
fi

# Get bounties in a variable
projects=$(echo "$NEXT_DATA" | jq '.props.pageProps.bounties')

# Delete vault and performance metrics field
projects=$(echo "$projects" | jq -r 'del(.[].vaultBalance)' | jq -r 'del(.[].performanceMetrics)')

# Create projects.json and audit_comp_projects.json files if not exist
touch ./projects.json

# Let's see if new projects were added or paused
contents=$(< ./projects.json)
echo $contents | jq -r '.[].project' | sort > prev_projects_name.txt
# cat ./projects.json | jq -r '.[].project' | sort > prev_projects_name.txt
echo "$projects" | jq -r '.[].project' | sort > current_projects_name.txt

# Paused or Removed
paused_programs=$(comm -23 ./prev_projects_name.txt ./current_projects_name.txt | sed 's/^/#/' | xargs)
# Added or Unpaused
added_programs=$(comm -13 ./prev_projects_name.txt ./current_projects_name.txt | sed 's/^/#/' | xargs)

# Clean temporal files
rm ./prev_projects_name.txt
rm ./current_projects_name.txt

if [[ -z $projects ]]; then
	echo "ERROR: Empty projects"
	exit
fi

# Save current bounties
echo -e "$projects" > projects.json

# Get buildId
buildId=$(echo "$NEXT_DATA" | jq -r '.buildId')
if [[ -z $buildId ]]; then
	echo "ERROR: Empty buildId"
	exit
fi

echo "Bounty Build ID: $buildId"

# Create folder if not exist
test -d ./projects || mkdir ./projects

# Get how many bounties are
bounties_length=$(echo -E "$projects" | jq length)
echo "Bounties Length: $bounties_length"

for ((c = 0; c < $bounties_length; c++)); do
	# Get project's name
	name=$(echo "$projects" | jq -r .[$c].id)
	if [[ -z $name ]]; then
		echo "ERROR: Empty Name for index [$c/$bounties_length]"
		exit
	fi

	echo "Scanning: $name [`expr $c + 1`/$bounties_length]"

	# Loop for 3 times until we get the record properly
	found=false
	for ((t = 0; t < 3; t++)); do
		# Get project's data
		PROJECT_DATA=$(curl -s "https://immunefi.com/_next/data/$buildId/bug-bounty/$name/scope.json")
		echo "Calling: https://immunefi.com/_next/data/$buildId/bug-bounty/$name/scope.json"
		# echo -E "$PROJECT_DATA"
		# There's no try/catch in batch, so this is our way to double check everything went right:
		# Get name from JSON response
		name_received=$(echo "$PROJECT_DATA" | jq -r '.pageProps.bounty.id')
		# echo "Name received: $name_received"
		# Compare it with stored name
		if [ "$name_received" = "$name" ]; then
			# All good!
			echo "$PROJECT_DATA" | jq 'del(.pageProps.project.vault)' | jq 'del(.pageProps.flags)' | jq 'del(.pageProps.project.performanceMetrics)' > ./projects/$name.json
			#Print DONE
			echo "Scanned: $name"
			sleep $SLEEP_TIME
			found=true
			break
		else
			# PANIC!
			# echo "PANIC ERROR!!! [`expr $c + 1`/$bounties_length]"
			echo "Error: name_received is empty, Try #`expr $t + 1` Retrying [`expr $c + 1`/$bounties_length]"
		fi
	done
	if [ "$found" == false ] ; then
		echo "PANIC ERROR!!! [`expr $c + 1`/$bounties_length]"
		exit
	fi
done

# --------------- AUDIT COMP. PROGRAMS ---------------

# Get NEXT_DATA in JSON format for audit competitions
NEXT_DATA_AUDIT_COMP=$(curl -s https://immunefi.com/audit-competition/ | ggrep -oP "<script id=\"__NEXT_DATA__\".*>.*</script>" | ggrep -oP "{.*}" | jq)
if [[ -z $NEXT_DATA_AUDIT_COMP ]]; then
	echo "ERROR: Empty NEXT_DATA_AUDIT_COMP"
	exit
fi

audit_competitions=$(echo "$NEXT_DATA_AUDIT_COMP" | jq '.props.pageProps.bounties')

# Delete vault and performance metrics field
audit_competitions=$(echo "$audit_competitions" | jq -r 'del(.[].vaultBalance)' | jq -r 'del(.[].performanceMetrics)')

# merged two arrays
# projects=$(jq -s 'add' <<< "$projects[@] $audit_competitions[@]")

# Create audit_competitions.json file if not exist
touch ./audit_competitions.json

# Let's see if new projects were added or paused
audit_file_contents=$(< ./audit_competitions.json)
echo $audit_file_contents | jq -r '.[].project' | sort > prev_audit_competitions_name.txt
# cat ./audit_competitions.json | jq -r '.[].project' | sort > prev_audit_competitions_name.txt
echo "$audit_competitions" | jq -r '.[].project' | sort > current_audit_competitions_name.txt

# Paused or Removed
paused_audit_programs=$(comm -23 ./prev_audit_competitions_name.txt ./current_audit_competitions_name.txt | sed 's/^/#/' | xargs)
# Added or Unpaused
added_audit_programs=$(comm -13 ./prev_audit_competitions_name.txt ./current_audit_competitions_name.txt | sed 's/^/#/' | xargs)

# Clean temporal files
rm ./prev_audit_competitions_name.txt
rm ./current_audit_competitions_name.txt

if [[ -z $audit_competitions ]]; then
	echo "ERROR: Empty audit_competitions"
	exit
fi

# Save current bounties
echo -e "$audit_competitions" > audit_competitions.json

# Get buildId
buildIdAudit=$(echo "$NEXT_DATA_AUDIT_COMP" | jq -r '.buildId')
if [[ -z $buildIdAudit ]]; then
	echo "ERROR: Empty buildIdAudit"
	exit
fi

echo "Audit Competition Build ID: $buildIdAudit"

# Create folder if not exist
test -d ./audit_competitions || mkdir ./audit_competitions

# Get how many bounties are
audit_comps_length=$(echo "$audit_competitions" | jq length)
echo "Audit Competitions Length: $audit_comps_length"

for ((c = 0; c < $audit_comps_length; c++)); do
	# Get project's name
	name=$(echo "$audit_competitions" | jq -r .[$c].id)
	if [[ -z $name ]]; then
		echo "ERROR: Empty Name for index [$c/$audit_comps_length]"
		exit
	fi

	echo "Scanning: $name [`expr $c + 1`/$audit_comps_length]"

	# Loop for 3 times until we get the record properly
	found=false
	for ((t = 0; t < 3; t++)); do
		# Get project's data
		PROJECT_DATA=$(curl -s "https://immunefi.com/_next/data/$buildIdAudit/audit-competition/$name/scope.json")
		echo "Calling: https://immunefi.com/_next/data/$buildIdAudit/audit-competition/$name/scope.json"
		# Check if its a new program for which scope.json doesn't exist
		is_found=$(echo -E "$PROJECT_DATA" | jq 'has("pageProps")')
		if [[ $is_found == false ]]; then
			echo "Not yet started. Continuing..."
			found=true
			break
		fi
		# echo -E "$PROJECT_DATA"
		# There's no try/catch in batch, so this is our way to double check everything went right:
		# Get name from JSON response
		name_received=$(echo "$PROJECT_DATA" | jq -r '.pageProps.bounty.id')
		# echo "Name received: $name_received"
		# Compare it with stored name
		if [ "$name_received" = "$name" ]; then
			# All good!
			echo "$PROJECT_DATA" | jq 'del(.pageProps.project.vault)' | jq 'del(.pageProps.flags)' | jq 'del(.pageProps.project.performanceMetrics)' > ./audit_competitions/$name.json
			#Print DONE
			echo "Scanned: $name"
			sleep $SLEEP_TIME
			found=true
			break
		else
			# PANIC!
			# echo "PANIC ERROR!!! [`expr $c + 1`/$bounties_length]"
			echo "Error: name_received is empty, Try #`expr $t + 1` Retrying [`expr $c + 1`/$audit_comps_length]"
		fi
	done
	if [ "$found" == false ] ; then
		echo "PANIC ERROR!!! [`expr $c + 1`/$audit_comps_length]"
		exit
	fi
done


# If there are any changes, commit them.
if [[ -z $(git status -s | ggrep -oP '.*.json') ]]; then
	echo "Nothing changed"
else

	# added_qty=$(echo "$added_programs" | sed '/^\s*$/d' | wc -l)
	# paused_qty=$(echo "$paused_programs" | sed '/^\s*$/d' | wc -l)
	projects_changed=$(git status -s | ggrep -oP '(?<=M projects\/).*(?=\.json)' | sed 's/^/#/' | xargs)
	audit_competitions_changed=$(git status -s | ggrep -oP '(?<=M audit_competitions\/).*(?=\.json)' | sed 's/^/#/' | xargs)
	# updated_qty=$(git status -s | grep -o -P '(?<=M project\/).*(?=\.json)' | sed '/^\s*$/d' | wc -l)

	# git status
	git_status=$(git status -s)
	echo -e "Git Status:\n$git_status"

	# Commit message
	echo -e "\n"
	mg=$(echo -e "Update\n\nProjects added or unpaused:\n$added_programs\n\nProjects removed or paused:\n$paused_programs\n\nProjects updated their program:\n$projects_changed\n\nAudit Competitons added or unpaused:\n$added_audit_programs\n\nAudit Competitions removed or paused:\n$paused_audit_programs\n\nAudit Competitions updated their program:\n$audit_competitions_changed")
	echo -e "$mg"

	# Push to github
	git add --all
	git commit -m "$mg"
	git push

fi

end_time=`date +%s`
echo -e "\nTotal run time = $(expr $end_time - $start_time) seconds"
echo -e "#################################`date`#######################################\n\n"

exit
