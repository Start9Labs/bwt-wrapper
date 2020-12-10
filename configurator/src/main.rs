use std::fs::File;
use std::io::Write;
use std::net::IpAddr;


use http::Uri;
use serde::{
    de::{Deserializer, Error as DeserializeError, Unexpected},
    Deserialize,
};

fn deserialize_parse<'de, D: Deserializer<'de>, T: std::str::FromStr>(
    deserializer: D,
) -> Result<T, D::Error> {
    let s: String = Deserialize::deserialize(deserializer)?;
    s.parse()
        .map_err(|_| DeserializeError::invalid_value(Unexpected::Str(&s), &"a valid URI"))
}

fn parse_quick_connect_url(url: Uri) -> Result<(String, String, String, u16), anyhow::Error> {
    let auth = url
        .authority()
        .ok_or_else(|| anyhow::anyhow!("invalid Quick Connect URL"))?;
    let mut auth_split = auth.as_str().split(|c| c == ':' || c == '@');
    let user = auth_split
        .next()
        .ok_or_else(|| anyhow::anyhow!("missing user"))?;
    let pass = auth_split
        .next()
        .ok_or_else(|| anyhow::anyhow!("missing pass"))?;
    let host = url.host().unwrap();
    let port = url.port_u16().unwrap_or(8332);
    Ok((user.to_owned(), pass.to_owned(), host.to_owned(), port))
}

#[derive(Deserialize)]
#[serde(rename_all = "kebab-case")]
struct Config {
    bitcoind: BitcoinCoreConfig,
    xpubs: Vec<String>,
    rescan_since: String,
}

#[derive(serde::Deserialize)]
#[serde(tag = "type")]
#[serde(rename_all = "kebab-case")]
enum BitcoinCoreConfig {
    #[serde(rename_all = "kebab-case")]
    Internal {
        rpc_address: IpAddr,
        user: String,
        password: String,
    },
    #[serde(rename_all = "kebab-case")]
    External {
        #[serde(deserialize_with = "deserialize_parse")]
        host: Uri,
        rpc_user: String,
        rpc_password: String,
        rpc_port: u16,
    },
    #[serde(rename_all = "kebab-case")]
    QuickConnect {
        #[serde(deserialize_with = "deserialize_parse")]
        quick_connect_url: Uri,
    },
}

#[derive(serde::Serialize)]
pub struct Properties {
    version: u8,
    data: Data,
}

#[derive(serde::Serialize)]
pub struct Data {
    #[serde(rename = "LND Connect URL")]
    lnd_connect: Property<String>,
}

#[derive(serde::Serialize)]
pub struct Property<T> {
    #[serde(rename = "type")]
    value_type: &'static str,
    value: T,
    description: Option<String>,
    copyable: bool,
    qr: bool,
    masked: bool,
}

fn main() -> Result<(), anyhow::Error> {
    let config: Config = serde_yaml::from_reader(File::open("/root/start9/config.yaml")?)?;

    {
        let mut outfile = File::create("/root/bwt.env")?;

        let (
            bitcoin_rpc_user,
            bitcoin_rpc_pass,
            bitcoin_rpc_host,
            bitcoin_rpc_port,
        ) = match config.bitcoind {
            BitcoinCoreConfig::Internal {
                rpc_address,
                user,
                password,
            } => (
                user,
                password,
                format!("{}", rpc_address),
                8332,
            ),
            BitcoinCoreConfig::External {
                host,
                rpc_user,
                rpc_password,
                rpc_port,
            } => (
                rpc_user,
                rpc_password,
                format!("{}", host.host().unwrap()),
                rpc_port,
            ),
            BitcoinCoreConfig::QuickConnect {
                quick_connect_url,
            } => {
                let (bitcoin_rpc_user, bitcoin_rpc_pass, bitcoin_rpc_host, bitcoin_rpc_port) =
                    parse_quick_connect_url(quick_connect_url)?;
                (
                    bitcoin_rpc_user,
                    bitcoin_rpc_pass,
                    bitcoin_rpc_host.clone(),
                    bitcoin_rpc_port,
                )
            }
        };

        write!(
            outfile,
            include_str!("bwt.env.template"),
            bitcoin_rpc_user = bitcoin_rpc_user,
            bitcoin_rpc_pass = bitcoin_rpc_pass,
            bitcoin_rpc_host = bitcoin_rpc_host,
            bitcoin_rpc_port = bitcoin_rpc_port,
            rescan_since = config.rescan_since,
            xpubs = format!("'{}'", config.xpubs.join(";")),
        )?;
    }

    Ok(())
}
