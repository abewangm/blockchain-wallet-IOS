var Buffer = Blockchain.Buffer;
var CryptoJS = Blockchain.CryptoJS;

var MyWallet = Blockchain.MyWallet;
var WalletStore = Blockchain.WalletStore;
var WalletCrypto = Blockchain.WalletCrypto;
var BlockchainAPI = Blockchain.API;
var ImportExport = Blockchain.ImportExport;
var BlockchainSettingsAPI = Blockchain.BlockchainSettingsAPI;
var Helpers = Blockchain.Helpers;
var Payment = Blockchain.Payment;

APP_NAME = 'javascript_iphone_app';
APP_VERSION = '3.0';
API_CODE = '35e77459-723f-48b0-8c9e-6e9e8f54fbd3';
// Don't use minified JS files when loading web worker scripts
min = false;

// Set the API code for the iOS Wallet for the server calls
WalletStore.setAPICode(API_CODE);

var MyWalletPhone = {};
var pendingTransactions = {};
var currentPayment = null;

window.onerror = function(errorMsg, url, lineNumber) {
    device.execute("jsUncaughtException:url:lineNumber:", [errorMsg, url, lineNumber]);
};

console.log = function(message) {
    device.execute("log:", [message]);
};

document.addEventListener("DOMContentLoaded", function(event) {
    MyWallet.logout = function() {}
});


// Register for JS event handlers and forward to Obj-C handlers

WalletStore.addEventListener(function (event, obj) {
    var eventsWithObjCHandlers = ["did_fail_set_guid", "did_multiaddr", "did_set_latest_block", "error_restoring_wallet", "logging_out", "on_backup_wallet_start", "on_backup_wallet_error", "on_backup_wallet_success", "on_block", "on_tx", "ws_on_close", "ws_on_open", "did_load_wallet"];

    if (event == 'msg') {
        if (obj.type == 'error') {
                             
            if (obj.message != "For Improved security add an email address to your account.") {
                // Cancel busy view in case any error comes in - except for add email, that's handled differently in makeNotice
                device.execute('loading_stop');
            }
                             
            if (obj.message == "Error Downloading Account Settings") {
                device.execute('on_error_downloading_account_settings');
                return;
            }
                             
            if (obj.message == "update-currency-error" || obj.message == "update-btc-currency-error") {
                device.execute('on_change_currency_error');
                return;
            }

            // Some messages are JSON objects and the error message is in the map
            try {
                var messageJSON = JSON.parse(obj.message);
                if (messageJSON && messageJSON.initial_error) {
                    device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+messageJSON.initial_error]);
                    return;
                }
            } catch (e) {}

            device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+obj.message]);
        }

        else if (obj.type == 'success') {
            device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+obj.message]);
        }
                             
        else if (obj.type == 'ajax-start' && obj.message == "ajax call started") {
            webSocketDisconnect();
        }
        
        else if (obj.type == 'ajax-start' && obj.message == "ajax call ended") {
            simpleWebSocketConnect();
        }

        return;
    }

    if (eventsWithObjCHandlers.indexOf(event) == -1) {
        return;
    }

    // Obj-C part of handling events (calls function of event name in Wallet.m)
    if (obj) {
        event += ':';
    }

    device.execute(event, [obj]);
});


// My Wallet phone functions

MyWalletPhone.cancelTxSigning = function() {
    for (var key in pendingTransactions) {
        pendingTransactions[key].cancel();
    }
}

MyWalletPhone.upgradeToHDWallet = function(firstAccountName) {
    var success = function () {
        console.log('Upgraded legacy wallet to HD wallet');

        MyWallet.wallet.getHistory();
        device.execute('loading_stop');
        device.execute('upgrade_success');
    };

    var error = function (e) {
        console.log('Error upgrading legacy wallet to HD wallet: ' + e);
        device.execute('loading_stop');
    };
    
    if (MyWallet.wallet.isDoubleEncrypted) {
        MyWalletPhone.getSecondPassword(function (pw) {
            MyWallet.wallet.newHDWallet(firstAccountName, pw, success, error);
        });
    }
    else {
        MyWallet.wallet.newHDWallet(firstAccountName, null, success, error);
    }
};

