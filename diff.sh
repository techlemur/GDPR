#!/bin/bash

#original https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/blob/master/useful_scripts/git-diffn.sh

for file in $(git diff --name-only --diff-filter=M original/master origin/techlemur); do
	echo $file;

#git diff --color=always "$@" | 
#git --no-pager show --color=always --pretty=format:"Author: %an %nDate: %ci" --no-prefix | 
git --no-pager show --pretty=format:"Changed By: %an %nDate: %ci" --color=always --no-prefix  original/master origin/techlemur -- $file | \
gawk \
'
# -------------------------------
# Awk Program Start
# -------------------------------
BEGIN {
    # color code to turn color and text formatting OFF at this location in a string
    COLOR_OFF = "\033[m"
    # color code for the left side, or lines deleted (-); this will be auto-detected later
    color_L = ""
    # color code for the right side, or lines added (+); this will be auto-detected later
    color_R = ""
    # color code for **Context lines**, which are unchanged lines around added or deleted lines 
    # which `git diff` shows for context; this will be auto-detected later
    color_C = ""
    
    # Note that "knowing" any of the below color codes could also mean knowing that there are 
    # no color codes for these lines, because they are uncolored and unformatted. If we 
    # are able to detect that, we know that the code is empty/nonexistant, so we will set these 
    # values to "true" in that case as well since we "know" the color code.
    # true if the -/left (deletion) color code is known; false otherwise
    color_L_known = "false"
    # true if the +/right (addition) color code is known; false otherwise
    color_R_known = "false"
    # true if the Context line color code is known; false otherwise
    color_C_known = "false"
}
{
    raw_line = $0
}




