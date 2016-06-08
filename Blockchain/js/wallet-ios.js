var Buffer = Blockchain.Buffer;

var MyWallet = Blockchain.MyWallet;
var WalletStore = Blockchain.WalletStore;
var WalletCrypto = Blockchain.WalletCrypto;
var BlockchainAPI = Blockchain.API;
var BlockchainSettingsAPI = Blockchain.BlockchainSettingsAPI;
var Helpers = Blockchain.Helpers;
var Payment = Blockchain.Payment;
var WalletNetwork = Blockchain.WalletNetwork;
var RNG = Blockchain.RNG;
var Address = Blockchain.Address;
var Bitcoin = Blockchain.Bitcoin;

APP_NAME = 'javascript_iphone_app';
APP_VERSION = '3.0';
API_CODE = '35e77459-723f-48b0-8c9e-6e9e8f54fbd3';
// Don't use minified JS files when loading web worker scripts
min = false;

// Set the API code for the iOS Wallet for the server calls
BlockchainAPI.API_CODE = API_CODE;
BlockchainAPI.AJAX_TIMEOUT = 30000; // 30 seconds
BlockchainAPI.API_ROOT_URL = 'https://api.blockchain.info/'

var MyWalletPhone = {};
var currentPayment = null;
var transferAllPayments = {};

window.onerror = function(errorMsg, url, lineNumber) {
    device.execute("jsUncaughtException:url:lineNumber:", [errorMsg, url, lineNumber]);
};

console.log = function(message) {
    device.execute("log:", [message]);
};

// Register for JS event handlers and forward to Obj-C handlers

WalletStore.addEventListener(function (event, obj) {
    var eventsWithObjCHandlers = ["did_fail_set_guid", "did_multiaddr", "did_set_latest_block", "error_restoring_wallet", "logging_out", "on_backup_wallet_start", "on_backup_wallet_error", "on_backup_wallet_success", "on_tx_received", "ws_on_close", "ws_on_open", "did_load_wallet"];

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

MyWalletPhone.upgradeToV3 = function(firstAccountName) {
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
            MyWallet.wallet.upgradeToV3(firstAccountName, pw, success, error);
        });
    }
    else {
        MyWallet.wallet.upgradeToV3(firstAccountName, null, success, error);
    }
};

MyWalletPhone.createAccount = function(label) {
    var success = function () {
        console.log('Created new account');

        device.execute('loading_stop');

        device.execute('on_add_new_account');
        
        device.execute('reload');
    };

    var error = function (error) {
        device.execute('on_error_add_new_account:', [error]);
    }
    
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
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return [];
    }
    
    var accounts = MyWallet.wallet.hdwallet.accounts;
    
    var activeAccounts = accounts.filter(function(account) { return account.archived === false; });
    
    return activeAccounts;
};

MyWalletPhone.getIndexOfActiveAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }
    
    var activeAccounts = MyWalletPhone.getActiveAccounts();

    var realNum = activeAccounts[num].index;

    return realNum;
};

MyWalletPhone.getDefaultAccountIndex = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }
    
    var accounts = MyWallet.wallet.hdwallet.accounts;
    
    var index = MyWallet.wallet.hdwallet.defaultAccountIndex;

    var defaultAccountIndex = null;
    for (var i = 0; i < accounts.length; i++) {
        var account = accounts[i];
        if (account.index === index) {
            defaultAccountIndex = i;
        }
    }

    if (defaultAccountIndex) {
        return defaultAccountIndex;
    }

    return 0;
}

MyWalletPhone.setDefaultAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }
    
    MyWallet.wallet.hdwallet.defaultAccountIndex = num;
}

MyWalletPhone.getActiveAccountsCount = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }

    var activeAccounts = MyWalletPhone.getActiveAccounts();

    return activeAccounts.length;
};

MyWalletPhone.getAllTransactionsCount = function() {
    return MyWallet.wallet.txList.transactionsForIOS().length;
}

MyWalletPhone.getAllAccountsCount = function() {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }
    
    return MyWallet.wallet.hdwallet.accounts.length;
};

MyWalletPhone.getBalanceForAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return 0;
    }
    
    return MyWallet.wallet.hdwallet.accounts[num].balance;
};

MyWalletPhone.getLabelForAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return '';
    }
    
    return MyWallet.wallet.hdwallet.accounts[num].label;
};

MyWalletPhone.setLabelForAccount = function(num, label) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return;
    }
    
    MyWallet.wallet.hdwallet.accounts[num].label = label;
};

MyWalletPhone.isAccountNameValid = function(name) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return false;
    }
    
    var accounts = MyWallet.wallet.hdwallet.accounts;
    for (var i = 0; i < accounts.length; i++) {
        var account = accounts[i];
        if (account.label == name) {
            device.execute('on_error_account_name_in_use');
            return false;
        }
    }
    
    return true;
}