MyWalletPhone.createAccount = function(label) {
    var success = function () {
        console.log('Created new account');

        device.execute('loading_stop');

        device.execute('reload');
    };

    if (MyWallet.wallet.isDoubleEncrypted) {
        MyWalletPhone.getSecondPassword(function (pw) {
            MyWallet.wallet.newAccount(label, pw, null, success);
        });
    }
    else {
        MyWallet.wallet.newAccount(label, null, null, success);
    }
};

MyWalletPhone.getActiveAccounts = function() {
    var accounts = MyWallet.wallet.hdwallet.accounts;
    
    var activeAccounts = accounts.filter(function(account) { return account.archived === false; });
    
    return activeAccounts;
};

MyWalletPhone.getIndexOfActiveAccount = function(num) {
    var activeAccounts = MyWalletPhone.getActiveAccounts();

    var realNum = activeAccounts[num].index;

    return realNum;
};

MyWalletPhone.getDefaultAccountIndex = function() {
    var index = MyWallet.wallet.hdwallet.defaultAccountIndex;

    var activeAccounts = MyWalletPhone.getActiveAccounts();

    var defaultAccountIndex = null;
    for (var i = 0; i < activeAccounts.length; i++) {
        var account = activeAccounts[i];
        if (account.index === index) {
            defaultAccount = i;
        }
    }

    if (defaultAccountIndex) {
        return defaultAccountIndex;
    }

    return 0;
}

MyWalletPhone.getAccountsCount = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        return 0;
    }

    var activeAccounts = MyWalletPhone.getActiveAccounts();

    return activeAccounts.length;
};

MyWalletPhone.getBalanceForAccount = function(num) {
    return MyWallet.wallet.hdwallet.accounts[MyWalletPhone.getIndexOfActiveAccount(num)].balance;
};

MyWalletPhone.getLabelForAccount = function(num) {
    return MyWallet.wallet.hdwallet.accounts[MyWalletPhone.getIndexOfActiveAccount(num)].label;
};

MyWalletPhone.setLabelForAccount = function(num, label) {
    MyWallet.wallet.hdwallet.accounts[MyWalletPhone.getIndexOfActiveAccount(num)].label = label;
};

MyWalletPhone.getReceivingAddressForAccount = function(num) {
    return MyWallet.wallet.hdwallet.accounts[MyWalletPhone.getIndexOfActiveAccount(num)].receiveAddress;
};

MyWalletPhone.createNewPayment = function() {
    console.log('Creating new payment');
    currentPayment = new Payment();
}

MyWalletPhone.changePaymentFrom = function(from) {
    currentPayment.from(from);
}

MyWalletPhone.changePaymentTo = function(to) {
    currentPayment.to(to);
}

MyWalletPhone.changePaymentAmount = function(amount) {
    currentPayment.amount(amount);
}

MyWalletPhone.changePaymentAmountThenConfirm = function(amount) {
    currentPayment.amount(amount);
}

MyWalletPhone.getPaymentFee = function() {
    
    currentPayment.build();
    
    currentPayment.payment.then(function(x) {
        console.log('getPaymentFee');
        device.execute('update_fee:', [x.transaction.fee]);
    });
    
    currentPayment.payment.catch(function(error) {
        var errorArgument;
        if (error.error) {
            errorArgument = error.error;
        } else {
            errorArgument = error.message;
        }
                                 
        console.log('error updating fee: ' + errorArgument);
        device.execute('on_error_update_fee:', [errorArgument]);
    });
}

MyWalletPhone.checkIfUserIsOverSpending = function() {

    currentPayment.payment = currentPayment.payment.then(function(x) {
        device.execute('check_max_amount:fee:', [x.sweepAmount, x.sweepFee]);
        return x;
    });
}

MyWalletPhone.sweepPayment = function() {
    
    currentPayment
      .sweep()
    
    currentPayment.payment = currentPayment.payment.then(function(x) {
        console.log('SweepFee: ' + x.sweepFee);
        console.log('SweepAmount: ' + x.sweepAmount);
        console.log('maxAmount and fee are' + x.sweepAmount + ',' + x.sweepFee);
        device.execute('update_max_amount:fee:', [x.sweepAmount, x.sweepFee]);
        return x;
    });
};

