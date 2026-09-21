DROP TABLE host_ip_address;

CREATE TABLE host_ip_address (
    id uuid PRIMARY KEY,
    address INET NOT NULL,
    hostname TEXT NOT NULL,
    interface TEXT NOT NULL
);

CREATE UNIQUE INDEX host_ip_address__address_hostname_interface ON host_ip_address(address, hostname, interface);
