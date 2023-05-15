use std::{collections::HashMap, error, ffi::CString, fmt, io, str::FromStr, sync::Arc};

use allo_isolate::ffi::*;
use bitcoin::Amount;
use cashu_crab::{
    cashu_wallet::CashuWallet,
    client::Client,
    error::Error as CashuCrabError,
    types::{Proofs, Token},
};
use lazy_static::lazy_static;
use lightning_invoice::{Invoice, InvoiceDescription};
use tokio::sync::Mutex;

/// A useless Error just for the Demo
#[derive(Clone, Debug)]
pub struct CashuError(String);

impl fmt::Display for CashuError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let msg = format!("Error in Rust: {:?}", self.0);
        write!(f, "{}", &msg)
    }
}

impl error::Error for CashuError {}

impl From<minreq::Error> for CashuError {
    fn from(err: minreq::Error) -> Self {
        Self(err.to_string())
    }
}

impl From<io::Error> for CashuError {
    fn from(err: io::Error) -> Self {
        Self(err.to_string())
    }
}

impl From<serde_json::Error> for CashuError {
    fn from(err: serde_json::Error) -> Self {
        Self(err.to_string())
    }
}

impl From<CashuCrabError> for CashuError {
    fn from(err: CashuCrabError) -> Self {
        Self(err.to_string())
    }
}

impl From<tokio::sync::TryLockError> for CashuError {
    fn from(err: tokio::sync::TryLockError) -> Self {
        Self(err.to_string())
    }
}

lazy_static! {
    static ref WALLETS: Arc<Mutex<HashMap<String, Option<CashuWallet>>>> =
        Arc::new(Mutex::new(HashMap::new()));
    static ref PROOFS: Arc<Mutex<HashMap<String, Proofs>>> = Arc::new(Mutex::new(HashMap::new()));
    static ref PENDING_PROOFS: Arc<Mutex<HashMap<String, Proofs>>> =
        Arc::new(Mutex::new(HashMap::new()));
}

pub async fn get_balances() -> Result<String, CashuError> {
    let proofs = PROOFS.lock().await;

    let balances = proofs
        .iter()
        .map(|(mint, proofs)| {
            let balance = proofs
                .iter()
                .fold(0, |acc, proof| acc + proof.amount.to_sat());
            (mint.to_owned(), balance)
        })
        .collect::<HashMap<_, _>>();

    Ok(serde_json::to_string(&balances)?)
}

/// Create Wallet
pub async fn create_wallet(url: &str) -> Result<String, CashuError> {
    let client = Client::new(url)?;
    let wallet = match client.get_keys().await {
        Ok(keys) => Some(CashuWallet::new(client.clone(), keys)),
        Err(_err) => None,
    };

    WALLETS.lock().await.insert(url.to_string(), wallet.clone());

    Ok("".to_string())
}

pub async fn get_wallets() -> Result<Vec<String>, CashuError> {
    Ok(WALLETS
        .lock()
        .await
        .iter()
        .map(|(k, _v)| k.to_owned())
        .collect())
}

pub async fn remove_wallet(url: &str) -> Result<String, CashuError> {
    WALLETS.lock().await.remove(url);
    Ok("".to_string())
}

/// Check proofs for mints that should be added
pub async fn add_new_wallets(_mints: Vec<String>) -> Result<(), CashuError> {
    /*
    let mut wallets = WALLETS.lock().await;
    for mint in mints {
        if let Ok(client) = Client::new(&mint) {
            if let Ok(mint_keys) = client.get_keys().await {
                let wallet = CashuWallet::new(client, mint_keys);
                wallets.insert(mint, Some(wallet));
            }
        }
    }
    */

    Ok(())
}

/// Load Proofs
pub async fn set_proofs(proofs: &str) -> Result<String, CashuError> {
    let proofs: HashMap<String, Proofs> = serde_json::from_str(proofs)?;

    let mut c_proofs = PROOFS.lock().await;

    *c_proofs = proofs;
    Ok(serde_json::to_string(&*c_proofs)?)
}

/// Get Proofs
pub async fn get_proofs() -> Result<String, CashuError> {
    let c_proofs = PROOFS.lock().await;

    Ok(serde_json::to_string(&*c_proofs)?)
}

pub async fn set_mints(mints: &str) -> Result<String, CashuError> {
    let mints: Vec<String> = serde_json::from_str(mints)?;

    add_new_wallets(mints).await?;

    let m: Vec<String> = WALLETS.lock().await.keys().cloned().collect();
    let m = serde_json::to_string(&m)?;

    Ok(m)
}