MyWalletPhone.setTransactionFee = function(fee) {
    MyWallet.wallet.fee_per_kb = fee;
}

MyWalletPhone.getTransactionFee = function() {
    return MyWallet.wallet.fee_per_kb;
}

MyWalletPhone.setPbkdf2Iterations = function(iterations) {
    var success = function () {
        console.log('Updated PBKDF2 iterations');
    };

    var error = function () {
        console.log('Error updating PBKDF2 iterations');
    };

    if (MyWallet.wallet.isDoubleEncrypted) {
        MyWalletPhone.getSecondPassword(function (pw) {
            MyWallet.setPbkdf2Iterations(iterations, success, error, pw);
        });
    }
    else {
        MyWallet.setPbkdf2Iterations(iterations, success, error, null);
    }
};

MyWalletPhone.getLegacyArchivedAddresses = function() {
    return MyWallet.wallet.addresses.filter(function (addr) {
        return MyWallet.wallet.key(addr).archived === true;
    });
};

MyWalletPhone.login = function(user_guid, shared_key, resend_code, inputedPassword, twoFACode, success, needs_two_factor_code, wrong_two_factor_code, other_error) {
    // Timing
    var t0 = new Date().getTime(), t1;
    
    var logTime = function(name) {
        t1 = new Date().getTime();
        
        console.log('----------');
        console.log('Execution time ' + name + ': ' + (t1 - t0) + ' milliseconds.')
        console.log('----------');
        
        t0 = t1;
    };
    
    var fetch_success = function() {
        logTime('download');
        
        device.execute('loading_start_decrypt_wallet');
    };
    
    var decrypt_success = function() {
        logTime('decrypt');
        
        device.execute('did_decrypt');
        
        device.execute('loading_start_build_wallet');
    };
    
    var build_hd_success = function() {
        logTime('build HD wallet');
        
        device.execute('loading_start_multiaddr');
    };
    
    var history_success = function() {
        logTime('get history');
        
        device.execute('loading_stop');
        
        device.execute('did_load_wallet');
        
        MyWallet.wallet.getBalancesForArchived();
    };
    
    var success = function() {
        var getHistory = MyWallet.wallet.getHistory();
        getHistory.then(history_success);
    };
    
    var other_error = function(e) {
        console.log('login: other error: ' + e);
        device.execute('loading_stop');
        device.execute('error_other_decrypting_wallet:', [e]);
    };
    
    var needs_two_factor_code = function(type) {
        console.log('login: needs 2fa of type: ' + WalletStore.get2FATypeString());
        device.execute('loading_stop');
        device.execute('on_fetch_needs_two_factor_code');
    };
    
    device.execute('loading_start_download_wallet');
    
    twoFACode = null;
    MyWallet.login(user_guid, shared_key, inputedPassword, twoFACode, success, needs_two_factor_code, wrong_two_factor_code, null, other_error, fetch_success, decrypt_success, build_hd_success);
};

MyWalletPhone.quickSend = function() {
    
    var id = ''+Math.round(Math.random()*100000);
    
    var listener = {
        on_start : function() {
            device.execute('tx_on_start:', [id]);
        },
        on_begin_signing : function() {
            device.execute('tx_on_begin_signing:', [id]);
        },
        on_sign_progress : function(i) {
            device.execute('tx_on_sign_progress:input:', [id, i]);
        },
        on_finish_signing : function() {
            device.execute('tx_on_finish_signing:', [id]);
        }
    };
    
    var success = function(payment) {
        device.execute('tx_on_success:', [id]);
        delete pendingTransactions[id];
    };
    
    var error = function(error) {
        device.execute('tx_on_error:error:', [id, ''+error]);
        delete pendingTransactions[id];
    };
    
    currentPayment.listener(listener);
    
    if (MyWallet.wallet.isDoubleEncrypted) {
        MyWalletPhone.getSecondPassword(function (pw) {
            currentPayment
                .sign(pw)
                .publish()
                .payment.then(success).catch(error);
        });
    } else {
        currentPayment
            .sign()
            .publish()
            .payment.then(success).catch(error);
    }

    return id;
};

