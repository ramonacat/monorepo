use chrono::{DateTime, Utc};
use diesel::{
    Selectable,
    associations::{Associations, Identifiable},
    deserialize::Queryable,
    prelude::Insertable,
};
use ipnet::IpNet;
use uuid::Uuid;

#[derive(Queryable, Selectable)]
#[diesel(
    table_name = crate::schema::host_closure_state,
    check_for_backend(diesel::pg::Pg),
    primary_key(hostname)
)]
pub struct HostClosureState {
    pub hostname: String,
    pub current_closure: Option<String>,
    pub current_closure_updated_at: Option<DateTime<Utc>>,
    pub latest_closure: Option<String>,
    pub latest_closure_updated_at: Option<DateTime<Utc>>,
}

#[derive(Queryable, Selectable, Identifiable)]
#[diesel(
    table_name = crate::schema::home_closure,
    check_for_backend(diesel::pg::Pg),
    primary_key(name)
)]
pub struct HomeClosure {
    pub name: String,
    pub current_closure: String,
    pub current_closure_updated_at: DateTime<Utc>,
}

#[derive(Queryable, Selectable, Associations, Identifiable)]
#[diesel(
    table_name = crate::schema::home_closure_state,
    check_for_backend(diesel::pg::Pg),
    belongs_to(HomeClosure, foreign_key=closure_name),
    primary_key(hostname)
)]
pub struct HomeClosureState {
    pub hostname: String,
    pub closure_name: String,
    pub current_closure: String,
    pub current_closure_updated_at: DateTime<Utc>,
}

#[derive(Queryable, Selectable)]
#[diesel(
    table_name = crate::schema::versions,
    check_for_backend(diesel::pg::Pg),
    primary_key(versioned_item, store_path)
)]
pub struct Version {
    #[allow(unused)]
    pub versioned_item: String,
    #[allow(unused)]
    pub store_path: String,
    pub version: i64,
}

#[derive(Queryable, Selectable)]
#[diesel(table_name = crate::schema::host_ip_address, check_for_backend(diesel::pg::Pg), primary_key(hostname))]
pub struct HostIpAddress {
    #[allow(unused, reason = "a non-compound primary key makes the code simpler")]
    pub id: Uuid,
    pub address: IpNet,
    pub hostname: String,
    pub interface: String,
}

#[derive(Queryable, Selectable)]
#[diesel(table_name = crate::schema::wireguard_endpoint, check_for_backend(diesel::pg::Pg), primary_key(hostname))]
pub struct WireguardEndpoint {
    pub hostname: String,
    pub public_key: String,
    pub endpoint: Option<IpNet>,
    pub port: Option<i32>,
}

#[derive(Identifiable, Queryable, Selectable, Insertable)]
#[diesel(table_name = crate::schema::address_allocation, check_for_backend(diesel::pg::Pg), primary_key(id))]
pub struct AddressAllocation {
    pub id: Uuid,
    pub name: String,
    pub parent_id: Option<Uuid>,
    pub cidr: ipnet::IpNet,
}

#[derive(Identifiable, Queryable, Selectable)]
#[diesel(table_name = crate::schema::wireguard_tunnel, check_for_backend(diesel::pg::Pg), primary_key(id))]
pub struct WireguardTunnel {
    pub id: Uuid,
    pub initiator_hostname: String,
    pub listener_hostname: String,
}

#[derive(Identifiable, Queryable, Selectable, Associations, Insertable)]
#[diesel(
    table_name = crate::schema::wireguard_tunnel_to_address_allocation,
    check_for_backend(diesel::pg::Pg),
    primary_key(wireguard_tunnel_id, address_allocation_id),
    belongs_to(WireguardTunnel),
    belongs_to(AddressAllocation)
)]
pub struct WireguardTunnelAddressAllocation {
    pub wireguard_tunnel_id: Uuid,
    pub address_allocation_id: Uuid,
}
