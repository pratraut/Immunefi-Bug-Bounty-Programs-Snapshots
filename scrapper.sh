#!/bin/bash

# Get NEXT_DATA in JSON format for bug bounties
NEXT_DATA=$(curl -s https://immunefi.com/bug-bounty/ | grep -o "<script id=\"__NEXT_DATA__\" type=\"application/json\">.*</script>" | grep -o "{.*}" | jq)

# Get bounties in a variable
projects=$(echo -E "$NEXT_DATA" | jq '.props.pageProps.bounties')

# Create projects.json and boost_projects.json files if not exist
touch ./projects.json

# Let's see if new projects were added or paused
cat ./projects.json | jq -r '.[].project' | sort > prev_projects_name.txt
echo -E "$projects" | jq -r '.[].project' | sort > current_projects_name.txt

# Paused or Removed
paused_programs=$(comm -23 ./prev_projects_name.txt ./current_projects_name.txt | sed 's/^/#/' | sed -r 's/\s+//g' | xargs)
# Added or Unpaused
added_programs=$(comm -13 ./prev_projects_name.txt ./current_projects_name.txt | sed 's/^/#/' | sed -r 's/\s+//g' | xargs)

# Clean temporal files
rm ./prev_projects_name.txt
rm ./current_projects_name.txt

# Save current bounties
echo -E "$projects" > projects.json

# Get buildId
buildId=$(echo -E "$NEXT_DATA" | jq -r '.buildId')

# Create folder if not exist
test -d ./project || mkdir ./project

# Get how many bounties are
bounties_length=$(echo -E "$projects" | jq length)

for ((c = 400; c <= $bounties_length - 1; c++)); do
	# Get project's name
	name=$(echo -E "$projects" | jq -r .[$c].id)
	echo -E "Scanning: $name [$c/$bounties_length]"
	# Get project's data
	PROJECT_DATA=$(curl -s "https://immunefi.com/_next/data/$buildId/bug-bounty/$name.json")
	echo -E "Calling: https://immunefi.com/_next/data/$buildId/bug-bounty/$name.json"
	# echo -E "$PROJECT_DATA"
	# There's no try/catch in batch, so this is our way to double check everything went right:
	# Get name from JSON response
	name_received=$(echo -E "$PROJECT_DATA" | jq -r '.pageProps.bounty.id')
	echo -E "Name received: $name_received [$c/$bounties_length]"
	# Compare it with stored name
	if [ "$name_received" = "$name" ]; then

		# All good!
		echo -E "$PROJECT_DATA" | jq 'del(.pageProps.project.vault)' > ./project/$name.json
		#Print DONE
		echo -E "Scanned: $name [$c/$bounties_length]"
		sleep .3

	else
		# PANIC!
		echo -E "PANIC ERROR!!! [$c/$bounties_length]"
		break
	fi
done

# --------------- BOOST PROGRAMS ---------------

# Get NEXT_DATA in JSON format for boosted bug bounties
NEXT_DATA_BOOST=$(curl -s https://immunefi.com/boost/ | grep -o "<script id=\"__NEXT_DATA__\" type=\"application/json\">.*</script>" | grep -o "{.*}" | jq)

boost_projects=$(echo -E "$NEXT_DATA_BOOST" | jq '.props.pageProps.bounties')

# merged two arrays
# projects=$(jq -s 'add' <<< "$projects[@] $boost_projects[@]")

# Create boost_projects.json file if not exist
touch ./boost_projects.json

# Let's see if new projects were added or paused
cat ./boost_projects.json | jq -r '.[].project' | sort > prev_boost_projects_name.txt
echo -E "$boost_projects" | jq -r '.[].project' | sort > current_boost_projects_name.txt

# Paused or Removed
paused_boost_programs=$(comm -23 ./prev_boost_projects_name.txt ./current_boost_projects_name.txt | sed 's/^/#/' | sed -r 's/\s+//g' | xargs)
# Added or Unpaused
added_boost_programs=$(comm -13 ./prev_boost_projects_name.txt ./current_boost_projects_name.txt | sed 's/^/#/' | sed -r 's/\s+//g' | xargs)

# Clean temporal files
rm ./prev_boost_projects_name.txt
rm ./current_boost_projects_name.txt

# Save current bounties
echo -E "$boost_projects" > boost_projects.json

# Get buildId
buildIdBoost=$(echo -E "$NEXT_DATA_BOOST" | jq -r '.buildId')

# Create folder if not exist
test -d ./boost_project || mkdir ./boost_project

# Get how many bounties are
boost_bounties_length=$(echo -E "$boost_projects" | jq length)

for ((c = 0; c <= $boost_bounties_length - 1; c++)); do
	# Get project's name
	name=$(echo -E "$boost_projects" | jq -r .[$c].id)
	echo -E "Scanning: $name [$c/$boost_bounties_length]"
	# Get project's data
	PROJECT_DATA=$(curl -s "https://immunefi.com/_next/data/$buildIdBoost/boost/$name.json")
	echo -E "Calling: https://immunefi.com/_next/data/$buildIdBoost/boost/$name.json"
	# echo -E "$PROJECT_DATA"
	# There's no try/catch in batch, so this is our way to double check everything went right:
	# Get name from JSON response
	name_received=$(echo -E "$PROJECT_DATA" | jq -r '.pageProps.bounty.id')
	echo -E "Name received: $name_received [$c/$boost_bounties_length]"
	# Compare it with stored name
	if [ "$name_received" = "$name" ]; then

		# All good!
		echo -E "$PROJECT_DATA" | jq 'del(.pageProps.project.vault)' > ./boost_project/$name.json
		#Print DONE
		echo -E "Scanned: $name [$c/$boost_bounties_length]"
		sleep .3

	else
		# PANIC!
		echo -E "PANIC ERROR!!! [$c/$boost_bounties_length]"
		break
	fi
done


# If there are any changes, commit them.
if [[ -z $(git status -s | grep -o 'project/.*') ]]; then
	echo "Nothing changed"
else

	# added_qty=$(echo "$added_programs" | sed '/^\s*$/d' | wc -l)
	# paused_qty=$(echo "$paused_programs" | sed '/^\s*$/d' | wc -l)
	projects_changed=$(git status -s | grep -o '(?<=M project\/).*(?=\.json)' | sed 's/^/#/' | xargs)
	boost_projects_changed=$(git status -s | grep -o '(?<=M boost_project\/).*(?=\.json)' | sed 's/^/#/' | xargs)
	# updated_qty=$(git status -s | grep -o -P '(?<=M project\/).*(?=\.json)' | sed '/^\s*$/d' | wc -l)

	# Commit message
	echo -e "\n"
	mg=$(echo -e "Update\n\nProjects added or unpaused:\n$added_programs\nProjects removed or paused:\n$paused_programs\nProjects updated their program:\n$projects_changed\n\nBoost Projects added or unpaused:\n$added_boost_programs\nBoost Projects removed or paused:\n$paused_boost_programs\nBoost Projects updated their program:\n$boost_projects_changed")
	echo -e "$mg"

	# Push to github
	git add --all
	git commit -m "$mg"
	git push

fi


date
exit