MyWalletPhone.apiGetPINValue = function(key, pin) {
    var data = {
        format: 'json',
        method: 'get',
        pin : pin,
        key : key
    };
    var s = function (responseObject) {
        device.execute('on_pin_code_get_response:', [responseObject]);
    };
    var e = function (res) {
        // Connection timed out
        
        if (res && res.statusText == "timeout") {
            device.execute('on_error_pin_code_get_timeout');
        }
        // Empty server response
        else if (!res || !res.responseText || res.responseText.length == 0) {
            device.execute('on_error_pin_code_get_empty_response');
        } else {
            try {
                var responseObject = JSON.parse(res.responseText);
                
                if (!responseObject) {
                    throw 'Response Object nil';
                }
                
                device.execute('on_pin_code_get_response:', [responseObject]);
            } catch (e) {
                // Invalid server response
                device.execute('on_error_pin_code_get_invalid_response');
            }
        }
    };
    
    BlockchainAPI.request("POST", 'pin-store', data, true, false).then(s).catch(e);
};

MyWalletPhone.pinServerPutKeyOnPinServerServer = function(key, value, pin) {
    var data = {
        format: 'json',
        method: 'put',
        value : value,
        pin : pin,
        key : key
    };
    var s = function (responseObject) {
        
        responseObject.key = key;
        responseObject.value = value;
        
        device.execute('on_pin_code_put_response:', [responseObject]);
    };
    var e = function (res) {
        
        if (!res || !res.responseText || res.responseText.length == 0) {
            device.execute('on_error_pin_code_put_error:', ['Unknown Error']);
        } else {
            try {
                var responseObject = JSON.parse(res.responseText);
                
                responseObject.key = key;
                responseObject.value = value;
                
                device.execute('on_pin_code_put_response:', [responseObject]);
            } catch (e) {
                device.execute('on_error_pin_code_put_error:', [res.responseText]);
            }
        }
    };
    
    BlockchainAPI.request("POST", 'pin-store', data, true, false).then(s).catch(e);
};

MyWalletPhone.newAccount = function(password, email, firstAccountName, isHD) {
    var success = function(guid, sharedKey, password) {
        device.execute('loading_stop');

        device.execute('on_create_new_account:sharedKey:password:', [guid, sharedKey, password]);
    };

    var error = function(e) {
        device.execute('loading_stop');

        device.execute('on_error_creating_new_account:', [''+e]);
    };

    device.execute('loading_start_new_account');

    var isCreatingHD = Boolean(isHD);
        
    MyWallet.createNewWallet(email, password, firstAccountName, null, null, success, error, isCreatingHD);
};

MyWalletPhone.parsePairingCode = function (raw_code) {
    var success = function (pairing_code) {
        device.execute("didParsePairingCode:", [pairing_code]);
    };

    var error = function (e) {
        device.execute("errorParsingPairingCode:", [e]);
    };

    try {
        if (raw_code == null || raw_code.length == 0) {
            throw "Invalid Pairing QR Code";
        }

        if (raw_code[0] != '1') {
            throw "Invalid Pairing Version Code " + raw_code[0];
        }

        var components = raw_code.split("|");

        if (components.length < 3) {
            throw "Invalid Pairing QR Code. Not enough components.";
        }

        var guid = components[1];
        if (guid.length != 36) {
            throw "Invalid Pairing QR Code. GUID wrong length.";
        }

        var encrypted_data = components[2];
        
        var data = {
            format: 'plain',
            method: 'pairing-encryption-password',
            guid: guid
        };
        var s = function (encryption_phrase) {
            try {
                
                // Pairing code PBKDF2 iterations is set to 10 in My Wallet
                var pairing_code_pbkdf2_iterations = 10;
                var decrypted = WalletCrypto.decrypt(encrypted_data, encryption_phrase, pairing_code_pbkdf2_iterations);
                
                if (decrypted != null) {
                    var components2 = decrypted.split("|");
                    
                    success({
                            version: raw_code[0],
                            guid: guid,
                            sharedKey: components2[0],
                            password: CryptoJS.enc.Hex.parse(components2[1]).toString(CryptoJS.enc.Utf8)
                            });
                } else {
                    error('Decryption Error');
                }
            } catch(e) {
                error(''+e);
            }
        };
        var e = function (res) {
            error('Pairing Code Server Error');
        };
        
        BlockchainAPI.request("POST", 'wallet', data, true, false).then(s).catch(e);
    } catch (e) {
        error(''+e);
    }
};

