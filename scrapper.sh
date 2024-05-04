#!/bin/bash

SLEEP_TIME=.3
start_time=`date +%s`
echo "#################################`date`#######################################\n"

# Get NEXT_DATA in JSON format for bug bounties
NEXT_DATA=$(curl -s https://immunefi.com/bug-bounty/ | grep -o "<script id=\"__NEXT_DATA__\" type=\"application/json\">.*</script>" | grep -o "{.*}" | jq)

# Get bounties in a variable
projects=$(echo "$NEXT_DATA" | jq '.props.pageProps.bounties')

# Create projects.json and boost_projects.json files if not exist
touch ./projects.json

# Let's see if new projects were added or paused
cat ./projects.json | jq -r '.[].project' | sort > prev_projects_name.txt
echo "$projects" | jq -r '.[].project' | sort > current_projects_name.txt

# Paused or Removed
paused_programs=$(comm -23 ./prev_projects_name.txt ./current_projects_name.txt | sed 's/^/#/' | sed -r 's/\s+//g' | xargs)
# Added or Unpaused
added_programs=$(comm -13 ./prev_projects_name.txt ./current_projects_name.txt | sed 's/^/#/' | sed -r 's/\s+//g' | xargs)

# Clean temporal files
rm ./prev_projects_name.txt
rm ./current_projects_name.txt

# Save current bounties
echo -e "$projects" > projects.json

# Get buildId
buildId=$(echo "$NEXT_DATA" | jq -r '.buildId')
echo "Bounty Build ID: $buildId"

# Create folder if not exist
test -d ./project || mkdir ./project

# Get how many bounties are
bounties_length=$(echo -E "$projects" | jq length)
echo "Bounties Length: $bounties_length"

for ((c = 0; c <= $bounties_length - 1; c++)); do
	# Get project's name
	name=$(echo "$projects" | jq -r .[$c].id)
	if [[ -z $name ]]; then
		echo "ERROR: Empty Name for index [$c/$bounties_length]"
		exit
	fi

	echo "Scanning: $name [`expr $c + 1`/$bounties_length]"
	# Get project's data
	PROJECT_DATA=$(curl -s "https://immunefi.com/_next/data/$buildId/bug-bounty/$name.json")
	echo "Calling: https://immunefi.com/_next/data/$buildId/bug-bounty/$name.json"
	# echo -E "$PROJECT_DATA"
	# There's no try/catch in batch, so this is our way to double check everything went right:
	# Get name from JSON response
	name_received=$(echo "$PROJECT_DATA" | jq -r '.pageProps.bounty.id')
	echo "Name received: $name_received [`expr $c + 1`/$bounties_length]"
	# Compare it with stored name
	if [ "$name_received" = "$name" ]; then

		# All good!
		echo "$PROJECT_DATA" | jq 'del(.pageProps.project.vault)' > ./project/$name.json
		#Print DONE
		echo "Scanned: $name [`expr $c + 1`/$bounties_length]"
		sleep $SLEEP_TIME

	else
		# PANIC!
		echo "PANIC ERROR!!! [`expr $c + 1`/$bounties_length]"
		exit
	fi
done

# --------------- BOOST PROGRAMS ---------------

# Get NEXT_DATA in JSON format for boosted bug bounties
NEXT_DATA_BOOST=$(curl -s https://immunefi.com/boost/ | grep -o "<script id=\"__NEXT_DATA__\" type=\"application/json\">.*</script>" | grep -o "{.*}" | jq)

boost_projects=$(echo "$NEXT_DATA_BOOST" | jq '.props.pageProps.bounties')

# merged two arrays
# projects=$(jq -s 'add' <<< "$projects[@] $boost_projects[@]")

# Create boost_projects.json file if not exist
touch ./boost_projects.json

# Let's see if new projects were added or paused
cat ./boost_projects.json | jq -r '.[].project' | sort > prev_boost_projects_name.txt
echo "$boost_projects" | jq -r '.[].project' | sort > current_boost_projects_name.txt

# Paused or Removed
paused_boost_programs=$(comm -23 ./prev_boost_projects_name.txt ./current_boost_projects_name.txt | sed 's/^/#/' | sed -r 's/\s+//g' | xargs)
# Added or Unpaused
added_boost_programs=$(comm -13 ./prev_boost_projects_name.txt ./current_boost_projects_name.txt | sed 's/^/#/' | sed -r 's/\s+//g' | xargs)

# Clean temporal files
rm ./prev_boost_projects_name.txt
rm ./current_boost_projects_name.txt

# Save current bounties
echo -e "$boost_projects" > boost_projects.json

# Get buildId
buildIdBoost=$(echo "$NEXT_DATA_BOOST" | jq -r '.buildId')
echo "Boost Bounty Build ID: $buildIdBoost"

# Create folder if not exist
test -d ./boost_project || mkdir ./boost_project

# Get how many bounties are
boost_bounties_length=$(echo "$boost_projects" | jq length)
echo "Boost Bounties Length: $boost_bounties_length"

for ((c = 0; c <= $boost_bounties_length - 1; c++)); do
	# Get project's name
	name=$(echo "$boost_projects" | jq -r .[$c].id)
	if [[ -z $name ]]; then
		echo "ERROR: Empty Name for index [$c/$boost_bounties_length]"
		exit
	fi

	echo "Scanning: $name [`expr $c + 1`/$boost_bounties_length]"
	# Get project's data
	PROJECT_DATA=$(curl -s "https://immunefi.com/_next/data/$buildIdBoost/boost/$name.json")
	echo "Calling: https://immunefi.com/_next/data/$buildIdBoost/boost/$name.json"
	# echo -E "$PROJECT_DATA"
	# There's no try/catch in batch, so this is our way to double check everything went right:
	# Get name from JSON response
	name_received=$(echo "$PROJECT_DATA" | jq -r '.pageProps.bounty.id')
	echo "Name received: $name_received [`expr $c + 1`/$boost_bounties_length]"
	# Compare it with stored name
	if [ "$name_received" = "$name" ]; then

		# All good!
		echo "$PROJECT_DATA" | jq 'del(.pageProps.project.vault)' > ./boost_project/$name.json
		#Print DONE
		echo "Scanned: $name [`expr $c + 1`/$boost_bounties_length]"
		sleep $SLEEP_TIME

	else
		# PANIC!
		echo "PANIC ERROR!!! [`expr $c + 1`/$boost_bounties_length]"
		exit
	fi
done


# If there are any changes, commit them.
if [[ -z $(git status -s | ggrep -oP 'project/.*') ]]; then
	echo "Nothing changed"
else

	# added_qty=$(echo "$added_programs" | sed '/^\s*$/d' | wc -l)
	# paused_qty=$(echo "$paused_programs" | sed '/^\s*$/d' | wc -l)
	projects_changed=$(git status -s | ggrep -oP '(?<=M project\/).*(?=\.json)' | sed 's/^/#/' | xargs)
	boost_projects_changed=$(git status -s | ggrep -oP '(?<=M boost_project\/).*(?=\.json)' | sed 's/^/#/' | xargs)
	# updated_qty=$(git status -s | grep -o -P '(?<=M project\/).*(?=\.json)' | sed '/^\s*$/d' | wc -l)

	# git status
	git_status=$(git status -s)
	echo -e "Git Status:\n$git_status"

	# Commit message
	echo -e "\n"
	mg=$(echo -e "Update\n\nProjects added or unpaused:\n$added_programs\nProjects removed or paused:\n$paused_programs\nProjects updated their program:\n$projects_changed\n\nBoost Projects added or unpaused:\n$added_boost_programs\nBoost Projects removed or paused:\n$paused_boost_programs\nBoost Projects updated their program:\n$boost_projects_changed")
	echo -e "$mg"

	# Push to github
	git add --all
	git commit -m "$mg"
	git push

fi

end_time=`date +%s`
echo -e "\nTotal run time = $(expr $end_time - $start_time) seconds"
echo "#################################`date`#######################################\n"

exit
