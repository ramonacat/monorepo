{config, ...}: {
  nix = {
    buildMachines = [
      {
        hostName = "redwood";
        systems = ["aarch64-linux"];
        sshUser = "root";
        maxJobs = 8;
        publicHostKey = "c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFDQVFEZ3UvOGR1YnhtQkVwd2dHb0NRN2dwcmVLeitiWHltS29ONm9IMlZjNk1NUG5xZlFZVE1TbkVwaXlHY0xvTUN3dDVTK2ZxSE5KNlVQeXRNajQwczRiUFdNTFhxYkpmZGJRSHEvRjk4REJSSDA3Wk5RNnFYaGozZFJNWjJQNlk0d2dKdWxTWXVyNlVQSXN4Zzl0QUcxMW1TeHpEVE1ycS93T1BlanhtOVkvWGcvM0JmMis3Si9KRnlpdXMrcG8xQWx4TTFzRlRSbUZtbE9JQ2krdGw3UDI1UmZoOHNpMjBwTWxLZ01YV0x0ZmcyeE0vOXRueFJQUmxXMDhGOUFZQVdoOVNwYThJMzNMRW9ZWitNYVBscFQyRnNFTTRYU2oxb3lDM0djU0t2bW1ySUpFU0ZVM2pIa2x2Ylk3RHhoQXZWZUFYcThOUUZackRnSFlYeGZCYXdnNHNVTW5GMXI4YzlPYitSWHpST0NUdkUvVEM0c2xuV0ZCZlJiN3Q0anoxTkFFK05SVzNwNUQ3aWlUaWpHQ0dKZ2dlbndzbldscXFVbXhLRHV1SXhQSFdweFdGNjFBdzFUNmZqZFl6N1dHbE1zblZOVkx5WkV6NEJhQmtDejc4ckRHMHVLVk5OeUQwTVBBUkZvbW0zdFVaaURCU1NEUlQweUZzM3FERXNDSHZUdW5HS2xVMExSalBnNnB5U3ZLYldrR3g5aVR1QzNlbDJkWGlMdlJNVDJ0QUlNdkZuMmQvdEhpN0x2aDVoSzZ0U1l5ZGFURyswNVpnamZXbktLcTJmSDExTHZJOUlxYThjVk5mR0prbnBpdkZRUm1STGNueE4zR1F0ektGa3ZtUkk4TjVEaG51QnF0cDdWSzVIYlAvWWVXNG9VbTJEWnJZRERSOVI2N1drN2plclE9PSByb290QHJlZHdvb2QK";
        sshKey = config.age.secrets.universal-root.path;
        supportedFeatures = ["big-parallel" "kvm"];
      }
    ];
    distributedBuilds = true;
  };
}
