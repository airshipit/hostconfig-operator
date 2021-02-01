## Packages Role

This role can be used by the hostconfig CR to install/upgrade packages
and then restart the corresponding services on the kubernetes hosts selected.
If no version is specified the package will be installed/upgraded to latest version.

Here is a sample CR object
```
apiVersion: hostconfig.airshipit.org/v1alpha1
kind: HostConfig
metadata:
  name: example-containerd
spec:
  host_groups:
   - name: "kubernetes.io/hostname"
     values:
      - "hostconfig-worker"
  config:
    packages:
      - name: docker
        version: "18.06.1~ce~3-0~ubuntu"
        # allow_downgrade: true # optional parameter to allow downgrading packages
        # pkg_manager: "apt" # optional parameter to specify which package manager to use
```
In this example we are upgrading docker on the hostconfig-worker node
to "18.06.1~ce~3-0~ubuntu" version.

The required fields for the CR object are name of the package to be
installed/upgraded to. Using one CR we can upgrade multiple packages, however
the installation happens one after the other.

Downgrading of the package will require and additional flag `allow_downgrade`
to set to true, if not the CR fails. Downgrading a major version may require
manually restarting the service.

Additionally the user can also specify `pkg_manager` which specifies using a
specific package manager instead of default. Current support exists for `apt`
and `yum` package managers.

Please note: Downgrading a major version of the package may require manual restart
of the service if `restart` flag is set to false.
If the package installation/upgrading has dependency on other packages, please use
`exec` role to define the steps and dependency. This feature is currently out of
scope using this role.

Current implementation supports installing/upgrading of `containerd.io`, `docker`
and apache2 packages with corresponding services restart on the kubernetes hosts.

Installation of `openstack3` and `nova3` package binaries are supported
as well.

Please note: `openstack3` refers to `python3-openstackclient` and `nova3`
refers to `python3-novaclient`.

If Installation/Upgrading/Downgrading fails the hostconfig-operator keeps on reconciling the
CR until it is successful. If the failure happens in the 2nd or 3rd package from the
list of packages in the CR, the whole CR fails and starts over again. So it is recommended
to delete the CR incase if the installation/upgrading/downgrading fails.

## Adding support for other packages

To add support for new package installation/upgrade, please update the [packages.ini](packages.ini)
file with an ini section, specifying package name which has to be
installed/upgraded and corresponding service name and restart flag(if applicable).

Sample configuration
```
[docker]
# Service name to restart
service=docker
# Package name to upgrade
package=docker-ce
# restart flag, used to restart service or not after upgrade
restart=false

## For simple binaries
[kubectl]
package=kubectl
```

Once edited the image has to be rebuilt and then can be used to
deploy the hostconfig-operator.