async fn wallet_for_url(mint_url: &str) -> Result<CashuWallet, CashuError> {
    let mut wallets = WALLETS.lock().await;
    let cashu_wallet = match wallets.get(mint_url) {
        Some(Some(wallet)) => wallet.clone(),
        _ => {
            let client = Client::new(mint_url)?;
            let keys = client.get_keys().await?;
            let wallet = CashuWallet::new(client, keys);
            wallets.insert(mint_url.to_string(), Some(wallet.clone()));

            wallet
        }
    };

    Ok(cashu_wallet)
}

pub async fn check_spendable(encoded_token: &str) -> Result<bool, CashuError> {
    let token = Token::from_str(encoded_token)?;
    let wallet = wallet_for_url(&token.token_info().1).await?;

    let check_spent = wallet
        .check_proofs_spent(token.token[0].clone().proofs)
        .await?;

    // REVIEW: This is a fairly naive check on if a token is spendable
    if check_spent.spendable.is_empty() {
        return Ok(false);
    } else {
        return Ok(true);
    }
}

async fn insert_proofs(mint_url: &str, proofs: Proofs) {
    let mut mint_proofs = PROOFS.lock().await;

    let current_proofs = mint_proofs.get(mint_url);

    let proofs = match current_proofs {
        Some(c_proofs) => {
            let mut c_proofs = c_proofs.clone();
            c_proofs.extend(proofs);

            c_proofs
        }
        None => proofs,
    };

    mint_proofs.insert(mint_url.to_string(), proofs);
}

pub async fn receive_token(encoded_token: &str) -> Result<String, CashuError> {
    let token = Token::from_str(encoded_token)?;
    let wallet = wallet_for_url(&token.token_info().1).await?;
    let mint_url = wallet.client.mint_url.to_string();
    let received_proofs = wallet.receive(encoded_token).await?;

    insert_proofs(&mint_url, received_proofs).await;

    get_proofs().await
}

// REVIEW: Naive coin selection
fn select_send_proofs(amount: u64, proofs: &Proofs) -> (Proofs, Proofs) {
    let mut send_proofs = vec![];
    let mut keep_proofs = vec![];

    let mut a = 0;

    for proof in proofs {
        if a < amount {
            send_proofs.push(proof.clone());
        } else {
            keep_proofs.push(proof.clone());
        }
        a += proof.amount.to_sat();
    }

    (send_proofs, keep_proofs)
}

pub async fn send(amount: u64, active_mint: &str) -> Result<String, CashuError> {
    let wallet = wallet_for_url(active_mint).await?;

    let mut proofs = PROOFS.lock().await;
    let active_proofs = proofs.get(active_mint);

    if let Some(proofs_l) = active_proofs {
        let (send_proofs, mut keep_proofs) = select_send_proofs(amount, proofs_l);
        let r = wallet.send(Amount::from_sat(amount), send_proofs).await?;
        keep_proofs.extend(r.change_proofs.clone());

        // Sent wallet proofs to change
        proofs.insert(active_mint.to_owned(), keep_proofs);

        // Add pending proofs
        PENDING_PROOFS
            .lock()
            .await
            .insert(active_mint.to_owned(), r.send_proofs.clone());

        let token = wallet.proofs_to_token(r.send_proofs, None);

        return Ok(token);
    }
    Ok("".to_string())
}

// TODO: Need to make sure wallet is in wallets
pub async fn request_mint(amount: u64, mint_url: &str) -> Result<RequestMintInfo, CashuError> {
    let wallet = wallet_for_url(mint_url).await?;
    let invoice = wallet.request_mint(Amount::from_sat(amount)).await?;
    Ok(RequestMintInfo {
        pr: invoice.pr.to_string(),
        hash: invoice.hash,
    })
}

pub async fn mint(amount: u64, hash: &str, mint: &str) -> Result<String, CashuError> {
    let wallets = WALLETS.lock().await;
    if let Some(Some(wallet)) = wallets.get(mint) {
        let proofs = wallet.mint_token(Amount::from_sat(amount), hash).await?;

        insert_proofs(mint, proofs).await;

        return get_proofs().await;
    }

    Err(CashuError("Could not get invoice".to_string()))
}

// TODO: Melt, untested as legend.lnbits has LN issues
pub async fn melt(amount: u64, invoice: &str, mint: &str) -> Result<String, CashuError> {
    let wallet = wallet_for_url(mint).await?;

    let invoice = str::parse::<Invoice>(&invoice).unwrap();
    let mut proofs = PROOFS.lock().await;
    let active_proofs = proofs.get(mint);

    if let Some(proofs_l) = active_proofs {
        let (send_proofs, mut keep_proofs) = select_send_proofs(amount, proofs_l);
        let change = wallet.melt(invoice, send_proofs).await?;
        keep_proofs.extend(change.change.unwrap());

        // Sent wallet proofs to change
        proofs.insert(mint.to_owned(), keep_proofs);
    }

    get_proofs().await
}

