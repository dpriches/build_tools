#!/bin/bash

#-------------------------------------------------------------------------------#
#  Get most recent xx.yy.zz tag, split out major.minor number & build number.   #
#  Increment build number, create new tag & push it back to server              #
#                                                                               #
#  Assumptions                                                                  #
#   Directory specified in -d is a git repo containing a maven pom file         #
#                                                                               #
#  Date        Revision    Author            Comments                           #
#  8/3/16    1.0            Dave Riches        Initial version                  #
#  4/27/18   1.1            Dave Riches        Add -d directory param           #
#                                              Add -C option to git cmds        #
#                                              Add -f option to mvn cmds        #
#-------------------------------------------------------------------------------#

function DEBUG ()
#-------------------------------------------------------------------------------#
#                              Enable debug messaging                           #
#-------------------------------------------------------------------------------#
{
    [ "$_DEBUG" == "on" ] && $@
}

usage () {
s=${0}
cat <<EOF
usage: ${s##*/} -s <Source branch> -d <Source repo directory > -c <Commit ID> -v <Version>

    -d Directory - required. Directory containing repo
    -s Source Branch - required. Source branch to create new branch from
    -c Commit ID - optional; uses latest commit from Source Branch if ommitted. Use 7 digit ID
    -v Version - optional; must be of form x.y.z

e.g.
    ${s##*/} -s dev -d /var/tmp/project
    ${s##*/} -s dev -c d1994ed -v 5.2.1 -d /var/tmp/myrepo
EOF
}

REQFLAGCOUNT=0
VERSIONFORMAT="[0-9]+\.[0-9]+\.[0-9]+"
CREATEMAINTBRANCH=false

#-------------------------------------------------------------------------------#
#        Get required/optional params, verify # of reqd params are there        #
#-------------------------------------------------------------------------------#

while getopts c:d:s:v: option
do
        case "${option}"
        in
            c) REVISION=${OPTARG}
              TMPVAL=$(echo $REVISION | wc -c)
              if [ $TMPVAL -ne 8 ]
              then 
                  usage;
                  exit 1
              fi
              ;;
              
            d) SRCDIR=${OPTARG}
              if [ ! -d $SRCDIR ] 
              then 
                echo "Project directory not found"
              else
                ((REQFLAGCOUNT++))
              fi
              ;;
              
            s) SRCBRANCH=${OPTARG}
              ((REQFLAGCOUNT++))
              ;;
              
            v) BRANCHNAME=${OPTARG}            
              TMPVAL=$(echo $BRANCHNAME | egrep "${VERSIONFORMAT}" | wc -l)
              if [ $TMPVAL -ne 1 ]
              then 
                  usage;
                  exit 1
              fi
              ;;
              
            \?) usage;
                exit 1
                ;;
        esac
done

if [ $REQFLAGCOUNT -ne 2 ]
then
    usage
    exit 1
fi

#-------------------------------------------------------------------------------#
# If BRANCHNAME variable not set, check repo for branch pattern. If no existing #
# branch, start with 1.0.0, otherwise set to <current major>.<incremented       #
# branch>.0.                                                                    #    
# If BRANCHNAME is set, check it's not already present                          #
#-------------------------------------------------------------------------------#
_DEBUG='off'
DEBUG echo "SRCDIR: $SRCDIR"

echo -e "\nSwitching to $SRCBRANCH..."
git -C ${SRCDIR} checkout $SRCBRANCH
if [ $? -ne 0 ]
then
    echo "ERROR: Can't switch to branch $SRCBRANCH...exiting"
    exit 1
fi


if [ -z "$BRANCHNAME" ]
then

# Get current branch, sort numerically to get most recent version
    CURPOMVERSION=$(cat ${SRCDIR}/pom.xml | xpath "/project/version/text()" 2>/dev/null | cut -f1,2 -d. | sed "s/-SNAPSHOT//")
    CURBLDNUM=$(git -C ${SRCDIR} branch -r | egrep "origin/${VERSIONFORMAT}$" | grep "origin/$CURPOMVERSION" | sort --version-sort | tail -1)
    DEBUG echo "CURPOMVERSION: $CURPOMVERSION"
    DEBUG echo "CURBLDNUM: $CURBLDNUM"

    if [ -z $CURBLDNUM ]
    then

        BRANCHNAME="${CURPOMVERSION}.0"
        echo "No branch found, setting first branch value to ${BRANCHNAME}"

    else

        echo "Most recent branch is $CURBLDNUM"

        BRANCHNUM=$(echo $CURBLDNUM | cut -f3 -d\.)
        ((BRANCHNUM++))
        BRANCHNAME="${CURPOMVERSION}.${BRANCHNUM}"
        echo "New branch is $BRANCHNAME"
    fi
    
else

    git -C ${SRCDIR} branch -r | grep ${BRANCHNAME} > /dev/null 2>&1
    retval=$?
    
    if [ $retval -eq 0 ] 
    then
    
        echo "ERROR: Branch ${BRANCHNAME} already exists in repo"
        exit 1
        
    fi
fi

#-------------------------------------------------------------------------------#
#             If no revision provided, get latest from source branch                #
#-------------------------------------------------------------------------------#

if [ -z "$REVISION"]
then
    REVISION=$(git -C ${SRCDIR} --no-pager log --oneline -1 | cut -c1-7)
fi

echo -e "\nCreating branch ${BRANCHNAME} from revision ${REVISION}..."
git -C ${SRCDIR} branch ${BRANCHNAME} ${REVISION}
if [ $? -ne 0 ]
then
    echo "ERROR: Can't create branch $BRANCHNAME...exiting"
    exit 1
fi

git -C ${SRCDIR} checkout ${BRANCHNAME}

#-------------------------------------------------------------------------------#
#                Update POM files, check code back into new branch                #
#-------------------------------------------------------------------------------#

echo -e "\nUpdating POM file versions..."

# update src code pom tree, also create-rpms tree which is separate from src tree
mvn versions:set -DnewVersion=${BRANCHNAME}  -DgenerateBackupPoms=false -f ${SRCDIR}/pom.xml
git -C ${SRCDIR} commit -am "Auto: Set POM version number to ${BRANCHNAME}"


#-------------------------------------------------------------------------------#
#                  Send new branch back to origin repo            #
#-------------------------------------------------------------------------------#

echo ""
echo "Pushing branch to origin..."
git -C ${SRCDIR} push origin $BRANCHNAME
if [ $? -ne 0 ]
then
    echo "ERROR: Can't push branch to origin repo...exiting"
    exit 1
fi

echo ""
echo "Done"