MyWalletPhone.addAddressBookEntry = function(bitcoinAddress, label) {
    MyWallet.addAddressBookEntry(bitcoinAddress, label);

    MyWallet.backupWallet();
};

MyWalletPhone.detectPrivateKeyFormat = function(privateKeyString) {
    try {
        return MyWallet.detectPrivateKeyFormat(privateKeyString);
    } catch(e) {
        return null;
    }
};

MyWalletPhone.hasEncryptedWalletData = function() {
    var data = MyWallet.getEncryptedWalletData();

    return data && data.length > 0;
};

MyWalletPhone.getWsReadyState = function() {
    if (!ws) return -1;

    return ws.readyState;
};

MyWalletPhone.get_history = function() {
    var success = function () {
        console.log('Got wallet history');
        device.execute('loading_stop');
        device.execute('on_get_history_success');
    };
    
    var error = function () {
        console.log('Error getting wallet history');
        device.execute('loading_stop');
    };
    
    device.execute('loading_start_get_history');
    
    var getHistory = MyWallet.wallet.getHistory();
    getHistory.then(success).catch(error);
};

MyWalletPhone.get_wallet_and_history = function() {
    var success = function () {
        console.log('Got wallet and history');
        device.execute('loading_stop');
    };
    
    var error = function () {
        console.log('Error getting wallet and history');
        device.execute('loading_stop');
    };
    
    device.execute('loading_start_get_wallet_and_history');
    
    MyWallet.getWallet(function() {
        var getHistory = MyWallet.wallet.getHistory();
        getHistory.then(success).catch(error);
    });
};

MyWalletPhone.getMultiAddrResponse = function() {
    var obj = {};

    obj.transactions = WalletStore.getTransactions();
    obj.total_received = MyWallet.wallet.totalReceived;
    obj.total_sent = MyWallet.wallet.totalSent;
    obj.final_balance = MyWallet.wallet.finalBalance;
    obj.n_transactions = MyWallet.wallet.numberTx;
    obj.addresses = MyWallet.wallet.addresses;

    obj.symbol_local = symbol_local;
    obj.symbol_btc = symbol_btc;

    return obj;
};

MyWalletPhone.addPrivateKey = function(privateKeyString) {
    var success = function(address) {
        console.log('Add private key success');
        
        device.execute('on_add_private_key:', [address.address]);
    };
    var error = function(e) {
        console.log('Add private key Error');
        
        var message = 'There was an error importing this private key';
        
        if (e === 'presentInWallet') {
            message = 'Key already imported';
        }
        else if (e === 'needsBip38') {
            message = 'Missing BIP38 password';
        }
        else if (e === 'wrongBipPass') {
            message = 'Wrong BIP38 password';
        }
        
        device.execute('on_error_adding_private_key:', [message]);
    };

    var needsBip38Passsword = MyWallet.detectPrivateKeyFormat(privateKeyString) === 'bip38';

    if (needsBip38Passsword) {
        MyWalletPhone.getPrivateKeyPassword(function (bip38Pass) {
            if (MyWallet.wallet.isDoubleEncrypted) {
                device.execute('on_add_private_key_start');
                MyWalletPhone.getSecondPassword(function (pw) {
                    var promise = MyWallet.wallet.importLegacyAddress(privateKeyString, null, pw, bip38Pass);
                    promise.then(success, error);
                });
            }
            else {
                device.execute('on_add_private_key_start');
                var promise = MyWallet.wallet.importLegacyAddress(privateKeyString, null, null, bip38Pass);
                promise.then(success, error);
            }
        });
    }
    else {
        if (MyWallet.wallet.isDoubleEncrypted) {
            device.execute('on_add_private_key_start');
            MyWalletPhone.getSecondPassword(function (pw) {
                var promise = MyWallet.wallet.importLegacyAddress(privateKeyString, null, pw, null);
                promise.then(success, error);
            });
        }
        else {
            device.execute('on_add_private_key_start');
            var promise = MyWallet.wallet.importLegacyAddress(privateKeyString, null, null, null);
            promise.then(success, error);
        }
    }
};

