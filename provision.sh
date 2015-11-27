cat "$0"
echo "Running provisioning"
echo


# BASE SYSTEM
echo "1. Provisioning base system"


# BASE SYSTEM
echo "2. Setting up ruby"


# BASE SYSTEM
echo "2. Setting up gems"
#!/bin/bash -x

# Ruby gems and Rbbt
# -------------------------
export REALLY_GEM_UPDATE_SYSTEM=true
env REALLY_GEM_UPDATE_SYSTEM=true gem update --system
gem install --force ZenTest
gem install --force RubyInline

# R (extra config in gem)
gem install --conservative --no-ri --no-rdoc rsruby -- --with-R-dir=/usr/lib/R --with-R-include=/usr/share/R/include --with_cflags="-fPIC -g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Wall -fno-strict-aliasing"

# Java (extra config in gem)
export JAVA_HOME=$(echo /usr/lib/jvm/java-7-openjdk-*)
gem install --conservative --force --no-ri --no-rdoc rjb

# Rbbt and some optional gems
gem install --no-ri --no-rdoc --force \
    rbbt-util rbbt-rest rbbt-dm rbbt-text rbbt-sources rbbt-phgx rbbt-GE \
    tokyocabinet \
    rserve-client \
    uglifier therubyracer kramdown\
    ruby-prof

# Get good version of lockfile
wget http://ubio.bioinfo.cnio.es/people/mvazquezg/lockfile-2.1.4.gem -O /tmp/lockfile-2.1.4.gem
gem install /tmp/lockfile-2.1.4.gem





####################
# USER CONFIGURATION

if [[ 'rbbt' == 'root' ]] ; then
  home_dir='/root'
else
  useradd -ms /bin/bash rbbt
  home_dir='/home/rbbt'
fi

user_script=$home_dir/.rbbt/bin/provision
mkdir -p $(dirname $user_script)
chown -R rbbt /home/rbbt/.rbbt/
cat > $user_script <<'EUSER'

. /etc/profile

echo "2.1. Custom variables"
export RBBT_LOG="0"
export BOOTSTRAP_WORKFLOWS="Enrichment Translation Sequence MutationEnrichment"
export REMOTE_RESOURCES="KEGG"

echo "2.2. Default variables"
#!/bin/bash -x

test -z ${RBBT_SERVER+x}           && RBBT_SERVER=http://rbbt.bioinfo.cnio.es/ 
test -z ${RBBT_FILE_SERVER+x}      && RBBT_FILE_SERVER="$RBBT_SERVER"
test -z ${RBBT_WORKFLOW_SERVER+x}  && RBBT_WORKFLOW_SERVER="$RBBT_SERVER"

test -z ${REMOTE_RESOURCES+x}  && REMOTE_RESOURCES="Organism ICGC COSMIC KEGG InterPro"
test -z ${REMOTE_WORFLOWS+x}   && REMOTE_WORFLOWS=""

test -z ${RBBT_WORKFLOW_AUTOINSTALL+x}  && RBBT_WORKFLOW_AUTOINSTALL="true"

test -z ${WORKFLOWS+x}  && WORKFLOWS=""

test -z ${BOOTSTRAP_WORKFLOWS+x}  && BOOTSTRAP_WORKFLOWS=""
test -z ${BOOTSTRAP_CPUS+x}       && BOOTSTRAP_CPUS="2"

test -z ${RBBT_LOG+x}  && RBBT_LOG="LOW"



echo "2.3. Configuring rbbt"
#!/bin/bash -x

# GENERAL
# -------

# File servers: to speed up the production of some resources
for resource in $REMOTE_RESOURCES; do
    echo "Adding remote file server: $resource -- $RBBT_FILE_SERVER"
    rbbt file_server add $resource $RBBT_FILE_SERVER
done

# Remote workflows: avoid costly cache generation
for workflow in $REMOTE_WORKFLOWS; do
    echo "Adding remote workflow: $workflow -- $RBBT_WORKFLOW_SERVER"
    rbbt workflow remote add $workflow $RBBT_WORKFLOW_SERVER
done


exit

echo "2.4. Bootstrap system"
#!/bin/bash -x

# APP
# ---

for workflow in $WORKFLOWS; do
    rbbt workflow install $workflow 
done

export RBBT_WORKFLOW_AUTOINSTALL
export RBBT_LOG

for workflow in $BOOTSTRAP_WORKFLOWS; do
    echo "Bootstrapping $workflow on $BOOTSTRAP_CPUS CPUs"
    rbbt workflow cmd $workflow bootstrap $BOOTSTRAP_CPUS
done


EUSER
####################
echo "2. Running user configuration as 'rbbt'"
chown rbbt $user_script;
su -l -c "bash $user_script" rbbt

# DONE
echo
echo "Installation done."

#--------------------------------------------------------

