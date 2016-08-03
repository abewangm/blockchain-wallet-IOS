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

// Register for JS event handlers and forward to Obj-C handlers

WalletStore.addEventListener(function (event, obj) {
    var eventsWithObjCHandlers = ["did_fail_set_guid", "did_multiaddr", "did_set_latest_block", "error_restoring_wallet", "logging_out", "on_backup_wallet_start", "on_backup_wallet_error", "on_backup_wallet_success", "on_tx_received", "ws_on_close", "ws_on_open", "did_load_wallet"];
                             
    if (event == 'msg') {
        if (obj.type == 'error') {
                             
            if (obj.message != "For Improved security add an email address to your account.") {
                // Cancel busy view in case any error comes in - except for add email, that's handled differently in makeNotice
                loading_stop();
            }
                             
            if (obj.message == "Error Downloading Account Settings") {
                on_error_downloading_account_settings();
                return;
            }
                             
            // Some messages are JSON objects and the error message is in the map
            try {
                var messageJSON = JSON.parse(obj.message);
                if (messageJSON && messageJSON.initial_error) {
                    makeNotice_id_message(''+obj.type, ''+obj.code, ''+messageJSON.initial_error);
                    return;
                }
            } catch (e) {
            }
            makeNotice_id_message(''+obj.type, ''+obj.code, ''+obj.message);
        } else if (obj.type == 'success') {
            makeNotice_id_message(''+obj.type, ''+obj.code, ''+obj.message);
        }
            return;
    }
                             
    if (eventsWithObjCHandlers.indexOf(event) == -1) {
        return;
    }
                             
    var codeToExecute = event.concat('()');
    var tmpFunc = new Function(codeToExecute);
    tmpFunc(obj);
});


// My Wallet phone functions

MyWalletPhone.upgradeToV3 = function(firstAccountName) {
    var success = function () {
        console.log('Upgraded legacy wallet to HD wallet');
        
        MyWallet.wallet.getHistory();
        loading_stop();
        upgrade_success();
    };
    
    var error = function (e) {
        console.log('Error upgrading legacy wallet to HD wallet: ' + e);
        loading_stop();
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
        
        loading_stop();
        
        on_add_new_account();
        
        reload();
    };
    
    var error = function (error) {
        on_error_add_new_account(error);
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
            on_error_account_name_in_use();
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
                return_to_addresses_screen();
                return false;
            }
            return MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived;
        } else {
            console.log('Warning: Getting accounts when wallet has not upgraded!');
            return false;
        }
    } else if (accountOrAddress) {
        
        if (MyWallet.wallet.key(accountOrAddress) == null) {
            return_to_addresses_screen();
            return false;
        }
        
        return MyWallet.wallet.key(accountOrAddress).archived;
    }
    
    return false;
}

MyWalletPhone.toggleArchived = function(accountOrAddress) {
    
    var didArchive = false;
    
    if (Helpers.isNumber(accountOrAddress) && accountOrAddress >= 0) {
        if (MyWallet.wallet.isUpgradedToHD) {
            MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived = !MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived;
            didArchive = MyWallet.wallet.hdwallet.accounts[accountOrAddress].archived
        } else {
            console.log('Warning: Getting accounts when wallet has not upgraded!');
            return '';
        }
    } else if (accountOrAddress) {
        MyWallet.wallet.key(accountOrAddress).archived = !MyWallet.wallet.key(accountOrAddress).archived;
        didArchive =  MyWallet.wallet.key(accountOrAddress).archived;
    }
    
    if (didArchive) {
        MyWalletPhone.get_history();
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
                        on_error_update_fee(errorDictionary);
                      });
    
    currentPayment.on('message', function(object) {
                        on_payment_notice(object['text']);
                      });
}

