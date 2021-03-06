#!/usr/bin/env bash

set -eux

# Install and configure r10k

if [ "${FEATURE_R10K}" == "true" ]
then

    # Install r10k

    set +e
    GEMINSTALL=`gem install r10k 2>&1`

    if [ $? -ne 0 ]
    then
        DEPERROR=`echo ${GEMINSTALL} | grep "requires semantic_puppet" | wc -l`
        if [ ${DEPERROR} -ne 0 ]
        then
            gem install puppet_forge -v 2.2.6
            gem install r10k
        else
            echo "Error installing r10k: ${GEMINSTALL}"
            exit 1
        fi
    fi
    set -e

    if [ ! -e "${PUPPET_CONFDIR}" ]
    then
        mkdir "${PUPPET_CONFDIR}"
    fi

    cd "${PUPPET_CONFDIR}"

    mkdir r10k

    cat > r10k/r10k.yaml <<EOL
sources:
    mysource:
        basedir: ${PUPPET_ENVDIR}
EOL

    if [ ${FEATURE_R10K_CUSTOM} == "true" ]
    then

        if [ ! -e /tmp/files/r10k.provision ]
        then
            echo "r10k.provision SSH private key file not found."
            exit 1
        fi

        if [ ! -x /root/.ssh ]
        then
            mkdir /root/.ssh
            chmod 0700 /root/.ssh
        fi

        # Setting up connection to custom r10k module repository server

        mv /tmp/files/r10k.provision /root/.ssh
        chmod 0600 /root/.ssh/r10k.provision

        # We're just disabling ssh host key checking here to avoid errors
        # with r10k

        cat >> /root/.ssh/config <<EOL
Host ${R10K_CUSTOM_HOST}
    IdentityFile ~/.ssh/r10k.provision
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no
EOL
        chmod 0600 /root/.ssh/config
    fi

fi