# 1. First, find an uncolored or (usually cyan) colored line like this which indicates the 
# line numbers: `@@ -159,6 +159,13 @@`
match(raw_line, /^(\033\[1m)?(diff|index).*/, array) {
    # The array indices below are according to the parenthetical group number in the regex
    #print raw_line
	next
}

match(raw_line, /^.*(\+\+\+|\-\-\-)[\s]*(.*)/, array) {
	filename = array[2]
	next
}



# 1. First, find an uncolored or (usually cyan) colored line like this which indicates the 
# line numbers: `@@ -159,6 +159,13 @@`
match(raw_line, /^(\033\[(([0-9]{1,2};?){1,10})m)?@@ -([0-9]+),[0-9]+ \+([0-9]+),[0-9]+ @@/, array) {
    # The array indices below are according to the parenthetical group number in the regex
    # above; see: 
    # https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html#index-match_0028_0029-function
    left_num = array[4]  # left (deletion) starting line number
    right_num = array[5] # right (addition) starting line number
    #print raw_line
	print filename
    # for debugging the array capture group indices above
    #printf "===left_num = %i, right_num = %i===\n", left_num, right_num 
    next
}


# 2. Match uncolored or colored (usually white) lines like this:
#   `--- a/my/file` and `+++ b/my/file`, as well as ANY OTHER LINE WHICH DOES
# *NOT* BEGIN WITH A -, +, or space (optional color code at the start accounted for).
/^(\033\[(([0-9]{1,2};?){1,10})m)?(--- a\/|\+\+\+ b\/|[^-+ \033])/ {
    print raw_line
    next 
}
# 3. Match lines beginning with a minus (`-`), plus (`+`), or space (` `), optionally with
# ANY color code in front of them too
# match lines deleted (-)
# Check to see if raw_line matches this regexp
/^(\033\[(([0-9]{1,2};?){1,10})m)?-/ {
    # Detect the color code if we dont yet know it
    if (color_L_known == "false") {
        match_index = match(raw_line, /^(\033\[(([0-9]{1,2};?){1,10})m)?/, array)
        if (match_index > 0) {
            # `git diff` color is ON, so lets save the color being used!
            # Index zero stores the string matched by regexp: "...the zeroth element of array 
            # is set to the entire portion of string matched by regexp." See:
            # https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html#index-match_0028_0029-function
            color_L = array[0]
        }
        # Set this to true in BOTH CASES because if a match was found above, we now know the color 
        # code, and if a match was NOT found, we now know these lines are NOT color-coded!
        color_L_known = "true"
    }
    if (color_L == "") {
        color_off = ""
    }
    else {
        color_off = COLOR_OFF
    }
	outputcheck = match(raw_line, /^(\033\[(([0-9]{1,2};?){1,10})m)?([\+\-])(.*)/, outputarray)
	if (outputcheck > 0) {
		output = outputarray[1]outputarray[5]
	}else{
		output = "raw"raw_line
	}
	#output = "test"raw_line
    # Print a **deleted line** with the appropriate colors based on whatever `git diff` is using
    printf color_L"-%+4s     "color_off":%s\n", left_num, output
    left_num++
    next
}
# match lines added (+)
# Check to see if raw_line matches this regexp
/^(\033\[(([0-9]{1,2};?){1,10})m)?\+/ {
    # Detect the color code if we dont yet know it
    if (color_R_known == "false") {
        match_index = match(raw_line, /^(\033\[(([0-9]{1,2};?){1,10})m)?/, array)
        if (match_index > 0) {
            color_R = array[0]
        }
        color_R_known = "true"
    }
    if (color_R == "") {
        color_off = ""
    }
    else {
        color_off = COLOR_OFF
    }
	outputcheck = match(raw_line, /^(\033\[(([0-9]{1,2};?){1,10})m)?([\+\-])(.*)/, outputarray)
	if (outputcheck > 0) {
		output = outputarray[1]outputarray[5]
	}else{
		output = "raw"raw_line
	}
    # Print an **added line** with the appropriate colors based on whatever `git diff` is using
    printf color_R"+     %+4s"color_off":%s\n", right_num, output
    right_num++
    next
}
# match lines not changed (these begin with an empty space ` `)
# These lines have no color or other attribute formatting by default (such as bold, italics, etc),
# but the user can add this in their git config settings if desired, so we must be able to handle
# color and attribute formatting on this text too.
# Check to see if raw_line matches this regexp
/^(\033\[(([0-9]{1,2};?){1,10})m)? / {
    # Detect the color code if we dont yet know it
    if (color_C_known == "false") {
        match_index = match(raw_line, /^(\033\[(([0-9]{1,2};?){1,10})m)?/, array)
        if (match_index > 0) {
            color_C = array[0]
        }
        color_C_known = "true"
    }
    if (color_C == "") {
        color_off = ""
    }
    else {
        color_off = COLOR_OFF
    }
    # Print a **context line** with the appropriate colors based on whatever `git diff` is using
    #printf color_C" %+4s,%+4s"color_off":%s\n", left_num, right_num, raw_line
    left_num++
    right_num++
    next
}

#match(raw_line, /^(\+|\-)(.*)(:)[\+\-](.*)/, array) {
#/^(\+|\-)(.*)(:)[\+\-](.*)/ {
#	#print "nope"
#	next
#}

# 4. Error-checking for sanity: this code should never be reached
{
    print "============== GIT DIFFN ERROR =============="
    print "THIS CODE SHOULD NEVER BE REACHED! If you see this, open up an issue for `git diffn`"
    print "  here: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles/issues"
    print "  It may be because you have some custom `git config` color or text formatting settings"
    print "  or something, which perhaps I am failing to handle correctly."
    print "Raw line: "raw_line
    print "============================================="
}
# -------------------------------
# Awk Program End
# -------------------------------
# Note that we are piping the output to `less` with -R to interpret ANSI color codes, -F to 
# quit immediately if the output takes up less than one-screen, and -X to not clear
# the screen when less exits! This way `git diffn` will provide exactly identical behavior
# to what `git diff` does! See:
# 1. https://stackoverflow.com/questions/2183900/how-do-i-prevent-git-diff-from-using-a-pager/14118014#14118014
# 2. https://unix.stackexchange.com/questions/38634/is-there-any-way-to-exit-less-without-clearing-the-screen/38638#38638
' \

done
exit