MyWalletPhone.isAddressAvailable = function(address) {
    return MyWallet.wallet.key(address) != null && !MyWallet.wallet.key(address).archived;
}

MyWalletPhone.isAccountAvailable = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return false;
    }

    return MyWallet.wallet.hdwallet.accounts[num] != null && !MyWallet.wallet.hdwallet.accounts[num].archived;
}

MyWalletPhone.getReceivingAddressForAccount = function(num) {
    if (!MyWallet.wallet.isUpgradedToHD) {
        console.log('Warning: Getting accounts when wallet has not upgraded!');
        return '';
    }
    
    return MyWallet.wallet.hdwallet.accounts[num].receiveAddress;
};

MyWalletPhone.isArchived = function(accountOrAddress) {
    if (Helpers.isNumber(accountOrAddress) && accountOrAddress >= 0) {
        
        if (MyWallet.wallet.isUpgradedToHD) {
            if (MyWallet.wallet.hdwallet.accounts[accountOrAddress] == null) {
                device.execute('return_to_addresses_screen');
                return false;
            }
            return MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived;
        } else {
            console.log('Warning: Getting accounts when wallet has not upgraded!');
            return false;
        }
    } else if (accountOrAddress) {
        
        if (MyWallet.wallet.key(accountOrAddress) == null) {
            device.execute('return_to_addresses_screen');
            return false;
        }
        
        return MyWallet.wallet.key(accountOrAddress).archived;
    }

    return false;
}

MyWalletPhone.toggleArchived = function(accountOrAddress) {
    if (Helpers.isNumber(accountOrAddress) && accountOrAddress >= 0) {
        if (MyWallet.wallet.isUpgradedToHD) {
            MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived = !MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived;
        } else {
            console.log('Warning: Getting accounts when wallet has not upgraded!');
            return '';
        }
    } else if (accountOrAddress) {
        MyWallet.wallet.key(accountOrAddress).archived = !MyWallet.wallet.key(accountOrAddress).archived;
    }
}

MyWalletPhone.archiveTransferredAddresses = function(addresses) {
    
    var parsedAddresses = JSON.parse(addresses);
    
    for (var index = 0; index < parsedAddresses.length; index++) {
        MyWallet.wallet.key(parsedAddresses[index]).archived = true;
    }
}

MyWalletPhone.createNewPayment = function() {
    console.log('Creating new payment')
    currentPayment = new Payment();
    currentPayment.on('error', function(errorObject) {
        var errorDictionary = {'message': {'error': errorObject['error']}};
        device.execute('on_error_update_fee:', [errorDictionary]);
    });
    
    currentPayment.on('message', function(object) {
        device.execute('on_payment_notice:', [object['text']]);
    });
}

