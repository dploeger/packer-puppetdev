# Puppetdev

*Local testing of puppet manifests using Vagrant*

This repository contains scripts together with basic Packer templates for
generating Vagrant boxes, that can be used for local puppet testing.

These boxes are available on [Hashicorp's Vagrant cloud](https://app.vagrantup.com/boxes/search?utf8=%E2%9C%93&sort=downloads&provider=&q=dodevops%2Fpuppetdev)
for use with Vagrant.

## Usage

The generated boxes have the following features:

* Install puppet modules using [r10k](https://github.com/puppetlabs/r10k)
* Install puppet modules from a private git repository
* Run puppet apply
* Use hiera

### Prerequisites

These boxes run under [vagrant](https://vagrantup.com) using the
[VirtualBox](https://virtualbox.org) provider, so you'll need to have both
things installed.

Once ready, create an empty directory somewhere and run the following command:

    vagrant init dodevops/puppetdev-CONFIGURATION

Where "CONFIGURATION" should be replaced with one of the following:

| CONFIGURATION      | Distribution | Version | Puppet-Release |
| ------------------ | ------------ | ------- | -------------- |
| debian             | Debian       | 8.6     | 3              |
| debianpuppet4      | Debian       | 8.6     | 4              |
| ubuntu             | Ubuntu       | 14.04   | 3              |
| ubuntupuppet4      | Ubuntu       | 14.04   | 4              |
| ubuntu16.04        | Ubuntu       | 16.04   | 3              |
| ubuntu16.04puppet4 | Ubuntu       | 16.04   | 4              |

For example, to install Ubuntu 16.04 with Puppet4, you would use:

    vagrant init dodevops/puppetdev-ubuntu16.04puppet4

Afterwards, `vagrant up` will start your virtual machine, but first, read on...

### Puppet

To use puppet, create a "puppet" subdirectory where your 
Vagrantfile lies.
 
Inside, create a "site.pp" file. This file will be run by puppet apply 
during the provisioning process.

You can also use a different manifest file name, provide custom facts 
and specify puppet apply arguments. See Overriding configuration 
below for details.

### r10k

You can create a Puppetfile in the puppet subdirectory and place 
modules there, that r10k will install. (Using r10k puppetfile install)

To support private repositories when using r10k, you'll have to put
two files in the directory where your Vagrantfile is: One file named
"r10k.provision" holding a SSH private key, that is used when
connecting to your private repositories and a file named "r10k.host"
with the host name of your private repository host.

### Hiera

Create a subdirectory "hieradata" and place hiera yaml files there. 

Look under vagrant.includes/hiera.yaml or hiera5.yaml (for puppet 4) for
the default hiera configuration.

### Overriding configuration

You can override certain configuration by placing a config.yaml where
your Vagrantfile is. Look in vagrant.includes/config.dist.yaml for the
keys you can override there.

Also, you can place a hiera.yaml where your Vagrantfile is to alter
the used hiera configuration. Use vagrant.includes/hiera.yaml or hiera5.yaml
(for puppet 4) as a template.

# Building

## Structure

To build our custom boxes, we're using the following things:

* _vars/*.json_: Additional variable files provided to packer
* _scripts/*.sh_: Additional scripts, that are run in the provisioning phase
* _vagrantfiles/Vagrantfile*_: Vagrantfile templates (this is basically, 
where our magic happens later on)
* _vagrant.includes/*_: Additional files packed together with the boxes

Because we're using the excellent Packer templates by 
[boxcutter](https://github.com/boxcutter) as a base for our templates
(base.debian and base.ubuntu), we needed to make changes to their 
templates to allow this.

For this we're using a Grunt-based building process, that applies
jsonpatch-files (in the directory patches/)

## Local additions

You can also extend our additions and provide additional files and
variables.

### Including variable files

To override any variables, you have to create variable files in 
local/vars. Afterwards, create a file named "vars.json" in local/* 

Here you can specify, which machine type gets which variable files:

    {
      "ubuntu": ["customvar1.json"],
      "*": ["customvar2.json"]
    }

The wildcard "*" will add the custom var file to all machine types.

### Enabling r10k custom host feature from within the box

If you'd like to use custom puppet modules in a private git-repository
and don't want the user to supply the public key beside the Vagrantfile,
you have to do two things:

Create an SSH private key named "r10k.provision" and place it under 
local/files. Give this private key access to all module repositories
you require. After that, define two keys using the local variable
feature (see above):

* _feature_r10k_custom_: Set this to true to enable this feature
* _r10k_custom_host_: The hostname of the git repository. This will be
used to configure an SSH-connection inside the virtual machine. The 
connection will use the provided key and ignore the host key to avoid
problems running r10k automatically.

## Prerequisites

* [Packer](https://packer.io)
* [Node.js](https://nodejs.org) >= 4.5.0
* [Vagrant](https://vagrantup.com)
* [VirtualBox](https://virtualbox.org)
* [Ruby](https://ruby-lang.org)

## Initialize the submodules

To fetch the external repositories by boxcutter, run these two commands:

    git submodule update --init 

## Building process

To build, you first need to install grunt-cli and the needed modules:

    npm install -g grunt-cli
    npm install

Tests are done using serverspec, which runs on ruby and needs some gems:

    gem install bundler
    bundle install

Then, simply run grunt with the desired target machine:

    grunt ubuntu

This will build the ubuntu version of the machine and run the testsuite
against it.

## Testing

The tests are done using [Serverspec](http://serverspec.org/).

The testing process injects the generated box into the vagrant box
cache and fires up a vagrant machine in test/. This machine starts up
and applies some changes using puppet.

Afterwards, the spec files (test/*_spec.rb) are applied and everything
is cleaned up again.