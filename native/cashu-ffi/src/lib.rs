#![allow(clippy::missing_safety_doc, clippy::not_unsafe_ptr_arg_deref)]

use allo_isolate::Isolate;
use ffi_helpers::null_pointer_check;
use lazy_static::lazy_static;
use std::{ffi::CStr, io, os::raw};
use tokio::runtime::{Builder, Runtime};

lazy_static! {
    static ref RUNTIME: io::Result<Runtime> = Builder::new_multi_thread()
        .enable_all()
        .thread_name("flutterust")
        .build();
}

macro_rules! error {
    ($result:expr) => {
        error!($result, 0);
    };
    ($result:expr, $error:expr) => {
        match $result {
            Ok(value) => value,
            Err(e) => {
                ffi_helpers::update_last_error(e);
                return $error;
            }
        }
    };
}

macro_rules! cstr {
    ($ptr:expr) => {
        cstr!($ptr, 0)
    };
    ($ptr:expr, $error:expr) => {{
        null_pointer_check!($ptr);
        error!(unsafe { CStr::from_ptr($ptr).to_str() }, $error)
    }};
}

macro_rules! runtime {
    () => {
        match RUNTIME.as_ref() {
            Ok(rt) => rt,
            Err(_) => {
                return 0;
            }
        }
    };
}

#[no_mangle]
pub unsafe extern "C" fn last_error_length() -> i32 {
    ffi_helpers::error_handling::last_error_length()
}

#[no_mangle]
pub unsafe extern "C" fn error_message_utf8(buf: *mut raw::c_char, length: i32) -> i32 {
    ffi_helpers::error_handling::error_message_utf8(buf, length)
}

#[no_mangle]
pub extern "C" fn create_wallet(port: i64, url: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let url = cstr!(url);
    let t = Isolate::new(port).task(cashu::create_wallet(url));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn remove_wallet(port: i64, url: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let url = cstr!(url);
    let t = Isolate::new(port).task(cashu::remove_wallet(url));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn get_mints(port: i64) -> i32 {
    let rt = runtime!();
    let t = Isolate::new(port).task(cashu::get_wallets());
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn receive_token(port: i64, token: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let token = cstr!(token);
    let t = Isolate::new(port).task(cashu::receive_token(token));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn decode_token(port: i64, token: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let token = cstr!(token);
    let t = Isolate::new(port).task(cashu::decode_token(token));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn decode_invoice(port: i64, invoice: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let invoice = cstr!(invoice);
    let t = Isolate::new(port).task(cashu::decode_invoice(invoice));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn pay_invoice(
    port: i64,
    amount: i64,
    invoice: *const raw::c_char,
    mint: *const raw::c_char,
) -> i32 {
    let rt = runtime!();
    let mint = cstr!(mint);
    let invoice = cstr!(invoice);
    let t = Isolate::new(port).task(cashu::melt(amount as u64, invoice, mint));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn set_proofs(port: i64, proofs: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let token = cstr!(proofs);
    let t = Isolate::new(port).task(cashu::set_proofs(token));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn set_mints(port: i64, mints: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let ms = cstr!(mints);
    let t = Isolate::new(port).task(cashu::set_mints(ms));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn get_proofs(port: i64) -> i32 {
    let rt = runtime!();
    let t = Isolate::new(port).task(cashu::get_proofs());
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn get_balances(port: i64) -> i32 {
    let rt = runtime!();
    let t = Isolate::new(port).task(cashu::get_balances());
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn send(port: i64, amount: i64, active_mint: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let active_mint = cstr!(active_mint);
    let t = Isolate::new(port).task(cashu::send(amount as u64, active_mint));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn check_spendable(port: i64, encoded_token: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let token = cstr!(encoded_token);
    let t = Isolate::new(port).task(cashu::check_spendable(token));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn request_mint(port: i64, amount: i64, mint: *const raw::c_char) -> i32 {
    let rt = runtime!();
    let mint = cstr!(mint);
    let t = Isolate::new(port).task(cashu::request_mint(amount as u64, mint));
    rt.spawn(t);
    1
}

#[no_mangle]
pub extern "C" fn mint(
    port: i64,
    amount: i64,
    hash: *const raw::c_char,
    mint: *const raw::c_char,
) -> i32 {
    let rt = runtime!();
    let mint = cstr!(mint);
    let hash = cstr!(hash);
    let t = Isolate::new(port).task(cashu::mint(amount as u64, hash, mint));
    rt.spawn(t);
    1
}

/*
#[no_mangle]
pub extern "C" fn wallets_from_proofs(port: i64) -> i32 {
    let rt = runtime!();
    let t = Isolate::new(port).task(cashu::add_new_wallets());
    rt.spawn(t);
    1
}
*/
/*

#[no_mangle]
pub extern "C" fn token_info(token: *const raw::c_char) -> String {
    let token = cstr!(token);
    cashu::decode_token(token).1
}
*/