MyWalletPhone.changePaymentFrom = function(from, isAdvanced) {
    if (currentPayment) {
        currentPayment.from(from).then(function(x) {
                                       if (x) {
                                       if (x.from != null) update_send_balance(isAdvanced ? x.balance : x.sweepAmount);
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
                                    update_surge_status(x.fees.default.surge);
                                    return x;
                                    });
    } else {
        console.log('Payment error: null payment object!');
    }
}

MyWalletPhone.checkIfUserIsOverSpending = function() {
    
    var checkForOverSpending = function(x) {
    check_max_amount_fee(x.sweepAmount, x.sweepFee);
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
                                                                on_error_update_fee(errorArgument);
                                                                
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
        on_error_update_fee(errorArgument);
        
        return error.payment;
    }
    
    if (currentPayment) {
        currentPayment.prebuild(fee).build().then(function (x) {
                                                  did_change_forced_fee_dust(fee, x.extraFeeConsumption);
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
                                          update_fee_bounds_confirmationEstimation_maxAmounts_maxFees(x.absoluteFeeBounds, expectedBlock, x.maxSpendableAmounts, x.sweepFees);
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
        on_error_update_fee(errorArgument);
        
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
        on_error_update_fee(errorArgument);
        
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
                                    update_max_amount_fee_dust_willConfirm(x.amounts[0], x.finalFee, x.extraFeeConsumption, willConfirm);
                                    return x;
                                    }).catch(function(error) {
                                             var errorArgument;
                                             if (error.error) {
                                             errorArgument = error.error;
                                             } else {
                                             errorArgument = error.message;
                                             }
                                             console.log('error sweeping payment: ' + errorArgument);
                                             on_error_update_fee(errorArgument);
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
            on_error_update_fee(errorArgument);
            
            return error.payment;
        }
        
        currentPayment.prebuild().build().then(function (x) {
                                               did_get_fee_dust_txSize(x.finalFee, x.extraFeeConsumption, x.txSize);
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
        on_get_session_token(sessionToken);
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
        loading_start_decrypt_wallet();
    };
    
    var decrypt_success = function() {
        logTime('decrypt');
        
        did_decrypt();
        
        loading_start_build_wallet();
    };
    
    var build_hd_success = function() {
        logTime('build HD wallet');
        
        loading_start_multiaddr();
    };
    
    var history_success = function() {
        logTime('get history');
        
        loading_stop();
        
        did_load_wallet();
    };
    
    var history_error = function(error) {console.log(error);
        console.log('login: error getting history');
        on_error_get_history(error);
    }
    
    var success = function() {
        var getHistory = MyWallet.wallet.getHistory();
        getHistory.then(history_success).catch(history_error);
    };
    
    var other_error = function(e) {
        console.log('login: other error: ' + e);
        loading_stop();
        error_other_decrypting_wallet(e);
    };
    
    var needs_two_factor_code = function(type) {
        console.log('login: needs 2fa of type: ' + WalletStore.get2FATypeString());
        loading_stop();
        on_fetch_needs_two_factor_code();
    };
    
    var wrong_two_factor_code = function(error) {
        console.log('wrong two factor code: ' + error);
        loading_stop();
        objc_wrong_two_factor_code(error);
    }
    
    var authorization_required = function() {
        console.log('authorization required');
        loading_stop();
        show_email_authorization_alert();
    }

    loading_start_download_wallet();
    
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
        var totalFee = payments.filter(function(p) {return p.finalFee > 0 && p.amounts[0] >= Bitcoin.networks.bitcoin.dustThreshold;}).map(function (p) { return p.finalFee; }).reduce(Helpers.add, 0);
        
    update_transfer_all_amount_fee_addressesUsed(totalAmount, totalFee, totalAddressesUsed);
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
                                         loading_start_transfer_all(index)
                                         };
                                         return createPayment(address);
                                         });
                      });
    
    queue.then(function(last) {
               payments.push(last);
               loading_start_transfer_all(addresses.length)
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
    on_error_transfer_all_secondPassword(errorArgument, secondPassword);
        
        return error.payment;
    }
    
    currentPayment = transferAllPayments[address];
    if (currentPayment) {
        currentPayment.build().then(function (x) {
                                    
                                    if (isFirstTransfer) {
                                    console.log('builtTransferAll: from:' + x.from);
                                    console.log('builtTransferAll: to:' + x.to);
                                    show_summary_for_transfer_all();
                                    } else {
                                    console.log('builtTransferAll: from:' + x.from);
                                    console.log('builtTransferAll: to:' + x.to);
                                    send_transfer_all(secondPassword);
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
    on_error_update_fee({'message': {'error':error.error.message}});
        
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
        tx_on_success_secondPassword(id, secondPassword);
    };
    
    var error = function(response) {
        console.log(response);
        
        var error = response;
        if (response.initial_error) {
            error = response.initial_error;
        }
        tx_on_error_error_secondPassword(id, ''+error, secondPassword);
    };
    
    if (!currentPayment) {
        console.log('Payment error: null payment object!');
        return;
    }
    
    currentPayment.on('on_start', function () {
                      tx_on_start(id);
                      });
    
    currentPayment.on('on_begin_signing', function() {
                      tx_on_begin_signing(id);
                      });
    
    currentPayment.on('on_sign_progress', function(i) {
                      tx_on_sign_progress_input(id, i);
                      });
    
    currentPayment.on('on_finish_signing', function(i) {
                      tx_on_finish_signing(id);
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
        on_pin_code_get_response(responseObject);
    };
    var error = function (res) {
        
        if (res === "Site is in Maintenance mode") {
            on_error_maintenance_mode();
        }
        if (res === "timeout request") {
            on_error_pin_code_get_timeout();
        }
        // Empty server response
        else if (!Helpers.isNumber(JSON.parse(res).code)) {
            on_error_pin_code_get_empty_response();
        } else {
            try {
                var parsedRes = JSON.parse(res);
                
                if (!parsedRes) {
                    throw 'Response Object nil';
                }
                
            on_pin_code_get_response(parsedRes);
            } catch (error) {
                // Invalid server response
                on_error_pin_code_get_invalid_response();
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
        
        on_pin_code_put_response(responseObject);
    };
    var error = function (res) {
        
        if (!res || !res.responseText || res.responseText.length == 0) {
        on_error_pin_code_put_error('Unknown Error');
        } else {
            try {
                var responseObject = JSON.parse(res.responseText);
                
                responseObject.key = key;
                responseObject.value = value;
                
            on_pin_code_put_response(responseObject);
            } catch (e) {
            on_error_pin_code_put_error(res.responseText);
            }
        }
    };
    
    BlockchainAPI.request("POST", 'pin-store', data, true, false).then(success).catch(error);
};

MyWalletPhone.newAccount = function(password, email, firstAccountName) {
    var success = function(guid, sharedKey, password) {
        loading_stop();
        
        on_create_new_account_sharedKey_password(guid, sharedKey, password);
    };
    
    var error = function(e) {
        loading_stop();
        if (e == 'Invalid Email') {
            on_update_email_error();
        } else {
            var message = e;
            if (e.initial_error) {
                message = e.initial_error;
            }
            
        on_error_creating_new_account(''+message);
        }
    };
    
    MyWallet.createNewWallet(email, password, firstAccountName, null, null, success, error);
};

MyWalletPhone.parsePairingCode = function (raw_code) {
    var success = function (pairing_code) {
        didParsePairingCode(pairing_code);
    };
    
    var error = function (e) {
        errorParsingPairingCode(e);
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
        var format = Helpers.detectPrivateKeyFormat(privateKeyString);
        return format == null ? '' : format;
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
        on_get_history_success();
    };
    
    var error = function () {
        console.log('Error getting wallet history');
        loading_stop();
    };
    
    loading_start_get_history();
    
    var getHistory = MyWallet.wallet.getHistory();
    getHistory.then(success).catch(error);
};

MyWalletPhone.get_wallet_and_history = function() {
    var success = function () {
        console.log('Got wallet and history');
        loading_stop();
    };
    
    var error = function () {
        console.log('Error getting wallet and history');
        loading_stop();
    };
    
    loading_start_get_wallet_and_history();
    
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
    loading_start_get_history();
    MyWallet.wallet.fetchTransactions().then(function(numFetched) {
                                             var loadedAll = numFetched < MyWallet.wallet.txList.loadNumber;
                                             update_loaded_all_transactions(loadedAll);
                                             });
}

MyWalletPhone.addKey = function(keyString) {
    var success = function(address) {
        console.log('Add private key success');
        
        on_add_key(address.address);
    };
    var error = function(e) {
        console.log('Add private key Error');
        console.log(e);
        
        on_error_adding_private_key(e);
    };
    
    var needsBip38Passsword = Helpers.detectPrivateKeyFormat(keyString) === 'bip38';
    
    if (needsBip38Passsword) {
        MyWalletPhone.getPrivateKeyPassword(function (bip38Pass) {
                                            if (MyWallet.wallet.isDoubleEncrypted) {
                                            on_add_private_key_start();
                                            MyWalletPhone.getSecondPassword(function (pw) {
                                                                            var promise = MyWallet.wallet.importLegacyAddress(keyString, null, pw, bip38Pass);
                                                                            promise.then(success, error);
                                                                            });
                                            }
                                            else {
                                            on_add_private_key_start();
                                            var promise = MyWallet.wallet.importLegacyAddress(keyString, null, null, bip38Pass);
                                            promise.then(success, error);
                                            }
                                            });
    }
    else {
        if (MyWallet.wallet.isDoubleEncrypted) {
            on_add_private_key_start();
            MyWalletPhone.getSecondPassword(function (pw) {
                                            var promise = MyWallet.wallet.importLegacyAddress(keyString, null, pw, null);
                                            promise.then(success, error);
                                            });
        }
        else {
            on_add_private_key_start();
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
        on_success_import_key_for_sending_from_watch_only();
    };
    
    var error = function(message) {
        console.log('Add private key error: ' + message);
        on_error_import_key_for_sending_from_watch_only(message);
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
                                                                                                                                       on_error_import_key_for_sending_from_watch_only('wrongPrivateKey');
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
                                                                                              on_error_import_key_for_sending_from_watch_only('wrongPrivateKey');
                                                                                              }
                                                                                              }).catch(error);
    }
}

MyWalletPhone.addKeyToLegacyAddress = function(privateKeyString, legacyAddress) {
    
    var success = function(address) {
        console.log('Add private key success:');
        console.log(address.address);
        
        if (address.address != legacyAddress) {
            on_add_incorrect_private_key(legacyAddress);
        } else {
            on_add_private_key_to_legacy_address();
        }
    };
    var error = function(message) {
        console.log('Add private key Error: ' + message);
        
        on_error_adding_private_key_watch_only(message);
    };
    
    var needsBip38Passsword = Helpers.detectPrivateKeyFormat(privateKeyString) === 'bip38';
    
    if (needsBip38Passsword) {
        MyWalletPhone.getPrivateKeyPassword(function (bip38Pass) {
                                            if (MyWallet.wallet.isDoubleEncrypted) {
                                            on_add_private_key_start();
                                            MyWalletPhone.getSecondPassword(function (pw) {
                                                                            MyWallet.wallet.addKeyToLegacyAddress(privateKeyString, legacyAddress, pw, bip38Pass).then(success).catch(error);
                                                                            });
                                            } else {
                                            on_add_private_key_start();
                                            MyWallet.wallet.addKeyToLegacyAddress(privateKeyString, legacyAddress, null, bip38Pass).then(success).catch(error);
                                            }
                                            });
    }
    else {
        if (MyWallet.wallet.isDoubleEncrypted) {
            on_add_private_key_start();
            MyWalletPhone.getSecondPassword(function (pw) {
                                            MyWallet.wallet.addKeyToLegacyAddress(privateKeyString, legacyAddress, pw, null).then(success).catch(error);
                                            });
        }
        else {
            on_add_private_key_start();
            MyWallet.wallet.addKeyToLegacyAddress(privateKeyString, legacyAddress, null, null).then(success).catch(error);
        }
    }
};

MyWalletPhone.getRecoveryPhrase = function(secondPassword) {
    var recoveryPhrase = MyWallet.wallet.getMnemonic(secondPassword);
    
    on_success_get_recovery_phrase(recoveryPhrase);
};


// Get passwords

MyWalletPhone.getPrivateKeyPassword = function(callback) {
    // Due to the way the JSBridge handles calls with success/error callbacks, we need a first argument that can be ignored
    getPrivateKeyPassword(function(pw) {
        callback(pw);
    });
};

MyWalletPhone.getSecondPassword = function(callback) {
    // Due to the way the JSBridge handles calls with success/error callbacks, we need a first argument that can be ignored
    getSecondPassword(function(pw) {
        callback(pw);
    });
};


// Overrides

RNG.randomBytes = function(nBytes) {
    return Buffer(objc_getRandomBytes(nBytes), 'hex');
}

MyWallet.socketConnect = function() {
    // override socketConnect to prevent memory leaks
}

WalletCrypto.scrypt = function(passwd, salt, N, r, p, dkLen, callback) {
    if(typeof(passwd) !== 'string') {
        passwd = passwd.toJSON().data;
    }
    
    if(typeof(salt) !== 'string') {
        salt = salt.toJSON().data;
    }
    
    crypto_scrypt_salt_n_r_p_dkLen(passwd, salt, N, r, p, dkLen, function(buffer) {
                   var bytes = new Buffer(buffer, 'hex');
                   
                   callback(bytes);
                   }, function(e) {
                   error(''+e);
                   });
};

WalletCrypto.stretchPassword = function (password, salt, iterations, keylen) {
    var retVal = objc_sjcl_misc_pbkdf2(password, salt.toJSON().data, iterations, keylen / 8);
    return new Buffer(retVal, 'hex');
}

// TODO what should this value be?
MyWallet.getNTransactionsPerPage = function() {
    return 50;
};

// Settings

MyWalletPhone.getAccountInfo = function () {
    
    var success = function (data) {
        console.log('Getting account info');
        var accountInfo = JSON.stringify(data, null, 2);
        on_get_account_info_success(accountInfo);
    }
    
    var error = function (e) {
        console.log('Error getting account info: ' + e);
    };
    
    MyWallet.wallet.fetchAccountInfo().then(success).catch(error);
}

MyWalletPhone.changeEmail = function(email) {
    
    var success = function () {
        console.log('Changing email');
        on_change_email_success();
    };
    
    var error = function (e) {
        console.log('Error changing email: ' + e);
    };
    
    BlockchainSettingsAPI.changeEmail(email, success, error);
}

MyWalletPhone.resendEmailConfirmation = function(email) {
    
    var success = function () {
        console.log('Resending verification email');
        on_resend_verification_email_success();
    };
    
    var error = function (e) {
        console.log('Error resending verification email: ' + e);
    };
    
    BlockchainSettingsAPI.resendEmailConfirmation(email, success, error);
}

MyWalletPhone.changeMobileNumber = function(mobileNumber) {
    
    var success = function () {
        console.log('Changing mobile number');
        on_change_mobile_number_success();
    };
    
    var error = function (e) {
        console.log('Error changing mobile number: ' + e);
    };
    
    BlockchainSettingsAPI.changeMobileNumber(mobileNumber, success, error);
}

MyWalletPhone.verifyMobile = function(code) {
    
    var success = function () {
        console.log('Verifying mobile number');
        on_verify_mobile_number_success();
    };
    
    var error = function (e) {
        console.log('Error verifying mobile number: ' + e);
        // Error message is already shown through a sendEvent
        on_verify_mobile_number_error();
    };
    
    BlockchainSettingsAPI.verifyMobile(code, success, error);
}

MyWalletPhone.setTwoFactorSMS = function() {
    
    var success = function () {
        console.log('Enabling two step SMS');
        on_change_two_step_success();
    };
    
    var error = function (e) {
        console.log('Error enabling two step SMS: ' + e);
        on_change_two_step_error();
    };
    
    BlockchainSettingsAPI.setTwoFactorSMS(success, error);
}

MyWalletPhone.unsetTwoFactor = function() {
    
    var success = function () {
        console.log('Disabling two step');
        on_change_two_step_success();
    };
    
    var error = function (e) {
        console.log('Error disabling two step: ' + e);
        on_change_two_step_error();
    };
    
    BlockchainSettingsAPI.unsetTwoFactor(success, error);
}

MyWalletPhone.updatePasswordHint = function(hint) {

    var success = function () {
        console.log('Updating password hint');
        on_update_password_hint_success();
    };
    
    var error = function (e) {
        console.log('Error updating password hint: ' + e);
        on_update_password_hint_error();
    };
    
    BlockchainSettingsAPI.updatePasswordHint1(hint, success, error);
}

MyWalletPhone.changePassword = function(password) {
    
    var success = function () {
        console.log('Changing password');
        on_change_password_success();
    };
    
    var error = function (e) {
        console.log('Error Changing password: ' + e);
        on_change_password_error();
    };
    
    WalletStore.changePassword(password, success, error);
}

MyWalletPhone.isCorrectMainPassword = function(password) {
    return WalletStore.isCorrectMainPassword(password);
}

MyWalletPhone.changeLocalCurrency = function(code) {
    
    var success = function () {
        console.log('Changing local currency');
        on_change_local_currency_success();
    };
    
    var error = function (e) {
        console.log('Error changing local currency: ' + e);
    };
    
    BlockchainSettingsAPI.changeLocalCurrency(code, success, error);
}

MyWalletPhone.changeBtcCurrency = function(code) {
    
    var success = function () {
        console.log('Changing btc currency');
        on_change_local_currency_success();
    };
    
    var error = function (e) {
        console.log('Error changing btc currency: ' + e);
    };
    
    BlockchainSettingsAPI.changeBtcCurrency(code, success, error);
}

MyWalletPhone.getAllCurrencySymbols = function () {
    
    var success = function (data) {
        console.log('Getting all currency symbols');
        var currencySymbolData = JSON.stringify(data, null, 2);
        on_get_all_currency_symbols_success(currencySymbolData);
    };
    
    var error = function (e) {
        console.log('Error getting all currency symbols: ' + e);
    };
    
    var promise = BlockchainAPI.getTicker();
    promise.then(success, error);
}

MyWalletPhone.getPasswordStrength = function(password) {
    var strength = Helpers.scorePassword(password);
    return strength;
}

MyWalletPhone.generateNewAddress = function() {
    MyWallet.getWallet(function() {
                       
                       loading_start_create_new_address();
                       
                       var label = null;
                       
                       var success = function () {
                       console.log('Success creating new address');
                       MyWalletPhone.get_history();
                       on_generate_key();
                       loading_stop();
                       };
                       
                       var error = function (e) {
                       console.log('Error creating new address: ' + e);
                       loading_stop();
                       on_error_creating_new_address(e);
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
            var totalReceived = obj['total_received'];
            var finalBalance = obj['final_balance'];
            on_progress_recover_with_passphrase_finalBalance(totalReceived, finalBalance);
        }
        
        var generateUUIDProgress = function() {
            loading_start_generate_uuids();
        }
        
        var decryptWalletProgress = function() {
            loading_start_decrypt_wallet();
        }
        
        var startedRestoreHDWallet = function() {
            loading_start_recover_wallet();
        }
        
        var success = function (recoveredWalletDictionary) {
            console.log('recovery success');
            on_success_recover_with_passphrase(recoveredWalletDictionary);
        }
        
        var error = function(error) {
            console.log('recovery error after validation: ' + error);
            on_error_recover_with_passphrase(error);
        }
        
        MyWallet.recoverFromMnemonic(email, password, passphrase, '', success, error, startedRestoreHDWallet, accountProgress, generateUUIDProgress, decryptWalletProgress);
        
    } else {
        console.log('Invalid passphrase');
        on_error_recover_with_passphrase('invalid passphrase');
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
        on_resend_two_factor_sms_success();
    }
    
    var error = function(error) {
        var parsedError = JSON.parse(error);
        console.log('Resend two factor SMS error: ');
        console.log(parsedError);
        on_resend_two_factor_sms_error(parsedError['initial_error']);
    }
    
    WalletNetwork.resendTwoFactorSms(user_guid, sessionToken).then(success).catch(error);
}

MyWalletPhone.get2FAType = function() {
    return WalletStore.get2FAType();
}

MyWalletPhone.emailNotificationsEnabled = function() {
    return MyWallet.wallet.accountInfo.notifications.email;
}
    
MyWalletPhone.SMSNotificationsEnabled = function() {
    return MyWallet.wallet.accountInfo.notifications.sms;
}

MyWalletPhone.enableEmailNotifications = function() {
    MyWalletPhone.updateNotification({email: 'enable'});
}

MyWalletPhone.disableEmailNotifications = function() {
    MyWalletPhone.updateNotification({email: 'disable'});
}

MyWalletPhone.enableSMSNotifications = function() {
    MyWalletPhone.updateNotification({sms: 'enable'});
}

MyWalletPhone.disableSMSNotifications = function() {
    MyWalletPhone.updateNotification({sms: 'disable'});
}

MyWalletPhone.updateNotification = function(updates) {
    var success = function () {
        
        var updateReceiveError = function(error) {
            console.log('Enable notifications error: ' + error);
        }
        
        if (!MyWallet.wallet.accountInfo.notifications.http) {
            console.log('Enable notifications success; enabling for receiving');
            BlockchainSettingsAPI.updateNotificationsOn({ receive: true }).then(function(x) {
                                                                                on_change_notifications_success();
                                                                                return x;
                                                                                }).catch(updateReceiveError);
        } else {
            console.log('Enable notifications success');
            on_change_notifications_success();
        }
    }
    
    var error = function(error) {
        console.log('Enable notifications error: ' + error);
    }
    
    var notificationsType = MyWallet.wallet.accountInfo.notifications;
    
    if (updates.sms == 'enable') notificationsType.sms = true;
    if (updates.sms == 'disable') notificationsType.sms = false;
    
    if (updates.http == 'enable') notificationsType.http = true;
    if (updates.http == 'disable') notificationsType.http = false;
    
    if (updates.email == 'enable') notificationsType.email = true;
    if (updates.email == 'disable') notificationsType.email = false;
    
    BlockchainSettingsAPI.updateNotificationsType(notificationsType).then(success).catch(error);
}

MyWalletPhone.updateTorIpBlock = function(willEnable) {
    
    var shouldEnable = Boolean(willEnable);
    
    var success = function () {
        console.log('Update tor success');
        on_update_tor_success();
    }
    
    var error = function(error) {
        console.log('Update tor error' + error);
        on_update_tor_error();
    }
    
    BlockchainSettingsAPI.updateTorIpBlock(shouldEnable, success, error);
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

MyWalletPhone.didSetLatestBlock = function() {
    var latestBlock = JSON.stringify(MyWallet.wallet.latestBlock);
    return latestBlock == null ? '' : latestBlock;
}

MyWalletPhone.dust = function() {
    return Bitcoin.networks.bitcoin.dustThreshold;
}

MyWalletPhone.labelForLegacyAddress = function(key) {
    var label = MyWallet.wallet.key(key).label;
    return label == null ? '' : label;
}