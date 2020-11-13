# Comply

## Table of Contents

- [Comply](#comply)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Setup](#setup)
    - [Prerequisites](#prerequisites)
    - [Ports and data flow](#ports-and-data-flow)
      - [Hardware requirements for the comply ui stack.](#hardware-requirements-for-the-comply-ui-stack)
    - [The Demo Plans](#the-demo-plans)
    - [Accessing your PE Console, Comply UI and Comply identity](#accessing-your-pe-console-comply-ui-and-comply-identity)
  - [Usage](#usage)
    - [Uninstalling the product.](#uninstalling-the-product)
  - [Development](#development)
    - [Github workflow](#github-workflow)
    - [Running acceptance tests locally](#running-acceptance-tests-locally)
    - [Running integration tests locally](#running-integration-tests-locally)
    - [Running the scarp docker stack](#running-the-scarp-docker-stack)
  - [Releasing](#releasing)
    - [Initial steps](#initial-steps)
    - [Verification of Demo](#verification-of-demo)
    - [Releasing the Module](#releasing-the-module)
    - [Verification](#verification)
    - [Updating the Wiki](#updating-the-wiki)
    - [Releasing the artifacts](#releasing-the-artifacts)
  - [Additional Resources](#additional-resources)

## Description

The comply module provides CIS Complicance scanning and reporting functionality when used alonside Puppet Enterprise.
This documentation is intended for Puppet Engineers. [User documentation can be found in the Wiki.](./wiki)

## Setup

We have a number of bolt plans that will spin up a demo environment. It will provision machines in vmpooler/ABS, install pe, install the module and setup the agents and setup the application stack with UI. Allowing you to focus on running scans and viewing the data.

### Prerequisites

* ruby 2.5 installed and working.
* Create a vmpooler/ABS token.

To create your token:

```
curl -X POST -d '' -u <your puppet username> --url https://cinext-abs.delivery.puppetlabs.net/api/v2/token
Enter host password for user 'tp':
{
  "ok": true,
  "token": "super_secret_token"
}%
```

Now you can update your fog file

```
cat ~/.fog
:default:
  :abs_token: super_secret_token # https://cinext-abs.delivery.puppetlabs.net/api/v2
```

> Things of note
>
> * comply::demo_01_provision_machines will spin up a large number of systems. Comment out the systems from plans/ demo_01_provision_machines.pp that you dont want.
> * The inventory.yaml file is created when the first plan is run, it contains all machines spun up along with their connection information.

### Ports and data flow

Comply is made of two main parts the scanner which is installed on to the scan targets, and the comply stack which contains are docker images which hosts the database / processor and UI.

Scans kicked of via the scan plan happen over PXP, as well as the installation of the comply stack on to machine.
``` bash
             PE
            /  \
   agent          agent
scan target    comply stack
```

The communication of scan results to the comply stack, And kicking off a scan from the comply ui happens over the following ports.

``` bash
                              PE
                              |
                3001          | 8143 orchestrator
            scan result       |
scan target  ---------  comply stack
                              |
                              | 3001 webapp
                              |
                             user
```

#### Hardware requirements for the comply ui stack.

* 4 cpu
* 12GB RAM
* 500GB disk added for data storage
* Tested on Centos 7

### The Demo Plans


``` bash
# clone the module
git clone git@github.com:puppetlabs/comply.git
cd comply

# install gems
bundle install --path .bundle/gems/ --jobs 4

# set up module dependencies
bundle exec rake spec_prep

# spin up machines in abs
bundle exec bolt --modulepath spec/fixtures/modules plan run comply::demo_01_provision_machines

# Alternatively, you can spin up the demo environment in vmpooler which
# will enable the extending of lifetimes
bundle exec bolt --modulepath spec/fixtures/modules plan run comply::demo_01_provision_machines provision_type=vmpooler


# sets up the pe machine and installs the comply module
bundle exec bolt --modulepath spec/fixtures/modules -i inventory.yaml plan run comply::demo_02_pe_server_setup

# installs both the scanners and scarp on the agents, (oscap and ciscat)
bundle exec bolt --modulepath spec/fixtures/modules -i inventory.yaml plan run comply::demo_03_puppet_agents_setup

# This sets-up a node with tha Comply UI. NB you have to specify a version to use, latest|master
bundle exec bolt --modulepath spec/fixtures/modules -i inventory.yaml plan run comply::demo_04_comply_stack_setup image_version=latest

# It is possible to extend the lifetime of Demo VMs, if they are in vmpooler. (This does NOT work in abs)
bundle exec rake extend_vm_life
```

### Accessing your PE Console, Comply UI and Comply identity
#### PE UI
> Identifying PE FQDN: look for a `vars/role` of `pe` within your generated `inventory.yaml`

* PE Console lives at: https://{PE-FQDN}
* Login  : admin
* Password : compliance

#### Comply UI
> Identifying Comply FQDN: look for a `vars/role` of `comply` within your generated `inventory.yaml`

* Comply UI lives at: http://{COMPLY-FQDN}:3001
* Username: comply
* Password: compliance

**After first login you will be forced to change the password. 12 characters long**

#### Keycloak UI **devs only**
* Comply Identity lives at: http://{COMPLY-FQDN}:8443/auth
* Username: puppet

Identity's password is a docker secret and random generated on every new instalaltion. To fetch it you have to ssh to your comply server and execute the following
```
docker exec $(docker ps -q -f name=comply_auth) /bin/sh -c 'cat /run/secrets/admin_password'
```
Password will look like the following  `29d24487-bb70-40e3-9d57-b14f68edf3bb`

### Uninstalling the product.

The comply stack.

``` puppet
docker_stack { 'comply_stack':
  compose_files => [ '/opt/puppetlabs/comply/docker-compose.yaml', ],
  ensure  => absent,
}
file { '/opt/puppetlabs/comply':
  ensure => absent,
  force => true,
  require => Docker_stack['comply_stack'],
}
```

The ciscat scanners from a target machine

``` puppet
if $facts['kernel'] == 'windows' {
  $install_path = 'C:/ProgramData/PuppetLabs/comply'
} else {
  $install_path = '/opt/puppetlabs/comply'
}
file { 'Assessor-CLI.jar':
  path    => "${install_path}/Assessor-CLI",
  force => true,
  ensure => absent,
}
```

## Development

### Github workflow

Puppet's normal workflow is to fork this repository and make your PR for this repo against a branch in your Fork. If you follow this workflow, the acceptance and integration tests will not run automatcially when you push your PR.

To enable our acceptance and integration tests for your PRs, you will need push your branch to the main repo. IE

``` bash
comply git:(splunk) ✗ cat .git/config
[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
[remote "origin"]
        url = git@github.com:tphoney/comply.git
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
        remote = origin
        merge = refs/heads/master
[remote "upstream"]
        url = git@github.com:puppetlabs/comply.git
        fetch = +refs/heads/*:refs/remotes/upstream/*
➜  comply git:(splunk) ✗ git push upstream splunk
```

> Pushing to master is disabled on this respository.

### Running acceptance tests locally

Using litmus we can test against supported operating systems

> Please ensure you must have a clean inventory.yaml.

``` bash
bundle exec rake 'litmus:provision_list[release_checks]'
bundle exec rake litmus:install_agent
bundle exec rake litmus:install_module
bundle exec rake litmus:acceptance:parallel
```

Giving this output:

``` bash
➜  comply git:(pipelines) ✗ bundle exec rake litmus:acceptance:parallel
┌ [✔] Running against 3 targets.
├── [✔] jl911a6nyz6agdn.delivery.puppetlabs.net, redhat-6-x86_64
├── [✔] ch4ky8bqcat1oqo.delivery.puppetlabs.net, redhat-7-x86_64
└── [✔] u30dpgjre89fu10.delivery.puppetlabs.net, centos-7-x86_64
================
u30dpgjre89fu10.delivery.puppetlabs.net, centos-7-x86_64
........

Finished in 1 minute 21.58 seconds (files took 0.39024 seconds to load)
8 examples, 0 failures

pid 8172 exit 0
================
ch4ky8bqcat1oqo.delivery.puppetlabs.net, redhat-7-x86_64
........

Finished in 2 minutes 22.1 seconds (files took 0.38761 seconds to load)
8 examples, 0 failures

pid 8166 exit 0
================
jl911a6nyz6agdn.delivery.puppetlabs.net, redhat-6-x86_64
........

Finished in 2 minutes 26.5 seconds (files took 0.37904 seconds to load)
8 examples, 0 failures

pid 8160 exit 0
Successful on 3 nodes: ["u30dpgjre89fu10.delivery.puppetlabs.net, centos-7-x86_64", "ch4ky8bqcat1oqo.delivery.puppetlabs.net, redhat-7-x86_64", "jl911a6nyz6agdn.delivery.puppetlabs.net, redhat-6-x86_64"]
```

### Running integration tests locally

> Please ensure you must have a clean inventory.yaml.

To run the integration tests locally you have to use the following set of commands first to provision and setup the test environment.
Running the Litmus acceptance test workflow will conflict with the new integration environment. Consider running `bundle exec rake litmus:tear_down` before beginning.

``` bash
bundle exec bolt --modulepath spec/fixtures/modules  plan run comply::demo_01_provision_machines
bundle exec bolt --modulepath spec/fixtures/modules -i inventory.yaml plan run comply::demo_02_pe_server_setup
bundle exec bolt --modulepath spec/fixtures/modules -i inventory.yaml plan run comply::demo_03_puppet_agents_setup
bundle exec bolt --modulepath spec/fixtures/modules -i inventory.yaml plan run comply::demo_04_comply_stack_setup
```

> You can find your pe master FQDN within the inventory.yaml file:

After that has run successfully then you can run your integration tests with the following command.

``` bash
bundle exec rake comply:integration
```
## Releasing

### Initial steps

* Ensure you have permissions for [Google Drive][gdrive]
* Ensure you have permissions for [Box][box]
* Ensure you have permissions for [compliance-builds S3 bucket](https://confluence.puppetlabs.com/display/COMPLIANCE/Accessing+our+S3+bucket)
* Ensure you have the wiki generator installed [Generator](https://github.com/yakivmospan/github-wikito-converter)
* Ensure you have a newly built demo environment. This will be what is released.

### Verification of Demo

* Run through the demo scripts and create a demo environment
* Sanity check that thedemo environment looks good and everything works
    1. SSH onto the comply node
    2. `docker container ls` make sure that containers are stable, not restarting etc
    3. `docker images`
    4. (if required) Update [image_helper.sh](files/image_helper.sh) to reflect the images listed

### Releasing the Module

*  Prepare the repository by ensuring a release branch is present on the module. On supported modules this branch should already exist.
   Then push the commits from the master to the release branch, you can use the following git command to do so:
   ```git push <remotename> <remotename>/master:release```
* From master, create a branch called `release_prep`
* Update module metadata(<module_path>/metadata.json) with the new release version.
  * Update Puppet version

    ```json
    "requirements": [
        {
          "name": "puppet",
          "version_requirement": ">= 5.5.10 < 7.0.0"
        }
      ],
    ```

  * Update supported OSes

    ```json
    {
      "operatingsystem": "Ubuntu",
      "operatingsystemrelease": [
        "14.04",
        "16.04",
        "18.04"
      ]
    },
      ```

* Update changelog

  Update the [changelog](https://confluence.puppetlabs.com/display/ECO/Modules+Changelogs) using the [changelog generator](https://github.com/github-changelog-generator/github-changelog-generator)

  ```bash
  CHANGELOG_GITHUB_TOKEN=<your_github_token> bundle exec rake changelog
  ```

* Update the documentation

  First update the REFERENCE.md file using Puppet Strings:

  ```bash
  bundle exec puppet strings generate --format markdown --out REFERENCE.md
  ```

* update [demo_02_pe_server_setup.pp](./plans/demo_02_pe_server_setup.pp)

  update the version number of the module to reflect the new version.

* Review your changes

  Look at the diff and ensure that your pr contains only the changes you expected:

  * metadata.json
  * CHANGELOG.md
  * plans/demo_02_pe_server_setup.pp
  * (optional) REFERENCE.md

* Commit your changes with the description `(CISC-xxx) release prep for vX.Y.Z`

* Push this branch to `upstream` and open a PR against `release` branch.
  ```
  git push --set-upstream upstream release_prep
  ```
  then visit https://github.com/puppetlabs/comply/pull/new/release_prep to create a new PR.

  This ensures that the github workflows are kicked off correctly

  Ensure that the `release_helper` action has kicked off upon making the pull request to `release_prep`. The following should happen:

  * Run the dependency checker.

  * Check for symlinks.

  * Create a new module tarball for the new version.

  * Package docker images and tar them together.

  * Uploads a zip containing both tars and `image_helper.sh`, as well as the latest version in seperate file to artifactory.

* Ensure CI validation passed successfully before and after the PR merge.

* Get a team mate to sanity check the PR.

* Tag the PR merge commit in the `release` branch with the new version ```git tag -a v0.3.0 -m "v0.3.0" 7780951ed01ace25e253dd572d0cf593ac415f7b```
* Push the tag to github `git push upstream --tags`
* Now a PR can be opened from `release` to `master` to merge back the changes.

### Verification

* Check out Comply module to `v0.2.1` to a local branch called `verification`.

```bash
git checkout tags/v0.2.1 -b verification
```

* Run through the demo script 1,2,3,4 to stand up the old demo environment.
* Ensure that you can see PE and the Comply UI.
* Upload `comply-stack.tar` to the comply node, e.g.

```bash
scp ~/downloads/comply-stack.tar root@comply.delivery.puppetlabs.net:~
```

* Upload `image_helper.sh` to the comply node
* Upload the Comply Module tarball e.g. `puppetlabs-comply-0.5.0.tar.gz` to the PE node
* (optional) [Disable the Puppet agent](https://puppet.com/docs/puppet/latest/services_agent_unix.html#disable_nix_puppet_runs) to ensure that Puppet doesn't fire before you finish
* SSH to your comply node and run the following, to remove the v0.2.1 images and containers:

```bash
docker-compose -f /opt/puppetlabs/comply/docker-compose.yaml rm -s -f
docker image rm $(docker images '*/compliance/*' -q)
```

* Install the latest images via the private registry method. First create the local registry:

```bash
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

* Now using the `image_helper.sh` script install the latest images

```bash
chmod +x ~/image_helper.sh
~/image_helper.sh ~/comply-stack.tar <comply-node-fqdn>:5000
```

* Verify that the images have the retagged correctly. i.e. `<comply-node-fqdn>/compliance/<image-name>`

```bash
[root@linear-coroner ~]# docker images
REPOSITORY                                                         TAG                 IMAGE ID            CREATED             SIZE
artifactory.delivery.puppetlabs.net/compliance/comply-ui           latest              9606c0b37ccb        4 days ago          90.7MB
linear-coroner.delivery.puppetlabs.net:5000/compliance/comply-ui   latest              9606c0b37ccb        4 days ago          90.7MB
artifactory.delivery.puppetlabs.net/compliance/postgres            11-alpine           98efe01f6671        5 days ago          155MB
artifactory.delivery.puppetlabs.net/compliance/scarp               latest              59a5b6b9560f        6 days ago          271MB
linear-coroner.delivery.puppetlabs.net:5000/compliance/scarp       latest              59a5b6b9560f        6 days ago          271MB
registry                                                           2                   708bc6af7e5e        4 months ago        25.7MB
```

* SSH to your PE node and install the new Module

```bash
puppet module install --force ~/puppetlabs-comply-<version>.tar.gz
```

* Now edit your Comply node's puppet file, e.g. `vi /etc/puppetlabs/code/environments/production/manifests/nodes/<comply-node-fqdn>.pp`

```puppet
node '<comply-node-fqdn>'
{
  class  { 'comply::demo_stack':
    image_prefix => '<comply-node-fqdn>:5000/compliance/'
  }
}
```

* SSH to your Comply node and perform a Puppet run

```bash
puppet agent -t
```

* Once the puppet run has completed, run `docker continer ls` and ensure the containers are using the new images e.g.

```bash
[root@linear-coroner ~]# docker container ls
CONTAINER ID        IMAGE                                                                       COMMAND                  CREATED             STATUS              PORTS                    NAMES
cebd2c2cabad        linear-coroner.delivery.puppetlabs.net:5000/compliance/comply-ui:latest     "docker-entrypoint.s…"   26 seconds ago      Up 25 seconds       0.0.0.0:3001->3001/tcp   comply_comply-ui_1
d64683c58b1f        linear-coroner.delivery.puppetlabs.net:5000/compliance/scarp:latest         "docker-entrypoint.sh"   37 seconds ago      Up 36 seconds       0.0.0.0:8088->8088/tcp   comply_scarpy_1
62858f8685cd        linear-coroner.delivery.puppetlabs.net:5000/compliance/postgres:11-alpine   "docker-entrypoint.s…"   48 seconds ago      Up 47 seconds       0.0.0.0:5432->5432/tcp   comply_db_1
334889f26b9a        registry:2                                                                  "/entrypoint.sh /etc…"   19 hours ago        Up 19 hours         0.0.0.0:5000->5000/tcp   registry
[root@linear-coroner ~]#
```

* Log into the Comply UI and perform a scan, ensure that everything works as expected.

### Updating the Wiki

* Clone the Comply wiki
```bash
   git clone git@github.com:puppetlabs/comply.wiki.git
```
* Generate the WIKI Document.
```bash
   cd <Your DIR where the wiki was cloned too. NOT inside the wiki clone itself>
   gwtc ./comply.wiki
```
* Tag [comply.wiki](https://github.com/puppetlabs/comply.wiki.git)
  In the wiki clone directory do the following.
  ```
  git fetch <remotename>
  git tag -a <version> -m "<version>" <commit_sha>
  git push <remotename> --tags
  ```
* You will upload this file in the release steps.

### Releasing the artifacts
* Ensure that the previous tarballs are moved to the `older versions` folder
* Upload the `files/image_helper.sh` from the comply repo to [Google Drive][gdrive]
* Upload the `files/image_helper.sh` from the comply repo to [Box][box]
* Upload the wiki file `documentation.html` to [Google Drive][gdrive]
* Upload the wiki file `documentation.html` to [Box][box]
* Download the newly build module tarball from artifactory, e.g. `https://artifactory.delivery.puppetlabs.net/artifactory/generic__local/compliance/comply/puppetlabs-comply-x.y.z.tar.gz`
* upload module and comply-stack tarballs to [Google Drive][gdrive] compliance folder
* upload module and comply-stack tarballs to [Box][box].
* Releasing to S3
   * Zip and password protect the 4 release artifacts using `7za a comply-0.6.0-release.zip -ppuppet-comply`
   * On the compliance-builds S3 console, select `Upload`, add the zip file and click `Upload`
   * When the upload has finished, click on the link of the actual file name, then click on the `Permissions` tab. In the `Public access` section at the bottom, click the radio button and select the `Read object` checkbox and hit `Save`

> 🎉 You have now released the comply product

## Additional Resources

### I want to start from scratch with my comply demo stack

This wipes everything, On your comply-ui box

```
cd /opt/puppetlabs/ && docker stack rm comply && sleep 10 && docker volume prune && docker swarm leave --force && docker-compose -f comply/docker-compose.yaml pull && rm -rf comply/ && puppet agent -t
```

### Testing dev image on your demo stack

For scarp or the watcher images, in your scarp dev environment

```
sudo docker build --rm --no-cache -t scarp .
docker image save scarp:latest -o scarp.tar
scp  -i ~/.ssh/id_rsa-acceptance scarp.tar root@complyui.delivery.puppetlabs.net:~/
# or
docker build --rm --no-cache -t watcher -f watcher.Dockerfile .
docker image save watcher:latest -o watcher.tar
scp  -i ~/.ssh/id_rsa-acceptance watcher.tar root@complyui.delivery.puppetlabs.net:~/
```

Then on your comply ui machine we can do this.

```
docker load -i scarp.tar
# Loaded image: scarp:latest
docker service update comply_watcher --image watcher:latest
```

**NB you cannot use the same image name and tag that is in your docker-compose.file** it will use a cached version, eg `docker service update comply_scarpy --image artifactory.delivery.puppetlabs.net/compliance/scarp:master` will fail.

[gdrive]: https://drive.google.com/drive/u/1/folders/0AOywIQsKa0wIUk9PVA
[box]: https://puppet.app.box.com/folder/112522524559