MyWalletPhone.getRecoveryPhrase = function(secondPassword) {
    var recoveryPhrase = MyWallet.wallet.getMnemonic(secondPassword);
    
    device.execute('on_success_get_recovery_phrase:', [recoveryPhrase]);
};

// Shared functions

function simpleWebSocketConnect() {
    if (!MyWallet.getIsInitialized()) {
        // The websocket should only operate when the wallet is initialized. We get calls before and after this is true because we stop and start the websocket for ajax calls
        return;
    }

    console.log('Connecting websocket...');

    if (!window.WebSocket) {
        console.log('No websocket support in JS runtime');
        return;
    }

    if (ws && reconnectInterval) {
        console.log('Websocket already exists. Connection status: ' + ws.readyState);
        return;
    }

    // This should never really happen - try to recover gracefully
    if (ws) {
        console.log('Websocket already exists but no reconnectInverval. Connection status: ' + ws.readyState);
        webSocketDisconnect();
    }

    MyWallet.connectWebSocket();
}

function webSocketDisconnect() {
    if (!MyWallet.getIsInitialized()) {
        // The websocket should only operate when the wallet is initialized. We get calls before and after this is true because we stop and start the websocket for ajax calls
        return;
    }

    console.log('Disconnecting websocket...');

    if (!window.WebSocket) {
        console.log('No websocket support in JS runtime');
        return;
    }

    if (reconnectInterval) {
        clearInterval(reconnectInterval);
        reconnectInterval = null;
    }
    else {
        console.log('No reconnectInterval');
    }

    if (!ws) {
        console.log('No websocket object');
        return;
    }

    ws.close();

    ws = null;
}


// Get passwords

MyWalletPhone.getPrivateKeyPassword = function(callback) {
    // Due to the way the JSBridge handles calls with success/error callbacks, we need a first argument that can be ignored
    device.execute("getPrivateKeyPassword:", ["discard"], function(pw) {
        callback(pw);
    }, function() {});
};

MyWalletPhone.getSecondPassword = function(callback) {
    // Due to the way the JSBridge handles calls with success/error callbacks, we need a first argument that can be ignored
    device.execute("getSecondPassword:", ["discard"], function(pw) {
        callback(pw);
    }, function() {});
};


// Overrides

ImportExport.Crypto_scrypt = function(passwd, salt, N, r, p, dkLen, callback) {
    if(typeof(passwd) !== 'string') {
        passwd = passwd.toJSON().data;
    }

    if(typeof(salt) !== 'string') {
        salt = salt.toJSON().data;
    }

    device.execute('crypto_scrypt:salt:n:r:p:dkLen:', [passwd, salt, N, r, p, dkLen], function(buffer) {
        var bytes = new Buffer(buffer, 'hex');

        callback(bytes);
    }, function(e) {
        error(''+e);
    });
};

// TODO what should this value be?
MyWallet.getNTransactionsPerPage = function() {
    return 50;
};

// Settings

MyWalletPhone.get_account_info = function () {
    
    var success = function (data) {
        console.log('Getting account info');
        var accountInfo = JSON.stringify(data, null, 2);
        device.execute('on_get_account_info_success:', [accountInfo]);
    }
    
    var error = function (e) {
        console.log('Error getting account info: ' + e);
    };
    
    BlockchainSettingsAPI.get_account_info(success, error);
}