/// Decode invoice
pub async fn decode_invoice(invoice: &str) -> Result<InvoiceInfo, CashuError> {
    let invoice = str::parse::<Invoice>(&invoice).unwrap();

    let memo = match invoice.description() {
        lightning_invoice::InvoiceDescription::Direct(memo) => Some(memo.clone().into_inner()),
        InvoiceDescription::Hash(_) => None,
    };

    Ok(InvoiceInfo {
        // FIXME: Convert this conrrectlly
        amount: invoice.amount_milli_satoshis().unwrap() / 1000,
        hash: invoice.payment_hash().to_string(),
        memo,
    })
}

pub struct InvoiceInfo {
    pub amount: u64,
    pub hash: String,
    pub memo: Option<String>,
}

impl From<InvoiceInfo> for DartCObject {
    fn from(invoice_info: InvoiceInfo) -> Self {
        let mut feilds = vec![];

        let pr = DartCObject {
            ty: DartCObjectType::DartInt64,
            value: DartCObjectValue {
                as_int64: invoice_info.amount as i64,
            },
        };
        feilds.push(pr);

        let hash = DartCObject {
            ty: DartCObjectType::DartString,
            value: DartCObjectValue {
                as_string: CString::new(invoice_info.hash).unwrap().into_raw(),
            },
        };

        feilds.push(hash);

        if let Some(memo) = invoice_info.memo {
            let memo = DartCObject {
                ty: DartCObjectType::DartString,
                value: DartCObjectValue {
                    as_string: CString::new(memo).unwrap().into_raw(),
                },
            };
            feilds.push(memo)
        }

        DartCObject {
            ty: DartCObjectType::DartArray,
            value: DartCObjectValue {
                as_array: vec_to_native_array(feilds),
            },
        }
    }
}

// REVIEW: Have to define this twice since its from another crate
pub struct RequestMintInfo {
    pub pr: String,
    pub hash: String,
}

impl From<RequestMintInfo> for DartCObject {
    fn from(mint_info: RequestMintInfo) -> Self {
        let pr = DartCObject {
            ty: DartCObjectType::DartString,
            value: DartCObjectValue {
                as_string: CString::new(mint_info.pr).unwrap().into_raw(),
            },
        };
        let hash = DartCObject {
            ty: DartCObjectType::DartString,
            value: DartCObjectValue {
                as_string: CString::new(mint_info.hash).unwrap().into_raw(),
            },
        };
        DartCObject {
            ty: DartCObjectType::DartArray,
            value: DartCObjectValue {
                as_array: vec_to_native_array(vec![pr, hash]),
            },
        }
    }
}

pub struct TokenData {
    pub mint: String,
    pub amount: u64,
    pub memo: Option<String>, // spendable: Option<bool>,
}

fn vec_to_native_array(values: Vec<DartCObject>) -> DartNativeArray {
    let len = values.len() as isize;
    let mut arr = DartNativeArray {
        length: len,
        values: std::ptr::null_mut(),
    };
    if len > 0 {
        let mut ptrs = Vec::with_capacity(len as usize);
        for value in values {
            ptrs.push(Box::into_raw(Box::new(value)));
        }
        arr.values = ptrs.as_mut_ptr();
        std::mem::forget(ptrs);
    }
    arr
}

impl From<TokenData> for DartCObject {
    fn from(my_type: TokenData) -> Self {
        let mut feilds = vec![];

        let mint = DartCObject {
            ty: DartCObjectType::DartString,
            value: DartCObjectValue {
                as_string: CString::new(my_type.mint).unwrap().into_raw(),
            },
        };
        feilds.push(mint);
        let value = DartCObject {
            ty: DartCObjectType::DartInt64,
            value: DartCObjectValue {
                as_int64: my_type.amount as i64,
            },
        };

        feilds.push(value);

        if let Some(memo) = my_type.memo {
            let memo = DartCObject {
                ty: DartCObjectType::DartString,
                value: DartCObjectValue {
                    as_string: CString::new(memo).unwrap().into_raw(),
                },
            };
            feilds.push(memo)
        }

        DartCObject {
            ty: DartCObjectType::DartArray,
            value: DartCObjectValue {
                as_array: vec_to_native_array(feilds),
            },
        }
    }
}

pub async fn decode_token(encoded_token: &str) -> Result<TokenData, CashuError> {
    let token = Token::from_str(encoded_token)?;

    let token_info = token.token_info();

    Ok(TokenData {
        mint: token_info.1,
        amount: token_info.0,
        memo: token.memo,
    })
}

/*
pub async fn create_client(url: &str) -> Result<String, CashuError> {
    let client = Client::new(url)?;

    let client = Cashu { mints: vec![] };
    Ok(url.to_string())
}
*/