MyWalletPhone.changePaymentFrom = function(from, isAdvanced) {
    if (currentPayment) {
        currentPayment.from(from).then(function(x) {
            if (x) {
                if (x.from != null) device.execute('update_send_balance:', [isAdvanced ? x.balance : x.sweepAmount]);
            }
            return x;
        });
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.changePaymentTo = function(to) {
    if (currentPayment) {
        currentPayment.to(to);
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.changePaymentAmount = function(amount) {
    if (currentPayment) {
        currentPayment.amount(amount);
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.getSurgeStatus = function() {
    if (currentPayment) {
       currentPayment.payment.then(function (x) {
          device.execute('update_surge_status:', [x.fees.default.surge]);
          return x;
       });
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.checkIfUserIsOverSpending = function() {
    
    var checkForOverSpending = function(x) {
        device.execute('check_max_amount:fee:', [x.sweepAmount, x.sweepFee]);
        console.log('checking for overspending: maxAmount and fee are' + x.sweepAmount + ',' + x.sweepFee);
        return x;
    }
    
    if (currentPayment) {
        currentPayment.payment.then(checkForOverSpending).catch(function(error) {
            var errorArgument;
            if (error.error) {
                errorArgument = error.error;
            } else {
                errorArgument = error.message;
            }
                                                            
            console.log('error checking for overspending: ' + errorArgument);
            device.execute('on_error_update_fee:', [errorArgument]);
                                                            
            return error.payment;
        });
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.changeForcedFee = function(fee) {
    console.log('changing forced fee to ' + fee);
    var buildFailure = function (error) {
        console.log('buildfailure forced fee');
        
        var errorArgument;
        if (error.error) {
            errorArgument = error.error;
        } else {
            errorArgument = error.message;
        }
        
        console.log('error updating fee: ' + errorArgument);
        device.execute('on_error_update_fee:', [errorArgument]);
        
        return error.payment;
    }
    
    if (currentPayment) {
       currentPayment.prebuild(fee).build().then(function (x) {
           device.execute('did_change_forced_fee:dust:', [fee, x.extraFeeConsumption]);
           return x;
       }).catch(buildFailure);
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.getFeeBounds = function(fee) {
    
    if (currentPayment) {
       currentPayment.prebuild(fee).then(function (x) {
           console.log('absolute fee bounds:');
           console.log(x.absoluteFeeBounds);
           var expectedBlock = x.confEstimation == Infinity ? -1 : x.confEstimation;
           device.execute('update_fee_bounds:confirmationEstimation:maxAmounts:maxFees:', [x.absoluteFeeBounds, expectedBlock, x.maxSpendableAmounts, x.sweepFees]);
           return x;
       });
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.sweepPaymentRegular = function() {
    if (currentPayment) {
        currentPayment.useAll().then(function (x) {
            MyWalletPhone.updateSweep(false, false);
            return x;
        });
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.sweepPaymentRegularThenConfirm = function() {
    
    var buildFailure = function (error) {
        console.log('buildfailure');
        
        var errorArgument;
        if (error.error) {
            errorArgument = error.error;
        } else {
            errorArgument = error.message;
        }
        
        console.log('error sweeping regular then confirm: ' + errorArgument);
        device.execute('on_error_update_fee:', [errorArgument]);
        
        return error.payment;
    }
    
    if (currentPayment) {
        currentPayment.useAll().build().then(function(x) {
            MyWalletPhone.updateSweep(false, true);
            return x;
        }).catch(buildFailure);
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.sweepPaymentAdvanced = function(fee) {
    if (currentPayment) {
        currentPayment.useAll(fee).then(function (x) {
            MyWalletPhone.updateSweep(true, false);
            return x;
        });
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.sweepPaymentAdvancedThenConfirm = function(fee) {
    var buildFailure = function (error) {
        console.log('buildfailure');
        
        var errorArgument;
        if (error.error) {
            errorArgument = error.error;
        } else {
            errorArgument = error.message;
        }
        
        console.log('error sweeping advanced then confirm: ' + errorArgument);
        device.execute('on_error_update_fee:', [errorArgument]);
        
        return error.payment;
    }
    
    if (currentPayment) {
        currentPayment.useAll(fee).build().then(function(x) {
            MyWalletPhone.updateSweep(true, true);
            return x;
        }).catch(buildFailure);
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.updateSweep = function(isAdvanced, willConfirm) {
    
    if (currentPayment) {
       currentPayment.payment.then(function(x) {
          console.log('updated fee: ' + x.finalFee);
          console.log('SweepAmount: ' + x.amounts);
          device.execute('update_max_amount:fee:dust:willConfirm:', [x.amounts[0], x.finalFee, x.extraFeeConsumption, willConfirm]);
          return x;
       }).catch(function(error) {
          var errorArgument;
          if (error.error) {
              errorArgument = error.error;
          } else {
              errorArgument = error.message;
          }
          console.log('error sweeping payment: ' + errorArgument);
          device.execute('on_error_update_fee:', [errorArgument]);
       });
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.getTransactionFee = function() {
    if (currentPayment) {

        var buildFailure = function(error) {

            var errorArgument;
            if (error.error) {
                errorArgument = error.error;
            } else {
                errorArgument = error.message;
            }
            
            console.log('error updating fee: ' + errorArgument);
            device.execute('on_error_update_fee:', [errorArgument]);
            
            return error.payment;
        }
        
        currentPayment.prebuild().build().then(function (x) {
            device.execute('did_get_fee:dust:', [x.finalFee, x.extraFeeConsumption]);
            return x;
        }).catch(buildFailure);
        
    } else {
        console.log('Payment error: null payment object!');
    }
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

MyWalletPhone.getSessionToken = function() {
    WalletNetwork.obtainSessionToken().then(function (sessionToken) {
        device.execute('on_get_session_token:', [sessionToken]);
    });
}

MyWalletPhone.login = function(user_guid, shared_key, resend_code, inputedPassword, sessionToken, twoFACode, twoFAType, success, needs_two_factor_code, wrong_two_factor_code, other_error) {
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
    
    var history_error = function(error) {
        console.log('login: error getting history');
        device.execute('on_error_get_history:', [error]);
    }
    
    var success = function() {
        var getHistory = MyWallet.wallet.getHistory();
        getHistory.then(history_success).catch(history_error);
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
    
    var wrong_two_factor_code = function() {
        console.log('wrong two factor code');
        device.execute('loading_stop');
        device.execute('wrong_two_factor_code');
    }
    
    var authorization_required = function() {
        console.log('authorization required');
        device.execute('loading_stop');
        device.execute('show_email_authorization_alert');
    }
    
    device.execute('loading_start_download_wallet');

    var credentials = {};

    credentials.twoFactor = twoFACode ? {type: WalletStore.get2FAType(), code : twoFACode} : null;
    
    if (shared_key) {
        console.log('setting sharedKey');
        credentials.sharedKey = shared_key;
    }
    
    if (sessionToken) {
        console.log('setting sessionToken');
        credentials.sessionToken = sessionToken;
    }
    
    var callbacks = {
        needsTwoFactorCode: needs_two_factor_code,
        wrongTwoFactorCode: wrong_two_factor_code,
        authorizationRequired: authorization_required,
        didFetch: fetch_success,
        didDecrypt: decrypt_success,
        didBuildHD: build_hd_success
    }

    MyWallet.login(user_guid, inputedPassword, credentials, callbacks).then(success).catch(other_error);
};

MyWalletPhone.getInfoForTransferAllFundsToDefaultAccount = function() {
    
    var totalAddressesUsed = [];
    var addresses = MyWallet.wallet.spendableActiveAddresses;
    var payments = [];
    transferAllPayments = {};
    
    var updateInfo = function(payments) {
        var totalAmount = payments.filter(function(p) {return p.amounts[0] >= Bitcoin.networks.bitcoin.dustThreshold;}).map(function (p) { totalAddressesUsed.push(p.from[0]); return p.amounts[0]; }).reduce(Helpers.add, 0);
        var totalFee = payments.filter(function(p) {return p.finalFee > 0}).map(function (p) { return p.finalFee; }).reduce(Helpers.add, 0);
        
        device.execute('update_transfer_all_amount:fee:addressesUsed:', [totalAmount, totalFee, totalAddressesUsed]);
    }
    
    var createPayment = function(address) {
        return new Promise(function (resolve) {
            var payment = new Payment().from(address).to(MyWallet.wallet.hdwallet.defaultAccountIndex).useAll();
            transferAllPayments[address] = payment;
            payment.sideEffect(function (p) { resolve(p); });
        })
    }
    
    var queue = Promise.resolve();
    addresses.forEach(function (address, index) {
        queue = queue.then(function (p) {
            if (p) {
                payments.push(p);
                device.execute('loading_start_transfer_all:', [index])
            };
            return createPayment(address);
        });
    });
    
    queue.then(function(last) {
        payments.push(last);
        device.execute('loading_start_transfer_all:', [addresses.length])
        updateInfo(payments);
    });
}

MyWalletPhone.transferAllFundsToDefaultAccount = function(isFirstTransfer, address, secondPassword) {
    var totalAmount = 0;
    var totalFee = 0;
    
    var buildFailure = function (error) {
        console.log('failure building transfer all payment');
        
        var errorArgument;
        if (error.error) {
            errorArgument = error.error;
        } else {
            errorArgument = error.message;
        }
        
        console.log('error transfering all funds: ' + errorArgument);
        
        // pass second password to frontend in case we want to continue sending from other addresses
        device.execute('on_error_transfer_all:secondPassword:', [errorArgument, secondPassword]);
        
        return error.payment;
    }
    
    currentPayment = transferAllPayments[address];
    if (currentPayment) {
        currentPayment.build().then(function (x) {
                                                                                                         
            if (isFirstTransfer) {
               console.log('builtTransferAll: from:' + x.from);
               console.log('builtTransferAll: to:' + x.to);
               device.execute('show_summary_for_transfer_all');
            } else {
                console.log('builtTransferAll: from:' + x.from);
                console.log('builtTransferAll: to:' + x.to);
                device.execute('send_transfer_all:', [secondPassword]);
            }
                                                                                                         
            return x;
        }).catch(buildFailure);
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.transferFundsToDefaultAccountFromAddress = function(address) {
    currentPayment = new Payment();
    
    var buildFailure = function (error) {
        console.log('buildfailure');
        
        console.log('error sweeping regular then confirm: ' + error);
        device.execute('on_error_update_fee:', [{'message': {'error':error.error.message}}]);
        
        return error.payment;
    }
    
    currentPayment.from(address).to(MyWalletPhone.getReceivingAddressForAccount(MyWallet.wallet.hdwallet.defaultAccountIndex)).useAll().build().then(function(x) {
        MyWalletPhone.updateSweep(false, true);
        return x;
    }).catch(buildFailure);
}

MyWalletPhone.quickSend = function(secondPassword) {
    
    console.log('quickSend');
    
    var id = ''+Math.round(Math.random()*100000);
    
    var success = function(payment) {
        device.execute('tx_on_success:secondPassword:', [id, secondPassword]);
    };
    
    var error = function(response) {
        console.log(response);
        
        var error = response;
        if (response.initial_error) {
            error = response.initial_error;
        }
        device.execute('tx_on_error:error:secondPassword:', [id, ''+error, secondPassword]);
    };
    
    if (!currentPayment) {
        console.log('Payment error: null payment object!');
        return;
    }
    
    currentPayment.on('on_start', function () {
        device.execute('tx_on_start:', [id]);
    });
    
    currentPayment.on('on_begin_signing', function() {
       device.execute('tx_on_begin_signing:', [id]);
    });
    
    currentPayment.on('on_sign_progress', function(i) {
        device.execute('tx_on_sign_progress:input:', [id, i]);
    });
    
    currentPayment.on('on_finish_signing', function(i) {
        device.execute('tx_on_finish_signing:', [id]);
    });
    
    if (MyWallet.wallet.isDoubleEncrypted) {
        if (secondPassword) {
            currentPayment
            .sign(secondPassword)
            .publish()
            .then(success).catch(error);
        } else {
            MyWalletPhone.getSecondPassword(function (pw) {
                                            
                secondPassword = pw;
                                            
                currentPayment
                .sign(pw)
                .publish()
                .then(success).catch(error);
            });
        }
    } else {
        currentPayment
            .sign()
            .publish()
            .then(success).catch(error);
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
    var success = function (responseObject) {
        device.execute('on_pin_code_get_response:', [responseObject]);
    };
    var error = function (res) {

        if (res === "Site is in Maintenance mode") {
            device.execute('on_error_maintenance_mode');
        }
        if (res === "timeout request") {
            device.execute('on_error_pin_code_get_timeout');
        }
        // Empty server response
        else if (!Helpers.isNumber(JSON.parse(res).code)) {
            device.execute('on_error_pin_code_get_empty_response');
        } else {
            try {
                var parsedRes = JSON.parse(res);
                
                if (!parsedRes) {
                    throw 'Response Object nil';
                }
                
                device.execute('on_pin_code_get_response:', [parsedRes]);
            } catch (error) {
                // Invalid server response
                device.execute('on_error_pin_code_get_invalid_response');
            }
        }
    };
    
    BlockchainAPI.request("POST", 'pin-store', data, true, false).then(success).catch(error);
};

MyWalletPhone.pinServerPutKeyOnPinServerServer = function(key, value, pin) {
    var data = {
        format: 'json',
        method: 'put',
        value : value,
        pin : pin,
        key : key
    };
    var success = function (responseObject) {
        
        responseObject.key = key;
        responseObject.value = value;
        
        device.execute('on_pin_code_put_response:', [responseObject]);
    };
    var error = function (res) {
        
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
    
    BlockchainAPI.request("POST", 'pin-store', data, true, false).then(success).catch(error);
};

MyWalletPhone.newAccount = function(password, email, firstAccountName) {
    var success = function(guid, sharedKey, password) {
        device.execute('loading_stop');

        device.execute('on_create_new_account:sharedKey:password:', [guid, sharedKey, password]);
    };

    var error = function(e) {
        device.execute('loading_stop');
        if (e == 'Invalid Email') {
            device.execute('on_update_email_error');
        } else {
            var message = e;
            if (e.initial_error) {
                message = e.initial_error;
            }
            
            device.execute('on_error_creating_new_account:', [''+message]);
        }
    };

    device.execute('loading_start_new_account');
        
    MyWallet.createNewWallet(email, password, firstAccountName, null, null, success, error);
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
        var requestSuccess = function (encryption_phrase) {
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
                            password: new Buffer(components2[1], 'hex').toString('utf8')
                            });
                } else {
                    error('Decryption Error');
                }
            } catch(e) {
                error(''+e);
            }
        };
        var requestError = function (res) {
            error('Pairing Code Server Error');
        };
        
        BlockchainAPI.request("POST", 'wallet', data, true, false).then(requestSuccess).catch(requestError);
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
        return Helpers.detectPrivateKeyFormat(privateKeyString);
    } catch(e) {
        return null;
    }
};

MyWalletPhone.hasEncryptedWalletData = function() {
    var data = MyWallet.getEncryptedWalletData();

    return data && data.length > 0;
};

MyWalletPhone.get_history = function() {
    var success = function () {
        console.log('Got wallet history');
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

MyWalletPhone.getMultiAddrResponse = function(txFilter) {
    var obj = {};

    obj.transactions = MyWallet.wallet.txList.transactionsForIOS(txFilter);
    obj.total_received = MyWallet.wallet.totalReceived;
    obj.total_sent = MyWallet.wallet.totalSent;
    obj.final_balance = MyWallet.wallet.finalBalance;
    obj.n_transactions = MyWallet.wallet.numberTx;
    obj.addresses = MyWallet.wallet.addresses;
    
    obj.symbol_local = Blockchain.Shared.getLocalSymbol();
    obj.symbol_btc = Blockchain.Shared.getBTCSymbol();
    
    return obj;
};

MyWalletPhone.fetchMoreTransactions = function() {
    device.execute('loading_start_get_history');
    MyWallet.wallet.fetchTransactions().then(function(numFetched) {
       var loadedAll = numFetched < MyWallet.wallet.txList.loadNumber;
       device.execute('update_loaded_all_transactions:', [loadedAll]);
    });
}

MyWalletPhone.addKey = function(keyString) {
    var success = function(address) {
        console.log('Add private key success');
        
        device.execute('on_add_key:', [address.address]);
    };
    var error = function(e) {
        console.log('Add private key Error');
        console.log(e);
        
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

    var needsBip38Passsword = Helpers.detectPrivateKeyFormat(keyString) === 'bip38';

    if (needsBip38Passsword) {
        MyWalletPhone.getPrivateKeyPassword(function (bip38Pass) {
            if (MyWallet.wallet.isDoubleEncrypted) {
                device.execute('on_add_private_key_start');
                MyWalletPhone.getSecondPassword(function (pw) {
                    var promise = MyWallet.wallet.importLegacyAddress(keyString, null, pw, bip38Pass);
                    promise.then(success, error);
                });
            }
            else {
                device.execute('on_add_private_key_start');
                var promise = MyWallet.wallet.importLegacyAddress(keyString, null, null, bip38Pass);
                promise.then(success, error);
            }
        });
    }
    else {
        if (MyWallet.wallet.isDoubleEncrypted) {
            device.execute('on_add_private_key_start');
            MyWalletPhone.getSecondPassword(function (pw) {
                var promise = MyWallet.wallet.importLegacyAddress(keyString, null, pw, null);
                promise.then(success, error);
            });
        }
        else {
            device.execute('on_add_private_key_start');
            var promise = MyWallet.wallet.importLegacyAddress(keyString, null, null, null);
            promise.then(success, error);
        }
    }
};

MyWalletPhone.sendFromWatchOnlyAddressWithPrivateKey = function(privateKeyString, watchOnlyAddress) {
    
    if (!MyWallet.wallet.key(watchOnlyAddress).isWatchOnly) {
        console.log('Address is not watch only!');
        return;
    }
    
    var success = function(payment) {
        console.log('Add private key success:');
        device.execute('on_success_import_key_for_sending_from_watch_only');
    };
    
    var error = function(message) {
        console.log('Add private key error: ' + message);
        device.execute('on_error_import_key_for_sending_from_watch_only:', [message]);
    };
    
    var needsBip38Passsword = Helpers.detectPrivateKeyFormat(privateKeyString) === 'bip38';
    
    if (needsBip38Passsword) {
        MyWalletPhone.getPrivateKeyPassword(function (bip38Pass) {
            Helpers.privateKeyCorrespondsToAddress(watchOnlyAddress, privateKeyString, bip38Pass).then(function (decryptedPrivateKey) {
                if (decryptedPrivateKey) {
                    if (currentPayment) {
                        currentPayment.from(decryptedPrivateKey).sideEffect(success).catch(error);
                    } else {
                        console.log('Payment error: null payment object!');
                    }
                } else {
                    console.log('Add private key error: ');
                    device.execute('on_error_import_key_for_sending_from_watch_only:', ['wrongPrivateKey']);
                }
            }).catch(error);
        });
    } else {
        Helpers.privateKeyCorrespondsToAddress(watchOnlyAddress, privateKeyString, null).then(function (decryptedPrivateKey) {
           if (decryptedPrivateKey) {
             if (currentPayment) {
                 currentPayment.from(decryptedPrivateKey).sideEffect(success).catch(error);
             } else {
                 console.log('Payment error: null payment object!');
             }
           } else {
             console.log('Add private key error: ');
             device.execute('on_error_import_key_for_sending_from_watch_only:', ['wrongPrivateKey']);
           }
        }).catch(error);
    }
}

MyWalletPhone.addKeyToLegacyAddress = function(privateKeyString, legacyAddress) {
    
    var success = function(address) {
        console.log('Add private key success:');
        console.log(address.address);
        
        if (address.address != legacyAddress) {
            device.execute('on_add_incorrect_private_key:', [legacyAddress]);
        } else {
            device.execute('on_add_private_key_to_legacy_address', [legacyAddress]);
        }
    };
    var error = function(message) {
        console.log('Add private key Error: ' + message);
    
        device.execute('on_error_adding_private_key_watch_only:', [message]);
    };
    
    var needsBip38Passsword = Helpers.detectPrivateKeyFormat(privateKeyString) === 'bip38';
    
    if (needsBip38Passsword) {
        MyWalletPhone.getPrivateKeyPassword(function (bip38Pass) {
            if (MyWallet.wallet.isDoubleEncrypted) {
                device.execute('on_add_private_key_start');
                MyWalletPhone.getSecondPassword(function (pw) {
                    MyWallet.wallet.addKeyToLegacyAddress(privateKeyString, legacyAddress, pw, bip38Pass).then(success).catch(error);
                });
            } else {
                device.execute('on_add_private_key_start');
                MyWallet.wallet.addKeyToLegacyAddress(privateKeyString, legacyAddress, null, bip38Pass).then(success).catch(error);
            }
        });
    }
    else {
        if (MyWallet.wallet.isDoubleEncrypted) {
            device.execute('on_add_private_key_start');
            MyWalletPhone.getSecondPassword(function (pw) {
                MyWallet.wallet.addKeyToLegacyAddress(privateKeyString, legacyAddress, pw, null).then(success).catch(error);
            });
        }
        else {
            device.execute('on_add_private_key_start');
            MyWallet.wallet.addKeyToLegacyAddress(privateKeyString, legacyAddress, null, null).then(success).catch(error);
        }
    }
};

MyWalletPhone.getRecoveryPhrase = function(secondPassword) {
    var recoveryPhrase = MyWallet.wallet.getMnemonic(secondPassword);
    
    device.execute('on_success_get_recovery_phrase:', [recoveryPhrase]);
};


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

WalletCrypto.scrypt = function(passwd, salt, N, r, p, dkLen, callback) {
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

MyWalletPhone.change_mobile_number = function(mobileNumber) {
    
    var success = function () {
        console.log('Changing mobile number');
        device.execute('on_change_mobile_number_success');
    };
    
    var error = function (e) {
        console.log('Error changing mobile number: ' + e);
    };
    
    BlockchainSettingsAPI.changeMobileNumber(mobileNumber, success, error);
}

MyWalletPhone.verify_mobile_number = function(code) {
    
    var success = function () {
        console.log('Verifying mobile number');
        device.execute('on_verify_mobile_number_success');
    };
    
    var error = function (e) {
        console.log('Error verifying mobile number: ' + e);
        // Error message is already shown through a sendEvent
        device.execute('on_verify_mobile_number_error');
    };
    
    BlockchainSettingsAPI.verifyMobile(code, success, error);
}

MyWalletPhone.enable_two_step_verification_sms = function() {
    
    var success = function () {
        console.log('Enabling two step SMS');
        device.execute('on_change_two_step_success');
    };
    
    var error = function (e) {
        console.log('Error enabling two step SMS: ' + e);
        device.execute('on_change_two_step_error');
    };
    
    BlockchainSettingsAPI.setTwoFactorSMS(success, error);
}

MyWalletPhone.disable_two_step_verification = function() {
    
    var success = function () {
        console.log('Disabling two step');
        device.execute('on_change_two_step_success');
    };
    
    var error = function (e) {
        console.log('Error disabling two step: ' + e);
        device.execute('on_change_two_step_error');
    };
    
    BlockchainSettingsAPI.unsetTwoFactor(success, error);
}

MyWalletPhone.update_password_hint = function(hint) {

    var success = function () {
        console.log('Updating password hint');
        device.execute('on_update_password_hint_success');
    };
    
    var error = function (e) {
        console.log('Error updating password hint: ' + e);
        device.execute('on_update_password_hint_error');
    };
    
    BlockchainSettingsAPI.update_password_hint1(hint, success, error);
}

MyWalletPhone.change_password = function(password) {
    
    var success = function () {
        console.log('Changing password');
        device.execute('on_change_password_success');
    };
    
    var error = function (e) {
        console.log('Error Changing password: ' + e);
        device.execute('on_change_password_error');
    };
    
    WalletStore.changePassword(password, success, error);
}

MyWalletPhone.isCorrectMainPassword = function(password) {
    return WalletStore.isCorrectMainPassword(password);
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
        
        device.execute('loading_start_create_new_address');
                       
        var label = null;
                       
        var success = function () {
            console.log('Success creating new address');
            MyWalletPhone.get_history();
            device.execute('on_generate_key');
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
    return (MyWallet.wallet.addresses.indexOf(address) > -1);
}

MyWalletPhone.recoverWithPassphrase = function(email, password, passphrase) {
    
    if (Helpers.isValidBIP39Mnemonic(passphrase)) {
        console.log('recovering wallet');
        
        var accountProgress = function(obj) {
            var totalReceived = obj.addresses[0]['total_received'];
            var finalBalance = obj.wallet['final_balance'];
            device.execute('on_progress_recover_with_passphrase:finalBalance:', [totalReceived, finalBalance]);
        }
        
        var generateUUIDProgress = function() {
            device.execute('loading_start_generate_uuids');
        }
        
        var decryptWalletProgress = function() {
            device.execute('loading_start_decrypt_wallet');
        }
        
        var startedRestoreHDWallet = function() {
            device.execute('loading_start_recover_wallet');
        }
        
        var success = function (recoveredWalletDictionary) {
            console.log('recovery success');
            device.execute('on_success_recover_with_passphrase:', [recoveredWalletDictionary]);
        }
        
        var error = function(error) {
            console.log('recovery error after validation: ' + error);
            device.execute('on_error_recover_with_passphrase:', [error]);
        }
        
        MyWallet.recoverFromMnemonic(email, password, passphrase, '', success, error, startedRestoreHDWallet, accountProgress, generateUUIDProgress, decryptWalletProgress);

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

MyWalletPhone.resendTwoFactorSms = function(user_guid, sessionToken) {
    
    var success = function () {
        console.log('Resend two factor SMS success');
        device.execute('on_resend_two_factor_sms_success');
    }
    
    var error = function(error) {
        var parsedError = JSON.parse(error);
        console.log('Resend two factor SMS error: ');
        console.log(parsedError);
        device.execute('on_resend_two_factor_sms_error:', [parsedError['initial_error']]);
    }
    
    WalletNetwork.resendTwoFactorSms(user_guid, sessionToken).then(success).catch(error);
}

MyWalletPhone.get2FAType = function() {
    return WalletStore.get2FAType();
}

MyWalletPhone.enableNotifications = function() {
    
    var success = function () {
        console.log('Enable notifications success');
        device.execute('on_change_email_notifications_success');
    }
    
    var error = function(error) {
        console.log('Enable notifications error: ' + error);
    }
    
    MyWallet.wallet.enableNotifications(success, error);
}

MyWalletPhone.disableNotifications = function() {
    
    var success = function () {
        console.log('Disable notifications success');
        device.execute('on_change_email_notifications_success');
    }
    
    var error = function(error) {
        console.log('Disable notifications error: ' + error);
    }
    
    MyWallet.wallet.disableNotifications(success, error);
}

MyWalletPhone.update_tor_ip_block = function(willEnable) {
    
    var shouldEnable = Boolean(willEnable);
    
    var success = function () {
        console.log('Update tor success');
        device.execute('on_update_tor_success');
    }
    
    var error = function(error) {
        console.log('Update tor error' + error);
        device.execute('on_update_tor_error');
    }
    
    BlockchainSettingsAPI.update_tor_ip_block(shouldEnable, success, error);
}

MyWalletPhone.updateServerURL = function(url) {
    if (url.substring(url.length - 1) == '/') {
        BlockchainAPI.ROOT_URL = url;
        MyWallet.ws.headers = { 'Origin': url.substring(0, url.length - 1) };
    } else {
        BlockchainAPI.ROOT_URL = url.concat('/');
        MyWallet.ws.headers = { 'Origin': url };
    }
}

MyWalletPhone.updateWebsocketURL = function(url) {
    if (url.substring(url.length - 1) == '/') {
        MyWallet.ws.wsUrl = url.substring(0, url.length - 1);
    } else {
        MyWallet.ws.wsUrl = url;
    }
}

MyWalletPhone.updateAPIURL = function(url) {
    if (url.substring(url.length - 1) != '/') {
        BlockchainAPI.API_ROOT_URL = url.concat('/')
    } else {
        BlockchainAPI.API_ROOT_URL = url;
    }
}

MyWalletPhone.getXpubForAccount = function(accountIndex) {
    return MyWallet.wallet.hdwallet.accounts[accountIndex].extendedPublicKey;
}

MyWalletPhone.filteredWalletJSON = function() {
    var walletJSON = JSON.parse(JSON.stringify(MyWallet.wallet, null, 2));
    var hidden = '(REMOVED)';
    
    walletJSON['guid'] = hidden;
    walletJSON['sharedKey'] = hidden;
    walletJSON['dpasswordhash'] = hidden;
    
    for (var key in walletJSON) {
        if (key == 'hd_wallets') {
            
            walletJSON[key][0]['seed_hex'] = hidden;
            
            for (var account in walletJSON[key][0]['accounts']) {
                walletJSON[key][0]['accounts'][account]['xpriv'] = hidden;
                walletJSON[key][0]['accounts'][account]['xpub'] = hidden;
                walletJSON[key][0]['accounts'][account]['label'] = hidden;
                walletJSON[key][0]['accounts'][account]['address_labels'] = hidden;
                
                if (walletJSON[key][0]['accounts'][account]['cache']) {
                    walletJSON[key][0]['accounts'][account]['cache']['changeAccount'] = hidden;
                    walletJSON[key][0]['accounts'][account]['cache']['receiveAccount'] = hidden;
                }
            }
        }
        
        if (key == 'keys') {
            for (var address in walletJSON[key]) {
                walletJSON[key][address]['priv'] = hidden;
                walletJSON[key][address]['label'] = hidden;
                walletJSON[key][address]['addr'] = hidden;
            }
        }
    }
    return walletJSON;
}

MyWalletPhone.dust = function() {
    return Bitcoin.networks.bitcoin.dustThreshold;
}