MyWalletPhone.change_email_account = function(email) {
    
    var success = function () {
        console.log('Changing email');
        device.execute('on_change_email_success');
    };
    
    var error = function (e) {
        console.log('Error changing email: ' + e);
    };
    
    BlockchainSettingsAPI.change_email(email, success, error);
}

MyWalletPhone.resend_verification_email = function(email) {
    
    var success = function () {
        console.log('Resending verification email');
        device.execute('on_resend_verification_email_success');
    };
    
    var error = function (e) {
        console.log('Error resending verification email: ' + e);
    };
    
    BlockchainSettingsAPI.resendEmailConfirmation(email, success, error);
}

MyWalletPhone.change_local_currency = function(code) {
    
    var success = function () {
        console.log('Changing local currency');
        device.execute('on_change_local_currency_success');
    };
    
    var error = function (e) {
        console.log('Error changing local currency: ' + e);
    };
    
    BlockchainSettingsAPI.change_local_currency(code, success, error);
}

MyWalletPhone.verify_email = function(code) {
    
    var success = function () {
        console.log('Verifying email');
        device.execute('on_verify_email_success');
    };
    
    var error = function (e) {
        console.log('Error verifying email: ' + e);
        device.execute('on_verify_email_error');
    };
    
    BlockchainSettingsAPI.verifyEmail(code, success, error);
}

MyWalletPhone.change_btc_currency = function(code) {
    
    var success = function () {
        console.log('Changing btc currency');
        device.execute('on_change_local_currency_success');
    };
    
    var error = function (e) {
        console.log('Error changing btc currency: ' + e);
    };
    
    BlockchainSettingsAPI.change_btc_currency(code, success, error);
}

MyWalletPhone.get_all_currency_symbols = function () {
    
    var success = function (data) {
        console.log('Getting all currency symbols');
        var currencySymbolData = JSON.stringify(data, null, 2);
        device.execute('on_get_all_currency_symbols_success:', [currencySymbolData]);
    };
    
    var error = function (e) {
        console.log('Error getting all currency symbols: ' + e);
    };
    
    var promise = BlockchainAPI.getTicker();
    promise.then(success, error);
}

MyWalletPhone.get_password_strength = function(password) {
    var strength = Helpers.scorePassword(password);
    return strength;
}

MyWalletPhone.generateNewAddress = function() {
    MyWallet.getWallet(function() {
        
        device.execute('loading_start_generate_new_address');
                       
        var label = null;
                       
        var success = function () {
            console.log('Success creating new address');
            MyWalletPhone.get_history();
            device.execute('loading_stop');
        };
        
        var error = function (e) {
            console.log('Error creating new address: ' + e);
            device.execute('loading_stop');
            device.execute('on_error_creating_new_address:', [e]);
        };
                       
        if (MyWallet.wallet.isDoubleEncrypted) {
            MyWalletPhone.getSecondPassword(function (pw) {
                MyWallet.wallet.newLegacyAddress(label, pw, success, error);
            });
        } else {
                MyWallet.wallet.newLegacyAddress(label, '', success, error);
        }
   });
};

MyWalletPhone.checkIfWalletHasAddress = function(address) {
    var addresses = MyWallet.wallet.addresses;
    return (addresses.indexOf(address) > -1);
}

MyWalletPhone.recoverWithPassphrase = function(email, password, passphrase) {
    
    if (MyWallet.isValidateBIP39Mnemonic(passphrase)) {
        console.log('recovering wallet');
        
        var success = function (recoveredWalletDictionary) {
            console.log('recovery success');
            device.execute('on_success_recover_with_passphrase:', [recoveredWalletDictionary]);
        }
        
        var error = function(error) {
            console.log('recovery error after validation: ' + error);
            device.execute('on_error_recover_with_passphrase:', [error]);
        }
        
        MyWallet.recoverFromMnemonic(email, password, passphrase, '', success, error);

    } else {
        console.log('recovery error: ' + error);
        device.execute('on_error_recover_with_passphrase:', [error]);
    };
}

MyWalletPhone.setLabelForAddress = function(address, label) {
    if (label == '') {
        label = null;
    }
    MyWallet.wallet.key(address).label = label;
}