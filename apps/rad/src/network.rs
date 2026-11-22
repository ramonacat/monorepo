use askama::Template;
use ipnet::IpNet;

#[derive(Debug, Template)]
#[template(path = "dummy.netdev")]
pub struct NetdevTemplate {
    pub name: String,
}

#[derive(Debug, Template)]
#[template(path = "dummy.network")]
pub struct NetworkTemplate {
    pub name: String,
    pub ip: IpNet,
}
