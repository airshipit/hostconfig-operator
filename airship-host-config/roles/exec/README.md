# Exec Role

This role can be used to perform configuration on the nodes using scripts.
The CR takes scriptname, script arguments and environment variables as
possible options to perform execution of the specified script on the node.

The script that is used to perform the configuration has to be present in
the hostconfig-operator before using the CR.

Sample CR object:

```
apiVersion: hostconfig.airshipit.org/v1alpha1
kind: HostConfig
metadata:
  name: example-exec
spec:
  host_groups:
   - name: "kubernetes.io/hostname"
     values:
      - "hostconfig-worker"
  config:
    exec:
      - name: example.sh
```

## Adding scripts to hostconfig-operator

To add custom scripts to hostconfig-operator which can be used later
as part of CR to perform configuration, please follow the below steps:

1. Add the script file to the [scripts](../../scripts) directory, the script
has to be executable.
2. Build the hostconfig-operator image, `make images`
3. Use this image to deploy the hostconfig-operator, make any changes
if necessary to the [operator.yaml](../../deploy/operator.yaml)
4. Once you have the deployment ready, use the appropriate CR, so that
the scripts can be executed. Example [CR example_exec.yaml](../../../demo_examples/example_exec.yaml)
