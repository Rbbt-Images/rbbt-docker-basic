#!/bin/bash -x

echo "RUNNING PROVISION"
echo
echo "CMD: build_rbbt_provision_sh.rb -ss -sr -sb --nocolor --nobar"

echo "1. Provisioning base system"
echo SKIPPED
echo

echo "2. Setting up ruby"
echo SKIPPED
echo

echo "3. Setting up gems"
#!/bin/bash -x

# RUBY GEMS and RBBT
# =================

export REALLY_GEM_UPDATE_SYSTEM=true
env REALLY_GEM_UPDATE_SYSTEM=true gem update --no-ri --no-rdoc --system
gem install --force --no-ri --no-rdoc ZenTest
gem install --force --no-ri --no-rdoc RubyInline

# R (extra config in gem)
gem install --conservative --no-ri --no-rdoc rsruby -- --with-R-dir=/usr/lib/R --with-R-include=/usr/share/R/include --with_cflags="-fPIC -g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Wall -fno-strict-aliasing"

# Java (extra config in gem)
export JAVA_HOME=$(echo /usr/lib/jvm/java-7-openjdk-*)
gem install --conservative --force --no-ri --no-rdoc rjb

# Rbbt and some optional gems
gem install --no-ri --no-rdoc --force \
    tokyocabinet \
    ruby-prof \
    rbbt-util rbbt-rest rbbt-dm rbbt-text rbbt-sources rbbt-phgx rbbt-GE \
    rserve-client \
    uglifier therubyracer kramdown\
    puma

# Get good version of lockfile
wget http://ubio.bioinfo.cnio.es/people/mvazquezg/lockfile-2.1.4.gem -O /tmp/lockfile-2.1.4.gem
gem install --no-ri --no-rdoc /tmp/lockfile-2.1.4.gem



echo "4. Configuring user"
####################
# USER CONFIGURATION

if [[ 'rbbt' == 'root' ]] ; then
  home_dir='/root'
else
  useradd -ms /bin/bash rbbt
  home_dir='/home/rbbt'
fi

user_script=$home_dir/.rbbt/bin/config_user
mkdir -p $(dirname $user_script)
chown -R rbbt /home/rbbt/.rbbt/


# set user configuration script
cat > $user_script <<'EUSER'

. /etc/profile

echo "4.1. Loading custom variables"
export RBBT_LOG="0"
export BOOTSTRAP_WORKFLOWS="Enrichment Translation Sequence MutationEnrichment"
export REMOTE_RESOURCES="KEGG"
export RBBT_NOCOLOR="true"
export RBBT_NO_PROGRESS="true"

echo "4.2. Loading default variables"
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



echo "4.3. Configuring rbbt"
#!/bin/bash -x

# USER RBBT CONFIG
# ================

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

EUSER

echo "4.4. Running user configuration as 'rbbt'"
chown rbbt $user_script;
su -l -c "bash $user_script" rbbt

echo "5. Bootstrapping workflows as 'rbbt'"
echo
echo SKIPPED
echo

# CODA
# ====

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



echo
echo "Installation done."
